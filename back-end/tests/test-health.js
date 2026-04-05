import { before, describe, it } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import request from 'supertest';
import healthRoutes from '../src/routes/health.routes.js';
import { createTestApp } from './helpers/app.helper.js';
import { hasTable, isDatabaseAvailable } from './helpers/db.helper.js';

dotenv.config();

describe('Health API', function () {
  let app;
  let dbReady = false;
  let schemaReady = false;

  before(async function () {
    dbReady = await isDatabaseAvailable();
    schemaReady = await hasTable('tourist_sites');
    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = createTestApp('/api/health', healthRoutes);
  });

  it('should return basic health status', async function () {
    const response = await request(app)
      .get('/api/health')
      .expect(200);

    expect(response.body.status).to.equal('OK');
    expect(response.body.service).to.equal('moroccocheck-backend');
    expect(response.body.timestamp).to.be.a('string');
  });

  it('should return database health and tourist site stats', async function () {
    const response = await request(app)
      .get('/api/health/db')
      .expect(200);

    expect(response.body.connected).to.equal(true);
    expect(response.body.database).to.equal(process.env.DB_NAME || 'moroccocheck');
    expect(response.body.tables).to.include('tourist_sites');
    expect(response.body.stats).to.have.keys(['users', 'sites', 'checkins', 'reviews']);
  });

  it('should return system information', async function () {
    const response = await request(app)
      .get('/api/health/system')
      .expect(200);

    expect(response.body.nodeVersion).to.be.a('string');
    expect(response.body.platform).to.be.a('string');
    expect(response.body.memory).to.be.an('object');
    expect(response.body.environment).to.be.an('object');
  });
});

