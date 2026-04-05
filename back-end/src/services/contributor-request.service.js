import pool from '../config/database.js';
import { USER_ROLES, USER_STATUS } from '../config/constants.js';
import { paginationMeta, parsePagination, toAppError } from './common.service.js';

const CONTRIBUTOR_REQUEST_STATUS = {
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
  CANCELLED: 'CANCELLED'
};

const PROFILE_REQUIREMENTS = [
  {
    field: 'phone_number',
    label: 'phone_number',
    isValid: (value) => Boolean(String(value || '').trim())
  },
  {
    field: 'nationality',
    label: 'nationality',
    isValid: (value) => String(value || '').trim().length === 2
  },
  {
    field: 'bio',
    label: 'bio',
    isValid: (value) => String(value || '').trim().length >= 20
  }
];

function getMissingProfileFields(user) {
  return PROFILE_REQUIREMENTS.filter((requirement) => !requirement.isValid(user[requirement.field]))
    .map((requirement) => requirement.label);
}

async function getUserForRequestFlow(userId, db = pool) {
  const [rows] = await db.query(
    `SELECT
        id,
        email,
        first_name,
        last_name,
        phone_number,
        nationality,
        bio,
        role,
        status,
        is_email_verified
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

async function getPendingRequestForUser(userId, db = pool) {
  const [rows] = await db.query(
    `SELECT id
     FROM contributor_requests
     WHERE user_id = ? AND status = ?
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId, CONTRIBUTOR_REQUEST_STATUS.PENDING]
  );

  return rows[0] || null;
}

async function getContributorRequestById(requestId, db = pool) {
  const [rows] = await db.query(
    `SELECT
        cr.id,
        cr.user_id,
        cr.requested_role,
        cr.status,
        cr.motivation,
        cr.admin_notes,
        cr.reviewed_at,
        cr.created_at,
        applicant.email,
        applicant.first_name,
        applicant.last_name,
        applicant.phone_number,
        applicant.nationality,
        applicant.bio,
        applicant.role AS applicant_role,
        applicant.status AS account_status,
        applicant.is_email_verified,
        reviewer.first_name AS reviewer_first_name,
        reviewer.last_name AS reviewer_last_name
     FROM contributor_requests cr
     INNER JOIN users applicant ON applicant.id = cr.user_id
     LEFT JOIN users reviewer ON reviewer.id = cr.reviewed_by
     WHERE cr.id = ?
     LIMIT 1`,
    [requestId]
  );

  return rows[0] || null;
}

function buildEligibility(user, hasPendingRequest) {
  const missing_fields = getMissingProfileFields(user);
  const isRoleEligible = user.role === USER_ROLES.TOURIST;
  const isStatusEligible = user.status === USER_STATUS.ACTIVE;
  const isEmailVerified = Boolean(user.is_email_verified);
  const isProfileComplete = missing_fields.length === 0;

  return {
    current_role: user.role,
    status: user.status,
    is_active: isStatusEligible,
    is_email_verified: isEmailVerified,
    is_profile_complete: isProfileComplete,
    missing_fields,
    has_pending_request: hasPendingRequest,
    can_request:
      isRoleEligible &&
      isStatusEligible &&
      isEmailVerified &&
      isProfileComplete &&
      !hasPendingRequest
  };
}

function ensureContributorRequestEligibility(user, hasPendingRequest) {
  if (user.role !== USER_ROLES.TOURIST) {
    throw toAppError(
      'Seuls les comptes TOURIST peuvent demander le role CONTRIBUTOR',
      409,
      'ROLE_NOT_ELIGIBLE'
    );
  }

  if (user.status !== USER_STATUS.ACTIVE) {
    throw toAppError(
      'Le compte doit etre ACTIVE pour envoyer cette demande',
      403,
      'ACCOUNT_NOT_ACTIVE'
    );
  }

  if (!user.is_email_verified) {
    throw toAppError(
      'L email doit etre verifie avant de demander le role CONTRIBUTOR',
      403,
      'EMAIL_NOT_VERIFIED'
    );
  }

  const missingFields = getMissingProfileFields(user);
  if (missingFields.length) {
    throw toAppError(
      'Le profil minimum doit etre complete avant de faire cette demande',
      400,
      'PROFILE_INCOMPLETE',
      { missing_fields: missingFields }
    );
  }

  if (hasPendingRequest) {
    throw toAppError(
      'Une demande de passage en CONTRIBUTOR est deja en attente',
      409,
      'REQUEST_ALREADY_PENDING'
    );
  }
}

export async function getMyContributorRequestStatus(userId) {
  const user = await getUserForRequestFlow(userId);
  const [requestRows] = await pool.query(
    `SELECT
        cr.id,
        cr.user_id,
        cr.requested_role,
        cr.status,
        cr.motivation,
        cr.admin_notes,
        cr.reviewed_at,
        cr.created_at,
        reviewer.first_name AS reviewer_first_name,
        reviewer.last_name AS reviewer_last_name
     FROM contributor_requests cr
     LEFT JOIN users reviewer ON reviewer.id = cr.reviewed_by
     WHERE cr.user_id = ?
     ORDER BY cr.created_at DESC
     LIMIT 1`,
    [userId]
  );

  const latestRequest = requestRows[0] || null;

  return {
    request: latestRequest,
    eligibility: buildEligibility(
      user,
      latestRequest?.status === CONTRIBUTOR_REQUEST_STATUS.PENDING
    )
  };
}

