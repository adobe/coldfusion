# Image drop instructions

**Source:** Firefly batches generated from prompts in [`../prompts/stylemart-firefly-prompts-ordered.txt`](../prompts/stylemart-firefly-prompts-ordered.txt) (or the per-category files in [`../prompts/firefly/`](../prompts/firefly/)). See [`../prompts/stylemart-firefly-prompts-index.md`](../prompts/stylemart-firefly-prompts-index.md) for the full inventory.

**Total expected:** 415 PNG files
- 200 products × 2 views (primary front + secondary) = 400
- 15 category hero banners

## Drop targets (relative to repo root)

| File type | Target directory | Aspect ratio | Final dimensions (after upscale) |
|---|---|---|---|
| Product primary + secondary | `StyleMart/assets/img/` | 3:4 portrait | 1200 × 1600 |
| Category hero banners | `StyleMart/assets/img/` (filename starts `cat-`) | 16:9 widescreen | 1920 × 1080 |

## Filename conventions

Every filename is deterministic and already encoded in three places:

1. `kit/seed/json/products.json` — `imageUrl` and `images[].url` fields
2. `kit/seed/sql/04-products.sql` — `image_url` column
3. `kit/seed/sql/06-images.sql` — `url` column

Filenames look like:

```
tshirt_cream_relaxed-fit_organic-cotton_01.png         ← primary
tshirt_cream_relaxed-fit_organic-cotton_01_back.png    ← secondary (apparel)
sunglasses_navy_acetate_polarized-01_detail.png        ← secondary (accessories)
cat-tshirts.png                                        ← category hero
cat-menswear.png                                       ← parent category hero
```

The full list of expected filenames is in [`../prompts/stylemart-catalog-manifest.csv`](../prompts/stylemart-catalog-manifest.csv) (columns `primaryFilename`, `secondaryFilename`) and [`../prompts/stylemart-hero-banners.csv`](../prompts/stylemart-hero-banners.csv).

## Replacing the existing SVG placeholders

Currently `StyleMart/assets/img/placeholders/` contains 37 SVG placeholders referenced by the 30-row mock fixture. They serve as the visual fallback during dev.

**Two options to phase them out:**

| Option | Approach |
|---|---|
| **Hard cut-over** | Replace `assets/js/mock/fixtures/products.json` with `kit/seed/json/products.json` and drop all 415 PNGs into `assets/img/`. Frontend immediately uses the new images and the 200-product catalogue. SVG placeholders become unreferenced and can be deleted. |
| **Coexistence** | Drop the 415 PNGs in `assets/img/` first. The 30-row fixture still references SVGs so the existing mock keeps working. Swap the fixture once the UI owner signs off on the PNG quality. |

## Sanity check after dropping

```bash
# from repo root
ls StyleMart/assets/img/*.png | wc -l   # expect: 415
ls StyleMart/assets/img/cat-*.png       # expect: 15 files
```

If counts mismatch, cross-reference against `kit/seed/sql/06-images.sql` (400 product image URLs) plus `kit/seed/json/categories.json` (15 hero URLs).
