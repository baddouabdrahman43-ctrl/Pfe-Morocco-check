import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { buildLogContext, logWarn } from './logger.utils.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..', '..');
const uploadsRoot = path.resolve(projectRoot, 'uploads');

function normalizeValue(value) {
  return String(value || '').trim();
}

export function isUploadMediaPath(value) {
  return /^\/uploads\//i.test(normalizeValue(value));
}

export function isExternalMediaUrl(value) {
  return /^https?:\/\//i.test(normalizeValue(value));
}

export function resolveUploadPath(value) {
  const normalizedValue = normalizeValue(value);
  if (!isUploadMediaPath(normalizedValue)) {
    return null;
  }

  const relativePath = normalizedValue.replace(/^\/+/, '');
  const absolutePath = path.resolve(projectRoot, relativePath);
  const normalizedUploadsRoot = `${uploadsRoot}${path.sep}`;

  if (
    absolutePath !== uploadsRoot &&
    !absolutePath.startsWith(normalizedUploadsRoot)
  ) {
    return null;
  }

  return absolutePath;
}

export function buildMediaValidationError(fieldName, message) {
  return {
    message,
    path: [fieldName],
    type: 'any.invalid'
  };
}

export function validateMediaFieldInput(
  value,
  { fieldName, entityType = 'entity', req } = {}
) {
  const normalizedValue = normalizeValue(value);
  if (!normalizedValue) {
    return null;
  }

  if (isUploadMediaPath(normalizedValue)) {
    const absolutePath = resolveUploadPath(normalizedValue);
    if (!absolutePath || !fs.existsSync(absolutePath)) {
      return buildMediaValidationError(
        fieldName,
        `Le fichier ${fieldName} ne correspond a aucun media disponible.`
      );
    }

    return null;
  }

  if (isExternalMediaUrl(normalizedValue)) {
    logWarn(
      'external_media_url_submitted',
      buildLogContext(req, {
        entity_type: entityType,
        field_name: fieldName,
        media_url: normalizedValue
      })
    );
    return null;
  }

  return buildMediaValidationError(
    fieldName,
    `Le champ ${fieldName} doit etre une URL http(s) ou un chemin /uploads/.`
  );
}
