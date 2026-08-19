-- StyleMart MySQL seed data
-- 01 - Categories (15 rows: 2 parent + 13 leaf)
-- Target table: categories
-- Schema: /Users/ndubey/Downloads/db/mysql/ (Layer 1 commerce DDL)
-- Generated: 2026-05-27 (regenerate via repo path: kit/seed/build.py)
--
-- IMPORTANT: Run DDL (00_create_database.sql .. 13_create_idempotency_keys.sql) FIRST.
-- Then run files in this directory in order via 00_seed_run_all.sql

USE stylemart;

SET FOREIGN_KEY_CHECKS = 0;
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

SET FOREIGN_KEY_CHECKS = 1;
