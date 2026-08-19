-- StyleMart Seed Data for MySQL
-- Inserts ~10 rows per table for demo/development
-- Run AFTER 99_run_all.sql has created all tables

USE stylemart;

-- ==============================================================================
-- 1. Categories (12 rows)
-- ==============================================================================
INSERT INTO categories (slug, display_name, description, hero_image, parent_slug, sort_order) VALUES
('jackets', 'Jackets', 'Outerwear for every occasion', 'assets/img/placeholders/jackets-hero.svg', NULL, 1),
('shirts', 'Shirts', 'Dress shirts and casual tops', 'assets/img/placeholders/shirts-hero.svg', NULL, 2),
('tshirts', 'T-Shirts', 'Casual cotton tees and henleys', 'assets/img/placeholders/tshirts-hero.svg', NULL, 3),
('jeans', 'Jeans', 'Denim for every style', 'assets/img/placeholders/jeans-hero.svg', NULL, 4),
('dresses', 'Dresses', 'From cocktail to casual', 'assets/img/placeholders/dresses-hero.svg', NULL, 5),
('sneakers', 'Sneakers', 'Athletic and casual footwear', 'assets/img/placeholders/sneakers-hero.svg', NULL, 6),
('formal-shoes', 'Formal Shoes', 'Oxford, derby, and loafers', 'assets/img/placeholders/formal-shoes-hero.svg', NULL, 7),
('backpacks', 'Backpacks', 'Travel and everyday carry', 'assets/img/placeholders/backpacks-hero.svg', NULL, 8),
('sunglasses', 'Sunglasses', 'UV protection with style', 'assets/img/placeholders/sunglasses-hero.svg', NULL, 9),
('raincoats', 'Raincoats', 'Stay dry in style', 'assets/img/placeholders/raincoats-hero.svg', NULL, 10),
('winter-wear', 'Winter Wear', 'Cold weather essentials', 'assets/img/placeholders/winter-wear-hero.svg', NULL, 11),
('accessories', 'Accessories', 'Belts, scarves, and more', 'assets/img/placeholders/accessories-hero.svg', NULL, 12);

-- ==============================================================================
-- 2. Loyalty Tiers (3 rows)
-- ==============================================================================
INSERT INTO loyalty_tiers (tier_id, display_name, discount_pct, spend_threshold_cents, benefits, sort_order) VALUES
('tier_bronze', 'Bronze', 0.00, 0, '["Free shipping on orders over $50", "Birthday reward"]', 1),
('tier_silver', 'Silver', 5.00, 50000, '["5% off all orders", "Free shipping", "Early access to sales", "Birthday reward"]', 2),
('tier_gold', 'Gold', 10.00, 200000, '["10% off all orders", "Free express shipping", "Early access to sales", "Exclusive events", "Birthday reward"]', 3);

-- ==============================================================================
-- 3. Users (5 rows)
-- ==============================================================================
INSERT INTO users (user_id, display_name, email, loyalty_tier_id, created_at) VALUES
('usr_demo_001', 'Jordan', 'jordan@example.com', 'tier_silver', '2025-08-12 00:00:00'),
('usr_demo_002', 'Alex', 'alex@example.com', 'tier_bronze', '2025-09-01 00:00:00'),
('usr_demo_003', 'Sam', 'sam@example.com', 'tier_gold', '2025-06-15 00:00:00'),
('usr_demo_004', 'Riley', 'riley@example.com', 'tier_bronze', '2026-01-10 00:00:00'),
('usr_demo_005', 'Morgan', 'morgan@example.com', 'tier_silver', '2025-11-20 00:00:00');

