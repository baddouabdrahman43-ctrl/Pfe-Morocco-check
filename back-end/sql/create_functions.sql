-- ============================================
-- MOROCCOCHECK - FUNCTIONS
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

DELIMITER $$

-- Function to calculate distance between GPS points
CREATE FUNCTION fn_calculate_distance(
    lat1 DECIMAL(10,8),
    lng1 DECIMAL(11,8),
    lat2 DECIMAL(10,8),
    lng2 DECIMAL(11,8)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE distance DECIMAL(10,2);
    
    -- Haversine formula
    SET distance = (
        6371000 * ACOS(
            LEAST(1.0,
                COS(RADIANS(lat1)) * 
                COS(RADIANS(lat2)) * 
                COS(RADIANS(lng2) - RADIANS(lng1)) + 
                SIN(RADIANS(lat1)) * 
                SIN(RADIANS(lat2))
            )
        )
    );
    
    RETURN ROUND(distance, 2);
END$$

-- Function to get user level from points
CREATE FUNCTION fn_get_level_from_points(
    p_points INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_level INT;
    
    IF p_points < 100 THEN
        SET v_level = 1;
    ELSEIF p_points < 250 THEN
        SET v_level = 2;
    ELSEIF p_points < 500 THEN
        SET v_level = 3;
    ELSEIF p_points < 1000 THEN
        SET v_level = 4;
    ELSEIF p_points < 2500 THEN
        SET v_level = 5;
    ELSEIF p_points < 5000 THEN
        SET v_level = 6;
    ELSEIF p_points < 10000 THEN
        SET v_level = 7;
    ELSE
        SET v_level = 8;
    END IF;
    
    RETURN v_level;
END$$

-- Function to get user rank from points
CREATE FUNCTION fn_get_rank_from_points(
    p_points INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_rank VARCHAR(20);
    
    IF p_points < 500 THEN
        SET v_rank = 'BRONZE';
    ELSEIF p_points < 1000 THEN
        SET v_rank = 'SILVER';
    ELSEIF p_points < 5000 THEN
        SET v_rank = 'GOLD';
    ELSE
        SET v_rank = 'PLATINUM';
    END IF;
    
    RETURN v_rank;
END$$

DELIMITER ;