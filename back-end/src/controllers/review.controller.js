import {
  paginatedResponse,
  successResponse,
  validationErrorResponse,
} from "../utils/response.utils.js";
import {
  validateRequest,
  reviewSchema,
  reviewUpdateSchema,
  reviewOwnerResponseSchema,
} from "../utils/validators.js";
import { normalizeUploadedReviewPhotos } from "../middleware/upload.middleware.js";
import {
  createReview,
  listReviews,
  getReviewById,
  respondToReview,
  updateReview,
  deleteReview,
} from "../services/review.service.js";

const normalizeReviewPayload = (body = {}) => {
  const payload = { ...body };

  if (
    typeof payload.recommendations === "string" &&
    payload.recommendations.trim()
  ) {
    try {
      payload.recommendations = JSON.parse(payload.recommendations);
    } catch (_error) {
      payload.recommendations = payload.recommendations
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean);
    }
  }

  return payload;
};

export const createReviewHandler = async (req, res) => {
  const { error, value } = validateRequest(
    reviewSchema,
    normalizeReviewPayload(req.body),
  );
  if (error) {
    return validationErrorResponse(res, error);
  }

  const uploadedPhotos = normalizeUploadedReviewPhotos(req.files || []);
  const result = await createReview(value, req.user, uploadedPhotos);
  return successResponse(res, result, "Avis cree avec succes", 201);
};

export const getReviews = async (req, res) => {
  const result = await listReviews(req.query, req.user);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getReview = async (req, res) => {
  const result = await getReviewById(Number(req.params.id), req.user);
  return successResponse(res, result);
};

export const respondToReviewHandler = async (req, res) => {
  const { error, value } = validateRequest(reviewOwnerResponseSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await respondToReview(Number(req.params.id), value, req.user);
  return successResponse(res, result, "Reponse professionnelle enregistree");
};

export const updateReviewHandler = async (req, res) => {
  const { error, value } = validateRequest(reviewUpdateSchema, req.body);
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await updateReview(Number(req.params.id), value, req.user);
  return successResponse(res, result, "Avis mis a jour avec succes");
};

export const deleteReviewHandler = async (req, res) => {
  const result = await deleteReview(Number(req.params.id), req.user);
  return successResponse(res, result, "Avis supprime avec succes");
};
