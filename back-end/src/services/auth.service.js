import pool from '../config/database.js';
import { randomBytes, randomUUID } from 'crypto';
import { USER_RANKS, USER_ROLES, USER_STATUS } from '../config/constants.js';
import runtimeConfig from '../config/runtime.js';
import { verifyGoogleIdToken } from '../utils/google-auth.utils.js';
import { decodeToken, generateToken } from '../utils/jwt.utils.js';
import { hashPassword, verifyPassword } from '../utils/password.utils.js';
import { awardEligibleBadges, syncUserStats, toAppError } from './common.service.js';

const REFRESH_TOKEN_TTL_DAYS = runtimeConfig.jwt.refreshTokenTtlDays;
const PUBLIC_USER_SELECT = `SELECT id, first_name, last_name, email, role, status, points, level, rank, profile_picture,
        checkins_count, reviews_count, created_at, updated_at
   FROM users
   WHERE id = ?`;

function normalizeDeviceType(deviceInfo = {}) {
  const rawType = String(
    deviceInfo.device_type ||
      deviceInfo.platform ||
      deviceInfo.type ||
      'WEB'
  ).toUpperCase();

  if (['IOS', 'ANDROID', 'WEB', 'OTHER'].includes(rawType)) {
    return rawType;
  }

  return 'OTHER';
}

function buildSessionPayload(accessToken, refreshToken) {
  const decoded = decodeToken(accessToken);
  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    expires_in: decoded?.exp && decoded?.iat ? decoded.exp - decoded.iat : null,
    token: accessToken
  };
}

function isAccountDisabled(status) {
  return [
    USER_STATUS.SUSPENDED,
    USER_STATUS.BANNED,
    USER_STATUS.INACTIVE
  ].includes(status);
}

function normalizeGoogleProfile(profile) {
  const fullName = String(profile.name || '').trim();
  const firstName =
    String(profile.given_name || '').trim() ||
    (fullName ? fullName.split(/\s+/)[0] : 'Utilisateur');
  const remainingName =
    String(profile.family_name || '').trim() ||
    fullName
      .split(/\s+/)
      .slice(1)
      .join(' ')
      .trim();

  return {
    first_name: firstName || 'Utilisateur',
    last_name: remainingName || 'Google',
    email: String(profile.email || '').trim().toLowerCase(),
    google_id: String(profile.sub || '').trim(),
    profile_picture: profile.picture || null,
    is_email_verified: Boolean(profile.email_verified)
  };
}

async function getPublicUserById(db, userId) {
  const [rows] = await db.query(PUBLIC_USER_SELECT, [userId]);
  return rows[0] || null;
}

async function updateUserLoginMetadata(db, userId) {
  await db.query(
    'UPDATE users SET last_login_at = NOW(), last_seen_at = NOW(), updated_at = NOW() WHERE id = ?',
    [userId]
  );
}

async function createGoogleUser(db, googleProfile) {
  const passwordHash = await hashPassword(randomUUID());
  const [result] = await db.query(
    `INSERT INTO users (
        email,
        password_hash,
        first_name,
        last_name,
        profile_picture,
        role,
        status,
        points,
        level,
        rank,
        is_email_verified,
        google_id,
        last_login_at,
        last_seen_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?, ?, NOW(), NOW())`,
    [
      googleProfile.email,
      passwordHash,
      googleProfile.first_name,
      googleProfile.last_name,
      googleProfile.profile_picture,
      USER_ROLES.TOURIST,
      USER_STATUS.ACTIVE,
      USER_RANKS.BRONZE,
      googleProfile.is_email_verified,
      googleProfile.google_id
    ]
  );

  return getPublicUserById(db, result.insertId);
}

async function linkGoogleIdentity(db, user, googleProfile) {
  if (user.google_id && user.google_id !== googleProfile.google_id) {
    throw toAppError(
      'Ce compte est deja lie a un autre compte Google',
      409,
      'GOOGLE_ACCOUNT_ALREADY_LINKED'
    );
  }

  const updates = [];
  const params = [];

  if (!user.google_id) {
    updates.push('google_id = ?');
    params.push(googleProfile.google_id);
  }

  if (googleProfile.is_email_verified && !user.is_email_verified) {
    updates.push('is_email_verified = TRUE');
  }

  if (!user.profile_picture && googleProfile.profile_picture) {
    updates.push('profile_picture = ?');
    params.push(googleProfile.profile_picture);
  }

  updates.push('last_login_at = NOW()');
  updates.push('last_seen_at = NOW()');
  updates.push('updated_at = NOW()');

  params.push(user.id);
  await db.query(
    `UPDATE users
     SET ${updates.join(', ')}
     WHERE id = ?`,
    params
  );

  return getPublicUserById(db, user.id);
}

