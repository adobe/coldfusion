-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 11_create_orders.sql
-- Description: Orders and order items tables (depend on users, carts, coupons, products, variants)

USE stylemart;

-- Orders table
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

  -- Constraints
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_orders_user_status_created
  ON orders(user_id, status, created_at DESC);
CREATE UNIQUE INDEX ux_orders_cart ON orders(cart_id);

-- Order items table
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

  -- Constraints
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_order_items_order ON order_items(order_id);
CREATE UNIQUE INDEX ux_order_items_variant ON order_items(order_id, variant_id);

-- Comments
ALTER TABLE orders COMMENT = 'Confirmed orders with snapshot of pricing and coupons';
ALTER TABLE order_items COMMENT = 'Order line items with frozen product details';
