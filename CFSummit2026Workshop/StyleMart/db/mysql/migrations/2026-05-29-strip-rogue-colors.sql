-- =============================================================================
-- StyleMart migration: strip rogue 2nd-color variants
-- Date:   2026-05-29
-- Owner:  ndubey
-- Tracker: see commit 5f9193c (single-color product invariant + PDP siblings[])
-- =============================================================================
--
-- WHAT
-- ----
-- A historical seed bug bolted a synthetic 2nd color onto product_variants
-- for ~46 of 200 products (e.g. "Cream Crew Neck Tshirts" got both cream and
-- navy variants), with no matching navy rows in product_images. This broke:
--   1) pnayak's color-selection query (every product appeared single-color
--      in product_images, but multi-color in product_variants).
--   2) PLP color facet semantics (?colors=navy returned a Cream T-shirt
--      because the rogue variant claimed navy).
--
-- This migration enforces the single-color product invariant locked in
-- the API contract (§6.2):
--
--     For every product:
--       DISTINCT product_images.color_ref == DISTINCT product_variants.color == 1
--
-- HOW
-- ---
-- For each product, the TRUE color is whatever appears in product_images
-- (single value by construction). Any product_variants row whose color
-- != true color is "rogue" and is deleted, along with cascade rows in
-- inventory, prices, and cart_items.
--
-- order_items rows are NEVER deleted (orders are immutable snapshots
-- per §7). If any rogue variant is referenced from order_items, the
-- FK fk_order_items_variant will reject the DELETE, the transaction
-- rolls back, and you get a constraint violation. In that case, manual
-- review is required before re-running.
--
-- SAFETY
-- ------
-- * Wrapped in a single transaction. Either the whole migration commits
--   or nothing changes.
-- * Idempotent. Re-running on a corrected DB finds 0 rogues and is a no-op.
-- * Pure DML. No DDL, no schema changes.
-- * Pre-flight read-only block prints expected counts so you can sanity-
--   check before any writes.
-- * No stored procedures, no DELIMITER directives. Any MySQL client
--   (cli, Workbench, JDBC, phpMyAdmin) can run this file end-to-end.
--
-- HOW TO RUN
-- ----------
--   mysql -u <user> -p stylemart < 2026-05-29-strip-rogue-colors.sql
--
-- Then read the printed "Post-migration verification" block. Expected
-- final state:
--     products:                  200
--     product_variants:          799   (down from 1016)
--     inventory:                 799   (down from 1016)
--     rogue_variants_remaining:    0
--     pnayak's query rowcount:     0
--     variants-multi-color:        0
-- =============================================================================

USE stylemart;

-- -----------------------------------------------------------------------------
-- Step 1. Build the set of rogue variant_ids into a temp table.
--          A variant is rogue iff:
--            (a) its product has exactly 1 distinct color in product_images, and
--            (b) the variant's color != that single image color.
--          Products with 0 or >1 image colors are EXCLUDED from the rogue
--          set entirely — those are pre-existing data anomalies that this
--          migration deliberately refuses to touch.
-- -----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS _tmp_true_colors;
CREATE TEMPORARY TABLE _tmp_true_colors (
  product_id  VARCHAR(50) PRIMARY KEY,
  true_color  VARCHAR(50) NOT NULL,
  color_count INT         NOT NULL
) ENGINE=Memory;

INSERT INTO _tmp_true_colors (product_id, true_color, color_count)
SELECT
  pi.product_id,
  MIN(pi.color_ref)              AS true_color,
  COUNT(DISTINCT pi.color_ref)   AS color_count
FROM product_images pi
WHERE pi.color_ref IS NOT NULL
GROUP BY pi.product_id;

DROP TEMPORARY TABLE IF EXISTS _tmp_rogue_variants;
CREATE TEMPORARY TABLE _tmp_rogue_variants (
  variant_id VARCHAR(50) PRIMARY KEY
) ENGINE=Memory;

INSERT INTO _tmp_rogue_variants (variant_id)
SELECT pv.variant_id
FROM product_variants pv
JOIN _tmp_true_colors tc ON tc.product_id = pv.product_id
WHERE tc.color_count = 1
  AND pv.color <> tc.true_color;

-- -----------------------------------------------------------------------------
-- Step 2. Pre-flight report (read-only). Inspect this BEFORE step 3.
-- -----------------------------------------------------------------------------
SELECT '--- Pre-flight ---' AS section;

SELECT
  (SELECT COUNT(*) FROM products)            AS products,
  (SELECT COUNT(*) FROM product_variants)    AS variants_before,
  (SELECT COUNT(*) FROM inventory)           AS inventory_before,
  (SELECT COUNT(*) FROM _tmp_rogue_variants) AS rogue_variants_to_drop;

-- (a) Products that violate the invariant on the IMAGES side
--     (color_count != 1). Should be 0 rows. If non-empty, fix images
--     before running the migration — this script will not touch those
--     products' variants.
SELECT 'IMAGES anomalies (expected: 0 rows; rogue variants for these are NOT touched):' AS check_label;
SELECT product_id, true_color, color_count
FROM _tmp_true_colors
WHERE color_count <> 1;

