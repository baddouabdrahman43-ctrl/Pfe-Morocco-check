-- ============================================
-- MOROCCOCHECK - TABLE CREATION SCRIPT - PART 3
-- Tables: subscriptions, payments, photos, notifications
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

-- ============================================
-- TABLE: subscriptions
-- ============================================
DROP TABLE IF EXISTS subscriptions;

CREATE TABLE subscriptions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    site_id INT UNSIGNED NULL,
    plan ENUM('FREE', 'BASIC', 'PRO', 'PREMIUM') NOT NULL DEFAULT 'FREE',
    billing_cycle ENUM('MONTHLY', 'QUARTERLY', 'YEARLY') NOT NULL DEFAULT 'MONTHLY',
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'MAD',
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    next_billing_date TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    paused_at TIMESTAMP NULL,
    resumed_at TIMESTAMP NULL,
    status ENUM('ACTIVE', 'EXPIRED', 'CANCELLED', 'PAUSED', 
                'PENDING_PAYMENT', 'PAST_DUE') NOT NULL DEFAULT 'ACTIVE',
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    payment_method_id VARCHAR(255),
    max_photos INT UNSIGNED NOT NULL DEFAULT 50,
    can_respond BOOLEAN NOT NULL DEFAULT FALSE,
    has_analytics BOOLEAN NOT NULL DEFAULT FALSE,
    has_priority_support BOOLEAN NOT NULL DEFAULT FALSE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (site_id) REFERENCES tourist_sites(id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_site_id (site_id),
    INDEX idx_status (status),
    INDEX idx_plan (plan),
    INDEX idx_end_date (end_date),
    INDEX idx_stripe_subscription_id (stripe_subscription_id),
    INDEX idx_stripe_customer_id (stripe_customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: payments
-- ============================================
DROP TABLE IF EXISTS payments;

CREATE TABLE payments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    subscription_id INT UNSIGNED NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'MAD',
    tax DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER', 
                        'MOBILE_MONEY', 'PAYPAL', 'OTHER') NOT NULL,
    stripe_payment_intent_id VARCHAR(255) UNIQUE,
    stripe_charge_id VARCHAR(255),
    transaction_id VARCHAR(255),
    status ENUM('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 
                'CANCELLED', 'REFUNDED', 'PARTIALLY_REFUNDED') 
        NOT NULL DEFAULT 'PENDING',
    failure_reason TEXT,
    refunded_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    refunded_at TIMESTAMP NULL,
    billing_name VARCHAR(255),
    billing_email VARCHAR(255),
    billing_address JSON,
    receipt_url VARCHAR(500),
    invoice_url VARCHAR(500),
    invoice_number VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_stripe_payment_intent_id (stripe_payment_intent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: photos
-- ============================================
DROP TABLE IF EXISTS photos;

CREATE TABLE photos (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    mime_type VARCHAR(50) NOT NULL,
    size INT UNSIGNED NOT NULL,
    width INT UNSIGNED,
    height INT UNSIGNED,
    user_id INT UNSIGNED NOT NULL,
    entity_type ENUM('SITE', 'REVIEW', 'CHECKIN', 'USER_PROFILE') NOT NULL,
    entity_id INT UNSIGNED NOT NULL,
    caption TEXT,
    alt_text VARCHAR(255),
    exif_data JSON,
    location JSON,
    status ENUM('ACTIVE', 'HIDDEN', 'DELETED', 'FLAGGED') 
        NOT NULL DEFAULT 'ACTIVE',
    moderation_status ENUM('PENDING', 'APPROVED', 'REJECTED') 
        NOT NULL DEFAULT 'PENDING',
    views_count INT UNSIGNED NOT NULL DEFAULT 0,
    likes_count INT UNSIGNED NOT NULL DEFAULT 0,
    display_order INT UNSIGNED NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_status (status),
    INDEX idx_moderation_status (moderation_status),
    INDEX idx_created_at (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: notifications
-- ============================================
DROP TABLE IF EXISTS notifications;

CREATE TABLE notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    type ENUM('BADGE_EARNED', 'LEVEL_UP', 'REVIEW_LIKED', 'REVIEW_RESPONSE', 
              'CHECKIN_VALIDATED', 'SUBSCRIPTION_EXPIRING', 'NEW_FOLLOWER', 
              'SYSTEM_ANNOUNCEMENT', 'MODERATION_RESULT') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    icon VARCHAR(255),
    related_entity_type VARCHAR(50),
    related_entity_id INT UNSIGNED,
    action_url VARCHAR(500),
    action_label VARCHAR(100),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP NULL,
    send_push BOOLEAN NOT NULL DEFAULT TRUE,
    send_email BOOLEAN NOT NULL DEFAULT FALSE,
    send_in_app BOOLEAN NOT NULL DEFAULT TRUE,
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'URGENT') 
        NOT NULL DEFAULT 'NORMAL',
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_is_read (is_read),
    INDEX idx_priority (priority),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_user_unread (user_id, is_read, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;