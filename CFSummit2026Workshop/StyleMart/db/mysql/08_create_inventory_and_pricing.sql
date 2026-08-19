-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 08_create_inventory_and_pricing.sql
-- Description: Inventory and pricing tables (depend on product_variants)

USE stylemart;

-- Inventory table
CREATE TABLE inventory (
  variant_id VARCHAR(50) PRIMARY KEY,
  quantity INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_inventory_quantity
    CHECK (quantity >= 0),
  CONSTRAINT fk_inventory_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for in-stock items
CREATE INDEX ix_inventory_instock ON inventory(variant_id, quantity);

-- Prices table
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

  -- Constraints
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_prices_product_segment_active
  ON prices(product_id, segment, valid_from DESC, valid_to);
CREATE INDEX ix_prices_variant_segment
  ON prices(variant_id, segment, valid_from DESC);
CREATE UNIQUE INDEX ux_prices_segment_priority_active
  ON prices(product_id, segment, priority, valid_from);

-- Comments
ALTER TABLE inventory COMMENT = 'Real-time inventory levels by variant';
ALTER TABLE prices COMMENT = 'Time-based pricing overrides by segment';