export async function createContributorRequest(userId, payload) {
  const user = await getUserForRequestFlow(userId);
  const pendingRequest = await getPendingRequestForUser(userId);

  ensureContributorRequestEligibility(user, Boolean(pendingRequest));

  const motivation = payload.motivation.trim();
  const [result] = await pool.query(
    `INSERT INTO contributor_requests (
        user_id,
        requested_role,
        status,
        motivation
      ) VALUES (?, 'CONTRIBUTOR', ?, ?)`,
    [userId, CONTRIBUTOR_REQUEST_STATUS.PENDING, motivation]
  );

  const createdRequest = await getContributorRequestById(result.insertId);

  return {
    request: createdRequest,
    eligibility: buildEligibility(user, true)
  };
}

export async function listContributorRequests(query = {}) {
  const { page, limit, offset } = parsePagination(query);
  const filters = ['1 = 1'];
  const params = [];

  if (query.status) {
    filters.push('cr.status = ?');
    params.push(query.status);
  }

  if (query.q) {
    const search = `%${query.q.trim()}%`;
    filters.push(`(
      applicant.email LIKE ?
      OR applicant.first_name LIKE ?
      OR applicant.last_name LIKE ?
      OR CONCAT_WS(' ', applicant.first_name, applicant.last_name) LIKE ?
      OR COALESCE(cr.requested_role, '') LIKE ?
    )`);
    params.push(search, search, search, search, search);
  }

  const whereClause = `WHERE ${filters.join(' AND ')}`;
  const sortMap = {
    oldest: `CASE WHEN cr.status = 'PENDING' THEN 0 ELSE 1 END, cr.created_at ASC`,
    newest: `CASE WHEN cr.status = 'PENDING' THEN 0 ELSE 1 END, cr.created_at DESC`,
    name: `CASE WHEN cr.status = 'PENDING' THEN 0 ELSE 1 END, applicant.last_name ASC, applicant.first_name ASC`
  };
  const orderBy = sortMap[query.sort] || sortMap.oldest;

  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total
     FROM contributor_requests cr
     INNER JOIN users applicant ON applicant.id = cr.user_id
     ${whereClause}`,
    params
  );

  const [rows] = await pool.query(
    `SELECT
        cr.id,
        cr.user_id,
        cr.requested_role,
        cr.status,
        cr.motivation,
        cr.admin_notes,
        cr.reviewed_at,
        cr.created_at,
        applicant.email,
        applicant.first_name,
        applicant.last_name,
        applicant.phone_number,
        applicant.nationality,
        applicant.bio,
        applicant.role AS applicant_role,
        applicant.status AS account_status,
        applicant.is_email_verified,
        reviewer.first_name AS reviewer_first_name,
        reviewer.last_name AS reviewer_last_name
     FROM contributor_requests cr
     INNER JOIN users applicant ON applicant.id = cr.user_id
     LEFT JOIN users reviewer ON reviewer.id = cr.reviewed_by
     ${whereClause}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  return {
    data: rows.map((row) => ({
      ...row,
      eligibility: buildEligibility(
        {
          role: row.applicant_role,
          status: row.account_status,
          is_email_verified: row.is_email_verified,
          phone_number: row.phone_number,
          nationality: row.nationality,
          bio: row.bio
        },
        row.status === CONTRIBUTOR_REQUEST_STATUS.PENDING
      )
    })),
    pagination: paginationMeta(Number(countRows[0]?.total || 0), page, limit)
  };
}

export async function reviewContributorRequest(requestId, adminUserId, payload) {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [requestRows] = await connection.query(
      `SELECT
          cr.id,
          cr.user_id,
          cr.status,
          u.role,
          u.status AS account_status,
          u.is_email_verified,
          u.phone_number,
          u.nationality,
          u.bio
       FROM contributor_requests cr
       INNER JOIN users u ON u.id = cr.user_id
       WHERE cr.id = ?
       LIMIT 1`,
      [requestId]
    );

    if (!requestRows.length) {
      throw toAppError('Demande non trouvee', 404);
    }

    const request = requestRows[0];
    if (request.status !== CONTRIBUTOR_REQUEST_STATUS.PENDING) {
      throw toAppError(
        'Cette demande a deja ete traitee',
        409,
        'REQUEST_ALREADY_REVIEWED'
      );
    }

    if (payload.action === 'APPROVE') {
      ensureContributorRequestEligibility(
        {
          role: request.role,
          status: request.account_status,
          is_email_verified: request.is_email_verified,
          phone_number: request.phone_number,
          nationality: request.nationality,
          bio: request.bio
        },
        false
      );

      await connection.query(
        `UPDATE users
         SET role = ?, updated_at = NOW()
         WHERE id = ?`,
        [USER_ROLES.CONTRIBUTOR, request.user_id]
      );
    }

    const nextStatus =
      payload.action === 'APPROVE'
        ? CONTRIBUTOR_REQUEST_STATUS.APPROVED
        : CONTRIBUTOR_REQUEST_STATUS.REJECTED;

    await connection.query(
      `UPDATE contributor_requests
       SET status = ?, admin_notes = ?, reviewed_by = ?, reviewed_at = NOW(), updated_at = NOW()
       WHERE id = ?`,
      [nextStatus, payload.admin_notes?.trim() || null, adminUserId, requestId]
    );

    await connection.commit();

    return getContributorRequestById(requestId);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}
