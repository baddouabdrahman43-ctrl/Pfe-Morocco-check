import {
  paginatedResponse,
  successResponse,
  validationErrorResponse,
} from "../utils/response.utils.js";
import {
  validateRequest,
  siteCreateSchema,
  siteUpdateSchema,
} from "../utils/validators.js";
import {
  listSites,
  listMySites,
  getSiteById,
  getMySiteById,
  claimSite,
  createSite,
  updateSite,
  deleteSite,
  getSiteReviews,
  getSitePhotos,
} from "../services/site.service.js";
import { validateMediaFieldInput } from "../utils/media-input.utils.js";

export const getSites = async (req, res) => {
  const result = await listSites(req.query, req.user);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getMySitesHandler = async (req, res) => {
  const result = await listMySites(req.user, req.query);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getMySiteHandler = async (req, res) => {
  const result = await getMySiteById(Number(req.params.id), req.user);
  return successResponse(res, result);
};

export const getSite = async (req, res) => {
  const result = await getSiteById(Number(req.params.id), req.user);
  return successResponse(res, result);
};

export const claimSiteHandler = async (req, res) => {
  const result = await claimSite(Number(req.params.id), req.user);
  return successResponse(res, result, "Site revendique avec succes");
};

export const createSiteHandler = async (req, res) => {
  const { error, value } = validateRequest(siteCreateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const mediaValidationError = validateMediaFieldInput(value.cover_photo, {
    fieldName: 'cover_photo',
    entityType: 'site',
    req,
  });
  if (mediaValidationError) {
    return validationErrorResponse(res, {
      details: [mediaValidationError],
    });
  }

  const result = await createSite(value, req.user);
  return successResponse(res, result, "Site cree avec succes", 201);
};

export const updateSiteHandler = async (req, res) => {
  const { error, value } = validateRequest(siteUpdateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const mediaValidationError = validateMediaFieldInput(value.cover_photo, {
    fieldName: 'cover_photo',
    entityType: 'site',
    req,
  });
  if (mediaValidationError) {
    return validationErrorResponse(res, {
      details: [mediaValidationError],
    });
  }

  const result = await updateSite(Number(req.params.id), value, req.user);
  return successResponse(res, result, "Site mis a jour avec succes");
};

export const deleteSiteHandler = async (req, res) => {
  const result = await deleteSite(Number(req.params.id), req.user);
  return successResponse(res, result, "Site archive avec succes");
};

export const getSiteReviewsHandler = async (req, res) => {
  const result = await getSiteReviews(
    Number(req.params.id),
    req.query,
    req.user,
  );
  return paginatedResponse(res, result.data, result.pagination);
};

export const getSitePhotosHandler = async (req, res) => {
  const result = await getSitePhotos(Number(req.params.id), req.query);
  return paginatedResponse(res, result.data, result.pagination);
};
