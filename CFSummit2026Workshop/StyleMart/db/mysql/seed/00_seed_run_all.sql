-- StyleMart MySQL seed - master loader
-- Run from this directory:  mysql -u root -p < 00_seed_run_all.sql
-- Prereq: DDL must already be loaded (../99_run_all.sql)

USE stylemart;

SOURCE 01_seed_categories.sql;
SOURCE 02_seed_loyalty_tiers.sql;
SOURCE 03_seed_users.sql;
SOURCE 04_seed_products.sql;
SOURCE 05_seed_product_variants.sql;
SOURCE 06_seed_product_images.sql;
SOURCE 07_seed_inventory.sql;
SOURCE 08_seed_coupons.sql;
SOURCE 09_seed_promotions.sql;
SOURCE 10_seed_product_reviews.sql;

SELECT 'Seed complete.' AS status,
       (SELECT COUNT(*) FROM categories)        AS categories,
       (SELECT COUNT(*) FROM loyalty_tiers)     AS loyalty_tiers,
       (SELECT COUNT(*) FROM users)             AS users,
       (SELECT COUNT(*) FROM products)          AS products,
       (SELECT COUNT(*) FROM product_variants)  AS variants,
       (SELECT COUNT(*) FROM product_images)    AS images,
       (SELECT COUNT(*) FROM inventory)         AS inventory_rows,
       (SELECT COUNT(*) FROM coupons)           AS coupons,
       (SELECT COUNT(*) FROM promotions)        AS promotions,
       (SELECT COUNT(*) FROM product_reviews)   AS reviews;
