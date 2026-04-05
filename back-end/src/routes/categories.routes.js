import express from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { getCategories } from '../controllers/category.controller.js';

const router = express.Router();

router.get('/', asyncHandler(getCategories));

export default router;
