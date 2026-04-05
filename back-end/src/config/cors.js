import runtimeConfig from './runtime.js';

const allowedOriginSet = new Set(runtimeConfig.cors.allowedOrigins);

function isAllowedDevelopmentOrigin(origin) {
  if (!runtimeConfig.isDevelopment) {
    return false;
  }

  try {
    const parsed = new URL(origin);
    const isLocalHost =
      parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1';

    return (
      isLocalHost &&
      (parsed.protocol === 'http:' || parsed.protocol === 'https:')
    );
  } catch (_error) {
    return false;
  }
}

function buildCorsError(origin) {
  const error = new Error('Origine non autorisee par la politique CORS');
  error.statusCode = 403;
  error.code = 'CORS_ORIGIN_NOT_ALLOWED';
  error.details = {
    origin
  };
  return error;
}

export function createCorsOptions() {
  return {
    origin(origin, callback) {
      if (!origin) {
        if (runtimeConfig.cors.allowNoOrigin) {
          return callback(null, true);
        }

        return callback(buildCorsError('NO_ORIGIN'));
      }

      if (allowedOriginSet.has(origin)) {
        return callback(null, true);
      }

      if (isAllowedDevelopmentOrigin(origin)) {
        return callback(null, true);
      }

      return callback(buildCorsError(origin));
    },
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    optionsSuccessStatus: 204
  };
}

export function describeCorsOrigins() {
  if (runtimeConfig.cors.allowedOrigins.length) {
    return runtimeConfig.cors.allowedOrigins.join(', ');
  }

  return '(aucune origine navigateur configuree)';
}
