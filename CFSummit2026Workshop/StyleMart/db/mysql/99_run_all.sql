-- StyleMart Database Schema for MySQL
-- File: 99_run_all.sql
-- Description: Master script to execute all table creation scripts in dependency order

-- ==============================================================================
-- STYLEMART E-COMMERCE DATABASE SCHEMA
-- Layer 1 - Commerce Tables (MySQL Version)
-- ==============================================================================
-- This script creates all tables in the correct dependency order
-- NOTE: This file contains all SQL statements inline (no SOURCE commands)
-- ==============================================================================

-- ==============================================================================
-- Step 0: Create database
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS stylemart
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE stylemart;

SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

SELECT 'Database stylemart created successfully' AS status;

-- ==============================================================================
-- Step 1: Foundation tables (no dependencies)
-- ==============================================================================

-- Categories
CREATE TABLE categories (
  slug VARCHAR(80) PRIMARY KEY,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  hero_image VARCHAR(500),
  parent_slug VARCHAR(80),
  sort_order INT NOT NULL DEFAULT 0,

  CONSTRAINT ck_categories_slug_format
    CHECK (slug REGEXP '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT ck_categories_parent_not_self
    CHECK (parent_slug IS NULL OR parent_slug <> slug),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_slug) REFERENCES categories(slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Product categories with hierarchical structure';

CREATE INDEX ix_categories_parent ON categories(parent_slug);

-- Loyalty tiers
CREATE TABLE loyalty_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  display_name VARCHAR(100) NOT NULL,
  discount_pct DECIMAL(5,2) NOT NULL,
  spend_threshold_cents INT NOT NULL,
  benefits JSON NOT NULL DEFAULT ('[]'),
  sort_order INT NOT NULL DEFAULT 0,

  CONSTRAINT ck_loyalty_discount_range
    CHECK (discount_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_loyalty_threshold
    CHECK (spend_threshold_cents >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Customer loyalty program tiers';

CREATE UNIQUE INDEX ux_tiers_sort ON loyalty_tiers(sort_order);

-- Users
CREATE TABLE users (
  user_id VARCHAR(50) PRIMARY KEY,
  display_name VARCHAR(80) NOT NULL,
  email VARCHAR(255),
  loyalty_tier_id VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_users_display_name_length
    CHECK (CHAR_LENGTH(display_name) BETWEEN 1 AND 80),
  CONSTRAINT ck_users_email_format
    CHECK (email IS NULL OR email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'),
  CONSTRAINT fk_users_loyalty_tier
    FOREIGN KEY (loyalty_tier_id) REFERENCES loyalty_tiers(tier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts with loyalty tier association';

-- ==============================================================================
-- Step 2: Product catalog (depends on categories)
-- ==============================================================================

CREATE TABLE products (
  product_id VARCHAR(50) PRIMARY KEY,
  slug VARCHAR(80) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  brand VARCHAR(60) NOT NULL DEFAULT 'StyleMart',
  category VARCHAR(80) NOT NULL,
  subcategory VARCHAR(40),
  description TEXT,
  care_instructions TEXT,
  base_price_cents INT NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  image_url VARCHAR(500) NOT NULL,
  attributes JSON NOT NULL DEFAULT ('{}'),
  occasion_tags JSON NOT NULL DEFAULT ('[]'),
  average_rating DECIMAL(3,2),
  review_count INT NOT NULL DEFAULT 0,
  image_source_ref VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT ck_products_slug_format
    CHECK (slug REGEXP '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT ck_products_brand_format
    CHECK (CHAR_LENGTH(brand) BETWEEN 1 AND 60
           AND brand NOT REGEXP '^\\s|\\s$'),
  CONSTRAINT ck_products_subcategory_format
    CHECK (subcategory IS NULL
           OR (subcategory REGEXP '^[a-z0-9]+(-[a-z0-9]+)*$'
               AND CHAR_LENGTH(subcategory) <= 40)),
  CONSTRAINT ck_products_base_price
    CHECK (base_price_cents >= 0),
  CONSTRAINT ck_products_currency
    CHECK (currency = 'USD'),
  CONSTRAINT ck_products_rating_range
    CHECK (average_rating IS NULL OR average_rating BETWEEN 0 AND 5),
  CONSTRAINT ck_products_review_count
    CHECK (review_count >= 0),
  CONSTRAINT ck_products_updated_after_created
    CHECK (updated_at >= created_at),
  CONSTRAINT fk_products_category
    FOREIGN KEY (category) REFERENCES categories(slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Product catalog with pricing, ratings, and categorization';

CREATE INDEX ix_products_category ON products(category);
CREATE INDEX ix_products_category_price ON products(category, base_price_cents);
CREATE INDEX ix_products_category_rating ON products(category, average_rating DESC);
CREATE INDEX ix_products_category_created ON products(category, created_at DESC);
CREATE FULLTEXT INDEX ix_products_fts ON products(name, description);

-- ==============================================================================
-- Step 3: Product-related tables (depend on products)
-- ==============================================================================

CREATE TABLE product_variants (
  variant_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  size VARCHAR(20) NOT NULL,
  color VARCHAR(50) NOT NULL,
  sku VARCHAR(100) NOT NULL UNIQUE,

  CONSTRAINT ck_variants_size_not_empty
    CHECK (CHAR_LENGTH(size) > 0),
  CONSTRAINT ck_variants_color_not_empty
    CHECK (CHAR_LENGTH(color) > 0),
  CONSTRAINT fk_variants_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Product size/color variants with unique SKUs';

CREATE INDEX ix_variants_product ON product_variants(product_id);
CREATE UNIQUE INDEX ux_variants_pid_size_color ON product_variants(product_id, size, color);

CREATE TABLE product_images (
  image_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  url VARCHAR(500) NOT NULL,
  alt_text VARCHAR(255),
  position INT NOT NULL DEFAULT 0,
  color_ref VARCHAR(50),

  CONSTRAINT fk_images_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Product image gallery with ordering';

CREATE INDEX ix_images_product ON product_images(product_id, position);

-- ==============================================================================
-- Step 4: User-related tables (depend on users)
-- ==============================================================================

CREATE TABLE user_preferences (
  user_id VARCHAR(50) PRIMARY KEY,
  preferences JSON NOT NULL,
  schema_version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT ck_preferences_schema_version
    CHECK (schema_version = 1),
  CONSTRAINT fk_preferences_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User shopping preferences (style, size, communication)';

-- ==============================================================================
-- Step 5: Reviews (depend on products and users)
-- ==============================================================================

CREATE TABLE product_reviews (
  review_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  rating INT NOT NULL,
  title VARCHAR(120),
  body TEXT,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_reviews_rating_range
    CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT ck_reviews_title_length
    CHECK (title IS NULL OR CHAR_LENGTH(title) <= 120),
  CONSTRAINT ck_reviews_body_length
    CHECK (body IS NULL OR CHAR_LENGTH(body) <= 4000),
  CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_reviews_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Customer product reviews and ratings';

CREATE INDEX ix_reviews_product ON product_reviews(product_id, created_at DESC);
CREATE INDEX ix_reviews_product_rating ON product_reviews(product_id, rating DESC, created_at DESC);
CREATE INDEX ix_reviews_product_verified ON product_reviews(product_id, created_at DESC, verified);
CREATE UNIQUE INDEX ux_reviews_user_product ON product_reviews(user_id, product_id);

-- ==============================================================================
-- Step 6: Inventory and pricing (depend on product_variants)
-- ==============================================================================

CREATE TABLE inventory (
  variant_id VARCHAR(50) PRIMARY KEY,
  quantity INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT ck_inventory_quantity
    CHECK (quantity >= 0),
  CONSTRAINT fk_inventory_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Real-time inventory levels by variant';

CREATE INDEX ix_inventory_instock ON inventory(variant_id, quantity);

CREATE TABLE prices (
  price_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  variant_id VARCHAR(50),
  segment VARCHAR(50) NOT NULL DEFAULT 'public',
  price_cents INT NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP,
  priority INT NOT NULL DEFAULT 100,

  CONSTRAINT ck_prices_segment
    CHECK (segment IN ('public', 'loyalty-bronze', 'loyalty-silver', 'loyalty-gold', 'employee')),
  CONSTRAINT ck_prices_amount
    CHECK (price_cents >= 0),
  CONSTRAINT ck_prices_currency
    CHECK (currency = 'USD'),
  CONSTRAINT ck_prices_priority
    CHECK (priority >= 0),
  CONSTRAINT ck_prices_valid_period
    CHECK (valid_to IS NULL OR valid_to > valid_from),
  CONSTRAINT fk_prices_product
    FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_prices_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Time-based pricing overrides by segment';

CREATE INDEX ix_prices_product_segment_active ON prices(product_id, segment, valid_from DESC, valid_to);
CREATE INDEX ix_prices_variant_segment ON prices(variant_id, segment, valid_from DESC);
CREATE UNIQUE INDEX ux_prices_segment_priority_active ON prices(product_id, segment, priority, valid_from);

-- ==============================================================================
-- Step 7: Coupons and promotions (no additional dependencies)
-- ==============================================================================

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User-redeemable coupon codes with scoping rules';

CREATE INDEX ix_coupons_code_active ON coupons(code, active);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Automatic promotional discounts';

CREATE INDEX ix_promotions_active ON promotions(priority DESC, valid_from, active);

-- ==============================================================================
-- Step 8: Carts (depend on users, product_variants, coupons)
-- ==============================================================================

CREATE TABLE carts (
  cart_id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT ck_carts_status
    CHECK (status IN ('active', 'checked-out')),
  CONSTRAINT ck_carts_updated_after_created
    CHECK (updated_at >= created_at),
  CONSTRAINT fk_carts_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Shopping carts with status tracking';

CREATE INDEX ix_carts_user ON carts(user_id);

CREATE TABLE cart_items (
  cart_item_id VARCHAR(50) PRIMARY KEY,
  cart_id VARCHAR(50) NOT NULL,
  variant_id VARCHAR(50) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_cart_items_quantity
    CHECK (quantity >= 1 AND quantity <= 10),
  CONSTRAINT fk_cart_items_cart
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_items_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Line items in shopping carts';

CREATE INDEX ix_cart_items_cart_added ON cart_items(cart_id, added_at);
CREATE UNIQUE INDEX ux_cart_items_variant ON cart_items(cart_id, variant_id);

CREATE TABLE applied_coupons (
  cart_id VARCHAR(50) PRIMARY KEY,
  coupon_id VARCHAR(50) NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_applied_coupons_cart
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_applied_coupons_coupon
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='One coupon per cart (workshop scope)';

CREATE INDEX ix_applied_coupons_coupon ON applied_coupons(coupon_id);

-- ==============================================================================
-- Step 9: Orders (depend on users, carts, coupons, products, variants)
-- ==============================================================================

CREATE TABLE orders (
  order_id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  cart_id VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'confirmed',
  subtotal_cents INT NOT NULL,
  discount_cents INT NOT NULL DEFAULT 0,
  total_cents INT NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  coupon_id VARCHAR(50),
  applied_coupon_code VARCHAR(32),
  applied_coupon_type VARCHAR(20),
  applied_coupon_value DECIMAL(10,2),
  applied_coupon_currency VARCHAR(3),
  notes TEXT,
  cancelled_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT ck_orders_status
    CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT ck_orders_subtotal
    CHECK (subtotal_cents >= 0),
  CONSTRAINT ck_orders_discount
    CHECK (discount_cents >= 0),
  CONSTRAINT ck_orders_total
    CHECK (total_cents >= 0),
  CONSTRAINT ck_orders_currency
    CHECK (currency = 'USD'),
  CONSTRAINT ck_orders_coupon_type
    CHECK (applied_coupon_type IN ('percent', 'fixed') OR applied_coupon_type IS NULL),
  CONSTRAINT ck_orders_coupon_currency
    CHECK (applied_coupon_currency IS NULL OR applied_coupon_currency = 'USD'),
  CONSTRAINT ck_orders_notes_length
    CHECK (notes IS NULL OR CHAR_LENGTH(notes) <= 500),
  CONSTRAINT ck_orders_cancelled_status
    CHECK ((status = 'cancelled') = (cancelled_at IS NOT NULL)),
  CONSTRAINT ck_orders_total_calculation
    CHECK (total_cents = subtotal_cents - discount_cents),
  CONSTRAINT ck_orders_coupon_fields
    CHECK (
      (coupon_id IS NULL) =
      (applied_coupon_code IS NULL
       AND applied_coupon_type IS NULL
       AND applied_coupon_value IS NULL
       AND applied_coupon_currency IS NULL)
    ),
  CONSTRAINT ck_orders_updated_after_created
    CHECK (updated_at >= created_at),
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_orders_cart
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id),
  CONSTRAINT fk_orders_coupon
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Confirmed orders with snapshot of pricing and coupons';

CREATE INDEX ix_orders_user_status_created ON orders(user_id, status, created_at DESC);
CREATE UNIQUE INDEX ux_orders_cart ON orders(cart_id);

CREATE TABLE order_items (
  order_item_id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(50) NOT NULL,
  variant_id VARCHAR(50) NOT NULL,
  product_id VARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  unit_price_cents INT NOT NULL,
  discount_cents INT NOT NULL DEFAULT 0,
  snapshot_name VARCHAR(255) NOT NULL,
  snapshot_image_url VARCHAR(500),
  snapshot_size VARCHAR(20) NOT NULL,
  snapshot_color VARCHAR(50) NOT NULL,
  snapshot_sku VARCHAR(100) NOT NULL,

  CONSTRAINT ck_order_items_quantity
    CHECK (quantity >= 1 AND quantity <= 10),
  CONSTRAINT ck_order_items_unit_price
    CHECK (unit_price_cents >= 0),
  CONSTRAINT ck_order_items_discount
    CHECK (discount_cents >= 0),
  CONSTRAINT ck_order_items_discount_max
    CHECK (discount_cents <= quantity * unit_price_cents),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT fk_order_items_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Order line items with frozen product details';

CREATE INDEX ix_order_items_order ON order_items(order_id);
CREATE UNIQUE INDEX ux_order_items_variant ON order_items(order_id, variant_id);

-- ==============================================================================
-- Step 10: Transactional emails (depend on orders and users)
-- ==============================================================================

CREATE TABLE transactional_emails (
  email_id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(50) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  type VARCHAR(50) NOT NULL,
  to_address VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  body_html LONGTEXT NOT NULL,
  rendered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_emails_type
    CHECK (type IN ('order-confirmation')),
  CONSTRAINT fk_emails_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_emails_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Template-rendered transactional emails (Layer 1)';

CREATE INDEX ix_emails_order ON transactional_emails(order_id);

-- ==============================================================================
-- Step 11: Idempotency keys (depend on users)
-- ==============================================================================

CREATE TABLE idempotency_keys (
  `key` VARCHAR(128) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  request_method VARCHAR(10) NOT NULL,
  request_path VARCHAR(500) NOT NULL,
  request_hash CHAR(64) NOT NULL,
  response_status INT NOT NULL,
  response_body JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_idempotency_method
    CHECK (request_method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_idempotency_hash_length
    CHECK (CHAR_LENGTH(request_hash) = 64),
  CONSTRAINT ck_idempotency_response_status
    CHECK (response_status BETWEEN 100 AND 599),
  CONSTRAINT fk_idempotency_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),

  PRIMARY KEY (`key`, user_id, request_method, request_path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Request deduplication for idempotent operations (24h retention)';

CREATE INDEX ix_idempotency_keys_pruning ON idempotency_keys(created_at);

-- ==============================================================================
-- Completion
-- ==============================================================================

SELECT 'All Layer 1 Commerce tables created successfully' AS status;

SELECT
  TABLE_NAME,
  TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'stylemart'
ORDER BY TABLE_NAME;
