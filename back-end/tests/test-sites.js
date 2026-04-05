import { after, before, describe, it } from "mocha";
import { expect } from "chai";
import dotenv from "dotenv";
import request from "supertest";
import sitesRoutes from "../src/routes/sites.routes.js";
import {
  cleanupTestData,
  createTestCategory,
  createSessionForUser,
  createTestSite,
  createTestUser,
  hasTable,
  isDatabaseAvailable,
} from "./helpers/db.helper.js";
import { createTestApp } from "./helpers/app.helper.js";

dotenv.config();

describe("Sites API", function () {
  let app;
  let professional;
  let professionalToken;
  let otherProfessional;
  let category;
  let childCategory;
  let ownedSite;
  let pendingSite;
  let foreignSite;
  let claimableSite;
  let childCategorySite;
  let legacySubcategorySite;
  let dbReady = false;
  let schemaReady = false;

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const requiredTables = await Promise.all([
      hasTable("users"),
      hasTable("tourist_sites"),
      hasTable("categories"),
    ]);
    schemaReady = requiredTables.every(Boolean);

    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = createTestApp("/api/sites", sitesRoutes);
    category = await createTestCategory();
    childCategory = await createTestCategory({
      parent_id: category.id,
      name: `Child Of ${Date.now()}`,
      name_ar: `Child Of AR ${Date.now()}`,
    });
    professional = await createTestUser({
      role: "PROFESSIONAL",
      email: `pro.owner.${Date.now()}@example.com`,
    });
    otherProfessional = await createTestUser({
      role: "PROFESSIONAL",
      email: `pro.other.${Date.now()}@example.com`,
    });
    ownedSite = await createTestSite(category.id, {
      owner_id: professional.id,
      status: "PUBLISHED",
      verification_status: "VERIFIED",
    });
    pendingSite = await createTestSite(category.id, {
      owner_id: professional.id,
      status: "PENDING_REVIEW",
      verification_status: "PENDING",
    });
    foreignSite = await createTestSite(category.id, {
      owner_id: otherProfessional.id,
      status: "PUBLISHED",
      verification_status: "VERIFIED",
    });
    claimableSite = await createTestSite(category.id, {
      status: "PUBLISHED",
      verification_status: "VERIFIED",
    });
    childCategorySite = await createTestSite(childCategory.id, {
      status: "PUBLISHED",
      verification_status: "VERIFIED",
    });
    legacySubcategorySite = await createTestSite(category.id, {
      status: "PUBLISHED",
      verification_status: "VERIFIED",
      subcategory: "Tea Room",
    });
    const professionalSession = await createSessionForUser(professional);
    professionalToken = professionalSession.access_token;
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanupTestData({
      siteIds: [
        ownedSite?.id,
        pendingSite?.id,
        foreignSite?.id,
        claimableSite?.id,
        childCategorySite?.id,
        legacySubcategorySite?.id,
      ].filter(Boolean),
      userIds: [professional?.id, otherProfessional?.id].filter(Boolean),
      categoryIds: [childCategory?.id, category?.id].filter(Boolean),
    });
  });

  it("should include child category sites when filtering by parent category", async function () {
    const response = await request(app)
      .get("/api/sites")
      .query({ category_id: category.id })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.map((site) => site.id)).to.include(
      childCategorySite.id,
    );

    const childResult = response.body.data.find(
      (site) => site.id === childCategorySite.id,
    );
    expect(childResult.category_name).to.equal(category.name);
    expect(childResult.subcategory_name).to.equal(childCategory.name);
  });

  it("should support subcategory_id filtering", async function () {
    const response = await request(app)
      .get("/api/sites")
      .query({ subcategory_id: childCategory.id })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.map((site) => site.id)).to.include(
      childCategorySite.id,
    );
    expect(response.body.data.map((site) => site.id)).to.not.include(
      ownedSite.id,
    );
  });

  it("should exclude child category sites when include_children is false", async function () {
    const response = await request(app)
      .get("/api/sites")
      .query({ category_id: category.id, include_children: "false" })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.map((site) => site.id)).to.include(ownedSite.id);
    expect(response.body.data.map((site) => site.id)).to.not.include(
      childCategorySite.id,
    );
  });

  it("should support legacy subcategory text filtering", async function () {
    const response = await request(app)
      .get("/api/sites")
      .query({ subcategory: "tea room" })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.map((site) => site.id)).to.include(
      legacySubcategorySite.id,
    );
  });

  it("should return owned sites including pending review entries", async function () {
    const response = await request(app)
      .get("/api/sites/mine")
      .set("Authorization", `Bearer ${professionalToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data).to.be.an("array");
    expect(response.body.data.map((site) => site.id)).to.include(ownedSite.id);
    expect(response.body.data.map((site) => site.id)).to.include(
      pendingSite.id,
    );
    expect(response.body.data.map((site) => site.id)).to.not.include(
      foreignSite.id,
    );

    const pendingResult = response.body.data.find(
      (site) => site.id === pendingSite.id,
    );
    expect(pendingResult.status).to.equal("PENDING_REVIEW");
  });

  it("should return owned site detail for a pending entry", async function () {
    const response = await request(app)
      .get(`/api/sites/mine/${pendingSite.id}`)
      .set("Authorization", `Bearer ${professionalToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.site.id).to.equal(pendingSite.id);
    expect(response.body.data.site.status).to.equal("PENDING_REVIEW");
    expect(response.body.data).to.have.property("opening_hours");
    expect(response.body.data).to.have.property("recent_reviews");
  });

  it("should reject access to another professional site detail", async function () {
    const response = await request(app)
      .get(`/api/sites/mine/${foreignSite.id}`)
      .set("Authorization", `Bearer ${professionalToken}`)
      .expect(404);

    expect(response.body.success).to.equal(false);
  });

  it("should allow a professional to claim an unowned site", async function () {
    const response = await request(app)
      .post(`/api/sites/${claimableSite.id}/claim`)
      .set("Authorization", `Bearer ${professionalToken}`)
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.claimed).to.equal(true);
    expect(response.body.data.site.id).to.equal(claimableSite.id);
    expect(response.body.data.site.owner_id).to.equal(professional.id);
    expect(response.body.data.site.is_professional_claimed).to.equal(1);
    expect(response.body.data).to.have.property("analytics");
  });
});
