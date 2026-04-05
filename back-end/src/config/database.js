import mysql from 'mysql2/promise';
import runtimeConfig from './runtime.js';

const pool = mysql.createPool({
  host: runtimeConfig.db.host,
  user: runtimeConfig.db.user,
  password: runtimeConfig.db.password,
  database: runtimeConfig.db.database,
  port: runtimeConfig.db.port,
  connectionLimit: 10,
  waitForConnections: true,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

try {
  const connection = await pool.getConnection();
  console.log(`Database connected: ${runtimeConfig.db.database}`);
  connection.release();
} catch (error) {
  console.error(`Database connection failed: ${error.message}`);
  const shouldExit =
    !runtimeConfig.isTest &&
    runtimeConfig.db.exitOnFailure;

  if (shouldExit) {
    process.exit(1);
  }
}

export default pool;
