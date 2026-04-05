/**
 * Utilitaires de réponse API — format uniforme succès / erreur
 */

/**
 * Envoie une réponse de succès
 * @param {Object} res - Objet response Express
 * @param {*} data - Données à retourner
 * @param {string} [message] - Message optionnel
 * @param {number} [statusCode=200]
 */
export function successResponse(res, data, message = null, statusCode = 200) {
  const body = {
    success: true,
    data,
    timestamp: new Date().toISOString()
  };
  if (message) body.message = message;
  res.status(statusCode).json(body);
}

/**
 * Envoie une réponse paginée
 * @param {Object} res
 * @param {Array} data - Liste des éléments
 * @param {Object} pagination - { page, limit, total }
 */
export function paginatedResponse(res, data, pagination) {
  res.status(200).json({
    success: true,
    data,
    meta: {
      pagination: {
        page: pagination.page,
        limit: pagination.limit,
        total: pagination.total
      },
      timestamp: new Date().toISOString()
    }
  });
}

/**
 * Envoie une réponse d'erreur
 * @param {Object} res
 * @param {string} message - Message d'erreur
 * @param {number} [statusCode=500]
 * @param {string} [code] - Code erreur métier (ex: 'EMAIL_ALREADY_USED')
 * @param {*} [details] - Détails optionnels (ex: erreurs de validation)
 */
export function errorResponse(res, message, statusCode = 500, code = null, details = null) {
  const body = {
    success: false,
    message,
    timestamp: new Date().toISOString()
  };
  if (code) body.code = code;
  if (details !== undefined && details !== null) body.details = details;
  res.status(statusCode).json(body);
}

export function validationErrorResponse(res, error, statusCode = 400) {
  const validationItems = (error?.details || []).map((detail) => ({
    message: detail.message,
    path: Array.isArray(detail.path) ? detail.path.join('.') : String(detail.path || ''),
    type: detail.type
  }));

  return res.status(statusCode).json({
    success: false,
    message: 'Validation echouee',
    code: 'VALIDATION_ERROR',
    errors: validationItems.map((item) => item.message),
    details: {
      validation: validationItems
    },
    timestamp: new Date().toISOString()
  });
}
