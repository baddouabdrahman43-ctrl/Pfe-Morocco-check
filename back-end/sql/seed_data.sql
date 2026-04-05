-- ============================================
-- MOROCCOCHECK - SEED DATA
-- Version: 1.1
-- Scope: Agadir only
-- ============================================

-- Insert categories
INSERT INTO categories (name, name_ar, description, icon, color, display_order) VALUES
('Restaurant', 'Matam', 'Restaurants et cafes a Agadir', 'restaurant', '#FF5722', 1),
('Hotel', 'Fondoq', 'Hotels et hebergements a Agadir', 'hotel', '#2196F3', 2),
('Museum', 'Mathaf', 'Musees et galeries a Agadir', 'museum', '#9C27B0', 3),
('Historical Site', 'Mawqi Tarikhi', 'Sites historiques a Agadir', 'historic', '#795548', 4),
('Beach', 'Shatie', 'Plages a Agadir', 'beach', '#00BCD4', 5),
('Park', 'Hadiqa', 'Parcs et jardins a Agadir', 'park', '#4CAF50', 6),
('Shopping', 'Tasawoq', 'Centres commerciaux et marches a Agadir', 'shopping', '#FF9800', 7),
('Entertainment', 'Tarfiha', 'Loisirs et divertissements a Agadir', 'entertainment', '#E91E63', 8),
('Religious Site', 'Mawqi Dini', 'Mosquees et sites religieux a Agadir', 'mosque', '#009688', 9),
('Natural Site', 'Mawqi Tabii', 'Sites naturels autour d Agadir', 'nature', '#8BC34A', 10);

-- Insert subcategories for Restaurant
INSERT INTO categories (name, name_ar, parent_id, display_order)
SELECT 'Moroccan Cuisine', 'Matbakh Maghribi', id, 1 FROM categories WHERE name = 'Restaurant';
INSERT INTO categories (name, name_ar, parent_id, display_order)
SELECT 'Fast Food', 'Wajabat Saria', id, 2 FROM categories WHERE name = 'Restaurant';
INSERT INTO categories (name, name_ar, parent_id, display_order)
SELECT 'Cafe', 'Maqha', id, 3 FROM categories WHERE name = 'Restaurant';

-- Seeded credentials for demo accounts: password123
-- Insert admin user
INSERT INTO users (
    email, password_hash, first_name, last_name,
    role, status, is_email_verified,
    points, level, rank
) VALUES (
    'admin@moroccocheck.com',
    '$2b$10$bVVVK69jU3YmTlUumt5e9eXnzYGGHWdNt4THtjeqU5P0nmDoWWYzy',
    'Admin',
    'MoroccoCheck',
    'ADMIN',
    'ACTIVE',
    TRUE,
    10000,
    8,
    'PLATINUM'
);

-- Insert contributor user
INSERT INTO users (
    email, password_hash, first_name, last_name,
    role, status, is_email_verified,
    points, level, rank
) VALUES (
    'contributor@test.com',
    '$2b$10$bVVVK69jU3YmTlUumt5e9eXnzYGGHWdNt4THtjeqU5P0nmDoWWYzy',
    'Ahmed',
    'Benali',
    'CONTRIBUTOR',
    'ACTIVE',
    TRUE,
    250,
    3,
    'BRONZE'
);

-- Insert professional user
INSERT INTO users (
    email, password_hash, first_name, last_name,
    role, status, is_email_verified,
    points, level, rank
) VALUES (
    'pro@test.com',
    '$2b$10$bVVVK69jU3YmTlUumt5e9eXnzYGGHWdNt4THtjeqU5P0nmDoWWYzy',
    'Fatima',
    'Alami',
    'PROFESSIONAL',
    'ACTIVE',
    TRUE,
    1200,
    5,
    'GOLD'
);

-- Get category IDs
SET @cat_restaurant = (SELECT id FROM categories WHERE name = 'Restaurant' LIMIT 1);
SET @cat_hotel = (SELECT id FROM categories WHERE name = 'Hotel' LIMIT 1);
SET @cat_museum = (SELECT id FROM categories WHERE name = 'Museum' LIMIT 1);

-- Insert tourist sites focused on Agadir
INSERT INTO tourist_sites (
    name, name_ar, description, category_id,
    latitude, longitude, address, city, region, country,
    phone_number, website,
    price_range, accepts_card_payment, has_wifi, has_parking,
    status, verification_status, is_active
) VALUES (
    'Pure Passion Agadir',
    'Pure Passion Agadir',
    'Restaurant avec vue sur la marina d Agadir, ideal pour une sortie en bord de mer.',
    @cat_restaurant,
    30.4259, -9.6065,
    'Marina d Agadir, Secteur Balneaire',
    'Agadir',
    'Souss-Massa',
    'MA',
    '+212 5 28 84 42 22',
    'https://www.purepassion.ma',
    'EXPENSIVE',
    TRUE, TRUE, TRUE,
    'PUBLISHED', 'VERIFIED', TRUE
);

INSERT INTO tourist_sites (
    name, name_ar, description, category_id,
    latitude, longitude, address, city, region, country,
    phone_number, website,
    price_range, accepts_card_payment, has_wifi, has_parking,
    status, verification_status, is_active
) VALUES (
    'Sofitel Agadir Thalassa Sea & Spa',
    'Sofitel Agadir Thalassa Sea and Spa',
    'Hotel haut de gamme en front de mer, tres connu a Agadir pour son spa et son acces plage.',
    @cat_hotel,
    30.3897, -9.5976,
    'Baie des Palmiers, Cite Founty P5',
    'Agadir',
    'Souss-Massa',
    'MA',
    '+212 5 28 84 56 00',
    'https://all.accor.com',
    'LUXURY',
    TRUE, TRUE, TRUE,
    'PUBLISHED', 'VERIFIED', TRUE
);

