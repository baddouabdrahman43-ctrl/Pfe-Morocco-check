import pool from '../config/database.js';
import { removeFileIfExists, resolveStoredReviewPhotoPath, toPublicMediaUrl } from '../utils/media.utils.js';
import { paginationMeta, parsePagination, syncSiteReviewAggregates, toAppError } from './common.service.js';

export async function listPendingSites(query) {
  const { page, limit, offset } = parsePagination(query);
  const filters = [
    'ts.deleted_at IS NULL',
    `ts.verification_status = 'PENDING'`
  ];
  const params = [];

  if (query.q) {
    const search = `%${query.q.trim()}%`;
    filters.push(`(
      ts.name LIKE ?
      OR ts.city LIKE ?
      OR ts.region LIKE ?
      OR COALESCE(c.name, '') LIKE ?
      OR COALESCE(u.email, '') LIKE ?
      OR CONCAT_WS(' ', COALESCE(u.first_name, ''), COALESCE(u.last_name, '')) LIKE ?
    )`);
    params.push(search, search, search, search, search, search);
  }

  if (query.city) {
    filters.push('ts.city = ?');
    params.push(query.city);
  }

  if (query.region) {
    filters.push('ts.region = ?');
    params.push(query.region);
  }

  const sortMap = {
    oldest: 'ts.created_at ASC',
    newest: 'ts.created_at DESC',
    city: 'ts.city ASC, ts.created_at ASC',
    name: 'ts.name ASC, ts.created_at ASC'
  };
  const orderBy = sortMap[query.sort] || sortMap.oldest;
  const whereClause = `WHERE ${filters.join(' AND ')}`;

  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total
     FROM tourist_sites ts
     LEFT JOIN users u ON u.id = ts.owner_id
     LEFT JOIN categories c ON c.id = ts.category_id
     ${whereClause}`,
    params
  );
  const [rows] = await pool.query(
    `SELECT
        ts.id,
        ts.name,
        ts.city,
        ts.region,
        c.name AS category_name,
        ts.status,
        ts.verification_status,
        ts.created_at,
        u.email AS owner_email,
        u.first_name AS owner_first_name,
        u.last_name AS owner_last_name
     FROM tourist_sites ts
     LEFT JOIN users u ON u.id = ts.owner_id
     LEFT JOIN categories c ON c.id = ts.category_id
     ${whereClause}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  return {
    data: rows,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function reviewSite(siteId, adminUserId, payload) {
  const [rows] = await pool.query(
    `SELECT id FROM tourist_sites WHERE id = ? AND deleted_at IS NULL`,
    [siteId]
  );
  if (!rows.length) {
    throw toAppError('Site non trouve', 404);
  }

  const states = {
    APPROVE: { verification_status: 'VERIFIED', status: 'PUBLISHED' },
    REJECT: { verification_status: 'REJECTED', status: 'ARCHIVED' },
    ARCHIVE: { verification_status: 'VERIFIED', status: 'ARCHIVED' }
  };
  const nextState = states[payload.action];
  const notes = payload.notes?.trim() || null;

  await pool.query(
    `UPDATE tourist_sites
     SET verification_status = ?, status = ?, moderation_notes = ?, moderated_by = ?, moderated_at = NOW(), updated_at = NOW()
     WHERE id = ?`,
    [nextState.verification_status, nextState.status, notes, adminUserId, siteId]
  );

  return {
    id: Number(siteId),
    reviewed_by: adminUserId,
    ...nextState,
    notes
  };
}

export async function getAdminSiteDetail(siteId) {
  const [rows] = await pool.query(
    `SELECT
        ts.id,
        ts.name,
        ts.description,
        ts.address,
        ts.city,
        ts.region,
        ts.country,
        ts.latitude,
        ts.longitude,
        ts.phone_number,
        ts.email,
        ts.website,
        ts.status,
        ts.verification_status,
        ts.created_at,
        ts.updated_at,
        ts.last_verified_at,
        ts.average_rating,
        ts.total_reviews,
        ts.freshness_score,
        ts.freshness_status,
        ts.moderation_notes,
        ts.moderated_at,
        c.name AS category_name,
        owner.id AS owner_id,
        owner.email AS owner_email,
        owner.first_name AS owner_first_name,
        owner.last_name AS owner_last_name,
        moderator.id AS moderator_id,
        moderator.first_name AS moderator_first_name,
        moderator.last_name AS moderator_last_name
     FROM tourist_sites ts
     LEFT JOIN categories c ON c.id = ts.category_id
     LEFT JOIN users owner ON owner.id = ts.owner_id
     LEFT JOIN users moderator ON moderator.id = ts.moderated_by
     WHERE ts.id = ? AND ts.deleted_at IS NULL
     LIMIT 1`,
    [siteId]
  );

  if (!rows.length) {
    throw toAppError('Site non trouve', 404);
  }

  return rows[0];
}

export async function listPendingReviews(query) {
  const { page, limit, offset } = parsePagination(query);
  const filters = [
    'r.deleted_at IS NULL',
    `r.moderation_status = 'PENDING'`
  ];
  const params = [];

  if (query.q) {
    const search = `%${query.q.trim()}%`;
    filters.push(`(
      COALESCE(r.title, '') LIKE ?
      OR r.content LIKE ?
      OR ts.name LIKE ?
      OR u.email LIKE ?
      OR CONCAT_WS(' ', COALESCE(u.first_name, ''), COALESCE(u.last_name, '')) LIKE ?
    )`);
    params.push(search, search, search, search, search);
  }

  if (query.min_rating) {
    filters.push('r.overall_rating >= ?');
    params.push(Number(query.min_rating));
  }

  const sortMap = {
    oldest: 'r.created_at ASC',
    newest: 'r.created_at DESC',
    rating_desc: 'r.overall_rating DESC, r.created_at ASC',
    rating_asc: 'r.overall_rating ASC, r.created_at ASC'
  };
  const orderBy = sortMap[query.sort] || sortMap.oldest;
  const whereClause = `WHERE ${filters.join(' AND ')}`;

  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     INNER JOIN users u ON u.id = r.user_id
     ${whereClause}`,
    params
  );
  const [rows] = await pool.query(
    `SELECT
        r.id,
        r.site_id,
        r.user_id,
        r.overall_rating,
        r.title,
        r.visit_type,
        r.created_at,
        ts.name AS site_name,
        u.email,
        u.first_name,
        u.last_name
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     INNER JOIN users u ON u.id = r.user_id
     ${whereClause}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  return {
    data: rows,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function moderateReview(reviewId, adminUserId, payload) {
  const [rows] = await pool.query(
    `SELECT id, site_id FROM reviews WHERE id = ? AND deleted_at IS NULL`,
    [reviewId]
  );
  if (!rows.length) {
    throw toAppError('Avis non trouve', 404);
  }

  const states = {
    APPROVE: { moderation_status: 'APPROVED', status: 'PUBLISHED' },
    REJECT: { moderation_status: 'REJECTED', status: 'HIDDEN' },
    FLAG: { moderation_status: 'FLAGGED', status: 'HIDDEN' },
    SPAM: { moderation_status: 'SPAM', status: 'HIDDEN' }
  };
  const nextState = states[payload.action];

  await pool.query(
    `UPDATE reviews
     SET moderation_status = ?, status = ?, moderated_by = ?, moderated_at = NOW(), moderation_notes = ?, updated_at = NOW()
     WHERE id = ?`,
    [nextState.moderation_status, nextState.status, adminUserId, payload.notes || null, reviewId]
  );
  const photoStateByAction = {
    APPROVE: { status: 'ACTIVE', moderation_status: 'APPROVED' },
    REJECT: { status: 'HIDDEN', moderation_status: 'REJECTED' },
    FLAG: { status: 'FLAGGED', moderation_status: 'REJECTED' },
    SPAM: { status: 'FLAGGED', moderation_status: 'REJECTED' }
  };
  const nextPhotoState = photoStateByAction[payload.action];
  if (nextPhotoState) {
    await pool.query(
      `UPDATE photos
       SET status = ?, moderation_status = ?, updated_at = NOW()
       WHERE entity_type = 'REVIEW' AND entity_id = ? AND status != 'DELETED'`,
      [nextPhotoState.status, nextPhotoState.moderation_status, reviewId]
    );
  }
  await syncSiteReviewAggregates(pool, rows[0].site_id);

  return {
    id: Number(reviewId),
    moderated_by: adminUserId,
    ...nextState,
    notes: payload.notes || null
  };
}

export async function getAdminReviewDetail(reviewId) {
  const [rows] = await pool.query(
    `SELECT
        r.id,
        r.site_id,
        r.user_id,
        r.overall_rating,
        r.service_rating,
        r.cleanliness_rating,
        r.value_rating,
        r.location_rating,
        r.title,
        r.content,
        r.visit_date,
        r.visit_type,
        r.status,
        r.moderation_status,
        r.moderation_notes,
        r.moderated_at,
        r.created_at,
        r.updated_at,
        r.helpful_count,
        r.not_helpful_count,
        r.reports_count,
        ts.name AS site_name,
        ts.city AS site_city,
        ts.region AS site_region,
        author.email AS author_email,
        author.first_name AS author_first_name,
        author.last_name AS author_last_name,
        moderator.id AS moderator_id,
        moderator.first_name AS moderator_first_name,
        moderator.last_name AS moderator_last_name
     FROM reviews r
     INNER JOIN tourist_sites ts ON ts.id = r.site_id
     INNER JOIN users author ON author.id = r.user_id
     LEFT JOIN users moderator ON moderator.id = r.moderated_by
     WHERE r.id = ? AND r.deleted_at IS NULL
     LIMIT 1`,
    [reviewId]
  );

  if (!rows.length) {
    throw toAppError('Avis non trouve', 404);
  }

  const review = rows[0];
  const [photos] = await pool.query(
    `SELECT
        id,
        url,
        thumbnail_url,
        filename,
        original_filename,
        caption,
        alt_text,
        status,
        moderation_status,
        is_primary,
        created_at
     FROM photos
     WHERE entity_type = 'REVIEW'
       AND entity_id = ?
       AND status != 'DELETED'
     ORDER BY is_primary DESC, display_order ASC, created_at ASC`,
    [reviewId]
  );

  return {
    ...review,
    photos: photos.map((photo) => ({
      ...photo,
      id: Number(photo.id),
      url: toPublicMediaUrl(photo.url),
      thumbnail_url: toPublicMediaUrl(photo.thumbnail_url || photo.url)
    }))
  };
}

export async function deleteReviewPhoto(reviewId, photoId, adminUserId) {
  const [rows] = await pool.query(
    `SELECT id, entity_id, user_id, filename
     FROM photos
     WHERE id = ?
       AND entity_type = 'REVIEW'
       AND entity_id = ?
       AND status != 'DELETED'
     LIMIT 1`,
    [photoId, reviewId]
  );

  if (!rows.length) {
    throw toAppError('Photo non trouvee', 404);
  }

  const photo = rows[0];
  await pool.query(
    `UPDATE photos
     SET status = 'DELETED', moderation_status = 'REJECTED', updated_at = NOW()
     WHERE id = ?`,
    [photoId]
  );
  await pool.query(
    `UPDATE reviews
     SET moderated_by = ?, moderated_at = NOW(), updated_at = NOW()
     WHERE id = ?`,
    [adminUserId, reviewId]
  );
  removeFileIfExists(resolveStoredReviewPhotoPath(photo.filename));

  return {
    id: Number(photoId),
    review_id: Number(reviewId),
    deleted: true
  };
}

export async function listUsers(query) {
  const { page, limit, offset } = parsePagination(query);
  const filters = ['deleted_at IS NULL'];
  const params = [];

  if (query.role) {
    filters.push('role = ?');
    params.push(query.role);
  }
  if (query.status) {
    filters.push('status = ?');
    params.push(query.status);
  }
  if (query.q) {
    filters.push('(email LIKE ? OR first_name LIKE ? OR last_name LIKE ?)');
    const search = `%${query.q}%`;
    params.push(search, search, search);
  }

  const whereClause = `WHERE ${filters.join(' AND ')}`;
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM users ${whereClause}`,
    params
  );
  const [rows] = await pool.query(
    `SELECT
        id,
        email,
        first_name,
        last_name,
        role,
        status,
        points,
        level,
        rank,
        created_at,
        last_login_at
     FROM users
     ${whereClause}
     ORDER BY created_at DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  return {
    data: rows,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function getUserById(userId) {
  const [rows] = await pool.query(
    `SELECT
        id,
        email,
        first_name,
        last_name,
        role,
        status,
        points,
        level,
        rank,
        created_at,
        last_login_at
     FROM users
     WHERE id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  return rows[0];
}

export async function updateUserStatus(userId, status) {
  const [rows] = await pool.query(
    `SELECT id FROM users WHERE id = ? AND deleted_at IS NULL`,
    [userId]
  );
  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  await pool.query(
    `UPDATE users SET status = ?, updated_at = NOW() WHERE id = ?`,
    [status, userId]
  );

  const [updatedRows] = await pool.query(
    `SELECT id, email, first_name, last_name, role, status, points, level, rank
     FROM users
     WHERE id = ?`,
    [userId]
  );

  return updatedRows[0];
}

export async function updateUserRole(userId, role) {
  const [rows] = await pool.query(
    `SELECT id FROM users WHERE id = ? AND deleted_at IS NULL`,
    [userId]
  );
  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  await pool.query(
    `UPDATE users SET role = ?, updated_at = NOW() WHERE id = ?`,
    [role, userId]
  );

  const [updatedRows] = await pool.query(
    `SELECT id, email, first_name, last_name, role, status, points, level, rank
     FROM users
     WHERE id = ?`,
    [userId]
  );

  return updatedRows[0];
}

export async function getAdminStats() {
  const [rows] = await pool.query(
    `SELECT
        (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL) AS users,
        (SELECT COUNT(*) FROM tourist_sites WHERE deleted_at IS NULL) AS sites,
        (SELECT COUNT(*) FROM checkins) AS checkins,
        (SELECT COUNT(*) FROM reviews WHERE deleted_at IS NULL) AS reviews,
        (SELECT COUNT(*) FROM tourist_sites WHERE deleted_at IS NULL AND verification_status = 'PENDING') AS pending_sites,
        (SELECT COUNT(*) FROM reviews WHERE deleted_at IS NULL AND moderation_status = 'PENDING') AS pending_reviews,
        (SELECT COUNT(*) FROM contributor_requests WHERE status = 'PENDING') AS pending_contributor_requests,
        (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL AND status = 'SUSPENDED') AS suspended_users`
  );

  return rows[0];
}
