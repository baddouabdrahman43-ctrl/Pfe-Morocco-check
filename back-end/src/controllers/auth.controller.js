import { successResponse, validationErrorResponse } from '../utils/response.utils.js';
import {
  validateRequest,
  registerSchema,
  loginSchema,
  googleAuthSchema,
  updateProfileSchema,
  refreshTokenSchema
} from '../utils/validators.js';
import {
  registerUser,
  loginUser,
  loginWithGoogleToken,
  getProfileById,
  updateProfileById,
  refreshSession,
  logoutSession
} from '../services/auth.service.js';
import { logAudit } from '../utils/logger.utils.js';
import { validateMediaFieldInput } from '../utils/media-input.utils.js';

const register = async (req, res) => {
  const { error, value } = validateRequest(registerSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await registerUser(value, {
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
    deviceInfo: req.body?.device_info
  });
  logAudit('auth_register_success', req, {
    target_email: result.user?.email || value.email,
    created_user_id: result.user?.id || null
  });
  return successResponse(res, result, 'Inscription reussie', 201);
};

const login = async (req, res) => {
  const { error, value } = validateRequest(loginSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await loginUser(value, {
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
    deviceInfo: value.device_info
  });
  logAudit('auth_login_success', req, {
    target_email: result.user?.email || value.email,
    authenticated_user_id: result.user?.id || null
  });
  return successResponse(res, result, 'Connexion reussie');
};

const googleLogin = async (req, res) => {
  const { error, value } = validateRequest(googleAuthSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await loginWithGoogleToken(value, {
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
    deviceInfo: value.device_info
  });
  logAudit('auth_google_login_success', req, {
    target_email: result.user?.email || null,
    authenticated_user_id: result.user?.id || null
  });
  return successResponse(res, result, 'Connexion Google reussie');
};

const getProfile = async (req, res) => {
  const result = await getProfileById(req.userId);
  return successResponse(res, result);
};

const updateProfile = async (req, res) => {
  const { error, value } = validateRequest(updateProfileSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const mediaValidationError = validateMediaFieldInput(value.profile_picture, {
    fieldName: 'profile_picture',
    entityType: 'user_profile',
    req
  });
  if (mediaValidationError) {
    return validationErrorResponse(res, {
      details: [mediaValidationError]
    });
  }

  const result = await updateProfileById(req.userId, value);
  return successResponse(res, result, 'Profil mis a jour avec succes');
};

const refresh = async (req, res) => {
  const { error, value } = validateRequest(refreshTokenSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await refreshSession(value.refresh_token, {
    ipAddress: req.ip,
    userAgent: req.get('user-agent')
  });
  logAudit('auth_refresh_success', req, {
    refresh_token_used: true
  });
  return successResponse(res, result);
};

const logout = async (req, res) => {
  await logoutSession(req.userId, req.authToken);
  logAudit('auth_logout_success', req);
  return successResponse(res, { logged_out: true }, 'Deconnexion reussie');
};

export {
  register,
  login,
  googleLogin,
  getProfile,
  updateProfile,
  refresh,
  logout
};