async function createSession(db, user, requestContext = {}) {
  const accessToken = generateToken(user);
  const refreshToken = randomBytes(32).toString('hex');
  const deviceInfo = requestContext.deviceInfo || {};

  await db.query(
    `INSERT INTO sessions (
        id, user_id, access_token, refresh_token, device_type, device_name, device_id,
        os_version, app_version, ip_address, user_agent, country, city, expires_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))`,
    [
      randomUUID(),
      user.id,
      accessToken,
      refreshToken,
      normalizeDeviceType(deviceInfo),
      deviceInfo.device_name || null,
      deviceInfo.device_id || null,
      deviceInfo.os_version || null,
      deviceInfo.app_version || null,
      requestContext.ipAddress || '0.0.0.0',
      requestContext.userAgent || null,
      deviceInfo.country || null,
      deviceInfo.city || null,
      REFRESH_TOKEN_TTL_DAYS
    ]
  );

  return buildSessionPayload(accessToken, refreshToken);
}

export async function registerUser(payload, requestContext = {}) {
  const { first_name, last_name, email, password } = payload;

  const [emailRows] = await pool.query(
    'SELECT COUNT(*) AS count FROM users WHERE email = ?',
    [email]
  );
  if (Number(emailRows[0]?.count || 0) > 0) {
    throw toAppError('Email deja utilise', 400, 'EMAIL_ALREADY_USED');
  }

  const password_hash = await hashPassword(password);
  const [result] = await pool.query(
    `INSERT INTO users (
        first_name,
        last_name,
        email,
        password_hash,
        role,
        status,
        points,
        level,
        rank,
        is_email_verified
      ) VALUES (?, ?, ?, ?, ?, ?, 0, 1, ?, FALSE)`,
    [
      first_name,
      last_name,
      email,
      password_hash,
      USER_ROLES.TOURIST,
      USER_STATUS.ACTIVE,
      USER_RANKS.BRONZE
    ]
  );

  const userId = result.insertId;
  const user = await getPublicUserById(pool, userId);
  const session = await createSession(pool, user, requestContext);

  return {
    ...session,
    user
  };
}

export async function loginUser(payload, requestContext = {}) {
  const { email, password } = payload;
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? AND deleted_at IS NULL', [email]);

  if (!rows.length) {
    throw toAppError('Email ou mot de passe incorrect', 401, 'INVALID_CREDENTIALS');
  }

  const user = rows[0];
  const isPasswordValid = await verifyPassword(password, user.password_hash);
  if (!isPasswordValid) {
    throw toAppError('Email ou mot de passe incorrect', 401, 'INVALID_CREDENTIALS');
  }

  if (isAccountDisabled(user.status)) {
    throw toAppError('Compte indisponible', 403, 'ACCOUNT_DISABLED');
  }

  await updateUserLoginMetadata(pool, user.id);
  const freshUser = await getPublicUserById(pool, user.id);
  const session = await createSession(pool, freshUser, requestContext);

  return {
    ...session,
    user: freshUser
  };
}

export async function loginWithGoogleToken(payload, requestContext = {}, dependencies = {}) {
  const verifyGoogleToken =
    dependencies.verifyGoogleToken || verifyGoogleIdToken;
  const verifiedToken = await verifyGoogleToken(payload.id_token);
  const googleProfile = normalizeGoogleProfile(verifiedToken);

  const [rows] = await pool.query(
    `SELECT *
     FROM users
     WHERE deleted_at IS NULL
       AND (google_id = ? OR email = ?)
     ORDER BY CASE WHEN google_id = ? THEN 0 ELSE 1 END
     LIMIT 1`,
    [googleProfile.google_id, googleProfile.email, googleProfile.google_id]
  );

  let currentUser;
  if (!rows.length) {
    currentUser = await createGoogleUser(pool, googleProfile);
  } else {
    const existingUser = rows[0];
    if (isAccountDisabled(existingUser.status)) {
      throw toAppError('Compte indisponible', 403, 'ACCOUNT_DISABLED');
    }

    currentUser = await linkGoogleIdentity(pool, existingUser, googleProfile);
  }

  const session = await createSession(pool, currentUser, requestContext);

  return {
    ...session,
    user: currentUser
  };
}

