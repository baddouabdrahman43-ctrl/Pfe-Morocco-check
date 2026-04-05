import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import runtimeConfig from '../config/runtime.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..', '..');

export const uploadsRoot = path.join(projectRoot, 'uploads');
export const reviewUploadsRoot = path.join(uploadsRoot, 'reviews');
export const checkinUploadsRoot = path.join(uploadsRoot, 'checkins');
export const siteUploadsRoot = path.join(uploadsRoot, 'sites');

function normalizeBaseUrl(value) {
  return String(value || '').trim().replace(/\/+$/, '');
}

export function ensureUploadsDirectories() {
  fs.mkdirSync(reviewUploadsRoot, { recursive: true });
  fs.mkdirSync(checkinUploadsRoot, { recursive: true });
  fs.mkdirSync(siteUploadsRoot, { recursive: true });
}

export function getMaxUploadFileSize() {
  return runtimeConfig.uploads.maxFileSize;
}

export function getPublicBaseUrl() {
  const configuredBaseUrl =
    process.env.PUBLIC_BASE_URL ||
    process.env.APP_BASE_URL ||
    process.env.BACKEND_PUBLIC_URL;

  if (configuredBaseUrl) {
    return normalizeBaseUrl(configuredBaseUrl);
  }

  const port = process.env.PORT || 5001;
  return `http://127.0.0.1:${port}`;
}

export function toPublicMediaUrl(value) {
  if (!value) {
    return value;
  }

  const rawValue = String(value).trim();
  if (!rawValue) {
    return rawValue;
  }

  if (/^https?:\/\//i.test(rawValue)) {
    return rawValue;
  }

  const normalizedPath = rawValue.startsWith('/') ? rawValue : `/${rawValue}`;
  return `${getPublicBaseUrl()}${normalizedPath}`;
}

export function sanitizeFilename(originalName = 'photo') {
  const extension = path.extname(originalName) || '.jpg';
  const basename = path
    .basename(originalName, extension)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);

  const safeBase = basename || 'photo';
  const uniqueSuffix = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  return `${uniqueSuffix}-${safeBase}${extension.toLowerCase()}`;
}

export function removeFilesIfExist(filePaths = []) {
  for (const filePath of filePaths) {
    removeFileIfExists(filePath);
  }
}

export function buildReviewPhotoPublicPath(filename) {
  return `/uploads/reviews/${filename}`;
}

export function buildCheckinPhotoPublicPath(filename) {
  return `/uploads/checkins/${filename}`;
}

export function buildSitePhotoPublicPath(filename) {
  return `/uploads/sites/${filename}`;
}

export function resolveStoredReviewPhotoPath(filename) {
  return path.join(reviewUploadsRoot, path.basename(filename));
}

export function resolveStoredCheckinPhotoPath(filename) {
  return path.join(checkinUploadsRoot, path.basename(filename));
}

export function resolveStoredSitePhotoPath(filename) {
  return path.join(siteUploadsRoot, path.basename(filename));
}

export function removeFileIfExists(filePath) {
  if (!filePath) {
    return;
  }

  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch (_error) {
  }
}
