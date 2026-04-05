import { after, before, describe, it } from "mocha";
import { expect } from "chai";
import dotenv from "dotenv";
import request from "supertest";
import reviewsRoutes from "../src/routes/reviews.routes.js";
import {
  cleanupTestData,
  createSessionForUser,
  createTestCategory,
  createTestSite,
  createTestUser,
  hasTable,
  isDatabaseAvailable,
} from "./helpers/db.helper.js";
import { createTestApp } from "./helpers/app.helper.js";

dotenv.config();

describe("Reviews API", function () {
  let app;
  let reviewer;
  let reviewerToken;
  let adminReviewer;
  let adminReviewerToken;
  let professionalOwner;
  let professionalOwnerToken;
  let category;
  let site;
  let dbReady = false;
  let schemaReady = false;

  const createdReviewIds = [];

  before(async function () {
    dbReady = await isDatabaseAvailable();
    const requiredTables = await Promise.all([
      hasTable("users"),
      hasTable("tourist_sites"),
      hasTable("reviews"),
      hasTable("categories"),
    ]);
    schemaReady = requiredTables.every(Boolean);

    if (!dbReady || !schemaReady) {
      this.skip();
    }

    app = createTestApp("/api/reviews", reviewsRoutes);
    category = await createTestCategory();
    reviewer = await createTestUser({
      role: "CONTRIBUTOR",
      email: `review.user.${Date.now()}@example.com`,
    });
    adminReviewer = await createTestUser({
      role: "ADMIN",
      email: `review.admin.${Date.now()}@example.com`,
    });
    professionalOwner = await createTestUser({
      role: "PROFESSIONAL",
      email: `review.owner.${Date.now()}@example.com`,
    });
    site = await createTestSite(category.id, {
      status: "PUBLISHED",
      verification_status: "VERIFIED",
      owner_id: professionalOwner.id,
    });
    const reviewerSession = await createSessionForUser(reviewer);
    const adminReviewerSession = await createSessionForUser(adminReviewer);
    const professionalOwnerSession = await createSessionForUser(
      professionalOwner,
    );
    reviewerToken = reviewerSession.access_token;
    adminReviewerToken = adminReviewerSession.access_token;
    professionalOwnerToken = professionalOwnerSession.access_token;
  });

  after(async function () {
    if (!dbReady || !schemaReady) {
      return;
    }

    await cleanupTestData({
      reviewIds: createdReviewIds,
      siteIds: site ? [site.id] : [],
      userIds: [
        reviewer?.id,
        adminReviewer?.id,
        professionalOwner?.id,
      ].filter(Boolean),
      categoryIds: category ? [category.id] : [],
    });
  });

  it("should create a review for a published site", async function () {
    const response = await request(app)
      .post("/api/reviews")
      .set("Authorization", `Bearer ${reviewerToken}`)
      .send({
        site_id: site.id,
        rating: 4,
        title: "Belle experience",
        content:
          "Une visite tres agreable avec un excellent accueil et un site bien entretenu.",
        visit_type: "FRIENDS",
      })
      .expect(201);

    expect(response.body.success).to.equal(true);
    expect(response.body.message).to.equal("Avis cree avec succes");
    expect(response.body.data.review.site_id).to.equal(site.id);
    expect(response.body.data.moderation_status).to.equal("PENDING");

    createdReviewIds.push(response.body.data.review.id);
  });

  it("should reject duplicate review for the same user and site", async function () {
    const response = await request(app)
      .post("/api/reviews")
      .set("Authorization", `Bearer ${reviewerToken}`)
      .send({
        site_id: site.id,
        rating: 5,
        title: "Deuxieme avis",
        content:
          "Ce second avis devrait etre refuse car un avis existe deja pour ce site.",
        visit_type: "SOLO",
      })
      .expect(409);

    expect(response.body.success).to.equal(false);
    expect(response.body.code).to.equal("REVIEW_ALREADY_EXISTS");
  });

  it("should allow the professional owner to respond to a published review", async function () {
    const publishedReviewResponse = await request(app)
      .post("/api/reviews")
      .set("Authorization", `Bearer ${adminReviewerToken}`)
      .send({
        site_id: site.id,
        rating: 5,
        title: "Service remarquable",
        content:
          "Une visite tres agreable avec un excellent accueil et un site bien entretenu. Le lieu reste une belle reference.",
        visit_type: "SOLO",
      })
      .expect(201);

    const reviewId = publishedReviewResponse.body.data.review.id;
    createdReviewIds.push(reviewId);

    const response = await request(app)
      .post(`/api/reviews/${reviewId}/owner-response`)
      .set("Authorization", `Bearer ${professionalOwnerToken}`)
      .send({
        response:
          "Merci pour votre retour. Nous continuerons a ameliorer l accueil et la qualite de visite.",
      })
      .expect(200);

    expect(response.body.success).to.equal(true);
    expect(response.body.data.owner_response).to.contain(
      "Merci pour votre retour",
    );
    expect(response.body.data.has_owner_response).to.equal(1);
  });
});
