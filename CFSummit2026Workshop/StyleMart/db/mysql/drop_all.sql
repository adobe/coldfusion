-- StyleMart Database Schema for MySQL
-- File: drop_all.sql
-- Description: Drop all tables and database (USE WITH CAUTION!)
-- WARNING: This will permanently delete all data!

-- Disable foreign key checks to allow dropping tables in any order
SET FOREIGN_KEY_CHECKS = 0;

USE stylemart;

-- Drop all tables in reverse dependency order
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS transactional_emails;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS applied_coupons;
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS carts;
DROP TABLE IF EXISTS promotions;
DROP TABLE IF EXISTS coupons;
DROP TABLE IF EXISTS prices;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS product_reviews;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS product_images;
DROP TABLE IF EXISTS product_variants;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS loyalty_tiers;
DROP TABLE IF EXISTS categories;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Optionally drop the entire database
-- Uncomment the line below to drop the database itself
-- DROP DATABASE IF EXISTS stylemart;

SELECT 'All tables dropped successfully' AS status;
