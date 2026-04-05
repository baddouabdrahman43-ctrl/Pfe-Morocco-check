import { after, before, describe, it } from 'mocha';
import { expect } from 'chai';
import request from 'supertest';
import authRoutes from '../src/routes/auth.routes.js';
import pool from '../src/config/database.js';
import { loginWithGoogleToken } from '../src/services/auth.service.js';
import {
  cleanUsersByEmails,
  createTestUser,
  hasTable,
  isDatabaseAvailable
} from './helpers/db.helper.js';
import { createTestApp } from './helpers/app.helper.js';

const TEST_EMAILS = [
  'google.new.user@example.com',
  'google.linked.user@example.com'
];

describe('Google Authentication', function () {
  let app;
  let dbReady = false;
  let schemaReady = false;
  const createdUserIds = [];

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const requiredTables = await Promise.all([hasTable('users'), hasTable('sessions')]);
    schemaReady = requiredTables.every(Boolean);

    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = createTestApp('/api/auth', authRoutes);
    await cleanUsersByEmails(TEST_EMAILS);
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanUsersByEmails(TEST_EMAILS);
  });

  it('should validate the google login payload', async function () {
    const response = await request(app)
      .post('/api/auth/google')
      .send({})
      .expect(400);

    expect(response.body.code).to.equal('VALIDATION_ERROR');
  });

  it('should create a new user from a verified Google token', async function () {
    const result = await loginWithGoogleToken(
      { id_token: 'fake-google-token' },
      { ipAddress: '127.0.0.1', userAgent: 'mocha' },
      {
        verifyGoogleToken: async () => ({
          sub: 'google-user-001',
          email: TEST_EMAILS[0],
          email_verified: true,
          given_name: 'Google',
          family_name: 'User',
          picture: 'https://example.com/google-user.jpg'
        })
      }
    );

    createdUserIds.push(result.user.id);

    expect(result.user.email).to.equal(TEST_EMAILS[0]);
    expect(result.user.first_name).to.equal('Google');
    expect(result.user.last_name).to.equal('User');
    expect(result.refresh_token).to.be.a('string');

    const [rows] = await pool.query(
      'SELECT google_id, is_email_verified, profile_picture FROM users WHERE id = ?',
      [result.user.id]
    );

    expect(rows[0].google_id).to.equal('google-user-001');
    expect(Boolean(rows[0].is_email_verified)).to.equal(true);
    expect(rows[0].profile_picture).to.equal('https://example.com/google-user.jpg');
  });

  it('should link a Google identity to an existing email account', async function () {
    const existingUser = await createTestUser({
      email: TEST_EMAILS[1],
      first_name: 'Existing',
      last_name: 'Account',
      is_email_verified: false
    });
    createdUserIds.push(existingUser.id);

    const result = await loginWithGoogleToken(
      { id_token: 'fake-google-token-2' },
      { ipAddress: '127.0.0.1', userAgent: 'mocha' },
      {
        verifyGoogleToken: async () => ({
          sub: 'google-user-002',
          email: TEST_EMAILS[1],
          email_verified: true,
          given_name: 'Existing',
          family_name: 'Account',
          picture: 'https://example.com/existing-account.jpg'
        })
      }
    );

    expect(result.user.id).to.equal(existingUser.id);
    expect(result.user.email).to.equal(TEST_EMAILS[1]);

    const [rows] = await pool.query(
      'SELECT google_id, is_email_verified, profile_picture FROM users WHERE id = ?',
      [existingUser.id]
    );

    expect(rows[0].google_id).to.equal('google-user-002');
    expect(Boolean(rows[0].is_email_verified)).to.equal(true);
    expect(rows[0].profile_picture).to.equal('https://example.com/existing-account.jpg');
  });
});
