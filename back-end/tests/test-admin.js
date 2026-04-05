import { after, before, describe, it } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import express from 'express';
import request from 'supertest';
import pool from '../src/config/database.js';
import adminRoutes from '../src/routes/admin.routes.js';
import sitesRoutes from '../src/routes/sites.routes.js';
import errorMiddleware from '../src/middleware/error.middleware.js';
import {
  cleanupTestData,
  createTestCategory,
  createSessionForUser,
  createTestSite,
  createTestUser,
  hasTable,
  isDatabaseAvailable
} from './helpers/db.helper.js';

dotenv.config();

describe('Admin API', function () {
  let app;
  let admin;
  let professional;
  let adminToken;
  let professionalToken;
  let category;
  let pendingSite;
  let reviewAuthor;
  let review;
  let reviewPhoto;
  let dbReady = false;
  let schemaReady = false;

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const requiredTables = await Promise.all([
      hasTable('users'),
      hasTable('tourist_sites'),
      hasTable('categories')
    ]);
    schemaReady = requiredTables.every(Boolean);

    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = express();
    app.use(express.json());
    app.use('/api/admin', adminRoutes);
    app.use('/api/sites', sitesRoutes);
    app.use(errorMiddleware.notFoundHandler);
    app.use(errorMiddleware.errorHandler);

    category = await createTestCategory();
    admin = await createTestUser({
      role: 'ADMIN',
      email: `admin.review.${Date.now()}@example.com`
    });
    professional = await createTestUser({
      role: 'PROFESSIONAL',
      email: `pro.review.${Date.now()}@example.com`
    });
    reviewAuthor = await createTestUser({
      role: 'TOURIST',
      email: `review.author.${Date.now()}@example.com`
    });
    pendingSite = await createTestSite(category.id, {
      owner_id: professional.id,
      status: 'PENDING_REVIEW',
      verification_status: 'PENDING'
    });
    const [reviewResult] = await pool.query(
      `INSERT INTO reviews (
          user_id, site_id, overall_rating, title, content, status, moderation_status
       ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        reviewAuthor.id,
        pendingSite.id,
        4.5,
        'Lieu tres prometteur',
        'Le lieu merite verification avant publication finale.',
        'PENDING',
        'PENDING'
      ]
    );
    review = { id: reviewResult.insertId };
    const [photoResult] = await pool.query(
      `INSERT INTO photos (
          url, thumbnail_url, filename, original_filename, mime_type, size,
          width, height, user_id, entity_type, entity_id, caption, alt_text,
          status, moderation_status, is_primary
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'REVIEW', ?, ?, ?, ?, ?, ?)`,
      [
        '/uploads/reviews/test-photo.jpg',
        '/uploads/reviews/thumb-test-photo.jpg',
        'test-photo.jpg',
        'test-photo.jpg',
        'image/jpeg',
        1024,
        1200,
        900,
        reviewAuthor.id,
        review.id,
        'Photo de verification',
        'Facade du lieu',
        'ACTIVE',
        'PENDING',
        true
      ]
    );
    reviewPhoto = { id: photoResult.insertId };

    const adminSession = await createSessionForUser(admin);
    const professionalSession = await createSessionForUser(professional);
    adminToken = adminSession.access_token;
    professionalToken = professionalSession.access_token;
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanupTestData({
      reviewIds: [review?.id].filter(Boolean),
      siteIds: [pendingSite?.id].filter(Boolean),
      userIds: [admin?.id, professional?.id, reviewAuthor?.id].filter(Boolean),
      categoryIds: category ? [category.id] : []
    });
    if (reviewPhoto?.id) {
      await pool.query(`DELETE FROM photos WHERE id = ?`, [reviewPhoto.id]);
    }
  });

  it('should persist moderation notes for a reviewed site and expose them to the owner', async function () {
    const notes =
      'Merci de preciser les horaires exacts et de corriger l adresse avant republication.';

    const moderationResponse = await request(app)
      .put(`/api/admin/sites/${pendingSite.id}/review`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        action: 'REJECT',
        notes
      })
      .expect(200);

    expect(moderationResponse.body.success).to.equal(true);
    expect(moderationResponse.body.data.notes).to.equal(notes);
    expect(moderationResponse.body.data.verification_status).to.equal('REJECTED');

    const ownerResponse = await request(app)
      .get(`/api/sites/mine/${pendingSite.id}`)
      .set('Authorization', `Bearer ${professionalToken}`)
      .expect(200);

    expect(ownerResponse.body.success).to.equal(true);
    expect(ownerResponse.body.data.site.verification_status).to.equal('REJECTED');
    expect(ownerResponse.body.data.site.moderation_notes).to.equal(notes);
    expect(ownerResponse.body.data.site.moderated_by).to.equal(admin.id);
    expect(ownerResponse.body.data.site.moderator_first_name).to.equal(admin.first_name);
  });

  it('should expose admin site detail for moderation pages', async function () {
    const response = await request(app)
      .get(`/api/admin/sites/${pendingSite.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.id).to.equal(pendingSite.id);
    expect(response.body.data.name).to.equal(pendingSite.name);
    expect(response.body.data.owner_id).to.equal(professional.id);
    expect(response.body.data.owner_email).to.equal(professional.email);
  });

  it('should expose admin review detail for moderation pages', async function () {
    const response = await request(app)
      .get(`/api/admin/reviews/${review.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.id).to.equal(review.id);
    expect(response.body.data.site_id).to.equal(pendingSite.id);
    expect(response.body.data.author_email).to.equal(reviewAuthor.email);
    expect(response.body.data.content).to.include('verification');
  });

  it('should delete a review photo from admin moderation detail', async function () {
    const response = await request(app)
      .delete(`/api/admin/reviews/${review.id}/photos/${reviewPhoto.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.deleted).to.equal(true);

    const detailResponse = await request(app)
      .get(`/api/admin/reviews/${review.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(detailResponse.body.data.photos).to.be.an('array');
    expect(detailResponse.body.data.photos).to.have.length(0);
  });

  it('should expose user detail when opening /api/admin/users/:id directly', async function () {
    const response = await request(app)
      .get(`/api/admin/users/${professional.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.id).to.equal(professional.id);
    expect(response.body.data.email).to.equal(professional.email);
    expect(response.body.data.role).to.equal('PROFESSIONAL');
  });

  it('should update a user role from the admin API', async function () {
    const response = await request(app)
      .patch(`/api/admin/users/${reviewAuthor.id}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'CONTRIBUTOR' })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.id).to.equal(reviewAuthor.id);
    expect(response.body.data.role).to.equal('CONTRIBUTOR');
  });

  it('should filter pending queues with search query params', async function () {
    const filteredSite = await createTestSite(category.id, {
      owner_id: professional.id,
      name: `Filtre Site ${Date.now()}`,
      city: 'Agadir',
      region: 'Souss-Massa',
      status: 'PENDING_REVIEW',
      verification_status: 'PENDING'
    });
    const [filteredReviewResult] = await pool.query(
      `INSERT INTO reviews (
          user_id, site_id, overall_rating, title, content, status, moderation_status
       ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        reviewAuthor.id,
        filteredSite.id,
        4.7,
        'Avis filtrable',
        'Contenu destine a tester la recherche admin prometteur.',
        'PENDING',
        'PENDING'
      ]
    );

    const sitesResponse = await request(app)
      .get(`/api/admin/sites/pending?q=${encodeURIComponent(filteredSite.name)}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    const reviewsResponse = await request(app)
      .get('/api/admin/reviews/pending?q=prometteur&min_rating=4')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(sitesResponse.body.success).to.equal(true);
    expect(sitesResponse.body.data.some((item) => item.id === filteredSite.id)).to.equal(true);

    expect(reviewsResponse.body.success).to.equal(true);
    expect(
      reviewsResponse.body.data.some((item) => item.id === filteredReviewResult.insertId)
    ).to.equal(true);

    await cleanupTestData({
      reviewIds: [filteredReviewResult.insertId],
      siteIds: [filteredSite.id]
    });
  });
});
