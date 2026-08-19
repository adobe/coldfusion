-- StyleMart MySQL seed data
-- 02 - Loyalty tiers (3 rows)
-- Target table: loyalty_tiers
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql

USE stylemart;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM loyalty_tiers;

INSERT INTO loyalty_tiers (tier_id, display_name, discount_pct, spend_threshold_cents, benefits, sort_order) VALUES
  ('tier_bronze', 'Bronze', 0.00, 0, '["Free shipping over $75","Birthday gift"]', 0),
  ('tier_silver', 'Silver', 5.00, 50000, '["Free shipping","Early access to drops","Birthday gift"]', 1),
  ('tier_gold', 'Gold', 10.00, 150000, '["Free expedited shipping","Early access","Personal stylist chat","Birthday gift"]', 2);

SET FOREIGN_KEY_CHECKS = 1;
