-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 07_create_product_reviews.sql
-- Description: Product reviews table (depends on products and users)

USE stylemart;

CREATE TABLE product_reviews (
  review_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  rating INT NOT NULL,
  title VARCHAR(120),
  body TEXT,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_reviews_product ON product_reviews(product_id, created_at DESC);
CREATE INDEX ix_reviews_product_rating
  ON product_reviews(product_id, rating DESC, created_at DESC);
CREATE INDEX ix_reviews_product_verified
  ON product_reviews(product_id, created_at DESC, verified);

-- Unique constraint: one review per user per product
CREATE UNIQUE INDEX ux_reviews_user_product
  ON product_reviews(user_id, product_id);

-- Comments
ALTER TABLE product_reviews COMMENT = 'Customer product reviews and ratings';
