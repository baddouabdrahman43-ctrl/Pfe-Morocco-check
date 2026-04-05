/**
 * Authentication routes for user registration, login, and profile management
 * 
 * This module provides endpoints for user authentication including:
 * - User registration
 * - User login
 * - Profile retrieval (protected)
 * - Profile updates (protected)
 */

import express from 'express';
import {
  register,
  login,
  googleLogin,
  getProfile,
  updateProfile,
  refresh,
  logout
} from '../controllers/auth.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/error.middleware.js';
import {
  registerRateLimit,
  loginRateLimit,
  refreshRateLimit
} from '../middleware/rate-limit.middleware.js';

const router = express.Router();

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', registerRateLimit, asyncHandler(register));

/**
 * @route   POST /api/auth/login
 * @desc    Login user and return JWT token
 * @access  Public
 */
router.post('/login', loginRateLimit, asyncHandler(login));
router.post('/google', loginRateLimit, asyncHandler(googleLogin));
router.post('/refresh', refreshRateLimit, asyncHandler(refresh));

/**
 * @route   GET /api/auth/profile
 * @desc    Get user profile (protected route)
 * @access  Private
 */
router.get('/profile', authMiddleware, asyncHandler(getProfile));

/**
 * @route   PUT /api/auth/profile
 * @desc    Update user profile (protected route)
 * @access  Private
 */
router.put('/profile', authMiddleware, asyncHandler(updateProfile));
router.post('/logout', authMiddleware, asyncHandler(logout));

export default router;
