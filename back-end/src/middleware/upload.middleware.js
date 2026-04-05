import multer from 'multer';
import path from 'path';
import runtimeConfig from '../config/runtime.js';
import {
  buildCheckinPhotoPublicPath,
  buildReviewPhotoPublicPath,
  checkinUploadsRoot,
  ensureUploadsDirectories,
  getMaxUploadFileSize,
  removeFilesIfExist,
  reviewUploadsRoot,
  sanitizeFilename
} from '../utils/media.utils.js';

ensureUploadsDirectories();

const allowedMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/jpg'
]);

const allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const maxUploadFiles = 5;
const maxUploadFileSize = getMaxUploadFileSize();

const reviewStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, reviewUploadsRoot);
  },
  filename: (_req, file, cb) => {
    cb(null, sanitizeFilename(file.originalname));
  }
});

const checkinStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, checkinUploadsRoot);
  },
  filename: (_req, file, cb) => {
    cb(null, sanitizeFilename(file.originalname));
  }
});

function fileFilter(_req, file, cb) {
  const extension = path.extname(file.originalname || '').toLowerCase();

  if (!allowedExtensions.has(extension)) {
    const error = new Error(
      'Extension d image non supportee. Utilisez JPG, JPEG, PNG ou WEBP.'
    );
    error.statusCode = 400;
    error.code = 'UNSUPPORTED_IMAGE_EXTENSION';
    cb(error);
    return;
  }

  if (!allowedMimeTypes.has(file.mimetype)) {
    const error = new Error('Format d image non supporte. Utilisez JPG, PNG ou WEBP.');
    error.statusCode = 400;
    error.code = 'UNSUPPORTED_IMAGE_TYPE';
    cb(error);
    return;
  }

  cb(null, true);
}

const reviewPhotoUpload = multer({
  storage: reviewStorage,
  fileFilter,
  limits: {
    files: maxUploadFiles,
    fileSize: maxUploadFileSize
  }
});

const checkinPhotoUpload = multer({
  storage: checkinStorage,
  fileFilter,
  limits: {
    files: maxUploadFiles,
    fileSize: maxUploadFileSize
  }
});

function cleanupUploadedFiles(req) {
  const files = Array.isArray(req.files) ? req.files : [];
  removeFilesIfExist(files.map((file) => file.path).filter(Boolean));
}

function wrapUploadArray(upload, fieldName, maxFiles) {
  return (req, res, next) => {
    upload.array(fieldName, maxFiles)(req, res, (error) => {
      if (error) {
        cleanupUploadedFiles(req);
        return next(error);
      }

      return next();
    });
  };
}

export const reviewPhotoUploadMiddleware = wrapUploadArray(
  reviewPhotoUpload,
  'photos',
  maxUploadFiles
);
export const checkinPhotoUploadMiddleware = wrapUploadArray(
  checkinPhotoUpload,
  'photos',
  maxUploadFiles
);

export function normalizeUploadedReviewPhotos(files = []) {
  return files.map((file, index) => ({
    url: buildReviewPhotoPublicPath(file.filename),
    thumbnail_url: buildReviewPhotoPublicPath(file.filename),
    filename: file.filename,
    original_filename: file.originalname,
    mime_type: file.mimetype,
    size: file.size,
    width: null,
    height: null,
    display_order: index,
    is_primary: index === 0
  }));
}

export function normalizeUploadedCheckinPhotos(files = []) {
  return files.map((file, index) => ({
    url: buildCheckinPhotoPublicPath(file.filename),
    thumbnail_url: buildCheckinPhotoPublicPath(file.filename),
    filename: file.filename,
    original_filename: file.originalname,
    mime_type: file.mimetype,
    size: file.size,
    width: null,
    height: null,
    display_order: index,
    is_primary: index === 0
  }));
}
