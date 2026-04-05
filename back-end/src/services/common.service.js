import { RANK_THRESHOLDS, USER_RANKS, USER_ROLES } from '../config/constants.js';
import { calculateDistance } from '../utils/gps.utils.js';
import { AppError } from '../utils/app-error.js';

export function parsePagination(query = {}) {
  const page = Math.max(1, Number.parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, Number.parseInt(query.limit, 10) || 10));
  return {
    page,
    limit,
    offset: (page - 1) * limit
  };
}

export function paginationMeta(total, page, limit) {
  return {
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit))
  };
}

export function toAppError(message, statusCode = 500, code = null, details = null) {
  return new AppError(message, statusCode, code, details);
}

export function getRankFromPoints(points) {
  if (points >= RANK_THRESHOLDS.PLATINUM) return USER_RANKS.PLATINUM;
  if (points >= RANK_THRESHOLDS.GOLD) return USER_RANKS.GOLD;
  if (points >= RANK_THRESHOLDS.SILVER) return USER_RANKS.SILVER;
  return USER_RANKS.BRONZE;
}

export function getLevelFromPoints(points) {
  return Math.max(1, Math.floor(points / 100) + 1);
}

export function getFreshnessStatus(score) {
  if (score >= 90) return 'FRESH';
  if (score >= 70) return 'RECENT';
  if (score >= 40) return 'OLD';
  return 'OBSOLETE';
}

export function normalizeCheckinStatus(status) {
  const map = {
    CLOSED: 'CLOSED_TEMPORARILY',
    UNDER_CONSTRUCTION: 'RENOVATING'
  };
  return map[status] || status;
}

export function canContribute(role) {
  return [
    USER_ROLES.CONTRIBUTOR,
    USER_ROLES.PROFESSIONAL,
    USER_ROLES.ADMIN
  ].includes(role);
}

export function canManageSites(role) {
  return [
    USER_ROLES.PROFESSIONAL,
    USER_ROLES.ADMIN
  ].includes(role);
}

export function canModerate(role) {
  return role === USER_ROLES.ADMIN;
}

export function canAdmin(role) {
  return role === USER_ROLES.ADMIN;
}

export function computeDistanceFromSite(site, latitude, longitude) {
  return calculateDistance(
    Number(latitude),
    Number(longitude),
    Number(site.latitude),
    Number(site.longitude)
  );
}

export async function awardPoints(db, userId, points) {
  await db.query(
    `UPDATE users
     SET points = points + ?, experience_points = experience_points + ?, updated_at = NOW()
     WHERE id = ?`,
    [points, points, userId]
  );
}

export async function syncUserStats(db, userId) {
  const [rows] = await db.query(
    `SELECT
        u.points,
        (SELECT COUNT(*) FROM checkins c WHERE c.user_id = u.id) AS checkins_count,
        (SELECT COUNT(*) FROM reviews r WHERE r.user_id = u.id AND r.deleted_at IS NULL AND r.status != 'DELETED') AS reviews_count,
        (
          SELECT COUNT(*)
          FROM photos p
          WHERE p.user_id = u.id
            AND p.status != 'DELETED'
            AND p.entity_type IN ('REVIEW', 'CHECKIN', 'SITE', 'USER_PROFILE')
        ) AS photos_count
     FROM users u
     WHERE u.id = ?`,
    [userId]
  );

  if (!rows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const stats = rows[0];
  const level = getLevelFromPoints(Number(stats.points || 0));
  const rank = getRankFromPoints(Number(stats.points || 0));

  await db.query(
    `UPDATE users
     SET checkins_count = ?, reviews_count = ?, photos_count = ?, level = ?, rank = ?, updated_at = NOW()
     WHERE id = ?`,
    [stats.checkins_count, stats.reviews_count, stats.photos_count, level, rank, userId]
  );

  return {
    ...stats,
    level,
    rank
  };
}

export async function awardEligibleBadges(db, userId) {
  const [userRows] = await db.query(
    `SELECT id, points, level, checkins_count, reviews_count, photos_count
     FROM users
     WHERE id = ?`,
    [userId]
  );

  if (!userRows.length) {
    throw toAppError('Utilisateur non trouve', 404);
  }

  const user = userRows[0];
  const [badgeRows] = await db.query(
    `SELECT b.*
     FROM badges b
     LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = ?
     WHERE b.is_active = TRUE
       AND ub.id IS NULL
       AND b.required_checkins <= ?
       AND b.required_reviews <= ?
       AND b.required_photos <= ?
       AND b.required_points <= ?
       AND b.required_level <= ?
     ORDER BY b.display_order ASC, b.id ASC`,
    [
      userId,
      user.checkins_count || 0,
      user.reviews_count || 0,
      user.photos_count || 0,
      user.points || 0,
      user.level || 1
    ]
  );

  if (!badgeRows.length) {
    return [];
  }

  let bonusPoints = 0;
  for (const badge of badgeRows) {
    await db.query(
      `INSERT INTO user_badges (user_id, badge_id, progress, notification_sent)
       VALUES (?, ?, 100, FALSE)`,
      [userId, badge.id]
    );
    await db.query(
      `UPDATE badges
       SET total_awarded = total_awarded + 1, updated_at = NOW()
       WHERE id = ?`,
      [badge.id]
    );
    bonusPoints += Number(badge.points_reward || 0);
  }

  if (bonusPoints > 0) {
    await awardPoints(db, userId, bonusPoints);
    await syncUserStats(db, userId);
  }

  return badgeRows.map((badge) => ({
    id: badge.id,
    name: badge.name,
    rarity: badge.rarity,
    points_reward: badge.points_reward
  }));
}

export async function syncSiteReviewAggregates(db, siteId) {
  const [rows] = await db.query(
    `SELECT
        COALESCE(AVG(overall_rating), 0) AS average_rating,
        COUNT(*) AS total_reviews
     FROM reviews
     WHERE site_id = ?
       AND deleted_at IS NULL
       AND status = 'PUBLISHED'`,
    [siteId]
  );

  const stats = rows[0] || { average_rating: 0, total_reviews: 0 };
  await db.query(
    `UPDATE tourist_sites
     SET average_rating = ?, total_reviews = ?, last_updated_at = NOW(), updated_at = NOW()
     WHERE id = ?`,
    [Number(stats.average_rating || 0), Number(stats.total_reviews || 0), siteId]
  );

  return stats;
}
