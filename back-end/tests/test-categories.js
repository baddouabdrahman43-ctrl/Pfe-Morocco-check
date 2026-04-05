import { after, before, describe, it } from 'mocha';
import { expect } from 'chai';
import dotenv from 'dotenv';
import request from 'supertest';
import categoriesRoutes from '../src/routes/categories.routes.js';
import {
  cleanupTestData,
  createTestCategory,
  hasTable,
  isDatabaseAvailable
} from './helpers/db.helper.js';
import { createTestApp } from './helpers/app.helper.js';

dotenv.config();

describe('Categories API', function () {
  let app;
  let parentCategory;
  let childCategory;
  let dbReady = false;
  let schemaReady = false;

  before(async function () {
    dbReady = await isDatabaseAvailable();
    schemaReady = await hasTable('categories');

    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = createTestApp('/api/categories', categoriesRoutes);
    parentCategory = await createTestCategory({
      name: `Top Category ${Date.now()}`,
      name_ar: `Top Category AR ${Date.now()}`
    });
    childCategory = await createTestCategory({
      name: `Child Category ${Date.now()}`,
      name_ar: `Child Category AR ${Date.now()}`,
      description: 'Child category for automated tests',
      parent_id: parentCategory.id
    });
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanupTestData({
      categoryIds: [childCategory?.id, parentCategory?.id].filter(Boolean)
    });
  });

  it('should list active categories with parent information', async function () {
    const response = await request(app)
      .get('/api/categories')
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data).to.be.an('array');

    const parent = response.body.data.find((item) => item.id === parentCategory.id);
    const child = response.body.data.find((item) => item.id === childCategory.id);

    expect(parent).to.exist;
    expect(parent.parent_id).to.equal(null);
    expect(child).to.exist;
    expect(child.parent_id).to.equal(parentCategory.id);
  });

  it('should support top_level filtering', async function () {
    const response = await request(app)
      .get('/api/categories')
      .query({ top_level: 'true' })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data).to.be.an('array');
    expect(response.body.data.some((item) => item.id === parentCategory.id)).to.equal(true);
    expect(response.body.data.some((item) => item.id === childCategory.id)).to.equal(false);
    const parent = response.body.data.find((item) => item.id === parentCategory.id);
    expect(parent.children).to.be.an('array');
    expect(parent.children.some((item) => item.id === childCategory.id)).to.equal(true);
  });
});
