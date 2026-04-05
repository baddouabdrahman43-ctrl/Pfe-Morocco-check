-- ============================================
-- MOROCCOCHECK - TABLE CREATION SCRIPT - PART 2
-- Tables: checkins, reviews, badges, user_badges
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

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
    
    UNIQUE KEY unique_user_site_date (user_id, site_id, created_at)
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

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;