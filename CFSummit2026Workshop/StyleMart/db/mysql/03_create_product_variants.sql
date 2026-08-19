-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 03_create_product_variants.sql
-- Description: Product variants table (depends on products)

USE stylemart;

CREATE TABLE product_variants (
  variant_id VARCHAR(50) PRIMARY KEY,
  product_id VARCHAR(50) NOT NULL,
  size VARCHAR(20) NOT NULL,
  color VARCHAR(50) NOT NULL,
  sku VARCHAR(100) NOT NULL UNIQUE,

  -- Constraints
  CONSTRAINT ck_variants_size_not_empty
    CHECK (CHAR_LENGTH(size) > 0),
  CONSTRAINT ck_variants_color_not_empty
    CHECK (CHAR_LENGTH(color) > 0),
  CONSTRAINT fk_variants_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_variants_product ON product_variants(product_id);
CREATE UNIQUE INDEX ux_variants_pid_size_color
  ON product_variants(product_id, size, color);

-- Comments
ALTER TABLE product_variants COMMENT = 'Product size/color variants with unique SKUs';
