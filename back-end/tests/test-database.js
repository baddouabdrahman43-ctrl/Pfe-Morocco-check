import { describe, it, before } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import pool from '../src/config/database.js';
import { hasTable, isDatabaseAvailable } from './helpers/db.helper.js';

dotenv.config();

describe('Database Configuration', function () {
  let dbReady = false;

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const schemaReady = await hasTable('users');
    if (!dbReady || !schemaReady) {
      this.skip();
    }
  });

  it('should establish a connection to the database', async function () {
    const connection = await pool.getConnection();
    expect(connection).to.exist;
    connection.release();
  });

  it('should execute a simple query', async function () {
    const [rows] = await pool.query('SELECT 1 AS test');
    expect(rows[0].test).to.equal(1);
  });

  it('should have environment variables loaded', function () {
    expect(process.env.DB_HOST || 'localhost').to.be.a('string');
    expect(process.env.DB_USER || 'root').to.be.a('string');
    expect(process.env.DB_NAME || 'moroccocheck').to.be.a('string');
  });

  it('should create, update and delete a test user with the MPD schema', async function () {
    const email = 'test_db_user@example.com';
    await pool.query('DELETE FROM users WHERE email = ?', [email]);

    const [insertResult] = await pool.query(
      `INSERT INTO users (
          email, password_hash, first_name, last_name, role, status, points, level, rank
        ) VALUES (?, ?, ?, ?, 'TOURIST', 'ACTIVE', 0, 1, 'BRONZE')`,
      [email, '$2a$10$test.hash.for.testing.purposes.only', 'Db', 'User']
    );

    const userId = insertResult.insertId;
    const [rows] = await pool.query(
      'SELECT email, first_name, last_name, role, status, level, rank FROM users WHERE id = ?',
      [userId]
    );

    expect(rows[0]).to.include({
      email,
      first_name: 'Db',
      last_name: 'User',
      role: 'TOURIST',
      status: 'ACTIVE',
      level: 1,
      rank: 'BRONZE'
    });

    await pool.query(
      'UPDATE users SET first_name = ?, last_name = ? WHERE id = ?',
      ['Updated', 'User', userId]
    );

    const [updatedRows] = await pool.query(
      'SELECT first_name, last_name FROM users WHERE id = ?',
      [userId]
    );
    expect(updatedRows[0]).to.include({
      first_name: 'Updated',
      last_name: 'User'
    });

    await pool.query('DELETE FROM users WHERE id = ?', [userId]);
    const [deletedRows] = await pool.query('SELECT id FROM users WHERE id = ?', [userId]);
    expect(deletedRows).to.have.length(0);
  });
});
