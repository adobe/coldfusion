-- StyleMart MySQL seed data
-- 08 - Coupons (3 rows)
-- Target table: coupons
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql

USE stylemart;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM coupons;

INSERT INTO coupons (coupon_id, code, type, value, currency, scope_categories, excludes_categories, conditions_json, valid_from, valid_to, active) VALUES
  ('cou_summit10', 'SUMMIT10', 'percent', 10.00, 'USD', '[]', '[]', '{}', '2026-04-27 00:00:00', '2026-09-24 00:00:00', TRUE),
  ('cou_welcome15', 'WELCOME15', 'percent', 15.00, 'USD', '[]', '[]', '{"minSubtotal":75.0}', '2026-05-13 00:00:00', '2026-07-26 00:00:00', TRUE),
  ('cou_jackets20', 'JACKETS20', 'percent', 20.00, 'USD', '["jackets"]', '[]', '{}', '2026-05-20 00:00:00', '2026-06-26 00:00:00', TRUE);

SET FOREIGN_KEY_CHECKS = 1;