-- ==============================================================================
-- 4. Products (10 rows)
-- ==============================================================================
INSERT INTO products (product_id, slug, name, brand, category, subcategory, description, care_instructions, base_price_cents, currency, image_url, attributes, occasion_tags, average_rating, review_count) VALUES
('prd_01HZX01T001', 'travel-blazer-prd-01hzx01t001', 'Travel Blazer', 'StyleMart', 'jackets', 'blazer', 'Tailored travel blazer in a wrinkle-resistant wool-poly blend.', 'Machine wash cold; lay flat to dry.', 18900, 'USD', 'assets/img/placeholders/jacket-navy.svg', '{"fit":"tailored","fabric":"wool-poly","closure":"two-button","care":"machine-washable"}', '["smart-casual","travel","conference"]', 4.40, 32),
('prd_01HZX01T002', 'quilted-down-parka-prd-01hzx01t002', 'Quilted Down Parka', 'StyleMart', 'jackets', 'parka', 'Warm quilted down parka with water-resistant nylon shell for cold-weather travel.', 'Dry clean only; do not tumble dry.', 22900, 'USD', 'assets/img/placeholders/jackets-charcoal.svg', '{"fit":"relaxed","fabric":"nylon-shell","closure":"zip-button","care":"dry-clean-only"}', '["outdoor","travel","weekend"]', 4.70, 88),
('prd_01HZX01T003', 'linen-field-jacket-prd-01hzx01t003', 'Linen Field Jacket', 'StyleMart', 'jackets', 'field-jacket', 'Lightweight linen-cotton field jacket with multiple cargo pockets.', 'Machine wash cold; tumble dry low.', 14500, 'USD', 'assets/img/placeholders/jackets-olive.svg', '{"fit":"straight","fabric":"linen-cotton","closure":"snap-buttons","care":"machine-washable"}', '["outdoor","weekend","smart-casual"]', 4.20, 54),
('prd_01HZX01T004', 'slim-stretch-chinos-prd-01hzx01t004', 'Slim Stretch Chinos', 'StyleMart', 'jeans', NULL, 'Comfortable slim-fit chinos with 2% stretch for all-day wear.', 'Machine wash warm; tumble dry medium.', 7900, 'USD', 'assets/img/placeholders/jeans-navy.svg', '{"fit":"slim","fabric":"cotton-stretch","closure":"zip-fly","care":"machine-washable"}', '["smart-casual","travel","office"]', 4.30, 67),
('prd_01HZX01T005', 'merino-crew-neck-tee-prd-01hzx01t005', 'Merino Crew-Neck Tee', 'StyleMart', 'tshirts', NULL, 'Premium merino wool t-shirt that regulates temperature and resists odor.', 'Machine wash cold; do not tumble dry.', 6500, 'USD', 'assets/img/placeholders/tshirt-charcoal.svg', '{"fit":"regular","fabric":"merino-wool","neckline":"crew","care":"machine-washable"}', '["travel","everyday","layering"]', 4.50, 41),
('prd_01HZX01T006', 'oxford-button-down-prd-01hzx01t006', 'Oxford Button-Down', 'StyleMart', 'shirts', NULL, 'Classic oxford cloth button-down in a relaxed fit.', 'Machine wash warm; iron medium heat.', 8900, 'USD', 'assets/img/placeholders/shirt-white.svg', '{"fit":"relaxed","fabric":"oxford-cotton","closure":"button-front","care":"machine-washable"}', '["smart-casual","office","conference"]', 4.10, 29),
('prd_01HZX01T007', 'canvas-travel-sneakers-prd-01hzx01t007', 'Canvas Travel Sneakers', 'StyleMart', 'sneakers', NULL, 'Lightweight canvas sneakers perfect for sightseeing.', 'Spot clean with damp cloth.', 9500, 'USD', 'assets/img/placeholders/sneakers-white.svg', '{"fit":"true-to-size","fabric":"canvas","sole":"rubber","care":"spot-clean"}', '["travel","everyday","weekend"]', 4.60, 73),
('prd_01HZX01T008', 'packable-rain-shell-prd-01hzx01t008', 'Packable Rain Shell', 'StyleMart', 'raincoats', NULL, 'Ultra-light waterproof shell that packs into its own pocket.', 'Machine wash cold; hang dry.', 11900, 'USD', 'assets/img/placeholders/raincoat-navy.svg', '{"fit":"regular","fabric":"ripstop-nylon","closure":"full-zip","care":"machine-washable"}', '["travel","outdoor","rainy"]', 4.40, 36),
('prd_01HZX01T009', 'leather-weekender-bag-prd-01hzx01t009', 'Leather Weekender Bag', 'StyleMart', 'backpacks', NULL, 'Full-grain leather duffle for weekend getaways.', 'Wipe with leather conditioner.', 24900, 'USD', 'assets/img/placeholders/bag-brown.svg', '{"material":"full-grain-leather","capacity":"45L","care":"leather-conditioner"}', '["travel","weekend","luxury"]', 4.80, 22),
('prd_01HZX01T010', 'aviator-sunglasses-prd-01hzx01t010', 'Aviator Sunglasses', 'StyleMart', 'sunglasses', NULL, 'Classic aviator frame with polarized lenses and UV400 protection.', 'Clean with microfiber cloth.', 12900, 'USD', 'assets/img/placeholders/sunglasses-gold.svg', '{"frame":"metal","lens":"polarized","protection":"UV400","care":"microfiber-cloth"}', '["travel","everyday","outdoor"]', 4.30, 48);

