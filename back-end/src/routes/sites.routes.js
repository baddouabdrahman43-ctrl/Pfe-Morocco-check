import express from "express";
import { asyncHandler } from "../middleware/error.middleware.js";
import {
  authMiddleware,
  authorizeRoles,
} from "../middleware/auth.middleware.js";
import {
  getSites,
  getMySitesHandler,
  getMySiteHandler,
  getSite,
  claimSiteHandler,
  createSiteHandler,
  updateSiteHandler,
  deleteSiteHandler,
  getSiteReviewsHandler,
  getSitePhotosHandler,
} from "../controllers/site.controller.js";

const router = express.Router();

router.get("/", asyncHandler(getSites));
router.get(
  "/mine",
  authMiddleware,
  authorizeRoles("PROFESSIONAL", "ADMIN"),
  asyncHandler(getMySitesHandler),
);
router.get(
  "/mine/:id",
  authMiddleware,
  authorizeRoles("PROFESSIONAL", "ADMIN"),
  asyncHandler(getMySiteHandler),
);
router.post(
  "/:id/claim",
  authMiddleware,
  authorizeRoles("PROFESSIONAL", "ADMIN"),
  asyncHandler(claimSiteHandler),
);
router.get("/:id/reviews", asyncHandler(getSiteReviewsHandler));
router.get("/:id/photos", asyncHandler(getSitePhotosHandler));
router.get("/:id", asyncHandler(getSite));
router.post(
  "/",
  authMiddleware,
  authorizeRoles("PROFESSIONAL", "ADMIN"),
  asyncHandler(createSiteHandler),
);
router.put("/:id", authMiddleware, asyncHandler(updateSiteHandler));
router.delete("/:id", authMiddleware, asyncHandler(deleteSiteHandler));

export default router;
