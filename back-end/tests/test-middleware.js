import { after, before, describe, it } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import express from 'express';
import request from 'supertest';
import { adminMiddleware, authMiddleware } from '../src/middleware/auth.middleware.js';
import { generateToken } from '../src/utils/jwt.utils.js';
import {
  cleanupTestData,
  createSessionForUser,
  createTestUser,
  hasTable,
  isDatabaseAvailable
} from './helpers/db.helper.js';

dotenv.config();

describe('Authentication Middleware', function () {
  let app;
  let touristUser;
  let adminUser;
  let touristToken;
  let adminToken;
  let dbReady = false;
  let schemaReady = false;

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

    app = express();
    app.use(express.json());

    app.get('/protected', authMiddleware, (req, res) => {
      res.json({
        success: true,
        userId: req.userId,
        userRole: req.userRole
      });
    });

    app.get('/admin', authMiddleware, adminMiddleware, (req, res) => {
      res.json({
        success: true,
        userId: req.userId,
        userRole: req.userRole
      });
    });

    touristUser = await createTestUser({
      role: 'TOURIST',
      email: `middleware.tourist.${Date.now()}@example.com`
    });
    adminUser = await createTestUser({
      role: 'ADMIN',
      email: `middleware.admin.${Date.now()}@example.com`
    });

    const touristSession = await createSessionForUser(touristUser);
    const adminSession = await createSessionForUser(adminUser);
    touristToken = touristSession.access_token;
    adminToken = adminSession.access_token;
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanupTestData({
      userIds: [touristUser?.id, adminUser?.id].filter(Boolean)
    });
  });

  it('should allow access with a valid token', async function () {
    const response = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${touristToken}`)
      .expect(200);

    expect(response.body).to.include({
      success: true,
      userId: touristUser.id,
      userRole: 'TOURIST'
    });
  });

  it('should reject missing token', async function () {
    const response = await request(app)
      .get('/protected')
      .expect(401);

    expect(response.body.message).to.equal('Token manquant');
  });

  it('should reject invalid token', async function () {
    const response = await request(app)
      .get('/protected')
      .set('Authorization', 'Bearer invalid-token')
      .expect(401);

    expect(response.body.message).to.equal('Token invalide');
  });

  it('should reject expired token', async function () {
    const expiredToken = generateToken(touristUser, '-1h');
    await createSessionForUser(touristUser, {
      access_token: expiredToken
    });

    const response = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401);

    expect(response.body.message).to.equal('Token expire');
  });

  it('should allow admin access for ADMIN role', async function () {
    const response = await request(app)
      .get('/admin')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.userRole).to.equal('ADMIN');
  });

  it('should reject non-admin access', async function () {
    const response = await request(app)
      .get('/admin')
      .set('Authorization', `Bearer ${touristToken}`)
      .expect(403);

    expect(response.body.message).to.equal('Acces refuse');
  });

  it('should accept authorization header with extra spaces', async function () {
    const response = await request(app)
      .get('/protected')
      .set('Authorization', `  Bearer   ${touristToken}  `)
      .expect(200);

    expect(response.body.success).to.equal(true);
  });
});
