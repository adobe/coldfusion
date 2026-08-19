-- StyleMart MySQL seed data
-- 03 - Users (5 demo users)
-- Target table: users
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql

USE stylemart;

-- All 5 demo users share the same workshop password: Workshop2026!
-- bcrypt cost-12 hash below; never check in the plain password to source control
-- in production. For the workshop kit, the hash is intentional and pre-computed
-- so attendees can log in as any demo user without setup.
--
-- To rotate: python3 -c "import bcrypt; print(bcrypt.hashpw(b'NEW_PASSWORD', bcrypt.gensalt(12)).decode())"

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM users;

INSERT INTO users (user_id, username, password_hash, display_name, email, loyalty_tier_id, created_at) VALUES
  ('usr_demo_001',      'jordan',      '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Jordan Lee',    'jordan@example.com',       'tier_silver', '2026-01-27 00:00:00'),
  ('usr_demo_002',      'sam',         '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Sam Patel',     'sam@example.com',          'tier_bronze', '2026-03-28 00:00:00'),
  ('usr_demo_003',      'riley',       '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Riley Chen',    'riley@example.com',        'tier_gold',   '2025-04-22 00:00:00'),
  ('usr_demo_004',      'alex',        '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Alex Nguyen',   'alex@example.com',         'tier_silver', '2025-11-28 00:00:00'),
  ('usr_demo_005',      'morgan',      '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Morgan Garcia', 'morgan@example.com',       'tier_bronze', '2026-04-27 00:00:00'),
  ('demo-shopper-001',  'demoshopper', '$2b$12$2bU8t7nnYtpVYK8yTCstmO0XHqjMWbkBgy4D.foos.etlPGj3DNXW', 'Demo Shopper',  'demoshopper@example.com',  'tier_silver', '2026-05-01 00:00:00');

SET FOREIGN_KEY_CHECKS = 1;
