-- ============================================
-- MOROCCOCHECK - DATABASE INITIALIZATION
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

-- Drop database if exists (WARNING: Use with caution)
-- DROP DATABASE IF EXISTS moroccocheck;

-- Create database
CREATE DATABASE IF NOT EXISTS moroccocheck
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE moroccocheck;

-- Set global variables
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;