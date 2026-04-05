import express from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { asyncHandler } from "../middleware/error.middleware.js";
import { reviewPhotoUploadMiddleware } from "../middleware/upload.middleware.js";
import {
  createReviewHandler,
  getReviews,
  getReview,
  respondToReviewHandler,
  updateReviewHandler,
  deleteReviewHandler,
} from "../controllers/review.controller.js";

const router = express.Router();

router.get("/", asyncHandler(getReviews));
router.get("/:id", asyncHandler(getReview));
router.post(
  "/:id/owner-response",
  authMiddleware,
  asyncHandler(respondToReviewHandler),
);
router.post(
  "/",
  authMiddleware,
  reviewPhotoUploadMiddleware,
  asyncHandler(createReviewHandler),
);
router.put("/:id", authMiddleware, asyncHandler(updateReviewHandler));
router.delete("/:id", authMiddleware, asyncHandler(deleteReviewHandler));

export default router;
