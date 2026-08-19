-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 09_create_coupons_and_promotions.sql
-- Description: Coupons and promotions tables

USE stylemart;

-- Coupons table
CREATE TABLE coupons (
  coupon_id VARCHAR(50) PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  type VARCHAR(20) NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  scope_categories JSON NOT NULL DEFAULT ('[]'),
  excludes_categories JSON NOT NULL DEFAULT ('[]'),
  conditions_json JSON NOT NULL DEFAULT ('{}'),
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,

  -- Constraints
  CONSTRAINT ck_coupons_code_format
    CHECK (code = UPPER(code) AND CHAR_LENGTH(code) BETWEEN 3 AND 32),
  CONSTRAINT ck_coupons_type
    CHECK (type IN ('percent', 'fixed')),
  CONSTRAINT ck_coupons_currency
    CHECK (currency = 'USD'),
  CONSTRAINT ck_coupons_valid_period
    CHECK (valid_to > valid_from),
  CONSTRAINT ck_coupons_value_range
    CHECK (
      (type = 'percent' AND value >= 0 AND value <= 100)
      OR (type = 'fixed' AND value >= 0)
    )
  -- Note: Cannot enforce mutual exclusivity of scope_categories and excludes_categories
  -- in MySQL CHECK constraints. Must be validated at application layer.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_coupons_code_active ON coupons(code, active);

-- Promotions table
CREATE TABLE promotions (
  promotion_id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  scope_json JSON NOT NULL DEFAULT ('{}'),
  priority INT NOT NULL DEFAULT 100,
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,

  -- Constraints
  CONSTRAINT ck_promotions_type
    CHECK (type IN ('percent', 'fixed')),
  CONSTRAINT ck_promotions_priority
    CHECK (priority >= 0),
  CONSTRAINT ck_promotions_valid_period
    CHECK (valid_to > valid_from),
  CONSTRAINT ck_promotions_value_range
    CHECK (
      (type = 'percent' AND value >= 0 AND value <= 100)
      OR (type = 'fixed' AND value >= 0)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_promotions_active ON promotions(priority DESC, valid_from, active);

-- Comments
ALTER TABLE coupons COMMENT = 'User-redeemable coupon codes with scoping rules';
ALTER TABLE promotions COMMENT = 'Automatic promotional discounts';
