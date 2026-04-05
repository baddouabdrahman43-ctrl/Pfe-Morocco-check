import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import helmet from 'helmet';
import path from 'path';
import { fileURLToPath } from 'url';
import pool from './src/config/database.js';
import runtimeConfig from './src/config/runtime.js';
import { createCorsOptions, describeCorsOrigins } from './src/config/cors.js';
import healthRoutes from './src/routes/health.routes.js';
import authRoutes from './src/routes/auth.routes.js';
import sitesRoutes from './src/routes/sites.routes.js';
import categoriesRoutes from './src/routes/categories.routes.js';
import checkinsRoutes from './src/routes/checkins.routes.js';
import reviewsRoutes from './src/routes/reviews.routes.js';
import usersRoutes from './src/routes/users.routes.js';
import adminRoutes from './src/routes/admin.routes.js';
import errorMiddleware from './src/middleware/error.middleware.js';
import requestContextMiddleware from './src/middleware/request-context.middleware.js';
import { ensureUploadsDirectories } from './src/utils/media.utils.js';
import { logInfo } from './src/utils/logger.utils.js';
import { initMonitoring, isMonitoringEnabled } from './src/config/monitoring.js';

// Configuration
const app = express();
const PORT = runtimeConfig.port;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const corsOptions = createCorsOptions();

ensureUploadsDirectories();
initMonitoring();

// Middleware
app.use(helmet());
app.use(cors(corsOptions));
app.use(requestContextMiddleware);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(
  morgan((tokens, req, res) =>
    JSON.stringify({
      level: 'info',
      event: 'http_request',
      timestamp: new Date().toISOString(),
      request_id: req.requestId,
      method: tokens.method(req, res),
      path: tokens.url(req, res),
      status: Number(tokens.status(req, res)),
      response_time_ms: Number(tokens['response-time'](req, res)),
      content_length: tokens.res(req, res, 'content-length') || null,
      ip: req.ip,
      user_id: req.userId || null,
      user_role: req.userRole || null
    })
  )
);
app.use('/uploads', (req, res, next) => {
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  res.setHeader('Access-Control-Allow-Origin', '*');
  next();
});
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes de test

// Health check routes
app.use('/api/health', healthRoutes);

// Authentication routes
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/sites', sitesRoutes);
app.use('/api/checkins', checkinsRoutes);
app.use('/api/reviews', reviewsRoutes);
app.use('/api', usersRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware (must be after all routes)
app.use(errorMiddleware.notFoundHandler);
app.use(errorMiddleware.errorHandler);

// Start server
app.listen(PORT, () => {
    const box = `
╔══════════════════════════════════════════════════════════════╗
║                    🚀 MOROCCOCHECK API                      ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  📦 Port: ${PORT.toString().padEnd(48)} ║
║  🌍 Environment: ${process.env.NODE_ENV || 'development'}${' '.repeat(35 - (process.env.NODE_ENV || 'development').length)} ║
║  🔗 URL: http://localhost:${PORT}${' '.repeat(39 - PORT.toString().length)} ║
║                                                              ║
║  ✨ Ready to serve MoroccoCheck API requests!                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
`;
    
    console.log(box);
    logInfo('server_started', {
      port: PORT,
      environment: runtimeConfig.nodeEnv,
      monitoring_enabled: isMonitoringEnabled(),
      cors_origins: describeCorsOrigins(),
      cors_allow_no_origin: runtimeConfig.cors.allowNoOrigin
    });
});
