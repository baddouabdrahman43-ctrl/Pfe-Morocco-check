import pool from '../src/config/database.js';
import { toPublicMediaUrl } from '../src/utils/media.utils.js';

const REQUEST_TIMEOUT_MS = 5000;

function normalizeMediaUrl(value) {
  const rawValue = String(value || '').trim();
  if (!rawValue) {
    return '';
  }

  return toPublicMediaUrl(rawValue);
}

async function headRequestStatus(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      method: 'HEAD',
      redirect: 'follow',
      signal: controller.signal
    });
    return response.status;
  } catch (error) {
    if (error?.name === 'AbortError') {
      return 'TIMEOUT';
    }

    return 'ERROR';
  } finally {
    clearTimeout(timeout);
  }
}

function logResult(entityType, entityId, fieldName, rawValue, status) {
  console.log(
    `[${entityType}] id=${entityId} field=${fieldName} status=${status} url=${rawValue}`
  );
}

async function validateRows(entityType, fieldName, rows, valueResolver) {
  for (const row of rows) {
    const mediaUrl = normalizeMediaUrl(valueResolver(row));
    if (!mediaUrl) {
      continue;
    }

    const status = await headRequestStatus(mediaUrl);
    logResult(entityType, row.id, fieldName, mediaUrl, status);
  }
}

async function main() {
  try {
    const [siteRows] = await pool.query(
      `SELECT id, cover_photo
       FROM tourist_sites
       WHERE cover_photo IS NOT NULL
         AND TRIM(cover_photo) <> ''`
    );
    await validateRows('SITE', 'cover_photo', siteRows, (row) => row.cover_photo);

    const [userRows] = await pool.query(
      `SELECT id, profile_picture
       FROM users
       WHERE profile_picture IS NOT NULL
         AND TRIM(profile_picture) <> ''`
    );
    await validateRows(
      'USER',
      'profile_picture',
      userRows,
      (row) => row.profile_picture
    );

    const [photoRows] = await pool.query(
      `SELECT
          entity_type,
          entity_id AS id,
          url,
          thumbnail_url
       FROM photos
       WHERE entity_type IN ('SITE', 'REVIEW', 'CHECKIN')
         AND (
           (url IS NOT NULL AND TRIM(url) <> '')
           OR (thumbnail_url IS NOT NULL AND TRIM(thumbnail_url) <> '')
         )
       ORDER BY entity_type ASC, entity_id ASC`
    );

    const groupedRows = photoRows.reduce((groups, row) => {
      const key = String(row.entity_type || '').toUpperCase();
      const currentGroup = groups.get(key) || [];
      currentGroup.push(row);
      groups.set(key, currentGroup);
      return groups;
    }, new Map());

    for (const [entityType, rows] of groupedRows.entries()) {
      await validateRows(entityType, 'url', rows, (row) => row.url);
      await validateRows(
        entityType,
        'thumbnail_url',
        rows,
        (row) => row.thumbnail_url
      );
    }
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error('validate_media_urls_failed', error);
  process.exitCode = 1;
});
