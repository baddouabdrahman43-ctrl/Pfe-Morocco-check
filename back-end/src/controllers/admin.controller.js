import {
  paginatedResponse,
  successResponse,
  validationErrorResponse
} from '../utils/response.utils.js';
import {
  validateRequest,
  adminSiteReviewSchema,
  adminReviewModerationSchema,
  userRoleUpdateSchema,
  userStatusUpdateSchema,
  contributorRequestReviewSchema
} from '../utils/validators.js';
import {
  listPendingSites,
  getAdminSiteDetail,
  reviewSite,
  listPendingReviews,
  getAdminReviewDetail,
  moderateReview,
  listUsers,
  getUserById,
  updateUserRole,
  updateUserStatus,
  getAdminStats,
  deleteReviewPhoto
} from '../services/admin.service.js';
import {
  listContributorRequests,
  reviewContributorRequest
} from '../services/contributor-request.service.js';
import { logAudit } from '../utils/logger.utils.js';

export const getPendingSites = async (req, res) => {
  const result = await listPendingSites(req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const reviewSiteHandler = async (req, res) => {
  const { error, value } = validateRequest(adminSiteReviewSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await reviewSite(Number(req.params.id), req.userId, value);
  logAudit('admin_site_reviewed', req, {
    site_id: Number(req.params.id),
    action: value.action
  });
  return successResponse(res, result, 'Decision de moderation appliquee');
};

export const getAdminSiteDetailHandler = async (req, res) => {
  const result = await getAdminSiteDetail(Number(req.params.id));
  return successResponse(res, result);
};

export const getPendingReviews = async (req, res) => {
  const result = await listPendingReviews(req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const moderateReviewHandler = async (req, res) => {
  const { error, value } = validateRequest(adminReviewModerationSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await moderateReview(Number(req.params.id), req.userId, value);
  logAudit('admin_review_moderated', req, {
    review_id: Number(req.params.id),
    action: value.action
  });
  return successResponse(res, result, 'Moderation appliquee');
};

export const getAdminReviewDetailHandler = async (req, res) => {
  const result = await getAdminReviewDetail(Number(req.params.id));
  return successResponse(res, result);
};

export const deleteReviewPhotoHandler = async (req, res) => {
  const result = await deleteReviewPhoto(
    Number(req.params.id),
    Number(req.params.photoId),
    req.userId
  );
  logAudit('admin_review_photo_deleted', req, {
    review_id: Number(req.params.id),
    photo_id: Number(req.params.photoId)
  });
  return successResponse(res, result, 'Photo supprimee avec succes');
};

export const getUsers = async (req, res) => {
  const result = await listUsers(req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getUserByIdHandler = async (req, res) => {
  const result = await getUserById(Number(req.params.id));
  return successResponse(res, result);
};

export const getContributorRequestsHandler = async (req, res) => {
  const result = await listContributorRequests(req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const reviewContributorRequestHandler = async (req, res) => {
  const { error, value } = validateRequest(contributorRequestReviewSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await reviewContributorRequest(
    Number(req.params.id),
    req.userId,
    value
  );
  logAudit('admin_contributor_request_reviewed', req, {
    contributor_request_id: Number(req.params.id),
    action: value.action
  });
  return successResponse(res, result, 'Demande contributor traitee');
};

export const updateUserStatusHandler = async (req, res) => {
  const { error, value } = validateRequest(userStatusUpdateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await updateUserStatus(Number(req.params.id), value.status);
  logAudit('admin_user_status_updated', req, {
    target_user_id: Number(req.params.id),
    next_status: value.status
  });
  return successResponse(res, result, 'Statut utilisateur mis a jour');
};

export const updateUserRoleHandler = async (req, res) => {
  const { error, value } = validateRequest(userRoleUpdateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await updateUserRole(Number(req.params.id), value.role);
  logAudit('admin_user_role_updated', req, {
    target_user_id: Number(req.params.id),
    next_role: value.role
  });
  return successResponse(res, result, 'Role utilisateur mis a jour');
};

export const getAdminStatsHandler = async (_req, res) => {
  const result = await getAdminStats();
  return successResponse(res, result);
};
