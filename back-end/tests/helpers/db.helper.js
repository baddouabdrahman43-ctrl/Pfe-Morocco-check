import pool from "../../src/config/database.js";
import { hashPassword } from "../../src/utils/password.utils.js";
import { randomBytes, randomUUID } from 'crypto';
import { generateToken } from '../../src/utils/jwt.utils.js';

export async function isDatabaseAvailable() {
  try {
    await pool.query("SELECT 1 AS ok");
    return true;
  } catch (_error) {
    return false;
  }
}

export async function hasTable(tableName) {
  try {
    const dbName = process.env.DB_NAME || "moroccocheck";
    const [rows] = await pool.query(
      `SELECT COUNT(*) AS count
       FROM information_schema.tables
       WHERE table_schema = ? AND table_name = ?`,
      [dbName, tableName],
    );

    return Number(rows[0]?.count || 0) > 0;
  } catch (_error) {
    return false;
  }
}

export async function cleanUsersByEmails(emails) {
  if (!emails.length) {
    return;
  }

  const placeholders = emails.map(() => "?").join(", ");
  await pool.query(
    `DELETE FROM users WHERE email IN (${placeholders})`,
    emails,
  );
}

export async function createTestCategory(overrides = {}) {
  const suffix = `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  const payload = {
    name: `Test Category ${suffix}`,
    name_ar: `Test Category AR ${suffix}`,
    description: "Test category for automated tests",
    icon: "test",
    color: "#123456",
    parent_id: null,
    ...overrides,
  };

  const [result] = await pool.query(
    `INSERT INTO categories (name, name_ar, description, icon, color, parent_id)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      payload.name,
      payload.name_ar,
      payload.description,
      payload.icon,
      payload.color,
      payload.parent_id,
    ],
  );

  return {
    id: result.insertId,
    ...payload,
  };
}

export async function createTestUser(overrides = {}) {
  const suffix = `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  const password = overrides.password || "password123";
  const passwordHash = await hashPassword(password);
  const payload = {
    email: overrides.email || `test.user.${suffix}@example.com`,
    first_name: overrides.first_name || "Test",
    last_name: overrides.last_name || "User",
    profile_picture: overrides.profile_picture || null,
    google_id: overrides.google_id || null,
    role: overrides.role || "TOURIST",
    status: overrides.status || "ACTIVE",
    rank: overrides.rank || "BRONZE",
    points: overrides.points || 0,
    level: overrides.level || 1,
    is_email_verified:
      overrides.is_email_verified === undefined
        ? true
        : overrides.is_email_verified,
  };

  const [result] = await pool.query(
    `INSERT INTO users (
        email, password_hash, first_name, last_name, profile_picture, google_id,
        role, status, is_email_verified, points, level, rank
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      payload.email,
      passwordHash,
      payload.first_name,
      payload.last_name,
      payload.profile_picture,
      payload.google_id,
      payload.role,
      payload.status,
      payload.is_email_verified,
      payload.points,
      payload.level,
      payload.rank,
    ],
  );

  return {
    id: result.insertId,
    password,
    ...payload,
  };
}

export async function createSessionForUser(user, overrides = {}) {
  const accessToken = overrides.access_token || generateToken(user);
  const refreshToken =
    overrides.refresh_token || randomBytes(32).toString('hex');

  await pool.query(
    `INSERT INTO sessions (
        id, user_id, access_token, refresh_token, device_type, device_name, device_id,
        os_version, app_version, ip_address, user_agent, country, city, expires_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))`,
    [
      randomUUID(),
      user.id,
      accessToken,
      refreshToken,
      overrides.device_type || 'WEB',
      overrides.device_name || 'Automated Test',
      overrides.device_id || null,
      overrides.os_version || null,
      overrides.app_version || 'test',
      overrides.ip_address || '127.0.0.1',
      overrides.user_agent || 'supertest',
      overrides.country || null,
      overrides.city || null,
      overrides.ttl_days || 30
    ]
  );

  return {
    access_token: accessToken,
    refresh_token: refreshToken
  };
}

