-- ============================================
-- MOROCCOCHECK - STORED PROCEDURES
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

DELIMITER $$

-- Procedure to calculate freshness score
CREATE PROCEDURE sp_calculate_freshness_score(
    IN p_site_id INT UNSIGNED
)
BEGIN
    DECLARE v_score INT DEFAULT 0;
    DECLARE v_time_score INT DEFAULT 0;
    DECLARE v_activity_score INT DEFAULT 0;
    DECLARE v_review_score INT DEFAULT 0;
    DECLARE v_days_since_verification INT;
    DECLARE v_checkins_24h INT;
    DECLARE v_checkins_7d INT;
    DECLARE v_checkins_30d INT;
    DECLARE v_reviews_30d INT;
    DECLARE v_status VARCHAR(20);
    
    -- Calculate days since last verification
    SELECT DATEDIFF(CURRENT_TIMESTAMP, last_verified_at)
    INTO v_days_since_verification
    FROM tourist_sites
    WHERE id = p_site_id;
    
    -- Time-based score (40 points max)
    IF v_days_since_verification IS NULL OR v_days_since_verification > 30 THEN
        SET v_time_score = 0;
    ELSEIF v_days_since_verification < 1 THEN
        SET v_time_score = 40;
    ELSEIF v_days_since_verification < 7 THEN
        SET v_time_score = 30;
    ELSEIF v_days_since_verification < 30 THEN
        SET v_time_score = 15;
    END IF;
    
    -- Count recent check-ins
    SELECT 
        COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END),
        COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END),
        COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END)
    INTO v_checkins_24h, v_checkins_7d, v_checkins_30d
    FROM checkins
    WHERE site_id = p_site_id AND validation_status = 'APPROVED';
    
    -- Activity-based score (40 points max)
    IF v_checkins_24h > 5 THEN
        SET v_activity_score = 20;
    ELSEIF v_checkins_24h > 2 THEN
        SET v_activity_score = 15;
    ELSEIF v_checkins_24h > 0 THEN
        SET v_activity_score = 10;
    END IF;
    
    IF v_checkins_7d > 10 THEN
        SET v_activity_score = v_activity_score + 15;
    ELSEIF v_checkins_7d > 5 THEN
        SET v_activity_score = v_activity_score + 10;
    ELSEIF v_checkins_7d > 0 THEN
        SET v_activity_score = v_activity_score + 5;
    END IF;
    
    -- Count recent reviews
    SELECT COUNT(*)
    INTO v_reviews_30d
    FROM reviews
    WHERE site_id = p_site_id 
      AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
      AND status = 'PUBLISHED';
    
    -- Review-based score (20 points max)
    IF v_reviews_30d > 5 THEN
        SET v_review_score = 15;
    ELSEIF v_reviews_30d > 2 THEN
        SET v_review_score = 10;
    ELSEIF v_reviews_30d > 0 THEN
        SET v_review_score = 5;
    END IF;
    
    -- Bonus for professional sites
    IF (SELECT is_professional_claimed FROM tourist_sites WHERE id = p_site_id) = TRUE THEN
        SET v_review_score = v_review_score + 5;
    END IF;
    
    -- Calculate total score
    SET v_score = v_time_score + v_activity_score + v_review_score;
    
    -- Limit between 0 and 100
    IF v_score > 100 THEN
        SET v_score = 100;
    ELSEIF v_score < 0 THEN
        SET v_score = 0;
    END IF;
    
    -- Determine status
    IF v_score >= 80 THEN
        SET v_status = 'FRESH';
    ELSEIF v_score >= 50 THEN
        SET v_status = 'RECENT';
    ELSEIF v_score >= 20 THEN
        SET v_status = 'OLD';
    ELSE
        SET v_status = 'OBSOLETE';
    END IF;
    
    -- Update site
    UPDATE tourist_sites
    SET 
        freshness_score = v_score,
        freshness_status = v_status,
        last_updated_at = CURRENT_TIMESTAMP
    WHERE id = p_site_id;
    
END$$

-- Procedure to update all freshness scores
CREATE PROCEDURE sp_update_all_freshness_scores()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_site_id INT;
    DECLARE cur CURSOR FOR 
        SELECT id FROM tourist_sites WHERE is_active = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_site_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        CALL sp_calculate_freshness_score(v_site_id);
    END LOOP;
    
    CLOSE cur;
    
    SELECT CONCAT('Updated freshness scores for ', COUNT(*), ' sites') as message
    FROM tourist_sites WHERE is_active = TRUE;
END$$