-- ==============================================================================
-- 5. Product Variants (~3 per product = 30 rows)
-- ==============================================================================
INSERT INTO product_variants (variant_id, product_id, size, color, sku) VALUES
-- Travel Blazer
('var_01HZX01T001_S_navy', 'prd_01HZX01T001', 'S', 'navy', 'SM-BLZ-NAV-S'),
('var_01HZX01T001_M_navy', 'prd_01HZX01T001', 'M', 'navy', 'SM-BLZ-NAV-M'),
('var_01HZX01T001_L_navy', 'prd_01HZX01T001', 'L', 'navy', 'SM-BLZ-NAV-L'),
('var_01HZX01T001_M_charcoal', 'prd_01HZX01T001', 'M', 'charcoal', 'SM-BLZ-CHR-M'),
-- Quilted Down Parka
('var_01HZX01T002_M_charcoal', 'prd_01HZX01T002', 'M', 'charcoal', 'SM-PRK-CHA-M'),
('var_01HZX01T002_L_charcoal', 'prd_01HZX01T002', 'L', 'charcoal', 'SM-PRK-CHA-L'),
('var_01HZX01T002_M_black', 'prd_01HZX01T002', 'M', 'black', 'SM-PRK-BLK-M'),
-- Linen Field Jacket
('var_01HZX01T003_M_olive', 'prd_01HZX01T003', 'M', 'olive', 'SM-FLD-OLV-M'),
('var_01HZX01T003_L_olive', 'prd_01HZX01T003', 'L', 'olive', 'SM-FLD-OLV-L'),
('var_01HZX01T003_M_tan', 'prd_01HZX01T003', 'M', 'tan', 'SM-FLD-TAN-M'),
-- Slim Stretch Chinos
('var_01HZX01T004_30_navy', 'prd_01HZX01T004', '30', 'navy', 'SM-CHN-NAV-30'),
('var_01HZX01T004_32_navy', 'prd_01HZX01T004', '32', 'navy', 'SM-CHN-NAV-32'),
('var_01HZX01T004_34_navy', 'prd_01HZX01T004', '34', 'navy', 'SM-CHN-NAV-34'),
-- Merino Crew-Neck Tee
('var_01HZX01T005_M_charcoal', 'prd_01HZX01T005', 'M', 'charcoal', 'SM-MER-CHR-M'),
('var_01HZX01T005_L_charcoal', 'prd_01HZX01T005', 'L', 'charcoal', 'SM-MER-CHR-L'),
('var_01HZX01T005_M_black', 'prd_01HZX01T005', 'M', 'black', 'SM-MER-BLK-M'),
-- Oxford Button-Down
('var_01HZX01T006_M_white', 'prd_01HZX01T006', 'M', 'white', 'SM-OXF-WHT-M'),
('var_01HZX01T006_L_white', 'prd_01HZX01T006', 'L', 'white', 'SM-OXF-WHT-L'),
('var_01HZX01T006_M_navy', 'prd_01HZX01T006', 'M', 'navy', 'SM-OXF-NAV-M'),
-- Canvas Travel Sneakers
('var_01HZX01T007_9_white', 'prd_01HZX01T007', '9', 'white', 'SM-SNK-WHT-9'),
('var_01HZX01T007_10_white', 'prd_01HZX01T007', '10', 'white', 'SM-SNK-WHT-10'),
('var_01HZX01T007_9_navy', 'prd_01HZX01T007', '9', 'navy', 'SM-SNK-NAV-9'),
-- Packable Rain Shell
('var_01HZX01T008_M_navy', 'prd_01HZX01T008', 'M', 'navy', 'SM-RNS-NAV-M'),
('var_01HZX01T008_L_navy', 'prd_01HZX01T008', 'L', 'navy', 'SM-RNS-NAV-L'),
-- Leather Weekender Bag (one-size)
('var_01HZX01T009_OS_brown', 'prd_01HZX01T009', 'OS', 'brown', 'SM-WKN-BRN-OS'),
('var_01HZX01T009_OS_tan', 'prd_01HZX01T009', 'OS', 'tan', 'SM-WKN-TAN-OS'),
-- Aviator Sunglasses (one-size)
('var_01HZX01T010_OS_gold', 'prd_01HZX01T010', 'OS', 'gold', 'SM-AVT-GLD-OS'),
('var_01HZX01T010_OS_black', 'prd_01HZX01T010', 'OS', 'black', 'SM-AVT-BLK-OS');

