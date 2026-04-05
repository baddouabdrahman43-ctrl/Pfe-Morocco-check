-- ============================================
-- MOROCCOCHECK - TABLE CREATION SCRIPT
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

-- ============================================
-- TABLE: checkins
-- ============================================
DROP TABLE IF EXISTS checkins;

CREATE TABLE checkins (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    site_id INT UNSIGNED NOT NULL,
    status ENUM('OPEN', 'CLOSED_TEMPORARILY', 'CLOSED_PERMANENTLY', 
                'RENOVATING', 'RELOCATED', 'NO_CHANGE') NOT NULL,
    comment TEXT,
    verification_notes TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(10, 2) NOT NULL,
    distance DECIMAL(10, 2) NOT NULL,
    is_location_verified BOOLEAN NOT NULL DEFAULT FALSE,
    has_photo BOOLEAN NOT NULL DEFAULT FALSE,
    points_earned INT UNSIGNED NOT NULL DEFAULT 10,
    validation_status ENUM('PENDING', 'APPROVED', 'REJECTED', 'FLAGGED') 
        NOT NULL DEFAULT 'PENDING',
    validated_by INT UNSIGNED NULL,
    validated_at TIMESTAMP NULL,
    rejection_reason TEXT,
    device_info JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (site_id) REFERENCES tourist_sites(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (validated_by) REFERENCES users(id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_site_id (site_id),
    INDEX idx_validation_status (validation_status),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_user_site (user_id, site_id),
    INDEX idx_site_date (site_id, created_at DESC),
    
    UNIQUE KEY unique_user_site_date (user_id, site_id, DATE(created_at))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: reviews
-- ============================================
DROP TABLE IF EXISTS reviews;

CREATE TABLE reviews (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    site_id INT UNSIGNED NOT NULL,
    overall_rating DECIMAL(2, 1) NOT NULL 
        CHECK (overall_rating >= 1.0 AND overall_rating <= 5.0),
    service_rating DECIMAL(2, 1) 
        CHECK (service_rating IS NULL OR (service_rating >= 1.0 AND service_rating <= 5.0)),
    cleanliness_rating DECIMAL(2, 1) 
        CHECK (cleanliness_rating IS NULL OR (cleanliness_rating >= 1.0 AND cleanliness_rating <= 5.0)),
    value_rating DECIMAL(2, 1) 
        CHECK (value_rating IS NULL OR (value_rating >= 1.0 AND value_rating <= 5.0)),
    location_rating DECIMAL(2, 1) 
        CHECK (location_rating IS NULL OR (location_rating >= 1.0 AND location_rating <= 5.0)),
    title VARCHAR(255),
    content TEXT NOT NULL,
    visit_date DATE,
    visit_type ENUM('BUSINESS', 'COUPLE', 'FAMILY', 'FRIENDS', 'SOLO'),
    recommendations JSON,
    helpful_count INT UNSIGNED NOT NULL DEFAULT 0,
    not_helpful_count INT UNSIGNED NOT NULL DEFAULT 0,
    reports_count INT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM('PENDING', 'PUBLISHED', 'HIDDEN', 'DELETED') 
        NOT NULL DEFAULT 'PENDING',
    moderation_status ENUM('PENDING', 'APPROVED', 'REJECTED', 'FLAGGED', 'SPAM') 
        NOT NULL DEFAULT 'PENDING',
    moderated_by INT UNSIGNED NULL,
    moderated_at TIMESTAMP NULL,
    moderation_notes TEXT,
    has_owner_response BOOLEAN NOT NULL DEFAULT FALSE,
    owner_response TEXT,
    owner_response_date TIMESTAMP NULL,
    points_earned INT UNSIGNED NOT NULL DEFAULT 15,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (site_id) REFERENCES tourist_sites(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (moderated_by) REFERENCES users(id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_site_id (site_id),
    INDEX idx_overall_rating (overall_rating),
    INDEX idx_status (status),
    INDEX idx_moderation_status (moderation_status),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_site_rating (site_id, overall_rating DESC),
    INDEX idx_site_date (site_id, created_at DESC),
    
    UNIQUE KEY unique_user_site (user_id, site_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: badges
-- ============================================
DROP TABLE IF EXISTS badges;

CREATE TABLE badges (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    description TEXT NOT NULL,
    description_ar TEXT,
    icon VARCHAR(500) NOT NULL,
    color VARCHAR(7) NOT NULL,
    type ENUM('CHECKIN_MILESTONE', 'REVIEW_MILESTONE', 'PHOTO_MILESTONE', 
              'LEVEL_ACHIEVEMENT', 'SPECIAL_EVENT', 'CATEGORY_EXPERT', 
              'REGION_EXPLORER', 'STREAK') NOT NULL,
    category ENUM('CONTRIBUTION', 'EXPLORATION', 'EXPERTISE', 
                  'ACHIEVEMENT', 'SPECIAL') NOT NULL,
    rarity ENUM('COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY') 
        NOT NULL DEFAULT 'COMMON',
    required_checkins INT UNSIGNED NOT NULL DEFAULT 0,
    required_reviews INT UNSIGNED NOT NULL DEFAULT 0,
    required_photos INT UNSIGNED NOT NULL DEFAULT 0,
    required_points INT UNSIGNED NOT NULL DEFAULT 0,
    required_level INT UNSIGNED NOT NULL DEFAULT 0,
    specific_conditions JSON,
    points_reward INT UNSIGNED NOT NULL DEFAULT 0,
    special_perks JSON,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INT UNSIGNED NOT NULL DEFAULT 0,
    total_awarded INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_rarity (rarity),
    INDEX idx_is_active (is_active),
    INDEX idx_display_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: user_badges
-- ============================================
DROP TABLE IF EXISTS user_badges;

CREATE TABLE user_badges (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    badge_id INT UNSIGNED NOT NULL,
    earned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    progress DECIMAL(5, 2) NOT NULL DEFAULT 100.00 
        CHECK (progress >= 0 AND progress <= 100),
    is_displayed BOOLEAN NOT NULL DEFAULT TRUE,
    notification_sent BOOLEAN NOT NULL DEFAULT FALSE,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_badge_id (badge_id),
    INDEX idx_earned_at (earned_at DESC),
    
    UNIQUE KEY unique_user_badge (user_id, badge_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================
-- TABLE: sessions
-- ============================================
DROP TABLE IF EXISTS sessions;

CREATE TABLE sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token VARCHAR(255) UNIQUE NOT NULL,
    device_type ENUM('IOS', 'ANDROID', 'WEB', 'OTHER') NOT NULL,
    device_name VARCHAR(255),
    device_id VARCHAR(255),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    country VARCHAR(2),
    city VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_activity_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_refresh_token (refresh_token),
    INDEX idx_is_active (is_active),
    INDEX idx_expires_at (expires_at),
    INDEX idx_last_activity_at (last_activity_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ADDITIONAL CONSTRAINTS
-- ============================================

-- Users constraints
ALTER TABLE users
    ADD CONSTRAINT chk_phone_number CHECK (phone_number REGEXP '^[+]?[0-9]{8,15}$');

-- Tourist sites constraints
ALTER TABLE tourist_sites
    ADD CONSTRAINT chk_latitude CHECK (latitude BETWEEN 27.0 AND 36.0),
    ADD CONSTRAINT chk_longitude CHECK (longitude BETWEEN -13.0 AND -1.0),
    ADD CONSTRAINT chk_average_rating CHECK (average_rating BETWEEN 0 AND 5),
    ADD CONSTRAINT chk_freshness_score CHECK (freshness_score BETWEEN 0 AND 100);

-- Reviews constraints
ALTER TABLE reviews
    ADD CONSTRAINT chk_overall_rating CHECK (overall_rating BETWEEN 1.0 AND 5.0),
    ADD CONSTRAINT chk_content_length CHECK (CHAR_LENGTH(content) >= 20);

-- Payments constraints
ALTER TABLE payments
    ADD CONSTRAINT chk_amount CHECK (amount >= 0),
    ADD CONSTRAINT chk_total_amount CHECK (total_amount >= amount);

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
