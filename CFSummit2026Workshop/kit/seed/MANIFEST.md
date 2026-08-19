# StyleMart Seed Manifest

**Generated:** 2026-05-27 (regenerate via `kit/seed/build.py` — pinned with `random.seed(20260527)` for reproducibility)
**Aligned with:** `assets/js/mock/fixtures/products.json` shape (drop-in replacement)

## What's in this folder

```
kit/seed/
├── MANIFEST.md             ← you are here
├── json/                   ← drop-in replacements for assets/js/mock/fixtures/
│   ├── products.json       ← 200 products, 1,016 variants, 400 images
│   ├── categories.json     ← 15 (2 parent + 13 leaf)
│   ├── reviews.json        ← 557 reviews (~3/product, deduped to satisfy §8.2 unique(user_id, product_id))
│   ├── inventory.json      ← 1,016 variant rows (40% high, 50% normal, 10% low stock)
│   ├── coupons.json        ← 3 (SUMMIT10, WELCOME15, JACKETS20)
│   ├── loyalty.json        ← 3 tiers (Bronze, Silver, Gold)
│   ├── promotions.json     ← 2 (sitewide 5%, jackets 15%)
│   └── shoppers.json       ← 5 demo users (usr_demo_001..005)
├── prompts/                ← Firefly prompts + catalog manifests (source of truth)
│   ├── README.md
│   ├── stylemart-firefly-prompts-index.md   ← start here
│   ├── firefly/            ← 13 per-category + 1 hero file (415 prompts total)
│   ├── stylemart-firefly-prompts.md         ← bundled markdown w/ seed metadata
│   ├── stylemart-firefly-prompts-ordered.txt← flat list for batch tooling
│   ├── stylemart-firefly-prompts.csv
│   ├── stylemart-catalog-manifest.csv       ← canonical 200-row product manifest
│   └── stylemart-hero-banners.csv           ← 15-row hero manifest
└── images/
    └── README.md           ← drop instructions for Firefly-generated PNGs
```

**MySQL DDL + seed DML lives at** `StyleMart/db/mysql/` (DDL) and
`StyleMart/db/mysql/seed/` (seed). See those folders' READMEs for details.

## Three drop targets

| Target | What to do | When |
|---|---|---|
| **Mock layer** | Copy `json/products.json` over `StyleMart/assets/js/mock/fixtures/products.json`. Same for `categories.json`, etc. once the mock handlers reference them. | Now — to expand mock catalog from 30 to 200 products. |
| **MySQL** | DDL: `cd StyleMart/db/mysql && mysql -u root -p < 99_run_all.sql`. Seed: `cd seed && mysql -u root -p < 00_seed_run_all.sql`. | When backend lands. |
| **Image directory** | Drop 415 Firefly-generated PNGs into `StyleMart/assets/img/`. Prompts live in [`prompts/firefly/`](prompts/firefly/); filename conventions and drop instructions in [`images/README.md`](images/README.md). | Whenever Firefly batches finish. |

## Row counts

| Table | Rows | Notes |
|---|---:|---|
| `categories` | 15 | 2 parent (menswear, womenswear) + 13 leaf |
| `loyalty_tiers` | 3 | Bronze (0% / $0), Silver (5% / $500), Gold (10% / $1500) |
| `users` | 5 | `usr_demo_001..005`, each with a username (`jordan`/`sam`/`riley`/`alex`/`morgan`), bcrypt-hashed password, and loyalty tier. **All 5 share the workshop password `Workshop2026!`** — see §4.4 auth model in the contract. |
| `products` | 200 | 13 categories, ~15 products/category, brand always `StyleMart`, USD only |
| `product_variants` | 1,016 | Full cross-product of sizes × colors per product |
| `product_images` | 400 | 2 per product (primary + secondary view) |
| `inventory` | 1,016 | One row per variant; stock 1–80 with skewed distribution |
| `coupons` | 3 | `SUMMIT10` (10%), `WELCOME15` (15% / min $75), `JACKETS20` (20% / jackets only) |
| `promotions` | 2 | sitewide 5% + jackets/raincoats 15% |
| `product_reviews` | 557 (json) / 600 (sql) | 1–4 per product, distributed across the 5 demo users, biased toward 4–5 stars. JSON was deduped post-hoc to satisfy §8.2 unique(user_id, product_id); SQL was generated with the constraint already enforced. |

## Key alignment notes

- **MySQL dialect** (not Postgres) — matches the team's existing DDL in `StyleMart/db/mysql/`. `JSON` columns instead of `JSONB`/`TEXT[]`, `TIMESTAMP` instead of `TIMESTAMPTZ`, no `::CAST` syntax, no `TRUNCATE … CASCADE`.
- **`subcategory` is normalised to slug form.** "low top" → `low-top`, "lightweight bomber" → `lightweight-bomber`, etc., matching the regex `^[a-z0-9]+(-[a-z0-9]+)*$`. Display capitalisation is the frontend's responsibility.
- **`coupons.type`** uses `'percent'` / `'fixed'` per the schema's `CHECK` constraint. (JSON files use `"percentage"` for human readability — the SQL generator translates.)
- **Reviews satisfy the unique `(user_id, product_id)` index.** Each of 200 products gets up to 5 unique reviewers (one per demo user); generator caps at 3 reviews/product to stay well under that ceiling. Zero rows skipped at generation time.
- **Image URLs are `assets/img/<filename>.png` (no leading slash)** to match the current SVG placeholder convention in `assets/js/mock/fixtures/products.json`. The CFML server's webroot makes this map to `<host>/assets/img/<filename>.png` and the API contract's `/static/img/` example is equivalent for any sensible web-server config.
- **Variants strategy**: apparel categories (tshirts, shirts, jackets, dresses) get 2 colour variants × 5 sizes = 10. Jeans, pants, sweaters, raincoats: 1 colour × 5 sizes = 5. Shoes: 1 colour × 6 sizes = 6. Bags/sunglasses/most accessories: 1 variant. Socks: 1 × 2 sizes.
- **Stock distribution** is deliberately uneven to enable demo signals: ~10% of variants have stock 1–4 (drives "Only 3 left!" badges and the §6 MCP inventory tool), ~50% have stock 8–24 (normal), ~40% have stock 30–80 (no urgency).

## What's **not** in this seed

- **Generated assets** (Session 6 fixtures: recovery email, landing section, upsell pitch). Those are in `assets/js/mock/fixtures/assets.json` and remain hand-curated for the workshop demo path.
- **Cart fixtures** (`carts.json`). The cart is reset on session start; demo cart is built by the SSE scenario script.
- **Chat sessions / messages / traces.** Those live entirely in the SSE mock engine (`assets/js/mock/sse/`); the DB seed is commerce-data only.
- **`prices` overrides table.** Kit `[K]` uses `products.base_price_cents` only — no segment overrides. Re-add when per-segment pricing ships as a stretch `[S]`.

## Regenerating

```bash
cd kit/seed/
python3 build.py            # writes both json/ and sql/ from the manifest CSV
```

The build script is deterministic (`random.seed(20260527)`); re-running produces byte-identical files.
