import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/error.middleware.js';
import { checkinPhotoUploadMiddleware } from '../middleware/upload.middleware.js';
import {
  createCheckinHandler,
  getCheckins,
  getCheckin
} from '../controllers/checkin.controller.js';

const router = express.Router();

router.use(authMiddleware);
router.get('/', asyncHandler(getCheckins));
router.get('/:id', asyncHandler(getCheckin));
router.post('/', checkinPhotoUploadMiddleware, asyncHandler(createCheckinHandler));

export default router;
