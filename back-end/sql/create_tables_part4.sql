-- ============================================
-- MOROCCOCHECK - TABLE CREATION SCRIPT - PART 4
-- Tables: favorites, sessions, constraints, triggers
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

-- ============================================
-- TABLE: favorites
-- ============================================
DROP TABLE IF EXISTS favorites;

CREATE TABLE favorites (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    site_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (site_id) REFERENCES tourist_sites(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_site_id (site_id),
    INDEX idx_created_at (created_at DESC),
    
    UNIQUE KEY unique_user_site (user_id, site_id)
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