-- ==============================================================================
-- 6. Product Images (10 rows, one per product)
-- ==============================================================================
INSERT INTO product_images (image_id, product_id, url, alt_text, position, color_ref) VALUES
('img_blazer_01', 'prd_01HZX01T001', 'assets/img/placeholders/jacket-navy.svg', 'Navy travel blazer front view', 0, 'navy'),
('img_parka_01', 'prd_01HZX01T002', 'assets/img/placeholders/jackets-charcoal.svg', 'Charcoal quilted down parka', 0, 'charcoal'),
('img_field_01', 'prd_01HZX01T003', 'assets/img/placeholders/jackets-olive.svg', 'Olive linen field jacket', 0, 'olive'),
('img_chinos_01', 'prd_01HZX01T004', 'assets/img/placeholders/jeans-navy.svg', 'Navy slim stretch chinos', 0, 'navy'),
('img_merino_01', 'prd_01HZX01T005', 'assets/img/placeholders/tshirt-charcoal.svg', 'Charcoal merino crew-neck tee', 0, 'charcoal'),
('img_oxford_01', 'prd_01HZX01T006', 'assets/img/placeholders/shirt-white.svg', 'White oxford button-down', 0, 'white'),
('img_sneaker_01', 'prd_01HZX01T007', 'assets/img/placeholders/sneakers-white.svg', 'White canvas travel sneakers', 0, 'white'),
('img_rain_01', 'prd_01HZX01T008', 'assets/img/placeholders/raincoat-navy.svg', 'Navy packable rain shell', 0, 'navy'),
('img_weekender_01', 'prd_01HZX01T009', 'assets/img/placeholders/bag-brown.svg', 'Brown leather weekender bag', 0, 'brown'),
('img_aviator_01', 'prd_01HZX01T010', 'assets/img/placeholders/sunglasses-gold.svg', 'Gold aviator sunglasses', 0, 'gold');

-- ==============================================================================
-- 7. Inventory (stock for all variants)
-- ==============================================================================
INSERT INTO inventory (variant_id, quantity) VALUES
('var_01HZX01T001_S_navy', 12),
('var_01HZX01T001_M_navy', 18),
('var_01HZX01T001_L_navy', 9),
('var_01HZX01T001_M_charcoal', 6),
('var_01HZX01T002_M_charcoal', 14),
('var_01HZX01T002_L_charcoal', 7),
('var_01HZX01T002_M_black', 11),
('var_01HZX01T003_M_olive', 20),
('var_01HZX01T003_L_olive', 8),
('var_01HZX01T003_M_tan', 15),
('var_01HZX01T004_30_navy', 22),
('var_01HZX01T004_32_navy', 30),
('var_01HZX01T004_34_navy', 25),
('var_01HZX01T005_M_charcoal', 16),
('var_01HZX01T005_L_charcoal', 10),
('var_01HZX01T005_M_black', 13),
('var_01HZX01T006_M_white', 19),
('var_01HZX01T006_L_white', 12),
('var_01HZX01T006_M_navy', 14),
('var_01HZX01T007_9_white', 8),
('var_01HZX01T007_10_white', 11),
('var_01HZX01T007_9_navy', 6),
('var_01HZX01T008_M_navy', 17),
('var_01HZX01T008_L_navy', 9),
('var_01HZX01T009_OS_brown', 5),
('var_01HZX01T009_OS_tan', 4),
('var_01HZX01T010_OS_gold', 20),
('var_01HZX01T010_OS_black', 15);

