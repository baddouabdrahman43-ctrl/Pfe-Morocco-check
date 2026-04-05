import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const testEnvPath = path.resolve(__dirname, '../../.env.test');

if (process.env.NODE_ENV === 'test' && fs.existsSync(testEnvPath)) {
  dotenv.config({ path: testEnvPath, override: true });
}

const DEFAULT_DEV_CORS_ORIGINS = [
  'http://127.0.0.1:3000',
  'http://localhost:3000',
  'http://127.0.0.1:3001',
  'http://localhost:3001',
  'http://127.0.0.1:3010',
  'http://localhost:3010',
  'http://127.0.0.1:5173',
  'http://localhost:5173'
];
const MINIMUM_ALLOWED_CORS_ORIGINS = [
  'http://127.0.0.1:3001',
  'http://localhost:3001'
];

function parseNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseBoolean(value, fallback = false) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }

  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'y', 'on'].includes(normalized)) {
    return true;
  }
  if (['false', '0', 'no', 'n', 'off'].includes(normalized)) {
    return false;
  }

  return fallback;
}

function parseList(value) {
  return String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function uniqueList(values) {
  return [...new Set(values.map((item) => String(item).trim()).filter(Boolean))];
}

function parseJson(value, fallback = null) {
  const rawValue = String(value || '').trim();
  if (!rawValue) {
    return fallback;
  }

  try {
    return JSON.parse(rawValue);
  } catch (_error) {
    return fallback;
  }
}

function resolveAllowedOrigins(nodeEnv, rawOrigins) {
  const configuredOrigins = parseList(rawOrigins);
  if (configuredOrigins.length) {
    return uniqueList([
      ...configuredOrigins,
      ...MINIMUM_ALLOWED_CORS_ORIGINS
    ]);
  }

  if (nodeEnv === 'development') {
    return uniqueList([
      ...DEFAULT_DEV_CORS_ORIGINS,
      ...MINIMUM_ALLOWED_CORS_ORIGINS
    ]);
  }

  return uniqueList(MINIMUM_ALLOWED_CORS_ORIGINS);
}

const nodeEnv = process.env.NODE_ENV || 'development';

export const runtimeConfig = {
  nodeEnv,
  isDevelopment: nodeEnv === 'development',
  isTest: nodeEnv === 'test',
  isProduction: nodeEnv === 'production',
  port: parseNumber(process.env.PORT, 5001),
  db: {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'moroccocheck',
    port: parseNumber(process.env.DB_PORT, 3306),
    exitOnFailure: parseBoolean(process.env.DB_EXIT_ON_FAILURE, true)
  },
  jwt: {
    secret: process.env.JWT_SECRET || '',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshTokenTtlDays: parseNumber(process.env.REFRESH_TOKEN_TTL_DAYS, 30)
  },
  google: {
    clientIds: parseList(process.env.GOOGLE_CLIENT_IDS)
  },
  firebase: {
    projectId: (process.env.FIREBASE_PROJECT_ID || '').trim(),
    clientEmail: (process.env.FIREBASE_CLIENT_EMAIL || '').trim(),
    privateKey: process.env.FIREBASE_PRIVATE_KEY || '',
    serviceAccountJson:
      parseJson(process.env.FIREBASE_SERVICE_ACCOUNT_JSON) ||
      parseJson(
        process.env.FIREBASE_SERVICE_ACCOUNT_BASE64
          ? Buffer.from(
              process.env.FIREBASE_SERVICE_ACCOUNT_BASE64,
              'base64'
            ).toString('utf8')
          : '',
        null
      )
  },
  uploads: {
    dir: process.env.UPLOAD_DIR || './uploads',
    maxFileSize: parseNumber(process.env.MAX_FILE_SIZE, 5 * 1024 * 1024)
  },
  rateLimit: {
    enabled: parseBoolean(
      process.env.RATE_LIMIT_ENABLED,
      nodeEnv !== 'test'
    ),
    store: (process.env.RATE_LIMIT_STORE || 'memory').trim().toLowerCase(),
    redisUrl: process.env.RATE_LIMIT_REDIS_URL || '',
    redisKeyPrefix:
      process.env.RATE_LIMIT_REDIS_KEY_PREFIX || 'moroccocheck:rate-limit',
    windowMs: parseNumber(process.env.RATE_LIMIT_WINDOW_MS, 900000),
    maxRequests: parseNumber(process.env.RATE_LIMIT_MAX_REQUESTS, 100),
    loginMax: parseNumber(process.env.RATE_LIMIT_LOGIN_MAX, 5),
    registerMax: parseNumber(process.env.RATE_LIMIT_REGISTER_MAX, 5),
    adminMax: parseNumber(process.env.RATE_LIMIT_ADMIN_MAX, 30)
  },
  monitoring: {
    dsn: process.env.SENTRY_DSN || '',
    environment:
      process.env.SENTRY_ENVIRONMENT || nodeEnv,
    tracesSampleRate: parseNumber(
      process.env.SENTRY_TRACES_SAMPLE_RATE,
      0
    ),
    enabled: Boolean(process.env.SENTRY_DSN || '')
  },
  cors: {
    allowNoOrigin: parseBoolean(
      process.env.CORS_ALLOW_NO_ORIGIN,
      nodeEnv !== 'production'
    ),
    allowedOrigins: resolveAllowedOrigins(
      nodeEnv,
      process.env.CORS_ALLOWED_ORIGINS
    ),
    defaultDevOrigins: DEFAULT_DEV_CORS_ORIGINS
  }
};

export default runtimeConfig;
