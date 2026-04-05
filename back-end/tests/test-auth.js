import { after, before, describe, it } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import request from 'supertest';
import authRoutes from '../src/routes/auth.routes.js';
import { cleanUsersByEmails, hasTable, isDatabaseAvailable } from './helpers/db.helper.js';
import { createTestApp } from './helpers/app.helper.js';

dotenv.config();

const TEST_EMAILS = [
  'test@example.com',
  'another@example.com',
  'security@example.com',
  'xss@example.com'
];

describe('Authentication API', function () {
  let app;
  let authToken;
  let refreshToken;
  let dbReady = false;
  let schemaReady = false;

  const testUser = {
    first_name: 'Test',
    last_name: 'User',
    email: 'test@example.com',
    password: 'password123'
  };

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const requiredTables = await Promise.all([
      hasTable('users'),
      hasTable('sessions')
    ]);
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

  describe('POST /api/auth/register', function () {
    it('should register a new user successfully', async function () {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      expect(response.body).to.include({
        success: true,
        message: 'Inscription reussie'
      });
      expect(response.body.data.token).to.be.a('string');
      expect(response.body.data.refresh_token).to.be.a('string');
      expect(response.body.data.user).to.include({
        first_name: testUser.first_name,
        last_name: testUser.last_name,
        email: testUser.email,
        role: 'TOURIST',
        status: 'ACTIVE',
        points: 0,
        level: 1,
        rank: 'BRONZE'
      });

      authToken = response.body.data.token;
      refreshToken = response.body.data.refresh_token;
    });

    it('should reject duplicate email', async function () {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(400);

      expect(response.body).to.include({
        success: false,
        message: 'Email deja utilise',
        code: 'EMAIL_ALREADY_USED'
      });
    });

    it('should validate payload', async function () {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          first_name: 'A',
          email: 'invalid-email',
          password: '123'
        })
        .expect(400);

      expect(response.body.success).to.equal(false);
      expect(response.body.message).to.equal('Validation echouee');
      expect(response.body.code).to.equal('VALIDATION_ERROR');
      expect(response.body.errors).to.be.an('array').that.is.not.empty;
      expect(response.body.details.validation).to.be.an('array').that.is.not.empty;
    });
  });

  describe('POST /api/auth/login', function () {
    it('should login with valid credentials', async function () {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        })
        .expect(200);

      expect(response.body).to.include({
        success: true,
        message: 'Connexion reussie'
      });
      expect(response.body.data.user.email).to.equal(testUser.email);
      expect(response.body.data.user).to.not.have.property('password_hash');
      expect(response.body.data.refresh_token).to.be.a('string');
      authToken = response.body.data.token;
      refreshToken = response.body.data.refresh_token;
    });

    it('should reject invalid credentials', async function () {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body.message).to.equal('Email ou mot de passe incorrect');
    });
  });

  describe('POST /api/auth/refresh', function () {
    it('should rotate access and refresh tokens', async function () {
      const oldAccessToken = authToken;
      const oldRefreshToken = refreshToken;

      const response = await request(app)
        .post('/api/auth/refresh')
        .send({
          refresh_token: oldRefreshToken
        })
        .expect(200);

      expect(response.body.success).to.equal(true);
      expect(response.body.data.token).to.be.a('string');
      expect(response.body.data.refresh_token).to.be.a('string');
      expect(response.body.data.token).to.not.equal(oldAccessToken);
      expect(response.body.data.refresh_token).to.not.equal(oldRefreshToken);

      authToken = response.body.data.token;
      refreshToken = response.body.data.refresh_token;

      const oldTokenResponse = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${oldAccessToken}`)
        .expect(401);

      expect(oldTokenResponse.body.code).to.equal('SESSION_INACTIVE');

      const newTokenResponse = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(newTokenResponse.body.success).to.equal(true);
    });
  });

  describe('GET /api/auth/profile', function () {
    it('should return profile and badges for valid token', async function () {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).to.equal(true);
      expect(response.body.data.user.email).to.equal(testUser.email);
      expect(response.body.data.user).to.not.have.property('password_hash');
      expect(response.body.data.badges).to.be.an('array');
    });

    it('should reject missing token', async function () {
      const response = await request(app)
        .get('/api/auth/profile')
        .expect(401);

      expect(response.body.message).to.equal('Token manquant');
    });
  });

  describe('PUT /api/auth/profile', function () {
    it('should update profile successfully', async function () {
      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          first_name: 'Updated',
          last_name: 'Tester',
          profile_picture: 'https://example.com/avatar.jpg'
        })
        .expect(200);

      expect(response.body.success).to.equal(true);
      expect(response.body.message).to.equal('Profil mis a jour avec succes');
      expect(response.body.data.user).to.include({
        first_name: 'Updated',
        last_name: 'Tester'
      });
    });

    it('should reject empty update payload', async function () {
      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(400);

      expect(response.body.message).to.equal('Aucun champ a mettre a jour fourni');
    });
  });

  describe('POST /api/auth/logout', function () {
    it('should invalidate the current session token', async function () {
      const logoutResponse = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(logoutResponse.body.success).to.equal(true);
      expect(logoutResponse.body.data.logged_out).to.equal(true);

      const profileResponse = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(401);

      expect(profileResponse.body.code).to.equal('SESSION_INACTIVE');
    });
  });
});