export async function createTestSite(categoryId, overrides = {}) {
  const suffix = `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  const payload = {
    name: overrides.name || `Test Site ${suffix}`,
    description:
      overrides.description || "Test tourist site for automated checks",
    latitude: overrides.latitude || 33.5731,
    longitude: overrides.longitude || -7.5898,
    city: overrides.city || "Casablanca",
    region: overrides.region || "Casablanca-Settat",
    country: overrides.country || "MA",
    subcategory: overrides.subcategory || null,
    status: overrides.status || "PUBLISHED",
    verification_status: overrides.verification_status || "VERIFIED",
    is_active: overrides.is_active === undefined ? true : overrides.is_active,
    owner_id: overrides.owner_id || null,
  };

  const [result] = await pool.query(
    `INSERT INTO tourist_sites (
        name, description, category_id, subcategory, latitude, longitude, city, region,
        country, owner_id, status, verification_status, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      payload.name,
      payload.description,
      categoryId,
      payload.subcategory,
      payload.latitude,
      payload.longitude,
      payload.city,
      payload.region,
      payload.country,
      payload.owner_id,
      payload.status,
      payload.verification_status,
      payload.is_active,
    ],
  );

  return {
    id: result.insertId,
    ...payload,
  };
}

export async function cleanupTestData({
  reviewIds = [],
  checkinIds = [],
  siteIds = [],
  userIds = [],
  categoryIds = [],
} = {}) {
  await pool.query(
    `UPDATE tourist_sites ts
     SET total_reviews = (
         SELECT COUNT(*)
         FROM reviews r
         WHERE r.site_id = ts.id
           AND r.deleted_at IS NULL
       ),
       average_rating = (
         SELECT COALESCE(AVG(r.overall_rating), 0)
         FROM reviews r
         WHERE r.site_id = ts.id
           AND r.deleted_at IS NULL
           AND r.status = 'PUBLISHED'
       )`,
  );

  if (reviewIds.length) {
    const placeholders = reviewIds.map(() => "?").join(", ");
    await pool.query(
      `DELETE FROM reviews WHERE id IN (${placeholders})`,
      reviewIds,
    );
  }

  if (checkinIds.length) {
    const placeholders = checkinIds.map(() => "?").join(", ");
    await pool.query(
      `DELETE FROM checkins WHERE id IN (${placeholders})`,
      checkinIds,
    );
  }

  if (siteIds.length) {
    await pool.query(
      `UPDATE tourist_sites ts
       SET total_reviews = (
           SELECT COUNT(*)
           FROM reviews r
           WHERE r.site_id = ts.id
             AND r.deleted_at IS NULL
         )`,
    );
    const placeholders = siteIds.map(() => "?").join(", ");
    await pool.query(
      `DELETE FROM favorites WHERE site_id IN (${placeholders})`,
      siteIds,
    );
    await pool.query(
      `DELETE FROM opening_hours WHERE site_id IN (${placeholders})`,
      siteIds,
    );
    await pool.query(
      `DELETE FROM reviews WHERE site_id IN (${placeholders})`,
      siteIds,
    );
    await pool.query(
      `DELETE FROM checkins WHERE site_id IN (${placeholders})`,
      siteIds,
    );
    await pool.query(
      `DELETE FROM tourist_sites WHERE id IN (${placeholders})`,
      siteIds,
    );
  }

  if (userIds.length) {
    await pool.query(
      `UPDATE tourist_sites ts
       SET total_reviews = (
           SELECT COUNT(*)
           FROM reviews r
           WHERE r.site_id = ts.id
             AND r.deleted_at IS NULL
         )`,
    );
    const placeholders = userIds.map(() => "?").join(", ");
    await pool.query(
      `DELETE FROM sessions WHERE user_id IN (${placeholders})`,
      userIds,
    );
    await pool.query(
      `DELETE FROM user_badges WHERE user_id IN (${placeholders})`,
      userIds,
    );
    await pool.query(
      `DELETE FROM favorites WHERE user_id IN (${placeholders})`,
      userIds,
    );
    await pool.query(
      `DELETE FROM reviews WHERE user_id IN (${placeholders})`,
      userIds,
    );
    await pool.query(
      `DELETE FROM checkins WHERE user_id IN (${placeholders})`,
      userIds,
    );
    await pool.query(
      `DELETE FROM users WHERE id IN (${placeholders})`,
      userIds,
    );
  }

  if (categoryIds.length) {
    const placeholders = categoryIds.map(() => "?").join(", ");
    await pool.query(
      `DELETE FROM categories WHERE id IN (${placeholders})`,
      categoryIds,
    );
  }
}
