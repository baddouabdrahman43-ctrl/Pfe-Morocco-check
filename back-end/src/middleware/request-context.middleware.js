import { randomUUID } from 'crypto';

export function requestContextMiddleware(req, res, next) {
  req.requestId = randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  return next();
}

export default requestContextMiddleware;
