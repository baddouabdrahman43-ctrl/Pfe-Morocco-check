import pool from '../config/database.js';
import { GPS_VALIDATION, POINTS } from '../config/constants.js';
import {
  removeFileIfExists,
  resolveStoredCheckinPhotoPath,
  toPublicMediaUrl
} from '../utils/media.utils.js';
import {
  awardEligibleBadges,
  awardPoints,
  canContribute,
  computeDistanceFromSite,
  getFreshnessStatus,
  normalizeCheckinStatus,
  paginationMeta,
  parsePagination,
  syncUserStats,
  toAppError
} from './common.service.js';

async function attachCheckinPhotos(checkins) {
  if (!checkins.length) {
    return checkins;
  }

  const checkinIds = [...new Set(checkins.map((checkin) => Number(checkin.id)).filter(Boolean))];
  if (!checkinIds.length) {
    return checkins.map((checkin) => ({ ...checkin, photos: [] }));
  }

  const placeholders = checkinIds.map(() => '?').join(', ');
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
     WHERE entity_type = 'CHECKIN'
       AND entity_id IN (${placeholders})
       AND status = 'ACTIVE'
       AND moderation_status = 'APPROVED'
     ORDER BY entity_id ASC, is_primary DESC, display_order ASC, created_at ASC`,
    checkinIds
  );

  const photosByCheckinId = new Map();
  for (const row of rows) {
    const checkinId = Number(row.entity_id);
    const collection = photosByCheckinId.get(checkinId) || [];
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
      created_at: row.created_at
    });
    photosByCheckinId.set(checkinId, collection);
  }

  return checkins.map((checkin) => ({
    ...checkin,
    photos: photosByCheckinId.get(Number(checkin.id)) || []
  }));
}

async function cleanupUploadedPhotos(uploadedPhotos = []) {
  for (const photo of uploadedPhotos) {
    removeFileIfExists(resolveStoredCheckinPhotoPath(photo.filename));
  }
}

function parseJsonObject(value) {
  if (!value) return {};
  if (typeof value === 'object' && !Array.isArray(value)) {
    return value;
  }

  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed
      : {};
  } catch (_error) {
    return {};
  }
}

function isStrictSite(site = {}) {
  const category = `${site.category_name || ''}`.toLowerCase();
  const subcategory = `${site.subcategory || ''}`.toLowerCase();
  const name = `${site.name || ''}`.toLowerCase();

  return [
    'museum',
    'musee',
    'histor',
    'heritage',
    'monument',
    'medina',
    'relig',
    'mosquee',
    'kasbah'
  ].some(
    (keyword) =>
      category.includes(keyword) ||
      subcategory.includes(keyword) ||
      name.includes(keyword)
  );
}

function isRelaxedSite(site = {}) {
  const category = `${site.category_name || ''}`.toLowerCase();
  const subcategory = `${site.subcategory || ''}`.toLowerCase();
  const name = `${site.name || ''}`.toLowerCase();

  return [
    'beach',
    'plage',
    'park',
    'parc',
    'garden',
    'jardin',
    'marina',
    'corniche'
  ].some(
    (keyword) =>
      category.includes(keyword) ||
      subcategory.includes(keyword) ||
      name.includes(keyword)
  );
}

function resolveAllowedDistanceMeters(site = {}) {
  if (isStrictSite(site)) {
    return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.strict;
  }

  if (isRelaxedSite(site)) {
    return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.relaxed;
  }

  return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.standard;
}

function resolveRecommendedAccuracyMeters(site = {}) {
  return isStrictSite(site)
    ? GPS_VALIDATION.STRICT_ACCURACY
    : GPS_VALIDATION.MIN_ACCURACY;
}

function resolveMinimumVisitDurationSeconds(site = {}) {
  if (isStrictSite(site)) {
    return 30;
  }

  if (isRelaxedSite(site)) {
    return 10;
  }

  return GPS_VALIDATION.DEFAULT_MIN_VISIT_DURATION_SECONDS;
}

function buildVerificationNotes({
  site,
  distance,
  allowedDistance,
  accuracy,
  allowedAccuracy,
  visitDuration,
  minimumVisitDuration,
  isOfflineSync,
  hasPhoto
}) {
  const notes = [
    `Rayon autorise: ${allowedDistance} m`,
    `Distance mesuree: ${distance.toFixed(1)} m`,
    `Precision GPS: ${accuracy.toFixed(1)} m (seuil ${allowedAccuracy} m)`
  ];

  if (visitDuration > 0) {
    notes.push(
      `Temps passe sur place: ${visitDuration}s (recommande: ${minimumVisitDuration}s)`
    );
  } else {
    notes.push(`Temps passe sur place non fourni (recommande: ${minimumVisitDuration}s)`);
  }

  if (hasPhoto) {
    notes.push('Preuve photo fournie');
  }
  if (isOfflineSync) {
    notes.push('Check-in collecte hors ligne puis synchronise');
  }
  if (isStrictSite(site)) {
    notes.push('Site a verification stricte');
  } else if (isRelaxedSite(site)) {
    notes.push('Site a rayon de verification elargi');
  }

  return notes.join(' | ');
}

function buildValidationContext({
  site,
  allowedDistance,
  allowedAccuracy,
  minimumVisitDuration,
  visitDuration,
  isOfflineSync
}) {
  return {
    radius_strategy: isStrictSite(site)
      ? 'STRICT'
      : isRelaxedSite(site)
      ? 'RELAXED'
      : 'STANDARD',
    allowed_distance_meters: allowedDistance,
    allowed_accuracy_meters: allowedAccuracy,
    minimum_visit_duration_seconds: minimumVisitDuration,
    recorded_visit_duration_seconds: visitDuration,
    offline_sync: isOfflineSync
  };
}

export async function createCheckin(payload, currentUser, requestMeta = {}) {
  if (!canContribute(currentUser.role)) {
    throw toAppError('Le role utilisateur ne permet pas les check-ins', 403, 'ROLE_NOT_ALLOWED');
  }

  const uploadedPhotos = requestMeta.uploadedPhotos || [];
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [siteRows] = await connection.query(
      `SELECT ts.id, ts.name, ts.latitude, ts.longitude, ts.status, ts.is_active, ts.subcategory,
              c.name AS category_name
       FROM tourist_sites ts
       INNER JOIN categories c ON c.id = ts.category_id
       WHERE ts.id = ? AND ts.deleted_at IS NULL`,
      [payload.site_id]
    );
    if (!siteRows.length) {
      throw toAppError('Site non trouve', 404);
    }

    const site = siteRows[0];
    if (!site.is_active || !['PUBLISHED', 'PENDING_REVIEW'].includes(site.status)) {
      throw toAppError('Le site ne peut pas recevoir de check-in', 400);
    }

    const [existingRows] = await connection.query(
      `SELECT id
       FROM checkins
       WHERE user_id = ?
         AND site_id = ?
         AND DATE(created_at) = CURDATE()
       LIMIT 1`,
      [currentUser.id, payload.site_id]
    );
    if (existingRows.length) {
      throw toAppError('Un check-in existe deja aujourd\'hui pour ce site', 409, 'CHECKIN_ALREADY_EXISTS');
    }

    const distance = computeDistanceFromSite(site, payload.latitude, payload.longitude);
    const allowedDistance = resolveAllowedDistanceMeters(site);
    const allowedAccuracy = resolveRecommendedAccuracyMeters(site);
    const deviceInfo = parseJsonObject(payload.device_info);
    const visitDuration = Math.max(
      0,
      Number.parseInt(deviceInfo.visit_duration_seconds, 10) || 0
    );
    const minimumVisitDuration = resolveMinimumVisitDurationSeconds(site);
    const isOfflineSync = deviceInfo.collected_offline === true;
    const isMockedLocation = deviceInfo.is_mocked_location === true;

    if (distance > allowedDistance) {
      throw toAppError('Vous etes trop loin du site pour valider ce check-in', 400, 'CHECKIN_TOO_FAR', {
        distance,
        maxDistance: allowedDistance
      });
    }

    if (Number(payload.accuracy ?? 0) > allowedAccuracy) {
      throw toAppError(
        'La precision GPS est insuffisante pour valider ce check-in',
        400,
        'CHECKIN_LOW_ACCURACY',
        {
          accuracy: Number(payload.accuracy ?? 0),
          maxAccuracy: allowedAccuracy
        }
      );
    }

    if (isMockedLocation) {
      throw toAppError(
        'Une position simulee a ete detectee, le check-in a ete bloque',
        400,
        'CHECKIN_MOCK_LOCATION'
      );
    }

    const hasPhoto = Boolean(payload.has_photo || uploadedPhotos.length);
    const pointsEarned = hasPhoto ? POINTS.CHECKIN_WITH_PHOTO : POINTS.CHECKIN;
    const normalizedStatus = normalizeCheckinStatus(payload.status);
    const shouldRequireReview =
      visitDuration > 0 &&
      visitDuration < minimumVisitDuration &&
      !hasPhoto;
    const validationStatus = shouldRequireReview ? 'PENDING' : 'APPROVED';
    const verificationNotes = buildVerificationNotes({
      site,
      distance,
      allowedDistance,
      accuracy: Number(payload.accuracy ?? 0),
      allowedAccuracy,
      visitDuration,
      minimumVisitDuration,
      isOfflineSync,
      hasPhoto
    });
    const validationContext = buildValidationContext({
      site,
      allowedDistance,
      allowedAccuracy,
      minimumVisitDuration,
      visitDuration,
      isOfflineSync
    });

    const [result] = await connection.query(
      `INSERT INTO checkins (
          user_id, site_id, status, comment, latitude, longitude, accuracy, distance,
          is_location_verified, has_photo, points_earned, validation_status, verification_notes,
          device_info, ip_address
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, ?, ?, ?, ?, ?, ?)`,
      [
        currentUser.id,
        payload.site_id,
        normalizedStatus,
        payload.comment || null,
        payload.latitude,
        payload.longitude,
        payload.accuracy ?? 20,
        distance,
        hasPhoto,
        pointsEarned,
        validationStatus,
        verificationNotes,
        JSON.stringify({
          ...deviceInfo,
          visit_duration_seconds: visitDuration,
          validation_context: validationContext
        }),
        requestMeta.ipAddress || null
      ]
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
        payload.comment || null,
        `Photo de check-in ${index + 1}`,
        'ACTIVE',
        'APPROVED',
        photo.display_order ?? index,
        photo.is_primary ? 1 : 0
      ]);

      await connection.query(
        `INSERT INTO photos (
            url, thumbnail_url, filename, original_filename, mime_type, size,
            width, height, user_id, entity_type, entity_id, caption, alt_text,
            status, moderation_status, display_order, is_primary
          ) VALUES ?`,
        [photoValues.map((values) => [
          values[0],
          values[1],
          values[2],
          values[3],
          values[4],
          values[5],
          values[6],
          values[7],
          values[8],
          'CHECKIN',
          values[9],
          values[10],
          values[11],
          values[12],
          values[13],
          values[14],
          values[15]
        ])]
      );
    }

    const freshnessScore = hasPhoto ? 100 : 95;
    await connection.query(
      `UPDATE tourist_sites
       SET freshness_score = ?, freshness_status = ?, last_verified_at = NOW(), last_updated_at = NOW(), updated_at = NOW()
       WHERE id = ?`,
      [freshnessScore, getFreshnessStatus(freshnessScore), payload.site_id]
    );

    await awardPoints(connection, currentUser.id, pointsEarned);
    await syncUserStats(connection, currentUser.id);
    const awardedBadges = await awardEligibleBadges(connection, currentUser.id);

    await connection.commit();

    const [rows] = await pool.query(
      `SELECT c.*, ts.name AS site_name
       FROM checkins c
       INNER JOIN tourist_sites ts ON ts.id = c.site_id
       WHERE c.id = ?`,
      [result.insertId]
    );

    const [checkin] = await attachCheckinPhotos(rows);

    return {
      checkin,
      points_earned: pointsEarned,
      photos_uploaded: uploadedPhotos.length,
      validation_context: validationContext,
      awarded_badges: awardedBadges
    };
  } catch (error) {
    await connection.rollback();
    await cleanupUploadedPhotos(uploadedPhotos);
    throw error;
  } finally {
    connection.release();
  }
}

export async function listCheckins(query, currentUser) {
  const { page, limit, offset } = parsePagination(query);
  const filters = [];
  const params = [];

  if (query.user_id && currentUser.role === 'ADMIN') {
    filters.push('c.user_id = ?');
    params.push(Number(query.user_id));
  } else {
    filters.push('c.user_id = ?');
    params.push(currentUser.id);
  }

  if (query.site_id) {
    filters.push('c.site_id = ?');
    params.push(Number(query.site_id));
  }

  const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM checkins c ${whereClause}`,
    params
  );
  const [rows] = await pool.query(
    `SELECT
        c.*,
        ts.name AS site_name,
        ts.city,
        ts.region
     FROM checkins c
     INNER JOIN tourist_sites ts ON ts.id = c.site_id
     ${whereClause}
     ORDER BY c.created_at DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const checkinsWithPhotos = await attachCheckinPhotos(rows);

  return {
    data: checkinsWithPhotos,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function getCheckinById(checkinId, currentUser) {
  const [rows] = await pool.query(
    `SELECT
        c.*,
        ts.name AS site_name,
        ts.address,
        ts.city,
        ts.region,
        u.first_name,
        u.last_name
     FROM checkins c
     INNER JOIN tourist_sites ts ON ts.id = c.site_id
     INNER JOIN users u ON u.id = c.user_id
     WHERE c.id = ?`,
    [checkinId]
  );

  if (!rows.length) {
    throw toAppError('Check-in non trouve', 404);
  }

  const checkin = rows[0];
  if (checkin.user_id !== currentUser.id && currentUser.role !== 'ADMIN') {
    throw toAppError('Acces refuse', 403, 'FORBIDDEN');
  }

  const [checkinWithPhotos] = await attachCheckinPhotos([checkin]);
  return checkinWithPhotos;
}
