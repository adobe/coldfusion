# StyleMart Firefly Prompt Index

> **Generation order:** start with the per-category files in `firefly/`. Open
> the file, paste each prompt into Firefly, save the PNG with the filename
> shown above each prompt (e.g. `tshirt_cream_relaxed-fit_organic-cotton_01.png`),
> then drop the file into `StyleMart/assets/img/` (see
> [`../images/README.md`](../images/README.md)).

**Catalog:** 200 products × 2 images = 400 product prompts
**Hero banners:** 15 (13 leaf + 2 parent categories)
**Total Firefly generations:** 415

## Per-category files (3:4 portrait product shots)

| File | API category | Products | Image prompts |
|---|---|---|---|
| `firefly/prompts-01-tshirts.txt` | `tshirts` (T-Shirts) | 18 | 36 |
| `firefly/prompts-02-shirts.txt` | `shirts` (Button-Down Shirts) | 18 | 36 |
| `firefly/prompts-03-jeans.txt` | `jeans` (Jeans) | 12 | 24 |
| `firefly/prompts-04-pants.txt` | `pants` (Pants & Trousers) | 10 | 20 |
| `firefly/prompts-05-jackets.txt` | `jackets` (Jackets & Blazers) | 16 | 32 |
| `firefly/prompts-06-dresses.txt` | `dresses` (Dresses) | 18 | 36 |
| `firefly/prompts-07-sweaters.txt` | `sweaters` (Sweaters & Cardigans) | 14 | 28 |
| `firefly/prompts-08-raincoats.txt` | `raincoats` (Raincoats) | 10 | 20 |
| `firefly/prompts-09-sneakers.txt` | `sneakers` (Sneakers) | 16 | 32 |
| `firefly/prompts-10-formal-shoes.txt` | `formal-shoes` (Formal Shoes) | 14 | 28 |
| `firefly/prompts-11-backpacks.txt` | `backpacks` (Backpacks) | 12 | 24 |
| `firefly/prompts-12-sunglasses.txt` | `sunglasses` (Sunglasses) | 14 | 28 |
| `firefly/prompts-13-accessories.txt` | `accessories` (Accessories) | 28 | 56 |

## Hero banners (16:9 lifestyle)

| File | Aspect | Count |
|---|---|---|
| `firefly/prompts-14-category-heroes.txt` | 16:9 | 15 |

## Companion files

- Full prompts (single file): `stylemart-firefly-prompts-ordered.txt`
- Markdown with seed metadata per prompt: `stylemart-firefly-prompts.md`
- Catalog seed manifest (CSV, 200 rows): `stylemart-catalog-manifest.csv`
- Hero banner manifest (CSV, 15 rows): `stylemart-hero-banners.csv`
- Original CSV (legacy 500-product source): `stylemart-firefly-prompts.csv`