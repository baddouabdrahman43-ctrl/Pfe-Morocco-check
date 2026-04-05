-- ============================================
-- MOROCCOCHECK - TRIGGERS
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

DELIMITER $$

-- Trigger after checkin insert
CREATE TRIGGER trg_after_checkin_insert
AFTER INSERT ON checkins
FOR EACH ROW
BEGIN
    -- Increment user's checkin count
    UPDATE users
    SET checkins_count = checkins_count + 1
    WHERE id = NEW.user_id;
    
    -- Update site's last verification date
    UPDATE tourist_sites
    SET last_verified_at = CURRENT_TIMESTAMP
    WHERE id = NEW.site_id;
END$$

-- Trigger after checkin delete
CREATE TRIGGER trg_after_checkin_delete
AFTER DELETE ON checkins
FOR EACH ROW
BEGIN
    -- Decrement user's checkin count
    UPDATE users
    SET checkins_count = GREATEST(checkins_count - 1, 0)
    WHERE id = OLD.user_id;
END$$

-- Trigger after review insert
CREATE TRIGGER trg_after_review_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    -- Increment user's review count
    UPDATE users
    SET reviews_count = reviews_count + 1
    WHERE id = NEW.user_id;
    
    -- Recalculate site's average rating
    UPDATE tourist_sites
    SET 
        average_rating = (
            SELECT AVG(overall_rating)
            FROM reviews
            WHERE site_id = NEW.site_id AND status = 'PUBLISHED'
        ),
        total_reviews = total_reviews + 1
    WHERE id = NEW.site_id;
END$$

-- Trigger after review update
CREATE TRIGGER trg_after_review_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    -- If rating or status changed
    IF OLD.overall_rating != NEW.overall_rating 
       OR OLD.status != NEW.status THEN
        -- Recalculate site's average rating
        UPDATE tourist_sites
        SET average_rating = (
            SELECT COALESCE(AVG(overall_rating), 0)
            FROM reviews
            WHERE site_id = NEW.site_id AND status = 'PUBLISHED'
        )
        WHERE id = NEW.site_id;
    END IF;
END$$

-- Trigger after review delete
CREATE TRIGGER trg_after_review_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    -- Decrement user's review count
    UPDATE users
    SET reviews_count = GREATEST(reviews_count - 1, 0)
    WHERE id = OLD.user_id;
    
    -- Recalculate site's average rating
    UPDATE tourist_sites
    SET 
        average_rating = (
            SELECT COALESCE(AVG(overall_rating), 0)
            FROM reviews
            WHERE site_id = OLD.site_id AND status = 'PUBLISHED'
        ),
        total_reviews = GREATEST(total_reviews - 1, 0)
    WHERE id = OLD.site_id;
END$$

-- Trigger after favorite insert
CREATE TRIGGER trg_after_favorite_insert
AFTER INSERT ON favorites
FOR EACH ROW
BEGIN
    UPDATE tourist_sites
    SET favorites_count = favorites_count + 1
    WHERE id = NEW.site_id;
END$$

-- Trigger after favorite delete
CREATE TRIGGER trg_after_favorite_delete
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    UPDATE tourist_sites
    SET favorites_count = GREATEST(favorites_count - 1, 0)
    WHERE id = OLD.site_id;
END$$

-- Trigger before checkin insert
CREATE TRIGGER trg_before_checkin_insert
BEFORE INSERT ON checkins
FOR EACH ROW
BEGIN
    -- Validate distance <= 100m
    IF NEW.distance > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Check-in distance must be <= 100 meters';
    END IF;
    
    -- Calculate points automatically
    IF NEW.has_photo = TRUE THEN
        SET NEW.points_earned = 15;
    ELSE
        SET NEW.points_earned = 10;
    END IF;
END$$

-- Trigger before review insert
CREATE TRIGGER trg_before_review_insert
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    -- Validate content length
    IF CHAR_LENGTH(NEW.content) < 20 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Review content must be at least 20 characters';
    END IF;
    
    -- Calculate points automatically
    SET NEW.points_earned = 15;
END$$

DELIMITER ;