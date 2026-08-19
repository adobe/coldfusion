# StyleMart MySQL — Seed Data

Seed DML for the Layer 1 commerce schema in the parent folder (`StyleMart/db/mysql/`).

**Prerequisite:** The DDL (`00_create_database.sql` .. `13_create_idempotency_keys.sql` in the parent folder) MUST be loaded first — these seed files only `INSERT`, they do not create tables.

## Files

| # | File | Table | Rows |
|---:|---|---|---:|
| 00 | `00_seed_run_all.sql` | _(driver)_ | — |
| 01 | `01_seed_categories.sql` | `categories` | 15 |
| 02 | `02_seed_loyalty_tiers.sql` | `loyalty_tiers` | 3 |
| 03 | `03_seed_users.sql` | `users` | 5 |
| 04 | `04_seed_products.sql` | `products` | 200 |
| 05 | `05_seed_product_variants.sql` | `product_variants` | 1,016 |
| 06 | `06_seed_product_images.sql` | `product_images` | 400 |
| 07 | `07_seed_inventory.sql` | `inventory` | 1,016 |
| 08 | `08_seed_coupons.sql` | `coupons` | 3 |
| 09 | `09_seed_promotions.sql` | `promotions` | 2 |
| 10 | `10_seed_product_reviews.sql` | `product_reviews` | 600 |

**Total: 3,260 rows across 10 tables.**

## Quick Start

```bash
# 1. Load DDL first (if not already done)
cd StyleMart/db/mysql
mysql -u root -p < 99_run_all.sql

# 2. Load seed data
cd seed
mysql -u root -p < 00_seed_run_all.sql
```

The driver prints row counts on completion; you should see:

```
status            categories  loyalty_tiers  users  products  variants  images  inventory_rows  coupons  promotions  reviews
Seed complete.    15          3              5      200       1016      400     1016            3        2           600
```

## Each file is independently re-runnable

Every file begins with `SET FOREIGN_KEY_CHECKS = 0; DELETE FROM <table>;` so you can reload one table without dropping the database. FK checks are re-enabled at the end. To re-seed a single table:

```bash
mysql -u root -p stylemart < 04_seed_products.sql
```

If you re-seed a parent table (e.g. `products`), you must also re-seed its dependents (`product_variants`, `product_images`, `product_reviews`, `inventory`).

## Demo data details

### Catalog (200 products)
- **13 leaf categories** (tshirts, shirts, jeans, pants, jackets, sweaters, raincoats, dresses, sneakers, formal-shoes, backpacks, sunglasses, accessories), each with ~10–18 products
- **2 parent categories** (menswear, womenswear) used by `parent_slug`
- All `currency = 'USD'`, `brand = 'StyleMart'`
- Prices realistic per category ($15 socks → $350 jackets), ending in `.49` or `.99`
- `attributes` and `occasion_tags` populated for every product
- `subcategory` normalised to slug form per the §8.1 regex (`crew-neck`, `low-top`, `lightweight-bomber`, etc.) — display capitalisation is the frontend's job

### Variants (1,016)
- Apparel (tshirts, shirts, jackets, dresses): 5 sizes × 2 colours = 10 variants
- Jeans, pants, sweaters, raincoats: 5 sizes × 1 colour = 5
- Sneakers, formal-shoes: 6 sizes (7–12) × 1 colour = 6
- Backpacks, sunglasses, most accessories: 1 variant
- Socks: 2 sizes × 1 colour = 2
- SKUs follow `SM-<CAT>-<COLOR>-<SIZE>` (e.g. `SM-TSH-CRE-XS`)

### Inventory (1,016)
- One row per variant (1-to-1 with `product_variants`)
- Stock distribution: ~10% have qty 1–4 (drives "Only N left!"), ~50% have 8–24 (normal), ~40% have 30–80 (no urgency)
- `updated_at` auto-set by `ON UPDATE CURRENT_TIMESTAMP` trigger from the DDL

