import {
  paginatedResponse,
  successResponse,
  validationErrorResponse
} from '../utils/response.utils.js';
import {
  validateRequest,
  updatePasswordSchema,
  contributorRequestCreateSchema
} from '../utils/validators.js';
import {
  listBadges,
  getUserBadges,
  getLeaderboard,
  getMe,
  updateMyPassword,
  getMyStats,
  getPublicUserProfile
} from '../services/user.service.js';
import {
  createContributorRequest,
  getMyContributorRequestStatus
} from '../services/contributor-request.service.js';

export const getBadges = async (_req, res) => {
  const result = await listBadges();
  return successResponse(res, result);
};

export const getMyBadges = async (req, res) => {
  const result = await getUserBadges(req.userId);
  return successResponse(res, result);
};

export const getLeaderboardHandler = async (req, res) => {
  const result = await getLeaderboard(req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getMeHandler = async (req, res) => {
  const result = await getMe(req.userId);
  return successResponse(res, result);
};

export const updateMyPasswordHandler = async (req, res) => {
  const { error, value } = validateRequest(updatePasswordSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await updateMyPassword(req.userId, value);
  return successResponse(res, result, 'Mot de passe mis a jour avec succes');
};

export const getMyStatsHandler = async (req, res) => {
  const result = await getMyStats(req.userId);
  return successResponse(res, result);
};

export const getMyContributorRequestHandler = async (req, res) => {
  const result = await getMyContributorRequestStatus(req.userId);
  return successResponse(res, result);
};

export const createContributorRequestHandler = async (req, res) => {
  const { error, value } = validateRequest(contributorRequestCreateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await createContributorRequest(req.userId, value);
  return successResponse(
    res,
    result,
    'Demande de passage en CONTRIBUTOR envoyee',
    201
  );
};

export const getPublicUserProfileHandler = async (req, res) => {
  const result = await getPublicUserProfile(Number(req.params.id));
  return successResponse(res, result);
};
