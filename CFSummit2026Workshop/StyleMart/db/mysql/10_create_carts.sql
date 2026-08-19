-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 10_create_carts.sql
-- Description: Shopping cart tables (depend on users, product_variants, coupons)

USE stylemart;

-- Carts table
CREATE TABLE carts (
  cart_id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_carts_status
    CHECK (status IN ('active', 'checked-out')),
  CONSTRAINT ck_carts_updated_after_created
    CHECK (updated_at >= created_at),
  CONSTRAINT fk_carts_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_carts_user ON carts(user_id);
CREATE UNIQUE INDEX ux_carts_user_active
  ON carts(user_id, status) WHERE status = 'active';

-- Cart items table
CREATE TABLE cart_items (
  cart_item_id VARCHAR(50) PRIMARY KEY,
  cart_id VARCHAR(50) NOT NULL,
  variant_id VARCHAR(50) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_cart_items_quantity
    CHECK (quantity >= 1 AND quantity <= 10),
  CONSTRAINT fk_cart_items_cart
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_items_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_cart_items_cart_added ON cart_items(cart_id, added_at);
CREATE UNIQUE INDEX ux_cart_items_variant ON cart_items(cart_id, variant_id);

-- Applied coupons table
CREATE TABLE applied_coupons (
  cart_id VARCHAR(50) PRIMARY KEY,
  coupon_id VARCHAR(50) NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT fk_applied_coupons_cart
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_applied_coupons_coupon
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_applied_coupons_coupon ON applied_coupons(coupon_id);

-- Comments
ALTER TABLE carts COMMENT = 'Shopping carts with status tracking';
ALTER TABLE cart_items COMMENT = 'Line items in shopping carts';
ALTER TABLE applied_coupons COMMENT = 'One coupon per cart (workshop scope)';
