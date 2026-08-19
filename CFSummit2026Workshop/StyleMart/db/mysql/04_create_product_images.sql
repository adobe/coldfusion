-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 04_create_product_images.sql
-- Description: Product images table (depends on products)

USE stylemart;

CREATE TABLE product_images (
  image_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  url VARCHAR(500) NOT NULL,
  alt_text VARCHAR(255),
  position INT NOT NULL DEFAULT 0,
  color_ref VARCHAR(50),

  -- Constraints
  CONSTRAINT fk_images_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_images_product ON product_images(product_id, position);

-- Comments
ALTER TABLE product_images COMMENT = 'Product image gallery with ordering';
