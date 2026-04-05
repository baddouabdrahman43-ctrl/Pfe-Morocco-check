-- ============================================
-- MOROCCOCHECK - TABLE CREATION SCRIPT - PART 1
-- Tables: categories, users, tourist_sites, opening_hours
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

-- ============================================
-- TABLE: categories
-- ============================================
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    description TEXT,
    description_ar TEXT,
    icon VARCHAR(255),
    color VARCHAR(7),
    parent_id INT UNSIGNED NULL,
    display_order INT UNSIGNED NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_parent_id (parent_id),
    INDEX idx_display_order (display_order),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add foreign key after table creation
ALTER TABLE categories
    ADD CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================
-- TABLE: users
-- ============================================
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY'),
    nationality VARCHAR(2),
    profile_picture VARCHAR(500),
    bio TEXT,
    
    role ENUM('TOURIST', 'CONTRIBUTOR', 'PROFESSIONAL', 'ADMIN') 
        NOT NULL DEFAULT 'TOURIST',
    status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED', 'PENDING_VERIFICATION') 
        NOT NULL DEFAULT 'PENDING_VERIFICATION',
    
    is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires_at TIMESTAMP NULL,
    
    points INT UNSIGNED NOT NULL DEFAULT 0,
    level INT UNSIGNED NOT NULL DEFAULT 1,
    experience_points INT UNSIGNED NOT NULL DEFAULT 0,
    rank ENUM('BRONZE', 'SILVER', 'GOLD', 'PLATINUM') NOT NULL DEFAULT 'BRONZE',
    checkins_count INT UNSIGNED NOT NULL DEFAULT 0,
    reviews_count INT UNSIGNED NOT NULL DEFAULT 0,
    photos_count INT UNSIGNED NOT NULL DEFAULT 0,
    
    google_id VARCHAR(255) UNIQUE,
    facebook_id VARCHAR(255) UNIQUE,
    apple_id VARCHAR(255) UNIQUE,
    
    last_login_at TIMESTAMP NULL,
    last_seen_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status),
    INDEX idx_points (points DESC),
    INDEX idx_level (level DESC),
    INDEX idx_created_at (created_at),
    INDEX idx_google_id (google_id),
    INDEX idx_facebook_id (facebook_id),
    INDEX idx_apple_id (apple_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: contributor_requests
-- ============================================
DROP TABLE IF EXISTS contributor_requests;

CREATE TABLE contributor_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    requested_role ENUM('CONTRIBUTOR') NOT NULL DEFAULT 'CONTRIBUTOR',
    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    motivation TEXT NOT NULL,
    admin_notes TEXT,
    reviewed_by INT UNSIGNED NULL,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_contributor_requests_user_id (user_id),
    INDEX idx_contributor_requests_status (status),
    INDEX idx_contributor_requests_created_at (created_at),
    INDEX idx_contributor_requests_reviewed_by (reviewed_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: tourist_sites
-- ============================================
DROP TABLE IF EXISTS tourist_sites;

CREATE TABLE tourist_sites (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255),
    description TEXT,
    description_ar TEXT,
    category_id INT UNSIGNED NOT NULL,
    subcategory VARCHAR(100),
    
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address VARCHAR(500),
    city VARCHAR(100),
    region VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) NOT NULL DEFAULT 'MA',
    
    phone_number VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(500),
    social_media JSON,
    
    price_range ENUM('BUDGET', 'MODERATE', 'EXPENSIVE', 'LUXURY'),
    
    accepts_card_payment BOOLEAN NOT NULL DEFAULT FALSE,
    has_wifi BOOLEAN NOT NULL DEFAULT FALSE,
    has_parking BOOLEAN NOT NULL DEFAULT FALSE,
    is_accessible BOOLEAN NOT NULL DEFAULT FALSE,
    amenities JSON,
    
    average_rating DECIMAL(3, 2) NOT NULL DEFAULT 0.00 
        CHECK (average_rating >= 0 AND average_rating <= 5),
    total_reviews INT UNSIGNED NOT NULL DEFAULT 0,
    freshness_score INT UNSIGNED NOT NULL DEFAULT 0 
        CHECK (freshness_score >= 0 AND freshness_score <= 100),
    freshness_status ENUM('FRESH', 'RECENT', 'OLD', 'OBSOLETE') 
        NOT NULL DEFAULT 'OBSOLETE',
    last_verified_at TIMESTAMP NULL,
    last_updated_at TIMESTAMP NULL,
    
    cover_photo VARCHAR(500),
    
    owner_id INT UNSIGNED NULL,
    is_professional_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    subscription_plan ENUM('FREE', 'BASIC', 'PRO', 'PREMIUM'),
    
    status ENUM('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REPORTED') 
        NOT NULL DEFAULT 'DRAFT',
    verification_status ENUM('PENDING', 'VERIFIED', 'REJECTED') 
        NOT NULL DEFAULT 'PENDING',
    moderation_notes TEXT,
    moderated_by INT UNSIGNED NULL,
    moderated_at TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    
    views_count INT UNSIGNED NOT NULL DEFAULT 0,
    favorites_count INT UNSIGNED NOT NULL DEFAULT 0,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (category_id) REFERENCES categories(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES users(id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (moderated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_category_id (category_id),
    INDEX idx_owner_id (owner_id),
    INDEX idx_location (latitude, longitude),
    INDEX idx_city (city),
    INDEX idx_region (region),
    INDEX idx_status (status),
    INDEX idx_moderated_by (moderated_by),
    INDEX idx_is_active (is_active),
    INDEX idx_is_featured (is_featured),
    INDEX idx_freshness_score (freshness_score DESC),
    INDEX idx_average_rating (average_rating DESC),
    INDEX idx_created_at (created_at),
    INDEX idx_freshness_rating (freshness_score DESC, average_rating DESC),
    FULLTEXT INDEX idx_fulltext_search (name, description, address, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: opening_hours
-- ============================================
DROP TABLE IF EXISTS opening_hours;

CREATE TABLE opening_hours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id INT UNSIGNED NOT NULL,
    day_of_week ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 
                     'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
    opens_at TIME,
    closes_at TIME,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    is_24_hours BOOLEAN NOT NULL DEFAULT FALSE,
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_id) REFERENCES tourist_sites(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_site_id (site_id),
    INDEX idx_day_of_week (day_of_week),
    UNIQUE KEY unique_site_day (site_id, day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
