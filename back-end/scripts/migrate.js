import fs from 'fs';
import path from 'path';
import mysql from 'mysql2/promise';
import { fileURLToPath } from 'url';
import runtimeConfig from '../src/config/runtime.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const migrationsDir = path.resolve(__dirname, '../sql/migrations');
const command = (process.argv[2] || 'up').trim().toLowerCase();

function getMigrationFiles() {
  if (!fs.existsSync(migrationsDir)) {
    return [];
  }

  return fs
    .readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort((left, right) => left.localeCompare(right));
}

async function ensureMigrationsTable(connection) {
  await connection.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

async function fetchAppliedMigrations(connection) {
  const [rows] = await connection.query(
    'SELECT filename FROM schema_migrations ORDER BY filename ASC'
  );

  return new Set(rows.map((row) => row.filename));
}

async function printStatus(connection) {
  const files = getMigrationFiles();
  const applied = await fetchAppliedMigrations(connection);

  if (!files.length) {
    console.log('No SQL migrations found in back-end/sql/migrations.');
    return;
  }

  console.log('Migration status:\n');
  for (const file of files) {
    const marker = applied.has(file) ? '[x]' : '[ ]';
    console.log(`${marker} ${file}`);
  }
}

async function applyPendingMigrations(connection) {
  const files = getMigrationFiles();
  const applied = await fetchAppliedMigrations(connection);
  const pending = files.filter((file) => !applied.has(file));

  if (!pending.length) {
    console.log('No pending migrations.');
    return;
  }

  for (const filename of pending) {
    const migrationPath = path.join(migrationsDir, filename);
    const sql = fs.readFileSync(migrationPath, 'utf8').trim();

    if (!sql) {
      console.log(`Skipping empty migration: ${filename}`);
      await connection.query(
        'INSERT INTO schema_migrations (filename) VALUES (?)',
        [filename]
      );
      continue;
    }

    console.log(`Applying migration: ${filename}`);
    await connection.beginTransaction();
    try {
      await connection.query(sql);
      await connection.query(
        'INSERT INTO schema_migrations (filename) VALUES (?)',
        [filename]
      );
      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw new Error(
        `Migration failed for ${filename}: ${error.message}`
      );
    }
  }

  console.log(`Applied ${pending.length} migration(s).`);
}

async function main() {
  const connection = await mysql.createConnection({
    host: runtimeConfig.db.host,
    user: runtimeConfig.db.user,
    password: runtimeConfig.db.password,
    database: runtimeConfig.db.database,
    port: runtimeConfig.db.port,
    multipleStatements: true
  });

  try {
    await ensureMigrationsTable(connection);

    if (command === 'status') {
      await printStatus(connection);
      return;
    }

    if (command !== 'up') {
      throw new Error(
        `Unsupported migration command "${command}". Use "up" or "status".`
      );
    }

    await applyPendingMigrations(connection);
  } finally {
    await connection.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
