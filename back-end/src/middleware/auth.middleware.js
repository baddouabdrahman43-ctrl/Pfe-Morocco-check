import { verifyToken } from '../utils/jwt.utils.js';
import { errorResponse } from '../utils/response.utils.js';
import pool from '../config/database.js';
import { USER_STATUS } from '../config/constants.js';

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization?.trim();
    if (!authHeader || !/^Bearer\s+/i.test(authHeader)) {
      return errorResponse(res, 'Token manquant', 401, 'TOKEN_MISSING');
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      return errorResponse(res, 'Token manquant', 401, 'TOKEN_MISSING');
    }

    const decoded = verifyToken(token);

    const [rows] = await pool.query(
      `SELECT
          s.id,
          s.user_id,
          s.is_active,
          s.expires_at,
          u.email,
          u.role,
          u.status
       FROM sessions s
       INNER JOIN users u ON u.id = s.user_id
       WHERE s.access_token = ?
         AND s.is_active = TRUE
         AND s.expires_at > NOW()
         AND u.deleted_at IS NULL
       LIMIT 1`,
      [token]
    );

    if (!rows.length) {
      return errorResponse(
        res,
        'Session invalide ou expiree',
        401,
        'SESSION_INACTIVE'
      );
    }

    const session = rows[0];
    if (
      [USER_STATUS.SUSPENDED, USER_STATUS.BANNED, USER_STATUS.INACTIVE].includes(
        session.status
      )
    ) {
      return errorResponse(res, 'Compte indisponible', 403, 'ACCOUNT_DISABLED');
    }

    await pool.query(
      `UPDATE sessions
       SET last_activity_at = NOW(), updated_at = NOW()
       WHERE id = ?`,
      [session.id]
    );

    req.user = {
      id: session.user_id,
      email: session.email,
      role: session.role
    };
    req.authToken = token;
    req.userId = session.user_id;
    req.userRole = session.role;
    req.sessionId = session.id;
    return next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Token invalide', 401, 'TOKEN_INVALID');
    }
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expire', 401, 'TOKEN_EXPIRED');
    }
    return errorResponse(res, 'Erreur lors de la verification du token', 500);
  }
};

const authorizeRoles = (...roles) => (req, res, next) => {
  if (!req.userRole) {
    return errorResponse(res, 'Utilisateur non authentifie', 401);
  }
  if (!roles.includes(req.userRole)) {
    return errorResponse(res, 'Acces refuse', 403, 'FORBIDDEN');
  }
  return next();
};

const adminMiddleware = authorizeRoles('ADMIN');

export {
  authMiddleware,
  authorizeRoles,
  adminMiddleware
};

export default {
  authMiddleware,
  authorizeRoles,
  adminMiddleware
};
