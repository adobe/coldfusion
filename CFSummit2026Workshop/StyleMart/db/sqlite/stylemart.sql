-- StyleMart SQLite bootstrap — single-file build (DDL + seed + cleanup).
-- Generated. Run with:  rm -f stylemart.db && sqlite3 stylemart.db < stylemart.sql

PRAGMA foreign_keys = OFF;       -- relaxed during seed (some MySQL seed rows reference duplicate-SKU variants that get IGNOREd)
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;

BEGIN;


-- ============================================================================
-- 01_create_categories.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 01_create_categories.sql
-- Description: Categories table (foundation for product foreign keys)
--
-- SQLite notes:
--  - No ENGINE / CHARSET / COLLATE — SQLite stores text as UTF-8 by default.
--  - The MySQL slug-format CHECK used REGEXP, which SQLite does not bundle.
--    Slug formatting is enforced by the application (categories are seeded,
--    not user-generated), so the regex CHECK is dropped here.

CREATE TABLE categories (
  slug         TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  description  TEXT,
  hero_image   TEXT,
  parent_slug  TEXT,
  sort_order   INTEGER NOT NULL DEFAULT 0,

  CONSTRAINT ck_categories_parent_not_self
    CHECK (parent_slug IS NULL OR parent_slug <> slug),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_slug) REFERENCES categories(slug)
);

CREATE INDEX ix_categories_parent ON categories(parent_slug);

-- ============================================================================
-- 02_create_products.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 02_create_products.sql
-- Description: Products table (depends on categories)
--
-- SQLite notes:
--  - JSON columns are TEXT; the JSON1 extension (bundled with sqlite-jdbc)
--    parses them via json_extract / json_valid.
--  - REGEXP-based CHECK constraints dropped (SQLite has no built-in REGEXP).
--    Brand / slug / subcategory format is enforced at the application layer.
--  - FULLTEXT index on (name, description) dropped. The app uses LIKE-based
--    search via ProductService, not MATCH … AGAINST. If true full-text search
--    is needed later, add an FTS5 virtual table mirroring (name, description).
--  - ON UPDATE CURRENT_TIMESTAMP replicated via an AFTER UPDATE trigger.

CREATE TABLE products (
  product_id        TEXT PRIMARY KEY,
  slug              TEXT NOT NULL UNIQUE,
  name              TEXT NOT NULL,
  brand             TEXT NOT NULL DEFAULT 'StyleMart',
  category          TEXT NOT NULL,
  subcategory       TEXT,
  description       TEXT,
  care_instructions TEXT,
  base_price_cents  INTEGER NOT NULL,
  currency          TEXT NOT NULL DEFAULT 'USD',
  image_url         TEXT NOT NULL,
  attributes        TEXT NOT NULL DEFAULT '{}',
  occasion_tags     TEXT NOT NULL DEFAULT '[]',
  average_rating    REAL,
  review_count      INTEGER NOT NULL DEFAULT 0,
  image_source_ref  TEXT,
  created_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
  updated_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_products_base_price     CHECK (base_price_cents >= 0),
  CONSTRAINT ck_products_currency       CHECK (currency = 'USD'),
  CONSTRAINT ck_products_rating_range   CHECK (average_rating IS NULL OR (average_rating BETWEEN 0 AND 5)),
  CONSTRAINT ck_products_review_count   CHECK (review_count >= 0),
  CONSTRAINT ck_products_attributes_json    CHECK (json_valid(attributes)),
  CONSTRAINT ck_products_occasion_tags_json CHECK (json_valid(occasion_tags)),
  CONSTRAINT fk_products_category       FOREIGN KEY (category) REFERENCES categories(slug)
);

CREATE INDEX ix_products_category         ON products(category);
CREATE INDEX ix_products_category_price   ON products(category, base_price_cents);
CREATE INDEX ix_products_category_rating  ON products(category, average_rating DESC);
CREATE INDEX ix_products_category_created ON products(category, created_at DESC);

-- Mirrors MySQL's `ON UPDATE CURRENT_TIMESTAMP`.
CREATE TRIGGER trg_products_updated_at
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  UPDATE products
     SET updated_at = strftime('%Y-%m-%d %H:%M:%f','now')
   WHERE product_id = OLD.product_id;
END;

-- ============================================================================
-- 03_create_product_variants.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 03_create_product_variants.sql
-- Description: Product variants table (depends on products)

CREATE TABLE product_variants (
  variant_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  size       TEXT NOT NULL,
  color      TEXT NOT NULL,
  sku        TEXT NOT NULL UNIQUE,

  CONSTRAINT ck_variants_size_not_empty  CHECK (length(size)  > 0),
  CONSTRAINT ck_variants_color_not_empty CHECK (length(color) > 0),
  CONSTRAINT fk_variants_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX ix_variants_product ON product_variants(product_id);
CREATE UNIQUE INDEX ux_variants_pid_size_color
  ON product_variants(product_id, size, color);

-- ============================================================================
-- 04_create_product_images.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 04_create_product_images.sql
-- Description: Product images table (depends on products)

CREATE TABLE product_images (
  image_id   TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  url        TEXT NOT NULL,
  alt_text   TEXT,
  position   INTEGER NOT NULL DEFAULT 0,
  color_ref  TEXT,

  CONSTRAINT fk_images_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX ix_images_product ON product_images(product_id, position);

-- ============================================================================
-- 05_create_users_and_loyalty.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 05_create_users_and_loyalty.sql
-- Description: Loyalty tiers and users tables
--
-- SQLite notes:
--  - regexp_like() email-format CHECK dropped (no built-in REGEXP). The
--    Layer-1 register/login flow validates email format in the app.
--  - JSON benefits stored as TEXT with a json_valid() guard.

CREATE TABLE loyalty_tiers (
  tier_id               TEXT PRIMARY KEY,
  display_name          TEXT NOT NULL,
  discount_pct          REAL NOT NULL,
  spend_threshold_cents INTEGER NOT NULL,
  benefits              TEXT NOT NULL DEFAULT '[]',
  sort_order            INTEGER NOT NULL DEFAULT 0,

  CONSTRAINT ck_loyalty_discount_range  CHECK (discount_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_loyalty_threshold       CHECK (spend_threshold_cents >= 0),
  CONSTRAINT ck_loyalty_benefits_json   CHECK (json_valid(benefits))
);

CREATE UNIQUE INDEX ux_tiers_sort ON loyalty_tiers(sort_order);

CREATE TABLE users (
  user_id         TEXT PRIMARY KEY,
  username        TEXT NOT NULL UNIQUE,
  password_hash   TEXT NOT NULL,
  display_name    TEXT NOT NULL,
  email           TEXT,
  loyalty_tier_id TEXT,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_users_display_name_length
    CHECK (length(display_name) BETWEEN 1 AND 80),
  CONSTRAINT fk_users_loyalty_tier
    FOREIGN KEY (loyalty_tier_id) REFERENCES loyalty_tiers(tier_id)
);

CREATE INDEX fk_users_loyalty_tier ON users(loyalty_tier_id);

-- ============================================================================
-- 06_create_user_preferences.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 06_create_user_preferences.sql
-- Description: User preferences table (depends on users)
--
-- SQLite notes:
--  - JSON column → TEXT + json_valid() CHECK.
--  - ON UPDATE CURRENT_TIMESTAMP replicated via AFTER UPDATE trigger.

CREATE TABLE user_preferences (
  user_id        TEXT PRIMARY KEY,
  preferences    TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_preferences_schema_version CHECK (schema_version = 1),
  CONSTRAINT ck_preferences_json           CHECK (json_valid(preferences)),
  CONSTRAINT fk_preferences_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TRIGGER trg_user_preferences_updated_at
AFTER UPDATE ON user_preferences
FOR EACH ROW
BEGIN
  UPDATE user_preferences
     SET updated_at = strftime('%Y-%m-%d %H:%M:%f','now')
   WHERE user_id = OLD.user_id;
END;

-- ============================================================================
-- 07_create_product_reviews.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 07_create_product_reviews.sql
-- Description: Product reviews table (depends on products and users)

CREATE TABLE product_reviews (
  review_id  TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  user_id    TEXT NOT NULL,
  rating     INTEGER NOT NULL,
  title      TEXT,
  body       TEXT,
  verified   INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_reviews_rating_range CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT ck_reviews_title_length CHECK (title IS NULL OR length(title) <= 120),
  CONSTRAINT ck_reviews_body_length  CHECK (body  IS NULL OR length(body)  <= 4000),
  CONSTRAINT ck_reviews_verified     CHECK (verified IN (0, 1)),
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_reviews_user    FOREIGN KEY (user_id)    REFERENCES users(user_id)
);

CREATE INDEX ix_reviews_product
  ON product_reviews(product_id, created_at DESC);
CREATE INDEX ix_reviews_product_rating
  ON product_reviews(product_id, rating DESC, created_at DESC);
CREATE INDEX ix_reviews_product_verified
  ON product_reviews(product_id, created_at DESC, verified);

CREATE UNIQUE INDEX ux_reviews_user_product
  ON product_reviews(user_id, product_id);

-- ============================================================================
-- 08_create_inventory_and_pricing.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 08_create_inventory_and_pricing.sql
-- Description: Inventory and pricing tables (depend on product_variants)
--
-- SQLite notes:
--  - ON UPDATE CURRENT_TIMESTAMP replicated via AFTER UPDATE trigger.

CREATE TABLE inventory (
  variant_id TEXT PRIMARY KEY,
  quantity   INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_inventory_quantity CHECK (quantity >= 0),
  CONSTRAINT fk_inventory_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE INDEX ix_inventory_instock ON inventory(variant_id, quantity);

CREATE TRIGGER trg_inventory_updated_at
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
  UPDATE inventory
     SET updated_at = strftime('%Y-%m-%d %H:%M:%f','now')
   WHERE variant_id = OLD.variant_id;
END;

CREATE TABLE prices (
  price_id    TEXT PRIMARY KEY,
  product_id  TEXT NOT NULL,
  variant_id  TEXT,
  segment     TEXT NOT NULL DEFAULT 'public',
  price_cents INTEGER NOT NULL,
  currency    TEXT NOT NULL DEFAULT 'USD',
  valid_from  TEXT NOT NULL,
  valid_to    TEXT,
  priority    INTEGER NOT NULL DEFAULT 100,

  CONSTRAINT ck_prices_segment
    CHECK (segment IN ('public', 'loyalty-bronze', 'loyalty-silver', 'loyalty-gold', 'employee')),
  CONSTRAINT ck_prices_amount       CHECK (price_cents >= 0),
  CONSTRAINT ck_prices_currency     CHECK (currency = 'USD'),
  CONSTRAINT ck_prices_priority     CHECK (priority >= 0),
  CONSTRAINT ck_prices_valid_period CHECK (valid_to IS NULL OR valid_to > valid_from),
  CONSTRAINT fk_prices_product
    FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_prices_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE INDEX ix_prices_product_segment_active
  ON prices(product_id, segment, valid_from DESC, valid_to);
CREATE INDEX ix_prices_variant_segment
  ON prices(variant_id, segment, valid_from DESC);
CREATE UNIQUE INDEX ux_prices_segment_priority_active
  ON prices(product_id, segment, priority, valid_from);

-- ============================================================================
-- 09_create_coupons_and_promotions.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 09_create_coupons_and_promotions.sql
-- Description: Coupons and promotions tables
--
-- SQLite notes:
--  - JSON columns → TEXT + json_valid() CHECK.
--  - upper(code) = code is enforced via CHECK (SQLite has upper()).
--  - Boolean `active` → INTEGER 0/1.

CREATE TABLE coupons (
  coupon_id           TEXT PRIMARY KEY,
  code                TEXT NOT NULL UNIQUE,
  type                TEXT NOT NULL,
  value               REAL NOT NULL,
  currency            TEXT NOT NULL DEFAULT 'USD',
  scope_categories    TEXT NOT NULL DEFAULT '[]',
  excludes_categories TEXT NOT NULL DEFAULT '[]',
  conditions_json     TEXT NOT NULL DEFAULT '{}',
  valid_from          TEXT NOT NULL,
  valid_to            TEXT NOT NULL,
  active              INTEGER NOT NULL DEFAULT 1,

  CONSTRAINT ck_coupons_code_format
    CHECK (code = upper(code) AND length(code) BETWEEN 3 AND 32),
  CONSTRAINT ck_coupons_type        CHECK (type IN ('percent', 'fixed')),
  CONSTRAINT ck_coupons_currency    CHECK (currency = 'USD'),
  CONSTRAINT ck_coupons_active      CHECK (active IN (0, 1)),
  CONSTRAINT ck_coupons_valid_period CHECK (valid_to > valid_from),
  CONSTRAINT ck_coupons_value_range
    CHECK ((type = 'percent' AND value BETWEEN 0 AND 100)
        OR (type = 'fixed'   AND value >= 0)),
  CONSTRAINT ck_coupons_scope_json     CHECK (json_valid(scope_categories)),
  CONSTRAINT ck_coupons_excludes_json  CHECK (json_valid(excludes_categories)),
  CONSTRAINT ck_coupons_conditions_json CHECK (json_valid(conditions_json))
);

CREATE INDEX ix_coupons_code_active ON coupons(code, active);

CREATE TABLE promotions (
  promotion_id TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  type         TEXT NOT NULL,
  value        REAL NOT NULL,
  scope_json   TEXT NOT NULL DEFAULT '{}',
  priority     INTEGER NOT NULL DEFAULT 100,
  valid_from   TEXT NOT NULL,
  valid_to     TEXT NOT NULL,
  active       INTEGER NOT NULL DEFAULT 1,

  CONSTRAINT ck_promotions_type     CHECK (type IN ('percent', 'fixed')),
  CONSTRAINT ck_promotions_priority CHECK (priority >= 0),
  CONSTRAINT ck_promotions_active   CHECK (active IN (0, 1)),
  CONSTRAINT ck_promotions_valid_period CHECK (valid_to > valid_from),
  CONSTRAINT ck_promotions_value_range
    CHECK ((type = 'percent' AND value BETWEEN 0 AND 100)
        OR (type = 'fixed'   AND value >= 0)),
  CONSTRAINT ck_promotions_scope_json CHECK (json_valid(scope_json))
);

CREATE INDEX ix_promotions_active ON promotions(priority DESC, valid_from, active);

-- ============================================================================
-- 10_create_carts.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 10_create_carts.sql
-- Description: Shopping cart tables (depend on users, product_variants, coupons)
--
-- SQLite notes:
--  - The MySQL "CREATE UNIQUE INDEX … (user_id, status) WHERE status = 'active'"
--    is a partial index; SQLite supports the same syntax.
--  - ON UPDATE CURRENT_TIMESTAMP replicated via AFTER UPDATE trigger.

CREATE TABLE carts (
  cart_id    TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  status     TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_carts_status CHECK (status IN ('active', 'checked-out')),
  CONSTRAINT fk_carts_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX ix_carts_user ON carts(user_id);
CREATE UNIQUE INDEX ux_carts_user_active
  ON carts(user_id, status) WHERE status = 'active';

CREATE TRIGGER trg_carts_updated_at
AFTER UPDATE ON carts
FOR EACH ROW
BEGIN
  UPDATE carts
     SET updated_at = strftime('%Y-%m-%d %H:%M:%f','now')
   WHERE cart_id = OLD.cart_id;
END;

CREATE TABLE cart_items (
  cart_item_id TEXT PRIMARY KEY,
  cart_id      TEXT NOT NULL,
  variant_id   TEXT NOT NULL,
  quantity     INTEGER NOT NULL DEFAULT 1,
  added_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_cart_items_quantity CHECK (quantity BETWEEN 1 AND 10),
  CONSTRAINT fk_cart_items_cart
    FOREIGN KEY (cart_id)    REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_items_variant
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE INDEX ix_cart_items_cart_added ON cart_items(cart_id, added_at);
CREATE UNIQUE INDEX ux_cart_items_variant ON cart_items(cart_id, variant_id);

CREATE TABLE applied_coupons (
  cart_id    TEXT PRIMARY KEY,
  coupon_id  TEXT NOT NULL,
  applied_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT fk_applied_coupons_cart
    FOREIGN KEY (cart_id)   REFERENCES carts(cart_id) ON DELETE CASCADE,
  CONSTRAINT fk_applied_coupons_coupon
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
);

CREATE INDEX ix_applied_coupons_coupon ON applied_coupons(coupon_id);

-- ============================================================================
-- 11_create_orders.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 11_create_orders.sql
-- Description: Orders and order items tables
-- (depend on users, carts, coupons, products, variants)
--
-- SQLite notes:
--  - All MySQL CHECKs translate cleanly except the "(A IS NULL) = (B IS NULL …)"
--    boolean equality form, which SQLite parses fine — kept verbatim.
--  - ON UPDATE CURRENT_TIMESTAMP replicated via AFTER UPDATE trigger.

CREATE TABLE orders (
  order_id                TEXT PRIMARY KEY,
  user_id                 TEXT NOT NULL,
  cart_id                 TEXT NOT NULL,
  status                  TEXT NOT NULL DEFAULT 'confirmed',
  subtotal_cents          INTEGER NOT NULL,
  discount_cents          INTEGER NOT NULL DEFAULT 0,
  total_cents             INTEGER NOT NULL,
  currency                TEXT NOT NULL DEFAULT 'USD',
  coupon_id               TEXT,
  applied_coupon_code     TEXT,
  applied_coupon_type     TEXT,
  applied_coupon_value    REAL,
  applied_coupon_currency TEXT,
  notes                   TEXT,
  cancelled_at            TEXT,
  created_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
  updated_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_orders_status   CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT ck_orders_subtotal CHECK (subtotal_cents >= 0),
  CONSTRAINT ck_orders_discount CHECK (discount_cents >= 0),
  CONSTRAINT ck_orders_total    CHECK (total_cents    >= 0),
  CONSTRAINT ck_orders_currency CHECK (currency = 'USD'),
  CONSTRAINT ck_orders_coupon_type
    CHECK (applied_coupon_type IS NULL OR applied_coupon_type IN ('percent', 'fixed')),
  CONSTRAINT ck_orders_coupon_currency
    CHECK (applied_coupon_currency IS NULL OR applied_coupon_currency = 'USD'),
  CONSTRAINT ck_orders_notes_length
    CHECK (notes IS NULL OR length(notes) <= 500),
  CONSTRAINT ck_orders_cancelled_status
    CHECK ((status = 'cancelled') = (cancelled_at IS NOT NULL)),
  CONSTRAINT ck_orders_total_calculation
    CHECK (total_cents = subtotal_cents - discount_cents),
  CONSTRAINT ck_orders_coupon_fields
    CHECK ((coupon_id IS NULL) =
           (applied_coupon_code IS NULL
        AND applied_coupon_type IS NULL
        AND applied_coupon_value IS NULL
        AND applied_coupon_currency IS NULL)),
  CONSTRAINT fk_orders_user   FOREIGN KEY (user_id)   REFERENCES users(user_id),
  CONSTRAINT fk_orders_cart   FOREIGN KEY (cart_id)   REFERENCES carts(cart_id),
  CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
);

CREATE INDEX ix_orders_user_status_created
  ON orders(user_id, status, created_at DESC);
CREATE UNIQUE INDEX ux_orders_cart ON orders(cart_id);

CREATE TRIGGER trg_orders_updated_at
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
  UPDATE orders
     SET updated_at = strftime('%Y-%m-%d %H:%M:%f','now')
   WHERE order_id = OLD.order_id;
END;

CREATE TABLE order_items (
  order_item_id      TEXT PRIMARY KEY,
  order_id           TEXT NOT NULL,
  variant_id         TEXT NOT NULL,
  product_id         TEXT NOT NULL,
  quantity           INTEGER NOT NULL,
  unit_price_cents   INTEGER NOT NULL,
  discount_cents     INTEGER NOT NULL DEFAULT 0,
  snapshot_name      TEXT NOT NULL,
  snapshot_image_url TEXT,
  snapshot_size      TEXT NOT NULL,
  snapshot_color     TEXT NOT NULL,
  snapshot_sku       TEXT NOT NULL,

  CONSTRAINT ck_order_items_quantity     CHECK (quantity BETWEEN 1 AND 10),
  CONSTRAINT ck_order_items_unit_price   CHECK (unit_price_cents >= 0),
  CONSTRAINT ck_order_items_discount     CHECK (discount_cents >= 0),
  CONSTRAINT ck_order_items_discount_max CHECK (discount_cents <= quantity * unit_price_cents),
  CONSTRAINT fk_order_items_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  CONSTRAINT fk_order_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX ix_order_items_order ON order_items(order_id);
CREATE UNIQUE INDEX ux_order_items_variant ON order_items(order_id, variant_id);

-- ============================================================================
-- 12_create_transactional_emails.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 12_create_transactional_emails.sql
-- Description: Transactional emails table (depends on orders and users)

CREATE TABLE transactional_emails (
  email_id    TEXT PRIMARY KEY,
  order_id    TEXT NOT NULL,
  user_id     TEXT NOT NULL,
  type        TEXT NOT NULL,
  to_address  TEXT NOT NULL,
  subject     TEXT NOT NULL,
  body_html   TEXT NOT NULL,
  rendered_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_emails_type CHECK (type IN ('order-confirmation')),
  CONSTRAINT fk_emails_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_emails_user
    FOREIGN KEY (user_id)  REFERENCES users(user_id)
);

CREATE INDEX ix_emails_order ON transactional_emails(order_id);

-- ============================================================================
-- 13_create_idempotency_keys.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 13_create_idempotency_keys.sql
-- Description: Idempotency keys for API request deduplication (depends on users)
--
-- SQLite notes:
--  - The MySQL CHAR(64) on request_hash collapses to TEXT; the length CHECK
--    enforces the 64-char invariant.
--  - JSON column → TEXT + json_valid() CHECK.
--  - "key" is a reserved-ish word; we keep the bare name and quote when needed.

CREATE TABLE idempotency_keys (
  key             TEXT NOT NULL,
  user_id         TEXT NOT NULL,
  request_method  TEXT NOT NULL,
  request_path    TEXT NOT NULL,
  request_hash    TEXT NOT NULL,
  response_status INTEGER NOT NULL,
  response_body   TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_idempotency_method
    CHECK (request_method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_idempotency_hash_length
    CHECK (length(request_hash) = 64),
  CONSTRAINT ck_idempotency_response_status
    CHECK (response_status BETWEEN 100 AND 599),
  CONSTRAINT ck_idempotency_response_json
    CHECK (json_valid(response_body)),
  CONSTRAINT fk_idempotency_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  PRIMARY KEY (key, user_id, request_method, request_path)
);

CREATE INDEX ix_idempotency_keys_pruning ON idempotency_keys(created_at);

-- ============================================================================
-- 14_create_agent_traces.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 14_create_agent_traces.sql
-- Description: Observability sink for the agent SSE pipeline (Session 1+).
--              One row per emitted SSE event. Write-only on the request thread.
--
-- SQLite notes:
--  - BIGINT UNSIGNED AUTO_INCREMENT → INTEGER PRIMARY KEY AUTOINCREMENT
--    (rowid is INT64; AUTOINCREMENT keeps the never-reuse guarantee).
--  - TIMESTAMP(3) → TEXT with millisecond strftime default. SQLite has no
--    native millisecond timestamp type; storing as ISO-8601 text with %f
--    keeps lexical ordering equivalent to chronological ordering.
--  - MEDIUMTEXT → TEXT (SQLite has no length cap on TEXT).

CREATE TABLE IF NOT EXISTS agent_traces (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id   TEXT NOT NULL,
  message_id   TEXT NOT NULL,
  seq          INTEGER NOT NULL,
  type         TEXT NOT NULL,
  payload_json TEXT,
  ts           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_agent_traces_seq CHECK (seq >= 0)
);

CREATE INDEX IF NOT EXISTS idx_agent_traces_session ON agent_traces(session_id, ts);
CREATE INDEX IF NOT EXISTS idx_agent_traces_message ON agent_traces(message_id, seq);

-- ============================================================================
-- 15_create_rag_tables.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 15_create_rag_tables.sql
-- Description: RAG tables for Session 5 — tracks ingested documents and chunks.
--
-- SQLite notes:
--  - JSON metadata column → TEXT + json_valid() CHECK.

CREATE TABLE IF NOT EXISTS rag_documents (
  document_id   TEXT PRIMARY KEY,
  doc_type      TEXT NOT NULL,
  category      TEXT,
  source_path   TEXT NOT NULL UNIQUE,
  loader        TEXT NOT NULL,
  splitter      TEXT NOT NULL,
  chunk_size    INTEGER NOT NULL CHECK (chunk_size > 0),
  chunk_overlap INTEGER NOT NULL CHECK (chunk_overlap >= 0),
  content_hash  TEXT NOT NULL,
  ingested_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now'))
);

CREATE TABLE IF NOT EXISTS rag_chunks (
  chunk_id      TEXT PRIMARY KEY,
  document_id   TEXT NOT NULL,
  chunk_index   INTEGER NOT NULL CHECK (chunk_index >= 0),
  chunk_text    TEXT NOT NULL,
  metadata_json TEXT NOT NULL,
  vector_ref    TEXT NOT NULL UNIQUE,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT ck_rag_chunks_metadata_json CHECK (json_valid(metadata_json)),
  CONSTRAINT fk_chunks_document
    FOREIGN KEY (document_id) REFERENCES rag_documents(document_id) ON DELETE CASCADE,
  CONSTRAINT ux_rag_chunks_doc_index UNIQUE (document_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS ix_rag_docs_type    ON rag_documents(doc_type);
CREATE INDEX IF NOT EXISTS ix_rag_chunks_docid ON rag_chunks(document_id);

-- ============================================================================
-- 16_create_generated_assets_and_guardrail_events.sql
-- ============================================================================
-- StyleMart Database Schema for SQLite
-- File: 16_create_generated_assets_and_guardrail_events.sql
-- Description: Session 6 (Guardrails + Generated Assets) Layer-2 tables.
--              Mirrors the Mysql migration 2026-06-05 (no hard FKs to chat_*
--              tables, since those are Layer-2 and not guaranteed present).

CREATE TABLE IF NOT EXISTS generated_assets (
  asset_id          TEXT PRIMARY KEY,
  type              TEXT NOT NULL,
  session_id        TEXT,
  user_id           TEXT,
  cart_id           TEXT,
  body_html         TEXT,
  body_json         TEXT,
  source_inputs     TEXT NOT NULL,
  guardrail_results TEXT NOT NULL,
  created_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT chk_generated_assets_type
    CHECK (type IN ('recovery-email', 'landing-section', 'upsell-pitch')),
  CONSTRAINT chk_generated_assets_body
    CHECK (body_html IS NOT NULL OR body_json IS NOT NULL),
  CONSTRAINT chk_generated_assets_source_inputs_json
    CHECK (json_valid(source_inputs)),
  CONSTRAINT chk_generated_assets_guardrail_results_json
    CHECK (json_valid(guardrail_results)),
  CONSTRAINT chk_generated_assets_body_json
    CHECK (body_json IS NULL OR json_valid(body_json))
);

CREATE INDEX IF NOT EXISTS idx_generated_assets_user
  ON generated_assets(user_id, created_at);

-- Rows are IMMUTABLE: every column captured once at G1/G3/G4 success.
-- Regenerating an asset always mints a NEW asset_id; no UPDATE path.

CREATE TABLE IF NOT EXISTS guardrail_events (
  event_id         TEXT PRIMARY KEY,
  session_id       TEXT NOT NULL,
  message_id       TEXT,
  rule_id          TEXT NOT NULL,
  phase            TEXT NOT NULL,
  result           TEXT NOT NULL,
  message          TEXT,
  reprompt_message TEXT,
  created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),

  CONSTRAINT chk_guardrail_events_result
    CHECK (result IN ('success', 'failure', 'fatal'))
);

CREATE INDEX IF NOT EXISTS idx_guardrail_events_session
  ON guardrail_events(session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_guardrail_events_message
  ON guardrail_events(message_id);

COMMIT;

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- ============================================================================
-- seed/01_seed_categories.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 01 - Categories (15 rows: 2 parent + 13 leaf)
-- Target table: categories
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM categories;

INSERT INTO categories (slug, display_name, description, hero_image, parent_slug, sort_order) VALUES
  ('menswear', 'Menswear', NULL, 'assets/img/cat-menswear.png', NULL, 0),
  ('womenswear', 'Womenswear', NULL, 'assets/img/cat-womenswear.png', NULL, 1),
  ('tshirts', 'T-Shirts', NULL, 'assets/img/cat-tshirts.png', 'menswear', 0),
  ('shirts', 'Button-Down Shirts', NULL, 'assets/img/cat-shirts.png', 'menswear', 1),
  ('jeans', 'Jeans', NULL, 'assets/img/cat-jeans.png', 'menswear', 2),
  ('pants', 'Pants & Trousers', NULL, 'assets/img/cat-pants.png', 'menswear', 3),
  ('jackets', 'Jackets & Blazers', NULL, 'assets/img/cat-jackets.png', 'menswear', 4),
  ('dresses', 'Dresses', NULL, 'assets/img/cat-dresses.png', 'womenswear', 0),
  ('sweaters', 'Sweaters & Cardigans', NULL, 'assets/img/cat-sweaters.png', 'menswear', 5),
  ('raincoats', 'Raincoats', NULL, 'assets/img/cat-raincoats.png', 'menswear', 6),
  ('sneakers', 'Sneakers', NULL, 'assets/img/cat-sneakers.png', 'menswear', 7),
  ('formal-shoes', 'Formal Shoes', NULL, 'assets/img/cat-formal-shoes.png', 'menswear', 8),
  ('backpacks', 'Backpacks', NULL, 'assets/img/cat-backpacks.png', 'menswear', 9),
  ('sunglasses', 'Sunglasses', NULL, 'assets/img/cat-sunglasses.png', 'menswear', 10),
  ('accessories', 'Accessories', NULL, 'assets/img/cat-accessories.png', 'menswear', 11);


-- ============================================================================
-- seed/02_seed_loyalty_tiers.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 02 - Loyalty tiers (3 rows)
-- Target table: loyalty_tiers
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM loyalty_tiers;

INSERT INTO loyalty_tiers (tier_id, display_name, discount_pct, spend_threshold_cents, benefits, sort_order) VALUES
  ('tier_bronze', 'Bronze', 0.00, 0, '["Free shipping over $75","Birthday gift"]', 0),
  ('tier_silver', 'Silver', 5.00, 50000, '["Free shipping","Early access to drops","Birthday gift"]', 1),
  ('tier_gold', 'Gold', 10.00, 150000, '["Free expedited shipping","Early access","Personal stylist chat","Birthday gift"]', 2);


-- ============================================================================
-- seed/03_seed_users.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 03 - Users (5 demo users)
-- Target table: users
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


-- All 5 demo users share the same workshop password: Workshop2026!
-- bcrypt cost-12 hash below; never check in the plain password to source control
-- in production. For the workshop kit, the hash is intentional and pre-computed
-- so attendees can log in as any demo user without setup.
--
-- To rotate: python3 -c "import bcrypt; print(bcrypt.hashpw(b'NEW_PASSWORD', bcrypt.gensalt(12)).decode())"

DELETE FROM users;

INSERT INTO users (user_id, username, password_hash, display_name, email, loyalty_tier_id, created_at) VALUES
  ('usr_demo_001', 'jordan', '5d19a0953bb3fb3e668624ba8c92f136', 'Jordan Lee',    'jordan@example.com',  'tier_silver', '2026-01-27 00:00:00'),
  ('usr_demo_002', 'sam',    '5d19a0953bb3fb3e668624ba8c92f136', 'Sam Patel',     'sam@example.com',     'tier_bronze', '2026-03-28 00:00:00'),
  ('usr_demo_003', 'riley',  '5d19a0953bb3fb3e668624ba8c92f136', 'Riley Chen',    'riley@example.com',   'tier_gold',   '2025-04-22 00:00:00'),
  ('usr_demo_004', 'alex',   '5d19a0953bb3fb3e668624ba8c92f136', 'Alex Nguyen',   'alex@example.com',    'tier_silver', '2025-11-28 00:00:00'),
  ('usr_demo_005', 'morgan', '5d19a0953bb3fb3e668624ba8c92f136', 'Morgan Garcia', 'morgan@example.com',  'tier_bronze', '2026-04-27 00:00:00');


-- ============================================================================
-- seed/04_seed_products.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 04 - Products (200 rows)
-- Target table: products
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM products;

INSERT INTO products (product_id, slug, name, brand, category, subcategory, description, care_instructions, base_price_cents, currency, image_url, attributes, occasion_tags, average_rating, review_count) VALUES
  ('prd_01HZX001B79A0', 'cream-crew-neck-tshirts-prd-b79a0', 'Cream Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Cream crew-neck t-shirt in organic cotton. Soft hand-feel and relaxed-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 2549, 'USD', 'assets/img/tshirt_cream_relaxed-fit_organic-cotton_01.png', '{"fit":"relaxed-fit","fabric":"organic cotton"}', '["casual","weekend","layering"]', 5.00, 2),
  ('prd_01HZX002DC84B', 'white-crew-neck-tshirts-prd-dc84b', 'White Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'White crew-neck t-shirt in pima cotton. Soft hand-feel and slim-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3999, 'USD', 'assets/img/tshirt_white_slim-fit_pima-cotton_02.png', '{"fit":"slim-fit","fabric":"pima cotton"}', '["casual","weekend","layering"]', 5.00, 4),
  ('prd_01HZX003C4E7A', 'off-white-crew-neck-tshirts-prd-c4e7a', 'Off White Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Off White crew-neck t-shirt in cotton modal. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3399, 'USD', 'assets/img/tshirt_off-white_regular-fit_cotton-modal_03.png', '{"fit":"regular-fit","fabric":"cotton modal"}', '["casual","weekend","layering"]', 5.00, 3),
  ('prd_01HZX00469D94', 'sage-green-crew-neck-tshirts-prd-69d94', 'Sage Green Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Sage Green crew-neck t-shirt in organic cotton. Soft hand-feel and relaxed-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 2799, 'USD', 'assets/img/tshirt_sage-green_relaxed-fit_organic-cotton_04.png', '{"fit":"relaxed-fit","fabric":"organic cotton"}', '["casual","weekend","layering"]', 4.80, 4),
  ('prd_01HZX005E0B47', 'dusty-rose-crew-neck-tshirts-prd-e0b47', 'Dusty Rose Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Dusty Rose crew-neck t-shirt in cotton. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4149, 'USD', 'assets/img/tshirt_dusty-rose_regular-fit_cotton_05.png', '{"fit":"regular-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 4.00, 3),
  ('prd_01HZX006E013F', 'navy-crew-neck-tshirts-prd-e013f', 'Navy Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Navy crew-neck t-shirt in cotton blend. Soft hand-feel and slim-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3299, 'USD', 'assets/img/tshirt_navy_slim-fit_cotton-blend_06.png', '{"fit":"slim-fit","fabric":"cotton blend"}', '["casual","weekend","layering"]', 4.50, 2),
  ('prd_01HZX007467E4', 'charcoal-crew-neck-tshirts-prd-467e4', 'Charcoal Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Charcoal crew-neck t-shirt in cotton. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3049, 'USD', 'assets/img/tshirt_charcoal_regular-fit_cotton_07.png', '{"fit":"regular-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 4.00, 3),
  ('prd_01HZX00824F04', 'ivory-crew-neck-tshirts-prd-24f04', 'Ivory Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Ivory crew-neck t-shirt in organic cotton. Soft hand-feel and relaxed-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4049, 'USD', 'assets/img/tshirt_ivory_relaxed-fit_organic-cotton_08.png', '{"fit":"relaxed-fit","fabric":"organic cotton"}', '["casual","weekend","layering"]', 4.70, 3),
  ('prd_01HZX0092B381', 'terracotta-crew-neck-tshirts-prd-2b381', 'Terracotta Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Terracotta crew-neck t-shirt in cotton. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3649, 'USD', 'assets/img/tshirt_terracotta_regular-fit_cotton_09.png', '{"fit":"regular-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 4.00, 4),
  ('prd_01HZX010C1DC3', 'olive-crew-neck-tshirts-prd-c1dc3', 'Olive Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Olive crew-neck t-shirt in cotton blend. Soft hand-feel and relaxed-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4149, 'USD', 'assets/img/tshirt_olive_relaxed-fit_cotton-blend_10.png', '{"fit":"relaxed-fit","fabric":"cotton blend"}', '["casual","weekend","layering"]', 4.00, 3),
  ('prd_01HZX01118584', 'slate-blue-crew-neck-tshirts-prd-18584', 'Slate Blue Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Slate Blue crew-neck t-shirt in cotton modal. Soft hand-feel and slim-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3349, 'USD', 'assets/img/tshirt_slate-blue_slim-fit_cotton-modal_11.png', '{"fit":"slim-fit","fabric":"cotton modal"}', '["casual","weekend","layering"]', 5.00, 2),
  ('prd_01HZX0126D23C', 'burgundy-crew-neck-tshirts-prd-6d23c', 'Burgundy Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Burgundy crew-neck t-shirt in cotton. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4499, 'USD', 'assets/img/tshirt_burgundy_regular-fit_cotton_12.png', '{"fit":"regular-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 5.00, 2),
  ('prd_01HZX013AB385', 'white-crew-neck-tshirts-prd-ab385', 'White Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'White crew-neck t-shirt in cotton. Soft hand-feel and oversized silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3049, 'USD', 'assets/img/tshirt_white_oversized_cotton_13.png', '{"fit":"oversized","fabric":"cotton"}', '["casual","weekend","layering"]', 4.80, 4),
  ('prd_01HZX0142D7F7', 'black-crew-neck-tshirts-prd-2d7f7', 'Black Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Black crew-neck t-shirt in cotton. Soft hand-feel and slim-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3199, 'USD', 'assets/img/tshirt_black_slim-fit_cotton_14.png', '{"fit":"slim-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 4.50, 4),
  ('prd_01HZX0154D2D3', 'light-gray-crew-neck-tshirts-prd-4d2d3', 'Light Gray Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Light Gray crew-neck t-shirt in cotton modal. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4399, 'USD', 'assets/img/tshirt_light-gray_regular-fit_cotton-modal_15.png', '{"fit":"regular-fit","fabric":"cotton modal"}', '["casual","weekend","layering"]', 4.00, 2),
  ('prd_01HZX0161A9D0', 'sky-blue-crew-neck-tshirts-prd-1a9d0', 'Sky Blue Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Sky Blue crew-neck t-shirt in pima cotton. Soft hand-feel and slim-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3749, 'USD', 'assets/img/tshirt_sky-blue_slim-fit_pima-cotton_16.png', '{"fit":"slim-fit","fabric":"pima cotton"}', '["casual","weekend","layering"]', 5.00, 3),
  ('prd_01HZX01710C1A', 'mustard-crew-neck-tshirts-prd-10c1a', 'Mustard Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Mustard crew-neck t-shirt in cotton. Soft hand-feel and relaxed-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 4149, 'USD', 'assets/img/tshirt_mustard_relaxed-fit_cotton_17.png', '{"fit":"relaxed-fit","fabric":"cotton"}', '["casual","weekend","layering"]', 4.20, 4),
  ('prd_01HZX01855961', 'forest-green-crew-neck-tshirts-prd-55961', 'Forest Green Crew Neck Tshirts', 'StyleMart', 'tshirts', 'crew-neck', 'Forest Green crew-neck t-shirt in organic cotton. Soft hand-feel and regular-fit silhouette make it a daily staple.', 'Machine wash cold; tumble dry low.', 3249, 'USD', 'assets/img/tshirt_forest-green_regular-fit_organic-cotton_18.png', '{"fit":"regular-fit","fabric":"organic cotton"}', '["casual","weekend","layering"]', 5.00, 3),
  ('prd_01HZX019AA2CD', 'white-button-down-shirts-prd-aa2cd', 'White Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'White regular-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 7849, 'USD', 'assets/img/shirt_white_regular_cotton-poplin_01.png', '{"fit":"regular-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 4.80, 4),
  ('prd_01HZX020F074E', 'sky-blue-button-down-shirts-prd-f074e', 'Sky Blue Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Sky Blue slim-fit button-down shirt in oxford cotton. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8749, 'USD', 'assets/img/shirt_sky-blue_slim_oxford-cotton_02.png', '{"fit":"slim-fit","fabric":"oxford cotton"}', '["smart-casual","office","weekend"]', 4.00, 3),
  ('prd_01HZX02133D5C', 'light-gray-button-down-shirts-prd-33d5c', 'Light Gray Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Light Gray regular-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 6499, 'USD', 'assets/img/shirt_light-gray_regular_cotton-poplin_03.png', '{"fit":"regular-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 4.70, 3),
  ('prd_01HZX02236351', 'navy-button-down-shirts-prd-36351', 'Navy Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Navy slim-fit button-down shirt in oxford cotton. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8849, 'USD', 'assets/img/shirt_navy_slim_oxford-cotton_04.png', '{"fit":"slim-fit","fabric":"oxford cotton"}', '["smart-casual","office","weekend"]', 5.00, 2),
  ('prd_01HZX023EEA5C', 'sage-button-down-shirts-prd-eea5c', 'Sage Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Sage relaxed-fit button-down shirt in linen cotton blend. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 9299, 'USD', 'assets/img/shirt_sage_relaxed_linen-cotton-blend_05.png', '{"fit":"relaxed-fit","fabric":"linen cotton blend"}', '["smart-casual","office","weekend"]', 5.00, 2),
  ('prd_01HZX024F0015', 'ecru-button-down-shirts-prd-f0015', 'Ecru Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Ecru regular-fit button-down shirt in washed linen. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8649, 'USD', 'assets/img/shirt_ecru_regular_washed-linen_06.png', '{"fit":"regular-fit","fabric":"washed linen"}', '["smart-casual","office","weekend"]', 4.80, 4),
  ('prd_01HZX025162AE', 'oxford-blue-button-down-shirts-prd-162ae', 'Oxford Blue Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Oxford Blue slim-fit button-down shirt in oxford cotton. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 6599, 'USD', 'assets/img/shirt_oxford-blue_slim_oxford-cotton_07.png', '{"fit":"slim-fit","fabric":"oxford cotton"}', '["smart-casual","office","weekend"]', 4.20, 4),
  ('prd_01HZX026D3A3F', 'charcoal-button-down-shirts-prd-d3a3f', 'Charcoal Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Charcoal tailored-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8999, 'USD', 'assets/img/shirt_charcoal_tailored_cotton-poplin_08.png', '{"fit":"tailored-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 5.00, 2),
  ('prd_01HZX027E5251', 'dusty-blue-button-down-shirts-prd-e5251', 'Dusty Blue Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Dusty Blue regular-fit button-down shirt in chambray. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8849, 'USD', 'assets/img/shirt_dusty-blue_regular_chambray_09.png', '{"fit":"regular-fit","fabric":"chambray"}', '["smart-casual","office","weekend"]', 5.00, 3),
  ('prd_01HZX028EE8C5', 'ivory-button-down-shirts-prd-ee8c5', 'Ivory Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Ivory relaxed-fit button-down shirt in washed linen. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 6999, 'USD', 'assets/img/shirt_ivory_relaxed_washed-linen_10.png', '{"fit":"relaxed-fit","fabric":"washed linen"}', '["smart-casual","office","weekend"]', 4.80, 4),
  ('prd_01HZX0299CD6E', 'black-button-down-shirts-prd-9cd6e', 'Black Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Black slim-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 7599, 'USD', 'assets/img/shirt_black_slim_cotton-poplin_11.png', '{"fit":"slim-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 4.80, 4),
  ('prd_01HZX0302514B', 'pale-pink-button-down-shirts-prd-2514b', 'Pale Pink Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Pale Pink regular-fit button-down shirt in oxford cotton. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 7899, 'USD', 'assets/img/shirt_pale-pink_regular_oxford-cotton_12.png', '{"fit":"regular-fit","fabric":"oxford cotton"}', '["smart-casual","office","weekend"]', 5.00, 2),
  ('prd_01HZX03104039', 'olive-button-down-shirts-prd-04039', 'Olive Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Olive relaxed-fit button-down shirt in linen cotton blend. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 5949, 'USD', 'assets/img/shirt_olive_relaxed_linen-cotton-blend_13.png', '{"fit":"relaxed-fit","fabric":"linen cotton blend"}', '["smart-casual","office","weekend"]', 4.70, 3),
  ('prd_01HZX03216941', 'midnight-blue-button-down-shirts-prd-16941', 'Midnight Blue Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Midnight Blue slim-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 7349, 'USD', 'assets/img/shirt_midnight-blue_slim_cotton-poplin_14.png', '{"fit":"slim-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 4.80, 4),
  ('prd_01HZX033157E7', 'beige-button-down-shirts-prd-157e7', 'Beige Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Beige regular-fit button-down shirt in washed linen. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 6549, 'USD', 'assets/img/shirt_beige_regular_washed-linen_15.png', '{"fit":"regular-fit","fabric":"washed linen"}', '["smart-casual","office","weekend"]', 5.00, 3),
  ('prd_01HZX034CB2B2', 'burgundy-button-down-shirts-prd-cb2b2', 'Burgundy Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Burgundy slim-fit button-down shirt in oxford cotton. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8799, 'USD', 'assets/img/shirt_burgundy_slim_oxford-cotton_16.png', '{"fit":"slim-fit","fabric":"oxford cotton"}', '["smart-casual","office","weekend"]', 5.00, 4),
  ('prd_01HZX035816E9', 'teal-button-down-shirts-prd-816e9', 'Teal Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Teal regular-fit button-down shirt in cotton poplin. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 8649, 'USD', 'assets/img/shirt_teal_regular_cotton-poplin_17.png', '{"fit":"regular-fit","fabric":"cotton poplin"}', '["smart-casual","office","weekend"]', 5.00, 3),
  ('prd_01HZX0363DC1B', 'sand-button-down-shirts-prd-3dc1b', 'Sand Button Down Shirts', 'StyleMart', 'shirts', 'button-down', 'Sand relaxed-fit button-down shirt in linen cotton blend. Crisp collar construction and a versatile cut for office or weekend.', 'Machine wash cold; hang to dry; iron warm.', 5799, 'USD', 'assets/img/shirt_sand_relaxed_linen-cotton-blend_18.png', '{"fit":"relaxed-fit","fabric":"linen cotton blend"}', '["smart-casual","office","weekend"]', 4.20, 4),
  ('prd_01HZX0379CC49', 'indigo-denim-jeans-prd-9cc49', 'Indigo Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Indigo slim-fit jeans in 12oz denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 10099, 'USD', 'assets/img/jeans_indigo_slim-fit_12oz-denim_01.png', '{"fit":"slim-fit","fabric":"12oz denim"}', '["casual","weekend","travel"]', 4.70, 3),
  ('prd_01HZX038D8B0C', 'black-denim-jeans-prd-d8b0c', 'Black Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Black straight-fit jeans in stretch denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 9649, 'USD', 'assets/img/jeans_black_straight-fit_stretch-denim_02.png', '{"fit":"straight-fit","fabric":"stretch denim"}', '["casual","weekend","travel"]', 5.00, 3),
  ('prd_01HZX03959B15', 'mid-blue-denim-jeans-prd-59b15', 'Mid Blue Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Mid Blue slim-fit jeans in 12oz denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 10099, 'USD', 'assets/img/jeans_mid-blue_slim-fit_12oz-denim_03.png', '{"fit":"slim-fit","fabric":"12oz denim"}', '["casual","weekend","travel"]', 5.00, 3),
  ('prd_01HZX0403CEB8', 'light-wash-blue-denim-jeans-prd-3ceb8', 'Light Wash Blue Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Light Wash Blue relaxed-fit jeans in lightweight denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 11649, 'USD', 'assets/img/jeans_light-wash-blue_relaxed-fit_lightweight-denim_04.png', '{"fit":"relaxed-fit","fabric":"lightweight denim"}', '["casual","weekend","travel"]', 4.50, 4),
  ('prd_01HZX041CC651', 'charcoal-denim-jeans-prd-cc651', 'Charcoal Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Charcoal tapered jeans in stretch denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 9599, 'USD', 'assets/img/jeans_charcoal_tapered_stretch-denim_05.png', '{"fit":"tapered","fabric":"stretch denim"}', '["casual","weekend","travel"]', 5.00, 3),
  ('prd_01HZX042115D1', 'raw-indigo-denim-jeans-prd-115d1', 'Raw Indigo Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Raw Indigo slim-fit jeans in 12oz denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 10149, 'USD', 'assets/img/jeans_raw-indigo_slim-fit_12oz-denim_10.png', '{"fit":"slim-fit","fabric":"12oz denim"}', '["casual","weekend","travel"]', 5.00, 4),
  ('prd_01HZX04321198', 'vintage-blue-denim-jeans-prd-21198', 'Vintage Blue Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Vintage Blue straight-fit jeans in 12oz denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 13249, 'USD', 'assets/img/jeans_vintage-blue_straight-fit_12oz-denim_11.png', '{"fit":"straight-fit","fabric":"12oz denim"}', '["casual","weekend","travel"]', 4.80, 4),
  ('prd_01HZX0449E075', 'gray-denim-jeans-prd-9e075', 'Gray Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Gray tapered jeans in stretch denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 10199, 'USD', 'assets/img/jeans_gray_tapered_stretch-denim_12.png', '{"fit":"tapered","fabric":"stretch denim"}', '["casual","weekend","travel"]', 4.50, 2),
  ('prd_01HZX045DDBC0', 'deep-blue-denim-jeans-prd-ddbc0', 'Deep Blue Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Deep Blue slim-fit jeans in stretch denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 10999, 'USD', 'assets/img/jeans_deep-blue_slim-fit_stretch-denim_14.png', '{"fit":"slim-fit","fabric":"stretch denim"}', '["casual","weekend","travel"]', 5.00, 3),
  ('prd_01HZX04673CA4', 'black-denim-jeans-prd-73ca4', 'Black Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Black wide-leg jeans in 12oz denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 11649, 'USD', 'assets/img/jeans_black_wide-leg_12oz-denim_15.png', '{"fit":"wide-leg","fabric":"12oz denim"}', '["casual","weekend","travel"]', 4.50, 2),
  ('prd_01HZX04784E6E', 'bleached-blue-denim-jeans-prd-84e6e', 'Bleached Blue Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Bleached Blue relaxed-fit jeans in lightweight denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 12149, 'USD', 'assets/img/jeans_bleached-blue_relaxed-fit_lightweight-denim_18.png', '{"fit":"relaxed-fit","fabric":"lightweight denim"}', '["casual","weekend","travel"]', 3.70, 3),
  ('prd_01HZX048241B3', 'slate-denim-jeans-prd-241b3', 'Slate Denim Jeans', 'StyleMart', 'jeans', 'denim', 'Slate tapered jeans in stretch denim. Comfortable through the day with refined detailing at the back pockets.', 'Machine wash cold inside out; tumble dry low.', 8149, 'USD', 'assets/img/jeans_slate_tapered_stretch-denim_19.png', '{"fit":"tapered","fabric":"stretch denim"}', '["casual","weekend","travel"]', 4.80, 4),
  ('prd_01HZX04904E67', 'khaki-chinos-pants-prd-04e67', 'Khaki Chinos Pants', 'StyleMart', 'pants', 'chinos', 'Khaki straight-fit chinos in chino cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 12649, 'USD', 'assets/img/jeans_khaki_straight-fit_chino-cotton_06.png', '{"fit":"straight-fit","fabric":"chino cotton"}', '["smart-casual","office","travel"]', 5.00, 2),
  ('prd_01HZX050F7543', 'olive-trousers-pants-prd-f7543', 'Olive Trousers Pants', 'StyleMart', 'pants', 'trousers', 'Olive slim-fit trousers in twill cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 10099, 'USD', 'assets/img/jeans_olive_slim-fit_twill-cotton_07.png', '{"fit":"slim-fit","fabric":"twill cotton"}', '["smart-casual","office","travel"]', 4.00, 2);

INSERT INTO products (product_id, slug, name, brand, category, subcategory, description, care_instructions, base_price_cents, currency, image_url, attributes, occasion_tags, average_rating, review_count) VALUES
  ('prd_01HZX051B5C03', 'navy-chinos-pants-prd-b5c03', 'Navy Chinos Pants', 'StyleMart', 'pants', 'chinos', 'Navy straight-fit chinos in chino cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 11349, 'USD', 'assets/img/jeans_navy_straight-fit_chino-cotton_08.png', '{"fit":"straight-fit","fabric":"chino cotton"}', '["smart-casual","office","travel"]', 4.80, 4),
  ('prd_01HZX052DC64F', 'stone-trousers-pants-prd-dc64f', 'Stone Trousers Pants', 'StyleMart', 'pants', 'trousers', 'Stone relaxed-fit trousers in twill cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 8249, 'USD', 'assets/img/jeans_stone_relaxed-fit_twill-cotton_09.png', '{"fit":"relaxed-fit","fabric":"twill cotton"}', '["smart-casual","office","travel"]', 4.50, 4),
  ('prd_01HZX0534DE92', 'sand-chinos-pants-prd-4de92', 'Sand Chinos Pants', 'StyleMart', 'pants', 'chinos', 'Sand relaxed-fit chinos in chino cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 9499, 'USD', 'assets/img/jeans_sand_relaxed-fit_chino-cotton_13.png', '{"fit":"relaxed-fit","fabric":"chino cotton"}', '["smart-casual","office","travel"]', 4.20, 4),
  ('prd_01HZX054AA876', 'camel-trousers-pants-prd-aa876', 'Camel Trousers Pants', 'StyleMart', 'pants', 'trousers', 'Camel straight-fit trousers in twill cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 8849, 'USD', 'assets/img/jeans_camel_straight-fit_twill-cotton_16.png', '{"fit":"straight-fit","fabric":"twill cotton"}', '["smart-casual","office","travel"]', 5.00, 2),
  ('prd_01HZX0552CB2B', 'forest-green-chinos-pants-prd-2cb2b', 'Forest Green Chinos Pants', 'StyleMart', 'pants', 'chinos', 'Forest Green slim-fit chinos in chino cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 12349, 'USD', 'assets/img/jeans_forest-green_slim-fit_chino-cotton_17.png', '{"fit":"slim-fit","fabric":"chino cotton"}', '["smart-casual","office","travel"]', 4.50, 4),
  ('prd_01HZX056AC195', 'burgundy-trousers-pants-prd-ac195', 'Burgundy Trousers Pants', 'StyleMart', 'pants', 'trousers', 'Burgundy straight-fit trousers in twill cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 8349, 'USD', 'assets/img/jeans_burgundy_straight-fit_twill-cotton_20.png', '{"fit":"straight-fit","fabric":"twill cotton"}', '["smart-casual","office","travel"]', 4.50, 4),
  ('prd_01HZX0573CF7C', 'white-chinos-pants-prd-3cf7c', 'White Chinos Pants', 'StyleMart', 'pants', 'chinos', 'White slim-fit chinos in chino cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 8849, 'USD', 'assets/img/jeans_white_slim-fit_chino-cotton_21.png', '{"fit":"slim-fit","fabric":"chino cotton"}', '["smart-casual","office","travel"]', 3.50, 2),
  ('prd_01HZX0587C9B0', 'tan-trousers-pants-prd-7c9b0', 'Tan Trousers Pants', 'StyleMart', 'pants', 'trousers', 'Tan slim-fit trousers in twill cotton. Cleanly tailored with a slight stretch for all-day wear.', 'Machine wash cold; hang to dry.', 8749, 'USD', 'assets/img/jeans_tan_slim-fit_twill-cotton_24.png', '{"fit":"slim-fit","fabric":"twill cotton"}', '["smart-casual","office","travel"]', 4.80, 4),
  ('prd_01HZX0597F0E3', 'navy-travel-blazer-jackets-prd-7f0e3', 'Navy Travel Blazer Jackets', 'StyleMart', 'jackets', 'travel-blazer', 'Navy travel blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 20599, 'USD', 'assets/img/jacket_navy_tailored_travel-blazer_01.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.50, 4),
  ('prd_01HZX060DAB51', 'charcoal-lightweight-bomber-jackets-prd-dab51', 'Charcoal Lightweight Bomber Jackets', 'StyleMart', 'jackets', 'lightweight-bomber', 'Charcoal lightweight bomber with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 24049, 'USD', 'assets/img/jacket_charcoal_relaxed_lightweight-bomber_02.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.20, 4),
  ('prd_01HZX061959D1', 'camel-soft-shoulder-blazer-jackets-prd-959d1', 'Camel Soft Shoulder Blazer Jackets', 'StyleMart', 'jackets', 'soft-shoulder-blazer', 'Camel soft shoulder blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 17799, 'USD', 'assets/img/jacket_camel_tailored_soft-shoulder-blazer_03.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.30, 3),
  ('prd_01HZX06218D2C', 'olive-packable-jacket-jackets-prd-18d2c', 'Olive Packable Jacket Jackets', 'StyleMart', 'jackets', 'packable-jacket', 'Olive packable jacket with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 23899, 'USD', 'assets/img/jacket_olive_relaxed_packable-jacket_04.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.50, 2),
  ('prd_01HZX06332272', 'slate-gray-travel-blazer-jackets-prd-32272', 'Slate Gray Travel Blazer Jackets', 'StyleMart', 'jackets', 'travel-blazer', 'Slate Gray travel blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 27249, 'USD', 'assets/img/jacket_slate-gray_tailored_travel-blazer_05.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.00, 3),
  ('prd_01HZX064F12C1', 'deep-burgundy-soft-shoulder-blazer-jackets-prd-f12c1', 'Deep Burgundy Soft Shoulder Blazer Jackets', 'StyleMart', 'jackets', 'soft-shoulder-blazer', 'Deep Burgundy soft shoulder blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 29199, 'USD', 'assets/img/jacket_deep-burgundy_tailored_soft-shoulder-blazer_06.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.50, 2),
  ('prd_01HZX0657230C', 'black-lightweight-bomber-jackets-prd-7230c', 'Black Lightweight Bomber Jackets', 'StyleMart', 'jackets', 'lightweight-bomber', 'Black lightweight bomber with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 22349, 'USD', 'assets/img/jacket_black_relaxed_lightweight-bomber_07.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 5.00, 4),
  ('prd_01HZX06612615', 'sand-packable-jacket-jackets-prd-12615', 'Sand Packable Jacket Jackets', 'StyleMart', 'jackets', 'packable-jacket', 'Sand packable jacket with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 27799, 'USD', 'assets/img/jacket_sand_relaxed_packable-jacket_08.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.20, 4),
  ('prd_01HZX067FC6AF', 'midnight-blue-travel-blazer-jackets-prd-fc6af', 'Midnight Blue Travel Blazer Jackets', 'StyleMart', 'jackets', 'travel-blazer', 'Midnight Blue travel blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 21049, 'USD', 'assets/img/jacket_midnight-blue_tailored_travel-blazer_09.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.00, 2),
  ('prd_01HZX0682F18D', 'forest-green-packable-jacket-jackets-prd-2f18d', 'Forest Green Packable Jacket Jackets', 'StyleMart', 'jackets', 'packable-jacket', 'Forest Green packable jacket with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 20649, 'USD', 'assets/img/jacket_forest-green_relaxed_packable-jacket_10.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 5.00, 3),
  ('prd_01HZX069DD580', 'stone-soft-shoulder-blazer-jackets-prd-dd580', 'Stone Soft Shoulder Blazer Jackets', 'StyleMart', 'jackets', 'soft-shoulder-blazer', 'Stone soft shoulder blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 25099, 'USD', 'assets/img/jacket_stone_tailored_soft-shoulder-blazer_11.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 5.00, 2),
  ('prd_01HZX070429F3', 'teal-lightweight-bomber-jackets-prd-429f3', 'Teal Lightweight Bomber Jackets', 'StyleMart', 'jackets', 'lightweight-bomber', 'Teal lightweight bomber with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 25699, 'USD', 'assets/img/jacket_teal_relaxed_lightweight-bomber_12.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.80, 4),
  ('prd_01HZX07187B9E', 'graphite-travel-blazer-jackets-prd-87b9e', 'Graphite Travel Blazer Jackets', 'StyleMart', 'jackets', 'travel-blazer', 'Graphite travel blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 22899, 'USD', 'assets/img/jacket_graphite_tailored_travel-blazer_13.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.50, 2),
  ('prd_01HZX0722E7BB', 'tan-packable-jacket-jackets-prd-2e7bb', 'Tan Packable Jacket Jackets', 'StyleMart', 'jackets', 'packable-jacket', 'Tan packable jacket with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 23299, 'USD', 'assets/img/jacket_tan_relaxed_packable-jacket_14.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.70, 3),
  ('prd_01HZX0739DCBA', 'wine-soft-shoulder-blazer-jackets-prd-9dcba', 'Wine Soft Shoulder Blazer Jackets', 'StyleMart', 'jackets', 'soft-shoulder-blazer', 'Wine soft shoulder blazer with a tailored silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 15249, 'USD', 'assets/img/jacket_wine_tailored_soft-shoulder-blazer_15.png', '{"fit":"tailored"}', '["smart-casual","office","travel","conference"]', 4.70, 3),
  ('prd_01HZX074BF315', 'steel-blue-lightweight-bomber-jackets-prd-bf315', 'Steel Blue Lightweight Bomber Jackets', 'StyleMart', 'jackets', 'lightweight-bomber', 'Steel Blue lightweight bomber with a relaxed silhouette. Wrinkle-resistant and packable for travel.', 'Spot clean or dry clean only.', 29749, 'USD', 'assets/img/jacket_steel-blue_relaxed_lightweight-bomber_16.png', '{"fit":"relaxed"}', '["smart-casual","office","travel","conference"]', 4.70, 3),
  ('prd_01HZX075CAF3A', 'black-a-line-dresses-prd-caf3a', 'Black A Line Dresses', 'StyleMart', 'dresses', 'a-line', 'Black a line dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 17949, 'USD', 'assets/img/dress_black_a-line_midi_01.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.30, 3),
  ('prd_01HZX076F5A53', 'navy-sheath-dresses-prd-f5a53', 'Navy Sheath Dresses', 'StyleMart', 'dresses', 'sheath', 'Navy sheath dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 9949, 'USD', 'assets/img/dress_navy_sheath_knee-length_02.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 5.00, 2),
  ('prd_01HZX0777A454', 'sage-wrap-dresses-prd-7a454', 'Sage Wrap Dresses', 'StyleMart', 'dresses', 'wrap', 'Sage wrap dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 10649, 'USD', 'assets/img/dress_sage_wrap_midi_03.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.30, 3),
  ('prd_01HZX07842949', 'dusty-rose-shift-dresses-prd-42949', 'Dusty Rose Shift Dresses', 'StyleMart', 'dresses', 'shift', 'Dusty Rose shift dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 10649, 'USD', 'assets/img/dress_dusty-rose_shift_knee-length_04.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 5.00, 3),
  ('prd_01HZX079F7EA2', 'terracotta-tiered-dresses-prd-f7ea2', 'Terracotta Tiered Dresses', 'StyleMart', 'dresses', 'tiered', 'Terracotta tiered dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 14949, 'USD', 'assets/img/dress_terracotta_tiered_maxi_05.png', '{"length":"maxi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.80, 4),
  ('prd_01HZX080C8931', 'ivory-a-line-dresses-prd-c8931', 'Ivory A Line Dresses', 'StyleMart', 'dresses', 'a-line', 'Ivory a line dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 16099, 'USD', 'assets/img/dress_ivory_a-line_knee-length_06.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 5.00, 2),
  ('prd_01HZX081764A2', 'deep-teal-sheath-dresses-prd-764a2', 'Deep Teal Sheath Dresses', 'StyleMart', 'dresses', 'sheath', 'Deep Teal sheath dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 15449, 'USD', 'assets/img/dress_deep-teal_sheath_midi_07.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.30, 3),
  ('prd_01HZX082D4891', 'burgundy-wrap-dresses-prd-d4891', 'Burgundy Wrap Dresses', 'StyleMart', 'dresses', 'wrap', 'Burgundy wrap dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 15349, 'USD', 'assets/img/dress_burgundy_wrap_knee-length_08.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.00, 2),
  ('prd_01HZX08301444', 'charcoal-shift-dresses-prd-01444', 'Charcoal Shift Dresses', 'StyleMart', 'dresses', 'shift', 'Charcoal shift dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 16549, 'USD', 'assets/img/dress_charcoal_shift_midi_09.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.00, 2),
  ('prd_01HZX0843DA3E', 'coral-a-line-dresses-prd-3da3e', 'Coral A Line Dresses', 'StyleMart', 'dresses', 'a-line', 'Coral a line dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 10149, 'USD', 'assets/img/dress_coral_a-line_maxi_10.png', '{"length":"maxi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.00, 2),
  ('prd_01HZX085CDF38', 'plum-sheath-dresses-prd-cdf38', 'Plum Sheath Dresses', 'StyleMart', 'dresses', 'sheath', 'Plum sheath dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 15499, 'USD', 'assets/img/dress_plum_sheath_knee-length_11.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.00, 2),
  ('prd_01HZX08657E3B', 'olive-wrap-dresses-prd-57e3b', 'Olive Wrap Dresses', 'StyleMart', 'dresses', 'wrap', 'Olive wrap dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 13499, 'USD', 'assets/img/dress_olive_wrap_midi_12.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 5.00, 3),
  ('prd_01HZX0874E45A', 'midnight-blue-tiered-dresses-prd-4e45a', 'Midnight Blue Tiered Dresses', 'StyleMart', 'dresses', 'tiered', 'Midnight Blue tiered dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 14199, 'USD', 'assets/img/dress_midnight-blue_tiered_maxi_13.png', '{"length":"maxi","fabric":"jersey"}', '["smart-casual","date","summer"]', 3.50, 2),
  ('prd_01HZX0880B378', 'blush-pink-a-line-dresses-prd-0b378', 'Blush Pink A Line Dresses', 'StyleMart', 'dresses', 'a-line', 'Blush Pink a line dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 16949, 'USD', 'assets/img/dress_blush-pink_a-line_knee-length_14.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.50, 4),
  ('prd_01HZX0890DDC6', 'forest-green-sheath-dresses-prd-0ddc6', 'Forest Green Sheath Dresses', 'StyleMart', 'dresses', 'sheath', 'Forest Green sheath dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 11449, 'USD', 'assets/img/dress_forest-green_sheath_midi_15.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.00, 2),
  ('prd_01HZX090404A1', 'mustard-shift-dresses-prd-404a1', 'Mustard Shift Dresses', 'StyleMart', 'dresses', 'shift', 'Mustard shift dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 14449, 'USD', 'assets/img/dress_mustard_shift_knee-length_16.png', '{"length":"knee length","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.50, 2),
  ('prd_01HZX091FD149', 'lavender-wrap-dresses-prd-fd149', 'Lavender Wrap Dresses', 'StyleMart', 'dresses', 'wrap', 'Lavender wrap dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 12249, 'USD', 'assets/img/dress_lavender_wrap_midi_17.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 4.80, 4),
  ('prd_01HZX0924A019', 'cream-tiered-dresses-prd-4a019', 'Cream Tiered Dresses', 'StyleMart', 'dresses', 'tiered', 'Cream tiered dress in jersey. Easy to layer and travel-friendly.', 'Machine wash cold; lay flat to dry.', 9599, 'USD', 'assets/img/dress_cream_tiered_midi_20.png', '{"length":"midi","fabric":"jersey"}', '["smart-casual","date","summer"]', 5.00, 4),
  ('prd_01HZX09307566', 'charcoal-crew-neck-sweater-sweaters-prd-07566', 'Charcoal Crew Neck Sweater Sweaters', 'StyleMart', 'sweaters', 'crew-neck-sweater', 'Charcoal crew neck sweater in merino wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 11949, 'USD', 'assets/img/winter_charcoal_crew-neck-sweater_merino-wool_01.png', '{"fabric":"merino wool"}', '["layering","autumn","weekend"]', 4.30, 3),
  ('prd_01HZX09475580', 'oatmeal-half-zip-pullover-sweaters-prd-75580', 'Oatmeal Half Zip Pullover Sweaters', 'StyleMart', 'sweaters', 'half-zip-pullover', 'Oatmeal half zip pullover in lambswool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 13999, 'USD', 'assets/img/winter_oatmeal_half-zip-pullover_lambswool_02.png', '{"fabric":"lambswool"}', '["layering","autumn","weekend"]', 5.00, 2),
  ('prd_01HZX0952D0E4', 'forest-green-cardigan-sweaters-prd-2d0e4', 'Forest Green Cardigan Sweaters', 'StyleMart', 'sweaters', 'cardigan', 'Forest Green cardigan in cashmere blend. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 9149, 'USD', 'assets/img/winter_forest-green_cardigan_cashmere-blend_03.png', '{"fabric":"cashmere blend"}', '["layering","autumn","weekend"]', 4.30, 3),
  ('prd_01HZX096BA323', 'burgundy-crew-neck-sweater-sweaters-prd-ba323', 'Burgundy Crew Neck Sweater Sweaters', 'StyleMart', 'sweaters', 'crew-neck-sweater', 'Burgundy crew neck sweater in merino wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 13049, 'USD', 'assets/img/winter_burgundy_crew-neck-sweater_merino-wool_06.png', '{"fabric":"merino wool"}', '["layering","autumn","weekend"]', 4.50, 2),
  ('prd_01HZX0975A9A5', 'slate-half-zip-pullover-sweaters-prd-5a9a5', 'Slate Half Zip Pullover Sweaters', 'StyleMart', 'sweaters', 'half-zip-pullover', 'Slate half zip pullover in lambswool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 17599, 'USD', 'assets/img/winter_slate_half-zip-pullover_lambswool_07.png', '{"fabric":"lambswool"}', '["layering","autumn","weekend"]', 3.50, 2),
  ('prd_01HZX098C50A4', 'cream-cardigan-sweaters-prd-c50a4', 'Cream Cardigan Sweaters', 'StyleMart', 'sweaters', 'cardigan', 'Cream cardigan in cashmere blend. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 8899, 'USD', 'assets/img/winter_cream_cardigan_cashmere-blend_08.png', '{"fabric":"cashmere blend"}', '["layering","autumn","weekend"]', 4.50, 2),
  ('prd_01HZX0992C9F9', 'rust-crew-neck-sweater-sweaters-prd-2c9f9', 'Rust Crew Neck Sweater Sweaters', 'StyleMart', 'sweaters', 'crew-neck-sweater', 'Rust crew neck sweater in lambswool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 10449, 'USD', 'assets/img/winter_rust_crew-neck-sweater_lambswool_11.png', '{"fabric":"lambswool"}', '["layering","autumn","weekend"]', 4.30, 3),
  ('prd_01HZX10097636', 'graphite-half-zip-pullover-sweaters-prd-97636', 'Graphite Half Zip Pullover Sweaters', 'StyleMart', 'sweaters', 'half-zip-pullover', 'Graphite half zip pullover in brushed alpaca. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 15049, 'USD', 'assets/img/winter_graphite_half-zip-pullover_brushed-alpaca_12.png', '{"fabric":"brushed alpaca"}', '["layering","autumn","weekend"]', 5.00, 2);

INSERT INTO products (product_id, slug, name, brand, category, subcategory, description, care_instructions, base_price_cents, currency, image_url, attributes, occasion_tags, average_rating, review_count) VALUES
  ('prd_01HZX10131F77', 'ivory-cardigan-sweaters-prd-31f77', 'Ivory Cardigan Sweaters', 'StyleMart', 'sweaters', 'cardigan', 'Ivory cardigan in merino wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 8849, 'USD', 'assets/img/winter_ivory_cardigan_merino-wool_13.png', '{"fabric":"merino wool"}', '["layering","autumn","weekend"]', 5.00, 3),
  ('prd_01HZX102C7A4D', 'steel-blue-crew-neck-sweater-sweaters-prd-c7a4d', 'Steel Blue Crew Neck Sweater Sweaters', 'StyleMart', 'sweaters', 'crew-neck-sweater', 'Steel Blue crew neck sweater in merino wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 14199, 'USD', 'assets/img/winter_steel-blue_crew-neck-sweater_merino-wool_16.png', '{"fabric":"merino wool"}', '["layering","autumn","weekend"]', 4.00, 3),
  ('prd_01HZX103049E0', 'mustard-half-zip-pullover-sweaters-prd-049e0', 'Mustard Half Zip Pullover Sweaters', 'StyleMart', 'sweaters', 'half-zip-pullover', 'Mustard half zip pullover in lambswool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 13649, 'USD', 'assets/img/winter_mustard_half-zip-pullover_lambswool_17.png', '{"fabric":"lambswool"}', '["layering","autumn","weekend"]', 4.20, 4),
  ('prd_01HZX10433FC9', 'plum-cardigan-sweaters-prd-33fc9', 'Plum Cardigan Sweaters', 'StyleMart', 'sweaters', 'cardigan', 'Plum cardigan in brushed alpaca. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 12999, 'USD', 'assets/img/winter_plum_cardigan_brushed-alpaca_18.png', '{"fabric":"brushed alpaca"}', '["layering","autumn","weekend"]', 4.50, 4),
  ('prd_01HZX1056D522', 'maroon-crew-neck-sweater-sweaters-prd-6d522', 'Maroon Crew Neck Sweater Sweaters', 'StyleMart', 'sweaters', 'crew-neck-sweater', 'Maroon crew neck sweater in recycled wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 13849, 'USD', 'assets/img/winter_maroon_crew-neck-sweater_recycled-wool_21.png', '{"fabric":"recycled wool"}', '["layering","autumn","weekend"]', 4.20, 4),
  ('prd_01HZX10612544', 'pebble-gray-half-zip-pullover-sweaters-prd-12544', 'Pebble Gray Half Zip Pullover Sweaters', 'StyleMart', 'sweaters', 'half-zip-pullover', 'Pebble Gray half zip pullover in merino wool. Soft, breathable, and shaped to layer cleanly.', 'Hand wash cold; lay flat to dry.', 15049, 'USD', 'assets/img/winter_pebble-gray_half-zip-pullover_merino-wool_22.png', '{"fabric":"merino wool"}', '["layering","autumn","weekend"]', 4.00, 3),
  ('prd_01HZX10787D6A', 'olive-packable-raincoats-prd-87d6a', 'Olive Packable Raincoats', 'StyleMart', 'raincoats', 'packable', 'Olive mid length packable raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 15499, 'USD', 'assets/img/raincoat_olive_mid-length_packable_01.png', '{"length":"mid length"}', '["rain","travel","commute"]', 5.00, 3),
  ('prd_01HZX1084A3F6', 'navy-technical-shell-raincoats-prd-4a3f6', 'Navy Technical Shell Raincoats', 'StyleMart', 'raincoats', 'technical-shell', 'Navy hip length technical shell raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 17549, 'USD', 'assets/img/raincoat_navy_hip-length_technical-shell_02.png', '{"length":"hip length"}', '["rain","travel","commute"]', 4.00, 2),
  ('prd_01HZX1096EF12', 'translucent-black-double-breasted-trench-raincoats-prd-6ef12', 'Translucent Black Double Breasted Trench Raincoats', 'StyleMart', 'raincoats', 'double-breasted-trench', 'Translucent Black longline double breasted trench raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 16449, 'USD', 'assets/img/raincoat_translucent-black_longline_double-breasted-trench_03.png', '{"length":"longline"}', '["rain","travel","commute"]', 5.00, 2),
  ('prd_01HZX1107C1E2', 'sand-packable-raincoats-prd-7c1e2', 'Sand Packable Raincoats', 'StyleMart', 'raincoats', 'packable', 'Sand mid length packable raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 25049, 'USD', 'assets/img/raincoat_sand_mid-length_packable_04.png', '{"length":"mid length"}', '["rain","travel","commute"]', 4.30, 3),
  ('prd_01HZX111A1816', 'slate-gray-technical-shell-raincoats-prd-a1816', 'Slate Gray Technical Shell Raincoats', 'StyleMart', 'raincoats', 'technical-shell', 'Slate Gray hip length technical shell raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 19099, 'USD', 'assets/img/raincoat_slate-gray_hip-length_technical-shell_05.png', '{"length":"hip length"}', '["rain","travel","commute"]', 4.00, 3),
  ('prd_01HZX11235EA4', 'butter-yellow-packable-raincoats-prd-35ea4', 'Butter Yellow Packable Raincoats', 'StyleMart', 'raincoats', 'packable', 'Butter Yellow longline packable raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 24249, 'USD', 'assets/img/raincoat_butter-yellow_longline_packable_06.png', '{"length":"longline"}', '["rain","travel","commute"]', 4.30, 3),
  ('prd_01HZX11384678', 'forest-green-double-breasted-trench-raincoats-prd-84678', 'Forest Green Double Breasted Trench Raincoats', 'StyleMart', 'raincoats', 'double-breasted-trench', 'Forest Green mid length double breasted trench raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 14099, 'USD', 'assets/img/raincoat_forest-green_mid-length_double-breasted-trench_07.png', '{"length":"mid length"}', '["rain","travel","commute"]', 5.00, 4),
  ('prd_01HZX11402B03', 'charcoal-packable-raincoats-prd-02b03', 'Charcoal Packable Raincoats', 'StyleMart', 'raincoats', 'packable', 'Charcoal hip length packable raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 12449, 'USD', 'assets/img/raincoat_charcoal_hip-length_packable_08.png', '{"length":"hip length"}', '["rain","travel","commute"]', 4.80, 4),
  ('prd_01HZX115C0A4D', 'midnight-blue-technical-shell-raincoats-prd-c0a4d', 'Midnight Blue Technical Shell Raincoats', 'StyleMart', 'raincoats', 'technical-shell', 'Midnight Blue longline technical shell raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 16749, 'USD', 'assets/img/raincoat_midnight-blue_longline_technical-shell_09.png', '{"length":"longline"}', '["rain","travel","commute"]', 4.30, 3),
  ('prd_01HZX116F83B6', 'camel-double-breasted-trench-raincoats-prd-f83b6', 'Camel Double Breasted Trench Raincoats', 'StyleMart', 'raincoats', 'double-breasted-trench', 'Camel mid length double breasted trench raincoat. Water-repellent and built to pack flat.', 'Wipe clean with a damp cloth; reproof annually.', 25899, 'USD', 'assets/img/raincoat_camel_mid-length_double-breasted-trench_10.png', '{"length":"mid length"}', '["rain","travel","commute"]', 4.00, 2),
  ('prd_01HZX11761294', 'white-low-top-sneakers-prd-61294', 'White Low Top Sneakers', 'StyleMart', 'sneakers', 'low-top', 'White low top sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 13999, 'USD', 'assets/img/sneakers_white_low-top_knit-textile_01.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 5.00, 2),
  ('prd_01HZX1187129E', 'off-white-minimalist-sneakers-prd-7129e', 'Off White Minimalist Sneakers', 'StyleMart', 'sneakers', 'minimalist', 'Off White minimalist sneakers in leather. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 16749, 'USD', 'assets/img/sneakers_off-white_minimalist_leather_02.png', '{"material":"leather"}', '["casual","walking","travel"]', 4.80, 4),
  ('prd_01HZX119D1277', 'cream-retro-sneakers-prd-d1277', 'Cream Retro Sneakers', 'StyleMart', 'sneakers', 'retro', 'Cream retro sneakers in suede. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 15799, 'USD', 'assets/img/sneakers_cream_retro_suede_03.png', '{"material":"suede"}', '["casual","walking","travel"]', 4.50, 4),
  ('prd_01HZX120F9C60', 'navy-low-top-sneakers-prd-f9c60', 'Navy Low Top Sneakers', 'StyleMart', 'sneakers', 'low-top', 'Navy low top sneakers in recycled mesh. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 16249, 'USD', 'assets/img/sneakers_navy_low-top_recycled-mesh_04.png', '{"material":"recycled mesh"}', '["casual","walking","travel"]', 5.00, 3),
  ('prd_01HZX1215905A', 'all-black-mid-top-sneakers-prd-5905a', 'All Black Mid Top Sneakers', 'StyleMart', 'sneakers', 'mid-top', 'All Black mid top sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 17549, 'USD', 'assets/img/sneakers_all-black_mid-top_knit-textile_05.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 5.00, 4),
  ('prd_01HZX122D9B14', 'gray-minimalist-sneakers-prd-d9b14', 'Gray Minimalist Sneakers', 'StyleMart', 'sneakers', 'minimalist', 'Gray minimalist sneakers in leather. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 10999, 'USD', 'assets/img/sneakers_gray_minimalist_leather_06.png', '{"material":"leather"}', '["casual","walking","travel"]', 5.00, 3),
  ('prd_01HZX123E4094', 'olive-low-top-sneakers-prd-e4094', 'Olive Low Top Sneakers', 'StyleMart', 'sneakers', 'low-top', 'Olive low top sneakers in suede. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 12049, 'USD', 'assets/img/sneakers_olive_low-top_suede_07.png', '{"material":"suede"}', '["casual","walking","travel"]', 4.00, 2),
  ('prd_01HZX1247FAD9', 'sand-retro-sneakers-prd-7fad9', 'Sand Retro Sneakers', 'StyleMart', 'sneakers', 'retro', 'Sand retro sneakers in recycled mesh. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 14849, 'USD', 'assets/img/sneakers_sand_retro_recycled-mesh_08.png', '{"material":"recycled mesh"}', '["casual","walking","travel"]', 4.80, 4),
  ('prd_01HZX125AC267', 'charcoal-low-top-sneakers-prd-ac267', 'Charcoal Low Top Sneakers', 'StyleMart', 'sneakers', 'low-top', 'Charcoal low top sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 9749, 'USD', 'assets/img/sneakers_charcoal_low-top_knit-textile_09.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 4.20, 4),
  ('prd_01HZX12691BDE', 'light-gray-minimalist-sneakers-prd-91bde', 'Light Gray Minimalist Sneakers', 'StyleMart', 'sneakers', 'minimalist', 'Light Gray minimalist sneakers in recycled mesh. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 16299, 'USD', 'assets/img/sneakers_light-gray_minimalist_recycled-mesh_10.png', '{"material":"recycled mesh"}', '["casual","walking","travel"]', 4.30, 3),
  ('prd_01HZX127232F6', 'beige-low-top-sneakers-prd-232f6', 'Beige Low Top Sneakers', 'StyleMart', 'sneakers', 'low-top', 'Beige low top sneakers in leather. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 16599, 'USD', 'assets/img/sneakers_beige_low-top_leather_11.png', '{"material":"leather"}', '["casual","walking","travel"]', 5.00, 3),
  ('prd_01HZX12889982', 'sky-blue-retro-sneakers-prd-89982', 'Sky Blue Retro Sneakers', 'StyleMart', 'sneakers', 'retro', 'Sky Blue retro sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 11649, 'USD', 'assets/img/sneakers_sky-blue_retro_knit-textile_12.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 4.50, 2),
  ('prd_01HZX1291DA14', 'taupe-minimalist-sneakers-prd-1da14', 'Taupe Minimalist Sneakers', 'StyleMart', 'sneakers', 'minimalist', 'Taupe minimalist sneakers in suede. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 13749, 'USD', 'assets/img/sneakers_taupe_minimalist_suede_14.png', '{"material":"suede"}', '["casual","walking","travel"]', 4.80, 4),
  ('prd_01HZX13080265', 'ivory-retro-sneakers-prd-80265', 'Ivory Retro Sneakers', 'StyleMart', 'sneakers', 'retro', 'Ivory retro sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 17249, 'USD', 'assets/img/sneakers_ivory_retro_knit-textile_16.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 4.00, 3),
  ('prd_01HZX13136F77', 'slate-mid-top-sneakers-prd-36f77', 'Slate Mid Top Sneakers', 'StyleMart', 'sneakers', 'mid-top', 'Slate mid top sneakers in leather. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 15549, 'USD', 'assets/img/sneakers_slate_mid-top_leather_17.png', '{"material":"leather"}', '["casual","walking","travel"]', 4.20, 4),
  ('prd_01HZX132713B9', 'white-mid-top-sneakers-prd-713b9', 'White Mid Top Sneakers', 'StyleMart', 'sneakers', 'mid-top', 'White mid top sneakers in knit textile. Cushioned footbed and a quiet sole.', 'Wipe clean with a damp cloth; air dry.', 17049, 'USD', 'assets/img/sneakers_white_mid-top_knit-textile_42.png', '{"material":"knit textile"}', '["casual","walking","travel"]', 5.00, 2),
  ('prd_01HZX133BF1C8', 'black-oxford-formal-shoes-prd-bf1c8', 'Black Oxford Formal Shoes', 'StyleMart', 'formal-shoes', 'oxford', 'Black oxford in smooth. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 18199, 'USD', 'assets/img/formal-shoes_black_oxford_smooth_01.png', '{"leather":"smooth"}', '["office","formal","conference"]', 4.80, 4),
  ('prd_01HZX134D5B9A', 'dark-brown-derby-formal-shoes-prd-d5b9a', 'Dark Brown Derby Formal Shoes', 'StyleMart', 'formal-shoes', 'derby', 'Dark Brown derby in full grain. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 27499, 'USD', 'assets/img/formal-shoes_dark-brown_derby_full-grain_02.png', '{"leather":"full grain"}', '["office","formal","conference"]', 5.00, 2),
  ('prd_01HZX135E48B5', 'oxblood-loafer-formal-shoes-prd-e48b5', 'Oxblood Loafer Formal Shoes', 'StyleMart', 'formal-shoes', 'loafer', 'Oxblood loafer in suede. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 21699, 'USD', 'assets/img/formal-shoes_oxblood_loafer_suede_03.png', '{"leather":"suede"}', '["office","formal","conference"]', 4.70, 3),
  ('prd_01HZX136DAFED', 'tan-monk-strap-formal-shoes-prd-dafed', 'Tan Monk Strap Formal Shoes', 'StyleMart', 'formal-shoes', 'monk-strap', 'Tan monk strap in pebbled. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 21549, 'USD', 'assets/img/formal-shoes_tan_monk-strap_pebbled_04.png', '{"leather":"pebbled"}', '["office","formal","conference"]', 5.00, 4),
  ('prd_01HZX137A036C', 'walnut-oxford-formal-shoes-prd-a036c', 'Walnut Oxford Formal Shoes', 'StyleMart', 'formal-shoes', 'oxford', 'Walnut oxford in full grain. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 19999, 'USD', 'assets/img/formal-shoes_walnut_oxford_full-grain_05.png', '{"leather":"full grain"}', '["office","formal","conference"]', 4.80, 4),
  ('prd_01HZX13862E11', 'black-derby-formal-shoes-prd-62e11', 'Black Derby Formal Shoes', 'StyleMart', 'formal-shoes', 'derby', 'Black derby in smooth. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 16199, 'USD', 'assets/img/formal-shoes_black_derby_smooth_06.png', '{"leather":"smooth"}', '["office","formal","conference"]', 4.80, 4),
  ('prd_01HZX139E8725', 'cognac-loafer-formal-shoes-prd-e8725', 'Cognac Loafer Formal Shoes', 'StyleMart', 'formal-shoes', 'loafer', 'Cognac loafer in full grain. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 24949, 'USD', 'assets/img/formal-shoes_cognac_loafer_full-grain_07.png', '{"leather":"full grain"}', '["office","formal","conference"]', 3.50, 2),
  ('prd_01HZX140A9006', 'charcoal-monk-strap-formal-shoes-prd-a9006', 'Charcoal Monk Strap Formal Shoes', 'StyleMart', 'formal-shoes', 'monk-strap', 'Charcoal monk strap in suede. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 18899, 'USD', 'assets/img/formal-shoes_charcoal_monk-strap_suede_08.png', '{"leather":"suede"}', '["office","formal","conference"]', 4.00, 3),
  ('prd_01HZX14183BB7', 'midnight-blue-oxford-formal-shoes-prd-83bb7', 'Midnight Blue Oxford Formal Shoes', 'StyleMart', 'formal-shoes', 'oxford', 'Midnight Blue oxford in pebbled. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 18349, 'USD', 'assets/img/formal-shoes_midnight-blue_oxford_pebbled_09.png', '{"leather":"pebbled"}', '["office","formal","conference"]', 4.20, 4),
  ('prd_01HZX1422D279', 'espresso-derby-formal-shoes-prd-2d279', 'Espresso Derby Formal Shoes', 'StyleMart', 'formal-shoes', 'derby', 'Espresso derby in smooth. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 15199, 'USD', 'assets/img/formal-shoes_espresso_derby_smooth_10.png', '{"leather":"smooth"}', '["office","formal","conference"]', 4.50, 4),
  ('prd_01HZX14302FF2', 'sand-loafer-formal-shoes-prd-02ff2', 'Sand Loafer Formal Shoes', 'StyleMart', 'formal-shoes', 'loafer', 'Sand loafer in suede. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 14499, 'USD', 'assets/img/formal-shoes_sand_loafer_suede_11.png', '{"leather":"suede"}', '["office","formal","conference"]', 3.50, 2),
  ('prd_01HZX1446DC9A', 'burgundy-monk-strap-formal-shoes-prd-6dc9a', 'Burgundy Monk Strap Formal Shoes', 'StyleMart', 'formal-shoes', 'monk-strap', 'Burgundy monk strap in full grain. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 25699, 'USD', 'assets/img/formal-shoes_burgundy_monk-strap_full-grain_12.png', '{"leather":"full grain"}', '["office","formal","conference"]', 5.00, 2),
  ('prd_01HZX145F81B7', 'graphite-oxford-formal-shoes-prd-f81b7', 'Graphite Oxford Formal Shoes', 'StyleMart', 'formal-shoes', 'oxford', 'Graphite oxford in smooth. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 24099, 'USD', 'assets/img/formal-shoes_graphite_oxford_smooth_13.png', '{"leather":"smooth"}', '["office","formal","conference"]', 4.00, 3),
  ('prd_01HZX146DC626', 'camel-derby-formal-shoes-prd-dc626', 'Camel Derby Formal Shoes', 'StyleMart', 'formal-shoes', 'derby', 'Camel derby in pebbled. Welted construction with a classic last.', 'Polish regularly; use shoe trees.', 17599, 'USD', 'assets/img/formal-shoes_camel_derby_pebbled_14.png', '{"leather":"pebbled"}', '["office","formal","conference"]', 4.70, 3),
  ('prd_01HZX147B19E0', 'black-minimalist-commuter-backpacks-prd-b19e0', 'Black Minimalist Commuter Backpacks', 'StyleMart', 'backpacks', 'minimalist-commuter', 'Black minimalist commuter backpack in recycled nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 20999, 'USD', 'assets/img/backpack_black_minimalist-commuter_recycled-nylon_01.png', '{"material":"recycled nylon"}', '["commute","travel","work"]', 5.00, 2),
  ('prd_01HZX148501A3', 'charcoal-technical-travel-backpacks-prd-501a3', 'Charcoal Technical Travel Backpacks', 'StyleMart', 'backpacks', 'technical-travel', 'Charcoal technical travel backpack in ripstop. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 19499, 'USD', 'assets/img/backpack_charcoal_technical-travel_ripstop_02.png', '{"material":"ripstop"}', '["commute","travel","work"]', 4.80, 4),
  ('prd_01HZX1494D48D', 'olive-daypack-backpacks-prd-4d48d', 'Olive Daypack Backpacks', 'StyleMart', 'backpacks', 'daypack', 'Olive daypack backpack in waxed canvas. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 21449, 'USD', 'assets/img/backpack_olive_daypack_waxed-canvas_03.png', '{"material":"waxed canvas"}', '["commute","travel","work"]', 4.30, 3),
  ('prd_01HZX1505B8A8', 'navy-roll-top-backpacks-prd-5b8a8', 'Navy Roll Top Backpacks', 'StyleMart', 'backpacks', 'roll-top', 'Navy roll top backpack in technical mesh and nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 10599, 'USD', 'assets/img/backpack_navy_roll-top_technical-mesh-and-nylon_04.png', '{"material":"technical mesh and nylon"}', '["commute","travel","work"]', 4.80, 4);

INSERT INTO products (product_id, slug, name, brand, category, subcategory, description, care_instructions, base_price_cents, currency, image_url, attributes, occasion_tags, average_rating, review_count) VALUES
  ('prd_01HZX151036EE', 'sand-minimalist-commuter-backpacks-prd-036ee', 'Sand Minimalist Commuter Backpacks', 'StyleMart', 'backpacks', 'minimalist-commuter', 'Sand minimalist commuter backpack in recycled nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 14699, 'USD', 'assets/img/backpack_sand_minimalist-commuter_recycled-nylon_05.png', '{"material":"recycled nylon"}', '["commute","travel","work"]', 5.00, 3),
  ('prd_01HZX152E9B46', 'slate-technical-travel-backpacks-prd-e9b46', 'Slate Technical Travel Backpacks', 'StyleMart', 'backpacks', 'technical-travel', 'Slate technical travel backpack in ripstop. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 13649, 'USD', 'assets/img/backpack_slate_technical-travel_ripstop_06.png', '{"material":"ripstop"}', '["commute","travel","work"]', 3.50, 2),
  ('prd_01HZX1537264B', 'forest-green-daypack-backpacks-prd-7264b', 'Forest Green Daypack Backpacks', 'StyleMart', 'backpacks', 'daypack', 'Forest Green daypack backpack in recycled nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 17349, 'USD', 'assets/img/backpack_forest-green_daypack_recycled-nylon_07.png', '{"material":"recycled nylon"}', '["commute","travel","work"]', 5.00, 2),
  ('prd_01HZX154A2535', 'tan-minimalist-commuter-backpacks-prd-a2535', 'Tan Minimalist Commuter Backpacks', 'StyleMart', 'backpacks', 'minimalist-commuter', 'Tan minimalist commuter backpack in waxed canvas. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 9599, 'USD', 'assets/img/backpack_tan_minimalist-commuter_waxed-canvas_08.png', '{"material":"waxed canvas"}', '["commute","travel","work"]', 5.00, 2),
  ('prd_01HZX15535D86', 'graphite-roll-top-backpacks-prd-35d86', 'Graphite Roll Top Backpacks', 'StyleMart', 'backpacks', 'roll-top', 'Graphite roll top backpack in ripstop. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 16249, 'USD', 'assets/img/backpack_graphite_roll-top_ripstop_09.png', '{"material":"ripstop"}', '["commute","travel","work"]', 5.00, 3),
  ('prd_01HZX156A0986', 'burgundy-daypack-backpacks-prd-a0986', 'Burgundy Daypack Backpacks', 'StyleMart', 'backpacks', 'daypack', 'Burgundy daypack backpack in recycled nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 17349, 'USD', 'assets/img/backpack_burgundy_daypack_recycled-nylon_10.png', '{"material":"recycled nylon"}', '["commute","travel","work"]', 4.30, 3),
  ('prd_01HZX15734629', 'stone-technical-travel-backpacks-prd-34629', 'Stone Technical Travel Backpacks', 'StyleMart', 'backpacks', 'technical-travel', 'Stone technical travel backpack in technical mesh and nylon. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 19449, 'USD', 'assets/img/backpack_stone_technical-travel_technical-mesh-and-nylon_11.png', '{"material":"technical mesh and nylon"}', '["commute","travel","work"]', 4.20, 4),
  ('prd_01HZX158EC477', 'steel-blue-roll-top-backpacks-prd-ec477', 'Steel Blue Roll Top Backpacks', 'StyleMart', 'backpacks', 'roll-top', 'Steel Blue roll top backpack in ripstop. Padded laptop sleeve and a structured silhouette.', 'Spot clean with mild detergent.', 21699, 'USD', 'assets/img/backpack_steel-blue_roll-top_ripstop_14.png', '{"material":"ripstop"}', '["commute","travel","work"]', 4.50, 4),
  ('prd_01HZX15904744', 'tortoise-rectangular-sunglasses-prd-04744', 'Tortoise Rectangular Sunglasses', 'StyleMart', 'sunglasses', 'rectangular', 'Tortoise rectangular sunglasses with gradient brown lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 19199, 'USD', 'assets/img/sunglasses_tortoise_rectangular_gradient-brown_01.png', '{"lens":"gradient brown"}', '["summer","travel","outdoors"]', 4.70, 3),
  ('prd_01HZX160B757F', 'matte-black-round-sunglasses-prd-b757f', 'Matte Black Round Sunglasses', 'StyleMart', 'sunglasses', 'round', 'Matte Black round sunglasses with smoke gray lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 11449, 'USD', 'assets/img/sunglasses_matte-black_round_smoke-gray_02.png', '{"lens":"smoke gray"}', '["summer","travel","outdoors"]', 5.00, 3),
  ('prd_01HZX161A7F7D', 'gunmetal-aviator-sunglasses-prd-a7f7d', 'Gunmetal Aviator Sunglasses', 'StyleMart', 'sunglasses', 'aviator', 'Gunmetal aviator sunglasses with polarized green lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 19599, 'USD', 'assets/img/sunglasses_gunmetal_aviator_polarized-green_03.png', '{"lens":"polarized green"}', '["summer","travel","outdoors"]', 4.80, 4),
  ('prd_01HZX162BE15C', 'clear-wayfarer-sunglasses-prd-be15c', 'Clear Wayfarer Sunglasses', 'StyleMart', 'sunglasses', 'wayfarer', 'Clear wayfarer sunglasses with mirrored silver lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 17999, 'USD', 'assets/img/sunglasses_clear_wayfarer_mirrored-silver_04.png', '{"lens":"mirrored silver"}', '["summer","travel","outdoors"]', 4.30, 3),
  ('prd_01HZX16343326', 'brown-oversized-square-sunglasses-prd-43326', 'Brown Oversized Square Sunglasses', 'StyleMart', 'sunglasses', 'oversized-square', 'Brown oversized square sunglasses with gradient brown lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 15599, 'USD', 'assets/img/sunglasses_brown_oversized-square_gradient-brown_05.png', '{"lens":"gradient brown"}', '["summer","travel","outdoors"]', 5.00, 2),
  ('prd_01HZX16429B41', 'matte-black-rimless-sunglasses-prd-29b41', 'Matte Black Rimless Sunglasses', 'StyleMart', 'sunglasses', 'rimless', 'Matte Black rimless sunglasses with smoke gray lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 17499, 'USD', 'assets/img/sunglasses_matte-black_rimless_smoke-gray_06.png', '{"lens":"smoke gray"}', '["summer","travel","outdoors"]', 4.50, 2),
  ('prd_01HZX16529DDC', 'tortoise-round-sunglasses-prd-29ddc', 'Tortoise Round Sunglasses', 'StyleMart', 'sunglasses', 'round', 'Tortoise round sunglasses with polarized green lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 15299, 'USD', 'assets/img/sunglasses_tortoise_round_polarized-green_07.png', '{"lens":"polarized green"}', '["summer","travel","outdoors"]', 4.50, 2),
  ('prd_01HZX1662C0FF', 'gunmetal-rectangular-sunglasses-prd-2c0ff', 'Gunmetal Rectangular Sunglasses', 'StyleMart', 'sunglasses', 'rectangular', 'Gunmetal rectangular sunglasses with mirrored silver lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 14549, 'USD', 'assets/img/sunglasses_gunmetal_rectangular_mirrored-silver_08.png', '{"lens":"mirrored silver"}', '["summer","travel","outdoors"]', 4.30, 3),
  ('prd_01HZX16737A05', 'charcoal-wayfarer-sunglasses-prd-37a05', 'Charcoal Wayfarer Sunglasses', 'StyleMart', 'sunglasses', 'wayfarer', 'Charcoal wayfarer sunglasses with smoke gray lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 15999, 'USD', 'assets/img/sunglasses_charcoal_wayfarer_smoke-gray_09.png', '{"lens":"smoke gray"}', '["summer","travel","outdoors"]', 4.00, 3),
  ('prd_01HZX16874C2F', 'amber-aviator-sunglasses-prd-74c2f', 'Amber Aviator Sunglasses', 'StyleMart', 'sunglasses', 'aviator', 'Amber aviator sunglasses with gradient brown lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 12449, 'USD', 'assets/img/sunglasses_amber_aviator_gradient-brown_10.png', '{"lens":"gradient brown"}', '["summer","travel","outdoors"]', 4.50, 4),
  ('prd_01HZX169EF961', 'navy-oversized-square-sunglasses-prd-ef961', 'Navy Oversized Square Sunglasses', 'StyleMart', 'sunglasses', 'oversized-square', 'Navy oversized square sunglasses with polarized green lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 16999, 'USD', 'assets/img/sunglasses_navy_oversized-square_polarized-green_11.png', '{"lens":"polarized green"}', '["summer","travel","outdoors"]', 5.00, 3),
  ('prd_01HZX170BD98F', 'silver-rimless-sunglasses-prd-bd98f', 'Silver Rimless Sunglasses', 'StyleMart', 'sunglasses', 'rimless', 'Silver rimless sunglasses with mirrored silver lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 18099, 'USD', 'assets/img/sunglasses_silver_rimless_mirrored-silver_12.png', '{"lens":"mirrored silver"}', '["summer","travel","outdoors"]', 4.00, 2),
  ('prd_01HZX171249AB', 'olive-rectangular-sunglasses-prd-249ab', 'Olive Rectangular Sunglasses', 'StyleMart', 'sunglasses', 'rectangular', 'Olive rectangular sunglasses with smoke gray lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 19649, 'USD', 'assets/img/sunglasses_olive_rectangular_smoke-gray_13.png', '{"lens":"smoke gray"}', '["summer","travel","outdoors"]', 4.00, 3),
  ('prd_01HZX172FFE1D', 'cream-round-sunglasses-prd-ffe1d', 'Cream Round Sunglasses', 'StyleMart', 'sunglasses', 'round', 'Cream round sunglasses with gradient brown lenses in an acetate frame.', 'Wipe lenses with the supplied microfiber.', 11849, 'USD', 'assets/img/sunglasses_cream_round_gradient-brown_14.png', '{"lens":"gradient brown"}', '["summer","travel","outdoors"]', 5.00, 3),
  ('prd_01HZX173F4F9D', 'navy-beanie-accessories-prd-f4f9d', 'Navy Beanie Accessories', 'StyleMart', 'accessories', 'beanie', 'Navy midweight beanie in recycled wool. Ribbed cuff and a soft hand.', 'Spot clean; refer to product label.', 4349, 'USD', 'assets/img/winter_navy_beanie_recycled-wool_04.png', '{"fabric":"recycled wool"}', '["travel","everyday"]', 4.50, 2),
  ('prd_01HZX174678B4', 'camel-scarf-accessories-prd-678b4', 'Camel Scarf Accessories', 'StyleMart', 'accessories', 'scarf', 'Camel chunky scarf in brushed alpaca. Cable knit with a finished edge.', 'Spot clean; refer to product label.', 6649, 'USD', 'assets/img/winter_camel_scarf_brushed-alpaca_05.png', '{"fabric":"brushed alpaca"}', '["travel","everyday"]', 5.00, 2),
  ('prd_01HZX1758E7B8', 'black-beanie-accessories-prd-8e7b8', 'Black Beanie Accessories', 'StyleMart', 'accessories', 'beanie', 'Black midweight beanie in recycled wool. Ribbed cuff and a soft hand.', 'Spot clean; refer to product label.', 3299, 'USD', 'assets/img/winter_black_beanie_recycled-wool_09.png', '{"fabric":"recycled wool"}', '["travel","everyday"]', 4.00, 4),
  ('prd_01HZX176B4C3D', 'deep-teal-scarf-accessories-prd-b4c3d', 'Deep Teal Scarf Accessories', 'StyleMart', 'accessories', 'scarf', 'Deep Teal chunky scarf in merino wool. Cable knit with a finished edge.', 'Spot clean; refer to product label.', 5299, 'USD', 'assets/img/winter_deep-teal_scarf_merino-wool_10.png', '{"fabric":"merino wool"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX1773E1F6', 'olive-beanie-accessories-prd-3e1f6', 'Olive Beanie Accessories', 'StyleMart', 'accessories', 'beanie', 'Olive midweight beanie in cashmere blend. Ribbed cuff and a soft hand.', 'Spot clean; refer to product label.', 4399, 'USD', 'assets/img/winter_olive_beanie_cashmere-blend_14.png', '{"fabric":"cashmere blend"}', '["travel","everyday"]', 4.50, 2),
  ('prd_01HZX1788C252', 'wine-scarf-accessories-prd-8c252', 'Wine Scarf Accessories', 'StyleMart', 'accessories', 'scarf', 'Wine chunky scarf in recycled wool. Cable knit with a finished edge.', 'Spot clean; refer to product label.', 6449, 'USD', 'assets/img/winter_wine_scarf_recycled-wool_15.png', '{"fabric":"recycled wool"}', '["travel","everyday"]', 4.00, 2),
  ('prd_01HZX1796A629', 'espresso-beanie-accessories-prd-6a629', 'Espresso Beanie Accessories', 'StyleMart', 'accessories', 'beanie', 'Espresso midweight beanie in merino wool. Ribbed cuff and a soft hand.', 'Spot clean; refer to product label.', 4299, 'USD', 'assets/img/winter_espresso_beanie_merino-wool_19.png', '{"fabric":"merino wool"}', '["travel","everyday"]', 5.00, 3),
  ('prd_01HZX18042163', 'sage-scarf-accessories-prd-42163', 'Sage Scarf Accessories', 'StyleMart', 'accessories', 'scarf', 'Sage chunky scarf in cashmere blend. Cable knit with a finished edge.', 'Spot clean; refer to product label.', 4249, 'USD', 'assets/img/winter_sage_scarf_cashmere-blend_20.png', '{"fabric":"cashmere blend"}', '["travel","everyday"]', 4.00, 4),
  ('prd_01HZX181D0B37', 'black-umbrella-accessories-prd-d0b37', 'Black Umbrella Accessories', 'StyleMart', 'accessories', 'umbrella', 'Black compact travel umbrella. Auto open-close mechanism and a ripstop canopy.', 'Spot clean; refer to product label.', 5049, 'USD', 'assets/img/travel_compact_black_ripstop-nylon_01.png', '{"material":"ripstop nylon"}', '["travel","everyday"]', 4.50, 2),
  ('prd_01HZX1828E989', 'charcoal-packing-cubes-accessories-prd-8e989', 'Charcoal Packing Cubes Accessories', 'StyleMart', 'accessories', 'packing-cubes', 'Charcoal set of three packing cubes. Ripstop fabric and webbing handles.', 'Spot clean; refer to product label.', 7049, 'USD', 'assets/img/travel_set_charcoal_recycled-polyester_02.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.30, 3),
  ('prd_01HZX183622D3', 'olive-socks-accessories-prd-622d3', 'Olive Socks Accessories', 'StyleMart', 'accessories', 'socks', 'Olive merino travel socks. Reinforced heel and cushioned sole.', 'Spot clean; refer to product label.', 2799, 'USD', 'assets/img/travel_merino_olive_merino-wool_03.png', '{"material":"merino wool"}', '["travel","everyday"]', 4.30, 3),
  ('prd_01HZX184DA162', 'navy-wallet-accessories-prd-da162', 'Navy Wallet Accessories', 'StyleMart', 'accessories', 'wallet', 'Navy card wallet in full-grain leather. Five card slots and a thumb cut-out.', 'Spot clean; refer to product label.', 11849, 'USD', 'assets/img/travel_leather_navy_full-grain-leather_04.png', '{"material":"full grain leather"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX185DBA6D', 'sand-towel-accessories-prd-dba6d', 'Sand Towel Accessories', 'StyleMart', 'accessories', 'towel', 'Sand microfiber travel towel. Quick-dry and ultra-packable.', 'Spot clean; refer to product label.', 3099, 'USD', 'assets/img/travel_microfiber_sand_microfiber_05.png', '{"material":"microfiber"}', '["travel","everyday"]', 4.50, 2),
  ('prd_01HZX18690CD3', 'slate-cable-organizer-accessories-prd-90cd3', 'Slate Cable Organizer Accessories', 'StyleMart', 'accessories', 'cable-organizer', 'Slate travel cable organizer pouch. Elastic loops and a YKK zipper.', 'Spot clean; refer to product label.', 4249, 'USD', 'assets/img/travel_travel_slate_recycled-polyester_06.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.50, 4),
  ('prd_01HZX187CDE05', 'forest-green-umbrella-accessories-prd-cde05', 'Forest Green Umbrella Accessories', 'StyleMart', 'accessories', 'umbrella', 'Forest Green compact travel umbrella. Auto open-close mechanism and a ripstop canopy.', 'Spot clean; refer to product label.', 4149, 'USD', 'assets/img/travel_compact_forest-green_ripstop-nylon_07.png', '{"material":"ripstop nylon"}', '["travel","everyday"]', 4.30, 3),
  ('prd_01HZX18843E1A', 'tan-packing-cubes-accessories-prd-43e1a', 'Tan Packing Cubes Accessories', 'StyleMart', 'accessories', 'packing-cubes', 'Tan set of three packing cubes. Ripstop fabric and webbing handles.', 'Spot clean; refer to product label.', 7499, 'USD', 'assets/img/travel_set_tan_recycled-polyester_08.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX1894C92B', 'graphite-socks-accessories-prd-4c92b', 'Graphite Socks Accessories', 'StyleMart', 'accessories', 'socks', 'Graphite merino travel socks. Reinforced heel and cushioned sole.', 'Spot clean; refer to product label.', 1549, 'USD', 'assets/img/travel_merino_graphite_merino-wool_09.png', '{"material":"merino wool"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX19085328', 'burgundy-wallet-accessories-prd-85328', 'Burgundy Wallet Accessories', 'StyleMart', 'accessories', 'wallet', 'Burgundy card wallet in full-grain leather. Five card slots and a thumb cut-out.', 'Spot clean; refer to product label.', 8799, 'USD', 'assets/img/travel_leather_burgundy_full-grain-leather_10.png', '{"material":"full grain leather"}', '["travel","everyday"]', 4.80, 4),
  ('prd_01HZX191E8813', 'stone-towel-accessories-prd-e8813', 'Stone Towel Accessories', 'StyleMart', 'accessories', 'towel', 'Stone microfiber travel towel. Quick-dry and ultra-packable.', 'Spot clean; refer to product label.', 2849, 'USD', 'assets/img/travel_microfiber_stone_microfiber_11.png', '{"material":"microfiber"}', '["travel","everyday"]', 4.30, 3),
  ('prd_01HZX192C159C', 'midnight-blue-cable-organizer-accessories-prd-c159c', 'Midnight Blue Cable Organizer Accessories', 'StyleMart', 'accessories', 'cable-organizer', 'Midnight Blue travel cable organizer pouch. Elastic loops and a YKK zipper.', 'Spot clean; refer to product label.', 2699, 'USD', 'assets/img/travel_travel_midnight-blue_recycled-polyester_12.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX193C9A38', 'camel-umbrella-accessories-prd-c9a38', 'Camel Umbrella Accessories', 'StyleMart', 'accessories', 'umbrella', 'Camel compact travel umbrella. Auto open-close mechanism and a ripstop canopy.', 'Spot clean; refer to product label.', 5449, 'USD', 'assets/img/travel_compact_camel_ripstop-nylon_13.png', '{"material":"ripstop nylon"}', '["travel","everyday"]', 4.00, 2),
  ('prd_01HZX19465179', 'steel-blue-packing-cubes-accessories-prd-65179', 'Steel Blue Packing Cubes Accessories', 'StyleMart', 'accessories', 'packing-cubes', 'Steel Blue set of three packing cubes. Ripstop fabric and webbing handles.', 'Spot clean; refer to product label.', 6299, 'USD', 'assets/img/travel_set_steel-blue_recycled-polyester_14.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.80, 4),
  ('prd_01HZX195A9CC5', 'espresso-socks-accessories-prd-a9cc5', 'Espresso Socks Accessories', 'StyleMart', 'accessories', 'socks', 'Espresso merino travel socks. Reinforced heel and cushioned sole.', 'Spot clean; refer to product label.', 2699, 'USD', 'assets/img/travel_merino_espresso_merino-wool_15.png', '{"material":"merino wool"}', '["travel","everyday"]', 5.00, 3),
  ('prd_01HZX1968B4BC', 'sage-wallet-accessories-prd-8b4bc', 'Sage Wallet Accessories', 'StyleMart', 'accessories', 'wallet', 'Sage card wallet in full-grain leather. Five card slots and a thumb cut-out.', 'Spot clean; refer to product label.', 7949, 'USD', 'assets/img/travel_leather_sage_full-grain-leather_16.png', '{"material":"full grain leather"}', '["travel","everyday"]', 4.80, 4),
  ('prd_01HZX1978AC07', 'pewter-towel-accessories-prd-8ac07', 'Pewter Towel Accessories', 'StyleMart', 'accessories', 'towel', 'Pewter microfiber travel towel. Quick-dry and ultra-packable.', 'Spot clean; refer to product label.', 3649, 'USD', 'assets/img/travel_microfiber_pewter_microfiber_17.png', '{"material":"microfiber"}', '["travel","everyday"]', 4.70, 3),
  ('prd_01HZX1989AE7B', 'rust-cable-organizer-accessories-prd-9ae7b', 'Rust Cable Organizer Accessories', 'StyleMart', 'accessories', 'cable-organizer', 'Rust travel cable organizer pouch. Elastic loops and a YKK zipper.', 'Spot clean; refer to product label.', 2649, 'USD', 'assets/img/travel_travel_rust_recycled-polyester_18.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.50, 2),
  ('prd_01HZX199AFA79', 'ivory-umbrella-accessories-prd-afa79', 'Ivory Umbrella Accessories', 'StyleMart', 'accessories', 'umbrella', 'Ivory compact travel umbrella. Auto open-close mechanism and a ripstop canopy.', 'Spot clean; refer to product label.', 4899, 'USD', 'assets/img/travel_compact_ivory_ripstop-nylon_19.png', '{"material":"ripstop nylon"}', '["travel","everyday"]', 5.00, 2),
  ('prd_01HZX200DFBE7', 'teal-packing-cubes-accessories-prd-dfbe7', 'Teal Packing Cubes Accessories', 'StyleMart', 'accessories', 'packing-cubes', 'Teal set of three packing cubes. Ripstop fabric and webbing handles.', 'Spot clean; refer to product label.', 6249, 'USD', 'assets/img/travel_set_teal_recycled-polyester_20.png', '{"material":"recycled polyester"}', '["travel","everyday"]', 4.50, 2);


-- ============================================================================
-- seed/05_seed_product_variants.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 05 - Product variants (1016 rows)
-- Target table: product_variants
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM product_variants;

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX001B79A0_XS_cream_B30849', 'prd_01HZX001B79A0', 'XS', 'cream', 'SM-TSH-CRE-XS'),
  ('var_01HZX001B79A0_S_cream_4A300C', 'prd_01HZX001B79A0', 'S', 'cream', 'SM-TSH-CRE-S'),
  ('var_01HZX001B79A0_M_cream_B3ABCA', 'prd_01HZX001B79A0', 'M', 'cream', 'SM-TSH-CRE-M'),
  ('var_01HZX001B79A0_L_cream_26CD7A', 'prd_01HZX001B79A0', 'L', 'cream', 'SM-TSH-CRE-L'),
  ('var_01HZX001B79A0_XL_cream_68A166', 'prd_01HZX001B79A0', 'XL', 'cream', 'SM-TSH-CRE-XL'),
  ('var_01HZX002DC84B_XS_white_6BF790', 'prd_01HZX002DC84B', 'XS', 'white', 'SM-TSH-WHI-XS'),
  ('var_01HZX002DC84B_S_white_B5135F', 'prd_01HZX002DC84B', 'S', 'white', 'SM-TSH-WHI-S'),
  ('var_01HZX002DC84B_M_white_4CED6F', 'prd_01HZX002DC84B', 'M', 'white', 'SM-TSH-WHI-M'),
  ('var_01HZX002DC84B_L_white_41775A', 'prd_01HZX002DC84B', 'L', 'white', 'SM-TSH-WHI-L'),
  ('var_01HZX002DC84B_XL_white_068212', 'prd_01HZX002DC84B', 'XL', 'white', 'SM-TSH-WHI-XL'),
  ('var_01HZX003C4E7A_XS_offwhite_248048', 'prd_01HZX003C4E7A', 'XS', 'off white', 'SM-TSH-OFF-XS'),
  ('var_01HZX003C4E7A_S_offwhite_D39897', 'prd_01HZX003C4E7A', 'S', 'off white', 'SM-TSH-OFF-S'),
  ('var_01HZX003C4E7A_M_offwhite_094A39', 'prd_01HZX003C4E7A', 'M', 'off white', 'SM-TSH-OFF-M'),
  ('var_01HZX003C4E7A_L_offwhite_C74F6B', 'prd_01HZX003C4E7A', 'L', 'off white', 'SM-TSH-OFF-L'),
  ('var_01HZX003C4E7A_XL_offwhite_297838', 'prd_01HZX003C4E7A', 'XL', 'off white', 'SM-TSH-OFF-XL'),
  ('var_01HZX00469D94_XS_sagegreen_2DF82F', 'prd_01HZX00469D94', 'XS', 'sage green', 'SM-TSH-SAG-XS'),
  ('var_01HZX00469D94_S_sagegreen_5AE7C8', 'prd_01HZX00469D94', 'S', 'sage green', 'SM-TSH-SAG-S'),
  ('var_01HZX00469D94_M_sagegreen_885059', 'prd_01HZX00469D94', 'M', 'sage green', 'SM-TSH-SAG-M'),
  ('var_01HZX00469D94_L_sagegreen_21F481', 'prd_01HZX00469D94', 'L', 'sage green', 'SM-TSH-SAG-L'),
  ('var_01HZX00469D94_XL_sagegreen_B385E4', 'prd_01HZX00469D94', 'XL', 'sage green', 'SM-TSH-SAG-XL'),
  ('var_01HZX005E0B47_XS_dustyrose_AF9EB2', 'prd_01HZX005E0B47', 'XS', 'dusty rose', 'SM-TSH-DUS-XS'),
  ('var_01HZX005E0B47_S_dustyrose_66E763', 'prd_01HZX005E0B47', 'S', 'dusty rose', 'SM-TSH-DUS-S'),
  ('var_01HZX005E0B47_M_dustyrose_EB2EEC', 'prd_01HZX005E0B47', 'M', 'dusty rose', 'SM-TSH-DUS-M'),
  ('var_01HZX005E0B47_L_dustyrose_3129BE', 'prd_01HZX005E0B47', 'L', 'dusty rose', 'SM-TSH-DUS-L'),
  ('var_01HZX005E0B47_XL_dustyrose_C53120', 'prd_01HZX005E0B47', 'XL', 'dusty rose', 'SM-TSH-DUS-XL'),
  ('var_01HZX006E013F_XS_navy_A2E5A4', 'prd_01HZX006E013F', 'XS', 'navy', 'SM-TSH-NAV-XS'),
  ('var_01HZX006E013F_S_navy_D6A210', 'prd_01HZX006E013F', 'S', 'navy', 'SM-TSH-NAV-S'),
  ('var_01HZX006E013F_M_navy_53E636', 'prd_01HZX006E013F', 'M', 'navy', 'SM-TSH-NAV-M'),
  ('var_01HZX006E013F_L_navy_C22BE6', 'prd_01HZX006E013F', 'L', 'navy', 'SM-TSH-NAV-L'),
  ('var_01HZX006E013F_XL_navy_CB4331', 'prd_01HZX006E013F', 'XL', 'navy', 'SM-TSH-NAV-XL'),
  ('var_01HZX007467E4_XS_charcoal_82A648', 'prd_01HZX007467E4', 'XS', 'charcoal', 'SM-TSH-CHA-XS'),
  ('var_01HZX007467E4_S_charcoal_3215E0', 'prd_01HZX007467E4', 'S', 'charcoal', 'SM-TSH-CHA-S'),
  ('var_01HZX007467E4_M_charcoal_D24684', 'prd_01HZX007467E4', 'M', 'charcoal', 'SM-TSH-CHA-M'),
  ('var_01HZX007467E4_L_charcoal_F4B7A5', 'prd_01HZX007467E4', 'L', 'charcoal', 'SM-TSH-CHA-L'),
  ('var_01HZX007467E4_XL_charcoal_CC1597', 'prd_01HZX007467E4', 'XL', 'charcoal', 'SM-TSH-CHA-XL'),
  ('var_01HZX00824F04_XS_ivory_DA28CA', 'prd_01HZX00824F04', 'XS', 'ivory', 'SM-TSH-IVO-XS'),
  ('var_01HZX00824F04_S_ivory_7951EA', 'prd_01HZX00824F04', 'S', 'ivory', 'SM-TSH-IVO-S'),
  ('var_01HZX00824F04_M_ivory_57A67B', 'prd_01HZX00824F04', 'M', 'ivory', 'SM-TSH-IVO-M'),
  ('var_01HZX00824F04_L_ivory_5E7287', 'prd_01HZX00824F04', 'L', 'ivory', 'SM-TSH-IVO-L'),
  ('var_01HZX00824F04_XL_ivory_7B5A9F', 'prd_01HZX00824F04', 'XL', 'ivory', 'SM-TSH-IVO-XL'),
  ('var_01HZX0092B381_XS_terracotta_AAD41B', 'prd_01HZX0092B381', 'XS', 'terracotta', 'SM-TSH-TER-XS'),
  ('var_01HZX0092B381_S_terracotta_48C4EC', 'prd_01HZX0092B381', 'S', 'terracotta', 'SM-TSH-TER-S'),
  ('var_01HZX0092B381_M_terracotta_5A0E89', 'prd_01HZX0092B381', 'M', 'terracotta', 'SM-TSH-TER-M'),
  ('var_01HZX0092B381_L_terracotta_052402', 'prd_01HZX0092B381', 'L', 'terracotta', 'SM-TSH-TER-L'),
  ('var_01HZX0092B381_XL_terracotta_50E69B', 'prd_01HZX0092B381', 'XL', 'terracotta', 'SM-TSH-TER-XL'),
  ('var_01HZX010C1DC3_XS_olive_4E50B3', 'prd_01HZX010C1DC3', 'XS', 'olive', 'SM-TSH-OLI-XS'),
  ('var_01HZX010C1DC3_S_olive_9B180A', 'prd_01HZX010C1DC3', 'S', 'olive', 'SM-TSH-OLI-S'),
  ('var_01HZX010C1DC3_M_olive_B2D0E5', 'prd_01HZX010C1DC3', 'M', 'olive', 'SM-TSH-OLI-M'),
  ('var_01HZX010C1DC3_L_olive_B75701', 'prd_01HZX010C1DC3', 'L', 'olive', 'SM-TSH-OLI-L'),
  ('var_01HZX010C1DC3_XL_olive_154866', 'prd_01HZX010C1DC3', 'XL', 'olive', 'SM-TSH-OLI-XL'),
  ('var_01HZX01118584_XS_slateblue_C31446', 'prd_01HZX01118584', 'XS', 'slate blue', 'SM-TSH-SLA-XS'),
  ('var_01HZX01118584_S_slateblue_14A721', 'prd_01HZX01118584', 'S', 'slate blue', 'SM-TSH-SLA-S'),
  ('var_01HZX01118584_M_slateblue_D85F6F', 'prd_01HZX01118584', 'M', 'slate blue', 'SM-TSH-SLA-M'),
  ('var_01HZX01118584_L_slateblue_A98A3F', 'prd_01HZX01118584', 'L', 'slate blue', 'SM-TSH-SLA-L'),
  ('var_01HZX01118584_XL_slateblue_107CE1', 'prd_01HZX01118584', 'XL', 'slate blue', 'SM-TSH-SLA-XL'),
  ('var_01HZX0126D23C_XS_burgundy_530AC8', 'prd_01HZX0126D23C', 'XS', 'burgundy', 'SM-TSH-BUR-XS'),
  ('var_01HZX0126D23C_S_burgundy_6A69BD', 'prd_01HZX0126D23C', 'S', 'burgundy', 'SM-TSH-BUR-S'),
  ('var_01HZX0126D23C_M_burgundy_333DCE', 'prd_01HZX0126D23C', 'M', 'burgundy', 'SM-TSH-BUR-M'),
  ('var_01HZX0126D23C_L_burgundy_AFC67B', 'prd_01HZX0126D23C', 'L', 'burgundy', 'SM-TSH-BUR-L'),
  ('var_01HZX0126D23C_XL_burgundy_26AF37', 'prd_01HZX0126D23C', 'XL', 'burgundy', 'SM-TSH-BUR-XL'),
  ('var_01HZX013AB385_XS_white_9F9A61', 'prd_01HZX013AB385', 'XS', 'white', 'SM-TSH-WHI-XS'),
  ('var_01HZX013AB385_S_white_59FF9A', 'prd_01HZX013AB385', 'S', 'white', 'SM-TSH-WHI-S'),
  ('var_01HZX013AB385_M_white_7E152E', 'prd_01HZX013AB385', 'M', 'white', 'SM-TSH-WHI-M'),
  ('var_01HZX013AB385_L_white_1C9F9A', 'prd_01HZX013AB385', 'L', 'white', 'SM-TSH-WHI-L'),
  ('var_01HZX013AB385_XL_white_FFE9AE', 'prd_01HZX013AB385', 'XL', 'white', 'SM-TSH-WHI-XL'),
  ('var_01HZX0142D7F7_XS_black_6A13F9', 'prd_01HZX0142D7F7', 'XS', 'black', 'SM-TSH-BLA-XS'),
  ('var_01HZX0142D7F7_S_black_10D74F', 'prd_01HZX0142D7F7', 'S', 'black', 'SM-TSH-BLA-S'),
  ('var_01HZX0142D7F7_M_black_E50A00', 'prd_01HZX0142D7F7', 'M', 'black', 'SM-TSH-BLA-M'),
  ('var_01HZX0142D7F7_L_black_639B0B', 'prd_01HZX0142D7F7', 'L', 'black', 'SM-TSH-BLA-L'),
  ('var_01HZX0142D7F7_XL_black_8EA12F', 'prd_01HZX0142D7F7', 'XL', 'black', 'SM-TSH-BLA-XL'),
  ('var_01HZX0154D2D3_XS_lightgray_72D638', 'prd_01HZX0154D2D3', 'XS', 'light gray', 'SM-TSH-LIG-XS'),
  ('var_01HZX0154D2D3_S_lightgray_42DB5A', 'prd_01HZX0154D2D3', 'S', 'light gray', 'SM-TSH-LIG-S'),
  ('var_01HZX0154D2D3_M_lightgray_992B2B', 'prd_01HZX0154D2D3', 'M', 'light gray', 'SM-TSH-LIG-M'),
  ('var_01HZX0154D2D3_L_lightgray_4BF50D', 'prd_01HZX0154D2D3', 'L', 'light gray', 'SM-TSH-LIG-L'),
  ('var_01HZX0154D2D3_XL_lightgray_97B129', 'prd_01HZX0154D2D3', 'XL', 'light gray', 'SM-TSH-LIG-XL'),
  ('var_01HZX0161A9D0_XS_skyblue_139FCA', 'prd_01HZX0161A9D0', 'XS', 'sky blue', 'SM-TSH-SKY-XS'),
  ('var_01HZX0161A9D0_S_skyblue_958205', 'prd_01HZX0161A9D0', 'S', 'sky blue', 'SM-TSH-SKY-S'),
  ('var_01HZX0161A9D0_M_skyblue_0F988E', 'prd_01HZX0161A9D0', 'M', 'sky blue', 'SM-TSH-SKY-M'),
  ('var_01HZX0161A9D0_L_skyblue_4648CF', 'prd_01HZX0161A9D0', 'L', 'sky blue', 'SM-TSH-SKY-L'),
  ('var_01HZX0161A9D0_XL_skyblue_93E02B', 'prd_01HZX0161A9D0', 'XL', 'sky blue', 'SM-TSH-SKY-XL'),
  ('var_01HZX01710C1A_XS_mustard_68522E', 'prd_01HZX01710C1A', 'XS', 'mustard', 'SM-TSH-MUS-XS'),
  ('var_01HZX01710C1A_S_mustard_A6F720', 'prd_01HZX01710C1A', 'S', 'mustard', 'SM-TSH-MUS-S'),
  ('var_01HZX01710C1A_M_mustard_D75D24', 'prd_01HZX01710C1A', 'M', 'mustard', 'SM-TSH-MUS-M'),
  ('var_01HZX01710C1A_L_mustard_E27841', 'prd_01HZX01710C1A', 'L', 'mustard', 'SM-TSH-MUS-L'),
  ('var_01HZX01710C1A_XL_mustard_6ADC5D', 'prd_01HZX01710C1A', 'XL', 'mustard', 'SM-TSH-MUS-XL'),
  ('var_01HZX01855961_XS_forestgreen_ED1B84', 'prd_01HZX01855961', 'XS', 'forest green', 'SM-TSH-FOR-XS'),
  ('var_01HZX01855961_S_forestgreen_E0A0AA', 'prd_01HZX01855961', 'S', 'forest green', 'SM-TSH-FOR-S'),
  ('var_01HZX01855961_M_forestgreen_0D122D', 'prd_01HZX01855961', 'M', 'forest green', 'SM-TSH-FOR-M'),
  ('var_01HZX01855961_L_forestgreen_BB78A7', 'prd_01HZX01855961', 'L', 'forest green', 'SM-TSH-FOR-L'),
  ('var_01HZX01855961_XL_forestgreen_72F7B2', 'prd_01HZX01855961', 'XL', 'forest green', 'SM-TSH-FOR-XL'),
  ('var_01HZX019AA2CD_XS_white_40B5D4', 'prd_01HZX019AA2CD', 'XS', 'white', 'SM-SHI-WHI-XS'),
  ('var_01HZX019AA2CD_S_white_38D1FE', 'prd_01HZX019AA2CD', 'S', 'white', 'SM-SHI-WHI-S'),
  ('var_01HZX019AA2CD_M_white_E075E2', 'prd_01HZX019AA2CD', 'M', 'white', 'SM-SHI-WHI-M'),
  ('var_01HZX019AA2CD_L_white_C18CA0', 'prd_01HZX019AA2CD', 'L', 'white', 'SM-SHI-WHI-L'),
  ('var_01HZX019AA2CD_XL_white_1CAEBE', 'prd_01HZX019AA2CD', 'XL', 'white', 'SM-SHI-WHI-XL'),
  ('var_01HZX020F074E_XS_skyblue_38408C', 'prd_01HZX020F074E', 'XS', 'sky blue', 'SM-SHI-SKY-XS'),
  ('var_01HZX020F074E_S_skyblue_9DF26E', 'prd_01HZX020F074E', 'S', 'sky blue', 'SM-SHI-SKY-S'),
  ('var_01HZX020F074E_M_skyblue_6414F8', 'prd_01HZX020F074E', 'M', 'sky blue', 'SM-SHI-SKY-M'),
  ('var_01HZX020F074E_L_skyblue_99E2A2', 'prd_01HZX020F074E', 'L', 'sky blue', 'SM-SHI-SKY-L'),
  ('var_01HZX020F074E_XL_skyblue_24D465', 'prd_01HZX020F074E', 'XL', 'sky blue', 'SM-SHI-SKY-XL');

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX02133D5C_XS_lightgray_077CBD', 'prd_01HZX02133D5C', 'XS', 'light gray', 'SM-SHI-LIG-XS'),
  ('var_01HZX02133D5C_S_lightgray_32C875', 'prd_01HZX02133D5C', 'S', 'light gray', 'SM-SHI-LIG-S'),
  ('var_01HZX02133D5C_M_lightgray_345990', 'prd_01HZX02133D5C', 'M', 'light gray', 'SM-SHI-LIG-M'),
  ('var_01HZX02133D5C_L_lightgray_BA8984', 'prd_01HZX02133D5C', 'L', 'light gray', 'SM-SHI-LIG-L'),
  ('var_01HZX02133D5C_XL_lightgray_775EA0', 'prd_01HZX02133D5C', 'XL', 'light gray', 'SM-SHI-LIG-XL'),
  ('var_01HZX02236351_XS_navy_0E1BF7', 'prd_01HZX02236351', 'XS', 'navy', 'SM-SHI-NAV-XS'),
  ('var_01HZX02236351_S_navy_A6E483', 'prd_01HZX02236351', 'S', 'navy', 'SM-SHI-NAV-S'),
  ('var_01HZX02236351_M_navy_3D4776', 'prd_01HZX02236351', 'M', 'navy', 'SM-SHI-NAV-M'),
  ('var_01HZX02236351_L_navy_4BE81E', 'prd_01HZX02236351', 'L', 'navy', 'SM-SHI-NAV-L'),
  ('var_01HZX02236351_XL_navy_429814', 'prd_01HZX02236351', 'XL', 'navy', 'SM-SHI-NAV-XL'),
  ('var_01HZX023EEA5C_XS_sage_C50F01', 'prd_01HZX023EEA5C', 'XS', 'sage', 'SM-SHI-SAG-XS'),
  ('var_01HZX023EEA5C_S_sage_94F9E1', 'prd_01HZX023EEA5C', 'S', 'sage', 'SM-SHI-SAG-S'),
  ('var_01HZX023EEA5C_M_sage_CF0EC3', 'prd_01HZX023EEA5C', 'M', 'sage', 'SM-SHI-SAG-M'),
  ('var_01HZX023EEA5C_L_sage_9BCF5B', 'prd_01HZX023EEA5C', 'L', 'sage', 'SM-SHI-SAG-L'),
  ('var_01HZX023EEA5C_XL_sage_9729F6', 'prd_01HZX023EEA5C', 'XL', 'sage', 'SM-SHI-SAG-XL'),
  ('var_01HZX024F0015_XS_ecru_470E1F', 'prd_01HZX024F0015', 'XS', 'ecru', 'SM-SHI-ECR-XS'),
  ('var_01HZX024F0015_S_ecru_D7F9BC', 'prd_01HZX024F0015', 'S', 'ecru', 'SM-SHI-ECR-S'),
  ('var_01HZX024F0015_M_ecru_86ACD2', 'prd_01HZX024F0015', 'M', 'ecru', 'SM-SHI-ECR-M'),
  ('var_01HZX024F0015_L_ecru_5F295B', 'prd_01HZX024F0015', 'L', 'ecru', 'SM-SHI-ECR-L'),
  ('var_01HZX024F0015_XL_ecru_001995', 'prd_01HZX024F0015', 'XL', 'ecru', 'SM-SHI-ECR-XL'),
  ('var_01HZX025162AE_XS_oxfordblue_6832D1', 'prd_01HZX025162AE', 'XS', 'oxford blue', 'SM-SHI-OXF-XS'),
  ('var_01HZX025162AE_S_oxfordblue_6B72FC', 'prd_01HZX025162AE', 'S', 'oxford blue', 'SM-SHI-OXF-S'),
  ('var_01HZX025162AE_M_oxfordblue_2471C2', 'prd_01HZX025162AE', 'M', 'oxford blue', 'SM-SHI-OXF-M'),
  ('var_01HZX025162AE_L_oxfordblue_9CF31A', 'prd_01HZX025162AE', 'L', 'oxford blue', 'SM-SHI-OXF-L'),
  ('var_01HZX025162AE_XL_oxfordblue_61AB9D', 'prd_01HZX025162AE', 'XL', 'oxford blue', 'SM-SHI-OXF-XL'),
  ('var_01HZX026D3A3F_XS_charcoal_7A0DAA', 'prd_01HZX026D3A3F', 'XS', 'charcoal', 'SM-SHI-CHA-XS'),
  ('var_01HZX026D3A3F_S_charcoal_DEEB73', 'prd_01HZX026D3A3F', 'S', 'charcoal', 'SM-SHI-CHA-S'),
  ('var_01HZX026D3A3F_M_charcoal_8CAF9E', 'prd_01HZX026D3A3F', 'M', 'charcoal', 'SM-SHI-CHA-M'),
  ('var_01HZX026D3A3F_L_charcoal_E6BAC0', 'prd_01HZX026D3A3F', 'L', 'charcoal', 'SM-SHI-CHA-L'),
  ('var_01HZX026D3A3F_XL_charcoal_829FB7', 'prd_01HZX026D3A3F', 'XL', 'charcoal', 'SM-SHI-CHA-XL'),
  ('var_01HZX027E5251_XS_dustyblue_94035F', 'prd_01HZX027E5251', 'XS', 'dusty blue', 'SM-SHI-DUS-XS'),
  ('var_01HZX027E5251_S_dustyblue_581AA2', 'prd_01HZX027E5251', 'S', 'dusty blue', 'SM-SHI-DUS-S'),
  ('var_01HZX027E5251_M_dustyblue_9165D7', 'prd_01HZX027E5251', 'M', 'dusty blue', 'SM-SHI-DUS-M'),
  ('var_01HZX027E5251_L_dustyblue_C152B2', 'prd_01HZX027E5251', 'L', 'dusty blue', 'SM-SHI-DUS-L'),
  ('var_01HZX027E5251_XL_dustyblue_42BB10', 'prd_01HZX027E5251', 'XL', 'dusty blue', 'SM-SHI-DUS-XL'),
  ('var_01HZX028EE8C5_XS_ivory_002BB6', 'prd_01HZX028EE8C5', 'XS', 'ivory', 'SM-SHI-IVO-XS'),
  ('var_01HZX028EE8C5_S_ivory_4ED302', 'prd_01HZX028EE8C5', 'S', 'ivory', 'SM-SHI-IVO-S'),
  ('var_01HZX028EE8C5_M_ivory_ADDFA2', 'prd_01HZX028EE8C5', 'M', 'ivory', 'SM-SHI-IVO-M'),
  ('var_01HZX028EE8C5_L_ivory_5EBEF0', 'prd_01HZX028EE8C5', 'L', 'ivory', 'SM-SHI-IVO-L'),
  ('var_01HZX028EE8C5_XL_ivory_BA3DFB', 'prd_01HZX028EE8C5', 'XL', 'ivory', 'SM-SHI-IVO-XL'),
  ('var_01HZX0299CD6E_XS_black_200535', 'prd_01HZX0299CD6E', 'XS', 'black', 'SM-SHI-BLA-XS'),
  ('var_01HZX0299CD6E_S_black_F0FEDC', 'prd_01HZX0299CD6E', 'S', 'black', 'SM-SHI-BLA-S'),
  ('var_01HZX0299CD6E_M_black_C84DA1', 'prd_01HZX0299CD6E', 'M', 'black', 'SM-SHI-BLA-M'),
  ('var_01HZX0299CD6E_L_black_585684', 'prd_01HZX0299CD6E', 'L', 'black', 'SM-SHI-BLA-L'),
  ('var_01HZX0299CD6E_XL_black_143587', 'prd_01HZX0299CD6E', 'XL', 'black', 'SM-SHI-BLA-XL'),
  ('var_01HZX0302514B_XS_palepink_3A0F8A', 'prd_01HZX0302514B', 'XS', 'pale pink', 'SM-SHI-PAL-XS'),
  ('var_01HZX0302514B_S_palepink_8EDFD0', 'prd_01HZX0302514B', 'S', 'pale pink', 'SM-SHI-PAL-S'),
  ('var_01HZX0302514B_M_palepink_EECEFE', 'prd_01HZX0302514B', 'M', 'pale pink', 'SM-SHI-PAL-M'),
  ('var_01HZX0302514B_L_palepink_0F7438', 'prd_01HZX0302514B', 'L', 'pale pink', 'SM-SHI-PAL-L'),
  ('var_01HZX0302514B_XL_palepink_284AB3', 'prd_01HZX0302514B', 'XL', 'pale pink', 'SM-SHI-PAL-XL'),
  ('var_01HZX03104039_XS_olive_8D4631', 'prd_01HZX03104039', 'XS', 'olive', 'SM-SHI-OLI-XS'),
  ('var_01HZX03104039_S_olive_4F15EA', 'prd_01HZX03104039', 'S', 'olive', 'SM-SHI-OLI-S'),
  ('var_01HZX03104039_M_olive_596F9B', 'prd_01HZX03104039', 'M', 'olive', 'SM-SHI-OLI-M'),
  ('var_01HZX03104039_L_olive_9DEC73', 'prd_01HZX03104039', 'L', 'olive', 'SM-SHI-OLI-L'),
  ('var_01HZX03104039_XL_olive_EB6BBA', 'prd_01HZX03104039', 'XL', 'olive', 'SM-SHI-OLI-XL'),
  ('var_01HZX03216941_XS_midnightblue_155FC6', 'prd_01HZX03216941', 'XS', 'midnight blue', 'SM-SHI-MID-XS'),
  ('var_01HZX03216941_S_midnightblue_7F7F2C', 'prd_01HZX03216941', 'S', 'midnight blue', 'SM-SHI-MID-S'),
  ('var_01HZX03216941_M_midnightblue_C38746', 'prd_01HZX03216941', 'M', 'midnight blue', 'SM-SHI-MID-M'),
  ('var_01HZX03216941_L_midnightblue_ECDF52', 'prd_01HZX03216941', 'L', 'midnight blue', 'SM-SHI-MID-L'),
  ('var_01HZX03216941_XL_midnightblue_7AFD39', 'prd_01HZX03216941', 'XL', 'midnight blue', 'SM-SHI-MID-XL'),
  ('var_01HZX033157E7_XS_beige_443E33', 'prd_01HZX033157E7', 'XS', 'beige', 'SM-SHI-BEI-XS'),
  ('var_01HZX033157E7_S_beige_A05890', 'prd_01HZX033157E7', 'S', 'beige', 'SM-SHI-BEI-S'),
  ('var_01HZX033157E7_M_beige_EB3696', 'prd_01HZX033157E7', 'M', 'beige', 'SM-SHI-BEI-M'),
  ('var_01HZX033157E7_L_beige_22EEFF', 'prd_01HZX033157E7', 'L', 'beige', 'SM-SHI-BEI-L'),
  ('var_01HZX033157E7_XL_beige_92018C', 'prd_01HZX033157E7', 'XL', 'beige', 'SM-SHI-BEI-XL'),
  ('var_01HZX034CB2B2_XS_burgundy_9ABB06', 'prd_01HZX034CB2B2', 'XS', 'burgundy', 'SM-SHI-BUR-XS'),
  ('var_01HZX034CB2B2_S_burgundy_ED11C7', 'prd_01HZX034CB2B2', 'S', 'burgundy', 'SM-SHI-BUR-S'),
  ('var_01HZX034CB2B2_M_burgundy_0D67B6', 'prd_01HZX034CB2B2', 'M', 'burgundy', 'SM-SHI-BUR-M'),
  ('var_01HZX034CB2B2_L_burgundy_FC1B8E', 'prd_01HZX034CB2B2', 'L', 'burgundy', 'SM-SHI-BUR-L'),
  ('var_01HZX034CB2B2_XL_burgundy_2318CC', 'prd_01HZX034CB2B2', 'XL', 'burgundy', 'SM-SHI-BUR-XL'),
  ('var_01HZX035816E9_XS_teal_E7435D', 'prd_01HZX035816E9', 'XS', 'teal', 'SM-SHI-TEA-XS'),
  ('var_01HZX035816E9_S_teal_3DBA8C', 'prd_01HZX035816E9', 'S', 'teal', 'SM-SHI-TEA-S'),
  ('var_01HZX035816E9_M_teal_E97E02', 'prd_01HZX035816E9', 'M', 'teal', 'SM-SHI-TEA-M'),
  ('var_01HZX035816E9_L_teal_24C017', 'prd_01HZX035816E9', 'L', 'teal', 'SM-SHI-TEA-L'),
  ('var_01HZX035816E9_XL_teal_C0699E', 'prd_01HZX035816E9', 'XL', 'teal', 'SM-SHI-TEA-XL'),
  ('var_01HZX0363DC1B_XS_sand_F6FCDF', 'prd_01HZX0363DC1B', 'XS', 'sand', 'SM-SHI-SAN-XS'),
  ('var_01HZX0363DC1B_S_sand_31EABD', 'prd_01HZX0363DC1B', 'S', 'sand', 'SM-SHI-SAN-S'),
  ('var_01HZX0363DC1B_M_sand_87F23A', 'prd_01HZX0363DC1B', 'M', 'sand', 'SM-SHI-SAN-M'),
  ('var_01HZX0363DC1B_L_sand_AA1A9E', 'prd_01HZX0363DC1B', 'L', 'sand', 'SM-SHI-SAN-L'),
  ('var_01HZX0363DC1B_XL_sand_CE6A2C', 'prd_01HZX0363DC1B', 'XL', 'sand', 'SM-SHI-SAN-XL'),
  ('var_01HZX0379CC49_28_indigo_FF5F9B', 'prd_01HZX0379CC49', '28', 'indigo', 'SM-JEA-IND-28'),
  ('var_01HZX0379CC49_30_indigo_BA2084', 'prd_01HZX0379CC49', '30', 'indigo', 'SM-JEA-IND-30'),
  ('var_01HZX0379CC49_32_indigo_BBD9A1', 'prd_01HZX0379CC49', '32', 'indigo', 'SM-JEA-IND-32'),
  ('var_01HZX0379CC49_34_indigo_C4F078', 'prd_01HZX0379CC49', '34', 'indigo', 'SM-JEA-IND-34'),
  ('var_01HZX0379CC49_36_indigo_4C374F', 'prd_01HZX0379CC49', '36', 'indigo', 'SM-JEA-IND-36'),
  ('var_01HZX038D8B0C_28_black_57417B', 'prd_01HZX038D8B0C', '28', 'black', 'SM-JEA-BLA-28'),
  ('var_01HZX038D8B0C_30_black_0F305A', 'prd_01HZX038D8B0C', '30', 'black', 'SM-JEA-BLA-30'),
  ('var_01HZX038D8B0C_32_black_578826', 'prd_01HZX038D8B0C', '32', 'black', 'SM-JEA-BLA-32'),
  ('var_01HZX038D8B0C_34_black_4DD948', 'prd_01HZX038D8B0C', '34', 'black', 'SM-JEA-BLA-34'),
  ('var_01HZX038D8B0C_36_black_3C8B55', 'prd_01HZX038D8B0C', '36', 'black', 'SM-JEA-BLA-36'),
  ('var_01HZX03959B15_28_midblue_E4A9B3', 'prd_01HZX03959B15', '28', 'mid blue', 'SM-JEA-MID-28'),
  ('var_01HZX03959B15_30_midblue_3EE13B', 'prd_01HZX03959B15', '30', 'mid blue', 'SM-JEA-MID-30'),
  ('var_01HZX03959B15_32_midblue_ACB1F0', 'prd_01HZX03959B15', '32', 'mid blue', 'SM-JEA-MID-32'),
  ('var_01HZX03959B15_34_midblue_7C6946', 'prd_01HZX03959B15', '34', 'mid blue', 'SM-JEA-MID-34'),
  ('var_01HZX03959B15_36_midblue_E464D2', 'prd_01HZX03959B15', '36', 'mid blue', 'SM-JEA-MID-36'),
  ('var_01HZX0403CEB8_28_lightwashblue_DA68F1', 'prd_01HZX0403CEB8', '28', 'light wash blue', 'SM-JEA-LIG-28'),
  ('var_01HZX0403CEB8_30_lightwashblue_23CB53', 'prd_01HZX0403CEB8', '30', 'light wash blue', 'SM-JEA-LIG-30'),
  ('var_01HZX0403CEB8_32_lightwashblue_6748E2', 'prd_01HZX0403CEB8', '32', 'light wash blue', 'SM-JEA-LIG-32'),
  ('var_01HZX0403CEB8_34_lightwashblue_8EC877', 'prd_01HZX0403CEB8', '34', 'light wash blue', 'SM-JEA-LIG-34'),
  ('var_01HZX0403CEB8_36_lightwashblue_FBE463', 'prd_01HZX0403CEB8', '36', 'light wash blue', 'SM-JEA-LIG-36'),
  ('var_01HZX041CC651_28_charcoal_1B1B53', 'prd_01HZX041CC651', '28', 'charcoal', 'SM-JEA-CHA-28'),
  ('var_01HZX041CC651_30_charcoal_670DC3', 'prd_01HZX041CC651', '30', 'charcoal', 'SM-JEA-CHA-30'),
  ('var_01HZX041CC651_32_charcoal_E8BA08', 'prd_01HZX041CC651', '32', 'charcoal', 'SM-JEA-CHA-32'),
  ('var_01HZX041CC651_34_charcoal_97E128', 'prd_01HZX041CC651', '34', 'charcoal', 'SM-JEA-CHA-34'),
  ('var_01HZX041CC651_36_charcoal_8C8194', 'prd_01HZX041CC651', '36', 'charcoal', 'SM-JEA-CHA-36'),
  ('var_01HZX042115D1_28_rawindigo_694993', 'prd_01HZX042115D1', '28', 'raw indigo', 'SM-JEA-RAW-28'),
  ('var_01HZX042115D1_30_rawindigo_2FC350', 'prd_01HZX042115D1', '30', 'raw indigo', 'SM-JEA-RAW-30'),
  ('var_01HZX042115D1_32_rawindigo_FFD461', 'prd_01HZX042115D1', '32', 'raw indigo', 'SM-JEA-RAW-32'),
  ('var_01HZX042115D1_34_rawindigo_684A12', 'prd_01HZX042115D1', '34', 'raw indigo', 'SM-JEA-RAW-34'),
  ('var_01HZX042115D1_36_rawindigo_234629', 'prd_01HZX042115D1', '36', 'raw indigo', 'SM-JEA-RAW-36'),
  ('var_01HZX04321198_28_vintageblue_88EBCB', 'prd_01HZX04321198', '28', 'vintage blue', 'SM-JEA-VIN-28'),
  ('var_01HZX04321198_30_vintageblue_58D70B', 'prd_01HZX04321198', '30', 'vintage blue', 'SM-JEA-VIN-30'),
  ('var_01HZX04321198_32_vintageblue_276C54', 'prd_01HZX04321198', '32', 'vintage blue', 'SM-JEA-VIN-32'),
  ('var_01HZX04321198_34_vintageblue_640692', 'prd_01HZX04321198', '34', 'vintage blue', 'SM-JEA-VIN-34'),
  ('var_01HZX04321198_36_vintageblue_76C1DE', 'prd_01HZX04321198', '36', 'vintage blue', 'SM-JEA-VIN-36'),
  ('var_01HZX0449E075_28_gray_8791F7', 'prd_01HZX0449E075', '28', 'gray', 'SM-JEA-GRA-28'),
  ('var_01HZX0449E075_30_gray_9030D8', 'prd_01HZX0449E075', '30', 'gray', 'SM-JEA-GRA-30'),
  ('var_01HZX0449E075_32_gray_D596EE', 'prd_01HZX0449E075', '32', 'gray', 'SM-JEA-GRA-32'),
  ('var_01HZX0449E075_34_gray_BAF9AE', 'prd_01HZX0449E075', '34', 'gray', 'SM-JEA-GRA-34'),
  ('var_01HZX0449E075_36_gray_E0E049', 'prd_01HZX0449E075', '36', 'gray', 'SM-JEA-GRA-36'),
  ('var_01HZX045DDBC0_28_deepblue_504783', 'prd_01HZX045DDBC0', '28', 'deep blue', 'SM-JEA-DEE-28'),
  ('var_01HZX045DDBC0_30_deepblue_D7DBD9', 'prd_01HZX045DDBC0', '30', 'deep blue', 'SM-JEA-DEE-30'),
  ('var_01HZX045DDBC0_32_deepblue_A0B1E0', 'prd_01HZX045DDBC0', '32', 'deep blue', 'SM-JEA-DEE-32'),
  ('var_01HZX045DDBC0_34_deepblue_99C539', 'prd_01HZX045DDBC0', '34', 'deep blue', 'SM-JEA-DEE-34'),
  ('var_01HZX045DDBC0_36_deepblue_C79155', 'prd_01HZX045DDBC0', '36', 'deep blue', 'SM-JEA-DEE-36'),
  ('var_01HZX04673CA4_28_black_02A183', 'prd_01HZX04673CA4', '28', 'black', 'SM-JEA-BLA-28'),
  ('var_01HZX04673CA4_30_black_A68E45', 'prd_01HZX04673CA4', '30', 'black', 'SM-JEA-BLA-30'),
  ('var_01HZX04673CA4_32_black_0B854A', 'prd_01HZX04673CA4', '32', 'black', 'SM-JEA-BLA-32'),
  ('var_01HZX04673CA4_34_black_12A210', 'prd_01HZX04673CA4', '34', 'black', 'SM-JEA-BLA-34'),
  ('var_01HZX04673CA4_36_black_C0BBF0', 'prd_01HZX04673CA4', '36', 'black', 'SM-JEA-BLA-36'),
  ('var_01HZX04784E6E_28_bleachedblue_1E0EF9', 'prd_01HZX04784E6E', '28', 'bleached blue', 'SM-JEA-BLE-28'),
  ('var_01HZX04784E6E_30_bleachedblue_72AD51', 'prd_01HZX04784E6E', '30', 'bleached blue', 'SM-JEA-BLE-30'),
  ('var_01HZX04784E6E_32_bleachedblue_87B62E', 'prd_01HZX04784E6E', '32', 'bleached blue', 'SM-JEA-BLE-32'),
  ('var_01HZX04784E6E_34_bleachedblue_C404FA', 'prd_01HZX04784E6E', '34', 'bleached blue', 'SM-JEA-BLE-34'),
  ('var_01HZX04784E6E_36_bleachedblue_72C54B', 'prd_01HZX04784E6E', '36', 'bleached blue', 'SM-JEA-BLE-36'),
  ('var_01HZX048241B3_28_slate_7B1222', 'prd_01HZX048241B3', '28', 'slate', 'SM-JEA-SLA-28'),
  ('var_01HZX048241B3_30_slate_788DA8', 'prd_01HZX048241B3', '30', 'slate', 'SM-JEA-SLA-30'),
  ('var_01HZX048241B3_32_slate_CE8CB3', 'prd_01HZX048241B3', '32', 'slate', 'SM-JEA-SLA-32'),
  ('var_01HZX048241B3_34_slate_6012A1', 'prd_01HZX048241B3', '34', 'slate', 'SM-JEA-SLA-34'),
  ('var_01HZX048241B3_36_slate_E40BA6', 'prd_01HZX048241B3', '36', 'slate', 'SM-JEA-SLA-36'),
  ('var_01HZX04904E67_28_khaki_532422', 'prd_01HZX04904E67', '28', 'khaki', 'SM-PAN-KHA-28'),
  ('var_01HZX04904E67_30_khaki_189BF5', 'prd_01HZX04904E67', '30', 'khaki', 'SM-PAN-KHA-30'),
  ('var_01HZX04904E67_32_khaki_EC46A7', 'prd_01HZX04904E67', '32', 'khaki', 'SM-PAN-KHA-32'),
  ('var_01HZX04904E67_34_khaki_A3B053', 'prd_01HZX04904E67', '34', 'khaki', 'SM-PAN-KHA-34'),
  ('var_01HZX04904E67_36_khaki_45D51A', 'prd_01HZX04904E67', '36', 'khaki', 'SM-PAN-KHA-36'),
  ('var_01HZX050F7543_28_olive_AB98CF', 'prd_01HZX050F7543', '28', 'olive', 'SM-PAN-OLI-28'),
  ('var_01HZX050F7543_30_olive_B65E9F', 'prd_01HZX050F7543', '30', 'olive', 'SM-PAN-OLI-30'),
  ('var_01HZX050F7543_32_olive_534578', 'prd_01HZX050F7543', '32', 'olive', 'SM-PAN-OLI-32'),
  ('var_01HZX050F7543_34_olive_00ECF3', 'prd_01HZX050F7543', '34', 'olive', 'SM-PAN-OLI-34'),
  ('var_01HZX050F7543_36_olive_71A3A8', 'prd_01HZX050F7543', '36', 'olive', 'SM-PAN-OLI-36'),
  ('var_01HZX051B5C03_28_navy_F106E8', 'prd_01HZX051B5C03', '28', 'navy', 'SM-PAN-NAV-28'),
  ('var_01HZX051B5C03_30_navy_2A0301', 'prd_01HZX051B5C03', '30', 'navy', 'SM-PAN-NAV-30'),
  ('var_01HZX051B5C03_32_navy_E10FEC', 'prd_01HZX051B5C03', '32', 'navy', 'SM-PAN-NAV-32'),
  ('var_01HZX051B5C03_34_navy_1234F2', 'prd_01HZX051B5C03', '34', 'navy', 'SM-PAN-NAV-34'),
  ('var_01HZX051B5C03_36_navy_EB0F4A', 'prd_01HZX051B5C03', '36', 'navy', 'SM-PAN-NAV-36'),
  ('var_01HZX052DC64F_28_stone_9BD174', 'prd_01HZX052DC64F', '28', 'stone', 'SM-PAN-STO-28'),
  ('var_01HZX052DC64F_30_stone_A71D82', 'prd_01HZX052DC64F', '30', 'stone', 'SM-PAN-STO-30'),
  ('var_01HZX052DC64F_32_stone_2858BB', 'prd_01HZX052DC64F', '32', 'stone', 'SM-PAN-STO-32'),
  ('var_01HZX052DC64F_34_stone_A73021', 'prd_01HZX052DC64F', '34', 'stone', 'SM-PAN-STO-34'),
  ('var_01HZX052DC64F_36_stone_20F403', 'prd_01HZX052DC64F', '36', 'stone', 'SM-PAN-STO-36'),
  ('var_01HZX0534DE92_28_sand_6CAC1C', 'prd_01HZX0534DE92', '28', 'sand', 'SM-PAN-SAN-28'),
  ('var_01HZX0534DE92_30_sand_81E663', 'prd_01HZX0534DE92', '30', 'sand', 'SM-PAN-SAN-30'),
  ('var_01HZX0534DE92_32_sand_2C9864', 'prd_01HZX0534DE92', '32', 'sand', 'SM-PAN-SAN-32'),
  ('var_01HZX0534DE92_34_sand_58FFAC', 'prd_01HZX0534DE92', '34', 'sand', 'SM-PAN-SAN-34'),
  ('var_01HZX0534DE92_36_sand_8635B4', 'prd_01HZX0534DE92', '36', 'sand', 'SM-PAN-SAN-36');

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX054AA876_28_camel_52D2F8', 'prd_01HZX054AA876', '28', 'camel', 'SM-PAN-CAM-28'),
  ('var_01HZX054AA876_30_camel_3C2138', 'prd_01HZX054AA876', '30', 'camel', 'SM-PAN-CAM-30'),
  ('var_01HZX054AA876_32_camel_A05377', 'prd_01HZX054AA876', '32', 'camel', 'SM-PAN-CAM-32'),
  ('var_01HZX054AA876_34_camel_ACB279', 'prd_01HZX054AA876', '34', 'camel', 'SM-PAN-CAM-34'),
  ('var_01HZX054AA876_36_camel_569389', 'prd_01HZX054AA876', '36', 'camel', 'SM-PAN-CAM-36'),
  ('var_01HZX0552CB2B_28_forestgreen_6A0F49', 'prd_01HZX0552CB2B', '28', 'forest green', 'SM-PAN-FOR-28'),
  ('var_01HZX0552CB2B_30_forestgreen_A56926', 'prd_01HZX0552CB2B', '30', 'forest green', 'SM-PAN-FOR-30'),
  ('var_01HZX0552CB2B_32_forestgreen_CAF20A', 'prd_01HZX0552CB2B', '32', 'forest green', 'SM-PAN-FOR-32'),
  ('var_01HZX0552CB2B_34_forestgreen_7D8D9D', 'prd_01HZX0552CB2B', '34', 'forest green', 'SM-PAN-FOR-34'),
  ('var_01HZX0552CB2B_36_forestgreen_715B7E', 'prd_01HZX0552CB2B', '36', 'forest green', 'SM-PAN-FOR-36'),
  ('var_01HZX056AC195_28_burgundy_A3F4E2', 'prd_01HZX056AC195', '28', 'burgundy', 'SM-PAN-BUR-28'),
  ('var_01HZX056AC195_30_burgundy_58AEFD', 'prd_01HZX056AC195', '30', 'burgundy', 'SM-PAN-BUR-30'),
  ('var_01HZX056AC195_32_burgundy_77916C', 'prd_01HZX056AC195', '32', 'burgundy', 'SM-PAN-BUR-32'),
  ('var_01HZX056AC195_34_burgundy_231CFF', 'prd_01HZX056AC195', '34', 'burgundy', 'SM-PAN-BUR-34'),
  ('var_01HZX056AC195_36_burgundy_1C4984', 'prd_01HZX056AC195', '36', 'burgundy', 'SM-PAN-BUR-36'),
  ('var_01HZX0573CF7C_28_white_40ABDB', 'prd_01HZX0573CF7C', '28', 'white', 'SM-PAN-WHI-28'),
  ('var_01HZX0573CF7C_30_white_7AEEB2', 'prd_01HZX0573CF7C', '30', 'white', 'SM-PAN-WHI-30'),
  ('var_01HZX0573CF7C_32_white_2E94F4', 'prd_01HZX0573CF7C', '32', 'white', 'SM-PAN-WHI-32'),
  ('var_01HZX0573CF7C_34_white_ED2332', 'prd_01HZX0573CF7C', '34', 'white', 'SM-PAN-WHI-34'),
  ('var_01HZX0573CF7C_36_white_55CC50', 'prd_01HZX0573CF7C', '36', 'white', 'SM-PAN-WHI-36'),
  ('var_01HZX0587C9B0_28_tan_FCD5FC', 'prd_01HZX0587C9B0', '28', 'tan', 'SM-PAN-TAN-28'),
  ('var_01HZX0587C9B0_30_tan_2D68E3', 'prd_01HZX0587C9B0', '30', 'tan', 'SM-PAN-TAN-30'),
  ('var_01HZX0587C9B0_32_tan_4E47F2', 'prd_01HZX0587C9B0', '32', 'tan', 'SM-PAN-TAN-32'),
  ('var_01HZX0587C9B0_34_tan_BE21F9', 'prd_01HZX0587C9B0', '34', 'tan', 'SM-PAN-TAN-34'),
  ('var_01HZX0587C9B0_36_tan_EDF4E9', 'prd_01HZX0587C9B0', '36', 'tan', 'SM-PAN-TAN-36'),
  ('var_01HZX0597F0E3_XS_navy_9D9C81', 'prd_01HZX0597F0E3', 'XS', 'navy', 'SM-JAC-NAV-XS'),
  ('var_01HZX0597F0E3_S_navy_F33AE8', 'prd_01HZX0597F0E3', 'S', 'navy', 'SM-JAC-NAV-S'),
  ('var_01HZX0597F0E3_M_navy_F95DBF', 'prd_01HZX0597F0E3', 'M', 'navy', 'SM-JAC-NAV-M'),
  ('var_01HZX0597F0E3_L_navy_7CF662', 'prd_01HZX0597F0E3', 'L', 'navy', 'SM-JAC-NAV-L'),
  ('var_01HZX0597F0E3_XL_navy_9EB0E4', 'prd_01HZX0597F0E3', 'XL', 'navy', 'SM-JAC-NAV-XL'),
  ('var_01HZX060DAB51_XS_charcoal_672D4A', 'prd_01HZX060DAB51', 'XS', 'charcoal', 'SM-JAC-CHA-XS'),
  ('var_01HZX060DAB51_S_charcoal_58F3EB', 'prd_01HZX060DAB51', 'S', 'charcoal', 'SM-JAC-CHA-S'),
  ('var_01HZX060DAB51_M_charcoal_0DAAD2', 'prd_01HZX060DAB51', 'M', 'charcoal', 'SM-JAC-CHA-M'),
  ('var_01HZX060DAB51_L_charcoal_4ED97E', 'prd_01HZX060DAB51', 'L', 'charcoal', 'SM-JAC-CHA-L'),
  ('var_01HZX060DAB51_XL_charcoal_7A3BCB', 'prd_01HZX060DAB51', 'XL', 'charcoal', 'SM-JAC-CHA-XL'),
  ('var_01HZX061959D1_XS_camel_A04531', 'prd_01HZX061959D1', 'XS', 'camel', 'SM-JAC-CAM-XS'),
  ('var_01HZX061959D1_S_camel_8B2E64', 'prd_01HZX061959D1', 'S', 'camel', 'SM-JAC-CAM-S'),
  ('var_01HZX061959D1_M_camel_6B419C', 'prd_01HZX061959D1', 'M', 'camel', 'SM-JAC-CAM-M'),
  ('var_01HZX061959D1_L_camel_1300CE', 'prd_01HZX061959D1', 'L', 'camel', 'SM-JAC-CAM-L'),
  ('var_01HZX061959D1_XL_camel_A1C67E', 'prd_01HZX061959D1', 'XL', 'camel', 'SM-JAC-CAM-XL'),
  ('var_01HZX06218D2C_XS_olive_62538C', 'prd_01HZX06218D2C', 'XS', 'olive', 'SM-JAC-OLI-XS'),
  ('var_01HZX06218D2C_S_olive_F68408', 'prd_01HZX06218D2C', 'S', 'olive', 'SM-JAC-OLI-S'),
  ('var_01HZX06218D2C_M_olive_29E03F', 'prd_01HZX06218D2C', 'M', 'olive', 'SM-JAC-OLI-M'),
  ('var_01HZX06218D2C_L_olive_72E0C8', 'prd_01HZX06218D2C', 'L', 'olive', 'SM-JAC-OLI-L'),
  ('var_01HZX06218D2C_XL_olive_043913', 'prd_01HZX06218D2C', 'XL', 'olive', 'SM-JAC-OLI-XL'),
  ('var_01HZX06332272_XS_slategray_1A617B', 'prd_01HZX06332272', 'XS', 'slate gray', 'SM-JAC-SLA-XS'),
  ('var_01HZX06332272_S_slategray_0DBD85', 'prd_01HZX06332272', 'S', 'slate gray', 'SM-JAC-SLA-S'),
  ('var_01HZX06332272_M_slategray_C85B48', 'prd_01HZX06332272', 'M', 'slate gray', 'SM-JAC-SLA-M'),
  ('var_01HZX06332272_L_slategray_FCD165', 'prd_01HZX06332272', 'L', 'slate gray', 'SM-JAC-SLA-L'),
  ('var_01HZX06332272_XL_slategray_666543', 'prd_01HZX06332272', 'XL', 'slate gray', 'SM-JAC-SLA-XL'),
  ('var_01HZX064F12C1_XS_deepburgundy_8E2B25', 'prd_01HZX064F12C1', 'XS', 'deep burgundy', 'SM-JAC-DEE-XS'),
  ('var_01HZX064F12C1_S_deepburgundy_96D17F', 'prd_01HZX064F12C1', 'S', 'deep burgundy', 'SM-JAC-DEE-S'),
  ('var_01HZX064F12C1_M_deepburgundy_21E98F', 'prd_01HZX064F12C1', 'M', 'deep burgundy', 'SM-JAC-DEE-M'),
  ('var_01HZX064F12C1_L_deepburgundy_EEA530', 'prd_01HZX064F12C1', 'L', 'deep burgundy', 'SM-JAC-DEE-L'),
  ('var_01HZX064F12C1_XL_deepburgundy_BCD42F', 'prd_01HZX064F12C1', 'XL', 'deep burgundy', 'SM-JAC-DEE-XL'),
  ('var_01HZX0657230C_XS_black_05CC8C', 'prd_01HZX0657230C', 'XS', 'black', 'SM-JAC-BLA-XS'),
  ('var_01HZX0657230C_S_black_5FDAD7', 'prd_01HZX0657230C', 'S', 'black', 'SM-JAC-BLA-S'),
  ('var_01HZX0657230C_M_black_F5ED8A', 'prd_01HZX0657230C', 'M', 'black', 'SM-JAC-BLA-M'),
  ('var_01HZX0657230C_L_black_1D9B4C', 'prd_01HZX0657230C', 'L', 'black', 'SM-JAC-BLA-L'),
  ('var_01HZX0657230C_XL_black_AEE7C6', 'prd_01HZX0657230C', 'XL', 'black', 'SM-JAC-BLA-XL'),
  ('var_01HZX06612615_XS_sand_EF1AD1', 'prd_01HZX06612615', 'XS', 'sand', 'SM-JAC-SAN-XS'),
  ('var_01HZX06612615_S_sand_A3544F', 'prd_01HZX06612615', 'S', 'sand', 'SM-JAC-SAN-S'),
  ('var_01HZX06612615_M_sand_A48B75', 'prd_01HZX06612615', 'M', 'sand', 'SM-JAC-SAN-M'),
  ('var_01HZX06612615_L_sand_CB7831', 'prd_01HZX06612615', 'L', 'sand', 'SM-JAC-SAN-L'),
  ('var_01HZX06612615_XL_sand_C96923', 'prd_01HZX06612615', 'XL', 'sand', 'SM-JAC-SAN-XL'),
  ('var_01HZX067FC6AF_XS_midnightblue_9FE7D8', 'prd_01HZX067FC6AF', 'XS', 'midnight blue', 'SM-JAC-MID-XS'),
  ('var_01HZX067FC6AF_S_midnightblue_2FB9C1', 'prd_01HZX067FC6AF', 'S', 'midnight blue', 'SM-JAC-MID-S'),
  ('var_01HZX067FC6AF_M_midnightblue_9C402E', 'prd_01HZX067FC6AF', 'M', 'midnight blue', 'SM-JAC-MID-M'),
  ('var_01HZX067FC6AF_L_midnightblue_C080B4', 'prd_01HZX067FC6AF', 'L', 'midnight blue', 'SM-JAC-MID-L'),
  ('var_01HZX067FC6AF_XL_midnightblue_A190A0', 'prd_01HZX067FC6AF', 'XL', 'midnight blue', 'SM-JAC-MID-XL'),
  ('var_01HZX0682F18D_XS_forestgreen_B0101E', 'prd_01HZX0682F18D', 'XS', 'forest green', 'SM-JAC-FOR-XS'),
  ('var_01HZX0682F18D_S_forestgreen_0FB462', 'prd_01HZX0682F18D', 'S', 'forest green', 'SM-JAC-FOR-S'),
  ('var_01HZX0682F18D_M_forestgreen_2EC480', 'prd_01HZX0682F18D', 'M', 'forest green', 'SM-JAC-FOR-M'),
  ('var_01HZX0682F18D_L_forestgreen_F9339F', 'prd_01HZX0682F18D', 'L', 'forest green', 'SM-JAC-FOR-L'),
  ('var_01HZX0682F18D_XL_forestgreen_21ACF2', 'prd_01HZX0682F18D', 'XL', 'forest green', 'SM-JAC-FOR-XL'),
  ('var_01HZX069DD580_XS_stone_A673F2', 'prd_01HZX069DD580', 'XS', 'stone', 'SM-JAC-STO-XS'),
  ('var_01HZX069DD580_S_stone_66CD93', 'prd_01HZX069DD580', 'S', 'stone', 'SM-JAC-STO-S'),
  ('var_01HZX069DD580_M_stone_C2D8C5', 'prd_01HZX069DD580', 'M', 'stone', 'SM-JAC-STO-M'),
  ('var_01HZX069DD580_L_stone_D88F1B', 'prd_01HZX069DD580', 'L', 'stone', 'SM-JAC-STO-L'),
  ('var_01HZX069DD580_XL_stone_4CCCD5', 'prd_01HZX069DD580', 'XL', 'stone', 'SM-JAC-STO-XL'),
  ('var_01HZX070429F3_XS_teal_0D5306', 'prd_01HZX070429F3', 'XS', 'teal', 'SM-JAC-TEA-XS'),
  ('var_01HZX070429F3_S_teal_05C291', 'prd_01HZX070429F3', 'S', 'teal', 'SM-JAC-TEA-S'),
  ('var_01HZX070429F3_M_teal_47AF43', 'prd_01HZX070429F3', 'M', 'teal', 'SM-JAC-TEA-M'),
  ('var_01HZX070429F3_L_teal_7E62FE', 'prd_01HZX070429F3', 'L', 'teal', 'SM-JAC-TEA-L'),
  ('var_01HZX070429F3_XL_teal_901741', 'prd_01HZX070429F3', 'XL', 'teal', 'SM-JAC-TEA-XL'),
  ('var_01HZX07187B9E_XS_graphite_A3A21D', 'prd_01HZX07187B9E', 'XS', 'graphite', 'SM-JAC-GRA-XS'),
  ('var_01HZX07187B9E_S_graphite_E0A68A', 'prd_01HZX07187B9E', 'S', 'graphite', 'SM-JAC-GRA-S'),
  ('var_01HZX07187B9E_M_graphite_CAD6C3', 'prd_01HZX07187B9E', 'M', 'graphite', 'SM-JAC-GRA-M'),
  ('var_01HZX07187B9E_L_graphite_2AD9BB', 'prd_01HZX07187B9E', 'L', 'graphite', 'SM-JAC-GRA-L'),
  ('var_01HZX07187B9E_XL_graphite_AA0965', 'prd_01HZX07187B9E', 'XL', 'graphite', 'SM-JAC-GRA-XL'),
  ('var_01HZX0722E7BB_XS_tan_07F5AA', 'prd_01HZX0722E7BB', 'XS', 'tan', 'SM-JAC-TAN-XS'),
  ('var_01HZX0722E7BB_S_tan_E12B2A', 'prd_01HZX0722E7BB', 'S', 'tan', 'SM-JAC-TAN-S'),
  ('var_01HZX0722E7BB_M_tan_37B029', 'prd_01HZX0722E7BB', 'M', 'tan', 'SM-JAC-TAN-M'),
  ('var_01HZX0722E7BB_L_tan_37C526', 'prd_01HZX0722E7BB', 'L', 'tan', 'SM-JAC-TAN-L'),
  ('var_01HZX0722E7BB_XL_tan_D3E757', 'prd_01HZX0722E7BB', 'XL', 'tan', 'SM-JAC-TAN-XL'),
  ('var_01HZX0739DCBA_XS_wine_993307', 'prd_01HZX0739DCBA', 'XS', 'wine', 'SM-JAC-WIN-XS'),
  ('var_01HZX0739DCBA_S_wine_3B9109', 'prd_01HZX0739DCBA', 'S', 'wine', 'SM-JAC-WIN-S'),
  ('var_01HZX0739DCBA_M_wine_B78375', 'prd_01HZX0739DCBA', 'M', 'wine', 'SM-JAC-WIN-M'),
  ('var_01HZX0739DCBA_L_wine_38446A', 'prd_01HZX0739DCBA', 'L', 'wine', 'SM-JAC-WIN-L'),
  ('var_01HZX0739DCBA_XL_wine_3FB1E9', 'prd_01HZX0739DCBA', 'XL', 'wine', 'SM-JAC-WIN-XL'),
  ('var_01HZX074BF315_XS_steelblue_491FAC', 'prd_01HZX074BF315', 'XS', 'steel blue', 'SM-JAC-STE-XS'),
  ('var_01HZX074BF315_S_steelblue_C23EFC', 'prd_01HZX074BF315', 'S', 'steel blue', 'SM-JAC-STE-S'),
  ('var_01HZX074BF315_M_steelblue_F2A234', 'prd_01HZX074BF315', 'M', 'steel blue', 'SM-JAC-STE-M'),
  ('var_01HZX074BF315_L_steelblue_45D9CB', 'prd_01HZX074BF315', 'L', 'steel blue', 'SM-JAC-STE-L'),
  ('var_01HZX074BF315_XL_steelblue_976D57', 'prd_01HZX074BF315', 'XL', 'steel blue', 'SM-JAC-STE-XL'),
  ('var_01HZX075CAF3A_XS_black_FB9C29', 'prd_01HZX075CAF3A', 'XS', 'black', 'SM-DRE-BLA-XS'),
  ('var_01HZX075CAF3A_S_black_509C82', 'prd_01HZX075CAF3A', 'S', 'black', 'SM-DRE-BLA-S'),
  ('var_01HZX075CAF3A_M_black_AC0D19', 'prd_01HZX075CAF3A', 'M', 'black', 'SM-DRE-BLA-M'),
  ('var_01HZX075CAF3A_L_black_1F3792', 'prd_01HZX075CAF3A', 'L', 'black', 'SM-DRE-BLA-L'),
  ('var_01HZX076F5A53_XS_navy_2AAE39', 'prd_01HZX076F5A53', 'XS', 'navy', 'SM-DRE-NAV-XS'),
  ('var_01HZX076F5A53_S_navy_B38A69', 'prd_01HZX076F5A53', 'S', 'navy', 'SM-DRE-NAV-S'),
  ('var_01HZX076F5A53_M_navy_8E9947', 'prd_01HZX076F5A53', 'M', 'navy', 'SM-DRE-NAV-M'),
  ('var_01HZX076F5A53_L_navy_D8B019', 'prd_01HZX076F5A53', 'L', 'navy', 'SM-DRE-NAV-L'),
  ('var_01HZX0777A454_XS_sage_C44AE8', 'prd_01HZX0777A454', 'XS', 'sage', 'SM-DRE-SAG-XS'),
  ('var_01HZX0777A454_S_sage_DECA3C', 'prd_01HZX0777A454', 'S', 'sage', 'SM-DRE-SAG-S'),
  ('var_01HZX0777A454_M_sage_22FBAF', 'prd_01HZX0777A454', 'M', 'sage', 'SM-DRE-SAG-M'),
  ('var_01HZX0777A454_L_sage_13147E', 'prd_01HZX0777A454', 'L', 'sage', 'SM-DRE-SAG-L'),
  ('var_01HZX07842949_XS_dustyrose_E22585', 'prd_01HZX07842949', 'XS', 'dusty rose', 'SM-DRE-DUS-XS'),
  ('var_01HZX07842949_S_dustyrose_300474', 'prd_01HZX07842949', 'S', 'dusty rose', 'SM-DRE-DUS-S'),
  ('var_01HZX07842949_M_dustyrose_87DC80', 'prd_01HZX07842949', 'M', 'dusty rose', 'SM-DRE-DUS-M'),
  ('var_01HZX07842949_L_dustyrose_AE1173', 'prd_01HZX07842949', 'L', 'dusty rose', 'SM-DRE-DUS-L'),
  ('var_01HZX079F7EA2_XS_terracotta_8310E0', 'prd_01HZX079F7EA2', 'XS', 'terracotta', 'SM-DRE-TER-XS'),
  ('var_01HZX079F7EA2_S_terracotta_84F9A6', 'prd_01HZX079F7EA2', 'S', 'terracotta', 'SM-DRE-TER-S'),
  ('var_01HZX079F7EA2_M_terracotta_75080A', 'prd_01HZX079F7EA2', 'M', 'terracotta', 'SM-DRE-TER-M'),
  ('var_01HZX079F7EA2_L_terracotta_863137', 'prd_01HZX079F7EA2', 'L', 'terracotta', 'SM-DRE-TER-L'),
  ('var_01HZX080C8931_XS_ivory_D43057', 'prd_01HZX080C8931', 'XS', 'ivory', 'SM-DRE-IVO-XS'),
  ('var_01HZX080C8931_S_ivory_CA47B8', 'prd_01HZX080C8931', 'S', 'ivory', 'SM-DRE-IVO-S'),
  ('var_01HZX080C8931_M_ivory_013A39', 'prd_01HZX080C8931', 'M', 'ivory', 'SM-DRE-IVO-M'),
  ('var_01HZX080C8931_L_ivory_2B7A6F', 'prd_01HZX080C8931', 'L', 'ivory', 'SM-DRE-IVO-L'),
  ('var_01HZX081764A2_XS_deepteal_8BB0A8', 'prd_01HZX081764A2', 'XS', 'deep teal', 'SM-DRE-DEE-XS'),
  ('var_01HZX081764A2_S_deepteal_132347', 'prd_01HZX081764A2', 'S', 'deep teal', 'SM-DRE-DEE-S'),
  ('var_01HZX081764A2_M_deepteal_C55003', 'prd_01HZX081764A2', 'M', 'deep teal', 'SM-DRE-DEE-M'),
  ('var_01HZX081764A2_L_deepteal_39E116', 'prd_01HZX081764A2', 'L', 'deep teal', 'SM-DRE-DEE-L'),
  ('var_01HZX082D4891_XS_burgundy_DB53EB', 'prd_01HZX082D4891', 'XS', 'burgundy', 'SM-DRE-BUR-XS'),
  ('var_01HZX082D4891_S_burgundy_568705', 'prd_01HZX082D4891', 'S', 'burgundy', 'SM-DRE-BUR-S'),
  ('var_01HZX082D4891_M_burgundy_A3647A', 'prd_01HZX082D4891', 'M', 'burgundy', 'SM-DRE-BUR-M'),
  ('var_01HZX082D4891_L_burgundy_5EF3E8', 'prd_01HZX082D4891', 'L', 'burgundy', 'SM-DRE-BUR-L'),
  ('var_01HZX08301444_XS_charcoal_C5A8C3', 'prd_01HZX08301444', 'XS', 'charcoal', 'SM-DRE-CHA-XS'),
  ('var_01HZX08301444_S_charcoal_0ADAE7', 'prd_01HZX08301444', 'S', 'charcoal', 'SM-DRE-CHA-S'),
  ('var_01HZX08301444_M_charcoal_DC2545', 'prd_01HZX08301444', 'M', 'charcoal', 'SM-DRE-CHA-M'),
  ('var_01HZX08301444_L_charcoal_95ED52', 'prd_01HZX08301444', 'L', 'charcoal', 'SM-DRE-CHA-L'),
  ('var_01HZX0843DA3E_XS_coral_C4C546', 'prd_01HZX0843DA3E', 'XS', 'coral', 'SM-DRE-COR-XS');

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX0843DA3E_S_coral_ECB5E1', 'prd_01HZX0843DA3E', 'S', 'coral', 'SM-DRE-COR-S'),
  ('var_01HZX0843DA3E_M_coral_FD49BA', 'prd_01HZX0843DA3E', 'M', 'coral', 'SM-DRE-COR-M'),
  ('var_01HZX0843DA3E_L_coral_E2A257', 'prd_01HZX0843DA3E', 'L', 'coral', 'SM-DRE-COR-L'),
  ('var_01HZX085CDF38_XS_plum_931C7E', 'prd_01HZX085CDF38', 'XS', 'plum', 'SM-DRE-PLU-XS'),
  ('var_01HZX085CDF38_S_plum_5B354F', 'prd_01HZX085CDF38', 'S', 'plum', 'SM-DRE-PLU-S'),
  ('var_01HZX085CDF38_M_plum_A3BC4F', 'prd_01HZX085CDF38', 'M', 'plum', 'SM-DRE-PLU-M'),
  ('var_01HZX085CDF38_L_plum_B832F9', 'prd_01HZX085CDF38', 'L', 'plum', 'SM-DRE-PLU-L'),
  ('var_01HZX08657E3B_XS_olive_5CA21C', 'prd_01HZX08657E3B', 'XS', 'olive', 'SM-DRE-OLI-XS'),
  ('var_01HZX08657E3B_S_olive_EDC88C', 'prd_01HZX08657E3B', 'S', 'olive', 'SM-DRE-OLI-S'),
  ('var_01HZX08657E3B_M_olive_17839E', 'prd_01HZX08657E3B', 'M', 'olive', 'SM-DRE-OLI-M'),
  ('var_01HZX08657E3B_L_olive_493907', 'prd_01HZX08657E3B', 'L', 'olive', 'SM-DRE-OLI-L'),
  ('var_01HZX0874E45A_XS_midnightblue_D27747', 'prd_01HZX0874E45A', 'XS', 'midnight blue', 'SM-DRE-MID-XS'),
  ('var_01HZX0874E45A_S_midnightblue_14DBF8', 'prd_01HZX0874E45A', 'S', 'midnight blue', 'SM-DRE-MID-S'),
  ('var_01HZX0874E45A_M_midnightblue_9C170A', 'prd_01HZX0874E45A', 'M', 'midnight blue', 'SM-DRE-MID-M'),
  ('var_01HZX0874E45A_L_midnightblue_0EA905', 'prd_01HZX0874E45A', 'L', 'midnight blue', 'SM-DRE-MID-L'),
  ('var_01HZX0880B378_XS_blushpink_6DA52B', 'prd_01HZX0880B378', 'XS', 'blush pink', 'SM-DRE-BLU-XS'),
  ('var_01HZX0880B378_S_blushpink_43133C', 'prd_01HZX0880B378', 'S', 'blush pink', 'SM-DRE-BLU-S'),
  ('var_01HZX0880B378_M_blushpink_C0C817', 'prd_01HZX0880B378', 'M', 'blush pink', 'SM-DRE-BLU-M'),
  ('var_01HZX0880B378_L_blushpink_7218A6', 'prd_01HZX0880B378', 'L', 'blush pink', 'SM-DRE-BLU-L'),
  ('var_01HZX0890DDC6_XS_forestgreen_31FDF3', 'prd_01HZX0890DDC6', 'XS', 'forest green', 'SM-DRE-FOR-XS'),
  ('var_01HZX0890DDC6_S_forestgreen_BF05E2', 'prd_01HZX0890DDC6', 'S', 'forest green', 'SM-DRE-FOR-S'),
  ('var_01HZX0890DDC6_M_forestgreen_7EC448', 'prd_01HZX0890DDC6', 'M', 'forest green', 'SM-DRE-FOR-M'),
  ('var_01HZX0890DDC6_L_forestgreen_195804', 'prd_01HZX0890DDC6', 'L', 'forest green', 'SM-DRE-FOR-L'),
  ('var_01HZX090404A1_XS_mustard_050C0C', 'prd_01HZX090404A1', 'XS', 'mustard', 'SM-DRE-MUS-XS'),
  ('var_01HZX090404A1_S_mustard_B9603E', 'prd_01HZX090404A1', 'S', 'mustard', 'SM-DRE-MUS-S'),
  ('var_01HZX090404A1_M_mustard_18EDC5', 'prd_01HZX090404A1', 'M', 'mustard', 'SM-DRE-MUS-M'),
  ('var_01HZX090404A1_L_mustard_FFA616', 'prd_01HZX090404A1', 'L', 'mustard', 'SM-DRE-MUS-L'),
  ('var_01HZX091FD149_XS_lavender_961116', 'prd_01HZX091FD149', 'XS', 'lavender', 'SM-DRE-LAV-XS'),
  ('var_01HZX091FD149_S_lavender_AD9613', 'prd_01HZX091FD149', 'S', 'lavender', 'SM-DRE-LAV-S'),
  ('var_01HZX091FD149_M_lavender_3CC88E', 'prd_01HZX091FD149', 'M', 'lavender', 'SM-DRE-LAV-M'),
  ('var_01HZX091FD149_L_lavender_6EFEE3', 'prd_01HZX091FD149', 'L', 'lavender', 'SM-DRE-LAV-L'),
  ('var_01HZX0924A019_XS_cream_383BBF', 'prd_01HZX0924A019', 'XS', 'cream', 'SM-DRE-CRE-XS'),
  ('var_01HZX0924A019_S_cream_DA8227', 'prd_01HZX0924A019', 'S', 'cream', 'SM-DRE-CRE-S'),
  ('var_01HZX0924A019_M_cream_90060B', 'prd_01HZX0924A019', 'M', 'cream', 'SM-DRE-CRE-M'),
  ('var_01HZX0924A019_L_cream_A79EB8', 'prd_01HZX0924A019', 'L', 'cream', 'SM-DRE-CRE-L'),
  ('var_01HZX09307566_XS_charcoal_22ECB1', 'prd_01HZX09307566', 'XS', 'charcoal', 'SM-SWE-CHA-XS'),
  ('var_01HZX09307566_S_charcoal_18A7B5', 'prd_01HZX09307566', 'S', 'charcoal', 'SM-SWE-CHA-S'),
  ('var_01HZX09307566_M_charcoal_785AC6', 'prd_01HZX09307566', 'M', 'charcoal', 'SM-SWE-CHA-M'),
  ('var_01HZX09307566_L_charcoal_CF5F00', 'prd_01HZX09307566', 'L', 'charcoal', 'SM-SWE-CHA-L'),
  ('var_01HZX09307566_XL_charcoal_F91D4F', 'prd_01HZX09307566', 'XL', 'charcoal', 'SM-SWE-CHA-XL'),
  ('var_01HZX09475580_XS_oatmeal_85ACD3', 'prd_01HZX09475580', 'XS', 'oatmeal', 'SM-SWE-OAT-XS'),
  ('var_01HZX09475580_S_oatmeal_7E7516', 'prd_01HZX09475580', 'S', 'oatmeal', 'SM-SWE-OAT-S'),
  ('var_01HZX09475580_M_oatmeal_B954CE', 'prd_01HZX09475580', 'M', 'oatmeal', 'SM-SWE-OAT-M'),
  ('var_01HZX09475580_L_oatmeal_29FC74', 'prd_01HZX09475580', 'L', 'oatmeal', 'SM-SWE-OAT-L'),
  ('var_01HZX09475580_XL_oatmeal_DCAAE3', 'prd_01HZX09475580', 'XL', 'oatmeal', 'SM-SWE-OAT-XL'),
  ('var_01HZX0952D0E4_XS_forestgreen_A77B28', 'prd_01HZX0952D0E4', 'XS', 'forest green', 'SM-SWE-FOR-XS'),
  ('var_01HZX0952D0E4_S_forestgreen_96B1FE', 'prd_01HZX0952D0E4', 'S', 'forest green', 'SM-SWE-FOR-S'),
  ('var_01HZX0952D0E4_M_forestgreen_E3B876', 'prd_01HZX0952D0E4', 'M', 'forest green', 'SM-SWE-FOR-M'),
  ('var_01HZX0952D0E4_L_forestgreen_0E4AED', 'prd_01HZX0952D0E4', 'L', 'forest green', 'SM-SWE-FOR-L'),
  ('var_01HZX0952D0E4_XL_forestgreen_03573E', 'prd_01HZX0952D0E4', 'XL', 'forest green', 'SM-SWE-FOR-XL'),
  ('var_01HZX096BA323_XS_burgundy_BAB314', 'prd_01HZX096BA323', 'XS', 'burgundy', 'SM-SWE-BUR-XS'),
  ('var_01HZX096BA323_S_burgundy_E9008E', 'prd_01HZX096BA323', 'S', 'burgundy', 'SM-SWE-BUR-S'),
  ('var_01HZX096BA323_M_burgundy_B763F8', 'prd_01HZX096BA323', 'M', 'burgundy', 'SM-SWE-BUR-M'),
  ('var_01HZX096BA323_L_burgundy_4DD334', 'prd_01HZX096BA323', 'L', 'burgundy', 'SM-SWE-BUR-L'),
  ('var_01HZX096BA323_XL_burgundy_5FA399', 'prd_01HZX096BA323', 'XL', 'burgundy', 'SM-SWE-BUR-XL'),
  ('var_01HZX0975A9A5_XS_slate_165FDA', 'prd_01HZX0975A9A5', 'XS', 'slate', 'SM-SWE-SLA-XS'),
  ('var_01HZX0975A9A5_S_slate_053FAB', 'prd_01HZX0975A9A5', 'S', 'slate', 'SM-SWE-SLA-S'),
  ('var_01HZX0975A9A5_M_slate_1DC85D', 'prd_01HZX0975A9A5', 'M', 'slate', 'SM-SWE-SLA-M'),
  ('var_01HZX0975A9A5_L_slate_2E248B', 'prd_01HZX0975A9A5', 'L', 'slate', 'SM-SWE-SLA-L'),
  ('var_01HZX0975A9A5_XL_slate_2CB4E2', 'prd_01HZX0975A9A5', 'XL', 'slate', 'SM-SWE-SLA-XL'),
  ('var_01HZX098C50A4_XS_cream_DFF555', 'prd_01HZX098C50A4', 'XS', 'cream', 'SM-SWE-CRE-XS'),
  ('var_01HZX098C50A4_S_cream_0CE817', 'prd_01HZX098C50A4', 'S', 'cream', 'SM-SWE-CRE-S'),
  ('var_01HZX098C50A4_M_cream_6366A0', 'prd_01HZX098C50A4', 'M', 'cream', 'SM-SWE-CRE-M'),
  ('var_01HZX098C50A4_L_cream_B6D241', 'prd_01HZX098C50A4', 'L', 'cream', 'SM-SWE-CRE-L'),
  ('var_01HZX098C50A4_XL_cream_8D6BB7', 'prd_01HZX098C50A4', 'XL', 'cream', 'SM-SWE-CRE-XL'),
  ('var_01HZX0992C9F9_XS_rust_E3125D', 'prd_01HZX0992C9F9', 'XS', 'rust', 'SM-SWE-RUS-XS'),
  ('var_01HZX0992C9F9_S_rust_FFC134', 'prd_01HZX0992C9F9', 'S', 'rust', 'SM-SWE-RUS-S'),
  ('var_01HZX0992C9F9_M_rust_C66723', 'prd_01HZX0992C9F9', 'M', 'rust', 'SM-SWE-RUS-M'),
  ('var_01HZX0992C9F9_L_rust_FF7A33', 'prd_01HZX0992C9F9', 'L', 'rust', 'SM-SWE-RUS-L'),
  ('var_01HZX0992C9F9_XL_rust_F49EB7', 'prd_01HZX0992C9F9', 'XL', 'rust', 'SM-SWE-RUS-XL'),
  ('var_01HZX10097636_XS_graphite_DDAF9A', 'prd_01HZX10097636', 'XS', 'graphite', 'SM-SWE-GRA-XS'),
  ('var_01HZX10097636_S_graphite_2FCA23', 'prd_01HZX10097636', 'S', 'graphite', 'SM-SWE-GRA-S'),
  ('var_01HZX10097636_M_graphite_5962AB', 'prd_01HZX10097636', 'M', 'graphite', 'SM-SWE-GRA-M'),
  ('var_01HZX10097636_L_graphite_699D81', 'prd_01HZX10097636', 'L', 'graphite', 'SM-SWE-GRA-L'),
  ('var_01HZX10097636_XL_graphite_0828EA', 'prd_01HZX10097636', 'XL', 'graphite', 'SM-SWE-GRA-XL'),
  ('var_01HZX10131F77_XS_ivory_99C467', 'prd_01HZX10131F77', 'XS', 'ivory', 'SM-SWE-IVO-XS'),
  ('var_01HZX10131F77_S_ivory_952A59', 'prd_01HZX10131F77', 'S', 'ivory', 'SM-SWE-IVO-S'),
  ('var_01HZX10131F77_M_ivory_4BDE25', 'prd_01HZX10131F77', 'M', 'ivory', 'SM-SWE-IVO-M'),
  ('var_01HZX10131F77_L_ivory_3CEA48', 'prd_01HZX10131F77', 'L', 'ivory', 'SM-SWE-IVO-L'),
  ('var_01HZX10131F77_XL_ivory_45FFCF', 'prd_01HZX10131F77', 'XL', 'ivory', 'SM-SWE-IVO-XL'),
  ('var_01HZX102C7A4D_XS_steelblue_76B41E', 'prd_01HZX102C7A4D', 'XS', 'steel blue', 'SM-SWE-STE-XS'),
  ('var_01HZX102C7A4D_S_steelblue_605FA3', 'prd_01HZX102C7A4D', 'S', 'steel blue', 'SM-SWE-STE-S'),
  ('var_01HZX102C7A4D_M_steelblue_F7C0EF', 'prd_01HZX102C7A4D', 'M', 'steel blue', 'SM-SWE-STE-M'),
  ('var_01HZX102C7A4D_L_steelblue_F14382', 'prd_01HZX102C7A4D', 'L', 'steel blue', 'SM-SWE-STE-L'),
  ('var_01HZX102C7A4D_XL_steelblue_E73DB0', 'prd_01HZX102C7A4D', 'XL', 'steel blue', 'SM-SWE-STE-XL'),
  ('var_01HZX103049E0_XS_mustard_ABF52C', 'prd_01HZX103049E0', 'XS', 'mustard', 'SM-SWE-MUS-XS'),
  ('var_01HZX103049E0_S_mustard_BAD759', 'prd_01HZX103049E0', 'S', 'mustard', 'SM-SWE-MUS-S'),
  ('var_01HZX103049E0_M_mustard_4677BD', 'prd_01HZX103049E0', 'M', 'mustard', 'SM-SWE-MUS-M'),
  ('var_01HZX103049E0_L_mustard_8F0E27', 'prd_01HZX103049E0', 'L', 'mustard', 'SM-SWE-MUS-L'),
  ('var_01HZX103049E0_XL_mustard_EDC9E1', 'prd_01HZX103049E0', 'XL', 'mustard', 'SM-SWE-MUS-XL'),
  ('var_01HZX10433FC9_XS_plum_E2A919', 'prd_01HZX10433FC9', 'XS', 'plum', 'SM-SWE-PLU-XS'),
  ('var_01HZX10433FC9_S_plum_59495F', 'prd_01HZX10433FC9', 'S', 'plum', 'SM-SWE-PLU-S'),
  ('var_01HZX10433FC9_M_plum_01CF66', 'prd_01HZX10433FC9', 'M', 'plum', 'SM-SWE-PLU-M'),
  ('var_01HZX10433FC9_L_plum_024101', 'prd_01HZX10433FC9', 'L', 'plum', 'SM-SWE-PLU-L'),
  ('var_01HZX10433FC9_XL_plum_FD1862', 'prd_01HZX10433FC9', 'XL', 'plum', 'SM-SWE-PLU-XL'),
  ('var_01HZX1056D522_XS_maroon_7890E9', 'prd_01HZX1056D522', 'XS', 'maroon', 'SM-SWE-MAR-XS'),
  ('var_01HZX1056D522_S_maroon_BED3EF', 'prd_01HZX1056D522', 'S', 'maroon', 'SM-SWE-MAR-S'),
  ('var_01HZX1056D522_M_maroon_D45383', 'prd_01HZX1056D522', 'M', 'maroon', 'SM-SWE-MAR-M'),
  ('var_01HZX1056D522_L_maroon_B98690', 'prd_01HZX1056D522', 'L', 'maroon', 'SM-SWE-MAR-L'),
  ('var_01HZX1056D522_XL_maroon_4CDA53', 'prd_01HZX1056D522', 'XL', 'maroon', 'SM-SWE-MAR-XL'),
  ('var_01HZX10612544_XS_pebblegray_A4704A', 'prd_01HZX10612544', 'XS', 'pebble gray', 'SM-SWE-PEB-XS'),
  ('var_01HZX10612544_S_pebblegray_92AEBB', 'prd_01HZX10612544', 'S', 'pebble gray', 'SM-SWE-PEB-S'),
  ('var_01HZX10612544_M_pebblegray_80E2F9', 'prd_01HZX10612544', 'M', 'pebble gray', 'SM-SWE-PEB-M'),
  ('var_01HZX10612544_L_pebblegray_AB7626', 'prd_01HZX10612544', 'L', 'pebble gray', 'SM-SWE-PEB-L'),
  ('var_01HZX10612544_XL_pebblegray_1C59B9', 'prd_01HZX10612544', 'XL', 'pebble gray', 'SM-SWE-PEB-XL'),
  ('var_01HZX10787D6A_XS_olive_B9C842', 'prd_01HZX10787D6A', 'XS', 'olive', 'SM-RAI-OLI-XS'),
  ('var_01HZX10787D6A_S_olive_584F71', 'prd_01HZX10787D6A', 'S', 'olive', 'SM-RAI-OLI-S'),
  ('var_01HZX10787D6A_M_olive_9E2071', 'prd_01HZX10787D6A', 'M', 'olive', 'SM-RAI-OLI-M'),
  ('var_01HZX10787D6A_L_olive_EA4000', 'prd_01HZX10787D6A', 'L', 'olive', 'SM-RAI-OLI-L'),
  ('var_01HZX10787D6A_XL_olive_25164B', 'prd_01HZX10787D6A', 'XL', 'olive', 'SM-RAI-OLI-XL'),
  ('var_01HZX1084A3F6_XS_navy_06F332', 'prd_01HZX1084A3F6', 'XS', 'navy', 'SM-RAI-NAV-XS'),
  ('var_01HZX1084A3F6_S_navy_D37885', 'prd_01HZX1084A3F6', 'S', 'navy', 'SM-RAI-NAV-S'),
  ('var_01HZX1084A3F6_M_navy_7A596E', 'prd_01HZX1084A3F6', 'M', 'navy', 'SM-RAI-NAV-M'),
  ('var_01HZX1084A3F6_L_navy_E59A65', 'prd_01HZX1084A3F6', 'L', 'navy', 'SM-RAI-NAV-L'),
  ('var_01HZX1084A3F6_XL_navy_A0FAE7', 'prd_01HZX1084A3F6', 'XL', 'navy', 'SM-RAI-NAV-XL'),
  ('var_01HZX1096EF12_XS_translucentblack_77D223', 'prd_01HZX1096EF12', 'XS', 'translucent black', 'SM-RAI-TRA-XS'),
  ('var_01HZX1096EF12_S_translucentblack_F2DE7A', 'prd_01HZX1096EF12', 'S', 'translucent black', 'SM-RAI-TRA-S'),
  ('var_01HZX1096EF12_M_translucentblack_200879', 'prd_01HZX1096EF12', 'M', 'translucent black', 'SM-RAI-TRA-M'),
  ('var_01HZX1096EF12_L_translucentblack_01B10E', 'prd_01HZX1096EF12', 'L', 'translucent black', 'SM-RAI-TRA-L'),
  ('var_01HZX1096EF12_XL_translucentblack_127839', 'prd_01HZX1096EF12', 'XL', 'translucent black', 'SM-RAI-TRA-XL'),
  ('var_01HZX1107C1E2_XS_sand_405EDC', 'prd_01HZX1107C1E2', 'XS', 'sand', 'SM-RAI-SAN-XS'),
  ('var_01HZX1107C1E2_S_sand_518455', 'prd_01HZX1107C1E2', 'S', 'sand', 'SM-RAI-SAN-S'),
  ('var_01HZX1107C1E2_M_sand_78FA7F', 'prd_01HZX1107C1E2', 'M', 'sand', 'SM-RAI-SAN-M'),
  ('var_01HZX1107C1E2_L_sand_9BD170', 'prd_01HZX1107C1E2', 'L', 'sand', 'SM-RAI-SAN-L'),
  ('var_01HZX1107C1E2_XL_sand_8B2CEB', 'prd_01HZX1107C1E2', 'XL', 'sand', 'SM-RAI-SAN-XL'),
  ('var_01HZX111A1816_XS_slategray_E91F0F', 'prd_01HZX111A1816', 'XS', 'slate gray', 'SM-RAI-SLA-XS'),
  ('var_01HZX111A1816_S_slategray_1C2455', 'prd_01HZX111A1816', 'S', 'slate gray', 'SM-RAI-SLA-S'),
  ('var_01HZX111A1816_M_slategray_379583', 'prd_01HZX111A1816', 'M', 'slate gray', 'SM-RAI-SLA-M'),
  ('var_01HZX111A1816_L_slategray_A1CBF5', 'prd_01HZX111A1816', 'L', 'slate gray', 'SM-RAI-SLA-L'),
  ('var_01HZX111A1816_XL_slategray_7A868A', 'prd_01HZX111A1816', 'XL', 'slate gray', 'SM-RAI-SLA-XL'),
  ('var_01HZX11235EA4_XS_butteryellow_3763A0', 'prd_01HZX11235EA4', 'XS', 'butter yellow', 'SM-RAI-BUT-XS'),
  ('var_01HZX11235EA4_S_butteryellow_498CF3', 'prd_01HZX11235EA4', 'S', 'butter yellow', 'SM-RAI-BUT-S'),
  ('var_01HZX11235EA4_M_butteryellow_896B81', 'prd_01HZX11235EA4', 'M', 'butter yellow', 'SM-RAI-BUT-M'),
  ('var_01HZX11235EA4_L_butteryellow_8604E2', 'prd_01HZX11235EA4', 'L', 'butter yellow', 'SM-RAI-BUT-L'),
  ('var_01HZX11235EA4_XL_butteryellow_E4067B', 'prd_01HZX11235EA4', 'XL', 'butter yellow', 'SM-RAI-BUT-XL'),
  ('var_01HZX11384678_XS_forestgreen_512B35', 'prd_01HZX11384678', 'XS', 'forest green', 'SM-RAI-FOR-XS'),
  ('var_01HZX11384678_S_forestgreen_F3ECF2', 'prd_01HZX11384678', 'S', 'forest green', 'SM-RAI-FOR-S'),
  ('var_01HZX11384678_M_forestgreen_E53EA5', 'prd_01HZX11384678', 'M', 'forest green', 'SM-RAI-FOR-M'),
  ('var_01HZX11384678_L_forestgreen_1378A8', 'prd_01HZX11384678', 'L', 'forest green', 'SM-RAI-FOR-L'),
  ('var_01HZX11384678_XL_forestgreen_010578', 'prd_01HZX11384678', 'XL', 'forest green', 'SM-RAI-FOR-XL'),
  ('var_01HZX11402B03_XS_charcoal_378B52', 'prd_01HZX11402B03', 'XS', 'charcoal', 'SM-RAI-CHA-XS'),
  ('var_01HZX11402B03_S_charcoal_8A4C07', 'prd_01HZX11402B03', 'S', 'charcoal', 'SM-RAI-CHA-S'),
  ('var_01HZX11402B03_M_charcoal_27C035', 'prd_01HZX11402B03', 'M', 'charcoal', 'SM-RAI-CHA-M'),
  ('var_01HZX11402B03_L_charcoal_333758', 'prd_01HZX11402B03', 'L', 'charcoal', 'SM-RAI-CHA-L'),
  ('var_01HZX11402B03_XL_charcoal_5F8BCD', 'prd_01HZX11402B03', 'XL', 'charcoal', 'SM-RAI-CHA-XL'),
  ('var_01HZX115C0A4D_XS_midnightblue_CFB5A2', 'prd_01HZX115C0A4D', 'XS', 'midnight blue', 'SM-RAI-MID-XS'),
  ('var_01HZX115C0A4D_S_midnightblue_5ADA76', 'prd_01HZX115C0A4D', 'S', 'midnight blue', 'SM-RAI-MID-S'),
  ('var_01HZX115C0A4D_M_midnightblue_1D68E7', 'prd_01HZX115C0A4D', 'M', 'midnight blue', 'SM-RAI-MID-M'),
  ('var_01HZX115C0A4D_L_midnightblue_1EA57B', 'prd_01HZX115C0A4D', 'L', 'midnight blue', 'SM-RAI-MID-L'),
  ('var_01HZX115C0A4D_XL_midnightblue_DD4537', 'prd_01HZX115C0A4D', 'XL', 'midnight blue', 'SM-RAI-MID-XL'),
  ('var_01HZX116F83B6_XS_camel_A0FFB9', 'prd_01HZX116F83B6', 'XS', 'camel', 'SM-RAI-CAM-XS'),
  ('var_01HZX116F83B6_S_camel_CB3ED5', 'prd_01HZX116F83B6', 'S', 'camel', 'SM-RAI-CAM-S'),
  ('var_01HZX116F83B6_M_camel_AFE20C', 'prd_01HZX116F83B6', 'M', 'camel', 'SM-RAI-CAM-M'),
  ('var_01HZX116F83B6_L_camel_66FD1A', 'prd_01HZX116F83B6', 'L', 'camel', 'SM-RAI-CAM-L'),
  ('var_01HZX116F83B6_XL_camel_8FFFF0', 'prd_01HZX116F83B6', 'XL', 'camel', 'SM-RAI-CAM-XL'),
  ('var_01HZX11761294_7_white_E5738F', 'prd_01HZX11761294', '7', 'white', 'SM-SNE-WHI-7'),
  ('var_01HZX11761294_8_white_882E35', 'prd_01HZX11761294', '8', 'white', 'SM-SNE-WHI-8'),
  ('var_01HZX11761294_9_white_D7F81E', 'prd_01HZX11761294', '9', 'white', 'SM-SNE-WHI-9'),
  ('var_01HZX11761294_10_white_C3F773', 'prd_01HZX11761294', '10', 'white', 'SM-SNE-WHI-10'),
  ('var_01HZX11761294_11_white_B36D23', 'prd_01HZX11761294', '11', 'white', 'SM-SNE-WHI-11'),
  ('var_01HZX11761294_12_white_2CFEFB', 'prd_01HZX11761294', '12', 'white', 'SM-SNE-WHI-12'),
  ('var_01HZX1187129E_7_offwhite_87E5E5', 'prd_01HZX1187129E', '7', 'off white', 'SM-SNE-OFF-7'),
  ('var_01HZX1187129E_8_offwhite_AEDF72', 'prd_01HZX1187129E', '8', 'off white', 'SM-SNE-OFF-8'),
  ('var_01HZX1187129E_9_offwhite_25054C', 'prd_01HZX1187129E', '9', 'off white', 'SM-SNE-OFF-9'),
  ('var_01HZX1187129E_10_offwhite_1216F6', 'prd_01HZX1187129E', '10', 'off white', 'SM-SNE-OFF-10'),
  ('var_01HZX1187129E_11_offwhite_27A5B9', 'prd_01HZX1187129E', '11', 'off white', 'SM-SNE-OFF-11'),
  ('var_01HZX1187129E_12_offwhite_B7E920', 'prd_01HZX1187129E', '12', 'off white', 'SM-SNE-OFF-12'),
  ('var_01HZX119D1277_7_cream_4843BC', 'prd_01HZX119D1277', '7', 'cream', 'SM-SNE-CRE-7'),
  ('var_01HZX119D1277_8_cream_C7D088', 'prd_01HZX119D1277', '8', 'cream', 'SM-SNE-CRE-8'),
  ('var_01HZX119D1277_9_cream_DC077D', 'prd_01HZX119D1277', '9', 'cream', 'SM-SNE-CRE-9'),
  ('var_01HZX119D1277_10_cream_DAC887', 'prd_01HZX119D1277', '10', 'cream', 'SM-SNE-CRE-10'),
  ('var_01HZX119D1277_11_cream_E851EB', 'prd_01HZX119D1277', '11', 'cream', 'SM-SNE-CRE-11'),
  ('var_01HZX119D1277_12_cream_CDF095', 'prd_01HZX119D1277', '12', 'cream', 'SM-SNE-CRE-12'),
  ('var_01HZX120F9C60_7_navy_46DA49', 'prd_01HZX120F9C60', '7', 'navy', 'SM-SNE-NAV-7'),
  ('var_01HZX120F9C60_8_navy_5C47D1', 'prd_01HZX120F9C60', '8', 'navy', 'SM-SNE-NAV-8'),
  ('var_01HZX120F9C60_9_navy_1A1F0D', 'prd_01HZX120F9C60', '9', 'navy', 'SM-SNE-NAV-9');

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX120F9C60_10_navy_2CBE83', 'prd_01HZX120F9C60', '10', 'navy', 'SM-SNE-NAV-10'),
  ('var_01HZX120F9C60_11_navy_224A71', 'prd_01HZX120F9C60', '11', 'navy', 'SM-SNE-NAV-11'),
  ('var_01HZX120F9C60_12_navy_2D2F4D', 'prd_01HZX120F9C60', '12', 'navy', 'SM-SNE-NAV-12'),
  ('var_01HZX1215905A_7_allblack_9223A6', 'prd_01HZX1215905A', '7', 'all black', 'SM-SNE-ALL-7'),
  ('var_01HZX1215905A_8_allblack_34D779', 'prd_01HZX1215905A', '8', 'all black', 'SM-SNE-ALL-8'),
  ('var_01HZX1215905A_9_allblack_CA144E', 'prd_01HZX1215905A', '9', 'all black', 'SM-SNE-ALL-9'),
  ('var_01HZX1215905A_10_allblack_7D29A3', 'prd_01HZX1215905A', '10', 'all black', 'SM-SNE-ALL-10'),
  ('var_01HZX1215905A_11_allblack_B16B03', 'prd_01HZX1215905A', '11', 'all black', 'SM-SNE-ALL-11'),
  ('var_01HZX1215905A_12_allblack_B97B75', 'prd_01HZX1215905A', '12', 'all black', 'SM-SNE-ALL-12'),
  ('var_01HZX122D9B14_7_gray_18A0C0', 'prd_01HZX122D9B14', '7', 'gray', 'SM-SNE-GRA-7'),
  ('var_01HZX122D9B14_8_gray_1BC732', 'prd_01HZX122D9B14', '8', 'gray', 'SM-SNE-GRA-8'),
  ('var_01HZX122D9B14_9_gray_E2D96A', 'prd_01HZX122D9B14', '9', 'gray', 'SM-SNE-GRA-9'),
  ('var_01HZX122D9B14_10_gray_1A2E55', 'prd_01HZX122D9B14', '10', 'gray', 'SM-SNE-GRA-10'),
  ('var_01HZX122D9B14_11_gray_D7D739', 'prd_01HZX122D9B14', '11', 'gray', 'SM-SNE-GRA-11'),
  ('var_01HZX122D9B14_12_gray_2442E9', 'prd_01HZX122D9B14', '12', 'gray', 'SM-SNE-GRA-12'),
  ('var_01HZX123E4094_7_olive_A0062D', 'prd_01HZX123E4094', '7', 'olive', 'SM-SNE-OLI-7'),
  ('var_01HZX123E4094_8_olive_633A2D', 'prd_01HZX123E4094', '8', 'olive', 'SM-SNE-OLI-8'),
  ('var_01HZX123E4094_9_olive_C6240A', 'prd_01HZX123E4094', '9', 'olive', 'SM-SNE-OLI-9'),
  ('var_01HZX123E4094_10_olive_344BC7', 'prd_01HZX123E4094', '10', 'olive', 'SM-SNE-OLI-10'),
  ('var_01HZX123E4094_11_olive_0B3950', 'prd_01HZX123E4094', '11', 'olive', 'SM-SNE-OLI-11'),
  ('var_01HZX123E4094_12_olive_DE8ACF', 'prd_01HZX123E4094', '12', 'olive', 'SM-SNE-OLI-12'),
  ('var_01HZX1247FAD9_7_sand_9723B6', 'prd_01HZX1247FAD9', '7', 'sand', 'SM-SNE-SAN-7'),
  ('var_01HZX1247FAD9_8_sand_D7C2FB', 'prd_01HZX1247FAD9', '8', 'sand', 'SM-SNE-SAN-8'),
  ('var_01HZX1247FAD9_9_sand_00E389', 'prd_01HZX1247FAD9', '9', 'sand', 'SM-SNE-SAN-9'),
  ('var_01HZX1247FAD9_10_sand_7FC638', 'prd_01HZX1247FAD9', '10', 'sand', 'SM-SNE-SAN-10'),
  ('var_01HZX1247FAD9_11_sand_46CF5E', 'prd_01HZX1247FAD9', '11', 'sand', 'SM-SNE-SAN-11'),
  ('var_01HZX1247FAD9_12_sand_D748B1', 'prd_01HZX1247FAD9', '12', 'sand', 'SM-SNE-SAN-12'),
  ('var_01HZX125AC267_7_charcoal_FE5CA7', 'prd_01HZX125AC267', '7', 'charcoal', 'SM-SNE-CHA-7'),
  ('var_01HZX125AC267_8_charcoal_9BD799', 'prd_01HZX125AC267', '8', 'charcoal', 'SM-SNE-CHA-8'),
  ('var_01HZX125AC267_9_charcoal_84E887', 'prd_01HZX125AC267', '9', 'charcoal', 'SM-SNE-CHA-9'),
  ('var_01HZX125AC267_10_charcoal_E62E53', 'prd_01HZX125AC267', '10', 'charcoal', 'SM-SNE-CHA-10'),
  ('var_01HZX125AC267_11_charcoal_6F1236', 'prd_01HZX125AC267', '11', 'charcoal', 'SM-SNE-CHA-11'),
  ('var_01HZX125AC267_12_charcoal_DB52A6', 'prd_01HZX125AC267', '12', 'charcoal', 'SM-SNE-CHA-12'),
  ('var_01HZX12691BDE_7_lightgray_6957FC', 'prd_01HZX12691BDE', '7', 'light gray', 'SM-SNE-LIG-7'),
  ('var_01HZX12691BDE_8_lightgray_625B70', 'prd_01HZX12691BDE', '8', 'light gray', 'SM-SNE-LIG-8'),
  ('var_01HZX12691BDE_9_lightgray_E5038F', 'prd_01HZX12691BDE', '9', 'light gray', 'SM-SNE-LIG-9'),
  ('var_01HZX12691BDE_10_lightgray_53D9DE', 'prd_01HZX12691BDE', '10', 'light gray', 'SM-SNE-LIG-10'),
  ('var_01HZX12691BDE_11_lightgray_B825C0', 'prd_01HZX12691BDE', '11', 'light gray', 'SM-SNE-LIG-11'),
  ('var_01HZX12691BDE_12_lightgray_C2A71E', 'prd_01HZX12691BDE', '12', 'light gray', 'SM-SNE-LIG-12'),
  ('var_01HZX127232F6_7_beige_E953D6', 'prd_01HZX127232F6', '7', 'beige', 'SM-SNE-BEI-7'),
  ('var_01HZX127232F6_8_beige_5D971C', 'prd_01HZX127232F6', '8', 'beige', 'SM-SNE-BEI-8'),
  ('var_01HZX127232F6_9_beige_A5DC85', 'prd_01HZX127232F6', '9', 'beige', 'SM-SNE-BEI-9'),
  ('var_01HZX127232F6_10_beige_5A7E53', 'prd_01HZX127232F6', '10', 'beige', 'SM-SNE-BEI-10'),
  ('var_01HZX127232F6_11_beige_8D8FA2', 'prd_01HZX127232F6', '11', 'beige', 'SM-SNE-BEI-11'),
  ('var_01HZX127232F6_12_beige_596CFC', 'prd_01HZX127232F6', '12', 'beige', 'SM-SNE-BEI-12'),
  ('var_01HZX12889982_7_skyblue_17D5DD', 'prd_01HZX12889982', '7', 'sky blue', 'SM-SNE-SKY-7'),
  ('var_01HZX12889982_8_skyblue_267AE3', 'prd_01HZX12889982', '8', 'sky blue', 'SM-SNE-SKY-8'),
  ('var_01HZX12889982_9_skyblue_DD05FA', 'prd_01HZX12889982', '9', 'sky blue', 'SM-SNE-SKY-9'),
  ('var_01HZX12889982_10_skyblue_2472FA', 'prd_01HZX12889982', '10', 'sky blue', 'SM-SNE-SKY-10'),
  ('var_01HZX12889982_11_skyblue_1B5C01', 'prd_01HZX12889982', '11', 'sky blue', 'SM-SNE-SKY-11'),
  ('var_01HZX12889982_12_skyblue_6E18C8', 'prd_01HZX12889982', '12', 'sky blue', 'SM-SNE-SKY-12'),
  ('var_01HZX1291DA14_7_taupe_5B6623', 'prd_01HZX1291DA14', '7', 'taupe', 'SM-SNE-TAU-7'),
  ('var_01HZX1291DA14_8_taupe_FE4D8B', 'prd_01HZX1291DA14', '8', 'taupe', 'SM-SNE-TAU-8'),
  ('var_01HZX1291DA14_9_taupe_7B4F87', 'prd_01HZX1291DA14', '9', 'taupe', 'SM-SNE-TAU-9'),
  ('var_01HZX1291DA14_10_taupe_FF3B0F', 'prd_01HZX1291DA14', '10', 'taupe', 'SM-SNE-TAU-10'),
  ('var_01HZX1291DA14_11_taupe_68026D', 'prd_01HZX1291DA14', '11', 'taupe', 'SM-SNE-TAU-11'),
  ('var_01HZX1291DA14_12_taupe_89815E', 'prd_01HZX1291DA14', '12', 'taupe', 'SM-SNE-TAU-12'),
  ('var_01HZX13080265_7_ivory_4F79C0', 'prd_01HZX13080265', '7', 'ivory', 'SM-SNE-IVO-7'),
  ('var_01HZX13080265_8_ivory_C7754A', 'prd_01HZX13080265', '8', 'ivory', 'SM-SNE-IVO-8'),
  ('var_01HZX13080265_9_ivory_D6C34A', 'prd_01HZX13080265', '9', 'ivory', 'SM-SNE-IVO-9'),
  ('var_01HZX13080265_10_ivory_B733C3', 'prd_01HZX13080265', '10', 'ivory', 'SM-SNE-IVO-10'),
  ('var_01HZX13080265_11_ivory_CF5298', 'prd_01HZX13080265', '11', 'ivory', 'SM-SNE-IVO-11'),
  ('var_01HZX13080265_12_ivory_3625A8', 'prd_01HZX13080265', '12', 'ivory', 'SM-SNE-IVO-12'),
  ('var_01HZX13136F77_7_slate_4F4CB4', 'prd_01HZX13136F77', '7', 'slate', 'SM-SNE-SLA-7'),
  ('var_01HZX13136F77_8_slate_EBD58F', 'prd_01HZX13136F77', '8', 'slate', 'SM-SNE-SLA-8'),
  ('var_01HZX13136F77_9_slate_AD531B', 'prd_01HZX13136F77', '9', 'slate', 'SM-SNE-SLA-9'),
  ('var_01HZX13136F77_10_slate_1221D4', 'prd_01HZX13136F77', '10', 'slate', 'SM-SNE-SLA-10'),
  ('var_01HZX13136F77_11_slate_DA551D', 'prd_01HZX13136F77', '11', 'slate', 'SM-SNE-SLA-11'),
  ('var_01HZX13136F77_12_slate_55204A', 'prd_01HZX13136F77', '12', 'slate', 'SM-SNE-SLA-12'),
  ('var_01HZX132713B9_7_white_373E0E', 'prd_01HZX132713B9', '7', 'white', 'SM-SNE-WHI-7'),
  ('var_01HZX132713B9_8_white_0F55EF', 'prd_01HZX132713B9', '8', 'white', 'SM-SNE-WHI-8'),
  ('var_01HZX132713B9_9_white_4C07D5', 'prd_01HZX132713B9', '9', 'white', 'SM-SNE-WHI-9'),
  ('var_01HZX132713B9_10_white_870E5C', 'prd_01HZX132713B9', '10', 'white', 'SM-SNE-WHI-10'),
  ('var_01HZX132713B9_11_white_B9CCFC', 'prd_01HZX132713B9', '11', 'white', 'SM-SNE-WHI-11'),
  ('var_01HZX132713B9_12_white_70FDE7', 'prd_01HZX132713B9', '12', 'white', 'SM-SNE-WHI-12'),
  ('var_01HZX133BF1C8_7_black_2B51AB', 'prd_01HZX133BF1C8', '7', 'black', 'SM-FOR-BLA-7'),
  ('var_01HZX133BF1C8_8_black_0AAFED', 'prd_01HZX133BF1C8', '8', 'black', 'SM-FOR-BLA-8'),
  ('var_01HZX133BF1C8_9_black_BF51D3', 'prd_01HZX133BF1C8', '9', 'black', 'SM-FOR-BLA-9'),
  ('var_01HZX133BF1C8_10_black_28B514', 'prd_01HZX133BF1C8', '10', 'black', 'SM-FOR-BLA-10'),
  ('var_01HZX133BF1C8_11_black_1DE234', 'prd_01HZX133BF1C8', '11', 'black', 'SM-FOR-BLA-11'),
  ('var_01HZX133BF1C8_12_black_A878E4', 'prd_01HZX133BF1C8', '12', 'black', 'SM-FOR-BLA-12'),
  ('var_01HZX134D5B9A_7_darkbrown_CA983E', 'prd_01HZX134D5B9A', '7', 'dark brown', 'SM-FOR-DAR-7'),
  ('var_01HZX134D5B9A_8_darkbrown_EF81C6', 'prd_01HZX134D5B9A', '8', 'dark brown', 'SM-FOR-DAR-8'),
  ('var_01HZX134D5B9A_9_darkbrown_04314D', 'prd_01HZX134D5B9A', '9', 'dark brown', 'SM-FOR-DAR-9'),
  ('var_01HZX134D5B9A_10_darkbrown_F8DE36', 'prd_01HZX134D5B9A', '10', 'dark brown', 'SM-FOR-DAR-10'),
  ('var_01HZX134D5B9A_11_darkbrown_CC8A4C', 'prd_01HZX134D5B9A', '11', 'dark brown', 'SM-FOR-DAR-11'),
  ('var_01HZX134D5B9A_12_darkbrown_23E82C', 'prd_01HZX134D5B9A', '12', 'dark brown', 'SM-FOR-DAR-12'),
  ('var_01HZX135E48B5_7_oxblood_75CB28', 'prd_01HZX135E48B5', '7', 'oxblood', 'SM-FOR-OXB-7'),
  ('var_01HZX135E48B5_8_oxblood_C98245', 'prd_01HZX135E48B5', '8', 'oxblood', 'SM-FOR-OXB-8'),
  ('var_01HZX135E48B5_9_oxblood_4D9BEE', 'prd_01HZX135E48B5', '9', 'oxblood', 'SM-FOR-OXB-9'),
  ('var_01HZX135E48B5_10_oxblood_854615', 'prd_01HZX135E48B5', '10', 'oxblood', 'SM-FOR-OXB-10'),
  ('var_01HZX135E48B5_11_oxblood_437AD7', 'prd_01HZX135E48B5', '11', 'oxblood', 'SM-FOR-OXB-11'),
  ('var_01HZX135E48B5_12_oxblood_50AAFB', 'prd_01HZX135E48B5', '12', 'oxblood', 'SM-FOR-OXB-12'),
  ('var_01HZX136DAFED_7_tan_D3C7DD', 'prd_01HZX136DAFED', '7', 'tan', 'SM-FOR-TAN-7'),
  ('var_01HZX136DAFED_8_tan_D4A558', 'prd_01HZX136DAFED', '8', 'tan', 'SM-FOR-TAN-8'),
  ('var_01HZX136DAFED_9_tan_AE8B4C', 'prd_01HZX136DAFED', '9', 'tan', 'SM-FOR-TAN-9'),
  ('var_01HZX136DAFED_10_tan_EFF64B', 'prd_01HZX136DAFED', '10', 'tan', 'SM-FOR-TAN-10'),
  ('var_01HZX136DAFED_11_tan_60E450', 'prd_01HZX136DAFED', '11', 'tan', 'SM-FOR-TAN-11'),
  ('var_01HZX136DAFED_12_tan_8D91D4', 'prd_01HZX136DAFED', '12', 'tan', 'SM-FOR-TAN-12'),
  ('var_01HZX137A036C_7_walnut_91E976', 'prd_01HZX137A036C', '7', 'walnut', 'SM-FOR-WAL-7'),
  ('var_01HZX137A036C_8_walnut_14AD39', 'prd_01HZX137A036C', '8', 'walnut', 'SM-FOR-WAL-8'),
  ('var_01HZX137A036C_9_walnut_81D135', 'prd_01HZX137A036C', '9', 'walnut', 'SM-FOR-WAL-9'),
  ('var_01HZX137A036C_10_walnut_3BA5D6', 'prd_01HZX137A036C', '10', 'walnut', 'SM-FOR-WAL-10'),
  ('var_01HZX137A036C_11_walnut_F6EDA6', 'prd_01HZX137A036C', '11', 'walnut', 'SM-FOR-WAL-11'),
  ('var_01HZX137A036C_12_walnut_ED97F6', 'prd_01HZX137A036C', '12', 'walnut', 'SM-FOR-WAL-12'),
  ('var_01HZX13862E11_7_black_8D202D', 'prd_01HZX13862E11', '7', 'black', 'SM-FOR-BLA-7'),
  ('var_01HZX13862E11_8_black_20A21F', 'prd_01HZX13862E11', '8', 'black', 'SM-FOR-BLA-8'),
  ('var_01HZX13862E11_9_black_CE7BEB', 'prd_01HZX13862E11', '9', 'black', 'SM-FOR-BLA-9'),
  ('var_01HZX13862E11_10_black_8A7EA6', 'prd_01HZX13862E11', '10', 'black', 'SM-FOR-BLA-10'),
  ('var_01HZX13862E11_11_black_5DB51A', 'prd_01HZX13862E11', '11', 'black', 'SM-FOR-BLA-11'),
  ('var_01HZX13862E11_12_black_7926ED', 'prd_01HZX13862E11', '12', 'black', 'SM-FOR-BLA-12'),
  ('var_01HZX139E8725_7_cognac_11DCBE', 'prd_01HZX139E8725', '7', 'cognac', 'SM-FOR-COG-7'),
  ('var_01HZX139E8725_8_cognac_F8BFFC', 'prd_01HZX139E8725', '8', 'cognac', 'SM-FOR-COG-8'),
  ('var_01HZX139E8725_9_cognac_64AD84', 'prd_01HZX139E8725', '9', 'cognac', 'SM-FOR-COG-9'),
  ('var_01HZX139E8725_10_cognac_89612F', 'prd_01HZX139E8725', '10', 'cognac', 'SM-FOR-COG-10'),
  ('var_01HZX139E8725_11_cognac_8E859E', 'prd_01HZX139E8725', '11', 'cognac', 'SM-FOR-COG-11'),
  ('var_01HZX139E8725_12_cognac_C60C30', 'prd_01HZX139E8725', '12', 'cognac', 'SM-FOR-COG-12'),
  ('var_01HZX140A9006_7_charcoal_1D8566', 'prd_01HZX140A9006', '7', 'charcoal', 'SM-FOR-CHA-7'),
  ('var_01HZX140A9006_8_charcoal_F4874E', 'prd_01HZX140A9006', '8', 'charcoal', 'SM-FOR-CHA-8'),
  ('var_01HZX140A9006_9_charcoal_594DB9', 'prd_01HZX140A9006', '9', 'charcoal', 'SM-FOR-CHA-9'),
  ('var_01HZX140A9006_10_charcoal_5FD179', 'prd_01HZX140A9006', '10', 'charcoal', 'SM-FOR-CHA-10'),
  ('var_01HZX140A9006_11_charcoal_4947D7', 'prd_01HZX140A9006', '11', 'charcoal', 'SM-FOR-CHA-11'),
  ('var_01HZX140A9006_12_charcoal_88CD82', 'prd_01HZX140A9006', '12', 'charcoal', 'SM-FOR-CHA-12'),
  ('var_01HZX14183BB7_7_midnightblue_D6B44A', 'prd_01HZX14183BB7', '7', 'midnight blue', 'SM-FOR-MID-7'),
  ('var_01HZX14183BB7_8_midnightblue_17A99A', 'prd_01HZX14183BB7', '8', 'midnight blue', 'SM-FOR-MID-8'),
  ('var_01HZX14183BB7_9_midnightblue_A565E5', 'prd_01HZX14183BB7', '9', 'midnight blue', 'SM-FOR-MID-9'),
  ('var_01HZX14183BB7_10_midnightblue_42487D', 'prd_01HZX14183BB7', '10', 'midnight blue', 'SM-FOR-MID-10'),
  ('var_01HZX14183BB7_11_midnightblue_30A59D', 'prd_01HZX14183BB7', '11', 'midnight blue', 'SM-FOR-MID-11'),
  ('var_01HZX14183BB7_12_midnightblue_4C7CEE', 'prd_01HZX14183BB7', '12', 'midnight blue', 'SM-FOR-MID-12'),
  ('var_01HZX1422D279_7_espresso_04020D', 'prd_01HZX1422D279', '7', 'espresso', 'SM-FOR-ESP-7'),
  ('var_01HZX1422D279_8_espresso_57618A', 'prd_01HZX1422D279', '8', 'espresso', 'SM-FOR-ESP-8'),
  ('var_01HZX1422D279_9_espresso_C7B248', 'prd_01HZX1422D279', '9', 'espresso', 'SM-FOR-ESP-9'),
  ('var_01HZX1422D279_10_espresso_9AAC59', 'prd_01HZX1422D279', '10', 'espresso', 'SM-FOR-ESP-10'),
  ('var_01HZX1422D279_11_espresso_4207D2', 'prd_01HZX1422D279', '11', 'espresso', 'SM-FOR-ESP-11'),
  ('var_01HZX1422D279_12_espresso_817051', 'prd_01HZX1422D279', '12', 'espresso', 'SM-FOR-ESP-12'),
  ('var_01HZX14302FF2_7_sand_50E9C2', 'prd_01HZX14302FF2', '7', 'sand', 'SM-FOR-SAN-7'),
  ('var_01HZX14302FF2_8_sand_C30BB6', 'prd_01HZX14302FF2', '8', 'sand', 'SM-FOR-SAN-8'),
  ('var_01HZX14302FF2_9_sand_FB2050', 'prd_01HZX14302FF2', '9', 'sand', 'SM-FOR-SAN-9'),
  ('var_01HZX14302FF2_10_sand_364202', 'prd_01HZX14302FF2', '10', 'sand', 'SM-FOR-SAN-10'),
  ('var_01HZX14302FF2_11_sand_195A21', 'prd_01HZX14302FF2', '11', 'sand', 'SM-FOR-SAN-11'),
  ('var_01HZX14302FF2_12_sand_7175DE', 'prd_01HZX14302FF2', '12', 'sand', 'SM-FOR-SAN-12'),
  ('var_01HZX1446DC9A_7_burgundy_6E8EC1', 'prd_01HZX1446DC9A', '7', 'burgundy', 'SM-FOR-BUR-7'),
  ('var_01HZX1446DC9A_8_burgundy_1D1FD2', 'prd_01HZX1446DC9A', '8', 'burgundy', 'SM-FOR-BUR-8'),
  ('var_01HZX1446DC9A_9_burgundy_971123', 'prd_01HZX1446DC9A', '9', 'burgundy', 'SM-FOR-BUR-9'),
  ('var_01HZX1446DC9A_10_burgundy_61C288', 'prd_01HZX1446DC9A', '10', 'burgundy', 'SM-FOR-BUR-10'),
  ('var_01HZX1446DC9A_11_burgundy_B09E90', 'prd_01HZX1446DC9A', '11', 'burgundy', 'SM-FOR-BUR-11'),
  ('var_01HZX1446DC9A_12_burgundy_96AE70', 'prd_01HZX1446DC9A', '12', 'burgundy', 'SM-FOR-BUR-12'),
  ('var_01HZX145F81B7_7_graphite_F9344B', 'prd_01HZX145F81B7', '7', 'graphite', 'SM-FOR-GRA-7'),
  ('var_01HZX145F81B7_8_graphite_74EF65', 'prd_01HZX145F81B7', '8', 'graphite', 'SM-FOR-GRA-8'),
  ('var_01HZX145F81B7_9_graphite_60CBE7', 'prd_01HZX145F81B7', '9', 'graphite', 'SM-FOR-GRA-9'),
  ('var_01HZX145F81B7_10_graphite_C0CB0F', 'prd_01HZX145F81B7', '10', 'graphite', 'SM-FOR-GRA-10'),
  ('var_01HZX145F81B7_11_graphite_392A1C', 'prd_01HZX145F81B7', '11', 'graphite', 'SM-FOR-GRA-11'),
  ('var_01HZX145F81B7_12_graphite_79E95F', 'prd_01HZX145F81B7', '12', 'graphite', 'SM-FOR-GRA-12'),
  ('var_01HZX146DC626_7_camel_61DCE2', 'prd_01HZX146DC626', '7', 'camel', 'SM-FOR-CAM-7'),
  ('var_01HZX146DC626_8_camel_84392B', 'prd_01HZX146DC626', '8', 'camel', 'SM-FOR-CAM-8'),
  ('var_01HZX146DC626_9_camel_685E3B', 'prd_01HZX146DC626', '9', 'camel', 'SM-FOR-CAM-9'),
  ('var_01HZX146DC626_10_camel_61B881', 'prd_01HZX146DC626', '10', 'camel', 'SM-FOR-CAM-10'),
  ('var_01HZX146DC626_11_camel_0EE6B4', 'prd_01HZX146DC626', '11', 'camel', 'SM-FOR-CAM-11'),
  ('var_01HZX146DC626_12_camel_9AF21A', 'prd_01HZX146DC626', '12', 'camel', 'SM-FOR-CAM-12'),
  ('var_01HZX147B19E0_ONE_SIZE_black_4635F2', 'prd_01HZX147B19E0', 'ONE_SIZE', 'black', 'SM-BAC-BLA-ONESIZE'),
  ('var_01HZX148501A3_ONE_SIZE_charcoal_64C39E', 'prd_01HZX148501A3', 'ONE_SIZE', 'charcoal', 'SM-BAC-CHA-ONESIZE'),
  ('var_01HZX1494D48D_ONE_SIZE_olive_04123F', 'prd_01HZX1494D48D', 'ONE_SIZE', 'olive', 'SM-BAC-OLI-ONESIZE'),
  ('var_01HZX1505B8A8_ONE_SIZE_navy_4E4BE0', 'prd_01HZX1505B8A8', 'ONE_SIZE', 'navy', 'SM-BAC-NAV-ONESIZE'),
  ('var_01HZX151036EE_ONE_SIZE_sand_926955', 'prd_01HZX151036EE', 'ONE_SIZE', 'sand', 'SM-BAC-SAN-ONESIZE'),
  ('var_01HZX152E9B46_ONE_SIZE_slate_080848', 'prd_01HZX152E9B46', 'ONE_SIZE', 'slate', 'SM-BAC-SLA-ONESIZE'),
  ('var_01HZX1537264B_ONE_SIZE_forestgreen_0ADB6E', 'prd_01HZX1537264B', 'ONE_SIZE', 'forest green', 'SM-BAC-FOR-ONESIZE'),
  ('var_01HZX154A2535_ONE_SIZE_tan_CD0706', 'prd_01HZX154A2535', 'ONE_SIZE', 'tan', 'SM-BAC-TAN-ONESIZE'),
  ('var_01HZX15535D86_ONE_SIZE_graphite_5FAE5F', 'prd_01HZX15535D86', 'ONE_SIZE', 'graphite', 'SM-BAC-GRA-ONESIZE'),
  ('var_01HZX156A0986_ONE_SIZE_burgundy_765CFD', 'prd_01HZX156A0986', 'ONE_SIZE', 'burgundy', 'SM-BAC-BUR-ONESIZE'),
  ('var_01HZX15734629_ONE_SIZE_stone_7C24A0', 'prd_01HZX15734629', 'ONE_SIZE', 'stone', 'SM-BAC-STO-ONESIZE'),
  ('var_01HZX158EC477_ONE_SIZE_steelblue_702E3E', 'prd_01HZX158EC477', 'ONE_SIZE', 'steel blue', 'SM-BAC-STE-ONESIZE'),
  ('var_01HZX15904744_ONE_SIZE_tortoise_66EA5B', 'prd_01HZX15904744', 'ONE_SIZE', 'tortoise', 'SM-SUN-TOR-ONESIZE'),
  ('var_01HZX160B757F_ONE_SIZE_matteblack_4D99ED', 'prd_01HZX160B757F', 'ONE_SIZE', 'matte black', 'SM-SUN-MAT-ONESIZE'),
  ('var_01HZX161A7F7D_ONE_SIZE_gunmetal_DECED0', 'prd_01HZX161A7F7D', 'ONE_SIZE', 'gunmetal', 'SM-SUN-GUN-ONESIZE'),
  ('var_01HZX162BE15C_ONE_SIZE_clear_713087', 'prd_01HZX162BE15C', 'ONE_SIZE', 'clear', 'SM-SUN-CLE-ONESIZE'),
  ('var_01HZX16343326_ONE_SIZE_brown_FE100E', 'prd_01HZX16343326', 'ONE_SIZE', 'brown', 'SM-SUN-BRO-ONESIZE'),
  ('var_01HZX16429B41_ONE_SIZE_matteblack_298217', 'prd_01HZX16429B41', 'ONE_SIZE', 'matte black', 'SM-SUN-MAT-ONESIZE'),
  ('var_01HZX16529DDC_ONE_SIZE_tortoise_AB95E8', 'prd_01HZX16529DDC', 'ONE_SIZE', 'tortoise', 'SM-SUN-TOR-ONESIZE'),
  ('var_01HZX1662C0FF_ONE_SIZE_gunmetal_4392B8', 'prd_01HZX1662C0FF', 'ONE_SIZE', 'gunmetal', 'SM-SUN-GUN-ONESIZE'),
  ('var_01HZX16737A05_ONE_SIZE_charcoal_0B5D24', 'prd_01HZX16737A05', 'ONE_SIZE', 'charcoal', 'SM-SUN-CHA-ONESIZE'),
  ('var_01HZX16874C2F_ONE_SIZE_amber_6C382B', 'prd_01HZX16874C2F', 'ONE_SIZE', 'amber', 'SM-SUN-AMB-ONESIZE'),
  ('var_01HZX169EF961_ONE_SIZE_navy_BA646D', 'prd_01HZX169EF961', 'ONE_SIZE', 'navy', 'SM-SUN-NAV-ONESIZE'),
  ('var_01HZX170BD98F_ONE_SIZE_silver_9E185F', 'prd_01HZX170BD98F', 'ONE_SIZE', 'silver', 'SM-SUN-SIL-ONESIZE'),
  ('var_01HZX171249AB_ONE_SIZE_olive_8AD183', 'prd_01HZX171249AB', 'ONE_SIZE', 'olive', 'SM-SUN-OLI-ONESIZE'),
  ('var_01HZX172FFE1D_ONE_SIZE_cream_F27187', 'prd_01HZX172FFE1D', 'ONE_SIZE', 'cream', 'SM-SUN-CRE-ONESIZE'),
  ('var_01HZX173F4F9D_ONE_SIZE_navy_152FD1', 'prd_01HZX173F4F9D', 'ONE_SIZE', 'navy', 'SM-ACC-NAV-ONESIZE'),
  ('var_01HZX174678B4_ONE_SIZE_camel_8C6094', 'prd_01HZX174678B4', 'ONE_SIZE', 'camel', 'SM-ACC-CAM-ONESIZE'),
  ('var_01HZX1758E7B8_ONE_SIZE_black_943AFE', 'prd_01HZX1758E7B8', 'ONE_SIZE', 'black', 'SM-ACC-BLA-ONESIZE'),
  ('var_01HZX176B4C3D_ONE_SIZE_deepteal_262AEA', 'prd_01HZX176B4C3D', 'ONE_SIZE', 'deep teal', 'SM-ACC-DEE-ONESIZE'),
  ('var_01HZX1773E1F6_ONE_SIZE_olive_755E32', 'prd_01HZX1773E1F6', 'ONE_SIZE', 'olive', 'SM-ACC-OLI-ONESIZE'),
  ('var_01HZX1788C252_ONE_SIZE_wine_418000', 'prd_01HZX1788C252', 'ONE_SIZE', 'wine', 'SM-ACC-WIN-ONESIZE'),
  ('var_01HZX1796A629_ONE_SIZE_espresso_9725C0', 'prd_01HZX1796A629', 'ONE_SIZE', 'espresso', 'SM-ACC-ESP-ONESIZE'),
  ('var_01HZX18042163_ONE_SIZE_sage_6C6E9D', 'prd_01HZX18042163', 'ONE_SIZE', 'sage', 'SM-ACC-SAG-ONESIZE'),
  ('var_01HZX181D0B37_ONE_SIZE_black_FD09AE', 'prd_01HZX181D0B37', 'ONE_SIZE', 'black', 'SM-ACC-BLA-ONESIZE'),
  ('var_01HZX1828E989_ONE_SIZE_charcoal_FA3DE8', 'prd_01HZX1828E989', 'ONE_SIZE', 'charcoal', 'SM-ACC-CHA-ONESIZE'),
  ('var_01HZX183622D3_S/M_olive_FB4ADE', 'prd_01HZX183622D3', 'S/M', 'olive', 'SM-ACC-OLI-SM'),
  ('var_01HZX183622D3_L/XL_olive_0D1565', 'prd_01HZX183622D3', 'L/XL', 'olive', 'SM-ACC-OLI-LXL'),
  ('var_01HZX184DA162_ONE_SIZE_navy_D8FB27', 'prd_01HZX184DA162', 'ONE_SIZE', 'navy', 'SM-ACC-NAV-ONESIZE'),
  ('var_01HZX185DBA6D_ONE_SIZE_sand_ED6165', 'prd_01HZX185DBA6D', 'ONE_SIZE', 'sand', 'SM-ACC-SAN-ONESIZE'),
  ('var_01HZX18690CD3_ONE_SIZE_slate_6D9FE9', 'prd_01HZX18690CD3', 'ONE_SIZE', 'slate', 'SM-ACC-SLA-ONESIZE');

INSERT OR IGNORE INTO product_variants (variant_id, product_id, size, color, sku) VALUES
  ('var_01HZX187CDE05_ONE_SIZE_forestgreen_A48EAB', 'prd_01HZX187CDE05', 'ONE_SIZE', 'forest green', 'SM-ACC-FOR-ONESIZE'),
  ('var_01HZX18843E1A_ONE_SIZE_tan_FCF1E4', 'prd_01HZX18843E1A', 'ONE_SIZE', 'tan', 'SM-ACC-TAN-ONESIZE'),
  ('var_01HZX1894C92B_S/M_graphite_2F7EAC', 'prd_01HZX1894C92B', 'S/M', 'graphite', 'SM-ACC-GRA-SM'),
  ('var_01HZX1894C92B_L/XL_graphite_9EB1A5', 'prd_01HZX1894C92B', 'L/XL', 'graphite', 'SM-ACC-GRA-LXL'),
  ('var_01HZX19085328_ONE_SIZE_burgundy_B84534', 'prd_01HZX19085328', 'ONE_SIZE', 'burgundy', 'SM-ACC-BUR-ONESIZE'),
  ('var_01HZX191E8813_ONE_SIZE_stone_F02FAD', 'prd_01HZX191E8813', 'ONE_SIZE', 'stone', 'SM-ACC-STO-ONESIZE'),
  ('var_01HZX192C159C_ONE_SIZE_midnightblue_4F960B', 'prd_01HZX192C159C', 'ONE_SIZE', 'midnight blue', 'SM-ACC-MID-ONESIZE'),
  ('var_01HZX193C9A38_ONE_SIZE_camel_56E98E', 'prd_01HZX193C9A38', 'ONE_SIZE', 'camel', 'SM-ACC-CAM-ONESIZE'),
  ('var_01HZX19465179_ONE_SIZE_steelblue_AD57FA', 'prd_01HZX19465179', 'ONE_SIZE', 'steel blue', 'SM-ACC-STE-ONESIZE'),
  ('var_01HZX195A9CC5_S/M_espresso_CF4A62', 'prd_01HZX195A9CC5', 'S/M', 'espresso', 'SM-ACC-ESP-SM'),
  ('var_01HZX195A9CC5_L/XL_espresso_0E50D1', 'prd_01HZX195A9CC5', 'L/XL', 'espresso', 'SM-ACC-ESP-LXL'),
  ('var_01HZX1968B4BC_ONE_SIZE_sage_7015C6', 'prd_01HZX1968B4BC', 'ONE_SIZE', 'sage', 'SM-ACC-SAG-ONESIZE'),
  ('var_01HZX1978AC07_ONE_SIZE_pewter_183E2F', 'prd_01HZX1978AC07', 'ONE_SIZE', 'pewter', 'SM-ACC-PEW-ONESIZE'),
  ('var_01HZX1989AE7B_ONE_SIZE_rust_4C319C', 'prd_01HZX1989AE7B', 'ONE_SIZE', 'rust', 'SM-ACC-RUS-ONESIZE'),
  ('var_01HZX199AFA79_ONE_SIZE_ivory_C0DA90', 'prd_01HZX199AFA79', 'ONE_SIZE', 'ivory', 'SM-ACC-IVO-ONESIZE'),
  ('var_01HZX200DFBE7_ONE_SIZE_teal_BB0CD2', 'prd_01HZX200DFBE7', 'ONE_SIZE', 'teal', 'SM-ACC-TEA-ONESIZE');


-- ============================================================================
-- seed/06_seed_product_images.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 06 - Product images (400 rows)
-- Target table: product_images
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM product_images;

INSERT INTO product_images (image_id, product_id, url, alt_text, position, color_ref) VALUES
  ('img_01HZX001B79A0_00', 'prd_01HZX001B79A0', 'assets/img/tshirt_cream_relaxed-fit_organic-cotton_01.png', 'Cream Crew Neck Tshirts front', 0, 'cream'),
  ('img_01HZX001B79A0_01', 'prd_01HZX001B79A0', 'assets/img/tshirt_cream_relaxed-fit_organic-cotton_01_back.png', 'Cream Crew Neck Tshirts back view', 1, 'cream'),
  ('img_01HZX002DC84B_00', 'prd_01HZX002DC84B', 'assets/img/tshirt_white_slim-fit_pima-cotton_02.png', 'White Crew Neck Tshirts front', 0, 'white'),
  ('img_01HZX002DC84B_01', 'prd_01HZX002DC84B', 'assets/img/tshirt_white_slim-fit_pima-cotton_02_back.png', 'White Crew Neck Tshirts back view', 1, 'white'),
  ('img_01HZX003C4E7A_00', 'prd_01HZX003C4E7A', 'assets/img/tshirt_off-white_regular-fit_cotton-modal_03.png', 'Off White Crew Neck Tshirts front', 0, 'off white'),
  ('img_01HZX003C4E7A_01', 'prd_01HZX003C4E7A', 'assets/img/tshirt_off-white_regular-fit_cotton-modal_03_back.png', 'Off White Crew Neck Tshirts back view', 1, 'off white'),
  ('img_01HZX00469D94_00', 'prd_01HZX00469D94', 'assets/img/tshirt_sage-green_relaxed-fit_organic-cotton_04.png', 'Sage Green Crew Neck Tshirts front', 0, 'sage green'),
  ('img_01HZX00469D94_01', 'prd_01HZX00469D94', 'assets/img/tshirt_sage-green_relaxed-fit_organic-cotton_04_back.png', 'Sage Green Crew Neck Tshirts back view', 1, 'sage green'),
  ('img_01HZX005E0B47_00', 'prd_01HZX005E0B47', 'assets/img/tshirt_dusty-rose_regular-fit_cotton_05.png', 'Dusty Rose Crew Neck Tshirts front', 0, 'dusty rose'),
  ('img_01HZX005E0B47_01', 'prd_01HZX005E0B47', 'assets/img/tshirt_dusty-rose_regular-fit_cotton_05_back.png', 'Dusty Rose Crew Neck Tshirts back view', 1, 'dusty rose'),
  ('img_01HZX006E013F_00', 'prd_01HZX006E013F', 'assets/img/tshirt_navy_slim-fit_cotton-blend_06.png', 'Navy Crew Neck Tshirts front', 0, 'navy'),
  ('img_01HZX006E013F_01', 'prd_01HZX006E013F', 'assets/img/tshirt_navy_slim-fit_cotton-blend_06_back.png', 'Navy Crew Neck Tshirts back view', 1, 'navy'),
  ('img_01HZX007467E4_00', 'prd_01HZX007467E4', 'assets/img/tshirt_charcoal_regular-fit_cotton_07.png', 'Charcoal Crew Neck Tshirts front', 0, 'charcoal'),
  ('img_01HZX007467E4_01', 'prd_01HZX007467E4', 'assets/img/tshirt_charcoal_regular-fit_cotton_07_back.png', 'Charcoal Crew Neck Tshirts back view', 1, 'charcoal'),
  ('img_01HZX00824F04_00', 'prd_01HZX00824F04', 'assets/img/tshirt_ivory_relaxed-fit_organic-cotton_08.png', 'Ivory Crew Neck Tshirts front', 0, 'ivory'),
  ('img_01HZX00824F04_01', 'prd_01HZX00824F04', 'assets/img/tshirt_ivory_relaxed-fit_organic-cotton_08_back.png', 'Ivory Crew Neck Tshirts back view', 1, 'ivory'),
  ('img_01HZX0092B381_00', 'prd_01HZX0092B381', 'assets/img/tshirt_terracotta_regular-fit_cotton_09.png', 'Terracotta Crew Neck Tshirts front', 0, 'terracotta'),
  ('img_01HZX0092B381_01', 'prd_01HZX0092B381', 'assets/img/tshirt_terracotta_regular-fit_cotton_09_back.png', 'Terracotta Crew Neck Tshirts back view', 1, 'terracotta'),
  ('img_01HZX010C1DC3_00', 'prd_01HZX010C1DC3', 'assets/img/tshirt_olive_relaxed-fit_cotton-blend_10.png', 'Olive Crew Neck Tshirts front', 0, 'olive'),
  ('img_01HZX010C1DC3_01', 'prd_01HZX010C1DC3', 'assets/img/tshirt_olive_relaxed-fit_cotton-blend_10_back.png', 'Olive Crew Neck Tshirts back view', 1, 'olive'),
  ('img_01HZX01118584_00', 'prd_01HZX01118584', 'assets/img/tshirt_slate-blue_slim-fit_cotton-modal_11.png', 'Slate Blue Crew Neck Tshirts front', 0, 'slate blue'),
  ('img_01HZX01118584_01', 'prd_01HZX01118584', 'assets/img/tshirt_slate-blue_slim-fit_cotton-modal_11_back.png', 'Slate Blue Crew Neck Tshirts back view', 1, 'slate blue'),
  ('img_01HZX0126D23C_00', 'prd_01HZX0126D23C', 'assets/img/tshirt_burgundy_regular-fit_cotton_12.png', 'Burgundy Crew Neck Tshirts front', 0, 'burgundy'),
  ('img_01HZX0126D23C_01', 'prd_01HZX0126D23C', 'assets/img/tshirt_burgundy_regular-fit_cotton_12_back.png', 'Burgundy Crew Neck Tshirts back view', 1, 'burgundy'),
  ('img_01HZX013AB385_00', 'prd_01HZX013AB385', 'assets/img/tshirt_white_oversized_cotton_13.png', 'White Crew Neck Tshirts front', 0, 'white'),
  ('img_01HZX013AB385_01', 'prd_01HZX013AB385', 'assets/img/tshirt_white_oversized_cotton_13_back.png', 'White Crew Neck Tshirts back view', 1, 'white'),
  ('img_01HZX0142D7F7_00', 'prd_01HZX0142D7F7', 'assets/img/tshirt_black_slim-fit_cotton_14.png', 'Black Crew Neck Tshirts front', 0, 'black'),
  ('img_01HZX0142D7F7_01', 'prd_01HZX0142D7F7', 'assets/img/tshirt_black_slim-fit_cotton_14_back.png', 'Black Crew Neck Tshirts back view', 1, 'black'),
  ('img_01HZX0154D2D3_00', 'prd_01HZX0154D2D3', 'assets/img/tshirt_light-gray_regular-fit_cotton-modal_15.png', 'Light Gray Crew Neck Tshirts front', 0, 'light gray'),
  ('img_01HZX0154D2D3_01', 'prd_01HZX0154D2D3', 'assets/img/tshirt_light-gray_regular-fit_cotton-modal_15_back.png', 'Light Gray Crew Neck Tshirts back view', 1, 'light gray'),
  ('img_01HZX0161A9D0_00', 'prd_01HZX0161A9D0', 'assets/img/tshirt_sky-blue_slim-fit_pima-cotton_16.png', 'Sky Blue Crew Neck Tshirts front', 0, 'sky blue'),
  ('img_01HZX0161A9D0_01', 'prd_01HZX0161A9D0', 'assets/img/tshirt_sky-blue_slim-fit_pima-cotton_16_back.png', 'Sky Blue Crew Neck Tshirts back view', 1, 'sky blue'),
  ('img_01HZX01710C1A_00', 'prd_01HZX01710C1A', 'assets/img/tshirt_mustard_relaxed-fit_cotton_17.png', 'Mustard Crew Neck Tshirts front', 0, 'mustard'),
  ('img_01HZX01710C1A_01', 'prd_01HZX01710C1A', 'assets/img/tshirt_mustard_relaxed-fit_cotton_17_back.png', 'Mustard Crew Neck Tshirts back view', 1, 'mustard'),
  ('img_01HZX01855961_00', 'prd_01HZX01855961', 'assets/img/tshirt_forest-green_regular-fit_organic-cotton_18.png', 'Forest Green Crew Neck Tshirts front', 0, 'forest green'),
  ('img_01HZX01855961_01', 'prd_01HZX01855961', 'assets/img/tshirt_forest-green_regular-fit_organic-cotton_18_back.png', 'Forest Green Crew Neck Tshirts back view', 1, 'forest green'),
  ('img_01HZX019AA2CD_00', 'prd_01HZX019AA2CD', 'assets/img/shirt_white_regular_cotton-poplin_01.png', 'White Button Down Shirts front', 0, 'white'),
  ('img_01HZX019AA2CD_01', 'prd_01HZX019AA2CD', 'assets/img/shirt_white_regular_cotton-poplin_01_back.png', 'White Button Down Shirts back view', 1, 'white'),
  ('img_01HZX020F074E_00', 'prd_01HZX020F074E', 'assets/img/shirt_sky-blue_slim_oxford-cotton_02.png', 'Sky Blue Button Down Shirts front', 0, 'sky blue'),
  ('img_01HZX020F074E_01', 'prd_01HZX020F074E', 'assets/img/shirt_sky-blue_slim_oxford-cotton_02_back.png', 'Sky Blue Button Down Shirts back view', 1, 'sky blue'),
  ('img_01HZX02133D5C_00', 'prd_01HZX02133D5C', 'assets/img/shirt_light-gray_regular_cotton-poplin_03.png', 'Light Gray Button Down Shirts front', 0, 'light gray'),
  ('img_01HZX02133D5C_01', 'prd_01HZX02133D5C', 'assets/img/shirt_light-gray_regular_cotton-poplin_03_back.png', 'Light Gray Button Down Shirts back view', 1, 'light gray'),
  ('img_01HZX02236351_00', 'prd_01HZX02236351', 'assets/img/shirt_navy_slim_oxford-cotton_04.png', 'Navy Button Down Shirts front', 0, 'navy'),
  ('img_01HZX02236351_01', 'prd_01HZX02236351', 'assets/img/shirt_navy_slim_oxford-cotton_04_back.png', 'Navy Button Down Shirts back view', 1, 'navy'),
  ('img_01HZX023EEA5C_00', 'prd_01HZX023EEA5C', 'assets/img/shirt_sage_relaxed_linen-cotton-blend_05.png', 'Sage Button Down Shirts front', 0, 'sage'),
  ('img_01HZX023EEA5C_01', 'prd_01HZX023EEA5C', 'assets/img/shirt_sage_relaxed_linen-cotton-blend_05_back.png', 'Sage Button Down Shirts back view', 1, 'sage'),
  ('img_01HZX024F0015_00', 'prd_01HZX024F0015', 'assets/img/shirt_ecru_regular_washed-linen_06.png', 'Ecru Button Down Shirts front', 0, 'ecru'),
  ('img_01HZX024F0015_01', 'prd_01HZX024F0015', 'assets/img/shirt_ecru_regular_washed-linen_06_back.png', 'Ecru Button Down Shirts back view', 1, 'ecru'),
  ('img_01HZX025162AE_00', 'prd_01HZX025162AE', 'assets/img/shirt_oxford-blue_slim_oxford-cotton_07.png', 'Oxford Blue Button Down Shirts front', 0, 'oxford blue'),
  ('img_01HZX025162AE_01', 'prd_01HZX025162AE', 'assets/img/shirt_oxford-blue_slim_oxford-cotton_07_back.png', 'Oxford Blue Button Down Shirts back view', 1, 'oxford blue'),
  ('img_01HZX026D3A3F_00', 'prd_01HZX026D3A3F', 'assets/img/shirt_charcoal_tailored_cotton-poplin_08.png', 'Charcoal Button Down Shirts front', 0, 'charcoal'),
  ('img_01HZX026D3A3F_01', 'prd_01HZX026D3A3F', 'assets/img/shirt_charcoal_tailored_cotton-poplin_08_back.png', 'Charcoal Button Down Shirts back view', 1, 'charcoal'),
  ('img_01HZX027E5251_00', 'prd_01HZX027E5251', 'assets/img/shirt_dusty-blue_regular_chambray_09.png', 'Dusty Blue Button Down Shirts front', 0, 'dusty blue'),
  ('img_01HZX027E5251_01', 'prd_01HZX027E5251', 'assets/img/shirt_dusty-blue_regular_chambray_09_back.png', 'Dusty Blue Button Down Shirts back view', 1, 'dusty blue'),
  ('img_01HZX028EE8C5_00', 'prd_01HZX028EE8C5', 'assets/img/shirt_ivory_relaxed_washed-linen_10.png', 'Ivory Button Down Shirts front', 0, 'ivory'),
  ('img_01HZX028EE8C5_01', 'prd_01HZX028EE8C5', 'assets/img/shirt_ivory_relaxed_washed-linen_10_back.png', 'Ivory Button Down Shirts back view', 1, 'ivory'),
  ('img_01HZX0299CD6E_00', 'prd_01HZX0299CD6E', 'assets/img/shirt_black_slim_cotton-poplin_11.png', 'Black Button Down Shirts front', 0, 'black'),
  ('img_01HZX0299CD6E_01', 'prd_01HZX0299CD6E', 'assets/img/shirt_black_slim_cotton-poplin_11_back.png', 'Black Button Down Shirts back view', 1, 'black'),
  ('img_01HZX0302514B_00', 'prd_01HZX0302514B', 'assets/img/shirt_pale-pink_regular_oxford-cotton_12.png', 'Pale Pink Button Down Shirts front', 0, 'pale pink'),
  ('img_01HZX0302514B_01', 'prd_01HZX0302514B', 'assets/img/shirt_pale-pink_regular_oxford-cotton_12_back.png', 'Pale Pink Button Down Shirts back view', 1, 'pale pink'),
  ('img_01HZX03104039_00', 'prd_01HZX03104039', 'assets/img/shirt_olive_relaxed_linen-cotton-blend_13.png', 'Olive Button Down Shirts front', 0, 'olive'),
  ('img_01HZX03104039_01', 'prd_01HZX03104039', 'assets/img/shirt_olive_relaxed_linen-cotton-blend_13_back.png', 'Olive Button Down Shirts back view', 1, 'olive'),
  ('img_01HZX03216941_00', 'prd_01HZX03216941', 'assets/img/shirt_midnight-blue_slim_cotton-poplin_14.png', 'Midnight Blue Button Down Shirts front', 0, 'midnight blue'),
  ('img_01HZX03216941_01', 'prd_01HZX03216941', 'assets/img/shirt_midnight-blue_slim_cotton-poplin_14_back.png', 'Midnight Blue Button Down Shirts back view', 1, 'midnight blue'),
  ('img_01HZX033157E7_00', 'prd_01HZX033157E7', 'assets/img/shirt_beige_regular_washed-linen_15.png', 'Beige Button Down Shirts front', 0, 'beige'),
  ('img_01HZX033157E7_01', 'prd_01HZX033157E7', 'assets/img/shirt_beige_regular_washed-linen_15_back.png', 'Beige Button Down Shirts back view', 1, 'beige'),
  ('img_01HZX034CB2B2_00', 'prd_01HZX034CB2B2', 'assets/img/shirt_burgundy_slim_oxford-cotton_16.png', 'Burgundy Button Down Shirts front', 0, 'burgundy'),
  ('img_01HZX034CB2B2_01', 'prd_01HZX034CB2B2', 'assets/img/shirt_burgundy_slim_oxford-cotton_16_back.png', 'Burgundy Button Down Shirts back view', 1, 'burgundy'),
  ('img_01HZX035816E9_00', 'prd_01HZX035816E9', 'assets/img/shirt_teal_regular_cotton-poplin_17.png', 'Teal Button Down Shirts front', 0, 'teal'),
  ('img_01HZX035816E9_01', 'prd_01HZX035816E9', 'assets/img/shirt_teal_regular_cotton-poplin_17_back.png', 'Teal Button Down Shirts back view', 1, 'teal'),
  ('img_01HZX0363DC1B_00', 'prd_01HZX0363DC1B', 'assets/img/shirt_sand_relaxed_linen-cotton-blend_18.png', 'Sand Button Down Shirts front', 0, 'sand'),
  ('img_01HZX0363DC1B_01', 'prd_01HZX0363DC1B', 'assets/img/shirt_sand_relaxed_linen-cotton-blend_18_back.png', 'Sand Button Down Shirts back view', 1, 'sand'),
  ('img_01HZX0379CC49_00', 'prd_01HZX0379CC49', 'assets/img/jeans_indigo_slim-fit_12oz-denim_01.png', 'Indigo Denim Jeans front', 0, 'indigo'),
  ('img_01HZX0379CC49_01', 'prd_01HZX0379CC49', 'assets/img/jeans_indigo_slim-fit_12oz-denim_01_back.png', 'Indigo Denim Jeans back view', 1, 'indigo'),
  ('img_01HZX038D8B0C_00', 'prd_01HZX038D8B0C', 'assets/img/jeans_black_straight-fit_stretch-denim_02.png', 'Black Denim Jeans front', 0, 'black'),
  ('img_01HZX038D8B0C_01', 'prd_01HZX038D8B0C', 'assets/img/jeans_black_straight-fit_stretch-denim_02_back.png', 'Black Denim Jeans back view', 1, 'black'),
  ('img_01HZX03959B15_00', 'prd_01HZX03959B15', 'assets/img/jeans_mid-blue_slim-fit_12oz-denim_03.png', 'Mid Blue Denim Jeans front', 0, 'mid blue'),
  ('img_01HZX03959B15_01', 'prd_01HZX03959B15', 'assets/img/jeans_mid-blue_slim-fit_12oz-denim_03_back.png', 'Mid Blue Denim Jeans back view', 1, 'mid blue'),
  ('img_01HZX0403CEB8_00', 'prd_01HZX0403CEB8', 'assets/img/jeans_light-wash-blue_relaxed-fit_lightweight-denim_04.png', 'Light Wash Blue Denim Jeans front', 0, 'light wash blue'),
  ('img_01HZX0403CEB8_01', 'prd_01HZX0403CEB8', 'assets/img/jeans_light-wash-blue_relaxed-fit_lightweight-denim_04_back.png', 'Light Wash Blue Denim Jeans back view', 1, 'light wash blue'),
  ('img_01HZX041CC651_00', 'prd_01HZX041CC651', 'assets/img/jeans_charcoal_tapered_stretch-denim_05.png', 'Charcoal Denim Jeans front', 0, 'charcoal'),
  ('img_01HZX041CC651_01', 'prd_01HZX041CC651', 'assets/img/jeans_charcoal_tapered_stretch-denim_05_back.png', 'Charcoal Denim Jeans back view', 1, 'charcoal'),
  ('img_01HZX042115D1_00', 'prd_01HZX042115D1', 'assets/img/jeans_raw-indigo_slim-fit_12oz-denim_10.png', 'Raw Indigo Denim Jeans front', 0, 'raw indigo'),
  ('img_01HZX042115D1_01', 'prd_01HZX042115D1', 'assets/img/jeans_raw-indigo_slim-fit_12oz-denim_10_back.png', 'Raw Indigo Denim Jeans back view', 1, 'raw indigo'),
  ('img_01HZX04321198_00', 'prd_01HZX04321198', 'assets/img/jeans_vintage-blue_straight-fit_12oz-denim_11.png', 'Vintage Blue Denim Jeans front', 0, 'vintage blue'),
  ('img_01HZX04321198_01', 'prd_01HZX04321198', 'assets/img/jeans_vintage-blue_straight-fit_12oz-denim_11_back.png', 'Vintage Blue Denim Jeans back view', 1, 'vintage blue'),
  ('img_01HZX0449E075_00', 'prd_01HZX0449E075', 'assets/img/jeans_gray_tapered_stretch-denim_12.png', 'Gray Denim Jeans front', 0, 'gray'),
  ('img_01HZX0449E075_01', 'prd_01HZX0449E075', 'assets/img/jeans_gray_tapered_stretch-denim_12_back.png', 'Gray Denim Jeans back view', 1, 'gray'),
  ('img_01HZX045DDBC0_00', 'prd_01HZX045DDBC0', 'assets/img/jeans_deep-blue_slim-fit_stretch-denim_14.png', 'Deep Blue Denim Jeans front', 0, 'deep blue'),
  ('img_01HZX045DDBC0_01', 'prd_01HZX045DDBC0', 'assets/img/jeans_deep-blue_slim-fit_stretch-denim_14_back.png', 'Deep Blue Denim Jeans back view', 1, 'deep blue'),
  ('img_01HZX04673CA4_00', 'prd_01HZX04673CA4', 'assets/img/jeans_black_wide-leg_12oz-denim_15.png', 'Black Denim Jeans front', 0, 'black'),
  ('img_01HZX04673CA4_01', 'prd_01HZX04673CA4', 'assets/img/jeans_black_wide-leg_12oz-denim_15_back.png', 'Black Denim Jeans back view', 1, 'black'),
  ('img_01HZX04784E6E_00', 'prd_01HZX04784E6E', 'assets/img/jeans_bleached-blue_relaxed-fit_lightweight-denim_18.png', 'Bleached Blue Denim Jeans front', 0, 'bleached blue'),
  ('img_01HZX04784E6E_01', 'prd_01HZX04784E6E', 'assets/img/jeans_bleached-blue_relaxed-fit_lightweight-denim_18_back.png', 'Bleached Blue Denim Jeans back view', 1, 'bleached blue'),
  ('img_01HZX048241B3_00', 'prd_01HZX048241B3', 'assets/img/jeans_slate_tapered_stretch-denim_19.png', 'Slate Denim Jeans front', 0, 'slate'),
  ('img_01HZX048241B3_01', 'prd_01HZX048241B3', 'assets/img/jeans_slate_tapered_stretch-denim_19_back.png', 'Slate Denim Jeans back view', 1, 'slate'),
  ('img_01HZX04904E67_00', 'prd_01HZX04904E67', 'assets/img/jeans_khaki_straight-fit_chino-cotton_06.png', 'Khaki Chinos Pants front', 0, 'khaki'),
  ('img_01HZX04904E67_01', 'prd_01HZX04904E67', 'assets/img/jeans_khaki_straight-fit_chino-cotton_06_back.png', 'Khaki Chinos Pants back view', 1, 'khaki'),
  ('img_01HZX050F7543_00', 'prd_01HZX050F7543', 'assets/img/jeans_olive_slim-fit_twill-cotton_07.png', 'Olive Trousers Pants front', 0, 'olive'),
  ('img_01HZX050F7543_01', 'prd_01HZX050F7543', 'assets/img/jeans_olive_slim-fit_twill-cotton_07_back.png', 'Olive Trousers Pants back view', 1, 'olive'),
  ('img_01HZX051B5C03_00', 'prd_01HZX051B5C03', 'assets/img/jeans_navy_straight-fit_chino-cotton_08.png', 'Navy Chinos Pants front', 0, 'navy'),
  ('img_01HZX051B5C03_01', 'prd_01HZX051B5C03', 'assets/img/jeans_navy_straight-fit_chino-cotton_08_back.png', 'Navy Chinos Pants back view', 1, 'navy'),
  ('img_01HZX052DC64F_00', 'prd_01HZX052DC64F', 'assets/img/jeans_stone_relaxed-fit_twill-cotton_09.png', 'Stone Trousers Pants front', 0, 'stone'),
  ('img_01HZX052DC64F_01', 'prd_01HZX052DC64F', 'assets/img/jeans_stone_relaxed-fit_twill-cotton_09_back.png', 'Stone Trousers Pants back view', 1, 'stone'),
  ('img_01HZX0534DE92_00', 'prd_01HZX0534DE92', 'assets/img/jeans_sand_relaxed-fit_chino-cotton_13.png', 'Sand Chinos Pants front', 0, 'sand'),
  ('img_01HZX0534DE92_01', 'prd_01HZX0534DE92', 'assets/img/jeans_sand_relaxed-fit_chino-cotton_13_back.png', 'Sand Chinos Pants back view', 1, 'sand'),
  ('img_01HZX054AA876_00', 'prd_01HZX054AA876', 'assets/img/jeans_camel_straight-fit_twill-cotton_16.png', 'Camel Trousers Pants front', 0, 'camel'),
  ('img_01HZX054AA876_01', 'prd_01HZX054AA876', 'assets/img/jeans_camel_straight-fit_twill-cotton_16_back.png', 'Camel Trousers Pants back view', 1, 'camel'),
  ('img_01HZX0552CB2B_00', 'prd_01HZX0552CB2B', 'assets/img/jeans_forest-green_slim-fit_chino-cotton_17.png', 'Forest Green Chinos Pants front', 0, 'forest green'),
  ('img_01HZX0552CB2B_01', 'prd_01HZX0552CB2B', 'assets/img/jeans_forest-green_slim-fit_chino-cotton_17_back.png', 'Forest Green Chinos Pants back view', 1, 'forest green'),
  ('img_01HZX056AC195_00', 'prd_01HZX056AC195', 'assets/img/jeans_burgundy_straight-fit_twill-cotton_20.png', 'Burgundy Trousers Pants front', 0, 'burgundy'),
  ('img_01HZX056AC195_01', 'prd_01HZX056AC195', 'assets/img/jeans_burgundy_straight-fit_twill-cotton_20_back.png', 'Burgundy Trousers Pants back view', 1, 'burgundy'),
  ('img_01HZX0573CF7C_00', 'prd_01HZX0573CF7C', 'assets/img/jeans_white_slim-fit_chino-cotton_21.png', 'White Chinos Pants front', 0, 'white'),
  ('img_01HZX0573CF7C_01', 'prd_01HZX0573CF7C', 'assets/img/jeans_white_slim-fit_chino-cotton_21_back.png', 'White Chinos Pants back view', 1, 'white'),
  ('img_01HZX0587C9B0_00', 'prd_01HZX0587C9B0', 'assets/img/jeans_tan_slim-fit_twill-cotton_24.png', 'Tan Trousers Pants front', 0, 'tan'),
  ('img_01HZX0587C9B0_01', 'prd_01HZX0587C9B0', 'assets/img/jeans_tan_slim-fit_twill-cotton_24_back.png', 'Tan Trousers Pants back view', 1, 'tan'),
  ('img_01HZX0597F0E3_00', 'prd_01HZX0597F0E3', 'assets/img/jacket_navy_tailored_travel-blazer_01.png', 'Navy Travel Blazer Jackets front', 0, 'navy'),
  ('img_01HZX0597F0E3_01', 'prd_01HZX0597F0E3', 'assets/img/jacket_navy_tailored_travel-blazer_01_back.png', 'Navy Travel Blazer Jackets back view', 1, 'navy'),
  ('img_01HZX060DAB51_00', 'prd_01HZX060DAB51', 'assets/img/jacket_charcoal_relaxed_lightweight-bomber_02.png', 'Charcoal Lightweight Bomber Jackets front', 0, 'charcoal'),
  ('img_01HZX060DAB51_01', 'prd_01HZX060DAB51', 'assets/img/jacket_charcoal_relaxed_lightweight-bomber_02_back.png', 'Charcoal Lightweight Bomber Jackets back view', 1, 'charcoal'),
  ('img_01HZX061959D1_00', 'prd_01HZX061959D1', 'assets/img/jacket_camel_tailored_soft-shoulder-blazer_03.png', 'Camel Soft Shoulder Blazer Jackets front', 0, 'camel'),
  ('img_01HZX061959D1_01', 'prd_01HZX061959D1', 'assets/img/jacket_camel_tailored_soft-shoulder-blazer_03_back.png', 'Camel Soft Shoulder Blazer Jackets back view', 1, 'camel'),
  ('img_01HZX06218D2C_00', 'prd_01HZX06218D2C', 'assets/img/jacket_olive_relaxed_packable-jacket_04.png', 'Olive Packable Jacket Jackets front', 0, 'olive'),
  ('img_01HZX06218D2C_01', 'prd_01HZX06218D2C', 'assets/img/jacket_olive_relaxed_packable-jacket_04_back.png', 'Olive Packable Jacket Jackets back view', 1, 'olive'),
  ('img_01HZX06332272_00', 'prd_01HZX06332272', 'assets/img/jacket_slate-gray_tailored_travel-blazer_05.png', 'Slate Gray Travel Blazer Jackets front', 0, 'slate gray'),
  ('img_01HZX06332272_01', 'prd_01HZX06332272', 'assets/img/jacket_slate-gray_tailored_travel-blazer_05_back.png', 'Slate Gray Travel Blazer Jackets back view', 1, 'slate gray'),
  ('img_01HZX064F12C1_00', 'prd_01HZX064F12C1', 'assets/img/jacket_deep-burgundy_tailored_soft-shoulder-blazer_06.png', 'Deep Burgundy Soft Shoulder Blazer Jackets front', 0, 'deep burgundy'),
  ('img_01HZX064F12C1_01', 'prd_01HZX064F12C1', 'assets/img/jacket_deep-burgundy_tailored_soft-shoulder-blazer_06_back.png', 'Deep Burgundy Soft Shoulder Blazer Jackets back view', 1, 'deep burgundy'),
  ('img_01HZX0657230C_00', 'prd_01HZX0657230C', 'assets/img/jacket_black_relaxed_lightweight-bomber_07.png', 'Black Lightweight Bomber Jackets front', 0, 'black'),
  ('img_01HZX0657230C_01', 'prd_01HZX0657230C', 'assets/img/jacket_black_relaxed_lightweight-bomber_07_back.png', 'Black Lightweight Bomber Jackets back view', 1, 'black'),
  ('img_01HZX06612615_00', 'prd_01HZX06612615', 'assets/img/jacket_sand_relaxed_packable-jacket_08.png', 'Sand Packable Jacket Jackets front', 0, 'sand'),
  ('img_01HZX06612615_01', 'prd_01HZX06612615', 'assets/img/jacket_sand_relaxed_packable-jacket_08_back.png', 'Sand Packable Jacket Jackets back view', 1, 'sand'),
  ('img_01HZX067FC6AF_00', 'prd_01HZX067FC6AF', 'assets/img/jacket_midnight-blue_tailored_travel-blazer_09.png', 'Midnight Blue Travel Blazer Jackets front', 0, 'midnight blue'),
  ('img_01HZX067FC6AF_01', 'prd_01HZX067FC6AF', 'assets/img/jacket_midnight-blue_tailored_travel-blazer_09_back.png', 'Midnight Blue Travel Blazer Jackets back view', 1, 'midnight blue'),
  ('img_01HZX0682F18D_00', 'prd_01HZX0682F18D', 'assets/img/jacket_forest-green_relaxed_packable-jacket_10.png', 'Forest Green Packable Jacket Jackets front', 0, 'forest green'),
  ('img_01HZX0682F18D_01', 'prd_01HZX0682F18D', 'assets/img/jacket_forest-green_relaxed_packable-jacket_10_back.png', 'Forest Green Packable Jacket Jackets back view', 1, 'forest green'),
  ('img_01HZX069DD580_00', 'prd_01HZX069DD580', 'assets/img/jacket_stone_tailored_soft-shoulder-blazer_11.png', 'Stone Soft Shoulder Blazer Jackets front', 0, 'stone'),
  ('img_01HZX069DD580_01', 'prd_01HZX069DD580', 'assets/img/jacket_stone_tailored_soft-shoulder-blazer_11_back.png', 'Stone Soft Shoulder Blazer Jackets back view', 1, 'stone'),
  ('img_01HZX070429F3_00', 'prd_01HZX070429F3', 'assets/img/jacket_teal_relaxed_lightweight-bomber_12.png', 'Teal Lightweight Bomber Jackets front', 0, 'teal'),
  ('img_01HZX070429F3_01', 'prd_01HZX070429F3', 'assets/img/jacket_teal_relaxed_lightweight-bomber_12_back.png', 'Teal Lightweight Bomber Jackets back view', 1, 'teal'),
  ('img_01HZX07187B9E_00', 'prd_01HZX07187B9E', 'assets/img/jacket_graphite_tailored_travel-blazer_13.png', 'Graphite Travel Blazer Jackets front', 0, 'graphite'),
  ('img_01HZX07187B9E_01', 'prd_01HZX07187B9E', 'assets/img/jacket_graphite_tailored_travel-blazer_13_back.png', 'Graphite Travel Blazer Jackets back view', 1, 'graphite'),
  ('img_01HZX0722E7BB_00', 'prd_01HZX0722E7BB', 'assets/img/jacket_tan_relaxed_packable-jacket_14.png', 'Tan Packable Jacket Jackets front', 0, 'tan'),
  ('img_01HZX0722E7BB_01', 'prd_01HZX0722E7BB', 'assets/img/jacket_tan_relaxed_packable-jacket_14_back.png', 'Tan Packable Jacket Jackets back view', 1, 'tan'),
  ('img_01HZX0739DCBA_00', 'prd_01HZX0739DCBA', 'assets/img/jacket_wine_tailored_soft-shoulder-blazer_15.png', 'Wine Soft Shoulder Blazer Jackets front', 0, 'wine'),
  ('img_01HZX0739DCBA_01', 'prd_01HZX0739DCBA', 'assets/img/jacket_wine_tailored_soft-shoulder-blazer_15_back.png', 'Wine Soft Shoulder Blazer Jackets back view', 1, 'wine'),
  ('img_01HZX074BF315_00', 'prd_01HZX074BF315', 'assets/img/jacket_steel-blue_relaxed_lightweight-bomber_16.png', 'Steel Blue Lightweight Bomber Jackets front', 0, 'steel blue'),
  ('img_01HZX074BF315_01', 'prd_01HZX074BF315', 'assets/img/jacket_steel-blue_relaxed_lightweight-bomber_16_back.png', 'Steel Blue Lightweight Bomber Jackets back view', 1, 'steel blue'),
  ('img_01HZX075CAF3A_00', 'prd_01HZX075CAF3A', 'assets/img/dress_black_a-line_midi_01.png', 'Black A Line Dresses front', 0, 'black'),
  ('img_01HZX075CAF3A_01', 'prd_01HZX075CAF3A', 'assets/img/dress_black_a-line_midi_01_back.png', 'Black A Line Dresses back view', 1, 'black'),
  ('img_01HZX076F5A53_00', 'prd_01HZX076F5A53', 'assets/img/dress_navy_sheath_knee-length_02.png', 'Navy Sheath Dresses front', 0, 'navy'),
  ('img_01HZX076F5A53_01', 'prd_01HZX076F5A53', 'assets/img/dress_navy_sheath_knee-length_02_back.png', 'Navy Sheath Dresses back view', 1, 'navy'),
  ('img_01HZX0777A454_00', 'prd_01HZX0777A454', 'assets/img/dress_sage_wrap_midi_03.png', 'Sage Wrap Dresses front', 0, 'sage'),
  ('img_01HZX0777A454_01', 'prd_01HZX0777A454', 'assets/img/dress_sage_wrap_midi_03_back.png', 'Sage Wrap Dresses back view', 1, 'sage'),
  ('img_01HZX07842949_00', 'prd_01HZX07842949', 'assets/img/dress_dusty-rose_shift_knee-length_04.png', 'Dusty Rose Shift Dresses front', 0, 'dusty rose'),
  ('img_01HZX07842949_01', 'prd_01HZX07842949', 'assets/img/dress_dusty-rose_shift_knee-length_04_back.png', 'Dusty Rose Shift Dresses back view', 1, 'dusty rose'),
  ('img_01HZX079F7EA2_00', 'prd_01HZX079F7EA2', 'assets/img/dress_terracotta_tiered_maxi_05.png', 'Terracotta Tiered Dresses front', 0, 'terracotta'),
  ('img_01HZX079F7EA2_01', 'prd_01HZX079F7EA2', 'assets/img/dress_terracotta_tiered_maxi_05_back.png', 'Terracotta Tiered Dresses back view', 1, 'terracotta'),
  ('img_01HZX080C8931_00', 'prd_01HZX080C8931', 'assets/img/dress_ivory_a-line_knee-length_06.png', 'Ivory A Line Dresses front', 0, 'ivory'),
  ('img_01HZX080C8931_01', 'prd_01HZX080C8931', 'assets/img/dress_ivory_a-line_knee-length_06_back.png', 'Ivory A Line Dresses back view', 1, 'ivory'),
  ('img_01HZX081764A2_00', 'prd_01HZX081764A2', 'assets/img/dress_deep-teal_sheath_midi_07.png', 'Deep Teal Sheath Dresses front', 0, 'deep teal'),
  ('img_01HZX081764A2_01', 'prd_01HZX081764A2', 'assets/img/dress_deep-teal_sheath_midi_07_back.png', 'Deep Teal Sheath Dresses back view', 1, 'deep teal'),
  ('img_01HZX082D4891_00', 'prd_01HZX082D4891', 'assets/img/dress_burgundy_wrap_knee-length_08.png', 'Burgundy Wrap Dresses front', 0, 'burgundy'),
  ('img_01HZX082D4891_01', 'prd_01HZX082D4891', 'assets/img/dress_burgundy_wrap_knee-length_08_back.png', 'Burgundy Wrap Dresses back view', 1, 'burgundy'),
  ('img_01HZX08301444_00', 'prd_01HZX08301444', 'assets/img/dress_charcoal_shift_midi_09.png', 'Charcoal Shift Dresses front', 0, 'charcoal'),
  ('img_01HZX08301444_01', 'prd_01HZX08301444', 'assets/img/dress_charcoal_shift_midi_09_back.png', 'Charcoal Shift Dresses back view', 1, 'charcoal'),
  ('img_01HZX0843DA3E_00', 'prd_01HZX0843DA3E', 'assets/img/dress_coral_a-line_maxi_10.png', 'Coral A Line Dresses front', 0, 'coral'),
  ('img_01HZX0843DA3E_01', 'prd_01HZX0843DA3E', 'assets/img/dress_coral_a-line_maxi_10_back.png', 'Coral A Line Dresses back view', 1, 'coral'),
  ('img_01HZX085CDF38_00', 'prd_01HZX085CDF38', 'assets/img/dress_plum_sheath_knee-length_11.png', 'Plum Sheath Dresses front', 0, 'plum'),
  ('img_01HZX085CDF38_01', 'prd_01HZX085CDF38', 'assets/img/dress_plum_sheath_knee-length_11_back.png', 'Plum Sheath Dresses back view', 1, 'plum'),
  ('img_01HZX08657E3B_00', 'prd_01HZX08657E3B', 'assets/img/dress_olive_wrap_midi_12.png', 'Olive Wrap Dresses front', 0, 'olive'),
  ('img_01HZX08657E3B_01', 'prd_01HZX08657E3B', 'assets/img/dress_olive_wrap_midi_12_back.png', 'Olive Wrap Dresses back view', 1, 'olive'),
  ('img_01HZX0874E45A_00', 'prd_01HZX0874E45A', 'assets/img/dress_midnight-blue_tiered_maxi_13.png', 'Midnight Blue Tiered Dresses front', 0, 'midnight blue'),
  ('img_01HZX0874E45A_01', 'prd_01HZX0874E45A', 'assets/img/dress_midnight-blue_tiered_maxi_13_back.png', 'Midnight Blue Tiered Dresses back view', 1, 'midnight blue'),
  ('img_01HZX0880B378_00', 'prd_01HZX0880B378', 'assets/img/dress_blush-pink_a-line_knee-length_14.png', 'Blush Pink A Line Dresses front', 0, 'blush pink'),
  ('img_01HZX0880B378_01', 'prd_01HZX0880B378', 'assets/img/dress_blush-pink_a-line_knee-length_14_back.png', 'Blush Pink A Line Dresses back view', 1, 'blush pink'),
  ('img_01HZX0890DDC6_00', 'prd_01HZX0890DDC6', 'assets/img/dress_forest-green_sheath_midi_15.png', 'Forest Green Sheath Dresses front', 0, 'forest green'),
  ('img_01HZX0890DDC6_01', 'prd_01HZX0890DDC6', 'assets/img/dress_forest-green_sheath_midi_15_back.png', 'Forest Green Sheath Dresses back view', 1, 'forest green'),
  ('img_01HZX090404A1_00', 'prd_01HZX090404A1', 'assets/img/dress_mustard_shift_knee-length_16.png', 'Mustard Shift Dresses front', 0, 'mustard'),
  ('img_01HZX090404A1_01', 'prd_01HZX090404A1', 'assets/img/dress_mustard_shift_knee-length_16_back.png', 'Mustard Shift Dresses back view', 1, 'mustard'),
  ('img_01HZX091FD149_00', 'prd_01HZX091FD149', 'assets/img/dress_lavender_wrap_midi_17.png', 'Lavender Wrap Dresses front', 0, 'lavender'),
  ('img_01HZX091FD149_01', 'prd_01HZX091FD149', 'assets/img/dress_lavender_wrap_midi_17_back.png', 'Lavender Wrap Dresses back view', 1, 'lavender'),
  ('img_01HZX0924A019_00', 'prd_01HZX0924A019', 'assets/img/dress_cream_tiered_midi_20.png', 'Cream Tiered Dresses front', 0, 'cream'),
  ('img_01HZX0924A019_01', 'prd_01HZX0924A019', 'assets/img/dress_cream_tiered_midi_20_back.png', 'Cream Tiered Dresses back view', 1, 'cream'),
  ('img_01HZX09307566_00', 'prd_01HZX09307566', 'assets/img/winter_charcoal_crew-neck-sweater_merino-wool_01.png', 'Charcoal Crew Neck Sweater Sweaters front', 0, 'charcoal'),
  ('img_01HZX09307566_01', 'prd_01HZX09307566', 'assets/img/winter_charcoal_crew-neck-sweater_merino-wool_01_back.png', 'Charcoal Crew Neck Sweater Sweaters back view', 1, 'charcoal'),
  ('img_01HZX09475580_00', 'prd_01HZX09475580', 'assets/img/winter_oatmeal_half-zip-pullover_lambswool_02.png', 'Oatmeal Half Zip Pullover Sweaters front', 0, 'oatmeal'),
  ('img_01HZX09475580_01', 'prd_01HZX09475580', 'assets/img/winter_oatmeal_half-zip-pullover_lambswool_02_back.png', 'Oatmeal Half Zip Pullover Sweaters back view', 1, 'oatmeal'),
  ('img_01HZX0952D0E4_00', 'prd_01HZX0952D0E4', 'assets/img/winter_forest-green_cardigan_cashmere-blend_03.png', 'Forest Green Cardigan Sweaters front', 0, 'forest green'),
  ('img_01HZX0952D0E4_01', 'prd_01HZX0952D0E4', 'assets/img/winter_forest-green_cardigan_cashmere-blend_03_back.png', 'Forest Green Cardigan Sweaters back view', 1, 'forest green'),
  ('img_01HZX096BA323_00', 'prd_01HZX096BA323', 'assets/img/winter_burgundy_crew-neck-sweater_merino-wool_06.png', 'Burgundy Crew Neck Sweater Sweaters front', 0, 'burgundy'),
  ('img_01HZX096BA323_01', 'prd_01HZX096BA323', 'assets/img/winter_burgundy_crew-neck-sweater_merino-wool_06_back.png', 'Burgundy Crew Neck Sweater Sweaters back view', 1, 'burgundy'),
  ('img_01HZX0975A9A5_00', 'prd_01HZX0975A9A5', 'assets/img/winter_slate_half-zip-pullover_lambswool_07.png', 'Slate Half Zip Pullover Sweaters front', 0, 'slate'),
  ('img_01HZX0975A9A5_01', 'prd_01HZX0975A9A5', 'assets/img/winter_slate_half-zip-pullover_lambswool_07_back.png', 'Slate Half Zip Pullover Sweaters back view', 1, 'slate'),
  ('img_01HZX098C50A4_00', 'prd_01HZX098C50A4', 'assets/img/winter_cream_cardigan_cashmere-blend_08.png', 'Cream Cardigan Sweaters front', 0, 'cream'),
  ('img_01HZX098C50A4_01', 'prd_01HZX098C50A4', 'assets/img/winter_cream_cardigan_cashmere-blend_08_back.png', 'Cream Cardigan Sweaters back view', 1, 'cream'),
  ('img_01HZX0992C9F9_00', 'prd_01HZX0992C9F9', 'assets/img/winter_rust_crew-neck-sweater_lambswool_11.png', 'Rust Crew Neck Sweater Sweaters front', 0, 'rust'),
  ('img_01HZX0992C9F9_01', 'prd_01HZX0992C9F9', 'assets/img/winter_rust_crew-neck-sweater_lambswool_11_back.png', 'Rust Crew Neck Sweater Sweaters back view', 1, 'rust'),
  ('img_01HZX10097636_00', 'prd_01HZX10097636', 'assets/img/winter_graphite_half-zip-pullover_brushed-alpaca_12.png', 'Graphite Half Zip Pullover Sweaters front', 0, 'graphite'),
  ('img_01HZX10097636_01', 'prd_01HZX10097636', 'assets/img/winter_graphite_half-zip-pullover_brushed-alpaca_12_back.png', 'Graphite Half Zip Pullover Sweaters back view', 1, 'graphite');

INSERT INTO product_images (image_id, product_id, url, alt_text, position, color_ref) VALUES
  ('img_01HZX10131F77_00', 'prd_01HZX10131F77', 'assets/img/winter_ivory_cardigan_merino-wool_13.png', 'Ivory Cardigan Sweaters front', 0, 'ivory'),
  ('img_01HZX10131F77_01', 'prd_01HZX10131F77', 'assets/img/winter_ivory_cardigan_merino-wool_13_back.png', 'Ivory Cardigan Sweaters back view', 1, 'ivory'),
  ('img_01HZX102C7A4D_00', 'prd_01HZX102C7A4D', 'assets/img/winter_steel-blue_crew-neck-sweater_merino-wool_16.png', 'Steel Blue Crew Neck Sweater Sweaters front', 0, 'steel blue'),
  ('img_01HZX102C7A4D_01', 'prd_01HZX102C7A4D', 'assets/img/winter_steel-blue_crew-neck-sweater_merino-wool_16_back.png', 'Steel Blue Crew Neck Sweater Sweaters back view', 1, 'steel blue'),
  ('img_01HZX103049E0_00', 'prd_01HZX103049E0', 'assets/img/winter_mustard_half-zip-pullover_lambswool_17.png', 'Mustard Half Zip Pullover Sweaters front', 0, 'mustard'),
  ('img_01HZX103049E0_01', 'prd_01HZX103049E0', 'assets/img/winter_mustard_half-zip-pullover_lambswool_17_back.png', 'Mustard Half Zip Pullover Sweaters back view', 1, 'mustard'),
  ('img_01HZX10433FC9_00', 'prd_01HZX10433FC9', 'assets/img/winter_plum_cardigan_brushed-alpaca_18.png', 'Plum Cardigan Sweaters front', 0, 'plum'),
  ('img_01HZX10433FC9_01', 'prd_01HZX10433FC9', 'assets/img/winter_plum_cardigan_brushed-alpaca_18_back.png', 'Plum Cardigan Sweaters back view', 1, 'plum'),
  ('img_01HZX1056D522_00', 'prd_01HZX1056D522', 'assets/img/winter_maroon_crew-neck-sweater_recycled-wool_21.png', 'Maroon Crew Neck Sweater Sweaters front', 0, 'maroon'),
  ('img_01HZX1056D522_01', 'prd_01HZX1056D522', 'assets/img/winter_maroon_crew-neck-sweater_recycled-wool_21_back.png', 'Maroon Crew Neck Sweater Sweaters back view', 1, 'maroon'),
  ('img_01HZX10612544_00', 'prd_01HZX10612544', 'assets/img/winter_pebble-gray_half-zip-pullover_merino-wool_22.png', 'Pebble Gray Half Zip Pullover Sweaters front', 0, 'pebble gray'),
  ('img_01HZX10612544_01', 'prd_01HZX10612544', 'assets/img/winter_pebble-gray_half-zip-pullover_merino-wool_22_back.png', 'Pebble Gray Half Zip Pullover Sweaters back view', 1, 'pebble gray'),
  ('img_01HZX10787D6A_00', 'prd_01HZX10787D6A', 'assets/img/raincoat_olive_mid-length_packable_01.png', 'Olive Packable Raincoats front', 0, 'olive'),
  ('img_01HZX10787D6A_01', 'prd_01HZX10787D6A', 'assets/img/raincoat_olive_mid-length_packable_01_back.png', 'Olive Packable Raincoats back view', 1, 'olive'),
  ('img_01HZX1084A3F6_00', 'prd_01HZX1084A3F6', 'assets/img/raincoat_navy_hip-length_technical-shell_02.png', 'Navy Technical Shell Raincoats front', 0, 'navy'),
  ('img_01HZX1084A3F6_01', 'prd_01HZX1084A3F6', 'assets/img/raincoat_navy_hip-length_technical-shell_02_back.png', 'Navy Technical Shell Raincoats back view', 1, 'navy'),
  ('img_01HZX1096EF12_00', 'prd_01HZX1096EF12', 'assets/img/raincoat_translucent-black_longline_double-breasted-trench_03.png', 'Translucent Black Double Breasted Trench Raincoats front', 0, 'translucent black'),
  ('img_01HZX1096EF12_01', 'prd_01HZX1096EF12', 'assets/img/raincoat_translucent-black_longline_double-breasted-trench_03_back.png', 'Translucent Black Double Breasted Trench Raincoats back view', 1, 'translucent black'),
  ('img_01HZX1107C1E2_00', 'prd_01HZX1107C1E2', 'assets/img/raincoat_sand_mid-length_packable_04.png', 'Sand Packable Raincoats front', 0, 'sand'),
  ('img_01HZX1107C1E2_01', 'prd_01HZX1107C1E2', 'assets/img/raincoat_sand_mid-length_packable_04_back.png', 'Sand Packable Raincoats back view', 1, 'sand'),
  ('img_01HZX111A1816_00', 'prd_01HZX111A1816', 'assets/img/raincoat_slate-gray_hip-length_technical-shell_05.png', 'Slate Gray Technical Shell Raincoats front', 0, 'slate gray'),
  ('img_01HZX111A1816_01', 'prd_01HZX111A1816', 'assets/img/raincoat_slate-gray_hip-length_technical-shell_05_back.png', 'Slate Gray Technical Shell Raincoats back view', 1, 'slate gray'),
  ('img_01HZX11235EA4_00', 'prd_01HZX11235EA4', 'assets/img/raincoat_butter-yellow_longline_packable_06.png', 'Butter Yellow Packable Raincoats front', 0, 'butter yellow'),
  ('img_01HZX11235EA4_01', 'prd_01HZX11235EA4', 'assets/img/raincoat_butter-yellow_longline_packable_06_back.png', 'Butter Yellow Packable Raincoats back view', 1, 'butter yellow'),
  ('img_01HZX11384678_00', 'prd_01HZX11384678', 'assets/img/raincoat_forest-green_mid-length_double-breasted-trench_07.png', 'Forest Green Double Breasted Trench Raincoats front', 0, 'forest green'),
  ('img_01HZX11384678_01', 'prd_01HZX11384678', 'assets/img/raincoat_forest-green_mid-length_double-breasted-trench_07_back.png', 'Forest Green Double Breasted Trench Raincoats back view', 1, 'forest green'),
  ('img_01HZX11402B03_00', 'prd_01HZX11402B03', 'assets/img/raincoat_charcoal_hip-length_packable_08.png', 'Charcoal Packable Raincoats front', 0, 'charcoal'),
  ('img_01HZX11402B03_01', 'prd_01HZX11402B03', 'assets/img/raincoat_charcoal_hip-length_packable_08_back.png', 'Charcoal Packable Raincoats back view', 1, 'charcoal'),
  ('img_01HZX115C0A4D_00', 'prd_01HZX115C0A4D', 'assets/img/raincoat_midnight-blue_longline_technical-shell_09.png', 'Midnight Blue Technical Shell Raincoats front', 0, 'midnight blue'),
  ('img_01HZX115C0A4D_01', 'prd_01HZX115C0A4D', 'assets/img/raincoat_midnight-blue_longline_technical-shell_09_back.png', 'Midnight Blue Technical Shell Raincoats back view', 1, 'midnight blue'),
  ('img_01HZX116F83B6_00', 'prd_01HZX116F83B6', 'assets/img/raincoat_camel_mid-length_double-breasted-trench_10.png', 'Camel Double Breasted Trench Raincoats front', 0, 'camel'),
  ('img_01HZX116F83B6_01', 'prd_01HZX116F83B6', 'assets/img/raincoat_camel_mid-length_double-breasted-trench_10_back.png', 'Camel Double Breasted Trench Raincoats back view', 1, 'camel'),
  ('img_01HZX11761294_00', 'prd_01HZX11761294', 'assets/img/sneakers_white_low-top_knit-textile_01.png', 'White Low Top Sneakers front', 0, 'white'),
  ('img_01HZX11761294_01', 'prd_01HZX11761294', 'assets/img/sneakers_white_low-top_knit-textile_01_detail.png', 'White Low Top Sneakers detail close-up', 1, 'white'),
  ('img_01HZX1187129E_00', 'prd_01HZX1187129E', 'assets/img/sneakers_off-white_minimalist_leather_02.png', 'Off White Minimalist Sneakers front', 0, 'off white'),
  ('img_01HZX1187129E_01', 'prd_01HZX1187129E', 'assets/img/sneakers_off-white_minimalist_leather_02_detail.png', 'Off White Minimalist Sneakers detail close-up', 1, 'off white'),
  ('img_01HZX119D1277_00', 'prd_01HZX119D1277', 'assets/img/sneakers_cream_retro_suede_03.png', 'Cream Retro Sneakers front', 0, 'cream'),
  ('img_01HZX119D1277_01', 'prd_01HZX119D1277', 'assets/img/sneakers_cream_retro_suede_03_detail.png', 'Cream Retro Sneakers detail close-up', 1, 'cream'),
  ('img_01HZX120F9C60_00', 'prd_01HZX120F9C60', 'assets/img/sneakers_navy_low-top_recycled-mesh_04.png', 'Navy Low Top Sneakers front', 0, 'navy'),
  ('img_01HZX120F9C60_01', 'prd_01HZX120F9C60', 'assets/img/sneakers_navy_low-top_recycled-mesh_04_detail.png', 'Navy Low Top Sneakers detail close-up', 1, 'navy'),
  ('img_01HZX1215905A_00', 'prd_01HZX1215905A', 'assets/img/sneakers_all-black_mid-top_knit-textile_05.png', 'All Black Mid Top Sneakers front', 0, 'all black'),
  ('img_01HZX1215905A_01', 'prd_01HZX1215905A', 'assets/img/sneakers_all-black_mid-top_knit-textile_05_detail.png', 'All Black Mid Top Sneakers detail close-up', 1, 'all black'),
  ('img_01HZX122D9B14_00', 'prd_01HZX122D9B14', 'assets/img/sneakers_gray_minimalist_leather_06.png', 'Gray Minimalist Sneakers front', 0, 'gray'),
  ('img_01HZX122D9B14_01', 'prd_01HZX122D9B14', 'assets/img/sneakers_gray_minimalist_leather_06_detail.png', 'Gray Minimalist Sneakers detail close-up', 1, 'gray'),
  ('img_01HZX123E4094_00', 'prd_01HZX123E4094', 'assets/img/sneakers_olive_low-top_suede_07.png', 'Olive Low Top Sneakers front', 0, 'olive'),
  ('img_01HZX123E4094_01', 'prd_01HZX123E4094', 'assets/img/sneakers_olive_low-top_suede_07_detail.png', 'Olive Low Top Sneakers detail close-up', 1, 'olive'),
  ('img_01HZX1247FAD9_00', 'prd_01HZX1247FAD9', 'assets/img/sneakers_sand_retro_recycled-mesh_08.png', 'Sand Retro Sneakers front', 0, 'sand'),
  ('img_01HZX1247FAD9_01', 'prd_01HZX1247FAD9', 'assets/img/sneakers_sand_retro_recycled-mesh_08_detail.png', 'Sand Retro Sneakers detail close-up', 1, 'sand'),
  ('img_01HZX125AC267_00', 'prd_01HZX125AC267', 'assets/img/sneakers_charcoal_low-top_knit-textile_09.png', 'Charcoal Low Top Sneakers front', 0, 'charcoal'),
  ('img_01HZX125AC267_01', 'prd_01HZX125AC267', 'assets/img/sneakers_charcoal_low-top_knit-textile_09_detail.png', 'Charcoal Low Top Sneakers detail close-up', 1, 'charcoal'),
  ('img_01HZX12691BDE_00', 'prd_01HZX12691BDE', 'assets/img/sneakers_light-gray_minimalist_recycled-mesh_10.png', 'Light Gray Minimalist Sneakers front', 0, 'light gray'),
  ('img_01HZX12691BDE_01', 'prd_01HZX12691BDE', 'assets/img/sneakers_light-gray_minimalist_recycled-mesh_10_detail.png', 'Light Gray Minimalist Sneakers detail close-up', 1, 'light gray'),
  ('img_01HZX127232F6_00', 'prd_01HZX127232F6', 'assets/img/sneakers_beige_low-top_leather_11.png', 'Beige Low Top Sneakers front', 0, 'beige'),
  ('img_01HZX127232F6_01', 'prd_01HZX127232F6', 'assets/img/sneakers_beige_low-top_leather_11_detail.png', 'Beige Low Top Sneakers detail close-up', 1, 'beige'),
  ('img_01HZX12889982_00', 'prd_01HZX12889982', 'assets/img/sneakers_sky-blue_retro_knit-textile_12.png', 'Sky Blue Retro Sneakers front', 0, 'sky blue'),
  ('img_01HZX12889982_01', 'prd_01HZX12889982', 'assets/img/sneakers_sky-blue_retro_knit-textile_12_detail.png', 'Sky Blue Retro Sneakers detail close-up', 1, 'sky blue'),
  ('img_01HZX1291DA14_00', 'prd_01HZX1291DA14', 'assets/img/sneakers_taupe_minimalist_suede_14.png', 'Taupe Minimalist Sneakers front', 0, 'taupe'),
  ('img_01HZX1291DA14_01', 'prd_01HZX1291DA14', 'assets/img/sneakers_taupe_minimalist_suede_14_detail.png', 'Taupe Minimalist Sneakers detail close-up', 1, 'taupe'),
  ('img_01HZX13080265_00', 'prd_01HZX13080265', 'assets/img/sneakers_ivory_retro_knit-textile_16.png', 'Ivory Retro Sneakers front', 0, 'ivory'),
  ('img_01HZX13080265_01', 'prd_01HZX13080265', 'assets/img/sneakers_ivory_retro_knit-textile_16_detail.png', 'Ivory Retro Sneakers detail close-up', 1, 'ivory'),
  ('img_01HZX13136F77_00', 'prd_01HZX13136F77', 'assets/img/sneakers_slate_mid-top_leather_17.png', 'Slate Mid Top Sneakers front', 0, 'slate'),
  ('img_01HZX13136F77_01', 'prd_01HZX13136F77', 'assets/img/sneakers_slate_mid-top_leather_17_detail.png', 'Slate Mid Top Sneakers detail close-up', 1, 'slate'),
  ('img_01HZX132713B9_00', 'prd_01HZX132713B9', 'assets/img/sneakers_white_mid-top_knit-textile_42.png', 'White Mid Top Sneakers front', 0, 'white'),
  ('img_01HZX132713B9_01', 'prd_01HZX132713B9', 'assets/img/sneakers_white_mid-top_knit-textile_42_detail.png', 'White Mid Top Sneakers detail close-up', 1, 'white'),
  ('img_01HZX133BF1C8_00', 'prd_01HZX133BF1C8', 'assets/img/formal-shoes_black_oxford_smooth_01.png', 'Black Oxford Formal Shoes front', 0, 'black'),
  ('img_01HZX133BF1C8_01', 'prd_01HZX133BF1C8', 'assets/img/formal-shoes_black_oxford_smooth_01_detail.png', 'Black Oxford Formal Shoes detail close-up', 1, 'black'),
  ('img_01HZX134D5B9A_00', 'prd_01HZX134D5B9A', 'assets/img/formal-shoes_dark-brown_derby_full-grain_02.png', 'Dark Brown Derby Formal Shoes front', 0, 'dark brown'),
  ('img_01HZX134D5B9A_01', 'prd_01HZX134D5B9A', 'assets/img/formal-shoes_dark-brown_derby_full-grain_02_detail.png', 'Dark Brown Derby Formal Shoes detail close-up', 1, 'dark brown'),
  ('img_01HZX135E48B5_00', 'prd_01HZX135E48B5', 'assets/img/formal-shoes_oxblood_loafer_suede_03.png', 'Oxblood Loafer Formal Shoes front', 0, 'oxblood'),
  ('img_01HZX135E48B5_01', 'prd_01HZX135E48B5', 'assets/img/formal-shoes_oxblood_loafer_suede_03_detail.png', 'Oxblood Loafer Formal Shoes detail close-up', 1, 'oxblood'),
  ('img_01HZX136DAFED_00', 'prd_01HZX136DAFED', 'assets/img/formal-shoes_tan_monk-strap_pebbled_04.png', 'Tan Monk Strap Formal Shoes front', 0, 'tan'),
  ('img_01HZX136DAFED_01', 'prd_01HZX136DAFED', 'assets/img/formal-shoes_tan_monk-strap_pebbled_04_detail.png', 'Tan Monk Strap Formal Shoes detail close-up', 1, 'tan'),
  ('img_01HZX137A036C_00', 'prd_01HZX137A036C', 'assets/img/formal-shoes_walnut_oxford_full-grain_05.png', 'Walnut Oxford Formal Shoes front', 0, 'walnut'),
  ('img_01HZX137A036C_01', 'prd_01HZX137A036C', 'assets/img/formal-shoes_walnut_oxford_full-grain_05_detail.png', 'Walnut Oxford Formal Shoes detail close-up', 1, 'walnut'),
  ('img_01HZX13862E11_00', 'prd_01HZX13862E11', 'assets/img/formal-shoes_black_derby_smooth_06.png', 'Black Derby Formal Shoes front', 0, 'black'),
  ('img_01HZX13862E11_01', 'prd_01HZX13862E11', 'assets/img/formal-shoes_black_derby_smooth_06_detail.png', 'Black Derby Formal Shoes detail close-up', 1, 'black'),
  ('img_01HZX139E8725_00', 'prd_01HZX139E8725', 'assets/img/formal-shoes_cognac_loafer_full-grain_07.png', 'Cognac Loafer Formal Shoes front', 0, 'cognac'),
  ('img_01HZX139E8725_01', 'prd_01HZX139E8725', 'assets/img/formal-shoes_cognac_loafer_full-grain_07_detail.png', 'Cognac Loafer Formal Shoes detail close-up', 1, 'cognac'),
  ('img_01HZX140A9006_00', 'prd_01HZX140A9006', 'assets/img/formal-shoes_charcoal_monk-strap_suede_08.png', 'Charcoal Monk Strap Formal Shoes front', 0, 'charcoal'),
  ('img_01HZX140A9006_01', 'prd_01HZX140A9006', 'assets/img/formal-shoes_charcoal_monk-strap_suede_08_detail.png', 'Charcoal Monk Strap Formal Shoes detail close-up', 1, 'charcoal'),
  ('img_01HZX14183BB7_00', 'prd_01HZX14183BB7', 'assets/img/formal-shoes_midnight-blue_oxford_pebbled_09.png', 'Midnight Blue Oxford Formal Shoes front', 0, 'midnight blue'),
  ('img_01HZX14183BB7_01', 'prd_01HZX14183BB7', 'assets/img/formal-shoes_midnight-blue_oxford_pebbled_09_detail.png', 'Midnight Blue Oxford Formal Shoes detail close-up', 1, 'midnight blue'),
  ('img_01HZX1422D279_00', 'prd_01HZX1422D279', 'assets/img/formal-shoes_espresso_derby_smooth_10.png', 'Espresso Derby Formal Shoes front', 0, 'espresso'),
  ('img_01HZX1422D279_01', 'prd_01HZX1422D279', 'assets/img/formal-shoes_espresso_derby_smooth_10_detail.png', 'Espresso Derby Formal Shoes detail close-up', 1, 'espresso'),
  ('img_01HZX14302FF2_00', 'prd_01HZX14302FF2', 'assets/img/formal-shoes_sand_loafer_suede_11.png', 'Sand Loafer Formal Shoes front', 0, 'sand'),
  ('img_01HZX14302FF2_01', 'prd_01HZX14302FF2', 'assets/img/formal-shoes_sand_loafer_suede_11_detail.png', 'Sand Loafer Formal Shoes detail close-up', 1, 'sand'),
  ('img_01HZX1446DC9A_00', 'prd_01HZX1446DC9A', 'assets/img/formal-shoes_burgundy_monk-strap_full-grain_12.png', 'Burgundy Monk Strap Formal Shoes front', 0, 'burgundy'),
  ('img_01HZX1446DC9A_01', 'prd_01HZX1446DC9A', 'assets/img/formal-shoes_burgundy_monk-strap_full-grain_12_detail.png', 'Burgundy Monk Strap Formal Shoes detail close-up', 1, 'burgundy'),
  ('img_01HZX145F81B7_00', 'prd_01HZX145F81B7', 'assets/img/formal-shoes_graphite_oxford_smooth_13.png', 'Graphite Oxford Formal Shoes front', 0, 'graphite'),
  ('img_01HZX145F81B7_01', 'prd_01HZX145F81B7', 'assets/img/formal-shoes_graphite_oxford_smooth_13_detail.png', 'Graphite Oxford Formal Shoes detail close-up', 1, 'graphite'),
  ('img_01HZX146DC626_00', 'prd_01HZX146DC626', 'assets/img/formal-shoes_camel_derby_pebbled_14.png', 'Camel Derby Formal Shoes front', 0, 'camel'),
  ('img_01HZX146DC626_01', 'prd_01HZX146DC626', 'assets/img/formal-shoes_camel_derby_pebbled_14_detail.png', 'Camel Derby Formal Shoes detail close-up', 1, 'camel'),
  ('img_01HZX147B19E0_00', 'prd_01HZX147B19E0', 'assets/img/backpack_black_minimalist-commuter_recycled-nylon_01.png', 'Black Minimalist Commuter Backpacks front', 0, 'black'),
  ('img_01HZX147B19E0_01', 'prd_01HZX147B19E0', 'assets/img/backpack_black_minimalist-commuter_recycled-nylon_01_detail.png', 'Black Minimalist Commuter Backpacks detail close-up', 1, 'black'),
  ('img_01HZX148501A3_00', 'prd_01HZX148501A3', 'assets/img/backpack_charcoal_technical-travel_ripstop_02.png', 'Charcoal Technical Travel Backpacks front', 0, 'charcoal'),
  ('img_01HZX148501A3_01', 'prd_01HZX148501A3', 'assets/img/backpack_charcoal_technical-travel_ripstop_02_detail.png', 'Charcoal Technical Travel Backpacks detail close-up', 1, 'charcoal'),
  ('img_01HZX1494D48D_00', 'prd_01HZX1494D48D', 'assets/img/backpack_olive_daypack_waxed-canvas_03.png', 'Olive Daypack Backpacks front', 0, 'olive'),
  ('img_01HZX1494D48D_01', 'prd_01HZX1494D48D', 'assets/img/backpack_olive_daypack_waxed-canvas_03_detail.png', 'Olive Daypack Backpacks detail close-up', 1, 'olive'),
  ('img_01HZX1505B8A8_00', 'prd_01HZX1505B8A8', 'assets/img/backpack_navy_roll-top_technical-mesh-and-nylon_04.png', 'Navy Roll Top Backpacks front', 0, 'navy'),
  ('img_01HZX1505B8A8_01', 'prd_01HZX1505B8A8', 'assets/img/backpack_navy_roll-top_technical-mesh-and-nylon_04_detail.png', 'Navy Roll Top Backpacks detail close-up', 1, 'navy'),
  ('img_01HZX151036EE_00', 'prd_01HZX151036EE', 'assets/img/backpack_sand_minimalist-commuter_recycled-nylon_05.png', 'Sand Minimalist Commuter Backpacks front', 0, 'sand'),
  ('img_01HZX151036EE_01', 'prd_01HZX151036EE', 'assets/img/backpack_sand_minimalist-commuter_recycled-nylon_05_detail.png', 'Sand Minimalist Commuter Backpacks detail close-up', 1, 'sand'),
  ('img_01HZX152E9B46_00', 'prd_01HZX152E9B46', 'assets/img/backpack_slate_technical-travel_ripstop_06.png', 'Slate Technical Travel Backpacks front', 0, 'slate'),
  ('img_01HZX152E9B46_01', 'prd_01HZX152E9B46', 'assets/img/backpack_slate_technical-travel_ripstop_06_detail.png', 'Slate Technical Travel Backpacks detail close-up', 1, 'slate'),
  ('img_01HZX1537264B_00', 'prd_01HZX1537264B', 'assets/img/backpack_forest-green_daypack_recycled-nylon_07.png', 'Forest Green Daypack Backpacks front', 0, 'forest green'),
  ('img_01HZX1537264B_01', 'prd_01HZX1537264B', 'assets/img/backpack_forest-green_daypack_recycled-nylon_07_detail.png', 'Forest Green Daypack Backpacks detail close-up', 1, 'forest green'),
  ('img_01HZX154A2535_00', 'prd_01HZX154A2535', 'assets/img/backpack_tan_minimalist-commuter_waxed-canvas_08.png', 'Tan Minimalist Commuter Backpacks front', 0, 'tan'),
  ('img_01HZX154A2535_01', 'prd_01HZX154A2535', 'assets/img/backpack_tan_minimalist-commuter_waxed-canvas_08_detail.png', 'Tan Minimalist Commuter Backpacks detail close-up', 1, 'tan'),
  ('img_01HZX15535D86_00', 'prd_01HZX15535D86', 'assets/img/backpack_graphite_roll-top_ripstop_09.png', 'Graphite Roll Top Backpacks front', 0, 'graphite'),
  ('img_01HZX15535D86_01', 'prd_01HZX15535D86', 'assets/img/backpack_graphite_roll-top_ripstop_09_detail.png', 'Graphite Roll Top Backpacks detail close-up', 1, 'graphite'),
  ('img_01HZX156A0986_00', 'prd_01HZX156A0986', 'assets/img/backpack_burgundy_daypack_recycled-nylon_10.png', 'Burgundy Daypack Backpacks front', 0, 'burgundy'),
  ('img_01HZX156A0986_01', 'prd_01HZX156A0986', 'assets/img/backpack_burgundy_daypack_recycled-nylon_10_detail.png', 'Burgundy Daypack Backpacks detail close-up', 1, 'burgundy'),
  ('img_01HZX15734629_00', 'prd_01HZX15734629', 'assets/img/backpack_stone_technical-travel_technical-mesh-and-nylon_11.png', 'Stone Technical Travel Backpacks front', 0, 'stone'),
  ('img_01HZX15734629_01', 'prd_01HZX15734629', 'assets/img/backpack_stone_technical-travel_technical-mesh-and-nylon_11_detail.png', 'Stone Technical Travel Backpacks detail close-up', 1, 'stone'),
  ('img_01HZX158EC477_00', 'prd_01HZX158EC477', 'assets/img/backpack_steel-blue_roll-top_ripstop_14.png', 'Steel Blue Roll Top Backpacks front', 0, 'steel blue'),
  ('img_01HZX158EC477_01', 'prd_01HZX158EC477', 'assets/img/backpack_steel-blue_roll-top_ripstop_14_detail.png', 'Steel Blue Roll Top Backpacks detail close-up', 1, 'steel blue'),
  ('img_01HZX15904744_00', 'prd_01HZX15904744', 'assets/img/sunglasses_tortoise_rectangular_gradient-brown_01.png', 'Tortoise Rectangular Sunglasses front', 0, 'tortoise'),
  ('img_01HZX15904744_01', 'prd_01HZX15904744', 'assets/img/sunglasses_tortoise_rectangular_gradient-brown_01_detail.png', 'Tortoise Rectangular Sunglasses detail close-up', 1, 'tortoise'),
  ('img_01HZX160B757F_00', 'prd_01HZX160B757F', 'assets/img/sunglasses_matte-black_round_smoke-gray_02.png', 'Matte Black Round Sunglasses front', 0, 'matte black'),
  ('img_01HZX160B757F_01', 'prd_01HZX160B757F', 'assets/img/sunglasses_matte-black_round_smoke-gray_02_detail.png', 'Matte Black Round Sunglasses detail close-up', 1, 'matte black'),
  ('img_01HZX161A7F7D_00', 'prd_01HZX161A7F7D', 'assets/img/sunglasses_gunmetal_aviator_polarized-green_03.png', 'Gunmetal Aviator Sunglasses front', 0, 'gunmetal'),
  ('img_01HZX161A7F7D_01', 'prd_01HZX161A7F7D', 'assets/img/sunglasses_gunmetal_aviator_polarized-green_03_detail.png', 'Gunmetal Aviator Sunglasses detail close-up', 1, 'gunmetal'),
  ('img_01HZX162BE15C_00', 'prd_01HZX162BE15C', 'assets/img/sunglasses_clear_wayfarer_mirrored-silver_04.png', 'Clear Wayfarer Sunglasses front', 0, 'clear'),
  ('img_01HZX162BE15C_01', 'prd_01HZX162BE15C', 'assets/img/sunglasses_clear_wayfarer_mirrored-silver_04_detail.png', 'Clear Wayfarer Sunglasses detail close-up', 1, 'clear'),
  ('img_01HZX16343326_00', 'prd_01HZX16343326', 'assets/img/sunglasses_brown_oversized-square_gradient-brown_05.png', 'Brown Oversized Square Sunglasses front', 0, 'brown'),
  ('img_01HZX16343326_01', 'prd_01HZX16343326', 'assets/img/sunglasses_brown_oversized-square_gradient-brown_05_detail.png', 'Brown Oversized Square Sunglasses detail close-up', 1, 'brown'),
  ('img_01HZX16429B41_00', 'prd_01HZX16429B41', 'assets/img/sunglasses_matte-black_rimless_smoke-gray_06.png', 'Matte Black Rimless Sunglasses front', 0, 'matte black'),
  ('img_01HZX16429B41_01', 'prd_01HZX16429B41', 'assets/img/sunglasses_matte-black_rimless_smoke-gray_06_detail.png', 'Matte Black Rimless Sunglasses detail close-up', 1, 'matte black'),
  ('img_01HZX16529DDC_00', 'prd_01HZX16529DDC', 'assets/img/sunglasses_tortoise_round_polarized-green_07.png', 'Tortoise Round Sunglasses front', 0, 'tortoise'),
  ('img_01HZX16529DDC_01', 'prd_01HZX16529DDC', 'assets/img/sunglasses_tortoise_round_polarized-green_07_detail.png', 'Tortoise Round Sunglasses detail close-up', 1, 'tortoise'),
  ('img_01HZX1662C0FF_00', 'prd_01HZX1662C0FF', 'assets/img/sunglasses_gunmetal_rectangular_mirrored-silver_08.png', 'Gunmetal Rectangular Sunglasses front', 0, 'gunmetal'),
  ('img_01HZX1662C0FF_01', 'prd_01HZX1662C0FF', 'assets/img/sunglasses_gunmetal_rectangular_mirrored-silver_08_detail.png', 'Gunmetal Rectangular Sunglasses detail close-up', 1, 'gunmetal'),
  ('img_01HZX16737A05_00', 'prd_01HZX16737A05', 'assets/img/sunglasses_charcoal_wayfarer_smoke-gray_09.png', 'Charcoal Wayfarer Sunglasses front', 0, 'charcoal'),
  ('img_01HZX16737A05_01', 'prd_01HZX16737A05', 'assets/img/sunglasses_charcoal_wayfarer_smoke-gray_09_detail.png', 'Charcoal Wayfarer Sunglasses detail close-up', 1, 'charcoal'),
  ('img_01HZX16874C2F_00', 'prd_01HZX16874C2F', 'assets/img/sunglasses_amber_aviator_gradient-brown_10.png', 'Amber Aviator Sunglasses front', 0, 'amber'),
  ('img_01HZX16874C2F_01', 'prd_01HZX16874C2F', 'assets/img/sunglasses_amber_aviator_gradient-brown_10_detail.png', 'Amber Aviator Sunglasses detail close-up', 1, 'amber'),
  ('img_01HZX169EF961_00', 'prd_01HZX169EF961', 'assets/img/sunglasses_navy_oversized-square_polarized-green_11.png', 'Navy Oversized Square Sunglasses front', 0, 'navy'),
  ('img_01HZX169EF961_01', 'prd_01HZX169EF961', 'assets/img/sunglasses_navy_oversized-square_polarized-green_11_detail.png', 'Navy Oversized Square Sunglasses detail close-up', 1, 'navy'),
  ('img_01HZX170BD98F_00', 'prd_01HZX170BD98F', 'assets/img/sunglasses_silver_rimless_mirrored-silver_12.png', 'Silver Rimless Sunglasses front', 0, 'silver'),
  ('img_01HZX170BD98F_01', 'prd_01HZX170BD98F', 'assets/img/sunglasses_silver_rimless_mirrored-silver_12_detail.png', 'Silver Rimless Sunglasses detail close-up', 1, 'silver'),
  ('img_01HZX171249AB_00', 'prd_01HZX171249AB', 'assets/img/sunglasses_olive_rectangular_smoke-gray_13.png', 'Olive Rectangular Sunglasses front', 0, 'olive'),
  ('img_01HZX171249AB_01', 'prd_01HZX171249AB', 'assets/img/sunglasses_olive_rectangular_smoke-gray_13_detail.png', 'Olive Rectangular Sunglasses detail close-up', 1, 'olive'),
  ('img_01HZX172FFE1D_00', 'prd_01HZX172FFE1D', 'assets/img/sunglasses_cream_round_gradient-brown_14.png', 'Cream Round Sunglasses front', 0, 'cream'),
  ('img_01HZX172FFE1D_01', 'prd_01HZX172FFE1D', 'assets/img/sunglasses_cream_round_gradient-brown_14_detail.png', 'Cream Round Sunglasses detail close-up', 1, 'cream'),
  ('img_01HZX173F4F9D_00', 'prd_01HZX173F4F9D', 'assets/img/winter_navy_beanie_recycled-wool_04.png', 'Navy Beanie Accessories front', 0, 'navy'),
  ('img_01HZX173F4F9D_01', 'prd_01HZX173F4F9D', 'assets/img/winter_navy_beanie_recycled-wool_04_detail.png', 'Navy Beanie Accessories detail close-up', 1, 'navy'),
  ('img_01HZX174678B4_00', 'prd_01HZX174678B4', 'assets/img/winter_camel_scarf_brushed-alpaca_05.png', 'Camel Scarf Accessories front', 0, 'camel'),
  ('img_01HZX174678B4_01', 'prd_01HZX174678B4', 'assets/img/winter_camel_scarf_brushed-alpaca_05_detail.png', 'Camel Scarf Accessories detail close-up', 1, 'camel'),
  ('img_01HZX1758E7B8_00', 'prd_01HZX1758E7B8', 'assets/img/winter_black_beanie_recycled-wool_09.png', 'Black Beanie Accessories front', 0, 'black'),
  ('img_01HZX1758E7B8_01', 'prd_01HZX1758E7B8', 'assets/img/winter_black_beanie_recycled-wool_09_detail.png', 'Black Beanie Accessories detail close-up', 1, 'black'),
  ('img_01HZX176B4C3D_00', 'prd_01HZX176B4C3D', 'assets/img/winter_deep-teal_scarf_merino-wool_10.png', 'Deep Teal Scarf Accessories front', 0, 'deep teal'),
  ('img_01HZX176B4C3D_01', 'prd_01HZX176B4C3D', 'assets/img/winter_deep-teal_scarf_merino-wool_10_detail.png', 'Deep Teal Scarf Accessories detail close-up', 1, 'deep teal'),
  ('img_01HZX1773E1F6_00', 'prd_01HZX1773E1F6', 'assets/img/winter_olive_beanie_cashmere-blend_14.png', 'Olive Beanie Accessories front', 0, 'olive'),
  ('img_01HZX1773E1F6_01', 'prd_01HZX1773E1F6', 'assets/img/winter_olive_beanie_cashmere-blend_14_detail.png', 'Olive Beanie Accessories detail close-up', 1, 'olive'),
  ('img_01HZX1788C252_00', 'prd_01HZX1788C252', 'assets/img/winter_wine_scarf_recycled-wool_15.png', 'Wine Scarf Accessories front', 0, 'wine'),
  ('img_01HZX1788C252_01', 'prd_01HZX1788C252', 'assets/img/winter_wine_scarf_recycled-wool_15_detail.png', 'Wine Scarf Accessories detail close-up', 1, 'wine'),
  ('img_01HZX1796A629_00', 'prd_01HZX1796A629', 'assets/img/winter_espresso_beanie_merino-wool_19.png', 'Espresso Beanie Accessories front', 0, 'espresso'),
  ('img_01HZX1796A629_01', 'prd_01HZX1796A629', 'assets/img/winter_espresso_beanie_merino-wool_19_detail.png', 'Espresso Beanie Accessories detail close-up', 1, 'espresso'),
  ('img_01HZX18042163_00', 'prd_01HZX18042163', 'assets/img/winter_sage_scarf_cashmere-blend_20.png', 'Sage Scarf Accessories front', 0, 'sage'),
  ('img_01HZX18042163_01', 'prd_01HZX18042163', 'assets/img/winter_sage_scarf_cashmere-blend_20_detail.png', 'Sage Scarf Accessories detail close-up', 1, 'sage'),
  ('img_01HZX181D0B37_00', 'prd_01HZX181D0B37', 'assets/img/travel_compact_black_ripstop-nylon_01.png', 'Black Umbrella Accessories front', 0, 'black'),
  ('img_01HZX181D0B37_01', 'prd_01HZX181D0B37', 'assets/img/travel_compact_black_ripstop-nylon_01_detail.png', 'Black Umbrella Accessories detail close-up', 1, 'black'),
  ('img_01HZX1828E989_00', 'prd_01HZX1828E989', 'assets/img/travel_set_charcoal_recycled-polyester_02.png', 'Charcoal Packing Cubes Accessories front', 0, 'charcoal'),
  ('img_01HZX1828E989_01', 'prd_01HZX1828E989', 'assets/img/travel_set_charcoal_recycled-polyester_02_detail.png', 'Charcoal Packing Cubes Accessories detail close-up', 1, 'charcoal'),
  ('img_01HZX183622D3_00', 'prd_01HZX183622D3', 'assets/img/travel_merino_olive_merino-wool_03.png', 'Olive Socks Accessories front', 0, 'olive'),
  ('img_01HZX183622D3_01', 'prd_01HZX183622D3', 'assets/img/travel_merino_olive_merino-wool_03_detail.png', 'Olive Socks Accessories detail close-up', 1, 'olive'),
  ('img_01HZX184DA162_00', 'prd_01HZX184DA162', 'assets/img/travel_leather_navy_full-grain-leather_04.png', 'Navy Wallet Accessories front', 0, 'navy'),
  ('img_01HZX184DA162_01', 'prd_01HZX184DA162', 'assets/img/travel_leather_navy_full-grain-leather_04_detail.png', 'Navy Wallet Accessories detail close-up', 1, 'navy'),
  ('img_01HZX185DBA6D_00', 'prd_01HZX185DBA6D', 'assets/img/travel_microfiber_sand_microfiber_05.png', 'Sand Towel Accessories front', 0, 'sand'),
  ('img_01HZX185DBA6D_01', 'prd_01HZX185DBA6D', 'assets/img/travel_microfiber_sand_microfiber_05_detail.png', 'Sand Towel Accessories detail close-up', 1, 'sand'),
  ('img_01HZX18690CD3_00', 'prd_01HZX18690CD3', 'assets/img/travel_travel_slate_recycled-polyester_06.png', 'Slate Cable Organizer Accessories front', 0, 'slate'),
  ('img_01HZX18690CD3_01', 'prd_01HZX18690CD3', 'assets/img/travel_travel_slate_recycled-polyester_06_detail.png', 'Slate Cable Organizer Accessories detail close-up', 1, 'slate'),
  ('img_01HZX187CDE05_00', 'prd_01HZX187CDE05', 'assets/img/travel_compact_forest-green_ripstop-nylon_07.png', 'Forest Green Umbrella Accessories front', 0, 'forest green'),
  ('img_01HZX187CDE05_01', 'prd_01HZX187CDE05', 'assets/img/travel_compact_forest-green_ripstop-nylon_07_detail.png', 'Forest Green Umbrella Accessories detail close-up', 1, 'forest green'),
  ('img_01HZX18843E1A_00', 'prd_01HZX18843E1A', 'assets/img/travel_set_tan_recycled-polyester_08.png', 'Tan Packing Cubes Accessories front', 0, 'tan'),
  ('img_01HZX18843E1A_01', 'prd_01HZX18843E1A', 'assets/img/travel_set_tan_recycled-polyester_08_detail.png', 'Tan Packing Cubes Accessories detail close-up', 1, 'tan'),
  ('img_01HZX1894C92B_00', 'prd_01HZX1894C92B', 'assets/img/travel_merino_graphite_merino-wool_09.png', 'Graphite Socks Accessories front', 0, 'graphite'),
  ('img_01HZX1894C92B_01', 'prd_01HZX1894C92B', 'assets/img/travel_merino_graphite_merino-wool_09_detail.png', 'Graphite Socks Accessories detail close-up', 1, 'graphite'),
  ('img_01HZX19085328_00', 'prd_01HZX19085328', 'assets/img/travel_leather_burgundy_full-grain-leather_10.png', 'Burgundy Wallet Accessories front', 0, 'burgundy'),
  ('img_01HZX19085328_01', 'prd_01HZX19085328', 'assets/img/travel_leather_burgundy_full-grain-leather_10_detail.png', 'Burgundy Wallet Accessories detail close-up', 1, 'burgundy'),
  ('img_01HZX191E8813_00', 'prd_01HZX191E8813', 'assets/img/travel_microfiber_stone_microfiber_11.png', 'Stone Towel Accessories front', 0, 'stone'),
  ('img_01HZX191E8813_01', 'prd_01HZX191E8813', 'assets/img/travel_microfiber_stone_microfiber_11_detail.png', 'Stone Towel Accessories detail close-up', 1, 'stone'),
  ('img_01HZX192C159C_00', 'prd_01HZX192C159C', 'assets/img/travel_travel_midnight-blue_recycled-polyester_12.png', 'Midnight Blue Cable Organizer Accessories front', 0, 'midnight blue'),
  ('img_01HZX192C159C_01', 'prd_01HZX192C159C', 'assets/img/travel_travel_midnight-blue_recycled-polyester_12_detail.png', 'Midnight Blue Cable Organizer Accessories detail close-up', 1, 'midnight blue'),
  ('img_01HZX193C9A38_00', 'prd_01HZX193C9A38', 'assets/img/travel_compact_camel_ripstop-nylon_13.png', 'Camel Umbrella Accessories front', 0, 'camel'),
  ('img_01HZX193C9A38_01', 'prd_01HZX193C9A38', 'assets/img/travel_compact_camel_ripstop-nylon_13_detail.png', 'Camel Umbrella Accessories detail close-up', 1, 'camel'),
  ('img_01HZX19465179_00', 'prd_01HZX19465179', 'assets/img/travel_set_steel-blue_recycled-polyester_14.png', 'Steel Blue Packing Cubes Accessories front', 0, 'steel blue'),
  ('img_01HZX19465179_01', 'prd_01HZX19465179', 'assets/img/travel_set_steel-blue_recycled-polyester_14_detail.png', 'Steel Blue Packing Cubes Accessories detail close-up', 1, 'steel blue'),
  ('img_01HZX195A9CC5_00', 'prd_01HZX195A9CC5', 'assets/img/travel_merino_espresso_merino-wool_15.png', 'Espresso Socks Accessories front', 0, 'espresso'),
  ('img_01HZX195A9CC5_01', 'prd_01HZX195A9CC5', 'assets/img/travel_merino_espresso_merino-wool_15_detail.png', 'Espresso Socks Accessories detail close-up', 1, 'espresso'),
  ('img_01HZX1968B4BC_00', 'prd_01HZX1968B4BC', 'assets/img/travel_leather_sage_full-grain-leather_16.png', 'Sage Wallet Accessories front', 0, 'sage'),
  ('img_01HZX1968B4BC_01', 'prd_01HZX1968B4BC', 'assets/img/travel_leather_sage_full-grain-leather_16_detail.png', 'Sage Wallet Accessories detail close-up', 1, 'sage'),
  ('img_01HZX1978AC07_00', 'prd_01HZX1978AC07', 'assets/img/travel_microfiber_pewter_microfiber_17.png', 'Pewter Towel Accessories front', 0, 'pewter'),
  ('img_01HZX1978AC07_01', 'prd_01HZX1978AC07', 'assets/img/travel_microfiber_pewter_microfiber_17_detail.png', 'Pewter Towel Accessories detail close-up', 1, 'pewter'),
  ('img_01HZX1989AE7B_00', 'prd_01HZX1989AE7B', 'assets/img/travel_travel_rust_recycled-polyester_18.png', 'Rust Cable Organizer Accessories front', 0, 'rust'),
  ('img_01HZX1989AE7B_01', 'prd_01HZX1989AE7B', 'assets/img/travel_travel_rust_recycled-polyester_18_detail.png', 'Rust Cable Organizer Accessories detail close-up', 1, 'rust'),
  ('img_01HZX199AFA79_00', 'prd_01HZX199AFA79', 'assets/img/travel_compact_ivory_ripstop-nylon_19.png', 'Ivory Umbrella Accessories front', 0, 'ivory'),
  ('img_01HZX199AFA79_01', 'prd_01HZX199AFA79', 'assets/img/travel_compact_ivory_ripstop-nylon_19_detail.png', 'Ivory Umbrella Accessories detail close-up', 1, 'ivory'),
  ('img_01HZX200DFBE7_00', 'prd_01HZX200DFBE7', 'assets/img/travel_set_teal_recycled-polyester_20.png', 'Teal Packing Cubes Accessories front', 0, 'teal'),
  ('img_01HZX200DFBE7_01', 'prd_01HZX200DFBE7', 'assets/img/travel_set_teal_recycled-polyester_20_detail.png', 'Teal Packing Cubes Accessories detail close-up', 1, 'teal');


-- ============================================================================
-- seed/07_seed_inventory.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 07 - Inventory (1016 variant rows)
-- Target table: inventory
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM inventory;

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX001B79A0_XS_cream_B30849', 19),
  ('var_01HZX001B79A0_S_cream_4A300C', 77),
  ('var_01HZX001B79A0_M_cream_B3ABCA', 24),
  ('var_01HZX001B79A0_L_cream_26CD7A', 12),
  ('var_01HZX001B79A0_XL_cream_68A166', 23),
  ('var_01HZX002DC84B_XS_white_6BF790', 22),
  ('var_01HZX002DC84B_S_white_B5135F', 75),
  ('var_01HZX002DC84B_M_white_4CED6F', 19),
  ('var_01HZX002DC84B_L_white_41775A', 17),
  ('var_01HZX002DC84B_XL_white_068212', 10),
  ('var_01HZX003C4E7A_XS_offwhite_248048', 15),
  ('var_01HZX003C4E7A_S_offwhite_D39897', 20),
  ('var_01HZX003C4E7A_M_offwhite_094A39', 10),
  ('var_01HZX003C4E7A_L_offwhite_C74F6B', 9),
  ('var_01HZX003C4E7A_XL_offwhite_297838', 24),
  ('var_01HZX00469D94_XS_sagegreen_2DF82F', 22),
  ('var_01HZX00469D94_S_sagegreen_5AE7C8', 66),
  ('var_01HZX00469D94_M_sagegreen_885059', 12),
  ('var_01HZX00469D94_L_sagegreen_21F481', 20),
  ('var_01HZX00469D94_XL_sagegreen_B385E4', 78),
  ('var_01HZX005E0B47_XS_dustyrose_AF9EB2', 55),
  ('var_01HZX005E0B47_S_dustyrose_66E763', 22),
  ('var_01HZX005E0B47_M_dustyrose_EB2EEC', 3),
  ('var_01HZX005E0B47_L_dustyrose_3129BE', 15),
  ('var_01HZX005E0B47_XL_dustyrose_C53120', 11),
  ('var_01HZX006E013F_XS_navy_A2E5A4', 20),
  ('var_01HZX006E013F_S_navy_D6A210', 33),
  ('var_01HZX006E013F_M_navy_53E636', 1),
  ('var_01HZX006E013F_L_navy_C22BE6', 42),
  ('var_01HZX006E013F_XL_navy_CB4331', 77),
  ('var_01HZX007467E4_XS_charcoal_82A648', 61),
  ('var_01HZX007467E4_S_charcoal_3215E0', 75),
  ('var_01HZX007467E4_M_charcoal_D24684', 18),
  ('var_01HZX007467E4_L_charcoal_F4B7A5', 14),
  ('var_01HZX007467E4_XL_charcoal_CC1597', 21),
  ('var_01HZX00824F04_XS_ivory_DA28CA', 19),
  ('var_01HZX00824F04_S_ivory_7951EA', 55),
  ('var_01HZX00824F04_M_ivory_57A67B', 62),
  ('var_01HZX00824F04_L_ivory_5E7287', 11),
  ('var_01HZX00824F04_XL_ivory_7B5A9F', 2),
  ('var_01HZX0092B381_XS_terracotta_AAD41B', 37),
  ('var_01HZX0092B381_S_terracotta_48C4EC', 9),
  ('var_01HZX0092B381_M_terracotta_5A0E89', 68),
  ('var_01HZX0092B381_L_terracotta_052402', 3),
  ('var_01HZX0092B381_XL_terracotta_50E69B', 23),
  ('var_01HZX010C1DC3_XS_olive_4E50B3', 2),
  ('var_01HZX010C1DC3_S_olive_9B180A', 10),
  ('var_01HZX010C1DC3_M_olive_B2D0E5', 13),
  ('var_01HZX010C1DC3_L_olive_B75701', 38),
  ('var_01HZX010C1DC3_XL_olive_154866', 15),
  ('var_01HZX01118584_XS_slateblue_C31446', 53),
  ('var_01HZX01118584_S_slateblue_14A721', 22),
  ('var_01HZX01118584_M_slateblue_D85F6F', 24),
  ('var_01HZX01118584_L_slateblue_A98A3F', 14),
  ('var_01HZX01118584_XL_slateblue_107CE1', 56),
  ('var_01HZX0126D23C_XS_burgundy_530AC8', 10),
  ('var_01HZX0126D23C_S_burgundy_6A69BD', 73),
  ('var_01HZX0126D23C_M_burgundy_333DCE', 13),
  ('var_01HZX0126D23C_L_burgundy_AFC67B', 22),
  ('var_01HZX0126D23C_XL_burgundy_26AF37', 67),
  ('var_01HZX013AB385_XS_white_9F9A61', 12),
  ('var_01HZX013AB385_S_white_59FF9A', 79),
  ('var_01HZX013AB385_M_white_7E152E', 68),
  ('var_01HZX013AB385_L_white_1C9F9A', 16),
  ('var_01HZX013AB385_XL_white_FFE9AE', 14),
  ('var_01HZX0142D7F7_XS_black_6A13F9', 13),
  ('var_01HZX0142D7F7_S_black_10D74F', 11),
  ('var_01HZX0142D7F7_M_black_E50A00', 70),
  ('var_01HZX0142D7F7_L_black_639B0B', 1),
  ('var_01HZX0142D7F7_XL_black_8EA12F', 18),
  ('var_01HZX0154D2D3_XS_lightgray_72D638', 65),
  ('var_01HZX0154D2D3_S_lightgray_42DB5A', 1),
  ('var_01HZX0154D2D3_M_lightgray_992B2B', 47),
  ('var_01HZX0154D2D3_L_lightgray_4BF50D', 53),
  ('var_01HZX0154D2D3_XL_lightgray_97B129', 54),
  ('var_01HZX0161A9D0_XS_skyblue_139FCA', 11),
  ('var_01HZX0161A9D0_S_skyblue_958205', 48),
  ('var_01HZX0161A9D0_M_skyblue_0F988E', 24),
  ('var_01HZX0161A9D0_L_skyblue_4648CF', 78),
  ('var_01HZX0161A9D0_XL_skyblue_93E02B', 77),
  ('var_01HZX01710C1A_XS_mustard_68522E', 10),
  ('var_01HZX01710C1A_S_mustard_A6F720', 17),
  ('var_01HZX01710C1A_M_mustard_D75D24', 3),
  ('var_01HZX01710C1A_L_mustard_E27841', 80),
  ('var_01HZX01710C1A_XL_mustard_6ADC5D', 53),
  ('var_01HZX01855961_XS_forestgreen_ED1B84', 43),
  ('var_01HZX01855961_S_forestgreen_E0A0AA', 21),
  ('var_01HZX01855961_M_forestgreen_0D122D', 11),
  ('var_01HZX01855961_L_forestgreen_BB78A7', 20),
  ('var_01HZX01855961_XL_forestgreen_72F7B2', 52),
  ('var_01HZX019AA2CD_XS_white_40B5D4', 54),
  ('var_01HZX019AA2CD_S_white_38D1FE', 4),
  ('var_01HZX019AA2CD_M_white_E075E2', 36),
  ('var_01HZX019AA2CD_L_white_C18CA0', 2),
  ('var_01HZX019AA2CD_XL_white_1CAEBE', 37),
  ('var_01HZX020F074E_XS_skyblue_38408C', 15),
  ('var_01HZX020F074E_S_skyblue_9DF26E', 34),
  ('var_01HZX020F074E_M_skyblue_6414F8', 57),
  ('var_01HZX020F074E_L_skyblue_99E2A2', 43),
  ('var_01HZX020F074E_XL_skyblue_24D465', 47);

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX02133D5C_XS_lightgray_077CBD', 35),
  ('var_01HZX02133D5C_S_lightgray_32C875', 3),
  ('var_01HZX02133D5C_M_lightgray_345990', 12),
  ('var_01HZX02133D5C_L_lightgray_BA8984', 79),
  ('var_01HZX02133D5C_XL_lightgray_775EA0', 3),
  ('var_01HZX02236351_XS_navy_0E1BF7', 43),
  ('var_01HZX02236351_S_navy_A6E483', 19),
  ('var_01HZX02236351_M_navy_3D4776', 20),
  ('var_01HZX02236351_L_navy_4BE81E', 57),
  ('var_01HZX02236351_XL_navy_429814', 19),
  ('var_01HZX023EEA5C_XS_sage_C50F01', 23),
  ('var_01HZX023EEA5C_S_sage_94F9E1', 67),
  ('var_01HZX023EEA5C_M_sage_CF0EC3', 4),
  ('var_01HZX023EEA5C_L_sage_9BCF5B', 10),
  ('var_01HZX023EEA5C_XL_sage_9729F6', 66),
  ('var_01HZX024F0015_XS_ecru_470E1F', 13),
  ('var_01HZX024F0015_S_ecru_D7F9BC', 17),
  ('var_01HZX024F0015_M_ecru_86ACD2', 77),
  ('var_01HZX024F0015_L_ecru_5F295B', 16),
  ('var_01HZX024F0015_XL_ecru_001995', 8),
  ('var_01HZX025162AE_XS_oxfordblue_6832D1', 12),
  ('var_01HZX025162AE_S_oxfordblue_6B72FC', 23),
  ('var_01HZX025162AE_M_oxfordblue_2471C2', 16),
  ('var_01HZX025162AE_L_oxfordblue_9CF31A', 11),
  ('var_01HZX025162AE_XL_oxfordblue_61AB9D', 50),
  ('var_01HZX026D3A3F_XS_charcoal_7A0DAA', 14),
  ('var_01HZX026D3A3F_S_charcoal_DEEB73', 10),
  ('var_01HZX026D3A3F_M_charcoal_8CAF9E', 18),
  ('var_01HZX026D3A3F_L_charcoal_E6BAC0', 50),
  ('var_01HZX026D3A3F_XL_charcoal_829FB7', 55),
  ('var_01HZX027E5251_XS_dustyblue_94035F', 12),
  ('var_01HZX027E5251_S_dustyblue_581AA2', 50),
  ('var_01HZX027E5251_M_dustyblue_9165D7', 22),
  ('var_01HZX027E5251_L_dustyblue_C152B2', 4),
  ('var_01HZX027E5251_XL_dustyblue_42BB10', 76),
  ('var_01HZX028EE8C5_XS_ivory_002BB6', 50),
  ('var_01HZX028EE8C5_S_ivory_4ED302', 78),
  ('var_01HZX028EE8C5_M_ivory_ADDFA2', 12),
  ('var_01HZX028EE8C5_L_ivory_5EBEF0', 71),
  ('var_01HZX028EE8C5_XL_ivory_BA3DFB', 14),
  ('var_01HZX0299CD6E_XS_black_200535', 77),
  ('var_01HZX0299CD6E_S_black_F0FEDC', 24),
  ('var_01HZX0299CD6E_M_black_C84DA1', 20),
  ('var_01HZX0299CD6E_L_black_585684', 10),
  ('var_01HZX0299CD6E_XL_black_143587', 24),
  ('var_01HZX0302514B_XS_palepink_3A0F8A', 8),
  ('var_01HZX0302514B_S_palepink_8EDFD0', 44),
  ('var_01HZX0302514B_M_palepink_EECEFE', 51),
  ('var_01HZX0302514B_L_palepink_0F7438', 21),
  ('var_01HZX0302514B_XL_palepink_284AB3', 80),
  ('var_01HZX03104039_XS_olive_8D4631', 1),
  ('var_01HZX03104039_S_olive_4F15EA', 13),
  ('var_01HZX03104039_M_olive_596F9B', 8),
  ('var_01HZX03104039_L_olive_9DEC73', 8),
  ('var_01HZX03104039_XL_olive_EB6BBA', 79),
  ('var_01HZX03216941_XS_midnightblue_155FC6', 38),
  ('var_01HZX03216941_S_midnightblue_7F7F2C', 4),
  ('var_01HZX03216941_M_midnightblue_C38746', 16),
  ('var_01HZX03216941_L_midnightblue_ECDF52', 70),
  ('var_01HZX03216941_XL_midnightblue_7AFD39', 18),
  ('var_01HZX033157E7_XS_beige_443E33', 19),
  ('var_01HZX033157E7_S_beige_A05890', 23),
  ('var_01HZX033157E7_M_beige_EB3696', 3),
  ('var_01HZX033157E7_L_beige_22EEFF', 37),
  ('var_01HZX033157E7_XL_beige_92018C', 18),
  ('var_01HZX034CB2B2_XS_burgundy_9ABB06', 79),
  ('var_01HZX034CB2B2_S_burgundy_ED11C7', 33),
  ('var_01HZX034CB2B2_M_burgundy_0D67B6', 46),
  ('var_01HZX034CB2B2_L_burgundy_FC1B8E', 2),
  ('var_01HZX034CB2B2_XL_burgundy_2318CC', 38),
  ('var_01HZX035816E9_XS_teal_E7435D', 2),
  ('var_01HZX035816E9_S_teal_3DBA8C', 18),
  ('var_01HZX035816E9_M_teal_E97E02', 16),
  ('var_01HZX035816E9_L_teal_24C017', 32),
  ('var_01HZX035816E9_XL_teal_C0699E', 12),
  ('var_01HZX0363DC1B_XS_sand_F6FCDF', 69),
  ('var_01HZX0363DC1B_S_sand_31EABD', 17),
  ('var_01HZX0363DC1B_M_sand_87F23A', 38),
  ('var_01HZX0363DC1B_L_sand_AA1A9E', 21),
  ('var_01HZX0363DC1B_XL_sand_CE6A2C', 21),
  ('var_01HZX0379CC49_28_indigo_FF5F9B', 47),
  ('var_01HZX0379CC49_30_indigo_BA2084', 61),
  ('var_01HZX0379CC49_32_indigo_BBD9A1', 15),
  ('var_01HZX0379CC49_34_indigo_C4F078', 75),
  ('var_01HZX0379CC49_36_indigo_4C374F', 4),
  ('var_01HZX038D8B0C_28_black_57417B', 62),
  ('var_01HZX038D8B0C_30_black_0F305A', 13),
  ('var_01HZX038D8B0C_32_black_578826', 22),
  ('var_01HZX038D8B0C_34_black_4DD948', 4),
  ('var_01HZX038D8B0C_36_black_3C8B55', 12),
  ('var_01HZX03959B15_28_midblue_E4A9B3', 18),
  ('var_01HZX03959B15_30_midblue_3EE13B', 50),
  ('var_01HZX03959B15_32_midblue_ACB1F0', 8),
  ('var_01HZX03959B15_34_midblue_7C6946', 51),
  ('var_01HZX03959B15_36_midblue_E464D2', 69),
  ('var_01HZX0403CEB8_28_lightwashblue_DA68F1', 12),
  ('var_01HZX0403CEB8_30_lightwashblue_23CB53', 15),
  ('var_01HZX0403CEB8_32_lightwashblue_6748E2', 22),
  ('var_01HZX0403CEB8_34_lightwashblue_8EC877', 52),
  ('var_01HZX0403CEB8_36_lightwashblue_FBE463', 61),
  ('var_01HZX041CC651_28_charcoal_1B1B53', 46),
  ('var_01HZX041CC651_30_charcoal_670DC3', 17),
  ('var_01HZX041CC651_32_charcoal_E8BA08', 23),
  ('var_01HZX041CC651_34_charcoal_97E128', 11),
  ('var_01HZX041CC651_36_charcoal_8C8194', 11),
  ('var_01HZX042115D1_28_rawindigo_694993', 20),
  ('var_01HZX042115D1_30_rawindigo_2FC350', 44),
  ('var_01HZX042115D1_32_rawindigo_FFD461', 19),
  ('var_01HZX042115D1_34_rawindigo_684A12', 74),
  ('var_01HZX042115D1_36_rawindigo_234629', 16),
  ('var_01HZX04321198_28_vintageblue_88EBCB', 61),
  ('var_01HZX04321198_30_vintageblue_58D70B', 31),
  ('var_01HZX04321198_32_vintageblue_276C54', 11),
  ('var_01HZX04321198_34_vintageblue_640692', 14),
  ('var_01HZX04321198_36_vintageblue_76C1DE', 33),
  ('var_01HZX0449E075_28_gray_8791F7', 14),
  ('var_01HZX0449E075_30_gray_9030D8', 24),
  ('var_01HZX0449E075_32_gray_D596EE', 72),
  ('var_01HZX0449E075_34_gray_BAF9AE', 15),
  ('var_01HZX0449E075_36_gray_E0E049', 53),
  ('var_01HZX045DDBC0_28_deepblue_504783', 17),
  ('var_01HZX045DDBC0_30_deepblue_D7DBD9', 9),
  ('var_01HZX045DDBC0_32_deepblue_A0B1E0', 59),
  ('var_01HZX045DDBC0_34_deepblue_99C539', 10),
  ('var_01HZX045DDBC0_36_deepblue_C79155', 16),
  ('var_01HZX04673CA4_28_black_02A183', 79),
  ('var_01HZX04673CA4_30_black_A68E45', 37),
  ('var_01HZX04673CA4_32_black_0B854A', 12),
  ('var_01HZX04673CA4_34_black_12A210', 23),
  ('var_01HZX04673CA4_36_black_C0BBF0', 12),
  ('var_01HZX04784E6E_28_bleachedblue_1E0EF9', 8),
  ('var_01HZX04784E6E_30_bleachedblue_72AD51', 24),
  ('var_01HZX04784E6E_32_bleachedblue_87B62E', 14),
  ('var_01HZX04784E6E_34_bleachedblue_C404FA', 8),
  ('var_01HZX04784E6E_36_bleachedblue_72C54B', 10),
  ('var_01HZX048241B3_28_slate_7B1222', 17),
  ('var_01HZX048241B3_30_slate_788DA8', 50),
  ('var_01HZX048241B3_32_slate_CE8CB3', 34),
  ('var_01HZX048241B3_34_slate_6012A1', 17),
  ('var_01HZX048241B3_36_slate_E40BA6', 37),
  ('var_01HZX04904E67_28_khaki_532422', 19),
  ('var_01HZX04904E67_30_khaki_189BF5', 15),
  ('var_01HZX04904E67_32_khaki_EC46A7', 13),
  ('var_01HZX04904E67_34_khaki_A3B053', 9),
  ('var_01HZX04904E67_36_khaki_45D51A', 20),
  ('var_01HZX050F7543_28_olive_AB98CF', 12),
  ('var_01HZX050F7543_30_olive_B65E9F', 24),
  ('var_01HZX050F7543_32_olive_534578', 11),
  ('var_01HZX050F7543_34_olive_00ECF3', 61),
  ('var_01HZX050F7543_36_olive_71A3A8', 61),
  ('var_01HZX051B5C03_28_navy_F106E8', 21),
  ('var_01HZX051B5C03_30_navy_2A0301', 9),
  ('var_01HZX051B5C03_32_navy_E10FEC', 22),
  ('var_01HZX051B5C03_34_navy_1234F2', 21),
  ('var_01HZX051B5C03_36_navy_EB0F4A', 22),
  ('var_01HZX052DC64F_28_stone_9BD174', 14),
  ('var_01HZX052DC64F_30_stone_A71D82', 70),
  ('var_01HZX052DC64F_32_stone_2858BB', 67),
  ('var_01HZX052DC64F_34_stone_A73021', 10),
  ('var_01HZX052DC64F_36_stone_20F403', 76),
  ('var_01HZX0534DE92_28_sand_6CAC1C', 10),
  ('var_01HZX0534DE92_30_sand_81E663', 52),
  ('var_01HZX0534DE92_32_sand_2C9864', 13),
  ('var_01HZX0534DE92_34_sand_58FFAC', 55),
  ('var_01HZX0534DE92_36_sand_8635B4', 32);

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX054AA876_28_camel_52D2F8', 9),
  ('var_01HZX054AA876_30_camel_3C2138', 23),
  ('var_01HZX054AA876_32_camel_A05377', 77),
  ('var_01HZX054AA876_34_camel_ACB279', 24),
  ('var_01HZX054AA876_36_camel_569389', 38),
  ('var_01HZX0552CB2B_28_forestgreen_6A0F49', 78),
  ('var_01HZX0552CB2B_30_forestgreen_A56926', 15),
  ('var_01HZX0552CB2B_32_forestgreen_CAF20A', 60),
  ('var_01HZX0552CB2B_34_forestgreen_7D8D9D', 67),
  ('var_01HZX0552CB2B_36_forestgreen_715B7E', 57),
  ('var_01HZX056AC195_28_burgundy_A3F4E2', 17),
  ('var_01HZX056AC195_30_burgundy_58AEFD', 78),
  ('var_01HZX056AC195_32_burgundy_77916C', 22),
  ('var_01HZX056AC195_34_burgundy_231CFF', 20),
  ('var_01HZX056AC195_36_burgundy_1C4984', 10),
  ('var_01HZX0573CF7C_28_white_40ABDB', 12),
  ('var_01HZX0573CF7C_30_white_7AEEB2', 8),
  ('var_01HZX0573CF7C_32_white_2E94F4', 36),
  ('var_01HZX0573CF7C_34_white_ED2332', 24),
  ('var_01HZX0573CF7C_36_white_55CC50', 23),
  ('var_01HZX0587C9B0_28_tan_FCD5FC', 13),
  ('var_01HZX0587C9B0_30_tan_2D68E3', 47),
  ('var_01HZX0587C9B0_32_tan_4E47F2', 10),
  ('var_01HZX0587C9B0_34_tan_BE21F9', 61),
  ('var_01HZX0587C9B0_36_tan_EDF4E9', 72),
  ('var_01HZX0597F0E3_XS_navy_9D9C81', 1),
  ('var_01HZX0597F0E3_S_navy_F33AE8', 78),
  ('var_01HZX0597F0E3_M_navy_F95DBF', 69),
  ('var_01HZX0597F0E3_L_navy_7CF662', 60),
  ('var_01HZX0597F0E3_XL_navy_9EB0E4', 9),
  ('var_01HZX060DAB51_XS_charcoal_672D4A', 17),
  ('var_01HZX060DAB51_S_charcoal_58F3EB', 21),
  ('var_01HZX060DAB51_M_charcoal_0DAAD2', 8),
  ('var_01HZX060DAB51_L_charcoal_4ED97E', 56),
  ('var_01HZX060DAB51_XL_charcoal_7A3BCB', 35),
  ('var_01HZX061959D1_XS_camel_A04531', 72),
  ('var_01HZX061959D1_S_camel_8B2E64', 24),
  ('var_01HZX061959D1_M_camel_6B419C', 67),
  ('var_01HZX061959D1_L_camel_1300CE', 9),
  ('var_01HZX061959D1_XL_camel_A1C67E', 4),
  ('var_01HZX06218D2C_XS_olive_62538C', 4),
  ('var_01HZX06218D2C_S_olive_F68408', 68),
  ('var_01HZX06218D2C_M_olive_29E03F', 60),
  ('var_01HZX06218D2C_L_olive_72E0C8', 1),
  ('var_01HZX06218D2C_XL_olive_043913', 19),
  ('var_01HZX06332272_XS_slategray_1A617B', 1),
  ('var_01HZX06332272_S_slategray_0DBD85', 21),
  ('var_01HZX06332272_M_slategray_C85B48', 44),
  ('var_01HZX06332272_L_slategray_FCD165', 17),
  ('var_01HZX06332272_XL_slategray_666543', 15),
  ('var_01HZX064F12C1_XS_deepburgundy_8E2B25', 73),
  ('var_01HZX064F12C1_S_deepburgundy_96D17F', 62),
  ('var_01HZX064F12C1_M_deepburgundy_21E98F', 55),
  ('var_01HZX064F12C1_L_deepburgundy_EEA530', 76),
  ('var_01HZX064F12C1_XL_deepburgundy_BCD42F', 74),
  ('var_01HZX0657230C_XS_black_05CC8C', 1),
  ('var_01HZX0657230C_S_black_5FDAD7', 9),
  ('var_01HZX0657230C_M_black_F5ED8A', 8),
  ('var_01HZX0657230C_L_black_1D9B4C', 1),
  ('var_01HZX0657230C_XL_black_AEE7C6', 60),
  ('var_01HZX06612615_XS_sand_EF1AD1', 48),
  ('var_01HZX06612615_S_sand_A3544F', 10),
  ('var_01HZX06612615_M_sand_A48B75', 21),
  ('var_01HZX06612615_L_sand_CB7831', 66),
  ('var_01HZX06612615_XL_sand_C96923', 10),
  ('var_01HZX067FC6AF_XS_midnightblue_9FE7D8', 17),
  ('var_01HZX067FC6AF_S_midnightblue_2FB9C1', 72),
  ('var_01HZX067FC6AF_M_midnightblue_9C402E', 24),
  ('var_01HZX067FC6AF_L_midnightblue_C080B4', 11),
  ('var_01HZX067FC6AF_XL_midnightblue_A190A0', 53),
  ('var_01HZX0682F18D_XS_forestgreen_B0101E', 8),
  ('var_01HZX0682F18D_S_forestgreen_0FB462', 64),
  ('var_01HZX0682F18D_M_forestgreen_2EC480', 10),
  ('var_01HZX0682F18D_L_forestgreen_F9339F', 65),
  ('var_01HZX0682F18D_XL_forestgreen_21ACF2', 35),
  ('var_01HZX069DD580_XS_stone_A673F2', 61),
  ('var_01HZX069DD580_S_stone_66CD93', 4),
  ('var_01HZX069DD580_M_stone_C2D8C5', 4),
  ('var_01HZX069DD580_L_stone_D88F1B', 30),
  ('var_01HZX069DD580_XL_stone_4CCCD5', 30),
  ('var_01HZX070429F3_XS_teal_0D5306', 3),
  ('var_01HZX070429F3_S_teal_05C291', 10),
  ('var_01HZX070429F3_M_teal_47AF43', 9),
  ('var_01HZX070429F3_L_teal_7E62FE', 12),
  ('var_01HZX070429F3_XL_teal_901741', 17),
  ('var_01HZX07187B9E_XS_graphite_A3A21D', 18),
  ('var_01HZX07187B9E_S_graphite_E0A68A', 52),
  ('var_01HZX07187B9E_M_graphite_CAD6C3', 17),
  ('var_01HZX07187B9E_L_graphite_2AD9BB', 16),
  ('var_01HZX07187B9E_XL_graphite_AA0965', 4),
  ('var_01HZX0722E7BB_XS_tan_07F5AA', 19),
  ('var_01HZX0722E7BB_S_tan_E12B2A', 57),
  ('var_01HZX0722E7BB_M_tan_37B029', 45),
  ('var_01HZX0722E7BB_L_tan_37C526', 46),
  ('var_01HZX0722E7BB_XL_tan_D3E757', 74),
  ('var_01HZX0739DCBA_XS_wine_993307', 23),
  ('var_01HZX0739DCBA_S_wine_3B9109', 23),
  ('var_01HZX0739DCBA_M_wine_B78375', 8),
  ('var_01HZX0739DCBA_L_wine_38446A', 35),
  ('var_01HZX0739DCBA_XL_wine_3FB1E9', 10),
  ('var_01HZX074BF315_XS_steelblue_491FAC', 50),
  ('var_01HZX074BF315_S_steelblue_C23EFC', 18),
  ('var_01HZX074BF315_M_steelblue_F2A234', 17),
  ('var_01HZX074BF315_L_steelblue_45D9CB', 40),
  ('var_01HZX074BF315_XL_steelblue_976D57', 24),
  ('var_01HZX075CAF3A_XS_black_FB9C29', 12),
  ('var_01HZX075CAF3A_S_black_509C82', 40),
  ('var_01HZX075CAF3A_M_black_AC0D19', 49),
  ('var_01HZX075CAF3A_L_black_1F3792', 22),
  ('var_01HZX076F5A53_XS_navy_2AAE39', 21),
  ('var_01HZX076F5A53_S_navy_B38A69', 2),
  ('var_01HZX076F5A53_M_navy_8E9947', 74),
  ('var_01HZX076F5A53_L_navy_D8B019', 41),
  ('var_01HZX0777A454_XS_sage_C44AE8', 40),
  ('var_01HZX0777A454_S_sage_DECA3C', 46),
  ('var_01HZX0777A454_M_sage_22FBAF', 46),
  ('var_01HZX0777A454_L_sage_13147E', 12),
  ('var_01HZX07842949_XS_dustyrose_E22585', 51),
  ('var_01HZX07842949_S_dustyrose_300474', 15),
  ('var_01HZX07842949_M_dustyrose_87DC80', 47),
  ('var_01HZX07842949_L_dustyrose_AE1173', 20),
  ('var_01HZX079F7EA2_XS_terracotta_8310E0', 76),
  ('var_01HZX079F7EA2_S_terracotta_84F9A6', 78),
  ('var_01HZX079F7EA2_M_terracotta_75080A', 30),
  ('var_01HZX079F7EA2_L_terracotta_863137', 16),
  ('var_01HZX080C8931_XS_ivory_D43057', 11),
  ('var_01HZX080C8931_S_ivory_CA47B8', 18),
  ('var_01HZX080C8931_M_ivory_013A39', 8),
  ('var_01HZX080C8931_L_ivory_2B7A6F', 20),
  ('var_01HZX081764A2_XS_deepteal_8BB0A8', 9),
  ('var_01HZX081764A2_S_deepteal_132347', 20),
  ('var_01HZX081764A2_M_deepteal_C55003', 62),
  ('var_01HZX081764A2_L_deepteal_39E116', 17),
  ('var_01HZX082D4891_XS_burgundy_DB53EB', 9),
  ('var_01HZX082D4891_S_burgundy_568705', 65),
  ('var_01HZX082D4891_M_burgundy_A3647A', 63),
  ('var_01HZX082D4891_L_burgundy_5EF3E8', 39),
  ('var_01HZX08301444_XS_charcoal_C5A8C3', 15),
  ('var_01HZX08301444_S_charcoal_0ADAE7', 71),
  ('var_01HZX08301444_M_charcoal_DC2545', 60),
  ('var_01HZX08301444_L_charcoal_95ED52', 49),
  ('var_01HZX0843DA3E_XS_coral_C4C546', 50);

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX0843DA3E_S_coral_ECB5E1', 30),
  ('var_01HZX0843DA3E_M_coral_FD49BA', 19),
  ('var_01HZX0843DA3E_L_coral_E2A257', 24),
  ('var_01HZX085CDF38_XS_plum_931C7E', 13),
  ('var_01HZX085CDF38_S_plum_5B354F', 10),
  ('var_01HZX085CDF38_M_plum_A3BC4F', 10),
  ('var_01HZX085CDF38_L_plum_B832F9', 11),
  ('var_01HZX08657E3B_XS_olive_5CA21C', 46),
  ('var_01HZX08657E3B_S_olive_EDC88C', 19),
  ('var_01HZX08657E3B_M_olive_17839E', 19),
  ('var_01HZX08657E3B_L_olive_493907', 20),
  ('var_01HZX0874E45A_XS_midnightblue_D27747', 4),
  ('var_01HZX0874E45A_S_midnightblue_14DBF8', 23),
  ('var_01HZX0874E45A_M_midnightblue_9C170A', 1),
  ('var_01HZX0874E45A_L_midnightblue_0EA905', 57),
  ('var_01HZX0880B378_XS_blushpink_6DA52B', 65),
  ('var_01HZX0880B378_S_blushpink_43133C', 41),
  ('var_01HZX0880B378_M_blushpink_C0C817', 8),
  ('var_01HZX0880B378_L_blushpink_7218A6', 24),
  ('var_01HZX0890DDC6_XS_forestgreen_31FDF3', 10),
  ('var_01HZX0890DDC6_S_forestgreen_BF05E2', 59),
  ('var_01HZX0890DDC6_M_forestgreen_7EC448', 23),
  ('var_01HZX0890DDC6_L_forestgreen_195804', 20),
  ('var_01HZX090404A1_XS_mustard_050C0C', 1),
  ('var_01HZX090404A1_S_mustard_B9603E', 18),
  ('var_01HZX090404A1_M_mustard_18EDC5', 16),
  ('var_01HZX090404A1_L_mustard_FFA616', 3),
  ('var_01HZX091FD149_XS_lavender_961116', 13),
  ('var_01HZX091FD149_S_lavender_AD9613', 1),
  ('var_01HZX091FD149_M_lavender_3CC88E', 59),
  ('var_01HZX091FD149_L_lavender_6EFEE3', 9),
  ('var_01HZX0924A019_XS_cream_383BBF', 56),
  ('var_01HZX0924A019_S_cream_DA8227', 10),
  ('var_01HZX0924A019_M_cream_90060B', 20),
  ('var_01HZX0924A019_L_cream_A79EB8', 51),
  ('var_01HZX09307566_XS_charcoal_22ECB1', 15),
  ('var_01HZX09307566_S_charcoal_18A7B5', 4),
  ('var_01HZX09307566_M_charcoal_785AC6', 61),
  ('var_01HZX09307566_L_charcoal_CF5F00', 21),
  ('var_01HZX09307566_XL_charcoal_F91D4F', 10),
  ('var_01HZX09475580_XS_oatmeal_85ACD3', 2),
  ('var_01HZX09475580_S_oatmeal_7E7516', 14),
  ('var_01HZX09475580_M_oatmeal_B954CE', 13),
  ('var_01HZX09475580_L_oatmeal_29FC74', 76),
  ('var_01HZX09475580_XL_oatmeal_DCAAE3', 10),
  ('var_01HZX0952D0E4_XS_forestgreen_A77B28', 18),
  ('var_01HZX0952D0E4_S_forestgreen_96B1FE', 14),
  ('var_01HZX0952D0E4_M_forestgreen_E3B876', 3),
  ('var_01HZX0952D0E4_L_forestgreen_0E4AED', 53),
  ('var_01HZX0952D0E4_XL_forestgreen_03573E', 16),
  ('var_01HZX096BA323_XS_burgundy_BAB314', 70),
  ('var_01HZX096BA323_S_burgundy_E9008E', 11),
  ('var_01HZX096BA323_M_burgundy_B763F8', 19),
  ('var_01HZX096BA323_L_burgundy_4DD334', 23),
  ('var_01HZX096BA323_XL_burgundy_5FA399', 78),
  ('var_01HZX0975A9A5_XS_slate_165FDA', 75),
  ('var_01HZX0975A9A5_S_slate_053FAB', 57),
  ('var_01HZX0975A9A5_M_slate_1DC85D', 22),
  ('var_01HZX0975A9A5_L_slate_2E248B', 1),
  ('var_01HZX0975A9A5_XL_slate_2CB4E2', 61),
  ('var_01HZX098C50A4_XS_cream_DFF555', 47),
  ('var_01HZX098C50A4_S_cream_0CE817', 4),
  ('var_01HZX098C50A4_M_cream_6366A0', 1),
  ('var_01HZX098C50A4_L_cream_B6D241', 20),
  ('var_01HZX098C50A4_XL_cream_8D6BB7', 4),
  ('var_01HZX0992C9F9_XS_rust_E3125D', 23),
  ('var_01HZX0992C9F9_S_rust_FFC134', 23),
  ('var_01HZX0992C9F9_M_rust_C66723', 37),
  ('var_01HZX0992C9F9_L_rust_FF7A33', 15),
  ('var_01HZX0992C9F9_XL_rust_F49EB7', 4),
  ('var_01HZX10097636_XS_graphite_DDAF9A', 8),
  ('var_01HZX10097636_S_graphite_2FCA23', 15),
  ('var_01HZX10097636_M_graphite_5962AB', 70),
  ('var_01HZX10097636_L_graphite_699D81', 16),
  ('var_01HZX10097636_XL_graphite_0828EA', 15),
  ('var_01HZX10131F77_XS_ivory_99C467', 15),
  ('var_01HZX10131F77_S_ivory_952A59', 11),
  ('var_01HZX10131F77_M_ivory_4BDE25', 21),
  ('var_01HZX10131F77_L_ivory_3CEA48', 42),
  ('var_01HZX10131F77_XL_ivory_45FFCF', 49),
  ('var_01HZX102C7A4D_XS_steelblue_76B41E', 36),
  ('var_01HZX102C7A4D_S_steelblue_605FA3', 4),
  ('var_01HZX102C7A4D_M_steelblue_F7C0EF', 57),
  ('var_01HZX102C7A4D_L_steelblue_F14382', 80),
  ('var_01HZX102C7A4D_XL_steelblue_E73DB0', 21),
  ('var_01HZX103049E0_XS_mustard_ABF52C', 10),
  ('var_01HZX103049E0_S_mustard_BAD759', 24),
  ('var_01HZX103049E0_M_mustard_4677BD', 80),
  ('var_01HZX103049E0_L_mustard_8F0E27', 21),
  ('var_01HZX103049E0_XL_mustard_EDC9E1', 20),
  ('var_01HZX10433FC9_XS_plum_E2A919', 3),
  ('var_01HZX10433FC9_S_plum_59495F', 11),
  ('var_01HZX10433FC9_M_plum_01CF66', 53),
  ('var_01HZX10433FC9_L_plum_024101', 1),
  ('var_01HZX10433FC9_XL_plum_FD1862', 19),
  ('var_01HZX1056D522_XS_maroon_7890E9', 70),
  ('var_01HZX1056D522_S_maroon_BED3EF', 10),
  ('var_01HZX1056D522_M_maroon_D45383', 46),
  ('var_01HZX1056D522_L_maroon_B98690', 40),
  ('var_01HZX1056D522_XL_maroon_4CDA53', 9),
  ('var_01HZX10612544_XS_pebblegray_A4704A', 58),
  ('var_01HZX10612544_S_pebblegray_92AEBB', 45),
  ('var_01HZX10612544_M_pebblegray_80E2F9', 72),
  ('var_01HZX10612544_L_pebblegray_AB7626', 30),
  ('var_01HZX10612544_XL_pebblegray_1C59B9', 53),
  ('var_01HZX10787D6A_XS_olive_B9C842', 18),
  ('var_01HZX10787D6A_S_olive_584F71', 10),
  ('var_01HZX10787D6A_M_olive_9E2071', 43),
  ('var_01HZX10787D6A_L_olive_EA4000', 2),
  ('var_01HZX10787D6A_XL_olive_25164B', 42),
  ('var_01HZX1084A3F6_XS_navy_06F332', 17),
  ('var_01HZX1084A3F6_S_navy_D37885', 15),
  ('var_01HZX1084A3F6_M_navy_7A596E', 3),
  ('var_01HZX1084A3F6_L_navy_E59A65', 33),
  ('var_01HZX1084A3F6_XL_navy_A0FAE7', 9),
  ('var_01HZX1096EF12_XS_translucentblack_77D223', 14),
  ('var_01HZX1096EF12_S_translucentblack_F2DE7A', 15),
  ('var_01HZX1096EF12_M_translucentblack_200879', 69),
  ('var_01HZX1096EF12_L_translucentblack_01B10E', 13),
  ('var_01HZX1096EF12_XL_translucentblack_127839', 45),
  ('var_01HZX1107C1E2_XS_sand_405EDC', 37),
  ('var_01HZX1107C1E2_S_sand_518455', 13),
  ('var_01HZX1107C1E2_M_sand_78FA7F', 24),
  ('var_01HZX1107C1E2_L_sand_9BD170', 11),
  ('var_01HZX1107C1E2_XL_sand_8B2CEB', 20),
  ('var_01HZX111A1816_XS_slategray_E91F0F', 15),
  ('var_01HZX111A1816_S_slategray_1C2455', 15),
  ('var_01HZX111A1816_M_slategray_379583', 21),
  ('var_01HZX111A1816_L_slategray_A1CBF5', 1),
  ('var_01HZX111A1816_XL_slategray_7A868A', 61),
  ('var_01HZX11235EA4_XS_butteryellow_3763A0', 75),
  ('var_01HZX11235EA4_S_butteryellow_498CF3', 50),
  ('var_01HZX11235EA4_M_butteryellow_896B81', 4),
  ('var_01HZX11235EA4_L_butteryellow_8604E2', 13),
  ('var_01HZX11235EA4_XL_butteryellow_E4067B', 63),
  ('var_01HZX11384678_XS_forestgreen_512B35', 43),
  ('var_01HZX11384678_S_forestgreen_F3ECF2', 50),
  ('var_01HZX11384678_M_forestgreen_E53EA5', 23),
  ('var_01HZX11384678_L_forestgreen_1378A8', 13),
  ('var_01HZX11384678_XL_forestgreen_010578', 2),
  ('var_01HZX11402B03_XS_charcoal_378B52', 11),
  ('var_01HZX11402B03_S_charcoal_8A4C07', 20),
  ('var_01HZX11402B03_M_charcoal_27C035', 20),
  ('var_01HZX11402B03_L_charcoal_333758', 68),
  ('var_01HZX11402B03_XL_charcoal_5F8BCD', 11),
  ('var_01HZX115C0A4D_XS_midnightblue_CFB5A2', 46),
  ('var_01HZX115C0A4D_S_midnightblue_5ADA76', 19),
  ('var_01HZX115C0A4D_M_midnightblue_1D68E7', 62),
  ('var_01HZX115C0A4D_L_midnightblue_1EA57B', 9),
  ('var_01HZX115C0A4D_XL_midnightblue_DD4537', 15),
  ('var_01HZX116F83B6_XS_camel_A0FFB9', 67),
  ('var_01HZX116F83B6_S_camel_CB3ED5', 1),
  ('var_01HZX116F83B6_M_camel_AFE20C', 76),
  ('var_01HZX116F83B6_L_camel_66FD1A', 59),
  ('var_01HZX116F83B6_XL_camel_8FFFF0', 15),
  ('var_01HZX11761294_7_white_E5738F', 20),
  ('var_01HZX11761294_8_white_882E35', 63),
  ('var_01HZX11761294_9_white_D7F81E', 22),
  ('var_01HZX11761294_10_white_C3F773', 10),
  ('var_01HZX11761294_11_white_B36D23', 8),
  ('var_01HZX11761294_12_white_2CFEFB', 12),
  ('var_01HZX1187129E_7_offwhite_87E5E5', 49),
  ('var_01HZX1187129E_8_offwhite_AEDF72', 10),
  ('var_01HZX1187129E_9_offwhite_25054C', 21),
  ('var_01HZX1187129E_10_offwhite_1216F6', 65),
  ('var_01HZX1187129E_11_offwhite_27A5B9', 11),
  ('var_01HZX1187129E_12_offwhite_B7E920', 55),
  ('var_01HZX119D1277_7_cream_4843BC', 67),
  ('var_01HZX119D1277_8_cream_C7D088', 20),
  ('var_01HZX119D1277_9_cream_DC077D', 80),
  ('var_01HZX119D1277_10_cream_DAC887', 62),
  ('var_01HZX119D1277_11_cream_E851EB', 18),
  ('var_01HZX119D1277_12_cream_CDF095', 13),
  ('var_01HZX120F9C60_7_navy_46DA49', 40),
  ('var_01HZX120F9C60_8_navy_5C47D1', 79),
  ('var_01HZX120F9C60_9_navy_1A1F0D', 80);

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX120F9C60_10_navy_2CBE83', 1),
  ('var_01HZX120F9C60_11_navy_224A71', 18),
  ('var_01HZX120F9C60_12_navy_2D2F4D', 24),
  ('var_01HZX1215905A_7_allblack_9223A6', 14),
  ('var_01HZX1215905A_8_allblack_34D779', 52),
  ('var_01HZX1215905A_9_allblack_CA144E', 13),
  ('var_01HZX1215905A_10_allblack_7D29A3', 50),
  ('var_01HZX1215905A_11_allblack_B16B03', 24),
  ('var_01HZX1215905A_12_allblack_B97B75', 80),
  ('var_01HZX122D9B14_7_gray_18A0C0', 23),
  ('var_01HZX122D9B14_8_gray_1BC732', 78),
  ('var_01HZX122D9B14_9_gray_E2D96A', 21),
  ('var_01HZX122D9B14_10_gray_1A2E55', 16),
  ('var_01HZX122D9B14_11_gray_D7D739', 10),
  ('var_01HZX122D9B14_12_gray_2442E9', 40),
  ('var_01HZX123E4094_7_olive_A0062D', 24),
  ('var_01HZX123E4094_8_olive_633A2D', 10),
  ('var_01HZX123E4094_9_olive_C6240A', 42),
  ('var_01HZX123E4094_10_olive_344BC7', 44),
  ('var_01HZX123E4094_11_olive_0B3950', 13),
  ('var_01HZX123E4094_12_olive_DE8ACF', 11),
  ('var_01HZX1247FAD9_7_sand_9723B6', 21),
  ('var_01HZX1247FAD9_8_sand_D7C2FB', 24),
  ('var_01HZX1247FAD9_9_sand_00E389', 9),
  ('var_01HZX1247FAD9_10_sand_7FC638', 8),
  ('var_01HZX1247FAD9_11_sand_46CF5E', 18),
  ('var_01HZX1247FAD9_12_sand_D748B1', 14),
  ('var_01HZX125AC267_7_charcoal_FE5CA7', 75),
  ('var_01HZX125AC267_8_charcoal_9BD799', 20),
  ('var_01HZX125AC267_9_charcoal_84E887', 50),
  ('var_01HZX125AC267_10_charcoal_E62E53', 11),
  ('var_01HZX125AC267_11_charcoal_6F1236', 2),
  ('var_01HZX125AC267_12_charcoal_DB52A6', 24),
  ('var_01HZX12691BDE_7_lightgray_6957FC', 43),
  ('var_01HZX12691BDE_8_lightgray_625B70', 16),
  ('var_01HZX12691BDE_9_lightgray_E5038F', 58),
  ('var_01HZX12691BDE_10_lightgray_53D9DE', 72),
  ('var_01HZX12691BDE_11_lightgray_B825C0', 20),
  ('var_01HZX12691BDE_12_lightgray_C2A71E', 23),
  ('var_01HZX127232F6_7_beige_E953D6', 18),
  ('var_01HZX127232F6_8_beige_5D971C', 9),
  ('var_01HZX127232F6_9_beige_A5DC85', 20),
  ('var_01HZX127232F6_10_beige_5A7E53', 30),
  ('var_01HZX127232F6_11_beige_8D8FA2', 79),
  ('var_01HZX127232F6_12_beige_596CFC', 12),
  ('var_01HZX12889982_7_skyblue_17D5DD', 54),
  ('var_01HZX12889982_8_skyblue_267AE3', 31),
  ('var_01HZX12889982_9_skyblue_DD05FA', 72),
  ('var_01HZX12889982_10_skyblue_2472FA', 49),
  ('var_01HZX12889982_11_skyblue_1B5C01', 23),
  ('var_01HZX12889982_12_skyblue_6E18C8', 74),
  ('var_01HZX1291DA14_7_taupe_5B6623', 16),
  ('var_01HZX1291DA14_8_taupe_FE4D8B', 24),
  ('var_01HZX1291DA14_9_taupe_7B4F87', 45),
  ('var_01HZX1291DA14_10_taupe_FF3B0F', 46),
  ('var_01HZX1291DA14_11_taupe_68026D', 37),
  ('var_01HZX1291DA14_12_taupe_89815E', 71),
  ('var_01HZX13080265_7_ivory_4F79C0', 17),
  ('var_01HZX13080265_8_ivory_C7754A', 18),
  ('var_01HZX13080265_9_ivory_D6C34A', 14),
  ('var_01HZX13080265_10_ivory_B733C3', 15),
  ('var_01HZX13080265_11_ivory_CF5298', 45),
  ('var_01HZX13080265_12_ivory_3625A8', 62),
  ('var_01HZX13136F77_7_slate_4F4CB4', 61),
  ('var_01HZX13136F77_8_slate_EBD58F', 30),
  ('var_01HZX13136F77_9_slate_AD531B', 2),
  ('var_01HZX13136F77_10_slate_1221D4', 2),
  ('var_01HZX13136F77_11_slate_DA551D', 10),
  ('var_01HZX13136F77_12_slate_55204A', 20),
  ('var_01HZX132713B9_7_white_373E0E', 42),
  ('var_01HZX132713B9_8_white_0F55EF', 3),
  ('var_01HZX132713B9_9_white_4C07D5', 10),
  ('var_01HZX132713B9_10_white_870E5C', 79),
  ('var_01HZX132713B9_11_white_B9CCFC', 20),
  ('var_01HZX132713B9_12_white_70FDE7', 8),
  ('var_01HZX133BF1C8_7_black_2B51AB', 21),
  ('var_01HZX133BF1C8_8_black_0AAFED', 17),
  ('var_01HZX133BF1C8_9_black_BF51D3', 23),
  ('var_01HZX133BF1C8_10_black_28B514', 1),
  ('var_01HZX133BF1C8_11_black_1DE234', 35),
  ('var_01HZX133BF1C8_12_black_A878E4', 17),
  ('var_01HZX134D5B9A_7_darkbrown_CA983E', 14),
  ('var_01HZX134D5B9A_8_darkbrown_EF81C6', 9),
  ('var_01HZX134D5B9A_9_darkbrown_04314D', 34),
  ('var_01HZX134D5B9A_10_darkbrown_F8DE36', 23),
  ('var_01HZX134D5B9A_11_darkbrown_CC8A4C', 63),
  ('var_01HZX134D5B9A_12_darkbrown_23E82C', 50),
  ('var_01HZX135E48B5_7_oxblood_75CB28', 8),
  ('var_01HZX135E48B5_8_oxblood_C98245', 58),
  ('var_01HZX135E48B5_9_oxblood_4D9BEE', 12),
  ('var_01HZX135E48B5_10_oxblood_854615', 18),
  ('var_01HZX135E48B5_11_oxblood_437AD7', 33),
  ('var_01HZX135E48B5_12_oxblood_50AAFB', 17),
  ('var_01HZX136DAFED_7_tan_D3C7DD', 38),
  ('var_01HZX136DAFED_8_tan_D4A558', 75),
  ('var_01HZX136DAFED_9_tan_AE8B4C', 13),
  ('var_01HZX136DAFED_10_tan_EFF64B', 24),
  ('var_01HZX136DAFED_11_tan_60E450', 52),
  ('var_01HZX136DAFED_12_tan_8D91D4', 18),
  ('var_01HZX137A036C_7_walnut_91E976', 14),
  ('var_01HZX137A036C_8_walnut_14AD39', 22),
  ('var_01HZX137A036C_9_walnut_81D135', 45),
  ('var_01HZX137A036C_10_walnut_3BA5D6', 69),
  ('var_01HZX137A036C_11_walnut_F6EDA6', 12),
  ('var_01HZX137A036C_12_walnut_ED97F6', 23),
  ('var_01HZX13862E11_7_black_8D202D', 22),
  ('var_01HZX13862E11_8_black_20A21F', 13),
  ('var_01HZX13862E11_9_black_CE7BEB', 9),
  ('var_01HZX13862E11_10_black_8A7EA6', 2),
  ('var_01HZX13862E11_11_black_5DB51A', 37),
  ('var_01HZX13862E11_12_black_7926ED', 11),
  ('var_01HZX139E8725_7_cognac_11DCBE', 3),
  ('var_01HZX139E8725_8_cognac_F8BFFC', 22),
  ('var_01HZX139E8725_9_cognac_64AD84', 32),
  ('var_01HZX139E8725_10_cognac_89612F', 13),
  ('var_01HZX139E8725_11_cognac_8E859E', 2),
  ('var_01HZX139E8725_12_cognac_C60C30', 8),
  ('var_01HZX140A9006_7_charcoal_1D8566', 15),
  ('var_01HZX140A9006_8_charcoal_F4874E', 79),
  ('var_01HZX140A9006_9_charcoal_594DB9', 22),
  ('var_01HZX140A9006_10_charcoal_5FD179', 53),
  ('var_01HZX140A9006_11_charcoal_4947D7', 14),
  ('var_01HZX140A9006_12_charcoal_88CD82', 8),
  ('var_01HZX14183BB7_7_midnightblue_D6B44A', 3),
  ('var_01HZX14183BB7_8_midnightblue_17A99A', 53),
  ('var_01HZX14183BB7_9_midnightblue_A565E5', 53),
  ('var_01HZX14183BB7_10_midnightblue_42487D', 3),
  ('var_01HZX14183BB7_11_midnightblue_30A59D', 68),
  ('var_01HZX14183BB7_12_midnightblue_4C7CEE', 40),
  ('var_01HZX1422D279_7_espresso_04020D', 4),
  ('var_01HZX1422D279_8_espresso_57618A', 31),
  ('var_01HZX1422D279_9_espresso_C7B248', 12),
  ('var_01HZX1422D279_10_espresso_9AAC59', 1),
  ('var_01HZX1422D279_11_espresso_4207D2', 12),
  ('var_01HZX1422D279_12_espresso_817051', 19),
  ('var_01HZX14302FF2_7_sand_50E9C2', 31),
  ('var_01HZX14302FF2_8_sand_C30BB6', 10),
  ('var_01HZX14302FF2_9_sand_FB2050', 14),
  ('var_01HZX14302FF2_10_sand_364202', 19),
  ('var_01HZX14302FF2_11_sand_195A21', 32),
  ('var_01HZX14302FF2_12_sand_7175DE', 20),
  ('var_01HZX1446DC9A_7_burgundy_6E8EC1', 24),
  ('var_01HZX1446DC9A_8_burgundy_1D1FD2', 69),
  ('var_01HZX1446DC9A_9_burgundy_971123', 15),
  ('var_01HZX1446DC9A_10_burgundy_61C288', 58),
  ('var_01HZX1446DC9A_11_burgundy_B09E90', 2),
  ('var_01HZX1446DC9A_12_burgundy_96AE70', 19),
  ('var_01HZX145F81B7_7_graphite_F9344B', 22),
  ('var_01HZX145F81B7_8_graphite_74EF65', 10),
  ('var_01HZX145F81B7_9_graphite_60CBE7', 10),
  ('var_01HZX145F81B7_10_graphite_C0CB0F', 73),
  ('var_01HZX145F81B7_11_graphite_392A1C', 17),
  ('var_01HZX145F81B7_12_graphite_79E95F', 4),
  ('var_01HZX146DC626_7_camel_61DCE2', 21),
  ('var_01HZX146DC626_8_camel_84392B', 76),
  ('var_01HZX146DC626_9_camel_685E3B', 14),
  ('var_01HZX146DC626_10_camel_61B881', 32),
  ('var_01HZX146DC626_11_camel_0EE6B4', 4),
  ('var_01HZX146DC626_12_camel_9AF21A', 17),
  ('var_01HZX147B19E0_ONE_SIZE_black_4635F2', 48),
  ('var_01HZX148501A3_ONE_SIZE_charcoal_64C39E', 49),
  ('var_01HZX1494D48D_ONE_SIZE_olive_04123F', 21),
  ('var_01HZX1505B8A8_ONE_SIZE_navy_4E4BE0', 16),
  ('var_01HZX151036EE_ONE_SIZE_sand_926955', 3),
  ('var_01HZX152E9B46_ONE_SIZE_slate_080848', 49),
  ('var_01HZX1537264B_ONE_SIZE_forestgreen_0ADB6E', 1),
  ('var_01HZX154A2535_ONE_SIZE_tan_CD0706', 3),
  ('var_01HZX15535D86_ONE_SIZE_graphite_5FAE5F', 43),
  ('var_01HZX156A0986_ONE_SIZE_burgundy_765CFD', 66),
  ('var_01HZX15734629_ONE_SIZE_stone_7C24A0', 33),
  ('var_01HZX158EC477_ONE_SIZE_steelblue_702E3E', 17),
  ('var_01HZX15904744_ONE_SIZE_tortoise_66EA5B', 10),
  ('var_01HZX160B757F_ONE_SIZE_matteblack_4D99ED', 4),
  ('var_01HZX161A7F7D_ONE_SIZE_gunmetal_DECED0', 70),
  ('var_01HZX162BE15C_ONE_SIZE_clear_713087', 45),
  ('var_01HZX16343326_ONE_SIZE_brown_FE100E', 76),
  ('var_01HZX16429B41_ONE_SIZE_matteblack_298217', 14),
  ('var_01HZX16529DDC_ONE_SIZE_tortoise_AB95E8', 44),
  ('var_01HZX1662C0FF_ONE_SIZE_gunmetal_4392B8', 4),
  ('var_01HZX16737A05_ONE_SIZE_charcoal_0B5D24', 62),
  ('var_01HZX16874C2F_ONE_SIZE_amber_6C382B', 45),
  ('var_01HZX169EF961_ONE_SIZE_navy_BA646D', 73),
  ('var_01HZX170BD98F_ONE_SIZE_silver_9E185F', 50),
  ('var_01HZX171249AB_ONE_SIZE_olive_8AD183', 15),
  ('var_01HZX172FFE1D_ONE_SIZE_cream_F27187', 43),
  ('var_01HZX173F4F9D_ONE_SIZE_navy_152FD1', 4),
  ('var_01HZX174678B4_ONE_SIZE_camel_8C6094', 1),
  ('var_01HZX1758E7B8_ONE_SIZE_black_943AFE', 48),
  ('var_01HZX176B4C3D_ONE_SIZE_deepteal_262AEA', 13),
  ('var_01HZX1773E1F6_ONE_SIZE_olive_755E32', 4),
  ('var_01HZX1788C252_ONE_SIZE_wine_418000', 16),
  ('var_01HZX1796A629_ONE_SIZE_espresso_9725C0', 13),
  ('var_01HZX18042163_ONE_SIZE_sage_6C6E9D', 77),
  ('var_01HZX181D0B37_ONE_SIZE_black_FD09AE', 14),
  ('var_01HZX1828E989_ONE_SIZE_charcoal_FA3DE8', 22),
  ('var_01HZX183622D3_S/M_olive_FB4ADE', 70),
  ('var_01HZX183622D3_L/XL_olive_0D1565', 46),
  ('var_01HZX184DA162_ONE_SIZE_navy_D8FB27', 30),
  ('var_01HZX185DBA6D_ONE_SIZE_sand_ED6165', 14),
  ('var_01HZX18690CD3_ONE_SIZE_slate_6D9FE9', 8);

INSERT OR IGNORE INTO inventory (variant_id, quantity) VALUES
  ('var_01HZX187CDE05_ONE_SIZE_forestgreen_A48EAB', 75),
  ('var_01HZX18843E1A_ONE_SIZE_tan_FCF1E4', 14),
  ('var_01HZX1894C92B_S/M_graphite_2F7EAC', 79),
  ('var_01HZX1894C92B_L/XL_graphite_9EB1A5', 17),
  ('var_01HZX19085328_ONE_SIZE_burgundy_B84534', 66),
  ('var_01HZX191E8813_ONE_SIZE_stone_F02FAD', 8),
  ('var_01HZX192C159C_ONE_SIZE_midnightblue_4F960B', 10),
  ('var_01HZX193C9A38_ONE_SIZE_camel_56E98E', 9),
  ('var_01HZX19465179_ONE_SIZE_steelblue_AD57FA', 59),
  ('var_01HZX195A9CC5_S/M_espresso_CF4A62', 57),
  ('var_01HZX195A9CC5_L/XL_espresso_0E50D1', 9),
  ('var_01HZX1968B4BC_ONE_SIZE_sage_7015C6', 20),
  ('var_01HZX1978AC07_ONE_SIZE_pewter_183E2F', 56),
  ('var_01HZX1989AE7B_ONE_SIZE_rust_4C319C', 19),
  ('var_01HZX199AFA79_ONE_SIZE_ivory_C0DA90', 3),
  ('var_01HZX200DFBE7_ONE_SIZE_teal_BB0CD2', 24);


-- ============================================================================
-- seed/08_seed_coupons.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 08 - Coupons (3 rows)
-- Target table: coupons
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM coupons;

INSERT INTO coupons (coupon_id, code, type, value, currency, scope_categories, excludes_categories, conditions_json, valid_from, valid_to, active) VALUES
  ('cou_summit10', 'SUMMIT10', 'percent', 10.00, 'USD', '[]', '[]', '{}', '2026-04-27 00:00:00', '2026-09-24 00:00:00', TRUE),
  ('cou_welcome15', 'WELCOME15', 'percent', 15.00, 'USD', '[]', '[]', '{"minSubtotal":75.0}', '2026-05-13 00:00:00', '2026-07-26 00:00:00', TRUE),
  ('cou_jackets20', 'JACKETS20', 'percent', 20.00, 'USD', '["jackets"]', '[]', '{}', '2026-05-20 00:00:00', '2026-06-26 00:00:00', TRUE);


-- ============================================================================
-- seed/09_seed_promotions.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 09 - Promotions (2 rows)
-- Target table: promotions
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM promotions;

INSERT INTO promotions (promotion_id, name, type, value, scope_json, priority, valid_from, valid_to, active) VALUES
  ('pro_summit_storewide', 'CF Summit Weekend', 'percent', 5.00, '{}', 1, '2026-05-25 00:00:00', '2026-06-01 00:00:00', TRUE),
  ('pro_jackets_seasonal', 'Jackets Refresh', 'percent', 15.00, '{"categories":["jackets","raincoats"]}', 2, '2026-05-17 00:00:00', '2026-07-11 00:00:00', TRUE);


-- ============================================================================
-- seed/10_seed_product_reviews.sql
-- ============================================================================
-- StyleMart MySQL seed data
-- 10 - Product reviews (600 rows)
-- Target table: product_reviews
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql


DELETE FROM product_reviews;

INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified, created_at) VALUES
  ('rev_6237A4ABFF4582C3', 'prd_01HZX001B79A0', 'usr_demo_003', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-11-10 00:00:00'),
  ('rev_E87322E4C60AD553', 'prd_01HZX001B79A0', 'usr_demo_002', 5, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-08-30 00:00:00'),
  ('rev_A41AC1A06DC7DBA1', 'prd_01HZX002DC84B', 'usr_demo_005', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in black.', TRUE, '2026-04-16 00:00:00'),
  ('rev_7DBE15A09999C499', 'prd_01HZX002DC84B', 'usr_demo_001', 5, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-05-31 00:00:00'),
  ('rev_59D093940D726B4E', 'prd_01HZX002DC84B', 'usr_demo_002', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2025-09-10 00:00:00'),
  ('rev_0DFFA4E387485E6A', 'prd_01HZX002DC84B', 'usr_demo_004', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2026-04-08 00:00:00'),
  ('rev_F2CAE51D9BD0D14B', 'prd_01HZX003C4E7A', 'usr_demo_004', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2025-09-01 00:00:00'),
  ('rev_704962E094F3DBEC', 'prd_01HZX003C4E7A', 'usr_demo_002', 5, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-11-01 00:00:00'),
  ('rev_828824E36D261157', 'prd_01HZX003C4E7A', 'usr_demo_001', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-07-22 00:00:00'),
  ('rev_C82C6D5376E87F82', 'prd_01HZX00469D94', 'usr_demo_002', 5, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2025-09-10 00:00:00'),
  ('rev_0C6A807F22846B52', 'prd_01HZX00469D94', 'usr_demo_003', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-06-24 00:00:00'),
  ('rev_4EFC03408B43B7F3', 'prd_01HZX00469D94', 'usr_demo_001', 4, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2026-01-10 00:00:00'),
  ('rev_F51F0FB812793FD2', 'prd_01HZX00469D94', 'usr_demo_004', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in cream.', TRUE, '2026-01-08 00:00:00'),
  ('rev_395E89FDAE602C43', 'prd_01HZX005E0B47', 'usr_demo_003', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in cream.', TRUE, '2025-06-26 00:00:00'),
  ('rev_7E40F41C674E549F', 'prd_01HZX005E0B47', 'usr_demo_001', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2026-03-02 00:00:00'),
  ('rev_26A74F0A14A818D4', 'prd_01HZX005E0B47', 'usr_demo_002', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2025-09-26 00:00:00'),
  ('rev_6A352D91FC8AC875', 'prd_01HZX006E013F', 'usr_demo_003', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', FALSE, '2025-06-26 00:00:00'),
  ('rev_8965552669527EB6', 'prd_01HZX006E013F', 'usr_demo_005', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-12-10 00:00:00'),
  ('rev_D32E4A0B6DADC1D1', 'prd_01HZX007467E4', 'usr_demo_005', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in cream.', TRUE, '2026-04-19 00:00:00'),
  ('rev_93C60C14C8DC9CD4', 'prd_01HZX007467E4', 'usr_demo_003', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', FALSE, '2025-06-27 00:00:00'),
  ('rev_4A6F0D60A5D45A42', 'prd_01HZX007467E4', 'usr_demo_002', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', FALSE, '2025-07-16 00:00:00'),
  ('rev_9BE2BBAD07119B7A', 'prd_01HZX00824F04', 'usr_demo_003', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2025-11-09 00:00:00'),
  ('rev_D86D11EA5BCA08FF', 'prd_01HZX00824F04', 'usr_demo_002', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2026-03-26 00:00:00'),
  ('rev_401E7CC444387F00', 'prd_01HZX00824F04', 'usr_demo_001', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in navy.', TRUE, '2025-10-22 00:00:00'),
  ('rev_024099F435500925', 'prd_01HZX0092B381', 'usr_demo_003', 4, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2026-03-07 00:00:00'),
  ('rev_9FDE2CB9DBFD2BDD', 'prd_01HZX0092B381', 'usr_demo_002', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2025-10-29 00:00:00'),
  ('rev_11A277070E4856C7', 'prd_01HZX0092B381', 'usr_demo_001', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2026-05-19 00:00:00'),
  ('rev_4CE1AA5702526220', 'prd_01HZX0092B381', 'usr_demo_004', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2026-02-12 00:00:00'),
  ('rev_EEF8E7CC265DD3CF', 'prd_01HZX010C1DC3', 'usr_demo_001', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2026-03-23 00:00:00'),
  ('rev_D7B863B335AD3612', 'prd_01HZX010C1DC3', 'usr_demo_004', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-11-25 00:00:00'),
  ('rev_10048833F9693062', 'prd_01HZX010C1DC3', 'usr_demo_002', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2025-10-31 00:00:00'),
  ('rev_54E246841503A791', 'prd_01HZX01118584', 'usr_demo_005', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-07-31 00:00:00'),
  ('rev_513DE1366A21691A', 'prd_01HZX01118584', 'usr_demo_001', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in cream.', TRUE, '2026-03-08 00:00:00'),
  ('rev_12CD86B0A478F295', 'prd_01HZX0126D23C', 'usr_demo_005', 5, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2026-01-25 00:00:00'),
  ('rev_F527B314B7B5FE0F', 'prd_01HZX0126D23C', 'usr_demo_003', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2025-11-07 00:00:00'),
  ('rev_3CE5AE2B357D58AA', 'prd_01HZX013AB385', 'usr_demo_003', 4, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-06-06 00:00:00'),
  ('rev_36448AD31A0DCA90', 'prd_01HZX013AB385', 'usr_demo_001', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2025-11-12 00:00:00'),
  ('rev_7093A91166CE1B5E', 'prd_01HZX013AB385', 'usr_demo_002', 5, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2025-11-19 00:00:00'),
  ('rev_231C24E9AAD27624', 'prd_01HZX013AB385', 'usr_demo_005', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in black.', FALSE, '2025-06-25 00:00:00'),
  ('rev_C1FF447A1C7AD84E', 'prd_01HZX0142D7F7', 'usr_demo_005', 4, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-07-03 00:00:00'),
  ('rev_756D407E4BC59638', 'prd_01HZX0142D7F7', 'usr_demo_001', 5, 'Premium feel.', 'Hand-feel is way above the price point. Buying another in cream.', TRUE, '2025-09-11 00:00:00'),
  ('rev_2E4D38ABA83F3FDC', 'prd_01HZX0142D7F7', 'usr_demo_002', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', FALSE, '2025-08-12 00:00:00'),
  ('rev_5C6ADE24EABCFFDF', 'prd_01HZX0142D7F7', 'usr_demo_003', 4, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2026-05-20 00:00:00'),
  ('rev_EC124781752C8202', 'prd_01HZX0154D2D3', 'usr_demo_004', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', FALSE, '2025-11-18 00:00:00'),
  ('rev_6727C247A565EE88', 'prd_01HZX0154D2D3', 'usr_demo_002', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2026-01-05 00:00:00'),
  ('rev_8D9B416F96544BD0', 'prd_01HZX0161A9D0', 'usr_demo_002', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2026-04-09 00:00:00'),
  ('rev_A01638208077DD4D', 'prd_01HZX0161A9D0', 'usr_demo_004', 5, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', FALSE, '2025-12-09 00:00:00'),
  ('rev_9FE0D5644350FEF0', 'prd_01HZX0161A9D0', 'usr_demo_001', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', TRUE, '2025-09-22 00:00:00'),
  ('rev_BD3ACF081BDCB972', 'prd_01HZX01710C1A', 'usr_demo_003', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', FALSE, '2025-09-08 00:00:00'),
  ('rev_05B219C03F67A031', 'prd_01HZX01710C1A', 'usr_demo_002', 4, 'Good basic, slightly thin.', 'Fabric is comfortable but feels lighter than expected. Still wear-worthy.', TRUE, '2025-06-11 00:00:00'),
  ('rev_115EC90EB7C8710C', 'prd_01HZX01710C1A', 'usr_demo_001', 3, 'Decent but plain.', 'Nothing wrong with it; nothing special either.', TRUE, '2026-02-15 00:00:00'),
  ('rev_9607267A66CD7973', 'prd_01HZX01710C1A', 'usr_demo_004', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', FALSE, '2025-12-31 00:00:00'),
  ('rev_DDC204B789BDF84B', 'prd_01HZX01855961', 'usr_demo_001', 5, 'Soft and runs true to size.', 'Fit is true to size, fabric softens after one wash. Daily wear pick.', FALSE, '2025-09-18 00:00:00'),
  ('rev_CEDC5051DB200B80', 'prd_01HZX01855961', 'usr_demo_004', 5, 'Holds shape well.', 'Washed several times, still keeps its shape and color.', TRUE, '2026-04-21 00:00:00'),
  ('rev_07A2481EC9C16FAD', 'prd_01HZX01855961', 'usr_demo_002', 5, 'Great layering tee.', 'Layers cleanly under a blazer. Sleeves sit just right.', TRUE, '2026-04-10 00:00:00'),
  ('rev_3A05C0892FFB8347', 'prd_01HZX019AA2CD', 'usr_demo_005', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-06-25 00:00:00'),
  ('rev_F0A6BAABA7B6E27C', 'prd_01HZX019AA2CD', 'usr_demo_001', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-12-07 00:00:00'),
  ('rev_AD737B3EC4ACE709', 'prd_01HZX019AA2CD', 'usr_demo_002', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2025-07-14 00:00:00'),
  ('rev_A49B97E6A5DE68BF', 'prd_01HZX019AA2CD', 'usr_demo_003', 5, 'Crisp without ironing.', 'Holds a press through the day. Worn it to two meetings already.', FALSE, '2025-11-12 00:00:00'),
  ('rev_AA32DC3CCA5F0B8D', 'prd_01HZX020F074E', 'usr_demo_001', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-11-04 00:00:00'),
  ('rev_76EF04399FD18A2B', 'prd_01HZX020F074E', 'usr_demo_003', 4, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2026-02-07 00:00:00'),
  ('rev_713059ED937F0CA8', 'prd_01HZX020F074E', 'usr_demo_005', 3, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2026-04-27 00:00:00'),
  ('rev_8CDA15E1D8CEA51E', 'prd_01HZX02133D5C', 'usr_demo_005', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2026-05-11 00:00:00'),
  ('rev_6B3C47580FD21938', 'prd_01HZX02133D5C', 'usr_demo_004', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-08-06 00:00:00'),
  ('rev_7A0E0F39ED005A02', 'prd_01HZX02133D5C', 'usr_demo_003', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2026-05-16 00:00:00'),
  ('rev_F2A2D883ED46BF30', 'prd_01HZX02236351', 'usr_demo_005', 5, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2025-08-08 00:00:00'),
  ('rev_AEAEED7720F76B87', 'prd_01HZX02236351', 'usr_demo_001', 5, 'Crisp without ironing.', 'Holds a press through the day. Worn it to two meetings already.', TRUE, '2025-10-17 00:00:00'),
  ('rev_CAB104D8FD535BB1', 'prd_01HZX023EEA5C', 'usr_demo_001', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2025-07-06 00:00:00'),
  ('rev_55F74615A142F43B', 'prd_01HZX023EEA5C', 'usr_demo_002', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2026-01-03 00:00:00'),
  ('rev_84A7B0C04FB06919', 'prd_01HZX024F0015', 'usr_demo_002', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', FALSE, '2025-06-28 00:00:00'),
  ('rev_E952594AA9CCAA8E', 'prd_01HZX024F0015', 'usr_demo_005', 4, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2026-01-09 00:00:00'),
  ('rev_31CAAAF6C8FF13DC', 'prd_01HZX024F0015', 'usr_demo_003', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2026-05-18 00:00:00'),
  ('rev_DB8851657EB2AB25', 'prd_01HZX024F0015', 'usr_demo_001', 5, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2026-03-13 00:00:00'),
  ('rev_DF40E7BE924B99D4', 'prd_01HZX025162AE', 'usr_demo_002', 3, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2026-03-22 00:00:00'),
  ('rev_C77FEE19F3D9AC77', 'prd_01HZX025162AE', 'usr_demo_005', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', FALSE, '2025-09-26 00:00:00'),
  ('rev_7357A21103154C33', 'prd_01HZX025162AE', 'usr_demo_001', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2026-04-18 00:00:00'),
  ('rev_3F0819D8CDC3E129', 'prd_01HZX025162AE', 'usr_demo_003', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-11-03 00:00:00'),
  ('rev_7E357B3D938937F2', 'prd_01HZX026D3A3F', 'usr_demo_004', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-07-21 00:00:00'),
  ('rev_032DFB0B3B3BDB68', 'prd_01HZX026D3A3F', 'usr_demo_001', 5, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', FALSE, '2025-06-10 00:00:00'),
  ('rev_0FE18A42BE799512', 'prd_01HZX027E5251', 'usr_demo_004', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', FALSE, '2025-06-23 00:00:00'),
  ('rev_DBE4A2C4CD170F69', 'prd_01HZX027E5251', 'usr_demo_002', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2026-04-15 00:00:00'),
  ('rev_2E8FC24278C1E112', 'prd_01HZX027E5251', 'usr_demo_001', 5, 'Crisp without ironing.', 'Holds a press through the day. Worn it to two meetings already.', TRUE, '2025-12-03 00:00:00'),
  ('rev_DA49D833F45A2A07', 'prd_01HZX028EE8C5', 'usr_demo_002', 4, 'Color is true to photo.', 'Color is exactly what the photo shows.', FALSE, '2026-01-14 00:00:00'),
  ('rev_0719750D389AB77A', 'prd_01HZX028EE8C5', 'usr_demo_001', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-10-30 00:00:00'),
  ('rev_1D7B8B4099101D79', 'prd_01HZX028EE8C5', 'usr_demo_003', 5, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2025-05-28 00:00:00'),
  ('rev_036653F48ADC4C9F', 'prd_01HZX028EE8C5', 'usr_demo_004', 5, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-09-30 00:00:00'),
  ('rev_CA8CBB2F1D709B57', 'prd_01HZX0299CD6E', 'usr_demo_004', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-08-28 00:00:00'),
  ('rev_86EA9299DA39C04E', 'prd_01HZX0299CD6E', 'usr_demo_001', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-08-23 00:00:00'),
  ('rev_F5A1D3DD16F5E537', 'prd_01HZX0299CD6E', 'usr_demo_002', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2026-03-11 00:00:00'),
  ('rev_D8F75D18A1896BD2', 'prd_01HZX0299CD6E', 'usr_demo_005', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-09-26 00:00:00'),
  ('rev_AE5BC860C153D596', 'prd_01HZX0302514B', 'usr_demo_004', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-10-05 00:00:00'),
  ('rev_F4F96820B8A84C4F', 'prd_01HZX0302514B', 'usr_demo_001', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-12-26 00:00:00'),
  ('rev_F10580C379E20494', 'prd_01HZX03104039', 'usr_demo_003', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-09-24 00:00:00'),
  ('rev_E443AD5478861BB1', 'prd_01HZX03104039', 'usr_demo_001', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-08-15 00:00:00'),
  ('rev_339D26A9DEA1CA50', 'prd_01HZX03104039', 'usr_demo_002', 5, 'Crisp without ironing.', 'Holds a press through the day. Worn it to two meetings already.', TRUE, '2026-01-06 00:00:00'),
  ('rev_200C4BD8637B0BA7', 'prd_01HZX03216941', 'usr_demo_005', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-11-06 00:00:00'),
  ('rev_A4C56DA66D096547', 'prd_01HZX03216941', 'usr_demo_001', 5, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2026-04-09 00:00:00'),
  ('rev_112DB3D3A94B006D', 'prd_01HZX03216941', 'usr_demo_003', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-11-10 00:00:00'),
  ('rev_2C50C01DAF8209A7', 'prd_01HZX03216941', 'usr_demo_002', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-09-08 00:00:00'),
  ('rev_F0EDA120EF0ED7D9', 'prd_01HZX033157E7', 'usr_demo_002', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-05-31 00:00:00'),
  ('rev_4B898EDB98A35887', 'prd_01HZX033157E7', 'usr_demo_001', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-10-26 00:00:00'),
  ('rev_B392EB1A5C42BB79', 'prd_01HZX033157E7', 'usr_demo_003', 5, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', FALSE, '2025-06-05 00:00:00'),
  ('rev_AD99E8110ADDCDCD', 'prd_01HZX034CB2B2', 'usr_demo_001', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2026-03-29 00:00:00'),
  ('rev_733672A21FC1E12A', 'prd_01HZX034CB2B2', 'usr_demo_005', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2026-03-14 00:00:00'),
  ('rev_7AEEBA8050248712', 'prd_01HZX034CB2B2', 'usr_demo_003', 5, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-08-21 00:00:00'),
  ('rev_6376737C275B5494', 'prd_01HZX034CB2B2', 'usr_demo_002', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-12-20 00:00:00'),
  ('rev_BE5E522C5EC67540', 'prd_01HZX035816E9', 'usr_demo_005', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2025-12-20 00:00:00'),
  ('rev_6EBEB6C07FC4DC82', 'prd_01HZX035816E9', 'usr_demo_001', 5, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-05-31 00:00:00'),
  ('rev_1F04E70DB58FB98A', 'prd_01HZX035816E9', 'usr_demo_003', 5, 'Travels well.', 'Rolled in carry-on for a week and hung out wrinkle-free.', TRUE, '2025-12-27 00:00:00'),
  ('rev_067A97C97F692F0B', 'prd_01HZX0363DC1B', 'usr_demo_005', 4, 'Fits a touch slim.', 'Sizing runs a bit slim through the shoulders. Sized up to L.', TRUE, '2025-09-30 00:00:00'),
  ('rev_86F9480262F89B7D', 'prd_01HZX0363DC1B', 'usr_demo_003', 5, 'Color is true to photo.', 'Color is exactly what the photo shows.', TRUE, '2026-05-14 00:00:00'),
  ('rev_CCFA63C0BE7E836C', 'prd_01HZX0363DC1B', 'usr_demo_001', 3, 'Buttons feel cheap.', 'Buttons feel a notch below the rest of the build.', TRUE, '2025-12-18 00:00:00'),
  ('rev_B8ADA278749535B1', 'prd_01HZX0363DC1B', 'usr_demo_002', 5, 'Versatile cut.', 'Pairs with jeans on Friday and trousers on Monday.', TRUE, '2025-08-31 00:00:00'),
  ('rev_87BDEF35014B837F', 'prd_01HZX0379CC49', 'usr_demo_002', 4, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', FALSE, '2026-05-03 00:00:00'),
  ('rev_1C97A67CCD190582', 'prd_01HZX0379CC49', 'usr_demo_004', 5, 'Best fit jeans in a while.', 'Comfortable through the day, hold shape after multiple wears.', TRUE, '2025-10-07 00:00:00'),
  ('rev_ABE6F8FDEF2508BF', 'prd_01HZX0379CC49', 'usr_demo_001', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2025-12-25 00:00:00'),
  ('rev_17D3E6263257874A', 'prd_01HZX038D8B0C', 'usr_demo_004', 5, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2025-09-22 00:00:00'),
  ('rev_E1BEA0B0CCF32770', 'prd_01HZX038D8B0C', 'usr_demo_001', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2025-12-30 00:00:00'),
  ('rev_DD7E8E1EC73E1C2C', 'prd_01HZX038D8B0C', 'usr_demo_002', 5, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-07-20 00:00:00'),
  ('rev_C5300B230EA4BE38', 'prd_01HZX03959B15', 'usr_demo_004', 5, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2026-02-25 00:00:00'),
  ('rev_09FACFDB419E2EC9', 'prd_01HZX03959B15', 'usr_demo_005', 5, 'Best fit jeans in a while.', 'Comfortable through the day, hold shape after multiple wears.', TRUE, '2026-01-06 00:00:00'),
  ('rev_434C6DBF7466ECBA', 'prd_01HZX03959B15', 'usr_demo_003', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2026-02-04 00:00:00'),
  ('rev_DC55707CBB478DA0', 'prd_01HZX0403CEB8', 'usr_demo_001', 5, 'Compliments often.', 'Multiple compliments first time wearing.', FALSE, '2026-05-20 00:00:00'),
  ('rev_7AD37DF396DFE30F', 'prd_01HZX0403CEB8', 'usr_demo_002', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2026-04-11 00:00:00'),
  ('rev_BCD02A560302E6BE', 'prd_01HZX0403CEB8', 'usr_demo_005', 4, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-09-27 00:00:00'),
  ('rev_5AC1B6549F62E12E', 'prd_01HZX0403CEB8', 'usr_demo_004', 4, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2025-09-25 00:00:00'),
  ('rev_23DDF2191D4C6382', 'prd_01HZX041CC651', 'usr_demo_005', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2026-03-20 00:00:00'),
  ('rev_0C82EB46BB381AF3', 'prd_01HZX041CC651', 'usr_demo_004', 5, 'Best fit jeans in a while.', 'Comfortable through the day, hold shape after multiple wears.', TRUE, '2025-06-11 00:00:00'),
  ('rev_8AEF23B45E2602A9', 'prd_01HZX041CC651', 'usr_demo_001', 5, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', FALSE, '2025-11-25 00:00:00'),
  ('rev_A583C47DCBB2BCFF', 'prd_01HZX042115D1', 'usr_demo_001', 5, 'Compliments often.', 'Multiple compliments first time wearing.', TRUE, '2025-06-12 00:00:00'),
  ('rev_B107A0278864A0B6', 'prd_01HZX042115D1', 'usr_demo_002', 5, 'Best fit jeans in a while.', 'Comfortable through the day, hold shape after multiple wears.', TRUE, '2025-05-29 00:00:00'),
  ('rev_ADCD1919EEF8882B', 'prd_01HZX042115D1', 'usr_demo_003', 5, 'Tight in the thigh.', 'Fit through the thigh is tight for an athletic build.', TRUE, '2026-05-14 00:00:00'),
  ('rev_6A53E07F723FE12B', 'prd_01HZX042115D1', 'usr_demo_004', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2025-09-05 00:00:00'),
  ('rev_5E0F0743EF746EFC', 'prd_01HZX04321198', 'usr_demo_003', 5, 'Compliments often.', 'Multiple compliments first time wearing.', TRUE, '2025-12-26 00:00:00'),
  ('rev_6911CEC5B1A127B2', 'prd_01HZX04321198', 'usr_demo_004', 4, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2025-07-06 00:00:00'),
  ('rev_8D6D44476471A44C', 'prd_01HZX04321198', 'usr_demo_005', 5, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-09-14 00:00:00'),
  ('rev_9042C1BFC14219A4', 'prd_01HZX04321198', 'usr_demo_002', 5, 'Tight in the thigh.', 'Fit through the thigh is tight for an athletic build.', TRUE, '2025-07-30 00:00:00'),
  ('rev_0CEBB83C5E30D989', 'prd_01HZX0449E075', 'usr_demo_002', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2026-03-05 00:00:00'),
  ('rev_834C082688ABEA6B', 'prd_01HZX0449E075', 'usr_demo_004', 4, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', FALSE, '2025-07-20 00:00:00'),
  ('rev_74D7806A0A9ED214', 'prd_01HZX045DDBC0', 'usr_demo_001', 5, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2025-06-22 00:00:00'),
  ('rev_8EC75D5A5515DC7C', 'prd_01HZX045DDBC0', 'usr_demo_002', 5, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-11-22 00:00:00'),
  ('rev_6389EF6C1FFC07D6', 'prd_01HZX045DDBC0', 'usr_demo_003', 5, 'Worth the price.', 'Stitching and pocketing detail noticeably better than fast fashion.', TRUE, '2026-05-01 00:00:00'),
  ('rev_5597D27EBFAAE65B', 'prd_01HZX04673CA4', 'usr_demo_001', 5, 'Tight in the thigh.', 'Fit through the thigh is tight for an athletic build.', TRUE, '2025-07-28 00:00:00'),
  ('rev_94876BE273843794', 'prd_01HZX04673CA4', 'usr_demo_004', 4, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-11-14 00:00:00'),
  ('rev_A84923F5E2970C8C', 'prd_01HZX04784E6E', 'usr_demo_005', 4, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2025-08-23 00:00:00'),
  ('rev_DFAE2F20DBB25FB2', 'prd_01HZX04784E6E', 'usr_demo_001', 4, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', TRUE, '2025-06-30 00:00:00'),
  ('rev_6957088E31F04978', 'prd_01HZX04784E6E', 'usr_demo_004', 3, 'Tight in the thigh.', 'Fit through the thigh is tight for an athletic build.', TRUE, '2026-03-22 00:00:00'),
  ('rev_6067EEFEBF4FC467', 'prd_01HZX048241B3', 'usr_demo_004', 5, 'Tight in the thigh.', 'Fit through the thigh is tight for an athletic build.', TRUE, '2025-06-22 00:00:00'),
  ('rev_B531510317A75978', 'prd_01HZX048241B3', 'usr_demo_003', 4, 'Wash is right.', 'Wash is exactly the photo. Sit at the waist as advertised.', TRUE, '2026-03-05 00:00:00'),
  ('rev_54CCB18D5361432D', 'prd_01HZX048241B3', 'usr_demo_001', 5, 'Solid pair.', 'Good denim weight, nice indigo cast. Inseam runs a hair long.', FALSE, '2026-03-02 00:00:00'),
  ('rev_143E4E2A6FA2B4C9', 'prd_01HZX048241B3', 'usr_demo_002', 5, 'Best fit jeans in a while.', 'Comfortable through the day, hold shape after multiple wears.', TRUE, '2025-07-04 00:00:00'),
  ('rev_256362AC95B2D66A', 'prd_01HZX04904E67', 'usr_demo_005', 5, 'Smart-casual win.', 'Works for office and dinner both.', FALSE, '2026-01-09 00:00:00'),
  ('rev_1E8395D7DBAFD082', 'prd_01HZX04904E67', 'usr_demo_001', 5, 'Good but a touch warm.', 'Heavier than expected. Better for cooler days.', FALSE, '2025-07-28 00:00:00'),
  ('rev_00A4DBEB79A9A724', 'prd_01HZX050F7543', 'usr_demo_004', 5, 'Light and breathable.', 'Breathable fabric. Good for travel.', TRUE, '2026-01-02 00:00:00'),
  ('rev_54DBEEEC37DE5FDF', 'prd_01HZX050F7543', 'usr_demo_002', 3, 'Wrinkles fast.', 'Wrinkles more than expected during the day.', FALSE, '2025-09-27 00:00:00'),
  ('rev_2353C575A610088B', 'prd_01HZX051B5C03', 'usr_demo_005', 5, 'Drape like trousers.', 'Drape better than typical chinos. Look dressed-up at a meeting.', TRUE, '2025-09-22 00:00:00'),
  ('rev_41BF5C51BFFFF7AD', 'prd_01HZX051B5C03', 'usr_demo_002', 5, 'Smart-casual win.', 'Works for office and dinner both.', TRUE, '2026-02-27 00:00:00'),
  ('rev_37461AFB68868365', 'prd_01HZX051B5C03', 'usr_demo_001', 4, 'Good but a touch warm.', 'Heavier than expected. Better for cooler days.', TRUE, '2025-10-03 00:00:00'),
  ('rev_17AE7EFC944FA64A', 'prd_01HZX051B5C03', 'usr_demo_003', 5, 'Pockets are shallow.', 'Front pockets are shallow.', TRUE, '2026-01-08 00:00:00'),
  ('rev_333E98F794437F8F', 'prd_01HZX052DC64F', 'usr_demo_002', 3, 'Wrinkles fast.', 'Wrinkles more than expected during the day.', TRUE, '2026-05-11 00:00:00'),
  ('rev_C5C6D9E0C8998DEF', 'prd_01HZX052DC64F', 'usr_demo_003', 5, 'Looks expensive.', 'Looks more expensive than the price tag.', TRUE, '2026-02-25 00:00:00'),
  ('rev_97EDF3AD0C446C6C', 'prd_01HZX052DC64F', 'usr_demo_001', 5, 'Light and breathable.', 'Breathable fabric. Good for travel.', FALSE, '2025-07-19 00:00:00'),
  ('rev_4D65C300E6A79278', 'prd_01HZX052DC64F', 'usr_demo_004', 5, 'Worth the investment.', 'Best workhorse trouser I own now.', TRUE, '2026-04-07 00:00:00'),
  ('rev_3168B3BA9CBD7271', 'prd_01HZX0534DE92', 'usr_demo_002', 5, 'Comfortable.', 'All-day comfort, very minimal break-in needed.', TRUE, '2026-03-31 00:00:00'),
  ('rev_CA7BB97EAB920AF6', 'prd_01HZX0534DE92', 'usr_demo_005', 4, 'Good but a touch warm.', 'Heavier than expected. Better for cooler days.', TRUE, '2025-08-01 00:00:00'),
  ('rev_BA1A1B9DC8F14B5B', 'prd_01HZX0534DE92', 'usr_demo_001', 5, 'Color is rich.', 'Color is richer in person than the photo.', TRUE, '2026-03-30 00:00:00'),
  ('rev_CFCEB2DB9DE2DD72', 'prd_01HZX0534DE92', 'usr_demo_003', 3, 'Pockets are shallow.', 'Front pockets are shallow.', FALSE, '2026-01-02 00:00:00'),
  ('rev_EDFAA1394C06C901', 'prd_01HZX054AA876', 'usr_demo_005', 5, 'Tailored feel off the rack.', 'Cleanest hem and break I''ve found off the rack.', TRUE, '2025-12-21 00:00:00'),
  ('rev_45F05DD994B6F00B', 'prd_01HZX054AA876', 'usr_demo_001', 5, 'Hem ran long.', 'Needed a small alteration; finished length is perfect now.', TRUE, '2026-04-23 00:00:00'),
  ('rev_2BB6BC3DED6AD3E5', 'prd_01HZX0552CB2B', 'usr_demo_002', 5, 'Smart-casual win.', 'Works for office and dinner both.', TRUE, '2025-08-04 00:00:00'),
  ('rev_84EA94428698DBC7', 'prd_01HZX0552CB2B', 'usr_demo_005', 5, 'Good but a touch warm.', 'Heavier than expected. Better for cooler days.', TRUE, '2025-08-05 00:00:00'),
  ('rev_D93C8D2D3F7ADB8D', 'prd_01HZX0552CB2B', 'usr_demo_001', 3, 'Pockets are shallow.', 'Front pockets are shallow.', TRUE, '2026-01-21 00:00:00'),
  ('rev_F88DD0EE37D08BE2', 'prd_01HZX0552CB2B', 'usr_demo_003', 5, 'Comfortable.', 'All-day comfort, very minimal break-in needed.', TRUE, '2026-01-02 00:00:00'),
  ('rev_56D5E3D1ABAD759A', 'prd_01HZX056AC195', 'usr_demo_003', 5, 'Hem ran long.', 'Needed a small alteration; finished length is perfect now.', TRUE, '2025-10-27 00:00:00'),
  ('rev_677C69E60A1F7FBF', 'prd_01HZX056AC195', 'usr_demo_004', 3, 'Wrinkles fast.', 'Wrinkles more than expected during the day.', TRUE, '2025-08-19 00:00:00'),
  ('rev_63CF0680CB6A5D98', 'prd_01HZX056AC195', 'usr_demo_005', 5, 'Worth the investment.', 'Best workhorse trouser I own now.', TRUE, '2026-02-09 00:00:00'),
  ('rev_5A684F724A22760D', 'prd_01HZX056AC195', 'usr_demo_001', 5, 'Tailored feel off the rack.', 'Cleanest hem and break I''ve found off the rack.', TRUE, '2025-12-22 00:00:00'),
  ('rev_5FB82189293D696B', 'prd_01HZX0573CF7C', 'usr_demo_003', 3, 'Pockets are shallow.', 'Front pockets are shallow.', TRUE, '2026-01-21 00:00:00'),
  ('rev_4C3CD07B0425F561', 'prd_01HZX0573CF7C', 'usr_demo_005', 4, 'Good but a touch warm.', 'Heavier than expected. Better for cooler days.', TRUE, '2025-10-04 00:00:00'),
  ('rev_A32C89D9D7A4D403', 'prd_01HZX0587C9B0', 'usr_demo_001', 4, 'Hem ran long.', 'Needed a small alteration; finished length is perfect now.', TRUE, '2025-05-30 00:00:00'),
  ('rev_788784CC544B16AD', 'prd_01HZX0587C9B0', 'usr_demo_003', 5, 'Worth the investment.', 'Best workhorse trouser I own now.', TRUE, '2025-06-09 00:00:00'),
  ('rev_A4790E8480EF0ACF', 'prd_01HZX0587C9B0', 'usr_demo_002', 5, 'Light and breathable.', 'Breathable fabric. Good for travel.', FALSE, '2025-09-11 00:00:00'),
  ('rev_A757C262008B0269', 'prd_01HZX0587C9B0', 'usr_demo_004', 5, 'Looks expensive.', 'Looks more expensive than the price tag.', TRUE, '2025-12-02 00:00:00'),
  ('rev_071B634F6833D6AC', 'prd_01HZX0597F0E3', 'usr_demo_001', 5, 'Packs flat, looks pressed.', 'Pulled it out of a carry-on and it looked pressed.', TRUE, '2026-05-01 00:00:00'),
  ('rev_246F7052229116CA', 'prd_01HZX0597F0E3', 'usr_demo_002', 3, 'Bit heavy for summer.', 'Warm in summer heat.', FALSE, '2025-08-02 00:00:00'),
  ('rev_E01B8995FAD45E5A', 'prd_01HZX0597F0E3', 'usr_demo_003', 5, 'Lining is comfortable.', 'Lining is silky and breathable.', TRUE, '2026-05-08 00:00:00'),
  ('rev_F195A3D7E589F689', 'prd_01HZX0597F0E3', 'usr_demo_005', 5, 'Multi-occasion.', 'Wore it to a meeting and to a dinner the same day.', TRUE, '2025-12-23 00:00:00'),
  ('rev_E8145DBD7A36C778', 'prd_01HZX060DAB51', 'usr_demo_001', 5, 'Slightly cropped.', 'Slightly cropped through the body; check sizing.', TRUE, '2025-09-18 00:00:00'),
  ('rev_CDB2C1BC2C5AD2A9', 'prd_01HZX060DAB51', 'usr_demo_002', 5, 'Perfect spring jacket.', 'Right weight for spring; sleeves slim without binding.', TRUE, '2026-01-12 00:00:00'),
  ('rev_2CD32479AFAF666A', 'prd_01HZX060DAB51', 'usr_demo_003', 3, 'Zipper sticky early on.', 'Zipper was sticky the first few uses.', TRUE, '2026-02-18 00:00:00'),
  ('rev_922C149FB58A94B7', 'prd_01HZX060DAB51', 'usr_demo_004', 4, 'Sleek silhouette.', 'Cleaner silhouette than typical bombers.', TRUE, '2025-07-19 00:00:00'),
  ('rev_DAE0DA646BEF4B95', 'prd_01HZX061959D1', 'usr_demo_001', 4, 'Heavier than expected.', 'Heavier weight than the photo suggests.', TRUE, '2026-04-01 00:00:00'),
  ('rev_FCBC4032E5C7B86D', 'prd_01HZX061959D1', 'usr_demo_002', 4, 'Goes with everything.', 'Wears with jeans and trousers equally.', TRUE, '2025-07-31 00:00:00'),
  ('rev_C259E3EE58F52E72', 'prd_01HZX061959D1', 'usr_demo_003', 5, 'Modern but not trendy.', 'Will look good in five years.', TRUE, '2025-11-13 00:00:00'),
  ('rev_807C06CA0E9BB507', 'prd_01HZX06218D2C', 'usr_demo_002', 4, 'Hood fits okay.', 'Hood fits okay; better with a hat.', TRUE, '2025-07-28 00:00:00'),
  ('rev_7E7DDA63EDAE9F51', 'prd_01HZX06218D2C', 'usr_demo_003', 5, 'Light and quiet.', 'Light and quiet fabric, no nylon swish.', TRUE, '2025-09-20 00:00:00'),
  ('rev_FCD2CE622AB2A32A', 'prd_01HZX06332272', 'usr_demo_003', 3, 'Bit heavy for summer.', 'Warm in summer heat.', FALSE, '2025-11-18 00:00:00'),
  ('rev_7D7699FDCAC0CB10', 'prd_01HZX06332272', 'usr_demo_005', 4, 'Lining is comfortable.', 'Lining is silky and breathable.', TRUE, '2025-05-28 00:00:00'),
  ('rev_42921182C1A3AB3A', 'prd_01HZX06332272', 'usr_demo_001', 5, 'Multi-occasion.', 'Wore it to a meeting and to a dinner the same day.', TRUE, '2025-12-20 00:00:00'),
  ('rev_E4028AF5698B7F06', 'prd_01HZX064F12C1', 'usr_demo_004', 4, 'Heavier than expected.', 'Heavier weight than the photo suggests.', TRUE, '2025-05-29 00:00:00');

INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified, created_at) VALUES
  ('rev_A3BD9D946835C522', 'prd_01HZX064F12C1', 'usr_demo_001', 5, 'Modern but not trendy.', 'Will look good in five years.', TRUE, '2026-01-21 00:00:00'),
  ('rev_9429ACC9163772CE', 'prd_01HZX0657230C', 'usr_demo_002', 5, 'Zipper sticky early on.', 'Zipper was sticky the first few uses.', TRUE, '2025-11-23 00:00:00'),
  ('rev_E2707086EA1DBFAA', 'prd_01HZX0657230C', 'usr_demo_001', 5, 'Comfortable lining.', 'Lining is silky and not noisy.', TRUE, '2025-09-07 00:00:00'),
  ('rev_11EBCAB81B862AAF', 'prd_01HZX0657230C', 'usr_demo_003', 5, 'Slightly cropped.', 'Slightly cropped through the body; check sizing.', TRUE, '2025-10-02 00:00:00'),
  ('rev_EFDC8F11BBDD8A04', 'prd_01HZX0657230C', 'usr_demo_004', 5, 'Perfect spring jacket.', 'Right weight for spring; sleeves slim without binding.', TRUE, '2025-06-12 00:00:00'),
  ('rev_4EB0677ABFC9A001', 'prd_01HZX06612615', 'usr_demo_004', 3, 'Cuffs loose.', 'Cuffs are loose around small wrists.', TRUE, '2025-08-14 00:00:00'),
  ('rev_34710AFFDE7720E9', 'prd_01HZX06612615', 'usr_demo_005', 4, 'Light and quiet.', 'Light and quiet fabric, no nylon swish.', TRUE, '2025-09-28 00:00:00'),
  ('rev_692C93EA050A0306', 'prd_01HZX06612615', 'usr_demo_002', 5, 'Hood fits okay.', 'Hood fits okay; better with a hat.', TRUE, '2026-01-22 00:00:00'),
  ('rev_37333DC0B098AA03', 'prd_01HZX06612615', 'usr_demo_001', 5, 'Cleans up well.', 'Wipes clean after a light rain.', FALSE, '2025-12-14 00:00:00'),
  ('rev_92E18D31FC34D710', 'prd_01HZX067FC6AF', 'usr_demo_001', 5, 'Packs flat, looks pressed.', 'Pulled it out of a carry-on and it looked pressed.', TRUE, '2026-04-20 00:00:00'),
  ('rev_D038E7070A196364', 'prd_01HZX067FC6AF', 'usr_demo_004', 3, 'Bit heavy for summer.', 'Warm in summer heat.', TRUE, '2025-10-22 00:00:00'),
  ('rev_EAA2E0CE2F14204A', 'prd_01HZX0682F18D', 'usr_demo_003', 5, 'Cuffs loose.', 'Cuffs are loose around small wrists.', TRUE, '2025-07-11 00:00:00'),
  ('rev_1C0EA5D2F588DAF3', 'prd_01HZX0682F18D', 'usr_demo_002', 5, 'Lives in my carry-on.', 'Folds into its own pocket; warm enough for spring.', FALSE, '2026-04-26 00:00:00'),
  ('rev_7C15C67900FCE540', 'prd_01HZX0682F18D', 'usr_demo_001', 5, 'Hood fits okay.', 'Hood fits okay; better with a hat.', TRUE, '2026-01-10 00:00:00'),
  ('rev_0CD20DA16B25C8D6', 'prd_01HZX069DD580', 'usr_demo_002', 5, 'Effortless silhouette.', 'Drapes naturally; no boxy structure.', TRUE, '2025-10-20 00:00:00'),
  ('rev_28EBA73FAB865463', 'prd_01HZX069DD580', 'usr_demo_003', 5, 'Worth alterations.', 'Worth a small alteration to nail the fit.', TRUE, '2026-02-02 00:00:00'),
  ('rev_84839B6130F6533D', 'prd_01HZX070429F3', 'usr_demo_001', 5, 'Zipper sticky early on.', 'Zipper was sticky the first few uses.', TRUE, '2025-11-17 00:00:00'),
  ('rev_20A14B195D953FE1', 'prd_01HZX070429F3', 'usr_demo_004', 4, 'Slightly cropped.', 'Slightly cropped through the body; check sizing.', FALSE, '2025-12-03 00:00:00'),
  ('rev_000E3E4F9686A68D', 'prd_01HZX070429F3', 'usr_demo_003', 5, 'Sleek silhouette.', 'Cleaner silhouette than typical bombers.', TRUE, '2026-01-09 00:00:00'),
  ('rev_E6AC454A5DB3C79F', 'prd_01HZX070429F3', 'usr_demo_002', 5, 'Comfortable lining.', 'Lining is silky and not noisy.', TRUE, '2025-08-18 00:00:00'),
  ('rev_A7E5DB8E45DA0E92', 'prd_01HZX07187B9E', 'usr_demo_001', 4, 'Smart and forgiving.', 'Forgiving fit through the chest; sleeves needed a quick alter.', FALSE, '2025-11-29 00:00:00'),
  ('rev_3CA82BBDC8786350', 'prd_01HZX07187B9E', 'usr_demo_002', 5, 'Packs flat, looks pressed.', 'Pulled it out of a carry-on and it looked pressed.', TRUE, '2026-04-18 00:00:00'),
  ('rev_76D6C7C95C1D3DFB', 'prd_01HZX0722E7BB', 'usr_demo_005', 5, 'Great travel jacket.', 'Perfect three-season travel layer.', TRUE, '2026-01-27 00:00:00'),
  ('rev_55393296A85F26DA', 'prd_01HZX0722E7BB', 'usr_demo_001', 5, 'Light and quiet.', 'Light and quiet fabric, no nylon swish.', TRUE, '2025-12-24 00:00:00'),
  ('rev_050A4BDF8C2E7F9D', 'prd_01HZX0722E7BB', 'usr_demo_002', 4, 'Hood fits okay.', 'Hood fits okay; better with a hat.', TRUE, '2025-11-04 00:00:00'),
  ('rev_880CF8D0C789028B', 'prd_01HZX0739DCBA', 'usr_demo_002', 5, 'Sleeves long.', 'Sleeves were a touch long for my arm length.', FALSE, '2025-06-07 00:00:00'),
  ('rev_82FB1A80C4142329', 'prd_01HZX0739DCBA', 'usr_demo_001', 4, 'Goes with everything.', 'Wears with jeans and trousers equally.', TRUE, '2025-09-15 00:00:00'),
  ('rev_90F91303AF4C5EF2', 'prd_01HZX0739DCBA', 'usr_demo_005', 5, 'Modern but not trendy.', 'Will look good in five years.', FALSE, '2025-12-01 00:00:00'),
  ('rev_14B5DA4AC9B506AF', 'prd_01HZX074BF315', 'usr_demo_005', 4, 'Slightly cropped.', 'Slightly cropped through the body; check sizing.', TRUE, '2025-09-14 00:00:00'),
  ('rev_287814031D0C29BA', 'prd_01HZX074BF315', 'usr_demo_002', 5, 'Looks premium.', 'Premium finishing for the price.', TRUE, '2025-07-04 00:00:00'),
  ('rev_05243D8C60C78C05', 'prd_01HZX074BF315', 'usr_demo_001', 5, 'Sleek silhouette.', 'Cleaner silhouette than typical bombers.', TRUE, '2025-11-09 00:00:00'),
  ('rev_82D0F4EC283939C3', 'prd_01HZX075CAF3A', 'usr_demo_004', 3, 'Plain styling.', 'Plain on its own, needs a scarf or jacket.', TRUE, '2025-12-12 00:00:00'),
  ('rev_B06F756DF4057874', 'prd_01HZX075CAF3A', 'usr_demo_001', 5, 'Flattering and easy.', 'Drapes well, never clings, no shaping required.', TRUE, '2026-05-15 00:00:00'),
  ('rev_4C1DD8C11EE29FEB', 'prd_01HZX075CAF3A', 'usr_demo_002', 5, 'Easy travel piece.', 'Rolled it in my bag and it came out wrinkle-free.', TRUE, '2025-06-03 00:00:00'),
  ('rev_D237E66F27DEB712', 'prd_01HZX076F5A53', 'usr_demo_001', 5, 'Zipper visible.', 'Zipper visible from the back; expected a hidden zip.', FALSE, '2026-04-17 00:00:00'),
  ('rev_83088150B0A6E29A', 'prd_01HZX076F5A53', 'usr_demo_004', 5, 'Office-perfect.', 'Clean lines through the bodice. Worn to two meetings.', TRUE, '2025-06-03 00:00:00'),
  ('rev_C974C33F9FA0615F', 'prd_01HZX0777A454', 'usr_demo_004', 5, 'Travels well.', 'Folds small for travel.', TRUE, '2025-11-23 00:00:00'),
  ('rev_D6FA3B0A68A7ED3B', 'prd_01HZX0777A454', 'usr_demo_003', 5, 'Soft fabric.', 'Buttery jersey.', TRUE, '2025-12-31 00:00:00'),
  ('rev_4707400A0FCC6D92', 'prd_01HZX0777A454', 'usr_demo_001', 3, 'Length awkward.', 'Length is between knee and midi awkwardly.', TRUE, '2025-12-12 00:00:00'),
  ('rev_38244D914DA11764', 'prd_01HZX07842949', 'usr_demo_003', 5, 'Solid daywear.', 'Wears all day without fussing.', FALSE, '2026-04-17 00:00:00'),
  ('rev_F50A1B3D36739F1A', 'prd_01HZX07842949', 'usr_demo_005', 5, 'Easy throw-on.', 'Easy to throw on and look intentional.', FALSE, '2026-03-25 00:00:00'),
  ('rev_3D5DC1D8E76F8CD6', 'prd_01HZX07842949', 'usr_demo_001', 5, 'Needs a layer.', 'Best with a cardigan or jacket.', FALSE, '2025-07-15 00:00:00'),
  ('rev_C43F87D0799B2826', 'prd_01HZX079F7EA2', 'usr_demo_003', 5, 'Lightweight and airy.', 'Airy fabric, great for warm days.', TRUE, '2026-01-18 00:00:00'),
  ('rev_5F8558E114B517FB', 'prd_01HZX079F7EA2', 'usr_demo_002', 4, 'Ties at the waist.', 'Ties at the waist soften the silhouette.', TRUE, '2025-11-21 00:00:00'),
  ('rev_7881A4AFBA9FD017', 'prd_01HZX079F7EA2', 'usr_demo_001', 5, 'Romantic without trying.', 'Tiers move beautifully when walking.', FALSE, '2025-06-21 00:00:00'),
  ('rev_83E742277658F766', 'prd_01HZX079F7EA2', 'usr_demo_004', 5, 'Wrinkles easily.', 'Wrinkles fast; needs a steam.', TRUE, '2025-08-15 00:00:00'),
  ('rev_EB255EE4D28C6DAF', 'prd_01HZX080C8931', 'usr_demo_001', 5, 'Pockets!', 'Functional pockets are a quiet luxury.', TRUE, '2026-04-21 00:00:00'),
  ('rev_7348F965A46FB411', 'prd_01HZX080C8931', 'usr_demo_005', 5, 'Soft jersey.', 'Jersey is soft and recovers shape after wear.', TRUE, '2025-11-03 00:00:00'),
  ('rev_3EE4BB66C95972EF', 'prd_01HZX081764A2', 'usr_demo_002', 5, 'Tailored feel.', 'Tailored feel off the rack.', TRUE, '2025-06-25 00:00:00'),
  ('rev_BE982F30075DC5EE', 'prd_01HZX081764A2', 'usr_demo_001', 4, 'Lining could be better.', 'Lining is functional but not luxurious.', TRUE, '2026-02-18 00:00:00'),
  ('rev_08C5101C6DC09A8C', 'prd_01HZX081764A2', 'usr_demo_004', 4, 'Slim through hips.', 'Runs a hair slim through the hips.', TRUE, '2026-04-29 00:00:00'),
  ('rev_442FAD28965824C2', 'prd_01HZX082D4891', 'usr_demo_002', 5, 'Soft fabric.', 'Buttery jersey.', TRUE, '2025-12-17 00:00:00'),
  ('rev_4946D0B1FB0A424A', 'prd_01HZX082D4891', 'usr_demo_004', 3, 'Length awkward.', 'Length is between knee and midi awkwardly.', TRUE, '2026-04-08 00:00:00'),
  ('rev_9BD5947770D56E4C', 'prd_01HZX08301444', 'usr_demo_005', 3, 'Material thin.', 'Fabric is on the thinner side.', TRUE, '2025-08-20 00:00:00'),
  ('rev_A2D346FB6CBBA91D', 'prd_01HZX08301444', 'usr_demo_001', 5, 'Solid daywear.', 'Wears all day without fussing.', TRUE, '2026-01-18 00:00:00'),
  ('rev_8359F87D38FF923B', 'prd_01HZX0843DA3E', 'usr_demo_002', 5, 'Flattering and easy.', 'Drapes well, never clings, no shaping required.', TRUE, '2026-04-15 00:00:00'),
  ('rev_7EFD62910E246DF8', 'prd_01HZX0843DA3E', 'usr_demo_004', 3, 'Plain styling.', 'Plain on its own, needs a scarf or jacket.', TRUE, '2026-04-16 00:00:00'),
  ('rev_78459B6EDF07DA3D', 'prd_01HZX085CDF38', 'usr_demo_002', 4, 'Lining could be better.', 'Lining is functional but not luxurious.', TRUE, '2026-03-09 00:00:00'),
  ('rev_7FA1617145824C49', 'prd_01HZX085CDF38', 'usr_demo_001', 4, 'Slim through hips.', 'Runs a hair slim through the hips.', TRUE, '2025-08-20 00:00:00'),
  ('rev_2A4DF33E54A33EC3', 'prd_01HZX08657E3B', 'usr_demo_005', 5, 'Soft fabric.', 'Buttery jersey.', TRUE, '2026-02-12 00:00:00'),
  ('rev_FB06B4E86B440890', 'prd_01HZX08657E3B', 'usr_demo_001', 5, 'Travels well.', 'Folds small for travel.', TRUE, '2026-01-03 00:00:00'),
  ('rev_C98D9B58E75D2C27', 'prd_01HZX08657E3B', 'usr_demo_004', 5, 'Pattern subtle.', 'Color is subtle in person.', TRUE, '2025-07-12 00:00:00'),
  ('rev_2FEBE424C4ABB4BA', 'prd_01HZX0874E45A', 'usr_demo_004', 4, 'Ties at the waist.', 'Ties at the waist soften the silhouette.', TRUE, '2025-11-24 00:00:00'),
  ('rev_B20A6738CEEC32EC', 'prd_01HZX0874E45A', 'usr_demo_001', 3, 'Wrinkles easily.', 'Wrinkles fast; needs a steam.', TRUE, '2025-08-23 00:00:00'),
  ('rev_FD58950B1B9C9B47', 'prd_01HZX0880B378', 'usr_demo_003', 4, 'Soft jersey.', 'Jersey is soft and recovers shape after wear.', FALSE, '2026-01-20 00:00:00'),
  ('rev_A68D06EA8A4B9353', 'prd_01HZX0880B378', 'usr_demo_005', 4, 'Hem just right.', 'Hem sits at a flattering length.', TRUE, '2026-04-25 00:00:00'),
  ('rev_BBCC27C5BF9F03AC', 'prd_01HZX0880B378', 'usr_demo_004', 5, 'Pockets!', 'Functional pockets are a quiet luxury.', FALSE, '2026-02-25 00:00:00'),
  ('rev_1270FDE4EED22D07', 'prd_01HZX0880B378', 'usr_demo_001', 5, 'Flattering and easy.', 'Drapes well, never clings, no shaping required.', FALSE, '2025-10-27 00:00:00'),
  ('rev_C99E2190F995907F', 'prd_01HZX0890DDC6', 'usr_demo_004', 3, 'Zipper visible.', 'Zipper visible from the back; expected a hidden zip.', TRUE, '2025-09-10 00:00:00'),
  ('rev_0961C90D90A74A18', 'prd_01HZX0890DDC6', 'usr_demo_001', 5, 'Office-perfect.', 'Clean lines through the bodice. Worn to two meetings.', TRUE, '2026-01-23 00:00:00'),
  ('rev_3E10B542F9DB5CFC', 'prd_01HZX090404A1', 'usr_demo_003', 5, 'Solid daywear.', 'Wears all day without fussing.', TRUE, '2025-12-02 00:00:00'),
  ('rev_4D0DE88CF0B1E07E', 'prd_01HZX090404A1', 'usr_demo_005', 4, 'Boxy as expected.', 'Boxy cut is correctly described.', TRUE, '2026-01-06 00:00:00'),
  ('rev_3109582F0711FD50', 'prd_01HZX091FD149', 'usr_demo_002', 5, 'Length awkward.', 'Length is between knee and midi awkwardly.', TRUE, '2026-03-21 00:00:00'),
  ('rev_679E6C196057639D', 'prd_01HZX091FD149', 'usr_demo_005', 4, 'Pattern subtle.', 'Color is subtle in person.', TRUE, '2026-02-06 00:00:00'),
  ('rev_C06116A33DE83DCC', 'prd_01HZX091FD149', 'usr_demo_001', 5, 'Forgiving and feminine.', 'Wraps easily and stays put.', TRUE, '2025-10-15 00:00:00'),
  ('rev_7484F5C5EF8EE479', 'prd_01HZX091FD149', 'usr_demo_003', 5, 'Travels well.', 'Folds small for travel.', FALSE, '2026-05-12 00:00:00'),
  ('rev_6397D7DD1C251DBB', 'prd_01HZX0924A019', 'usr_demo_005', 5, 'Compliments often.', 'Stopped twice for compliments at brunch.', TRUE, '2026-04-13 00:00:00'),
  ('rev_B5216C122F9D5E04', 'prd_01HZX0924A019', 'usr_demo_002', 5, 'Lightweight and airy.', 'Airy fabric, great for warm days.', FALSE, '2025-07-01 00:00:00'),
  ('rev_4E2AAA6B9E08959A', 'prd_01HZX0924A019', 'usr_demo_003', 5, 'Romantic without trying.', 'Tiers move beautifully when walking.', TRUE, '2025-11-14 00:00:00'),
  ('rev_83D4560472CA6652', 'prd_01HZX0924A019', 'usr_demo_001', 5, 'Wrinkles easily.', 'Wrinkles fast; needs a steam.', FALSE, '2025-11-12 00:00:00'),
  ('rev_C363252924AEB6DD', 'prd_01HZX09307566', 'usr_demo_001', 5, 'Layers well.', 'Layers cleanly under coats.', TRUE, '2026-03-05 00:00:00'),
  ('rev_28D279BC1392D020', 'prd_01HZX09307566', 'usr_demo_003', 5, 'Holds shape.', 'Holds shape after several washes.', TRUE, '2026-01-09 00:00:00'),
  ('rev_0411F70D692ED23B', 'prd_01HZX09307566', 'usr_demo_005', 3, 'Pills early.', 'Some pilling near the underarms after week three.', TRUE, '2025-10-14 00:00:00'),
  ('rev_5D5671B1C4013814', 'prd_01HZX09475580', 'usr_demo_003', 5, 'Year-round.', 'Year-round wearable.', TRUE, '2025-11-07 00:00:00'),
  ('rev_CCA366F8057A5DE1', 'prd_01HZX09475580', 'usr_demo_004', 5, 'Perfect office layer.', 'Right weight for a chilly office.', FALSE, '2025-09-23 00:00:00'),
  ('rev_30EBCE9E81364187', 'prd_01HZX0952D0E4', 'usr_demo_002', 5, 'Slightly oversized.', 'Runs slightly oversized.', TRUE, '2026-04-03 00:00:00'),
  ('rev_8732CC8B8D72477F', 'prd_01HZX0952D0E4', 'usr_demo_003', 3, 'Sheds at first.', 'Some shedding on first few wears.', FALSE, '2025-07-03 00:00:00'),
  ('rev_77BA8493E16B2F30', 'prd_01HZX0952D0E4', 'usr_demo_005', 5, 'Texture is rich.', 'Knit texture is rich; not flat.', TRUE, '2025-11-16 00:00:00'),
  ('rev_BBB804AFBF9B10DC', 'prd_01HZX096BA323', 'usr_demo_001', 4, 'Sleeves long.', 'Sleeves run slightly long.', TRUE, '2026-04-19 00:00:00'),
  ('rev_0609BA06599644B1', 'prd_01HZX096BA323', 'usr_demo_005', 5, 'Layers well.', 'Layers cleanly under coats.', TRUE, '2026-01-18 00:00:00'),
  ('rev_4E17D73BF3EC9FA1', 'prd_01HZX0975A9A5', 'usr_demo_003', 4, 'Collar stands up.', 'Collar holds shape without flopping.', TRUE, '2026-02-27 00:00:00'),
  ('rev_3F801069A9EE9C95', 'prd_01HZX0975A9A5', 'usr_demo_002', 3, 'Bottom hem rolls.', 'Bottom hem rolls when sitting.', TRUE, '2025-08-27 00:00:00'),
  ('rev_6CFD1003C3840C68', 'prd_01HZX098C50A4', 'usr_demo_005', 4, 'Slightly oversized.', 'Runs slightly oversized.', TRUE, '2025-09-05 00:00:00'),
  ('rev_920521EFF60235AE', 'prd_01HZX098C50A4', 'usr_demo_002', 5, 'Texture is rich.', 'Knit texture is rich; not flat.', TRUE, '2025-10-12 00:00:00'),
  ('rev_5CCE3BD456581EB2', 'prd_01HZX0992C9F9', 'usr_demo_001', 5, 'Lifetime sweater.', 'Will be in rotation for years.', TRUE, '2025-06-28 00:00:00'),
  ('rev_63053385CF2F895A', 'prd_01HZX0992C9F9', 'usr_demo_002', 5, 'Holds shape.', 'Holds shape after several washes.', TRUE, '2025-06-19 00:00:00'),
  ('rev_4CCE1724D5071BF2', 'prd_01HZX0992C9F9', 'usr_demo_004', 3, 'Pills early.', 'Some pilling near the underarms after week three.', TRUE, '2025-08-08 00:00:00'),
  ('rev_A733813397F2C9D5', 'prd_01HZX10097636', 'usr_demo_001', 5, 'Year-round.', 'Year-round wearable.', TRUE, '2025-07-19 00:00:00'),
  ('rev_07AA1EC8AE2F810B', 'prd_01HZX10097636', 'usr_demo_003', 5, 'Perfect office layer.', 'Right weight for a chilly office.', TRUE, '2025-08-28 00:00:00'),
  ('rev_7863431BB2CB1011', 'prd_01HZX10131F77', 'usr_demo_004', 5, 'Soft hand.', 'Buttery soft hand-feel.', TRUE, '2025-09-25 00:00:00'),
  ('rev_B74C72136B4B4D35', 'prd_01HZX10131F77', 'usr_demo_001', 5, 'Everyday warmth.', 'Throws over anything, looks intentional.', TRUE, '2025-07-14 00:00:00'),
  ('rev_54DF7E9044D06DEE', 'prd_01HZX10131F77', 'usr_demo_005', 5, 'Slightly oversized.', 'Runs slightly oversized.', TRUE, '2025-06-27 00:00:00'),
  ('rev_A8CEDB50D8FE9318', 'prd_01HZX102C7A4D', 'usr_demo_005', 5, 'Lifetime sweater.', 'Will be in rotation for years.', TRUE, '2025-12-25 00:00:00'),
  ('rev_0B2997DBE6226027', 'prd_01HZX102C7A4D', 'usr_demo_001', 4, 'Holds shape.', 'Holds shape after several washes.', TRUE, '2025-09-21 00:00:00'),
  ('rev_9BD401CB4E948C7E', 'prd_01HZX102C7A4D', 'usr_demo_002', 3, 'Pills early.', 'Some pilling near the underarms after week three.', TRUE, '2026-04-29 00:00:00'),
  ('rev_138B4ADD082EE0E4', 'prd_01HZX103049E0', 'usr_demo_001', 3, 'Bottom hem rolls.', 'Bottom hem rolls when sitting.', TRUE, '2026-02-13 00:00:00'),
  ('rev_886107379FEA0E36', 'prd_01HZX103049E0', 'usr_demo_003', 5, 'Perfect office layer.', 'Right weight for a chilly office.', TRUE, '2026-01-05 00:00:00'),
  ('rev_6C18BC16CB758BF8', 'prd_01HZX103049E0', 'usr_demo_004', 4, 'Zipper smooth.', 'Zipper glides without snagging the placket.', TRUE, '2025-08-23 00:00:00'),
  ('rev_65561F2485CF1843', 'prd_01HZX103049E0', 'usr_demo_005', 5, 'Year-round.', 'Year-round wearable.', FALSE, '2025-08-06 00:00:00'),
  ('rev_58F8A28556F6F38A', 'prd_01HZX10433FC9', 'usr_demo_003', 3, 'Sheds at first.', 'Some shedding on first few wears.', TRUE, '2025-07-16 00:00:00'),
  ('rev_2C3F7F032275FFDA', 'prd_01HZX10433FC9', 'usr_demo_005', 5, 'Soft hand.', 'Buttery soft hand-feel.', TRUE, '2025-08-10 00:00:00'),
  ('rev_D9DE1377FCD55893', 'prd_01HZX10433FC9', 'usr_demo_001', 5, 'Slightly oversized.', 'Runs slightly oversized.', FALSE, '2026-01-01 00:00:00'),
  ('rev_3E1EBA14ABF4BE82', 'prd_01HZX10433FC9', 'usr_demo_004', 5, 'Everyday warmth.', 'Throws over anything, looks intentional.', TRUE, '2025-07-23 00:00:00'),
  ('rev_EEECF6ED0A2C51D5', 'prd_01HZX1056D522', 'usr_demo_002', 5, 'Soft and warm.', 'Warm without being itchy. Breathes well.', TRUE, '2025-11-29 00:00:00'),
  ('rev_2B47FAF702587225', 'prd_01HZX1056D522', 'usr_demo_004', 3, 'Pills early.', 'Some pilling near the underarms after week three.', TRUE, '2026-02-23 00:00:00'),
  ('rev_EB8C5245BB764504', 'prd_01HZX1056D522', 'usr_demo_005', 5, 'Lifetime sweater.', 'Will be in rotation for years.', TRUE, '2026-05-20 00:00:00'),
  ('rev_980146A455F15AE1', 'prd_01HZX1056D522', 'usr_demo_001', 4, 'Sleeves long.', 'Sleeves run slightly long.', TRUE, '2025-08-24 00:00:00'),
  ('rev_F23D08ECE017CE6C', 'prd_01HZX10612544', 'usr_demo_002', 3, 'Bottom hem rolls.', 'Bottom hem rolls when sitting.', TRUE, '2025-11-24 00:00:00'),
  ('rev_F67A91E5F806094F', 'prd_01HZX10612544', 'usr_demo_003', 4, 'Zipper smooth.', 'Zipper glides without snagging the placket.', TRUE, '2025-08-05 00:00:00'),
  ('rev_D002FF68E16A3BF9', 'prd_01HZX10612544', 'usr_demo_004', 5, 'Year-round.', 'Year-round wearable.', TRUE, '2025-06-27 00:00:00'),
  ('rev_C3B22F74F3E1DBC1', 'prd_01HZX10787D6A', 'usr_demo_004', 5, 'Hood stays put.', 'Hood doesn''t slide off.', TRUE, '2026-02-25 00:00:00'),
  ('rev_E6E92C62D0DBA75D', 'prd_01HZX10787D6A', 'usr_demo_003', 5, 'Great travel rain layer.', 'Best travel rain shell I''ve owned.', TRUE, '2025-10-18 00:00:00'),
  ('rev_41675D6065D570C4', 'prd_01HZX10787D6A', 'usr_demo_002', 5, 'Loud fabric.', 'Fabric is a bit crinkly.', TRUE, '2026-04-07 00:00:00'),
  ('rev_F890C70B6750DA4E', 'prd_01HZX1084A3F6', 'usr_demo_004', 4, 'Zipper pulls small.', 'Zipper pulls are small; gloves struggle.', FALSE, '2026-03-19 00:00:00'),
  ('rev_D9DF5C760B44A3F4', 'prd_01HZX1084A3F6', 'usr_demo_001', 4, 'Breathable.', 'Doesn''t trap heat on a brisk walk.', FALSE, '2025-08-27 00:00:00'),
  ('rev_D09A3906048EDCEA', 'prd_01HZX1096EF12', 'usr_demo_001', 5, 'Throws over anything.', 'Pairs with workwear and weekend.', TRUE, '2026-02-11 00:00:00'),
  ('rev_1B0E0883CEE2F989', 'prd_01HZX1096EF12', 'usr_demo_004', 5, 'Will own for years.', 'Will be in rotation for a decade.', TRUE, '2025-07-10 00:00:00'),
  ('rev_A8014AA0AE2E4B59', 'prd_01HZX1107C1E2', 'usr_demo_005', 5, 'Loud fabric.', 'Fabric is a bit crinkly.', TRUE, '2026-03-10 00:00:00'),
  ('rev_71A9F274173CD9B1', 'prd_01HZX1107C1E2', 'usr_demo_003', 3, 'Cuffs gap.', 'Cuffs gap a little around small wrists.', TRUE, '2025-06-11 00:00:00'),
  ('rev_CF8344AC61BF3801', 'prd_01HZX1107C1E2', 'usr_demo_001', 5, 'Lives in my bag.', 'Folds tiny; saved me from two surprise showers.', TRUE, '2025-08-23 00:00:00'),
  ('rev_2823D3F62AC443AC', 'prd_01HZX111A1816', 'usr_demo_003', 4, 'Zipper pulls small.', 'Zipper pulls are small; gloves struggle.', FALSE, '2026-03-19 00:00:00'),
  ('rev_ADCCAEE36E3E9424', 'prd_01HZX111A1816', 'usr_demo_004', 5, 'Quiet fabric.', 'No swishing sound when walking.', TRUE, '2025-10-31 00:00:00'),
  ('rev_17304C3E57A38979', 'prd_01HZX111A1816', 'usr_demo_002', 3, 'Tight across shoulders.', 'Snug across the shoulders for layering.', TRUE, '2026-04-23 00:00:00'),
  ('rev_6E744AAC8E1DBCAD', 'prd_01HZX11235EA4', 'usr_demo_001', 5, 'Great travel rain layer.', 'Best travel rain shell I''ve owned.', TRUE, '2025-06-12 00:00:00'),
  ('rev_AB23428B5E32B8FC', 'prd_01HZX11235EA4', 'usr_demo_004', 3, 'Cuffs gap.', 'Cuffs gap a little around small wrists.', TRUE, '2026-04-05 00:00:00'),
  ('rev_8E4A898F9F0955D2', 'prd_01HZX11235EA4', 'usr_demo_005', 5, 'Lives in my bag.', 'Folds tiny; saved me from two surprise showers.', TRUE, '2026-03-22 00:00:00'),
  ('rev_6E5391E220E4AA0C', 'prd_01HZX11384678', 'usr_demo_003', 5, 'Lining unlined arms.', 'Sleeves not fully lined; cardigan layers stick.', TRUE, '2026-03-19 00:00:00'),
  ('rev_9A863AF7990E90E7', 'prd_01HZX11384678', 'usr_demo_001', 5, 'Belt tie nice.', 'Belt tie is generous and sits well.', TRUE, '2025-08-01 00:00:00'),
  ('rev_53A452CB68475679', 'prd_01HZX11384678', 'usr_demo_002', 5, 'Throws over anything.', 'Pairs with workwear and weekend.', TRUE, '2026-03-22 00:00:00'),
  ('rev_D5E35E15DA348043', 'prd_01HZX11384678', 'usr_demo_004', 5, 'Will own for years.', 'Will be in rotation for a decade.', TRUE, '2025-06-07 00:00:00'),
  ('rev_8B6BA20AB1DC9B38', 'prd_01HZX11402B03', 'usr_demo_001', 5, 'Lives in my bag.', 'Folds tiny; saved me from two surprise showers.', TRUE, '2026-04-30 00:00:00'),
  ('rev_059E871C84259DE9', 'prd_01HZX11402B03', 'usr_demo_004', 5, 'Cuffs gap.', 'Cuffs gap a little around small wrists.', TRUE, '2026-04-12 00:00:00'),
  ('rev_AFBC13F5DE67F817', 'prd_01HZX11402B03', 'usr_demo_005', 4, 'Loud fabric.', 'Fabric is a bit crinkly.', TRUE, '2025-06-16 00:00:00'),
  ('rev_506529A2B08408B8', 'prd_01HZX11402B03', 'usr_demo_002', 5, 'Hood stays put.', 'Hood doesn''t slide off.', FALSE, '2025-06-09 00:00:00'),
  ('rev_9D01EE8DCF748FA4', 'prd_01HZX115C0A4D', 'usr_demo_003', 5, 'Zipper pulls small.', 'Zipper pulls are small; gloves struggle.', FALSE, '2026-02-13 00:00:00'),
  ('rev_3511DFE2763F538E', 'prd_01HZX115C0A4D', 'usr_demo_001', 3, 'Tight across shoulders.', 'Snug across the shoulders for layering.', TRUE, '2025-07-03 00:00:00'),
  ('rev_5A69D93175425CB2', 'prd_01HZX115C0A4D', 'usr_demo_002', 5, 'Stays dry in real rain.', 'Held up in a real downpour, not just drizzle.', TRUE, '2026-04-15 00:00:00'),
  ('rev_16EC4A30731CF9AD', 'prd_01HZX116F83B6', 'usr_demo_001', 5, 'Will own for years.', 'Will be in rotation for a decade.', TRUE, '2025-07-15 00:00:00'),
  ('rev_EE66C32739066967', 'prd_01HZX116F83B6', 'usr_demo_002', 3, 'Heavy for the season.', 'Heavier than expected; better for cooler rain.', TRUE, '2025-12-06 00:00:00'),
  ('rev_068B270FFCB52BB8', 'prd_01HZX11761294', 'usr_demo_003', 5, 'Premium leather.', 'Leather softens beautifully.', FALSE, '2025-09-21 00:00:00'),
  ('rev_D8023B9901DBA6C0', 'prd_01HZX11761294', 'usr_demo_002', 5, 'Comfortable from day one.', 'No break-in. All-day comfort.', TRUE, '2025-08-24 00:00:00'),
  ('rev_AD905E3684FBEC41', 'prd_01HZX1187129E', 'usr_demo_003', 5, 'Best in closet.', 'Best minimalist sneakers I''ve owned.', FALSE, '2025-08-31 00:00:00'),
  ('rev_380FD34A0CD73E1D', 'prd_01HZX1187129E', 'usr_demo_001', 5, 'Clean, no logos.', 'No loud logos. Refined.', TRUE, '2026-04-23 00:00:00'),
  ('rev_CF2A287B76E2B2BE', 'prd_01HZX1187129E', 'usr_demo_005', 4, 'Heel slightly tall.', 'Heel is a hair taller than expected.', TRUE, '2026-03-14 00:00:00'),
  ('rev_C141D8969BC5E083', 'prd_01HZX1187129E', 'usr_demo_004', 5, 'Holds polish.', 'Polishes up cleanly.', TRUE, '2025-08-25 00:00:00'),
  ('rev_834B7B1CCB063465', 'prd_01HZX119D1277', 'usr_demo_003', 5, 'Daily driver.', 'Daily driver sneakers.', TRUE, '2025-05-28 00:00:00'),
  ('rev_DAE26B9255EBA444', 'prd_01HZX119D1277', 'usr_demo_001', 3, 'Laces too long.', 'Laces are too long; replaced.', TRUE, '2025-07-15 00:00:00'),
  ('rev_7BCEA113F6B58A9E', 'prd_01HZX119D1277', 'usr_demo_002', 5, 'Sole is grippy.', 'Grip is excellent on wet floors.', TRUE, '2025-07-06 00:00:00'),
  ('rev_333D030A82DCAA57', 'prd_01HZX119D1277', 'usr_demo_004', 5, 'Roomy fit.', 'Sized true; roomy toebox.', TRUE, '2025-07-23 00:00:00'),
  ('rev_36CCCC2AE950A3D4', 'prd_01HZX120F9C60', 'usr_demo_004', 5, 'Comfortable from day one.', 'No break-in. All-day comfort.', TRUE, '2025-06-03 00:00:00'),
  ('rev_9558D9C1A4F3F4D8', 'prd_01HZX120F9C60', 'usr_demo_003', 5, 'Premium leather.', 'Leather softens beautifully.', TRUE, '2025-07-12 00:00:00'),
  ('rev_0ED5E37204EAEF5C', 'prd_01HZX120F9C60', 'usr_demo_001', 5, 'Toebox narrow.', 'Toebox runs a touch narrow.', TRUE, '2026-04-04 00:00:00'),
  ('rev_FE24ACD4ED37A69C', 'prd_01HZX1215905A', 'usr_demo_003', 5, 'Right ankle support.', 'Ankle support without feeling boxy.', TRUE, '2025-08-01 00:00:00'),
  ('rev_BF8D11B3D0648962', 'prd_01HZX1215905A', 'usr_demo_001', 5, 'Surprisingly light.', 'Lighter than they look.', TRUE, '2025-06-30 00:00:00'),
  ('rev_3817E0910DB65652', 'prd_01HZX1215905A', 'usr_demo_005', 5, 'Hot in summer.', 'A touch warm in summer.', TRUE, '2025-11-11 00:00:00'),
  ('rev_098862AE23C09E37', 'prd_01HZX1215905A', 'usr_demo_004', 5, 'Solid construction.', 'Solid stitching throughout.', TRUE, '2026-01-04 00:00:00'),
  ('rev_3793325D4D890F92', 'prd_01HZX122D9B14', 'usr_demo_003', 5, 'Clean, no logos.', 'No loud logos. Refined.', TRUE, '2025-11-12 00:00:00'),
  ('rev_E626F4B20793CCCD', 'prd_01HZX122D9B14', 'usr_demo_001', 5, 'Pairs with suiting.', 'Works with smart-casual easily.', TRUE, '2026-04-13 00:00:00'),
  ('rev_EF956B44C497EEF8', 'prd_01HZX122D9B14', 'usr_demo_002', 5, 'Insole flat.', 'Insole is flat; needs an aftermarket insert.', TRUE, '2026-04-15 00:00:00'),
  ('rev_2E77941AE24155B8', 'prd_01HZX123E4094', 'usr_demo_004', 5, 'Quiet sole.', 'Sole doesn''t squeak on hard floors.', TRUE, '2026-05-05 00:00:00'),
  ('rev_9EB3F378F93FAD2C', 'prd_01HZX123E4094', 'usr_demo_005', 3, 'Toebox narrow.', 'Toebox runs a touch narrow.', TRUE, '2025-09-27 00:00:00'),
  ('rev_2A729153314478A2', 'prd_01HZX1247FAD9', 'usr_demo_002', 5, 'Sole is grippy.', 'Grip is excellent on wet floors.', TRUE, '2025-11-04 00:00:00'),
  ('rev_43B2AE51A38D3773', 'prd_01HZX1247FAD9', 'usr_demo_001', 5, 'Throwback vibes.', 'Hits the throwback look without trying too hard.', TRUE, '2025-07-06 00:00:00'),
  ('rev_ADFD8A5C6535A750', 'prd_01HZX1247FAD9', 'usr_demo_003', 5, 'Laces too long.', 'Laces are too long; replaced.', TRUE, '2025-06-01 00:00:00'),
  ('rev_5A8D97063FE0E34B', 'prd_01HZX1247FAD9', 'usr_demo_004', 4, 'Roomy fit.', 'Sized true; roomy toebox.', TRUE, '2025-06-15 00:00:00'),
  ('rev_7949A164490A9AD2', 'prd_01HZX125AC267', 'usr_demo_003', 3, 'Toebox narrow.', 'Toebox runs a touch narrow.', TRUE, '2025-06-05 00:00:00'),
  ('rev_9418CC5493D58527', 'prd_01HZX125AC267', 'usr_demo_004', 5, 'Comfortable from day one.', 'No break-in. All-day comfort.', FALSE, '2026-01-03 00:00:00'),
  ('rev_AC1904B934F395BF', 'prd_01HZX125AC267', 'usr_demo_001', 5, 'Premium leather.', 'Leather softens beautifully.', TRUE, '2026-01-29 00:00:00'),
  ('rev_A373B79D82A52E54', 'prd_01HZX125AC267', 'usr_demo_002', 4, 'Insole could be thicker.', 'Insole is thin; added an arch insert.', TRUE, '2025-06-03 00:00:00'),
  ('rev_BFE0E7A47A78F82E', 'prd_01HZX12691BDE', 'usr_demo_001', 5, 'Best in closet.', 'Best minimalist sneakers I''ve owned.', TRUE, '2026-02-25 00:00:00'),
  ('rev_3E01747DD37EBDBB', 'prd_01HZX12691BDE', 'usr_demo_005', 3, 'Insole flat.', 'Insole is flat; needs an aftermarket insert.', TRUE, '2025-08-08 00:00:00'),
  ('rev_AEF01E574A583E36', 'prd_01HZX12691BDE', 'usr_demo_002', 5, 'Pairs with suiting.', 'Works with smart-casual easily.', TRUE, '2026-04-19 00:00:00'),
  ('rev_182B092C2F8E4A74', 'prd_01HZX127232F6', 'usr_demo_003', 5, 'Toebox narrow.', 'Toebox runs a touch narrow.', TRUE, '2026-04-25 00:00:00'),
  ('rev_FABAA0E43A6C312F', 'prd_01HZX127232F6', 'usr_demo_005', 5, 'Versatile.', 'Wears with jeans and chinos equally.', TRUE, '2025-12-19 00:00:00'),
  ('rev_61FE3198F933D5E0', 'prd_01HZX127232F6', 'usr_demo_001', 5, 'Comfortable from day one.', 'No break-in. All-day comfort.', TRUE, '2025-06-04 00:00:00'),
  ('rev_4613E4BE66C76397', 'prd_01HZX12889982', 'usr_demo_005', 4, 'Tongue thick.', 'Tongue is a touch thick.', TRUE, '2026-01-28 00:00:00'),
  ('rev_AF3FF793AB3BCA60', 'prd_01HZX12889982', 'usr_demo_001', 5, 'Sole is grippy.', 'Grip is excellent on wet floors.', FALSE, '2026-01-29 00:00:00'),
  ('rev_636B17796AB09BED', 'prd_01HZX1291DA14', 'usr_demo_005', 4, 'Holds polish.', 'Polishes up cleanly.', TRUE, '2026-02-21 00:00:00'),
  ('rev_826A8F92BE92CFCE', 'prd_01HZX1291DA14', 'usr_demo_002', 5, 'Insole flat.', 'Insole is flat; needs an aftermarket insert.', TRUE, '2025-12-27 00:00:00'),
  ('rev_0185F5E8D86C6F1E', 'prd_01HZX1291DA14', 'usr_demo_001', 5, 'Heel slightly tall.', 'Heel is a hair taller than expected.', FALSE, '2025-10-15 00:00:00'),
  ('rev_9E09492B3B2C5AE0', 'prd_01HZX1291DA14', 'usr_demo_003', 5, 'Pairs with suiting.', 'Works with smart-casual easily.', TRUE, '2026-05-07 00:00:00'),
  ('rev_65064041DFA49BB8', 'prd_01HZX13080265', 'usr_demo_002', 4, 'Roomy fit.', 'Sized true; roomy toebox.', FALSE, '2025-06-07 00:00:00'),
  ('rev_6D86AA58E633FB7A', 'prd_01HZX13080265', 'usr_demo_003', 3, 'Laces too long.', 'Laces are too long; replaced.', TRUE, '2026-03-29 00:00:00'),
  ('rev_C79F5BEE80310883', 'prd_01HZX13080265', 'usr_demo_001', 5, 'Sole is grippy.', 'Grip is excellent on wet floors.', TRUE, '2025-06-30 00:00:00'),
  ('rev_6218C533638175B0', 'prd_01HZX13136F77', 'usr_demo_003', 5, 'Heel snug.', 'Heel locks in well.', TRUE, '2026-01-09 00:00:00'),
  ('rev_1A064D2A28E6F762', 'prd_01HZX13136F77', 'usr_demo_002', 5, 'Solid construction.', 'Solid stitching throughout.', TRUE, '2026-01-30 00:00:00'),
  ('rev_84B2D32E096F1568', 'prd_01HZX13136F77', 'usr_demo_004', 4, 'Surprisingly light.', 'Lighter than they look.', FALSE, '2025-09-11 00:00:00'),
  ('rev_22C664C0AEE4532B', 'prd_01HZX13136F77', 'usr_demo_001', 3, 'Hot in summer.', 'A touch warm in summer.', TRUE, '2025-08-31 00:00:00'),
  ('rev_53F7D8AD7295339C', 'prd_01HZX132713B9', 'usr_demo_002', 5, 'Goes with denim.', 'Pairs cleanly with denim.', FALSE, '2026-04-13 00:00:00'),
  ('rev_9B602D23B42DC8C0', 'prd_01HZX132713B9', 'usr_demo_001', 5, 'Solid construction.', 'Solid stitching throughout.', TRUE, '2025-06-13 00:00:00');

INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified, created_at) VALUES
  ('rev_2AE543DE02A14145', 'prd_01HZX133BF1C8', 'usr_demo_001', 5, 'Sized half up.', 'Recommend sizing half up.', TRUE, '2026-01-17 00:00:00'),
  ('rev_3FDF9BC75789BF54', 'prd_01HZX133BF1C8', 'usr_demo_005', 5, 'Office-ready.', 'Polished enough for boardroom.', TRUE, '2026-04-18 00:00:00'),
  ('rev_1A15B3648C634840', 'prd_01HZX133BF1C8', 'usr_demo_003', 4, 'Welted construction.', 'Welt is clean; will resole well.', TRUE, '2026-03-14 00:00:00'),
  ('rev_47381EDFE1ACB10F', 'prd_01HZX133BF1C8', 'usr_demo_002', 5, 'Breaks in over a week.', 'Quick break-in for leather.', TRUE, '2025-11-21 00:00:00'),
  ('rev_2AADC9C87D1591FA', 'prd_01HZX134D5B9A', 'usr_demo_002', 5, 'Pairs with chinos.', 'Pairs casually with chinos.', FALSE, '2025-07-20 00:00:00'),
  ('rev_3350490F1F32862B', 'prd_01HZX134D5B9A', 'usr_demo_004', 5, 'Beautiful leather.', 'Leather is supple.', TRUE, '2025-07-24 00:00:00'),
  ('rev_38D2AA3FD1D4B8B0', 'prd_01HZX135E48B5', 'usr_demo_004', 5, 'Beautiful patina.', 'Develops a beautiful patina.', TRUE, '2026-04-14 00:00:00'),
  ('rev_444ECA00F33834B5', 'prd_01HZX135E48B5', 'usr_demo_002', 4, 'Heel slippage early.', 'Some heel slippage initially.', TRUE, '2026-03-31 00:00:00'),
  ('rev_5378832188E742DF', 'prd_01HZX135E48B5', 'usr_demo_005', 5, 'Dressy and easy.', 'Slips on; looks dressy.', TRUE, '2025-07-01 00:00:00'),
  ('rev_35F59920472065D7', 'prd_01HZX136DAFED', 'usr_demo_002', 5, 'Distinctive.', 'Stands out without being loud.', TRUE, '2026-03-01 00:00:00'),
  ('rev_34DBBED035924D36', 'prd_01HZX136DAFED', 'usr_demo_004', 5, 'Conversation piece.', 'Get compliments often.', TRUE, '2026-03-22 00:00:00'),
  ('rev_EDF5DD153F587232', 'prd_01HZX136DAFED', 'usr_demo_001', 5, 'Strap holes wear.', 'Strap holes show wear early.', TRUE, '2026-03-20 00:00:00'),
  ('rev_BD028F739AD1B2F2', 'prd_01HZX136DAFED', 'usr_demo_003', 5, 'Buckles solid.', 'Buckles feel solid.', TRUE, '2025-10-27 00:00:00'),
  ('rev_A1DF19442C7E6495', 'prd_01HZX137A036C', 'usr_demo_005', 4, 'Welted construction.', 'Welt is clean; will resole well.', TRUE, '2025-06-22 00:00:00'),
  ('rev_87C0BB954CB75250', 'prd_01HZX137A036C', 'usr_demo_004', 5, 'Mirror polish.', 'Takes a mirror polish after one or two coats.', TRUE, '2025-11-28 00:00:00'),
  ('rev_52D72BAA1D1AA467', 'prd_01HZX137A036C', 'usr_demo_001', 5, 'Investment piece.', 'Worth investing in.', TRUE, '2026-02-05 00:00:00'),
  ('rev_09A9CA34C604EB9B', 'prd_01HZX137A036C', 'usr_demo_002', 5, 'Office-ready.', 'Polished enough for boardroom.', TRUE, '2026-05-15 00:00:00'),
  ('rev_331BA5E10FAD1823', 'prd_01HZX13862E11', 'usr_demo_003', 5, 'More forgiving than oxfords.', 'Roomier fit than oxfords.', FALSE, '2026-04-20 00:00:00'),
  ('rev_EF898D8A14F29AD7', 'prd_01HZX13862E11', 'usr_demo_002', 4, 'Stiff at first.', 'Stiff first week, then softens.', TRUE, '2025-10-07 00:00:00'),
  ('rev_D2A749FD5CFC5BA7', 'prd_01HZX13862E11', 'usr_demo_004', 5, 'Beautiful leather.', 'Leather is supple.', TRUE, '2026-01-15 00:00:00'),
  ('rev_6ABB72A8DAF46DC9', 'prd_01HZX13862E11', 'usr_demo_001', 5, 'Pairs with chinos.', 'Pairs casually with chinos.', TRUE, '2025-08-07 00:00:00'),
  ('rev_9AD0EC6E6D304B2A', 'prd_01HZX139E8725', 'usr_demo_003', 4, 'Heel slippage early.', 'Some heel slippage initially.', TRUE, '2025-10-29 00:00:00'),
  ('rev_416BCA58E4601F1B', 'prd_01HZX139E8725', 'usr_demo_004', 3, 'Slick sole.', 'Sole is slick on wet pavement.', TRUE, '2025-08-28 00:00:00'),
  ('rev_CB2FC22000408068', 'prd_01HZX140A9006', 'usr_demo_004', 4, 'Sized half down.', 'Recommend sizing half down.', FALSE, '2025-11-17 00:00:00'),
  ('rev_1EF1AB8C7ECEC104', 'prd_01HZX140A9006', 'usr_demo_002', 5, 'Dressy without laces.', 'Sharp without the formality of laces.', TRUE, '2025-07-23 00:00:00'),
  ('rev_D3FBE6A6DF613BD9', 'prd_01HZX140A9006', 'usr_demo_001', 3, 'Strap holes wear.', 'Strap holes show wear early.', TRUE, '2025-07-22 00:00:00'),
  ('rev_FF20F4203116C841', 'prd_01HZX14183BB7', 'usr_demo_002', 3, 'Sized half up.', 'Recommend sizing half up.', TRUE, '2025-08-29 00:00:00'),
  ('rev_4782935E9E906C0C', 'prd_01HZX14183BB7', 'usr_demo_001', 5, 'Breaks in over a week.', 'Quick break-in for leather.', FALSE, '2026-04-26 00:00:00'),
  ('rev_CB16DE7DEA4890E4', 'prd_01HZX14183BB7', 'usr_demo_004', 5, 'Mirror polish.', 'Takes a mirror polish after one or two coats.', TRUE, '2025-12-15 00:00:00'),
  ('rev_0297CD4B132E23ED', 'prd_01HZX14183BB7', 'usr_demo_003', 4, 'Welted construction.', 'Welt is clean; will resole well.', TRUE, '2025-10-18 00:00:00'),
  ('rev_17A018615471A2DD', 'prd_01HZX1422D279', 'usr_demo_001', 5, 'More forgiving than oxfords.', 'Roomier fit than oxfords.', TRUE, '2025-09-11 00:00:00'),
  ('rev_AA0499032FE69941', 'prd_01HZX1422D279', 'usr_demo_004', 5, 'Pairs with chinos.', 'Pairs casually with chinos.', TRUE, '2026-01-01 00:00:00'),
  ('rev_791972B1D32343EC', 'prd_01HZX1422D279', 'usr_demo_005', 3, 'Heel rubs.', 'Heel rubbed for a few days.', TRUE, '2025-07-20 00:00:00'),
  ('rev_758C7EA42139381B', 'prd_01HZX1422D279', 'usr_demo_002', 5, 'Stiff at first.', 'Stiff first week, then softens.', TRUE, '2025-08-14 00:00:00'),
  ('rev_1EA41692D6AC3555', 'prd_01HZX14302FF2', 'usr_demo_004', 4, 'Heel slippage early.', 'Some heel slippage initially.', TRUE, '2025-06-16 00:00:00'),
  ('rev_B63F199DDC51A1A6', 'prd_01HZX14302FF2', 'usr_demo_001', 3, 'Slick sole.', 'Sole is slick on wet pavement.', TRUE, '2025-08-23 00:00:00'),
  ('rev_0F6BB46C62DC7AD7', 'prd_01HZX1446DC9A', 'usr_demo_002', 5, 'Conversation piece.', 'Get compliments often.', TRUE, '2026-05-12 00:00:00'),
  ('rev_974CCCE71FEAA21B', 'prd_01HZX1446DC9A', 'usr_demo_001', 5, 'Dressy without laces.', 'Sharp without the formality of laces.', TRUE, '2025-12-11 00:00:00'),
  ('rev_0F3069885B9D07E1', 'prd_01HZX145F81B7', 'usr_demo_001', 5, 'Office-ready.', 'Polished enough for boardroom.', TRUE, '2025-08-27 00:00:00'),
  ('rev_0D008BA0744A501E', 'prd_01HZX145F81B7', 'usr_demo_003', 4, 'Welted construction.', 'Welt is clean; will resole well.', TRUE, '2025-10-16 00:00:00'),
  ('rev_1B2123373C24DD48', 'prd_01HZX145F81B7', 'usr_demo_002', 3, 'Sized half up.', 'Recommend sizing half up.', FALSE, '2026-02-01 00:00:00'),
  ('rev_92906E9B88F63A7E', 'prd_01HZX146DC626', 'usr_demo_002', 5, 'Pairs with chinos.', 'Pairs casually with chinos.', TRUE, '2026-04-20 00:00:00'),
  ('rev_1154284DDD20F4D9', 'prd_01HZX146DC626', 'usr_demo_003', 5, 'Beautiful leather.', 'Leather is supple.', TRUE, '2026-04-01 00:00:00'),
  ('rev_CFBCF74BC4D0A7C5', 'prd_01HZX146DC626', 'usr_demo_001', 4, 'Easy on, easy off.', 'Easy to slip on with the open lacing.', TRUE, '2025-06-24 00:00:00'),
  ('rev_FE9CA45C1AFF1364', 'prd_01HZX147B19E0', 'usr_demo_003', 5, 'Clean lines.', 'Clean lines; looks intentional at the office.', TRUE, '2025-07-07 00:00:00'),
  ('rev_E1677E2606F367AD', 'prd_01HZX147B19E0', 'usr_demo_004', 5, 'Daily commute.', 'Daily commute pick.', FALSE, '2025-10-03 00:00:00'),
  ('rev_3BE4C738E07DB532', 'prd_01HZX148501A3', 'usr_demo_004', 5, 'Best travel pack.', 'Best travel pack I''ve owned.', TRUE, '2025-12-01 00:00:00'),
  ('rev_5EF323A8FCC7A180', 'prd_01HZX148501A3', 'usr_demo_001', 4, 'Heavier empty.', 'Heavier than expected when empty.', TRUE, '2025-12-27 00:00:00'),
  ('rev_0461B7EE71430D59', 'prd_01HZX148501A3', 'usr_demo_005', 5, 'Zippers stiff.', 'Some zippers stiff initially.', FALSE, '2025-08-23 00:00:00'),
  ('rev_D2F586CEAFE8E582', 'prd_01HZX148501A3', 'usr_demo_002', 5, 'Trip-ready.', 'Held a week of clothes plus tech.', TRUE, '2025-06-21 00:00:00'),
  ('rev_0B9C565B3633D33A', 'prd_01HZX1494D48D', 'usr_demo_003', 5, 'Stylish enough.', 'Looks intentional, not sporty.', TRUE, '2026-04-15 00:00:00'),
  ('rev_89C4056D99D1E00F', 'prd_01HZX1494D48D', 'usr_demo_001', 3, 'No laptop sleeve.', 'No dedicated laptop sleeve.', TRUE, '2025-06-04 00:00:00'),
  ('rev_65C9792AD587CDA9', 'prd_01HZX1494D48D', 'usr_demo_005', 5, 'Just enough room.', 'Holds the essentials cleanly.', TRUE, '2026-03-09 00:00:00'),
  ('rev_4C9B5E1F5E7AD745', 'prd_01HZX1505B8A8', 'usr_demo_004', 5, 'Adjustable capacity.', 'Roll-top adjusts to load size.', TRUE, '2026-01-14 00:00:00'),
  ('rev_85FAEC17FFDA7B50', 'prd_01HZX1505B8A8', 'usr_demo_002', 5, 'Travel-perfect.', 'Travel-perfect.', TRUE, '2026-01-19 00:00:00'),
  ('rev_BF3F2B409956D67F', 'prd_01HZX1505B8A8', 'usr_demo_005', 4, 'Looks distinct.', 'Has a distinct look from typical packs.', TRUE, '2025-05-31 00:00:00'),
  ('rev_57D10E5FDF193372', 'prd_01HZX1505B8A8', 'usr_demo_001', 5, 'Water-resistant.', 'Water-resistant fabric is real.', TRUE, '2026-01-11 00:00:00'),
  ('rev_5B5EDE85810C4159', 'prd_01HZX151036EE', 'usr_demo_005', 5, 'Daily commute.', 'Daily commute pick.', TRUE, '2025-06-25 00:00:00'),
  ('rev_1F29D906D61B1FC7', 'prd_01HZX151036EE', 'usr_demo_004', 5, 'Holds 16in laptop.', 'Holds my 16in laptop with room to spare.', TRUE, '2025-09-09 00:00:00'),
  ('rev_055852CE8D5E00ED', 'prd_01HZX151036EE', 'usr_demo_003', 5, 'Bottom not rigid.', 'Bottom not rigid; contents bunch.', TRUE, '2025-08-21 00:00:00'),
  ('rev_F2A8E13B185F2A18', 'prd_01HZX152E9B46', 'usr_demo_003', 4, 'Pockets everywhere.', 'Pockets for everything.', TRUE, '2025-10-19 00:00:00'),
  ('rev_B4D0983C150B9C9B', 'prd_01HZX152E9B46', 'usr_demo_001', 3, 'Zippers stiff.', 'Some zippers stiff initially.', TRUE, '2025-12-20 00:00:00'),
  ('rev_4ED16BE0EDAD071D', 'prd_01HZX1537264B', 'usr_demo_002', 5, 'Everyday pick.', 'Everyday pick.', FALSE, '2026-04-01 00:00:00'),
  ('rev_004A55B5804CA836', 'prd_01HZX1537264B', 'usr_demo_003', 5, 'Stylish enough.', 'Looks intentional, not sporty.', TRUE, '2025-05-29 00:00:00'),
  ('rev_86893339B7372EC2', 'prd_01HZX154A2535', 'usr_demo_002', 5, 'Comfortable straps.', 'Padded straps hold comfortably.', TRUE, '2026-02-04 00:00:00'),
  ('rev_B08EBF1646EEBB98', 'prd_01HZX154A2535', 'usr_demo_005', 5, 'Daily commute.', 'Daily commute pick.', FALSE, '2026-01-14 00:00:00'),
  ('rev_4006F73B9BBF6D79', 'prd_01HZX15535D86', 'usr_demo_004', 5, 'Water-resistant.', 'Water-resistant fabric is real.', TRUE, '2026-03-25 00:00:00'),
  ('rev_40988B22A0074057', 'prd_01HZX15535D86', 'usr_demo_002', 5, 'Access slower.', 'Slower to access than zipped packs.', TRUE, '2026-03-19 00:00:00'),
  ('rev_FCD78CCDB2BC0CFA', 'prd_01HZX15535D86', 'usr_demo_005', 5, 'Travel-perfect.', 'Travel-perfect.', FALSE, '2025-11-27 00:00:00'),
  ('rev_3D415EC9AEFA8662', 'prd_01HZX156A0986', 'usr_demo_001', 5, 'Strap padding light.', 'Strap padding could be thicker.', TRUE, '2025-07-19 00:00:00'),
  ('rev_B60C6FABEA8C10C6', 'prd_01HZX156A0986', 'usr_demo_004', 3, 'No laptop sleeve.', 'No dedicated laptop sleeve.', FALSE, '2025-12-06 00:00:00'),
  ('rev_427F95AE4D83AD71', 'prd_01HZX156A0986', 'usr_demo_003', 5, 'Just enough room.', 'Holds the essentials cleanly.', TRUE, '2025-12-25 00:00:00'),
  ('rev_A49C59A4B25AE649', 'prd_01HZX15734629', 'usr_demo_004', 5, 'Heavier empty.', 'Heavier than expected when empty.', FALSE, '2025-11-15 00:00:00'),
  ('rev_9C2A3DC8208AA110', 'prd_01HZX15734629', 'usr_demo_001', 3, 'Zippers stiff.', 'Some zippers stiff initially.', TRUE, '2026-04-05 00:00:00'),
  ('rev_1522FE3DE209CCA6', 'prd_01HZX15734629', 'usr_demo_005', 4, 'Pockets everywhere.', 'Pockets for everything.', TRUE, '2025-09-12 00:00:00'),
  ('rev_8B308868B08955EA', 'prd_01HZX15734629', 'usr_demo_002', 5, 'Trip-ready.', 'Held a week of clothes plus tech.', FALSE, '2025-09-05 00:00:00'),
  ('rev_C656A1DEA36D7A81', 'prd_01HZX158EC477', 'usr_demo_005', 5, 'Water-resistant.', 'Water-resistant fabric is real.', FALSE, '2026-03-27 00:00:00'),
  ('rev_5116159DE31E3196', 'prd_01HZX158EC477', 'usr_demo_001', 5, 'Adjustable capacity.', 'Roll-top adjusts to load size.', TRUE, '2025-10-03 00:00:00'),
  ('rev_31F5BE8060C49478', 'prd_01HZX158EC477', 'usr_demo_004', 5, 'Travel-perfect.', 'Travel-perfect.', TRUE, '2025-09-05 00:00:00'),
  ('rev_E2DCCC4043DBC9D3', 'prd_01HZX158EC477', 'usr_demo_002', 3, 'No tablet pocket.', 'No tablet pocket.', TRUE, '2026-01-09 00:00:00'),
  ('rev_0CEEFA6AAC546A11', 'prd_01HZX15904744', 'usr_demo_002', 4, 'Slightly tight at temple.', 'Slightly tight at the temples first week.', TRUE, '2025-06-13 00:00:00'),
  ('rev_82B57DC61A1ABBED', 'prd_01HZX15904744', 'usr_demo_001', 5, 'Lenses crisp.', 'Lenses are crisp without distortion.', TRUE, '2025-08-09 00:00:00'),
  ('rev_5B26EBED9D3BF3C9', 'prd_01HZX15904744', 'usr_demo_003', 5, 'Refined silhouette.', 'Sit right on the face without slipping.', TRUE, '2026-01-29 00:00:00'),
  ('rev_115CB53C4AB06CDE', 'prd_01HZX160B757F', 'usr_demo_001', 5, 'Lenses are great.', 'Lenses are dark enough for direct sun.', TRUE, '2026-01-15 00:00:00'),
  ('rev_3599ED5607266EB3', 'prd_01HZX160B757F', 'usr_demo_003', 5, 'Classic shape.', 'Classic shape that won''t age out.', TRUE, '2025-11-05 00:00:00'),
  ('rev_FB08A7211F301816', 'prd_01HZX160B757F', 'usr_demo_002', 5, 'Lighter color preferred.', 'Wish a lighter color existed.', TRUE, '2025-11-01 00:00:00'),
  ('rev_892609240439FCC7', 'prd_01HZX161A7F7D', 'usr_demo_003', 4, 'Bridge narrow.', 'Bridge could be wider.', TRUE, '2026-02-19 00:00:00'),
  ('rev_E61F93FC2C748AA4', 'prd_01HZX161A7F7D', 'usr_demo_005', 5, 'Iconic.', 'Hard to beat the classic.', TRUE, '2025-09-15 00:00:00'),
  ('rev_7C377FB7ED55EE9A', 'prd_01HZX161A7F7D', 'usr_demo_001', 5, 'Lenses polarized well.', 'Polarization is effective.', TRUE, '2025-09-13 00:00:00'),
  ('rev_FAD0E0DC3F358D29', 'prd_01HZX161A7F7D', 'usr_demo_002', 5, 'Light frame.', 'Light frame, no nose marks.', TRUE, '2026-03-11 00:00:00'),
  ('rev_F2288939B45DD8EF', 'prd_01HZX162BE15C', 'usr_demo_002', 3, 'Hinges loose.', 'Hinges loosened in a month.', TRUE, '2026-03-07 00:00:00'),
  ('rev_3653B61E3EF3EFE3', 'prd_01HZX162BE15C', 'usr_demo_005', 5, 'Acetate quality.', 'Acetate is dense and quality.', TRUE, '2025-07-08 00:00:00'),
  ('rev_3A10C5A04691090C', 'prd_01HZX162BE15C', 'usr_demo_001', 5, 'Versatile fit.', 'Fits a range of faces.', TRUE, '2026-04-02 00:00:00'),
  ('rev_2E77DEA5A886E78E', 'prd_01HZX16343326', 'usr_demo_002', 5, 'Best of summer.', 'Best summer purchase.', TRUE, '2025-12-31 00:00:00'),
  ('rev_F3BB1D5393A90E39', 'prd_01HZX16343326', 'usr_demo_003', 5, 'Coverage and style.', 'Coverage and style both.', TRUE, '2025-12-31 00:00:00'),
  ('rev_C42AED3CA5A306B9', 'prd_01HZX16429B41', 'usr_demo_005', 4, 'Light as a feather.', 'Featherweight.', TRUE, '2025-09-11 00:00:00'),
  ('rev_59410B09AAACD224', 'prd_01HZX16429B41', 'usr_demo_002', 5, 'Polished look.', 'Polished, executive look.', TRUE, '2026-03-07 00:00:00'),
  ('rev_27E8B03D5CDD0265', 'prd_01HZX16529DDC', 'usr_demo_001', 4, 'Right weight.', 'Right weight; not heavy.', TRUE, '2025-10-18 00:00:00'),
  ('rev_12AE4FD8CE160782', 'prd_01HZX16529DDC', 'usr_demo_002', 5, 'Classic shape.', 'Classic shape that won''t age out.', TRUE, '2026-03-04 00:00:00'),
  ('rev_8145EC931009F591', 'prd_01HZX1662C0FF', 'usr_demo_003', 4, 'Slightly tight at temple.', 'Slightly tight at the temples first week.', TRUE, '2025-07-01 00:00:00'),
  ('rev_F98D6CFD839D61D2', 'prd_01HZX1662C0FF', 'usr_demo_004', 4, 'Lenses crisp.', 'Lenses are crisp without distortion.', TRUE, '2026-02-20 00:00:00'),
  ('rev_6AC049360C9A50C7', 'prd_01HZX1662C0FF', 'usr_demo_002', 5, 'Refined silhouette.', 'Sit right on the face without slipping.', TRUE, '2025-09-20 00:00:00'),
  ('rev_BEFC15671889097D', 'prd_01HZX16737A05', 'usr_demo_004', 4, 'Acetate quality.', 'Acetate is dense and quality.', TRUE, '2025-05-27 00:00:00'),
  ('rev_3F49601592D9DB11', 'prd_01HZX16737A05', 'usr_demo_002', 3, 'Hinges loose.', 'Hinges loosened in a month.', FALSE, '2025-08-01 00:00:00'),
  ('rev_13143964AFF26F2D', 'prd_01HZX16737A05', 'usr_demo_001', 5, 'Versatile fit.', 'Fits a range of faces.', FALSE, '2025-08-31 00:00:00'),
  ('rev_1FC3B0980E7949C8', 'prd_01HZX16874C2F', 'usr_demo_004', 5, 'Daily summer wear.', 'Daily summer pick.', TRUE, '2026-02-14 00:00:00'),
  ('rev_C7395C0102D6AD52', 'prd_01HZX16874C2F', 'usr_demo_002', 5, 'Iconic.', 'Hard to beat the classic.', TRUE, '2025-09-08 00:00:00'),
  ('rev_76AE754FB77DA07E', 'prd_01HZX16874C2F', 'usr_demo_005', 5, 'Light frame.', 'Light frame, no nose marks.', TRUE, '2026-05-01 00:00:00'),
  ('rev_B3CA6D7B6A75D7F4', 'prd_01HZX16874C2F', 'usr_demo_001', 3, 'Reflective coating off-center.', 'Reflective coating uneven.', TRUE, '2025-08-22 00:00:00'),
  ('rev_B72DA780DF12E333', 'prd_01HZX169EF961', 'usr_demo_003', 5, 'Lens fingerprints.', 'Fingerprints visible.', TRUE, '2025-08-13 00:00:00'),
  ('rev_270587B34618CCAD', 'prd_01HZX169EF961', 'usr_demo_005', 5, 'Glamour.', 'Glamorous without being loud.', FALSE, '2026-05-13 00:00:00'),
  ('rev_A335A4E9BA93ACEA', 'prd_01HZX169EF961', 'usr_demo_001', 5, 'Light wear.', 'Don''t notice them after a few minutes.', TRUE, '2025-09-12 00:00:00'),
  ('rev_D8B37D23C4EC6E49', 'prd_01HZX170BD98F', 'usr_demo_004', 5, 'Polished look.', 'Polished, executive look.', TRUE, '2025-09-21 00:00:00'),
  ('rev_7FFFA0FBCB767DFC', 'prd_01HZX170BD98F', 'usr_demo_001', 3, 'Care needed.', 'Need careful handling.', TRUE, '2025-08-21 00:00:00'),
  ('rev_F002A8C081486260', 'prd_01HZX171249AB', 'usr_demo_003', 3, 'Case is basic.', 'Case is functional but basic.', TRUE, '2025-06-16 00:00:00'),
  ('rev_7EC50035D2F13043', 'prd_01HZX171249AB', 'usr_demo_005', 4, 'Slightly tight at temple.', 'Slightly tight at the temples first week.', TRUE, '2026-01-14 00:00:00'),
  ('rev_A046B43747BB1B9B', 'prd_01HZX171249AB', 'usr_demo_001', 5, 'Lenses crisp.', 'Lenses are crisp without distortion.', TRUE, '2026-01-08 00:00:00'),
  ('rev_9AA312158A9E4B17', 'prd_01HZX172FFE1D', 'usr_demo_003', 5, 'Right weight.', 'Right weight; not heavy.', TRUE, '2026-04-15 00:00:00'),
  ('rev_F4AEF18161ABED0F', 'prd_01HZX172FFE1D', 'usr_demo_002', 5, 'Loose at first.', 'Loose at first; adjusted at an optician.', TRUE, '2025-11-25 00:00:00'),
  ('rev_AF726027B4BF80BD', 'prd_01HZX172FFE1D', 'usr_demo_001', 5, 'Statement piece.', 'Round shape stands out without being loud.', TRUE, '2026-01-03 00:00:00'),
  ('rev_A14828B9107C4286', 'prd_01HZX173F4F9D', 'usr_demo_002', 4, 'Cuff slightly loose.', 'Cuff could be tighter.', TRUE, '2025-08-02 00:00:00'),
  ('rev_7FB477FC53435A20', 'prd_01HZX173F4F9D', 'usr_demo_001', 5, 'Best winter piece.', 'Best winter buy.', TRUE, '2026-03-27 00:00:00'),
  ('rev_3886F052CE466B2A', 'prd_01HZX174678B4', 'usr_demo_003', 5, 'Sheds first wear.', 'Some shedding on the first wear.', TRUE, '2025-06-08 00:00:00'),
  ('rev_EA1DCFF0F5F91C9D', 'prd_01HZX174678B4', 'usr_demo_005', 5, 'Wide for thin necks.', 'Wide; takes up volume.', TRUE, '2026-01-02 00:00:00'),
  ('rev_0714D20D0BCFAFAA', 'prd_01HZX1758E7B8', 'usr_demo_004', 4, 'Wool soft.', 'Wool isn''t itchy.', TRUE, '2025-08-06 00:00:00'),
  ('rev_FE11E539CAEA6C31', 'prd_01HZX1758E7B8', 'usr_demo_003', 5, 'Holds shape.', 'Doesn''t stretch out.', TRUE, '2025-10-18 00:00:00'),
  ('rev_A472A9EF6904022B', 'prd_01HZX1758E7B8', 'usr_demo_005', 3, 'Static.', 'A bit of static after wearing.', TRUE, '2025-06-23 00:00:00'),
  ('rev_A674D2B0242B1067', 'prd_01HZX1758E7B8', 'usr_demo_001', 4, 'Cuff slightly loose.', 'Cuff could be tighter.', TRUE, '2025-08-27 00:00:00'),
  ('rev_9CA3537C192F1003', 'prd_01HZX176B4C3D', 'usr_demo_003', 4, 'Wide for thin necks.', 'Wide; takes up volume.', TRUE, '2025-10-11 00:00:00'),
  ('rev_FDDE1A891C5EDAD5', 'prd_01HZX176B4C3D', 'usr_demo_001', 5, 'Sheds first wear.', 'Some shedding on the first wear.', TRUE, '2025-10-10 00:00:00'),
  ('rev_911C7D91BFC7B655', 'prd_01HZX176B4C3D', 'usr_demo_004', 5, 'Buttery soft.', 'Buttery soft against the neck.', TRUE, '2025-11-09 00:00:00'),
  ('rev_B19FA9C4D177397B', 'prd_01HZX1773E1F6', 'usr_demo_004', 5, 'Wool soft.', 'Wool isn''t itchy.', TRUE, '2025-09-18 00:00:00'),
  ('rev_26A102011C5593C8', 'prd_01HZX1773E1F6', 'usr_demo_001', 4, 'Cuff slightly loose.', 'Cuff could be tighter.', FALSE, '2025-07-05 00:00:00'),
  ('rev_A29C355B01766A0E', 'prd_01HZX1788C252', 'usr_demo_003', 5, 'Long enough to loop.', 'Long enough for a double loop.', TRUE, '2025-07-13 00:00:00'),
  ('rev_3BDA4514C1B8F161', 'prd_01HZX1788C252', 'usr_demo_001', 3, 'Sheds first wear.', 'Some shedding on the first wear.', TRUE, '2025-07-12 00:00:00'),
  ('rev_E8711798E097B518', 'prd_01HZX1796A629', 'usr_demo_004', 5, 'Cuff slightly loose.', 'Cuff could be tighter.', TRUE, '2025-08-01 00:00:00'),
  ('rev_2B4E270E323BDD06', 'prd_01HZX1796A629', 'usr_demo_005', 5, 'Snug, not tight.', 'Fits snugly without pressing.', TRUE, '2025-11-05 00:00:00'),
  ('rev_B96F79FA80ABF245', 'prd_01HZX1796A629', 'usr_demo_002', 5, 'Holds shape.', 'Doesn''t stretch out.', TRUE, '2025-06-18 00:00:00'),
  ('rev_D269D56898551922', 'prd_01HZX18042163', 'usr_demo_004', 5, 'Forever piece.', 'Forever piece.', TRUE, '2025-06-24 00:00:00'),
  ('rev_1AE2EFFD6381255E', 'prd_01HZX18042163', 'usr_demo_001', 4, 'Wide for thin necks.', 'Wide; takes up volume.', TRUE, '2025-10-13 00:00:00'),
  ('rev_014160DC3CB74C15', 'prd_01HZX18042163', 'usr_demo_002', 3, 'Sheds first wear.', 'Some shedding on the first wear.', TRUE, '2025-10-23 00:00:00'),
  ('rev_754AC61C4FD6809C', 'prd_01HZX18042163', 'usr_demo_003', 4, 'Long enough to loop.', 'Long enough for a double loop.', TRUE, '2026-04-03 00:00:00'),
  ('rev_E24E5E2D7EE8E3E0', 'prd_01HZX181D0B37', 'usr_demo_003', 4, 'Compact.', 'Truly compact when folded.', TRUE, '2025-11-06 00:00:00'),
  ('rev_EAA7E9EFC9EBA19B', 'prd_01HZX181D0B37', 'usr_demo_005', 5, 'Auto open is responsive.', 'Auto open is fast and reliable.', TRUE, '2026-02-26 00:00:00'),
  ('rev_77890611CF1453A5', 'prd_01HZX1828E989', 'usr_demo_001', 5, 'Travel staple.', 'Travel staple.', TRUE, '2025-09-07 00:00:00'),
  ('rev_EBF494ADF0EEA810', 'prd_01HZX1828E989', 'usr_demo_004', 3, 'Bulky together.', 'Take up some space themselves.', TRUE, '2026-02-09 00:00:00'),
  ('rev_B5FF7871D001EF9D', 'prd_01HZX1828E989', 'usr_demo_003', 5, 'Visibility limited.', 'Solid panels; need to remember what''s inside.', TRUE, '2025-11-10 00:00:00'),
  ('rev_28ED25EBCEE1B9FB', 'prd_01HZX183622D3', 'usr_demo_002', 5, 'Fade after washes.', 'Color fades faster than expected.', TRUE, '2025-11-12 00:00:00'),
  ('rev_47D55452E1E7FA7A', 'prd_01HZX183622D3', 'usr_demo_004', 4, 'Cushion is right.', 'Right amount of cushion.', TRUE, '2026-04-19 00:00:00'),
  ('rev_C382D92D1944BFBA', 'prd_01HZX183622D3', 'usr_demo_003', 4, 'Slightly tall.', 'Sit a touch tall.', TRUE, '2026-03-05 00:00:00'),
  ('rev_0E42A78124BA5DAB', 'prd_01HZX184DA162', 'usr_demo_003', 4, 'Buttery leather.', 'Leather softens beautifully.', TRUE, '2025-09-05 00:00:00'),
  ('rev_89440702E5074277', 'prd_01HZX184DA162', 'usr_demo_004', 5, 'Stitching tight.', 'Stitching is tight; no loose ends.', TRUE, '2025-07-16 00:00:00'),
  ('rev_9A5F9D508BB4E087', 'prd_01HZX184DA162', 'usr_demo_001', 5, 'Holds just enough.', 'Just enough cards without bulk.', TRUE, '2026-02-15 00:00:00'),
  ('rev_8BAF9D36413195E9', 'prd_01HZX185DBA6D', 'usr_demo_005', 4, 'Compact and soft.', 'Folds small, surprisingly soft.', TRUE, '2025-11-29 00:00:00'),
  ('rev_61759605AD10B02D', 'prd_01HZX185DBA6D', 'usr_demo_004', 5, 'Dries fast.', 'Dries in minutes.', TRUE, '2025-12-03 00:00:00'),
  ('rev_DCD8F627DAF95D4B', 'prd_01HZX18690CD3', 'usr_demo_005', 5, 'Zipper smooth.', 'Zipper glides cleanly.', TRUE, '2025-10-06 00:00:00'),
  ('rev_86D90E985702F44E', 'prd_01HZX18690CD3', 'usr_demo_004', 4, 'Right size.', 'Sized right for travel.', TRUE, '2025-11-14 00:00:00'),
  ('rev_FB64F5D03972CCCC', 'prd_01HZX18690CD3', 'usr_demo_003', 5, 'Quiet life-changer.', 'Quiet life-changer.', TRUE, '2025-12-23 00:00:00'),
  ('rev_1158DCCFA18737B0', 'prd_01HZX18690CD3', 'usr_demo_001', 4, 'Loops small.', 'Loops are small for large adapters.', TRUE, '2025-08-20 00:00:00'),
  ('rev_72562C4BD7A9108F', 'prd_01HZX187CDE05', 'usr_demo_002', 4, 'Compact.', 'Truly compact when folded.', TRUE, '2026-02-18 00:00:00'),
  ('rev_DEA5B4B1234C36E8', 'prd_01HZX187CDE05', 'usr_demo_005', 4, 'Drying takes time.', 'Slow to dry.', TRUE, '2025-07-13 00:00:00'),
  ('rev_89E5960EE92D2F84', 'prd_01HZX187CDE05', 'usr_demo_004', 5, 'Backpack ready.', 'Always in my backpack.', TRUE, '2025-11-25 00:00:00'),
  ('rev_168A43A89832D85A', 'prd_01HZX18843E1A', 'usr_demo_004', 5, 'Zippers durable.', 'Zippers feel durable.', TRUE, '2025-08-19 00:00:00'),
  ('rev_DA5F81F0BE86C1A3', 'prd_01HZX18843E1A', 'usr_demo_002', 4, 'Three sizes great.', 'Three sizes cover everything.', TRUE, '2025-11-12 00:00:00'),
  ('rev_5133380AD1A40CB0', 'prd_01HZX18843E1A', 'usr_demo_001', 5, 'Travel staple.', 'Travel staple.', FALSE, '2026-01-15 00:00:00'),
  ('rev_F851D942C7A5E6B6', 'prd_01HZX1894C92B', 'usr_demo_005', 4, 'Cushion is right.', 'Right amount of cushion.', TRUE, '2025-06-05 00:00:00'),
  ('rev_517D5A1D4556323A', 'prd_01HZX1894C92B', 'usr_demo_003', 5, 'Wicks moisture.', 'Wicks moisture well.', TRUE, '2025-11-18 00:00:00'),
  ('rev_BA7793B203FB7673', 'prd_01HZX1894C92B', 'usr_demo_004', 5, 'Slightly tall.', 'Sit a touch tall.', FALSE, '2026-01-01 00:00:00'),
  ('rev_17E52E1ED2084297', 'prd_01HZX19085328', 'usr_demo_001', 4, 'Snug new.', 'Cards snug at first.', FALSE, '2025-06-04 00:00:00'),
  ('rev_7F2ECD26503D602F', 'prd_01HZX19085328', 'usr_demo_002', 5, 'Stitching tight.', 'Stitching is tight; no loose ends.', TRUE, '2025-09-16 00:00:00'),
  ('rev_33A8A8D223FB0B61', 'prd_01HZX19085328', 'usr_demo_003', 5, 'Holds just enough.', 'Just enough cards without bulk.', TRUE, '2026-03-04 00:00:00'),
  ('rev_F39AB386EAA99755', 'prd_01HZX19085328', 'usr_demo_004', 5, 'Buttery leather.', 'Leather softens beautifully.', TRUE, '2025-10-28 00:00:00'),
  ('rev_6C412950D94D44BA', 'prd_01HZX191E8813', 'usr_demo_001', 5, 'Dries fast.', 'Dries in minutes.', TRUE, '2026-05-10 00:00:00'),
  ('rev_A92C0B0D4B32BF64', 'prd_01HZX191E8813', 'usr_demo_002', 3, 'Edge frays.', 'Edges fray a bit after washes.', FALSE, '2025-10-23 00:00:00'),
  ('rev_76385275B21A06FD', 'prd_01HZX191E8813', 'usr_demo_003', 5, 'Travel essential.', 'Essential for travel.', TRUE, '2026-01-02 00:00:00'),
  ('rev_100E2AE29B53BD4B', 'prd_01HZX192C159C', 'usr_demo_004', 4, 'Right size.', 'Sized right for travel.', TRUE, '2025-06-01 00:00:00'),
  ('rev_F83492F037F217DF', 'prd_01HZX192C159C', 'usr_demo_005', 5, 'Zipper smooth.', 'Zipper glides cleanly.', TRUE, '2025-11-27 00:00:00'),
  ('rev_E72857D5880F5D34', 'prd_01HZX192C159C', 'usr_demo_002', 5, 'Wires under control.', 'No more tangled headphones.', TRUE, '2025-08-09 00:00:00'),
  ('rev_D9B7F84854621341', 'prd_01HZX193C9A38', 'usr_demo_004', 5, 'Auto open is responsive.', 'Auto open is fast and reliable.', TRUE, '2025-12-22 00:00:00'),
  ('rev_99DDA2339F2CCC46', 'prd_01HZX193C9A38', 'usr_demo_001', 3, 'Latch sticks.', 'Latch sticks sometimes.', TRUE, '2025-09-09 00:00:00'),
  ('rev_23FD61F6B307FD1F', 'prd_01HZX19465179', 'usr_demo_002', 4, 'Visibility limited.', 'Solid panels; need to remember what''s inside.', TRUE, '2025-12-18 00:00:00'),
  ('rev_4B235CA810EDE48D', 'prd_01HZX19465179', 'usr_demo_005', 5, 'Zippers durable.', 'Zippers feel durable.', TRUE, '2025-10-10 00:00:00'),
  ('rev_B82900028023DF09', 'prd_01HZX19465179', 'usr_demo_001', 5, 'Game changer.', 'Pack faster, find faster.', FALSE, '2025-07-31 00:00:00'),
  ('rev_040332165E964A09', 'prd_01HZX19465179', 'usr_demo_003', 5, 'Travel staple.', 'Travel staple.', TRUE, '2025-10-09 00:00:00'),
  ('rev_6E7A145CF042F008', 'prd_01HZX195A9CC5', 'usr_demo_001', 5, 'Wicks moisture.', 'Wicks moisture well.', TRUE, '2025-06-26 00:00:00'),
  ('rev_5E8438B95EC5A666', 'prd_01HZX195A9CC5', 'usr_demo_002', 5, 'Travel essential.', 'Travel essential.', FALSE, '2026-02-01 00:00:00'),
  ('rev_C741E5086BE60816', 'prd_01HZX195A9CC5', 'usr_demo_005', 5, 'Fade after washes.', 'Color fades faster than expected.', TRUE, '2026-04-13 00:00:00'),
  ('rev_775D6F1C35982D31', 'prd_01HZX1968B4BC', 'usr_demo_003', 5, 'EDC.', 'Everyday carry.', TRUE, '2025-10-25 00:00:00'),
  ('rev_758F5EC21D2AC3EF', 'prd_01HZX1968B4BC', 'usr_demo_001', 5, 'Stitching tight.', 'Stitching is tight; no loose ends.', TRUE, '2026-05-04 00:00:00'),
  ('rev_7D9D28C706BC78EC', 'prd_01HZX1968B4BC', 'usr_demo_002', 4, 'Buttery leather.', 'Leather softens beautifully.', TRUE, '2026-03-28 00:00:00'),
  ('rev_EB791B2A326240E3', 'prd_01HZX1968B4BC', 'usr_demo_004', 5, 'No coin pocket.', 'No coin pocket.', TRUE, '2025-09-27 00:00:00'),
  ('rev_BD17A012907D71BC', 'prd_01HZX1978AC07', 'usr_demo_003', 5, 'Holds water.', 'Absorbs more than expected.', TRUE, '2025-11-17 00:00:00'),
  ('rev_E1BE3F291D7BC22A', 'prd_01HZX1978AC07', 'usr_demo_001', 4, 'Smell new.', 'Slight smell out of the bag; faded after wash.', TRUE, '2025-06-04 00:00:00'),
  ('rev_B823622BA8266A14', 'prd_01HZX1978AC07', 'usr_demo_002', 5, 'Travel essential.', 'Essential for travel.', TRUE, '2026-01-21 00:00:00'),
  ('rev_E492676D4CE3C6CE', 'prd_01HZX1989AE7B', 'usr_demo_003', 5, 'Right size.', 'Sized right for travel.', TRUE, '2025-08-02 00:00:00'),
  ('rev_231D78985458E0BB', 'prd_01HZX1989AE7B', 'usr_demo_002', 4, 'Loops small.', 'Loops are small for large adapters.', FALSE, '2025-06-02 00:00:00'),
  ('rev_862783BC5A869EE1', 'prd_01HZX199AFA79', 'usr_demo_002', 5, 'Compact.', 'Truly compact when folded.', FALSE, '2025-11-02 00:00:00'),
  ('rev_BE7604662429BC2E', 'prd_01HZX199AFA79', 'usr_demo_005', 5, 'Auto open is responsive.', 'Auto open is fast and reliable.', TRUE, '2026-05-02 00:00:00'),
  ('rev_E50DA3836EA7C336', 'prd_01HZX200DFBE7', 'usr_demo_001', 5, 'Game changer.', 'Pack faster, find faster.', TRUE, '2026-04-18 00:00:00'),
  ('rev_4378831B84E4F977', 'prd_01HZX200DFBE7', 'usr_demo_004', 4, 'Visibility limited.', 'Solid panels; need to remember what''s inside.', TRUE, '2025-06-08 00:00:00');


-- ============================================================================
-- seed/11_strip_rogue_colors.sql
-- ============================================================================
-- Mirrors db/mysql/migrations/2026-05-29-strip-rogue-colors.sql but applied
-- here as a post-seed cleanup so the SQLite seed lands directly in the
-- "single distinct color per product" steady state (API contract §6.2).
--
-- Mechanism:
--  - For each product whose product_images have exactly one distinct color_ref,
--    delete any product_variants row whose color disagrees, plus its dependent
--    rows (cart_items, prices, inventory).
--  - order_items is NEVER touched (orders are immutable per §7); if a rogue
--    variant is referenced from order_items the FK would block deletion.

BEGIN;

CREATE TEMP TABLE _tmp_true_colors AS
SELECT pi.product_id,
       MIN(pi.color_ref) AS true_color,
       COUNT(DISTINCT pi.color_ref) AS color_count
  FROM product_images pi
 WHERE pi.color_ref IS NOT NULL
 GROUP BY pi.product_id;

CREATE TEMP TABLE _tmp_rogue_variants AS
SELECT pv.variant_id
  FROM product_variants pv
  JOIN _tmp_true_colors tc ON tc.product_id = pv.product_id
 WHERE tc.color_count = 1
   AND pv.color <> tc.true_color;

DELETE FROM cart_items
 WHERE variant_id IN (SELECT variant_id FROM _tmp_rogue_variants);

DELETE FROM prices
 WHERE variant_id IN (SELECT variant_id FROM _tmp_rogue_variants);

DELETE FROM inventory
 WHERE variant_id IN (SELECT variant_id FROM _tmp_rogue_variants);

DELETE FROM product_variants
 WHERE variant_id IN (SELECT variant_id FROM _tmp_rogue_variants);

DROP TABLE _tmp_rogue_variants;
DROP TABLE _tmp_true_colors;

COMMIT;

-- ============================================================================
-- POST-SEED: clean up orphaned inventory rows, re-enable FK enforcement
-- ============================================================================
DELETE FROM inventory  WHERE variant_id NOT IN (SELECT variant_id FROM product_variants);
DELETE FROM cart_items WHERE variant_id NOT IN (SELECT variant_id FROM product_variants);
DELETE FROM prices     WHERE variant_id NOT IN (SELECT variant_id FROM product_variants);

PRAGMA foreign_keys = ON;

-- ============================================================================
-- pending_actions  (s3+ feature; ported from api/agent/s3/config/schema/pending_actions.sql)
-- ============================================================================
CREATE TABLE IF NOT EXISTS pending_actions (
    pending_action_id TEXT PRIMARY KEY,
    cart_id           TEXT NOT NULL,
    kind              TEXT NOT NULL DEFAULT 'cart-add',
    items             TEXT NOT NULL,
    subtotal_cents    INTEGER NOT NULL DEFAULT 0,
    currency          TEXT NOT NULL DEFAULT 'USD',
    status            TEXT NOT NULL DEFAULT 'pending',
    created_at        TEXT DEFAULT CURRENT_TIMESTAMP,
    expires_at        TEXT NOT NULL,
    decided_at        TEXT NULL,

    CHECK (status IN ('pending', 'confirmed', 'declined', 'expired', 'partial')),
    CHECK (expires_at > created_at),
    CHECK (json_valid(items))
);

CREATE INDEX IF NOT EXISTS idx_pending_actions_cart_status
  ON pending_actions(cart_id, status);
