# Firefly prompts + catalog manifests

Source-of-truth Adobe Firefly prompts for the 415 StyleMart images
(200 products × 2 views + 15 category hero banners).

## Files

| File | Purpose |
|---|---|
| [`stylemart-firefly-prompts-index.md`](stylemart-firefly-prompts-index.md) | **Start here.** Maps API categories → per-category prompt files and explains conventions. |
| [`firefly/`](firefly/) | One `.txt` per category (1–13) plus `prompts-14-category-heroes.txt`. **Paste each block into Firefly individually.** |
| [`stylemart-firefly-prompts.md`](stylemart-firefly-prompts.md) | Full bundled markdown — every prompt with its seed-metadata JSON block, settings, and upscale target. |
| [`stylemart-firefly-prompts-ordered.txt`](stylemart-firefly-prompts-ordered.txt) | Flat newline-delimited list of all 415 prompts in catalog order — handy for batch tooling. |
| [`stylemart-firefly-prompts.csv`](stylemart-firefly-prompts.csv) | CSV variant of the prompt set with one row per image. |
| [`stylemart-catalog-manifest.csv`](stylemart-catalog-manifest.csv) | Canonical 200-row product manifest (columns: `productId`, `slug`, `category`, `subcategory`, `colors`, `fit`, `fabric`, `primaryFilename`, `secondaryFilename`, …). This drives both the SQL seed and the JSON seed generators. |
| [`stylemart-hero-banners.csv`](stylemart-hero-banners.csv) | 15-row category-hero manifest (columns: `categorySlug`, `parentSlug`, `heroFilename`, `prompt`, …). |

## Where the PNGs go

After generating in Firefly, drop every `.png` into
[`../../StyleMart/assets/img/`](../../StyleMart/assets/img/). See
[`../images/README.md`](../images/README.md) for the per-aspect-ratio breakdown
and the sanity-check command.

## Why prompts live in the repo

So that:
1. Anyone on the workshop team can regenerate, audit, or extend prompts
   without needing access to the original author's laptop.
2. Filename conventions stay traceable end-to-end: prompt → PNG → `assets/img/` →
   `kit/seed/json/products.json` (`imageUrl`) → `StyleMart/db/mysql/seed/`
   (`image_url` columns). A grep of `tshirt_cream_relaxed-fit_organic-cotton_01.png`
   should hit prompt, JSON seed, and SQL seed.
3. Future contract amendments (new colors, new subcategories) can be diffed
   against the prompts that generated the current image set.

## Generation budget

| Item | Count |
|---|---:|
| Product primary views (3:4 portrait, 1024×1408 → upscale 1200×1600) | 200 |
| Product secondary views (apparel = `_back`; accessories = `_detail`) | 200 |
| Category hero banners (16:9, 1792×1024 → upscale 1920×1080) | 15 |
| **Total Firefly generations** | **415** |
