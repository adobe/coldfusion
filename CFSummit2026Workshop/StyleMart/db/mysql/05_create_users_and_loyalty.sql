-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 05_create_users_and_loyalty.sql
-- Description: Loyalty tiers and users tables

USE stylemart;

-- Loyalty tiers (no dependencies)
CREATE TABLE loyalty_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  display_name VARCHAR(100) NOT NULL,
  discount_pct DECIMAL(5,2) NOT NULL,
  spend_threshold_cents INT NOT NULL,
  benefits JSON NOT NULL DEFAULT ('[]'),
  sort_order INT NOT NULL DEFAULT 0,

  -- Constraints
  CONSTRAINT ck_loyalty_discount_range
    CHECK (discount_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_loyalty_threshold
    CHECK (spend_threshold_cents >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Unique index on sort order
CREATE UNIQUE INDEX ux_tiers_sort ON loyalty_tiers(sort_order);

-- Users table (depends on loyalty_tiers)
CREATE TABLE `users` (
  `user_id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `loyalty_tier_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `ux_users_username` (`username`),
  KEY `fk_users_loyalty_tier` (`loyalty_tier_id`),
  CONSTRAINT `fk_users_loyalty_tier` FOREIGN KEY (`loyalty_tier_id`) REFERENCES `loyalty_tiers` (`tier_id`),
  CONSTRAINT `ck_users_display_name_length` CHECK ((char_length(`display_name`) between 1 and 80)),
  CONSTRAINT `ck_users_email_format` CHECK (((`email` is null) or regexp_like(`email`,_utf8mb4'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts with loyalty tier association';

-- Note: Unique email constraint is [S] stretch scope
-- CREATE UNIQUE INDEX ux_users_email ON users(email) WHERE email IS NOT NULL;

-- Comments
ALTER TABLE loyalty_tiers COMMENT = 'Customer loyalty program tiers';
ALTER TABLE users COMMENT = 'User accounts with loyalty tier association';
