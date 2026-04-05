import pool from '../config/database.js';
import { hashPassword, verifyPassword } from '../utils/password.utils.js';
import { toPublicMediaUrl } from '../utils/media.utils.js';
import { paginationMeta, parsePagination, toAppError } from './common.service.js';

export async function listBadges() {
  const [rows] = await pool.query(
    `SELECT id, name, description, icon, color, type, category, rarity,
            required_checkins, required_reviews, required_points, required_level,
            points_reward, total_awarded
     FROM badges
     WHERE is_active = TRUE
     ORDER BY display_order ASC, id ASC`
  );

  return rows;
}

export async function getUserBadges(userId) {
  const [rows] = await pool.query(
    `SELECT
        b.id,
        b.name,
        b.description,
        b.icon,
        b.color,
        b.rarity,
        ub.earned_at,
        ub.progress
     FROM user_badges ub
     INNER JOIN badges b ON b.id = ub.badge_id
     WHERE ub.user_id = ?
     ORDER BY ub.earned_at DESC`,
    [userId]
  );

  return rows;
}

export async function getLeaderboard(query) {
  const { page, limit, offset } = parsePagination(query);
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total
     FROM users
     WHERE deleted_at IS NULL AND status != 'BANNED'`
  );
  const [rows] = await pool.query(
    `SELECT
        id,
        first_name,
        last_name,
        profile_picture,
        points,
        level,
        rank,
        checkins_count,
        reviews_count
     FROM users
     WHERE deleted_at IS NULL AND status != 'BANNED'
     ORDER BY points DESC, level DESC, checkins_count DESC, reviews_count DESC
     LIMIT ? OFFSET ?`,
    [limit, offset]
  );

  return {
    data: rows,
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function getMe(userId) {
  const [rows] = await pool.query(
    `SELECT
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.phone_number,
        u.date_of_birth,
        u.gender,
        u.nationality,
        u.profile_picture,
        u.bio,
        u.role,
        u.status,
        u.is_email_verified,
        u.is_phone_verified,
        u.points,
        u.level,
        u.experience_points,
        u.rank,
        u.checkins_count,
        u.reviews_count,
        u.photos_count,
        u.created_at,
        u.last_login_at,
        (SELECT COUNT(*) FROM user_badges ub WHERE ub.user_id = u.id) AS badges_count,
        (SELECT COUNT(*) FROM favorites f WHERE f.user_id = u.id) AS favorites_count
     FROM users u
     WHERE u.id = ? AND u.deleted_at IS NULL`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const user = rows[0];
  return {
    ...user,
    stats: {
      checkins_count: user.checkins_count,
      reviews_count: user.reviews_count,
      photos_count: user.photos_count,
      badges_count: Number(user.badges_count || 0),
      favorites_count: Number(user.favorites_count || 0)
    }
  };
}

export async function updateMyPassword(userId, payload) {
  const [rows] = await pool.query(
    `SELECT id, password_hash
     FROM users
     WHERE id = ? AND deleted_at IS NULL`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const user = rows[0];
  const isCurrentPasswordValid = await verifyPassword(payload.current_password, user.password_hash);
  if (!isCurrentPasswordValid) {
    throw toAppError('Mot de passe actuel incorrect', 400, 'INVALID_CURRENT_PASSWORD');
  }

  if (payload.current_password === payload.new_password) {
    throw toAppError('Le nouveau mot de passe doit etre different', 400, 'PASSWORD_UNCHANGED');
  }

  const passwordHash = await hashPassword(payload.new_password);
  await pool.query(
    `UPDATE users
     SET password_hash = ?, updated_at = NOW()
     WHERE id = ?`,
    [passwordHash, userId]
  );
  await pool.query(
    `UPDATE sessions
     SET is_active = FALSE, updated_at = NOW()
     WHERE user_id = ?`,
    [userId]
  );

  return { password_updated: true };
}

export async function getMyStats(userId) {
  const [summaryRows] = await pool.query(
    `SELECT
        u.points,
        u.level,
        u.rank,
        u.checkins_count,
        u.reviews_count,
        u.photos_count,
        (SELECT COUNT(*) FROM user_badges ub WHERE ub.user_id = u.id) AS badges_earned,
        (SELECT COUNT(*) FROM badges b WHERE b.is_active = TRUE) AS total_badges,
        (SELECT COUNT(*) FROM favorites f WHERE f.user_id = u.id) AS favorites_count,
        (SELECT COALESCE(SUM(r.helpful_count), 0) FROM reviews r WHERE r.user_id = u.id AND r.deleted_at IS NULL) AS reviews_helpful_count
     FROM users u
     WHERE u.id = ? AND u.deleted_at IS NULL`,
    [userId]
  );

  if (!summaryRows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const summary = summaryRows[0];
  const nextLevelAt = Number(summary.level) * 100;
  const currentLevelFloor = Math.max(0, (Number(summary.level) - 1) * 100);
  const currentLevelProgress = Number(summary.points) - currentLevelFloor;

  const [recentActivity] = await pool.query(
    `SELECT *
     FROM (
       SELECT
         'CHECKIN' AS type,
         c.id AS activity_id,
         c.site_id,
         ts.name AS site_name,
         ts.city,
         c.points_earned,
         (
           SELECT p.url
           FROM photos p
           WHERE p.entity_type = 'CHECKIN'
             AND p.entity_id = c.id
             AND p.status = 'ACTIVE'
             AND p.moderation_status = 'APPROVED'
           ORDER BY p.is_primary DESC, p.display_order ASC, p.created_at ASC
           LIMIT 1
         ) AS photo_url,
         (
           SELECT p.thumbnail_url
           FROM photos p
           WHERE p.entity_type = 'CHECKIN'
             AND p.entity_id = c.id
             AND p.status = 'ACTIVE'
             AND p.moderation_status = 'APPROVED'
           ORDER BY p.is_primary DESC, p.display_order ASC, p.created_at ASC
           LIMIT 1
         ) AS photo_thumbnail_url,
         (
           SELECT COUNT(*)
           FROM photos p
           WHERE p.entity_type = 'CHECKIN'
             AND p.entity_id = c.id
             AND p.status = 'ACTIVE'
             AND p.moderation_status = 'APPROVED'
         ) AS photos_count,
         c.created_at
       FROM checkins c
       INNER JOIN tourist_sites ts ON ts.id = c.site_id
       WHERE c.user_id = ?
       UNION ALL
       SELECT
         'REVIEW' AS type,
         r.id AS activity_id,
         r.site_id,
         ts.name AS site_name,
         ts.city,
         r.points_earned,
         NULL AS photo_url,
         NULL AS photo_thumbnail_url,
         0 AS photos_count,
         r.created_at
       FROM reviews r
       INNER JOIN tourist_sites ts ON ts.id = r.site_id
       WHERE r.user_id = ? AND r.deleted_at IS NULL
     ) activity
     ORDER BY created_at DESC
     LIMIT 10`,
    [userId, userId]
  );

  const completionPercentage =
    Number(summary.total_badges || 0) === 0
      ? 0
      : Math.round((Number(summary.badges_earned || 0) / Number(summary.total_badges)) * 100);

  return {
    points: {
      total: Number(summary.points || 0),
      level: Number(summary.level || 1),
      rank: summary.rank,
      next_level_at: nextLevelAt,
      progress_to_next_level: Math.min(
        100,
        Math.round((currentLevelProgress / 100) * 100)
      )
    },
    activity: {
      checkins_count: Number(summary.checkins_count || 0),
      reviews_count: Number(summary.reviews_count || 0),
      photos_count: Number(summary.photos_count || 0)
    },
    achievements: {
      badges_earned: Number(summary.badges_earned || 0),
      total_badges: Number(summary.total_badges || 0),
      completion_percentage: completionPercentage
    },
    social: {
      favorites_count: Number(summary.favorites_count || 0),
      reviews_helpful_count: Number(summary.reviews_helpful_count || 0)
    },
    recent_activity: recentActivity.map((item) => ({
      ...item,
      activity_id: Number(item.activity_id || 0),
      site_id: Number(item.site_id || 0),
      city: item.city || '',
      points_earned: Number(item.points_earned || 0),
      photos_count: Number(item.photos_count || 0),
      photo_url: toPublicMediaUrl(item.photo_url),
      photo_thumbnail_url: toPublicMediaUrl(item.photo_thumbnail_url || item.photo_url)
    }))
  };
}

export async function getPublicUserProfile(userId) {
  const [rows] = await pool.query(
    `SELECT
        u.id,
        u.first_name,
        u.last_name,
        u.profile_picture,
        u.bio,
        u.rank,
        u.level,
        u.points,
        u.created_at,
        (SELECT COUNT(*) FROM user_badges ub WHERE ub.user_id = u.id) AS badges_count,
        u.checkins_count,
        u.reviews_count
     FROM users u
     WHERE u.id = ? AND u.deleted_at IS NULL AND u.status != 'BANNED'`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  return rows[0];
}
