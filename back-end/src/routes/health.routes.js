/**
 * Health check routes for system monitoring and diagnostics
 * 
 * This module provides endpoints for checking the health status of the
 * MoroccoCheck API, database connectivity, and system information.
 */

import express from 'express';
import pool from '../config/database.js';

const router = express.Router();

/**
 * Simple health check endpoint
 * 
 * Returns basic status and timestamp for quick health verification
 * 
 * @route GET /api/health
 * @returns {Object} Health status response
 */
router.get('/', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'moroccocheck-backend'
  });
});

/**
 * Database connectivity and statistics endpoint
 * 
 * Tests database connection and returns database information,
 * table list, and record counts for key tables.
 * 
 * @route GET /api/health/db
 * @returns {Object} Database status and statistics
 */
router.get('/db', async (req, res) => {
  try {
    const [connectionRows] = await pool.query('SELECT 1 as test');
    if (!connectionRows || connectionRows.length === 0) {
      throw new Error('Database connection test failed');
    }

    const tablesQuery = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = ?
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `;
    const dbName = process.env.DB_NAME || 'moroccocheck';
    const [tablesRows] = await pool.query(tablesQuery, [dbName]);
    const tables = (tablesRows || []).map((row) => row.table_name);

    const statsQuery = `
      SELECT
        (SELECT COUNT(*) FROM users) as users,
        (SELECT COUNT(*) FROM tourist_sites) as sites,
        (SELECT COUNT(*) FROM checkins) as checkins,
        (SELECT COUNT(*) FROM reviews) as reviews
    `;
    const [statsRows] = await pool.query(statsQuery);
    const stats = statsRows && statsRows[0] ? statsRows[0] : {};

    res.json({
      database: dbName,
      connected: true,
      timestamp: new Date().toISOString(),
      tables,
      stats: {
        users: parseInt(stats.users || 0, 10),
        sites: parseInt(stats.sites || 0, 10),
        checkins: parseInt(stats.checkins || 0, 10),
        reviews: parseInt(stats.reviews || 0, 10)
      }
    });

  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(500).json({
      database: 'moroccocheck',
      connected: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * System information endpoint
 * 
 * Returns Node.js version, platform information, uptime,
 * and memory usage statistics.
 * 
 * @route GET /api/health/system
 * @returns {Object} System information and metrics
 */
router.get('/system', (req, res) => {
  const memoryUsage = process.memoryUsage();
  
  res.json({
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    memory: {
      rss: Math.round(memoryUsage.rss / 1024 / 1024) + ' MB', // Resident Set Size
      heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024) + ' MB', // Total Heap Allocated
      heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024) + ' MB', // Heap Actually Used
      external: Math.round(memoryUsage.external / 1024 / 1024) + ' MB' // External Memory Usage
    },
    environment: {
      nodeEnv: process.env.NODE_ENV || 'development',
      port: process.env.PORT || 'not set'
    }
  });
});

export default router;
