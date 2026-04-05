import express from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authMiddleware, authorizeRoles } from '../middleware/auth.middleware.js';
import { adminRateLimit } from '../middleware/rate-limit.middleware.js';
import {
  getPendingSites,
  getAdminSiteDetailHandler,
  reviewSiteHandler,
  getPendingReviews,
  getAdminReviewDetailHandler,
  deleteReviewPhotoHandler,
  moderateReviewHandler,
  getUsers,
  getUserByIdHandler,
  getContributorRequestsHandler,
  reviewContributorRequestHandler,
  updateUserRoleHandler,
  updateUserStatusHandler,
  getAdminStatsHandler
} from '../controllers/admin.controller.js';

const router = express.Router();

router.use(adminRateLimit, authMiddleware, authorizeRoles('ADMIN'));

router.get('/sites/pending', asyncHandler(getPendingSites));
router.get('/sites/:id', asyncHandler(getAdminSiteDetailHandler));
router.put('/sites/:id/review', asyncHandler(reviewSiteHandler));
router.get('/reviews/pending', asyncHandler(getPendingReviews));
router.get('/reviews/:id', asyncHandler(getAdminReviewDetailHandler));
router.delete('/reviews/:id/photos/:photoId', asyncHandler(deleteReviewPhotoHandler));
router.put('/reviews/:id/moderate', asyncHandler(moderateReviewHandler));
router.get('/contributor-requests', asyncHandler(getContributorRequestsHandler));
router.patch(
  '/contributor-requests/:id',
  asyncHandler(reviewContributorRequestHandler)
);
router.get('/stats', asyncHandler(getAdminStatsHandler));
router.get('/users', asyncHandler(getUsers));
router.get('/users/:id', asyncHandler(getUserByIdHandler));
router.patch('/users/:id/role', authorizeRoles('ADMIN'), asyncHandler(updateUserRoleHandler));
router.patch('/users/:id/status', authorizeRoles('ADMIN'), asyncHandler(updateUserStatusHandler));

export default router;