### Images (400)
- Two per product: primary front view (`position=0`) + secondary view (`position=1`)
- Secondary is "back view" for apparel, "detail close-up" for accessories
- Plus 15 category hero images referenced from `categories.hero_image` (not in `product_images`)
- URLs use `assets/img/<filename>.png` — Firefly drops here per the workshop kit's image plan
- See `kit/seed/prompts/stylemart-firefly-prompts.md` for the full prompt set

### Users (5 demo accounts)
| user_id | display_name | tier |
|---|---|---|
| `usr_demo_001` | Jordan Lee | Silver |
| `usr_demo_002` | Sam Patel | Bronze |
| `usr_demo_003` | Riley Chen | Gold |
| `usr_demo_004` | Alex Nguyen | Silver |
| `usr_demo_005` | Morgan Garcia | Bronze |

### Loyalty tiers
| tier_id | name | discount_pct | spend_threshold |
|---|---|---:|---:|
| `tier_bronze` | Bronze | 0% | $0 |
| `tier_silver` | Silver | 5% | $500 |
| `tier_gold` | Gold | 10% | $1,500 |

### Coupons (3)
| code | type | value | scope |
|---|---|---:|---|
| `SUMMIT10` | percent | 10% | sitewide, no minimum |
| `WELCOME15` | percent | 15% | sitewide, min $75 subtotal |
| `JACKETS20` | percent | 20% | `jackets` category only |

### Promotions (2)
- `pro_summit_storewide` — 5% sitewide, active around CF Summit weekend
- `pro_jackets_seasonal` — 15% on `jackets` and `raincoats` for 45 days

### Reviews (600)
- 2–4 reviews per product, biased toward 4–5 stars (synthesised from subcategory-specific templates)
- Distributed across the 5 demo users (unique `(user_id, product_id)` enforced by `ux_reviews_user_product`)
- ~85% have `verified = TRUE`
- `created_at` spans the last 12 months

## What's NOT included

Per the team's README: "Layer 2 (AI Agent) tables are excluded from this initial implementation." The seed honours that:

- No `chat_sessions` / `messages` / `agent_traces` rows — those are session-time data created by the chat engine
- No `carts` / `cart_items` rows — carts are created at runtime
- No `orders` / `order_items` rows — built up by checkout
- No `prices` overrides — `products.base_price_cents` is authoritative for kit `[K]`
- No `applied_coupons` rows — runtime data
- No `transactional_emails` rows — written by O1/O5 endpoints at order time
- No `user_preferences` rows — set during agent onboarding flow (P1/P2)
- No `idempotency_keys` rows — request-time data

These tables stay empty after seeding; the API services populate them at runtime.

## Verification queries

```sql
USE stylemart;

-- Catalogue health
SELECT category, COUNT(*) AS products,
       SUM((SELECT COUNT(*) FROM product_variants pv WHERE pv.product_id = p.product_id)) AS variants
FROM products p
GROUP BY category
ORDER BY products DESC;

-- Inventory distribution
SELECT
  CASE
    WHEN quantity = 0 THEN 'out_of_stock'
    WHEN quantity BETWEEN 1 AND 4  THEN 'low (1-4)'
    WHEN quantity BETWEEN 5 AND 24 THEN 'normal (5-24)'
    ELSE 'high (25+)'
  END AS bucket,
  COUNT(*) AS variants
FROM inventory
GROUP BY bucket
ORDER BY MIN(quantity);

-- Reviews per user (should be balanced across the 5 demo users)
SELECT user_id, COUNT(*) AS reviews,
       ROUND(AVG(rating), 2) AS avg_rating
FROM product_reviews
GROUP BY user_id;

-- Top-rated products in catalog
SELECT p.product_id, p.name, p.category, p.average_rating, p.review_count
FROM products p
ORDER BY p.average_rating DESC, p.review_count DESC
LIMIT 10;
```

## Source

Generated by a Python builder against the canonical 200-product manifest aligned to the Firefly prompts. The same builder also produces JSON drop-ins for the mock frontend layer at `<repo>/kit/seed/json/`. Seed is deterministic via `random.seed(20260527)` — re-running produces byte-identical output.
