import pool from "../config/database.js";
import { POINTS } from "../config/constants.js";
import {
  removeFileIfExists,
  resolveStoredReviewPhotoPath,
  toPublicMediaUrl,
} from "../utils/media.utils.js";
import {
  awardEligibleBadges,
  awardPoints,
  canModerate,
  paginationMeta,
  parsePagination,
  syncSiteReviewAggregates,
  syncUserStats,
  toAppError,
} from "./common.service.js";

async function attachReviewPhotos(reviews, options = {}) {
  if (!reviews.length) {
    return reviews;
  }

  const includeHidden = options.includeHidden === true;
  const reviewIds = [
    ...new Set(reviews.map((review) => Number(review.id)).filter(Boolean)),
  ];
  if (!reviewIds.length) {
    return reviews.map((review) => ({ ...review, photos: [] }));
  }

  const placeholders = reviewIds.map(() => "?").join(", ");
  const filters = [
    `entity_type = 'REVIEW'`,
    `entity_id IN (${placeholders})`,
    `status != 'DELETED'`,
  ];

  if (!includeHidden) {
    filters.push(`status = 'ACTIVE'`);
    filters.push(`moderation_status = 'APPROVED'`);
  }

  const [rows] = await pool.query(
    `SELECT
        id,
        entity_id,
        url,
        thumbnail_url,
        caption,
        alt_text,
        width,
        height,
        status,
        moderation_status,
        is_primary,
        display_order,
        created_at
     FROM photos
     WHERE ${filters.join(" AND ")}
     ORDER BY entity_id ASC, is_primary DESC, display_order ASC, created_at ASC`,
    reviewIds,
  );

  const photosByReviewId = new Map();
  for (const row of rows) {
    const reviewId = Number(row.entity_id);
    const collection = photosByReviewId.get(reviewId) || [];
    collection.push({
      id: Number(row.id),
      url: toPublicMediaUrl(row.url),
      thumbnail_url: toPublicMediaUrl(row.thumbnail_url || row.url),
      caption: row.caption,
      alt_text: row.alt_text,
      width: row.width,
      height: row.height,
      status: row.status,
      moderation_status: row.moderation_status,
      is_primary: Boolean(row.is_primary),
      created_at: row.created_at,
    });
    photosByReviewId.set(reviewId, collection);
  }

  return reviews.map((review) => ({
    ...review,
    photos: photosByReviewId.get(Number(review.id)) || [],
  }));
}

async function cleanupUploadedPhotos(uploadedPhotos = []) {
  for (const photo of uploadedPhotos) {
    removeFileIfExists(resolveStoredReviewPhotoPath(photo.filename));
  }
}