export async function getProfileById(userId) {
  const [rows] = await pool.query(
    `SELECT id, first_name, last_name, email, phone_number, nationality, bio, role, status, points,
            level, rank, profile_picture, checkins_count, reviews_count, created_at, updated_at
     FROM users
     WHERE id = ? AND deleted_at IS NULL`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const [badgeRows] = await pool.query(
    `SELECT b.id, b.name, b.icon, b.color, b.rarity, ub.earned_at
     FROM user_badges ub
     INNER JOIN badges b ON b.id = ub.badge_id
     WHERE ub.user_id = ?
     ORDER BY ub.earned_at DESC`,
    [userId]
  );

  return {
    user: rows[0],
    badges: badgeRows
  };
}

export async function updateProfileById(userId, payload) {
  const updateEntries = Object.entries(payload).filter(([, value]) => value !== undefined);
  if (!updateEntries.length) {
    throw toAppError('Aucun champ a mettre a jour fourni', 400);
  }

  if (payload.email) {
    const [emailRows] = await pool.query(
      'SELECT id FROM users WHERE email = ? AND id != ? AND deleted_at IS NULL',
      [payload.email, userId]
    );
    if (emailRows.length) {
      throw toAppError('Email deja utilise', 400, 'EMAIL_ALREADY_USED');
    }
  }

  const updates = [];
  const params = [];
  for (const [key, value] of updateEntries) {
    updates.push(`${key} = ?`);
    params.push(value === '' ? null : value);
  }

  params.push(userId);
  await pool.query(
    `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ? AND deleted_at IS NULL`,
    params
  );

  await syncUserStats(pool, userId);
  await awardEligibleBadges(pool, userId);

  return getProfileById(userId);
}

export async function refreshSession(refreshToken, requestContext = {}) {
  const [rows] = await pool.query(
    `SELECT
        s.id,
        s.user_id,
        s.is_active,
        s.expires_at,
        u.id AS user_id_ref,
        u.email,
        u.role,
        u.status
     FROM sessions s
     INNER JOIN users u ON u.id = s.user_id
     WHERE s.refresh_token = ?
       AND s.is_active = TRUE
       AND s.expires_at > NOW()
       AND u.deleted_at IS NULL
     LIMIT 1`,
    [refreshToken]
  );

  if (!rows.length) {
    throw toAppError('Refresh token invalide ou expire', 401, 'INVALID_REFRESH_TOKEN');
  }

  const session = rows[0];
  if (isAccountDisabled(session.status)) {
    throw toAppError('Compte indisponible', 403, 'ACCOUNT_DISABLED');
  }

  const accessToken = generateToken({
    id: session.user_id_ref,
    email: session.email,
    role: session.role
  });
  const nextRefreshToken = randomBytes(32).toString('hex');

  await pool.query(
    `UPDATE sessions
     SET access_token = ?, refresh_token = ?, ip_address = ?, user_agent = ?,
         last_activity_at = NOW(), expires_at = DATE_ADD(NOW(), INTERVAL ? DAY), updated_at = NOW()
     WHERE id = ?`,
    [
      accessToken,
      nextRefreshToken,
      requestContext.ipAddress || '0.0.0.0',
      requestContext.userAgent || null,
      REFRESH_TOKEN_TTL_DAYS,
      session.id
    ]
  );

  return buildSessionPayload(accessToken, nextRefreshToken);
}

export async function logoutSession(userId, accessToken) {
  const [result] = await pool.query(
    `UPDATE sessions
     SET is_active = FALSE, updated_at = NOW()
     WHERE user_id = ? AND access_token = ? AND is_active = TRUE`,
    [userId, accessToken]
  );

  if (!result.affectedRows) {
    await pool.query(
      `UPDATE sessions
       SET is_active = FALSE, updated_at = NOW()
       WHERE user_id = ? AND is_active = TRUE`,
      [userId]
    );
  }

  return { logged_out: true };
}