-- (b) Rogue variants referenced by order_items. Must be 0 rows. If
--     non-empty, the migration WILL fail at the variants DELETE because
--     order_items.fk prevents it (orders are immutable). Resolve manually
--     before re-running.
SELECT 'ORDER-ITEMS anomalies (expected: 0 rows; will block migration if present):' AS check_label;
SELECT oi.order_id, oi.variant_id, oi.quantity
FROM order_items oi
JOIN _tmp_rogue_variants r ON r.variant_id = oi.variant_id;

-- (c) Cart-line + price-override impact (informational).
SELECT 'Side-effect counts:' AS check_label;
SELECT
  (SELECT COUNT(*) FROM cart_items ci JOIN _tmp_rogue_variants r ON r.variant_id = ci.variant_id) AS cart_lines_to_drop,
  (SELECT COUNT(*) FROM prices     p  JOIN _tmp_rogue_variants r ON r.variant_id = p.variant_id)  AS price_rows_to_drop,
  (SELECT COUNT(*) FROM inventory  i  JOIN _tmp_rogue_variants r ON r.variant_id = i.variant_id)  AS inventory_rows_to_drop;

-- -----------------------------------------------------------------------------
-- Step 3. The actual mutation. Single transaction. Either the whole thing
--          commits, or every change rolls back.
--
-- If you want to do a final eyeball before writes, comment out the COMMIT
-- and replace with ROLLBACK to dry-run.
-- -----------------------------------------------------------------------------
START TRANSACTION;

-- Cart lines pointing at rogue variants (any user mid-shop session).
DELETE ci FROM cart_items ci
JOIN _tmp_rogue_variants r ON r.variant_id = ci.variant_id;

-- Per-variant price overrides ([S] stretch only; no-op for kit [K]).
DELETE p FROM prices p
JOIN _tmp_rogue_variants r ON r.variant_id = p.variant_id;

-- Inventory rows.
DELETE i FROM inventory i
JOIN _tmp_rogue_variants r ON r.variant_id = i.variant_id;

-- The variants themselves. If any rogue variant is referenced from
-- order_items, this DELETE fails on fk_order_items_variant and the
-- whole transaction rolls back.
DELETE pv FROM product_variants pv
JOIN _tmp_rogue_variants r ON r.variant_id = pv.variant_id;

COMMIT;

-- -----------------------------------------------------------------------------
-- Step 4. Post-migration verification.
-- -----------------------------------------------------------------------------
SELECT '--- Post-migration verification ---' AS section;

SELECT
  (SELECT COUNT(*) FROM products)                                        AS products,
  (SELECT COUNT(*) FROM product_variants)                                AS variants_after,
  (SELECT COUNT(*) FROM inventory)                                       AS inventory_after,
  (SELECT COUNT(*)
     FROM product_variants pv
     JOIN _tmp_true_colors tc ON tc.product_id = pv.product_id
    WHERE tc.color_count = 1 AND pv.color <> tc.true_color)              AS rogue_variants_remaining;

-- pnayak's exact query — must return zero rows.
SELECT 'pnayak HAVING COUNT(DISTINCT color_ref) > 1 (expected: 0 rows):' AS check_label;
SELECT
  product_id,
  GROUP_CONCAT(DISTINCT color_ref) AS colors,
  COUNT(*)                          AS total_images
FROM product_images
WHERE color_ref IS NOT NULL
GROUP BY product_id
HAVING COUNT(DISTINCT color_ref) > 1;

-- Mirror check on variants — must return zero rows.
SELECT 'product_variants with > 1 distinct color per product (expected: 0 rows):' AS check_label;
SELECT
  product_id,
  GROUP_CONCAT(DISTINCT color) AS colors,
  COUNT(*)                     AS total_variants
FROM product_variants
GROUP BY product_id
HAVING COUNT(DISTINCT color) > 1;

-- Sample of one previously-rogue family so pnayak can eyeball the result.
SELECT 'Sample crew-neck T-shirt family after migration:' AS check_label;
SELECT p.product_id, p.name,
       (SELECT GROUP_CONCAT(DISTINCT pv.color)
          FROM product_variants pv WHERE pv.product_id = p.product_id) AS variant_colors,
       (SELECT GROUP_CONCAT(DISTINCT pi.color_ref)
          FROM product_images pi   WHERE pi.product_id = p.product_id) AS image_colors,
       (SELECT COUNT(*)
          FROM product_variants pv WHERE pv.product_id = p.product_id) AS n_variants
FROM products p
WHERE p.category = 'tshirts' AND p.subcategory = 'crew-neck'
ORDER BY p.name
LIMIT 5;

-- Cleanup.
DROP TEMPORARY TABLE IF EXISTS _tmp_rogue_variants;
DROP TEMPORARY TABLE IF EXISTS _tmp_true_colors;

-- =============================================================================
-- Done. Expected post-migration steady state:
--     products:                  200
--     product_variants:          799
--     inventory:                 799
--     rogue_variants_remaining:    0
--     pnayak's query rowcount:    0
--     variants-multi-color:        0
-- =============================================================================
