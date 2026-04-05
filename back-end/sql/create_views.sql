-- ============================================
-- MOROCCOCHECK - VIEWS
-- Version: 1.0
-- Date: 2026-01-16
-- ============================================

-- View: User statistics
CREATE OR REPLACE VIEW v_user_stats AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.role,
    u.status,
    u.points,
    u.level,
    u.rank,
    u.checkins_count,
    u.reviews_count,
    u.photos_count,
    COUNT(DISTINCT ub.badge_id) as badges_count,
    COUNT(DISTINCT f.site_id) as favorites_count,
    COALESCE(AVG(r.overall_rating), 0) as avg_rating_given,
    u.created_at,
    u.last_login_at
FROM users u
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN favorites f ON u.id = f.user_id
LEFT JOIN reviews r ON u.id = r.user_id AND r.status = 'PUBLISHED'
GROUP BY u.id;

-- View: Site details with statistics
CREATE OR REPLACE VIEW v_site_details AS
SELECT 
    s.id,
    s.name,
    s.name_ar,
    c.name as category_name,
    s.latitude,
    s.longitude,
    s.city,
    s.region,
    s.average_rating,
    s.total_reviews,
    s.freshness_score,
    s.freshness_status,
    s.is_featured,
    s.is_professional_claimed,
    COUNT(DISTINCT ch.id) as total_checkins,
    COUNT(DISTINCT ch.user_id) as unique_visitors,
    COUNT(DISTINCT p.id) as photos_count,
    s.favorites_count,
    s.views_count,
    DATEDIFF(CURRENT_TIMESTAMP, s.last_verified_at) as days_since_verification,
    s.created_at,
    s.updated_at
FROM tourist_sites s
LEFT JOIN categories c ON s.category_id = c.id
LEFT JOIN checkins ch ON s.id = ch.site_id AND ch.validation_status = 'APPROVED'
LEFT JOIN photos p ON s.id = p.entity_id AND p.entity_type = 'SITE' AND p.status = 'ACTIVE'
WHERE s.is_active = TRUE
GROUP BY s.id;

-- View: Global leaderboard
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.profile_picture,
    u.points,
    u.level,
    u.rank,
    u.checkins_count,
    u.reviews_count,
    COUNT(DISTINCT ub.badge_id) as badges_count,
    RANK() OVER (ORDER BY u.points DESC) as global_rank
FROM users u
LEFT JOIN user_badges ub ON u.id = ub.user_id
WHERE u.status = 'ACTIVE'
GROUP BY u.id
ORDER BY u.points DESC
LIMIT 100;

-- View: Category statistics
CREATE OR REPLACE VIEW v_category_stats AS
SELECT 
    c.id,
    c.name,
    c.name_ar,
    COUNT(DISTINCT s.id) as sites_count,
    COUNT(DISTINCT ch.id) as total_checkins,
    COUNT(DISTINCT r.id) as total_reviews,
    COALESCE(AVG(s.average_rating), 0) as avg_rating,
    COALESCE(AVG(s.freshness_score), 0) as avg_freshness
FROM categories c
LEFT JOIN tourist_sites s ON c.id = s.category_id AND s.is_active = TRUE
LEFT JOIN checkins ch ON s.id = ch.site_id AND ch.validation_status = 'APPROVED'
LEFT JOIN reviews r ON s.id = r.site_id AND r.status = 'PUBLISHED'
WHERE c.is_active = TRUE
GROUP BY c.id
ORDER BY sites_count DESC;

-- View: Recent reviews with details
CREATE OR REPLACE VIEW v_recent_reviews AS
SELECT 
    r.id,
    r.overall_rating,
    r.title,
    r.content,
    r.helpful_count,
    r.visit_date,
    r.created_at,
    u.id as user_id,
    u.first_name,
    u.last_name,
    u.profile_picture,
    u.level,
    u.rank,
    s.id as site_id,
    s.name as site_name,
    s.city as site_city,
    c.name as category_name,
    COUNT(DISTINCT p.id) as photos_count
FROM reviews r
JOIN users u ON r.user_id = u.id
JOIN tourist_sites s ON r.site_id = s.id
JOIN categories c ON s.category_id = c.id
LEFT JOIN photos p ON r.id = p.entity_id AND p.entity_type = 'REVIEW' AND p.status = 'ACTIVE'
WHERE r.status = 'PUBLISHED'
GROUP BY r.id
ORDER BY r.created_at DESC
LIMIT 50;