INSERT INTO tourist_sites (
    name, name_ar, description, category_id,
    latitude, longitude, address, city, region, country,
    phone_number,
    status, verification_status, is_active
) VALUES (
    'Musee du Patrimoine Amazigh d Agadir',
    'Musee du Patrimoine Amazigh d Agadir',
    'Musee dedie au patrimoine amazigh, situe au coeur d Agadir.',
    @cat_museum,
    30.4205, -9.5928,
    'Avenue Hassan II',
    'Agadir',
    'Souss-Massa',
    'MA',
    '+212 5 28 82 00 20',
    'PUBLISHED', 'VERIFIED', TRUE
);

-- Insert badges
INSERT INTO badges (
    name, name_ar, description, icon, color,
    type, category, rarity,
    required_checkins, points_reward
) VALUES
('First Steps', 'First Steps', 'Complete your first check-in', 'star', '#FFD700',
 'CHECKIN_MILESTONE', 'CONTRIBUTION', 'COMMON', 1, 10),
('Explorer', 'Explorer', 'Complete 10 check-ins', 'explore', '#4CAF50',
 'CHECKIN_MILESTONE', 'EXPLORATION', 'UNCOMMON', 10, 50),
('Traveler', 'Traveler', 'Complete 50 check-ins', 'travel', '#2196F3',
 'CHECKIN_MILESTONE', 'EXPLORATION', 'RARE', 50, 100),
('Adventurer', 'Adventurer', 'Complete 100 check-ins', 'adventure', '#9C27B0',
 'CHECKIN_MILESTONE', 'EXPLORATION', 'EPIC', 100, 250),
('Legend', 'Legend', 'Complete 500 check-ins', 'legend', '#FF5722',
 'CHECKIN_MILESTONE', 'EXPLORATION', 'LEGENDARY', 500, 500);

INSERT INTO badges (
    name, name_ar, description, icon, color,
    type, category, rarity,
    required_reviews, points_reward
) VALUES
('Critic', 'Critic', 'Write your first review', 'review', '#FFC107',
 'REVIEW_MILESTONE', 'CONTRIBUTION', 'COMMON', 1, 15),
('Reviewer', 'Reviewer', 'Write 10 reviews', 'reviews', '#FF9800',
 'REVIEW_MILESTONE', 'CONTRIBUTION', 'UNCOMMON', 10, 75),
('Expert Critic', 'Expert Critic', 'Write 50 reviews', 'expert', '#F44336',
 'REVIEW_MILESTONE', 'EXPERTISE', 'RARE', 50, 150);

INSERT INTO badges (
    name, name_ar, description, icon, color,
    type, category, rarity,
    required_level, points_reward
) VALUES
('Bronze Member', 'Bronze Member', 'Reach level 3', 'bronze', '#CD7F32',
 'LEVEL_ACHIEVEMENT', 'ACHIEVEMENT', 'COMMON', 3, 25),
('Silver Member', 'Silver Member', 'Reach level 5', 'silver', '#C0C0C0',
 'LEVEL_ACHIEVEMENT', 'ACHIEVEMENT', 'UNCOMMON', 5, 50),
('Gold Member', 'Gold Member', 'Reach level 7', 'gold', '#FFD700',
 'LEVEL_ACHIEVEMENT', 'ACHIEVEMENT', 'RARE', 7, 100);

-- Insert check-in on an Agadir site
SET @user_id = (SELECT id FROM users WHERE email = 'contributor@test.com');
SET @site_id = (SELECT id FROM tourist_sites WHERE name = 'Pure Passion Agadir');

INSERT INTO checkins (
    user_id, site_id, status, comment,
    latitude, longitude, accuracy, distance,
    has_photo, points_earned, validation_status
) VALUES (
    @user_id, @site_id, 'OPEN',
    'Belle vue sur la marina, service tres agreable et ambiance detendue.',
    30.4259, -9.6065, 10.5, 5.2,
    TRUE, 15, 'APPROVED'
);

-- Insert review on an Agadir site
INSERT INTO reviews (
    user_id, site_id,
    overall_rating, service_rating, cleanliness_rating, value_rating, location_rating,
    title, content, visit_date, visit_type,
    helpful_count, status, moderation_status, points_earned
) VALUES (
    @user_id, @site_id,
    4.5, 5.0, 4.5, 4.0, 5.0,
    'Tres belle experience a Agadir',
    'Vue magnifique sur la marina d Agadir, cuisine soignee et service attentionne. Une excellente adresse pour decouvrir le front de mer.',
    '2026-01-10', 'COUPLE',
    5, 'PUBLISHED', 'APPROVED', 15
);

-- Insert opening hours for Pure Passion Agadir
INSERT INTO opening_hours (site_id, day_of_week, opens_at, closes_at, is_closed)
VALUES
(@site_id, 'MONDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'TUESDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'WEDNESDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'THURSDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'FRIDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'SATURDAY', '08:00:00', '23:00:00', FALSE),
(@site_id, 'SUNDAY', '08:00:00', '23:00:00', FALSE);

-- Insert favorite
INSERT INTO favorites (user_id, site_id)
VALUES (@user_id, @site_id);

-- Update user stats
UPDATE users SET
    checkins_count = 1,
    reviews_count = 1,
    photos_count = 1
WHERE id = @user_id;

-- Update site stats
UPDATE tourist_sites SET
    total_reviews = 1,
    average_rating = 4.5,
    favorites_count = 1
WHERE id = @site_id;