-- ==============================================================================
-- 8. Prices (public pricing overrides — optional, products already have base_price_cents)
-- ==============================================================================
INSERT INTO prices (price_id, product_id, variant_id, segment, price_cents, currency, valid_from, valid_to, priority) VALUES
('pri_001', 'prd_01HZX01T001', NULL, 'public', 18900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_002', 'prd_01HZX01T002', NULL, 'public', 22900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_003', 'prd_01HZX01T003', NULL, 'public', 14500, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_004', 'prd_01HZX01T004', NULL, 'public', 7900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_005', 'prd_01HZX01T005', NULL, 'public', 6500, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_006', 'prd_01HZX01T006', NULL, 'public', 8900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_007', 'prd_01HZX01T007', NULL, 'public', 9500, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_008', 'prd_01HZX01T008', NULL, 'public', 11900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_009', 'prd_01HZX01T009', NULL, 'public', 24900, 'USD', '2026-01-01 00:00:00', NULL, 100),
('pri_010', 'prd_01HZX01T010', NULL, 'public', 12900, 'USD', '2026-01-01 00:00:00', NULL, 100);

-- ==============================================================================
-- 9. Coupons (2 rows — matches mock: SUMMIT10 and SAVE20)
-- ==============================================================================
INSERT INTO coupons (coupon_id, code, type, value, currency, scope_categories, excludes_categories, conditions_json, valid_from, valid_to, active) VALUES
('cpn_summit10', 'SUMMIT10', 'percent', 10.00, 'USD', '[]', '[]', '{}', '2026-05-01 00:00:00', '2026-12-31 23:59:59', TRUE),
('cpn_save20', 'SAVE20', 'fixed', 20.00, 'USD', '[]', '[]', '{}', '2026-05-01 00:00:00', '2026-12-31 23:59:59', TRUE);

-- ==============================================================================
-- 10. Promotions (2 rows)
-- ==============================================================================
INSERT INTO promotions (promotion_id, name, type, value, scope_json, priority, valid_from, valid_to, active) VALUES
('pro_summit10', 'Summit 10% Off', 'percent', 10.00, '{"categories":["jackets","shirts"]}', 100, '2026-05-01 00:00:00', '2026-06-30 23:59:59', TRUE),
('pro_freeship50', 'Free Shipping Over $50', 'fixed', 0.00, '{"minSubtotal":50}', 50, '2026-04-01 00:00:00', '2026-12-31 23:59:59', TRUE);

-- ==============================================================================
-- 11. User Preferences (for demo user)
-- ==============================================================================
INSERT INTO user_preferences (user_id, preferences, schema_version) VALUES
('usr_demo_001', '{"occasion":"London tech conference","tripLengthDays":5,"climate":"cool, occasional rain","budget":500,"topSize":"M","jeansSize":"32","shoeSize":"9","fitPreference":"regular","colors":["black","navy","gray","beige"],"fabricPreference":"easy-care","dislikes":["bold patterns"],"walkingComfort":"high"}', 1);

-- ==============================================================================
-- 12. Demo Cart (empty active cart for Jordan)
-- ==============================================================================
INSERT INTO carts (cart_id, user_id, status) VALUES
('crt_demo_jordan', 'usr_demo_001', 'active');

-- ==============================================================================
-- 13. Product Reviews (5 sample reviews)
-- ==============================================================================
INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified) VALUES
('rev_001', 'prd_01HZX01T001', 'usr_demo_002', 5, 'Exactly what I needed', 'Great blazer — fits well and looks fantastic for conferences.', TRUE),
('rev_002', 'prd_01HZX01T001', 'usr_demo_003', 4, 'Good quality', 'Nice fabric and construction. Would buy again.', TRUE),
('rev_003', 'prd_01HZX01T004', 'usr_demo_001', 5, 'Perfect travel pants', 'Comfortable all day with just the right amount of stretch.', TRUE),
('rev_004', 'prd_01HZX01T007', 'usr_demo_004', 4, 'Great for walking', 'Wore these all over London. Very comfortable.', FALSE),
('rev_005', 'prd_01HZX01T005', 'usr_demo_005', 5, 'Best travel tee', 'Merino is amazing for travel. No odor after 3 days.', TRUE);

-- ==============================================================================
-- Done
-- ==============================================================================
SELECT 'Seed data loaded successfully' AS status;
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as variant_count FROM product_variants;
SELECT COUNT(*) as user_count FROM users;