-- Procedure to check and award badges
CREATE PROCEDURE sp_check_and_award_badges(
    IN p_user_id INT UNSIGNED
)
BEGIN
    DECLARE v_checkins_count INT;
    DECLARE v_reviews_count INT;
    DECLARE v_photos_count INT;
    DECLARE v_points INT;
    DECLARE v_level INT;
    
    -- Get user stats
    SELECT 
        checkins_count, 
        reviews_count, 
        photos_count, 
        points, 
        level
    INTO 
        v_checkins_count, 
        v_reviews_count, 
        v_photos_count, 
        v_points, 
        v_level
    FROM users
    WHERE id = p_user_id;
    
    -- Check all unearned badges
    INSERT INTO user_badges (user_id, badge_id, earned_at, progress)
    SELECT 
        p_user_id,
        b.id,
        CURRENT_TIMESTAMP,
        100.00
    FROM badges b
    WHERE b.is_active = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM user_badges ub 
          WHERE ub.user_id = p_user_id AND ub.badge_id = b.id
      )
      AND (
          -- Check-in badges
          (b.type = 'CHECKIN_MILESTONE' AND v_checkins_count >= b.required_checkins)
          OR
          -- Review badges
          (b.type = 'REVIEW_MILESTONE' AND v_reviews_count >= b.required_reviews)
          OR
          -- Photo badges
          (b.type = 'PHOTO_MILESTONE' AND v_photos_count >= b.required_photos)
          OR
          -- Level badges
          (b.type = 'LEVEL_ACHIEVEMENT' AND v_level >= b.required_level)
          OR
          -- Points badges
          (b.required_points > 0 AND v_points >= b.required_points)
      );
    
    -- Award points for new badges
    UPDATE users
    SET points = points + (
        SELECT COALESCE(SUM(b.points_reward), 0)
        FROM user_badges ub
        JOIN badges b ON ub.badge_id = b.id
        WHERE ub.user_id = p_user_id
          AND ub.earned_at >= DATE_SUB(NOW(), INTERVAL 1 MINUTE)
    )
    WHERE id = p_user_id;
    
    -- Return new badges
    SELECT 
        b.id,
        b.name,
        b.description,
        b.icon,
        b.points_reward,
        ub.earned_at
    FROM user_badges ub
    JOIN badges b ON ub.badge_id = b.id
    WHERE ub.user_id = p_user_id
      AND ub.earned_at >= DATE_SUB(NOW(), INTERVAL 1 MINUTE);
      
END$$

-- Procedure to create a check-in
CREATE PROCEDURE sp_create_checkin(
    IN p_user_id INT UNSIGNED,
    IN p_site_id INT UNSIGNED,
    IN p_status VARCHAR(50),
    IN p_comment TEXT,
    IN p_latitude DECIMAL(10,8),
    IN p_longitude DECIMAL(11,8),
    IN p_accuracy DECIMAL(10,2),
    IN p_has_photo BOOLEAN,
    OUT p_checkin_id INT UNSIGNED,
    OUT p_points_earned INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_site_lat DECIMAL(10,8);
    DECLARE v_site_lng DECIMAL(11,8);
    DECLARE v_distance DECIMAL(10,2);
    DECLARE v_last_checkin_date DATE;
    DECLARE v_user_role VARCHAR(20);
    
    -- Check user role
    SELECT role INTO v_user_role
    FROM users
    WHERE id = p_user_id;
    
    IF v_user_role = 'TOURIST' THEN
        SET p_message = 'Only contributors and above can check in';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_message;
    END IF;
    
    -- Get site coordinates
    SELECT latitude, longitude
    INTO v_site_lat, v_site_lng
    FROM tourist_sites
    WHERE id = p_site_id;
    
    -- Calculate distance (simplified haversine)
    SET v_distance = (
        6371000 * ACOS(
            COS(RADIANS(p_latitude)) * 
            COS(RADIANS(v_site_lat)) * 
            COS(RADIANS(v_site_lng) - RADIANS(p_longitude)) + 
            SIN(RADIANS(p_latitude)) * 
            SIN(RADIANS(v_site_lat))
        )
    );
    
    -- Validate distance
    IF v_distance > 100 THEN
        SET p_message = CONCAT('Too far from site: ', ROUND(v_distance, 0), 'm (max 100m)');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_message;
    END IF;
    
    -- Check cooldown (1 check-in per site per day)
    SELECT DATE(created_at)
    INTO v_last_checkin_date
    FROM checkins
    WHERE user_id = p_user_id AND site_id = p_site_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_last_checkin_date = CURDATE() THEN
        SET p_message = 'Already checked in today at this site';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_message;
    END IF;
    
    -- Calculate points
    IF p_has_photo = TRUE THEN
        SET p_points_earned = 15;
    ELSE
        SET p_points_earned = 10;
    END IF;
    
    -- Insert check-in
    INSERT INTO checkins (
        user_id, site_id, status, comment,
        latitude, longitude, accuracy, distance,
        has_photo, points_earned, validation_status
    ) VALUES (
        p_user_id, p_site_id, p_status, p_comment,
        p_latitude, p_longitude, p_accuracy, v_distance,
        p_has_photo, p_points_earned, 'APPROVED'
    );
    
    SET p_checkin_id = LAST_INSERT_ID();
    
    -- Add points to user
    UPDATE users
    SET points = points + p_points_earned
    WHERE id = p_user_id;
    
    -- Check badges
    CALL sp_check_and_award_badges(p_user_id);
    
    -- Recalculate site freshness
    CALL sp_calculate_freshness_score(p_site_id);
    
    SET p_message = 'Check-in created successfully';
    
END$$

DELIMITER ;