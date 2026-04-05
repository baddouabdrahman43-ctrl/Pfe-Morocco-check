import express from 'express';
import errorMiddleware from '../../src/middleware/error.middleware.js';
import requestContextMiddleware from '../../src/middleware/request-context.middleware.js';

export function createTestApp(mountPath, router) {
  const app = express();
  app.use(express.json());
  app.use(requestContextMiddleware);
  app.use(mountPath, router);
  app.use(errorMiddleware.notFoundHandler);
  app.use(errorMiddleware.errorHandler);
  return app;
}
