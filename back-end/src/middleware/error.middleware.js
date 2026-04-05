import { buildLogContext, logError } from '../utils/logger.utils.js';
import { captureException } from '../config/monitoring.js';

const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route non trouvee',
    code: 'ROUTE_NOT_FOUND',
    path: req.originalUrl,
    method: req.method,
    request_id: req.requestId,
    timestamp: new Date().toISOString()
  });
};

const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || err.status || 500;
  const payload = {
    success: false,
    message: err.message || 'Une erreur est survenue',
    request_id: req.requestId,
    timestamp: new Date().toISOString()
  };

  if (err.name === 'ValidationError') {
    statusCode = 400;
    payload.message = 'Donnees de validation invalides';
  } else if (err.name === 'MulterError') {
    statusCode = 400;
    if (err.code === 'LIMIT_FILE_SIZE') {
      payload.message = 'Chaque image doit peser au maximum 5 Mo';
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      payload.message = 'Vous pouvez envoyer au maximum 5 photos par contribution';
    } else {
      payload.message = err.message || 'Erreur pendant l upload des fichiers';
    }
  } else if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    payload.message = 'Token d\'authentification invalide';
  } else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    payload.message = 'Token d\'authentification expire';
  }

  if (err.code) {
    payload.code = err.code;
  }
  if (err.details) {
    payload.details = err.details;
  }
  if (process.env.NODE_ENV === 'development') {
    payload.stack = err.stack;
  }

  logError('request_failed', {
    ...buildLogContext(req, {
      status_code: statusCode,
      code: err.code || null,
      message: payload.message
    }),
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });

  captureException(err, {
    tags: {
      layer: 'express',
      path: req.originalUrl,
      method: req.method,
      status_code: statusCode
    },
    extras: {
      request_id: req.requestId,
      code: err.code || null,
      details: err.details || null
    },
    user: req.userId ? { id: String(req.userId), role: req.userRole } : undefined
  });

  if (res.headersSent) {
    return next(err);
  }

  return res.status(statusCode).json(payload);
};

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export {
  notFoundHandler,
  errorHandler,
  asyncHandler
};

export default {
  notFoundHandler,
  errorHandler,
  asyncHandler
};
