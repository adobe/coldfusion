# Firefly prompts — split by API category

Each product file contains **primary + secondary** prompts for one canonical API category slug. The 14th file holds the 16:9 lifestyle category-hero banners.

> **Where to drop the generated PNGs:** [`../../images/README.md`](../../images/README.md) (target dir: `StyleMart/assets/img/`).

## Product prompt files (3:4 portrait)

| File | API category | Products | Image prompts |
|---|---|---|---|
| `prompts-01-tshirts.txt`      | `tshirts`      | 18 | 36 |
| `prompts-02-shirts.txt`       | `shirts`       | 18 | 36 |
| `prompts-03-jeans.txt`        | `jeans`        | 12 | 24 |
| `prompts-04-pants.txt`        | `pants`        | 10 | 20 |
| `prompts-05-jackets.txt`      | `jackets`      | 16 | 32 |
| `prompts-06-dresses.txt`      | `dresses`      | 18 | 36 |
| `prompts-07-sweaters.txt`     | `sweaters`     | 14 | 28 |
| `prompts-08-raincoats.txt`    | `raincoats`    | 10 | 20 |
| `prompts-09-sneakers.txt`     | `sneakers`     | 16 | 32 |
| `prompts-10-formal-shoes.txt` | `formal-shoes` | 14 | 28 |
| `prompts-11-backpacks.txt`    | `backpacks`    | 12 | 24 |
| `prompts-12-sunglasses.txt`   | `sunglasses`   | 14 | 28 |
| `prompts-13-accessories.txt`  | `accessories`  | 28 | 56 |
| **Subtotal** | 13 categories | **200** | **400** |

## Hero banner file (16:9 lifestyle)

| File | Aspect | Count |
|---|---|---|
| `prompts-14-category-heroes.txt` | 16:9 | 15 (13 leaf + 2 parent — `menswear`, `womenswear`) |

## Common heroes (4:3 site-wide flat-lays)

| File | Aspect | Count |
|---|---|---|
| `prompts-15-common-heroes.txt` | 4:3 | 1 (home page) — drop slot for future landing pages |

## Grand total

**416** Firefly generations: 400 product prompts + 15 category banners + 1 home hero.

## Image dimensions (must match the API contract)

| Surface | Firefly aspect | Source resolution | Build-time upscale | DB column |
|---|---|---|---|---|
| Product primary | 3:4 portrait | 1024×1408 | 1200×1600 | `products.image_url` (= `product_images[0].url`) |
| Product secondary | 3:4 portrait | 1024×1408 | 1200×1600 | `product_images[1].url` |
| Category hero banner | 16:9 widescreen | 1792×1024 | 1920×1080 | `categories.hero_image` |

Apparel categories (`tshirts`, `shirts`, `jeans`, `pants`, `jackets`, `dresses`, `sweaters`, `raincoats`) get a **back view** as the secondary; footwear / bags / sunglasses / accessories (`sneakers`, `formal-shoes`, `backpacks`, `sunglasses`, `accessories`) get a **detail close-up** as the secondary. Filenames append `_back` or `_detail` before `.png`.