export async function createReview(payload, currentUser, uploadedPhotos = []) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [siteRows] = await connection.query(
      `SELECT id, status, is_active
       FROM tourist_sites
       WHERE id = ? AND deleted_at IS NULL`,
      [payload.site_id],
    );
    if (!siteRows.length) {
      throw toAppError("Site non trouve", 404);
    }
    if (!siteRows[0].is_active || siteRows[0].status !== "PUBLISHED") {
      throw toAppError("Le site ne peut pas recevoir d'avis", 400);
    }

    const [existingRows] = await connection.query(
      `SELECT id
       FROM reviews
       WHERE user_id = ? AND site_id = ? AND deleted_at IS NULL
       LIMIT 1`,
      [currentUser.id, payload.site_id],
    );
    if (existingRows.length) {
      throw toAppError(
        "Un avis existe deja pour ce site",
        409,
        "REVIEW_ALREADY_EXISTS",
      );
    }

    const shouldAutoApprove = canModerate(currentUser?.role);
    const reviewStatus = shouldAutoApprove ? "PUBLISHED" : "PENDING";
    const moderationStatus = shouldAutoApprove ? "APPROVED" : "PENDING";
    const photoModerationStatus = shouldAutoApprove ? "APPROVED" : "PENDING";
    let totalPointsEarned = POINTS.REVIEW;

    const [result] = await connection.query(
      `INSERT INTO reviews (
          user_id, site_id, overall_rating, service_rating, cleanliness_rating, value_rating,
          location_rating, title, content, visit_date, visit_type, recommendations,
          status, moderation_status, points_earned
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        currentUser.id,
        payload.site_id,
        payload.rating,
        payload.service_rating ?? null,
        payload.cleanliness_rating ?? null,
        payload.value_rating ?? null,
        payload.location_rating ?? null,
        payload.title || null,
        payload.content,
        payload.visit_date || null,
        payload.visit_type || null,
        payload.recommendations
          ? JSON.stringify(payload.recommendations)
          : null,
        reviewStatus,
        moderationStatus,
        POINTS.REVIEW,
      ],
    );

    if (uploadedPhotos.length) {
      const photoValues = uploadedPhotos.map((photo, index) => [
        photo.url,
        photo.thumbnail_url || photo.url,
        photo.filename,
        photo.original_filename || photo.filename,
        photo.mime_type,
        photo.size,
        photo.width,
        photo.height,
        currentUser.id,
        result.insertId,
        payload.title || null,
        payload.title || `Photo d avis ${index + 1}`,
        "ACTIVE",
        photoModerationStatus,
        photo.display_order ?? index,
        photo.is_primary ? 1 : 0,
      ]);

      await connection.query(
        `INSERT INTO photos (
            url, thumbnail_url, filename, original_filename, mime_type, size,
            width, height, user_id, entity_type, entity_id, caption, alt_text,
            status, moderation_status, display_order, is_primary
          ) VALUES ?`,
        [
          photoValues.map((values) => [
            values[0],
            values[1],
            values[2],
            values[3],
            values[4],
            values[5],
            values[6],
            values[7],
            values[8],
            "REVIEW",
            values[9],
            values[10],
            values[11],
            values[12],
            values[13],
            values[14],
            values[15],
          ]),
        ],
      );

      await awardPoints(connection, currentUser.id, POINTS.PHOTO);
      totalPointsEarned += POINTS.PHOTO;
    }

    await awardPoints(connection, currentUser.id, POINTS.REVIEW);
    await syncUserStats(connection, currentUser.id);
    if (reviewStatus === "PUBLISHED") {
      await syncSiteReviewAggregates(connection, payload.site_id);
    }
    const awardedBadges = await awardEligibleBadges(connection, currentUser.id);

    await connection.commit();

    const review = await getReviewById(result.insertId, currentUser);
    return {
      review,
      points_earned: totalPointsEarned,
      moderation_status: moderationStatus,
      photos_uploaded: uploadedPhotos.length,
      awarded_badges: awardedBadges,
    };
  } catch (error) {
    await connection.rollback();
    await cleanupUploadedPhotos(uploadedPhotos);
    throw error;
  } finally {
    connection.release();
  }
}

export async function listReviews(query, currentUser = null) {
  const { page, limit, offset } = parsePagination(query);
  const filters = ["r.deleted_at IS NULL"];
  const params = [];
  const isOwnReviewsQuery =
    currentUser?.id &&
    query.user_id &&
    Number(query.user_id) === Number(currentUser.id);

  if (!canModerate(currentUser?.role) && !isOwnReviewsQuery) {
    filters.push(`r.status = 'PUBLISHED'`);
  } else if (query.status) {
    filters.push("r.status = ?");
    params.push(query.status);
  }

  if (query.site_id) {
    filters.push("r.site_id = ?");
    params.push(Number(query.site_id));
  }
  if (query.user_id) {
    filters.push("r.user_id = ?");
    params.push(Number(query.user_id));
  }

  const whereClause = `WHERE ${filters.join(" AND ")}`;
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM reviews r ${whereClause}`,
    params,
  );
  const [rows] = await pool.query(
    `SELECT
        r.id,
        r.site_id,
        r.user_id,
        r.overall_rating,
        r.title,
        r.content,
        r.status,
        r.moderation_status,
        r.has_owner_response,
        r.owner_response,
        r.owner_response_date,
        r.helpful_count,
        r.created_at,
        ts.name AS site_name,
        u.first_name,
        u.last_name
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     INNER JOIN users u ON u.id = r.user_id
     ${whereClause}
     ORDER BY r.created_at DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const reviewsWithPhotos = await attachReviewPhotos(rows);

  return {
    data: reviewsWithPhotos,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit),
  };
}

export async function getReviewById(reviewId, currentUser = null) {
  const [rows] = await pool.query(
    `SELECT
        r.*,
        ts.name AS site_name,
        ts.owner_id,
        u.first_name,
        u.last_name
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     INNER JOIN users u ON u.id = r.user_id
     WHERE r.id = ? AND r.deleted_at IS NULL`,
    [reviewId],
  );

  if (!rows.length) {
    throw toAppError("Avis non trouve", 404);
  }

  const review = rows[0];
  if (
    !canModerate(currentUser?.role) &&
    review.status !== "PUBLISHED" &&
    review.user_id !== currentUser?.id
  ) {
    throw toAppError("Avis non trouve", 404);
  }

  const [reviewWithPhotos] = await attachReviewPhotos([review]);
  return reviewWithPhotos;
}

export async function respondToReview(reviewId, payload, currentUser) {
  const [rows] = await pool.query(
    `SELECT
        r.id,
        r.site_id,
        r.status,
        ts.owner_id
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     WHERE r.id = ? AND r.deleted_at IS NULL`,
    [reviewId],
  );

  if (!rows.length) {
    throw toAppError("Avis non trouve", 404);
  }

  const review = rows[0];
  const isOwner = Number(review.owner_id || 0) === Number(currentUser.id);

  if (!isOwner && !canModerate(currentUser.role)) {
    throw toAppError("Acces refuse", 403, "FORBIDDEN");
  }

  if (review.status !== "PUBLISHED" && !canModerate(currentUser.role)) {
    throw toAppError(
      "Seuls les avis publies peuvent recevoir une reponse professionnelle",
      400,
    );
  }

  await pool.query(
    `UPDATE reviews
     SET has_owner_response = TRUE,
         owner_response = ?,
         owner_response_date = NOW(),
         updated_at = NOW()
     WHERE id = ?`,
    [payload.response.trim(), reviewId],
  );

  return getReviewById(reviewId, currentUser);
}

export async function updateReview(reviewId, payload, currentUser) {
  const review = await getReviewById(reviewId, currentUser);
  if (review.user_id !== currentUser.id && !canModerate(currentUser.role)) {
    throw toAppError("Acces refuse", 403, "FORBIDDEN");
  }

  const fields = [];
  const params = [];
  const fieldMap = {
    rating: "overall_rating",
    service_rating: "service_rating",
    cleanliness_rating: "cleanliness_rating",
    value_rating: "value_rating",
    location_rating: "location_rating",
    title: "title",
    content: "content",
    visit_date: "visit_date",
    visit_type: "visit_type",
    recommendations: "recommendations",
  };

  for (const [key, value] of Object.entries(payload)) {
    if (value === undefined) continue;
    const column = fieldMap[key];
    if (!column) continue;
    fields.push(`${column} = ?`);
    if (key === "recommendations" && value !== null) {
      params.push(JSON.stringify(value));
    } else {
      params.push(value === "" ? null : value);
    }
  }

  if (!fields.length) {
    throw toAppError("Aucune mise a jour fournie", 400);
  }

  params.push(reviewId);
  await pool.query(
    `UPDATE reviews SET ${fields.join(", ")}, updated_at = NOW() WHERE id = ?`,
    params,
  );
  await syncSiteReviewAggregates(pool, review.site_id);

  return getReviewById(reviewId, currentUser);
}

export async function deleteReview(reviewId, currentUser) {
  const review = await getReviewById(reviewId, currentUser);
  if (review.user_id !== currentUser.id && !canModerate(currentUser.role)) {
    throw toAppError("Acces refuse", 403, "FORBIDDEN");
  }

  await pool.query(
    `UPDATE reviews
     SET status = 'DELETED', deleted_at = NOW(), updated_at = NOW()
     WHERE id = ?`,
    [reviewId],
  );
  await pool.query(
    `UPDATE photos
     SET status = 'DELETED', moderation_status = 'REJECTED', updated_at = NOW()
     WHERE entity_type = 'REVIEW' AND entity_id = ? AND status != 'DELETED'`,
    [reviewId],
  );
  await syncUserStats(pool, review.user_id);
  await syncSiteReviewAggregates(pool, review.site_id);

  return { id: reviewId, deleted: true };
}
