-- StyleMart MySQL seed data
-- 09 - Promotions (2 rows)
-- Target table: promotions
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql

USE stylemart;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM promotions;

INSERT INTO promotions (promotion_id, name, type, value, scope_json, priority, valid_from, valid_to, active) VALUES
  ('pro_summit_storewide', 'CF Summit Weekend', 'percent', 5.00, '{}', 1, '2026-05-25 00:00:00', '2026-06-01 00:00:00', TRUE),
  ('pro_jackets_seasonal', 'Jackets Refresh', 'percent', 15.00, '{"categories":["jackets","raincoats"]}', 2, '2026-05-17 00:00:00', '2026-07-11 00:00:00', TRUE);

SET FOREIGN_KEY_CHECKS = 1;
