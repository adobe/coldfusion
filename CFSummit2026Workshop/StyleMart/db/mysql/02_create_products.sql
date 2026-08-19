-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 02_create_products.sql
-- Description: Products table (depends on categories)

USE stylemart;

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

  -- Constraints
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for filtering and sorting
CREATE INDEX ix_products_category ON products(category);
CREATE INDEX ix_products_category_price ON products(category, base_price_cents);
CREATE INDEX ix_products_category_rating ON products(category, average_rating DESC);
CREATE INDEX ix_products_category_created ON products(category, created_at DESC);

-- Full-text search index
CREATE FULLTEXT INDEX ix_products_fts ON products(name, description);

-- Comments
ALTER TABLE products COMMENT = 'Product catalog with pricing, ratings, and categorization';
