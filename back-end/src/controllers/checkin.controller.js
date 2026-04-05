import {
  paginatedResponse,
  successResponse,
  validationErrorResponse
} from '../utils/response.utils.js';
import { validateRequest, checkinSchema } from '../utils/validators.js';
import { normalizeUploadedCheckinPhotos } from '../middleware/upload.middleware.js';
import {
  createCheckin,
  listCheckins,
  getCheckinById
} from '../services/checkin.service.js';

const normalizeCheckinPayload = (body = {}, uploadedPhotos = []) => {
  const payload = { ...body };

  if (typeof payload.has_photo === 'string') {
    payload.has_photo = ['true', '1', 'yes', 'on'].includes(
      payload.has_photo.trim().toLowerCase()
    );
  }

  if (typeof payload.device_info === 'string' && payload.device_info.trim()) {
    try {
      payload.device_info = JSON.parse(payload.device_info);
    } catch (_error) {
      payload.device_info = undefined;
    }
  }

  if (uploadedPhotos.length) {
    payload.has_photo = true;
  }

  return payload;
};

export const createCheckinHandler = async (req, res) => {
  const uploadedPhotos = normalizeUploadedCheckinPhotos(req.files || []);
  const { error, value } = validateRequest(
    checkinSchema,
    normalizeCheckinPayload(req.body, uploadedPhotos)
  );
  if (error) {
    return validationErrorResponse(res, error);
  }

  const result = await createCheckin(value, req.user, {
    ipAddress: req.ip,
    uploadedPhotos
  });
  return successResponse(res, result, 'Check-in enregistre avec succes', 201);
};

export const getCheckins = async (req, res) => {
  const result = await listCheckins(req.query, req.user);
  return paginatedResponse(res, result.data, result.pagination);
};

export const getCheckin = async (req, res) => {
  const result = await getCheckinById(Number(req.params.id), req.user);
  return successResponse(res, result);
};
