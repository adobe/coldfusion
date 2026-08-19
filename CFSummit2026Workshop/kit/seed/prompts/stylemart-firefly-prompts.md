# StyleMart Firefly Image Prompts

**Total prompts:** 415  ·  **Products:** 200 × 2 images = 400  ·  **Category heroes:** 15

**Firefly settings:**

| Surface | Aspect Ratio | Source resolution | Build-time upscale target |
|---|---|---|---|
| Product primary + secondary | **3:4 Portrait** | 1024×1408 | 1200×1600 (PDP hero) |
| Category hero banner | **16:9 Widescreen** | 1792×1024 | 1920×1080 (mega-menu / category landing) |

**Tip:** After your first good output per family, set it as Style Reference for all remaining prompts in that family so style stays consistent across hundreds of generations.

### Post-generation upscale (one-shot, build-time only)

```bash
# Product images (3:4) → 1200x1600 for /static/img/<filename>
magick input.png -resize 1200x1600 -quality 90 output.png
# Category hero banners (16:9) → 1920x1080 for /static/img/cat-*.png
magick input.png -resize 1920x1080 -quality 90 output.png
```

---

## Alignment with API contract

This file is the source-of-truth catalog manifest for the seed script that populates `products`, `product_images`, and `categories.hero_image`.

Each product carries **two** Firefly prompts:

- **Primary view** (front / hung / flat-lay) → seeds `products.image_url` and `product_images` row at `position=0`.
- **Secondary view** (back view for apparel; detail close-up for shoes / bags / sunglasses / accessories) → seeds `product_images` row at `position=1`.

Each category carries **one** lifestyle hero banner (16:9) → seeds `categories.hero_image` (file family `/static/img/cat-*.png` per §3.4.1).

### Image inventory

| Surface | DB column / row | Aspect | Count |
|---|---|---|---|
| Product primary | `products.image_url` (= `product_images[0].url`) | 3:4 | 200 |
| Product secondary | `product_images[1].url` | 3:4 | 200 |
| Category hero banner | `categories.hero_image` | 16:9 | 15 |
| **Total Firefly generations** | | | **415** |

### Category coverage (13 leaf API categories)

| API slug | Section | Products | Subcategories represented |
|---|---|---|---|
| `tshirts` | T-Shirts | 18 | crew-neck (18) |
| `shirts` | Button-Down Shirts | 18 | button-down (18) |
| `jeans` | Jeans | 12 | denim (12) |
| `pants` | Pants & Trousers | 10 | chinos (5), trousers (5) |
| `jackets` | Jackets & Blazers | 16 | lightweight bomber (4), packable jacket (4), soft shoulder blazer (4), travel blazer (4) |
| `dresses` | Dresses | 18 | a-line (4), sheath (4), shift (3), tiered (3), wrap (4) |
| `sweaters` | Sweaters & Cardigans | 14 | cardigan (4), crew-neck-sweater (5), half-zip-pullover (5) |
| `raincoats` | Raincoats | 10 | double breasted trench (3), packable (4), technical shell (3) |
| `sneakers` | Sneakers | 16 | low top (5), mid top (3), minimalist (4), retro (4) |
| `formal-shoes` | Formal Shoes | 14 | derby (4), loafer (3), monk-strap (3), oxford (4) |
| `backpacks` | Backpacks | 12 | daypack (3), minimalist commuter (3), roll top (3), technical travel (3) |
| `sunglasses` | Sunglasses | 14 | aviator (2), oversized square (2), rectangular (3), rimless (2), round (3), wayfarer (2) |
| `accessories` | Accessories | 28 | beanie (4), cable-organizer (3), packing-cubes (4), scarf (4), socks (3), towel (3), umbrella (4), wallet (3) |

### Notes on changes from the previous 500-product layout

- Catalog reduced from **500 → 200 products** so we can ship two real PDP images per product without doubling Firefly cost.
- Each product now has a **primary** prompt + a **secondary** prompt (back view for apparel; detail close-up for footwear / bags / sunglasses / accessories).
- Category hero banners (15 total: 13 leaf + 2 parent) added as a separate 16:9 prompt set.
- Total Firefly generations: 200 × 2 + 15 = **415** (vs the previous 500 single-shots).
- Filenames preserved for primary; secondary view appends `_back` or `_detail` before `.png`.

---

## T-Shirts — `tshirts`

**API category slug:** `tshirts`  ·  **Products:** 18  ·  **Images:** 36 (primary + secondary)

### 1. `tshirt_cream_relaxed-fit_organic-cotton_01.png` &nbsp;·&nbsp; **primary**

Cream relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 1. `tshirt_cream_relaxed-fit_organic-cotton_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Cream relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Cream Crew Neck Tshirts",
  "color": "cream",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "organic cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_cream_relaxed-fit_organic-cotton_01.png",
  "secondaryImageUrl": "/static/img/tshirt_cream_relaxed-fit_organic-cotton_01_back.png",
  "secondaryViewType": "back"
}
```

### 2. `tshirt_white_slim-fit_pima-cotton_02.png` &nbsp;·&nbsp; **primary**

White slim-fit crew-neck pima cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 2. `tshirt_white_slim-fit_pima-cotton_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of White slim-fit crew-neck pima cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "White Crew Neck Tshirts",
  "color": "white",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "pima cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_white_slim-fit_pima-cotton_02.png",
  "secondaryImageUrl": "/static/img/tshirt_white_slim-fit_pima-cotton_02_back.png",
  "secondaryViewType": "back"
}
```

### 3. `tshirt_off-white_regular-fit_cotton-modal_03.png` &nbsp;·&nbsp; **primary**

Off-White regular-fit crew-neck cotton-modal t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 3. `tshirt_off-white_regular-fit_cotton-modal_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Off White regular-fit crew-neck cotton modal t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Off White Crew Neck Tshirts",
  "color": "off white",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton modal"
  },
  "primaryImageUrl": "/static/img/tshirt_off-white_regular-fit_cotton-modal_03.png",
  "secondaryImageUrl": "/static/img/tshirt_off-white_regular-fit_cotton-modal_03_back.png",
  "secondaryViewType": "back"
}
```

### 4. `tshirt_sage-green_relaxed-fit_organic-cotton_04.png` &nbsp;·&nbsp; **primary**

Sage Green relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 4. `tshirt_sage-green_relaxed-fit_organic-cotton_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sage Green relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Sage Green Crew Neck Tshirts",
  "color": "sage green",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "organic cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_sage-green_relaxed-fit_organic-cotton_04.png",
  "secondaryImageUrl": "/static/img/tshirt_sage-green_relaxed-fit_organic-cotton_04_back.png",
  "secondaryViewType": "back"
}
```

### 5. `tshirt_dusty-rose_regular-fit_cotton_05.png` &nbsp;·&nbsp; **primary**

Dusty Rose regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 5. `tshirt_dusty-rose_regular-fit_cotton_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Dusty Rose regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Dusty Rose Crew Neck Tshirts",
  "color": "dusty rose",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_dusty-rose_regular-fit_cotton_05.png",
  "secondaryImageUrl": "/static/img/tshirt_dusty-rose_regular-fit_cotton_05_back.png",
  "secondaryViewType": "back"
}
```

### 6. `tshirt_navy_slim-fit_cotton-blend_06.png` &nbsp;·&nbsp; **primary**

Navy slim-fit crew-neck cotton-blend t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 6. `tshirt_navy_slim-fit_cotton-blend_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy slim-fit crew-neck cotton blend t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Navy Crew Neck Tshirts",
  "color": "navy",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "cotton blend"
  },
  "primaryImageUrl": "/static/img/tshirt_navy_slim-fit_cotton-blend_06.png",
  "secondaryImageUrl": "/static/img/tshirt_navy_slim-fit_cotton-blend_06_back.png",
  "secondaryViewType": "back"
}
```

### 7. `tshirt_charcoal_regular-fit_cotton_07.png` &nbsp;·&nbsp; **primary**

Charcoal regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 7. `tshirt_charcoal_regular-fit_cotton_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Charcoal Crew Neck Tshirts",
  "color": "charcoal",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_charcoal_regular-fit_cotton_07.png",
  "secondaryImageUrl": "/static/img/tshirt_charcoal_regular-fit_cotton_07_back.png",
  "secondaryViewType": "back"
}
```

### 8. `tshirt_ivory_relaxed-fit_organic-cotton_08.png` &nbsp;·&nbsp; **primary**

Ivory relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 8. `tshirt_ivory_relaxed-fit_organic-cotton_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Ivory relaxed-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Ivory Crew Neck Tshirts",
  "color": "ivory",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "organic cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_ivory_relaxed-fit_organic-cotton_08.png",
  "secondaryImageUrl": "/static/img/tshirt_ivory_relaxed-fit_organic-cotton_08_back.png",
  "secondaryViewType": "back"
}
```

### 9. `tshirt_terracotta_regular-fit_cotton_09.png` &nbsp;·&nbsp; **primary**

Terracotta regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 9. `tshirt_terracotta_regular-fit_cotton_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Terracotta regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Terracotta Crew Neck Tshirts",
  "color": "terracotta",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_terracotta_regular-fit_cotton_09.png",
  "secondaryImageUrl": "/static/img/tshirt_terracotta_regular-fit_cotton_09_back.png",
  "secondaryViewType": "back"
}
```

### 10. `tshirt_olive_relaxed-fit_cotton-blend_10.png` &nbsp;·&nbsp; **primary**

Olive relaxed-fit crew-neck cotton-blend t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 10. `tshirt_olive_relaxed-fit_cotton-blend_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive relaxed-fit crew-neck cotton blend t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Olive Crew Neck Tshirts",
  "color": "olive",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "cotton blend"
  },
  "primaryImageUrl": "/static/img/tshirt_olive_relaxed-fit_cotton-blend_10.png",
  "secondaryImageUrl": "/static/img/tshirt_olive_relaxed-fit_cotton-blend_10_back.png",
  "secondaryViewType": "back"
}
```

### 11. `tshirt_slate-blue_slim-fit_cotton-modal_11.png` &nbsp;·&nbsp; **primary**

Slate Blue slim-fit crew-neck cotton-modal t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 11. `tshirt_slate-blue_slim-fit_cotton-modal_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Slate Blue slim-fit crew-neck cotton modal t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Slate Blue Crew Neck Tshirts",
  "color": "slate blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "cotton modal"
  },
  "primaryImageUrl": "/static/img/tshirt_slate-blue_slim-fit_cotton-modal_11.png",
  "secondaryImageUrl": "/static/img/tshirt_slate-blue_slim-fit_cotton-modal_11_back.png",
  "secondaryViewType": "back"
}
```

### 12. `tshirt_burgundy_regular-fit_cotton_12.png` &nbsp;·&nbsp; **primary**

Burgundy regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 12. `tshirt_burgundy_regular-fit_cotton_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Burgundy regular-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Burgundy Crew Neck Tshirts",
  "color": "burgundy",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_burgundy_regular-fit_cotton_12.png",
  "secondaryImageUrl": "/static/img/tshirt_burgundy_regular-fit_cotton_12_back.png",
  "secondaryViewType": "back"
}
```

### 13. `tshirt_white_oversized_cotton_13.png` &nbsp;·&nbsp; **primary**

White oversized crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 13. `tshirt_white_oversized_cotton_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of White oversized crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "White Crew Neck Tshirts",
  "color": "white",
  "attributes": {
    "fit": "oversized",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_white_oversized_cotton_13.png",
  "secondaryImageUrl": "/static/img/tshirt_white_oversized_cotton_13_back.png",
  "secondaryViewType": "back"
}
```

### 14. `tshirt_black_slim-fit_cotton_14.png` &nbsp;·&nbsp; **primary**

Black slim-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 14. `tshirt_black_slim-fit_cotton_14_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black slim-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Black Crew Neck Tshirts",
  "color": "black",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_black_slim-fit_cotton_14.png",
  "secondaryImageUrl": "/static/img/tshirt_black_slim-fit_cotton_14_back.png",
  "secondaryViewType": "back"
}
```

### 15. `tshirt_light-gray_regular-fit_cotton-modal_15.png` &nbsp;·&nbsp; **primary**

Light Gray regular-fit crew-neck cotton-modal t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 15. `tshirt_light-gray_regular-fit_cotton-modal_15_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Light Gray regular-fit crew-neck cotton modal t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Light Gray Crew Neck Tshirts",
  "color": "light gray",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton modal"
  },
  "primaryImageUrl": "/static/img/tshirt_light-gray_regular-fit_cotton-modal_15.png",
  "secondaryImageUrl": "/static/img/tshirt_light-gray_regular-fit_cotton-modal_15_back.png",
  "secondaryViewType": "back"
}
```

### 16. `tshirt_sky-blue_slim-fit_pima-cotton_16.png` &nbsp;·&nbsp; **primary**

Sky Blue slim-fit crew-neck pima cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 16. `tshirt_sky-blue_slim-fit_pima-cotton_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sky Blue slim-fit crew-neck pima cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Sky Blue Crew Neck Tshirts",
  "color": "sky blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "pima cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_sky-blue_slim-fit_pima-cotton_16.png",
  "secondaryImageUrl": "/static/img/tshirt_sky-blue_slim-fit_pima-cotton_16_back.png",
  "secondaryViewType": "back"
}
```

### 17. `tshirt_mustard_relaxed-fit_cotton_17.png` &nbsp;·&nbsp; **primary**

Mustard relaxed-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 17. `tshirt_mustard_relaxed-fit_cotton_17_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Mustard relaxed-fit crew-neck cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Mustard Crew Neck Tshirts",
  "color": "mustard",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_mustard_relaxed-fit_cotton_17.png",
  "secondaryImageUrl": "/static/img/tshirt_mustard_relaxed-fit_cotton_17_back.png",
  "secondaryViewType": "back"
}
```

### 18. `tshirt_forest-green_regular-fit_organic-cotton_18.png` &nbsp;·&nbsp; **primary**

Forest Green regular-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down on the backdrop, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 18. `tshirt_forest-green_regular-fit_organic-cotton_18_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green regular-fit crew-neck organic cotton t-shirt with short sleeves, displayed flat-lay top-down with back side facing up, neckline ribbing visible at the top, hem flat at the bottom, neatly arranged with subtle natural folds. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "tshirts",
  "subcategory": "crew-neck",
  "displayName": "Forest Green Crew Neck Tshirts",
  "color": "forest green",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "organic cotton"
  },
  "primaryImageUrl": "/static/img/tshirt_forest-green_regular-fit_organic-cotton_18.png",
  "secondaryImageUrl": "/static/img/tshirt_forest-green_regular-fit_organic-cotton_18_back.png",
  "secondaryViewType": "back"
}
```

## Button-Down Shirts — `shirts`

**API category slug:** `shirts`  ·  **Products:** 18  ·  **Images:** 36 (primary + secondary)

### 19. `shirt_white_regular_cotton-poplin_01.png` &nbsp;·&nbsp; **primary**

White regular-fit spread-collar cotton poplin button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 19. `shirt_white_regular_cotton-poplin_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of White regular-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "White Button Down Shirts",
  "color": "white",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_white_regular_cotton-poplin_01.png",
  "secondaryImageUrl": "/static/img/shirt_white_regular_cotton-poplin_01_back.png",
  "secondaryViewType": "back"
}
```

### 20. `shirt_sky-blue_slim_oxford-cotton_02.png` &nbsp;·&nbsp; **primary**

Sky Blue slim-fit button-down-collar oxford cotton button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 20. `shirt_sky-blue_slim_oxford-cotton_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sky Blue slim-fit oxford cotton button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Sky Blue Button Down Shirts",
  "color": "sky blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "oxford cotton"
  },
  "primaryImageUrl": "/static/img/shirt_sky-blue_slim_oxford-cotton_02.png",
  "secondaryImageUrl": "/static/img/shirt_sky-blue_slim_oxford-cotton_02_back.png",
  "secondaryViewType": "back"
}
```

### 21. `shirt_light-gray_regular_cotton-poplin_03.png` &nbsp;·&nbsp; **primary**

Light Gray regular-fit spread-collar cotton poplin button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 21. `shirt_light-gray_regular_cotton-poplin_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Light Gray regular-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Light Gray Button Down Shirts",
  "color": "light gray",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_light-gray_regular_cotton-poplin_03.png",
  "secondaryImageUrl": "/static/img/shirt_light-gray_regular_cotton-poplin_03_back.png",
  "secondaryViewType": "back"
}
```

### 22. `shirt_navy_slim_oxford-cotton_04.png` &nbsp;·&nbsp; **primary**

Navy slim-fit button-down-collar oxford cotton button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 22. `shirt_navy_slim_oxford-cotton_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy slim-fit oxford cotton button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Navy Button Down Shirts",
  "color": "navy",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "oxford cotton"
  },
  "primaryImageUrl": "/static/img/shirt_navy_slim_oxford-cotton_04.png",
  "secondaryImageUrl": "/static/img/shirt_navy_slim_oxford-cotton_04_back.png",
  "secondaryViewType": "back"
}
```

### 23. `shirt_sage_relaxed_linen-cotton-blend_05.png` &nbsp;·&nbsp; **primary**

Sage relaxed-fit mandarin-collar linen-cotton blend button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 23. `shirt_sage_relaxed_linen-cotton-blend_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sage relaxed-fit linen cotton blend button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Sage Button Down Shirts",
  "color": "sage",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "linen cotton blend"
  },
  "primaryImageUrl": "/static/img/shirt_sage_relaxed_linen-cotton-blend_05.png",
  "secondaryImageUrl": "/static/img/shirt_sage_relaxed_linen-cotton-blend_05_back.png",
  "secondaryViewType": "back"
}
```

### 24. `shirt_ecru_regular_washed-linen_06.png` &nbsp;·&nbsp; **primary**

Ecru regular-fit spread-collar washed linen button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 24. `shirt_ecru_regular_washed-linen_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Ecru regular-fit washed linen button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Ecru Button Down Shirts",
  "color": "ecru",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "washed linen"
  },
  "primaryImageUrl": "/static/img/shirt_ecru_regular_washed-linen_06.png",
  "secondaryImageUrl": "/static/img/shirt_ecru_regular_washed-linen_06_back.png",
  "secondaryViewType": "back"
}
```

### 25. `shirt_oxford-blue_slim_oxford-cotton_07.png` &nbsp;·&nbsp; **primary**

Oxford Blue slim-fit button-down-collar oxford cotton button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 25. `shirt_oxford-blue_slim_oxford-cotton_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Oxford Blue slim-fit oxford cotton button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Oxford Blue Button Down Shirts",
  "color": "oxford blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "oxford cotton"
  },
  "primaryImageUrl": "/static/img/shirt_oxford-blue_slim_oxford-cotton_07.png",
  "secondaryImageUrl": "/static/img/shirt_oxford-blue_slim_oxford-cotton_07_back.png",
  "secondaryViewType": "back"
}
```

### 26. `shirt_charcoal_tailored_cotton-poplin_08.png` &nbsp;·&nbsp; **primary**

Charcoal tailored-fit spread-collar cotton poplin button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 26. `shirt_charcoal_tailored_cotton-poplin_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal tailored-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Charcoal Button Down Shirts",
  "color": "charcoal",
  "attributes": {
    "fit": "tailored-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_charcoal_tailored_cotton-poplin_08.png",
  "secondaryImageUrl": "/static/img/shirt_charcoal_tailored_cotton-poplin_08_back.png",
  "secondaryViewType": "back"
}
```

### 27. `shirt_dusty-blue_regular_chambray_09.png` &nbsp;·&nbsp; **primary**

Dusty Blue regular-fit button-down-collar chambray button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 27. `shirt_dusty-blue_regular_chambray_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Dusty Blue regular-fit chambray button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Dusty Blue Button Down Shirts",
  "color": "dusty blue",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "chambray"
  },
  "primaryImageUrl": "/static/img/shirt_dusty-blue_regular_chambray_09.png",
  "secondaryImageUrl": "/static/img/shirt_dusty-blue_regular_chambray_09_back.png",
  "secondaryViewType": "back"
}
```

### 28. `shirt_ivory_relaxed_washed-linen_10.png` &nbsp;·&nbsp; **primary**

Ivory relaxed-fit mandarin-collar washed linen button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 28. `shirt_ivory_relaxed_washed-linen_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Ivory relaxed-fit washed linen button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Ivory Button Down Shirts",
  "color": "ivory",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "washed linen"
  },
  "primaryImageUrl": "/static/img/shirt_ivory_relaxed_washed-linen_10.png",
  "secondaryImageUrl": "/static/img/shirt_ivory_relaxed_washed-linen_10_back.png",
  "secondaryViewType": "back"
}
```

### 29. `shirt_black_slim_cotton-poplin_11.png` &nbsp;·&nbsp; **primary**

Black slim-fit spread-collar cotton poplin button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 29. `shirt_black_slim_cotton-poplin_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black slim-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Black Button Down Shirts",
  "color": "black",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_black_slim_cotton-poplin_11.png",
  "secondaryImageUrl": "/static/img/shirt_black_slim_cotton-poplin_11_back.png",
  "secondaryViewType": "back"
}
```

### 30. `shirt_pale-pink_regular_oxford-cotton_12.png` &nbsp;·&nbsp; **primary**

Pale Pink regular-fit button-down-collar oxford cotton button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 30. `shirt_pale-pink_regular_oxford-cotton_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Pale Pink regular-fit oxford cotton button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Pale Pink Button Down Shirts",
  "color": "pale pink",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "oxford cotton"
  },
  "primaryImageUrl": "/static/img/shirt_pale-pink_regular_oxford-cotton_12.png",
  "secondaryImageUrl": "/static/img/shirt_pale-pink_regular_oxford-cotton_12_back.png",
  "secondaryViewType": "back"
}
```

### 31. `shirt_olive_relaxed_linen-cotton-blend_13.png` &nbsp;·&nbsp; **primary**

Olive relaxed-fit spread-collar linen-cotton blend button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 31. `shirt_olive_relaxed_linen-cotton-blend_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive relaxed-fit linen cotton blend button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Olive Button Down Shirts",
  "color": "olive",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "linen cotton blend"
  },
  "primaryImageUrl": "/static/img/shirt_olive_relaxed_linen-cotton-blend_13.png",
  "secondaryImageUrl": "/static/img/shirt_olive_relaxed_linen-cotton-blend_13_back.png",
  "secondaryViewType": "back"
}
```

### 32. `shirt_midnight-blue_slim_cotton-poplin_14.png` &nbsp;·&nbsp; **primary**

Midnight Blue slim-fit button-down-collar cotton poplin button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 32. `shirt_midnight-blue_slim_cotton-poplin_14_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Midnight Blue slim-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Midnight Blue Button Down Shirts",
  "color": "midnight blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_midnight-blue_slim_cotton-poplin_14.png",
  "secondaryImageUrl": "/static/img/shirt_midnight-blue_slim_cotton-poplin_14_back.png",
  "secondaryViewType": "back"
}
```

### 33. `shirt_beige_regular_washed-linen_15.png` &nbsp;·&nbsp; **primary**

Beige regular-fit spread-collar washed linen button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 33. `shirt_beige_regular_washed-linen_15_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Beige regular-fit washed linen button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Beige Button Down Shirts",
  "color": "beige",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "washed linen"
  },
  "primaryImageUrl": "/static/img/shirt_beige_regular_washed-linen_15.png",
  "secondaryImageUrl": "/static/img/shirt_beige_regular_washed-linen_15_back.png",
  "secondaryViewType": "back"
}
```

### 34. `shirt_burgundy_slim_oxford-cotton_16.png` &nbsp;·&nbsp; **primary**

Burgundy slim-fit button-down-collar oxford cotton button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 34. `shirt_burgundy_slim_oxford-cotton_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Burgundy slim-fit oxford cotton button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Burgundy Button Down Shirts",
  "color": "burgundy",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "oxford cotton"
  },
  "primaryImageUrl": "/static/img/shirt_burgundy_slim_oxford-cotton_16.png",
  "secondaryImageUrl": "/static/img/shirt_burgundy_slim_oxford-cotton_16_back.png",
  "secondaryViewType": "back"
}
```

### 35. `shirt_teal_regular_cotton-poplin_17.png` &nbsp;·&nbsp; **primary**

Teal regular-fit spread-collar cotton poplin button-down shirt with long sleeves and straight hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 35. `shirt_teal_regular_cotton-poplin_17_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Teal regular-fit cotton poplin button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Teal Button Down Shirts",
  "color": "teal",
  "attributes": {
    "fit": "regular-fit",
    "fabric": "cotton poplin"
  },
  "primaryImageUrl": "/static/img/shirt_teal_regular_cotton-poplin_17.png",
  "secondaryImageUrl": "/static/img/shirt_teal_regular_cotton-poplin_17_back.png",
  "secondaryViewType": "back"
}
```

### 36. `shirt_sand_relaxed_linen-cotton-blend_18.png` &nbsp;·&nbsp; **primary**

Sand relaxed-fit mandarin-collar linen-cotton blend button-down shirt with long sleeves and curved hem, displayed flat-lay on the backdrop, collar slightly open, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 36. `shirt_sand_relaxed_linen-cotton-blend_18_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sand relaxed-fit linen cotton blend button-down shirt, displayed flat-lay top-down with back side facing up, yoke and shoulder seams visible across the upper back, sleeves neatly aligned. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "shirts",
  "subcategory": "button-down",
  "displayName": "Sand Button Down Shirts",
  "color": "sand",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "linen cotton blend"
  },
  "primaryImageUrl": "/static/img/shirt_sand_relaxed_linen-cotton-blend_18.png",
  "secondaryImageUrl": "/static/img/shirt_sand_relaxed_linen-cotton-blend_18_back.png",
  "secondaryViewType": "back"
}
```

## Jeans — `jeans`

**API category slug:** `jeans`  ·  **Products:** 12  ·  **Images:** 24 (primary + secondary)

### 37. `jeans_indigo_slim-fit_12oz-denim_01.png` &nbsp;·&nbsp; **primary**

Indigo slim-fit 12oz denim jeans, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 37. `jeans_indigo_slim-fit_12oz-denim_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Indigo slim-fit 12oz denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Indigo Denim Jeans",
  "color": "indigo",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "12oz denim"
  },
  "primaryImageUrl": "/static/img/jeans_indigo_slim-fit_12oz-denim_01.png",
  "secondaryImageUrl": "/static/img/jeans_indigo_slim-fit_12oz-denim_01_back.png",
  "secondaryViewType": "back"
}
```

### 38. `jeans_black_straight-fit_stretch-denim_02.png` &nbsp;·&nbsp; **primary**

Black straight-fit stretch denim jeans, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 38. `jeans_black_straight-fit_stretch-denim_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black straight-fit stretch denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Black Denim Jeans",
  "color": "black",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "stretch denim"
  },
  "primaryImageUrl": "/static/img/jeans_black_straight-fit_stretch-denim_02.png",
  "secondaryImageUrl": "/static/img/jeans_black_straight-fit_stretch-denim_02_back.png",
  "secondaryViewType": "back"
}
```

### 39. `jeans_mid-blue_slim-fit_12oz-denim_03.png` &nbsp;·&nbsp; **primary**

Mid-Blue slim-fit 12oz denim jeans, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 39. `jeans_mid-blue_slim-fit_12oz-denim_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Mid Blue slim-fit 12oz denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Mid Blue Denim Jeans",
  "color": "mid blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "12oz denim"
  },
  "primaryImageUrl": "/static/img/jeans_mid-blue_slim-fit_12oz-denim_03.png",
  "secondaryImageUrl": "/static/img/jeans_mid-blue_slim-fit_12oz-denim_03_back.png",
  "secondaryViewType": "back"
}
```

### 40. `jeans_light-wash-blue_relaxed-fit_lightweight-denim_04.png` &nbsp;·&nbsp; **primary**

Light Wash Blue relaxed-fit lightweight denim jeans, light wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 40. `jeans_light-wash-blue_relaxed-fit_lightweight-denim_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Light Wash Blue relaxed-fit lightweight denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Light Wash Blue Denim Jeans",
  "color": "light wash blue",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "lightweight denim"
  },
  "primaryImageUrl": "/static/img/jeans_light-wash-blue_relaxed-fit_lightweight-denim_04.png",
  "secondaryImageUrl": "/static/img/jeans_light-wash-blue_relaxed-fit_lightweight-denim_04_back.png",
  "secondaryViewType": "back"
}
```

### 41. `jeans_charcoal_tapered_stretch-denim_05.png` &nbsp;·&nbsp; **primary**

Charcoal tapered stretch denim jeans, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 41. `jeans_charcoal_tapered_stretch-denim_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal tapered stretch denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Charcoal Denim Jeans",
  "color": "charcoal",
  "attributes": {
    "fit": "tapered",
    "fabric": "stretch denim"
  },
  "primaryImageUrl": "/static/img/jeans_charcoal_tapered_stretch-denim_05.png",
  "secondaryImageUrl": "/static/img/jeans_charcoal_tapered_stretch-denim_05_back.png",
  "secondaryViewType": "back"
}
```

### 42. `jeans_raw-indigo_slim-fit_12oz-denim_10.png` &nbsp;·&nbsp; **primary**

Raw Indigo slim-fit 12oz denim jeans, raw wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 42. `jeans_raw-indigo_slim-fit_12oz-denim_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Raw Indigo slim-fit 12oz denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Raw Indigo Denim Jeans",
  "color": "raw indigo",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "12oz denim"
  },
  "primaryImageUrl": "/static/img/jeans_raw-indigo_slim-fit_12oz-denim_10.png",
  "secondaryImageUrl": "/static/img/jeans_raw-indigo_slim-fit_12oz-denim_10_back.png",
  "secondaryViewType": "back"
}
```

### 43. `jeans_vintage-blue_straight-fit_12oz-denim_11.png` &nbsp;·&nbsp; **primary**

Vintage Blue straight-fit 12oz denim jeans, vintage wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 43. `jeans_vintage-blue_straight-fit_12oz-denim_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Vintage Blue straight-fit 12oz denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Vintage Blue Denim Jeans",
  "color": "vintage blue",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "12oz denim"
  },
  "primaryImageUrl": "/static/img/jeans_vintage-blue_straight-fit_12oz-denim_11.png",
  "secondaryImageUrl": "/static/img/jeans_vintage-blue_straight-fit_12oz-denim_11_back.png",
  "secondaryViewType": "back"
}
```

### 44. `jeans_gray_tapered_stretch-denim_12.png` &nbsp;·&nbsp; **primary**

Gray tapered stretch denim jeans, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 44. `jeans_gray_tapered_stretch-denim_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Gray tapered stretch denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Gray Denim Jeans",
  "color": "gray",
  "attributes": {
    "fit": "tapered",
    "fabric": "stretch denim"
  },
  "primaryImageUrl": "/static/img/jeans_gray_tapered_stretch-denim_12.png",
  "secondaryImageUrl": "/static/img/jeans_gray_tapered_stretch-denim_12_back.png",
  "secondaryViewType": "back"
}
```

### 45. `jeans_deep-blue_slim-fit_stretch-denim_14.png` &nbsp;·&nbsp; **primary**

Deep Blue slim-fit stretch denim jeans, indigo wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 45. `jeans_deep-blue_slim-fit_stretch-denim_14_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Deep Blue slim-fit stretch denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Deep Blue Denim Jeans",
  "color": "deep blue",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "stretch denim"
  },
  "primaryImageUrl": "/static/img/jeans_deep-blue_slim-fit_stretch-denim_14.png",
  "secondaryImageUrl": "/static/img/jeans_deep-blue_slim-fit_stretch-denim_14_back.png",
  "secondaryViewType": "back"
}
```

### 46. `jeans_black_wide-leg_12oz-denim_15.png` &nbsp;·&nbsp; **primary**

Black wide-leg 12oz denim jeans, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 46. `jeans_black_wide-leg_12oz-denim_15_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black wide-leg 12oz denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Black Denim Jeans",
  "color": "black",
  "attributes": {
    "fit": "wide-leg",
    "fabric": "12oz denim"
  },
  "primaryImageUrl": "/static/img/jeans_black_wide-leg_12oz-denim_15.png",
  "secondaryImageUrl": "/static/img/jeans_black_wide-leg_12oz-denim_15_back.png",
  "secondaryViewType": "back"
}
```

### 47. `jeans_bleached-blue_relaxed-fit_lightweight-denim_18.png` &nbsp;·&nbsp; **primary**

Bleached Blue relaxed-fit lightweight denim jeans, light wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 47. `jeans_bleached-blue_relaxed-fit_lightweight-denim_18_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Bleached Blue relaxed-fit lightweight denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Bleached Blue Denim Jeans",
  "color": "bleached blue",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "lightweight denim"
  },
  "primaryImageUrl": "/static/img/jeans_bleached-blue_relaxed-fit_lightweight-denim_18.png",
  "secondaryImageUrl": "/static/img/jeans_bleached-blue_relaxed-fit_lightweight-denim_18_back.png",
  "secondaryViewType": "back"
}
```

### 48. `jeans_slate_tapered_stretch-denim_19.png` &nbsp;·&nbsp; **primary**

Slate tapered stretch denim jeans, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 48. `jeans_slate_tapered_stretch-denim_19_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Slate tapered stretch denim jeans, displayed flat-lay top-down with back side facing up, two back pockets and waistband loops visible, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jeans",
  "subcategory": "denim",
  "displayName": "Slate Denim Jeans",
  "color": "slate",
  "attributes": {
    "fit": "tapered",
    "fabric": "stretch denim"
  },
  "primaryImageUrl": "/static/img/jeans_slate_tapered_stretch-denim_19.png",
  "secondaryImageUrl": "/static/img/jeans_slate_tapered_stretch-denim_19_back.png",
  "secondaryViewType": "back"
}
```

## Pants & Trousers — `pants`

**API category slug:** `pants`  ·  **Products:** 10  ·  **Images:** 20 (primary + secondary)

### 49. `jeans_khaki_straight-fit_chino-cotton_06.png` &nbsp;·&nbsp; **primary**

Khaki straight-fit chino cotton chinos, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 49. `jeans_khaki_straight-fit_chino-cotton_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Khaki straight-fit chino cotton chinos, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "chinos",
  "displayName": "Khaki Chinos Pants",
  "color": "khaki",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "chino cotton"
  },
  "primaryImageUrl": "/static/img/jeans_khaki_straight-fit_chino-cotton_06.png",
  "secondaryImageUrl": "/static/img/jeans_khaki_straight-fit_chino-cotton_06_back.png",
  "secondaryViewType": "back"
}
```

### 50. `jeans_olive_slim-fit_twill-cotton_07.png` &nbsp;·&nbsp; **primary**

Olive slim-fit twill cotton trousers, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 50. `jeans_olive_slim-fit_twill-cotton_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive slim-fit twill cotton trousers, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "trousers",
  "displayName": "Olive Trousers Pants",
  "color": "olive",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "twill cotton"
  },
  "primaryImageUrl": "/static/img/jeans_olive_slim-fit_twill-cotton_07.png",
  "secondaryImageUrl": "/static/img/jeans_olive_slim-fit_twill-cotton_07_back.png",
  "secondaryViewType": "back"
}
```

### 51. `jeans_navy_straight-fit_chino-cotton_08.png` &nbsp;·&nbsp; **primary**

Navy straight-fit chino cotton chinos, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 51. `jeans_navy_straight-fit_chino-cotton_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy straight-fit chino cotton chinos, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "chinos",
  "displayName": "Navy Chinos Pants",
  "color": "navy",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "chino cotton"
  },
  "primaryImageUrl": "/static/img/jeans_navy_straight-fit_chino-cotton_08.png",
  "secondaryImageUrl": "/static/img/jeans_navy_straight-fit_chino-cotton_08_back.png",
  "secondaryViewType": "back"
}
```

### 52. `jeans_stone_relaxed-fit_twill-cotton_09.png` &nbsp;·&nbsp; **primary**

Stone relaxed-fit twill cotton trousers, light wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 52. `jeans_stone_relaxed-fit_twill-cotton_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Stone relaxed-fit twill cotton trousers, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "trousers",
  "displayName": "Stone Trousers Pants",
  "color": "stone",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "twill cotton"
  },
  "primaryImageUrl": "/static/img/jeans_stone_relaxed-fit_twill-cotton_09.png",
  "secondaryImageUrl": "/static/img/jeans_stone_relaxed-fit_twill-cotton_09_back.png",
  "secondaryViewType": "back"
}
```

### 53. `jeans_sand_relaxed-fit_chino-cotton_13.png` &nbsp;·&nbsp; **primary**

Sand relaxed-fit chino cotton chinos, light wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 53. `jeans_sand_relaxed-fit_chino-cotton_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sand relaxed-fit chino cotton chinos, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "chinos",
  "displayName": "Sand Chinos Pants",
  "color": "sand",
  "attributes": {
    "fit": "relaxed-fit",
    "fabric": "chino cotton"
  },
  "primaryImageUrl": "/static/img/jeans_sand_relaxed-fit_chino-cotton_13.png",
  "secondaryImageUrl": "/static/img/jeans_sand_relaxed-fit_chino-cotton_13_back.png",
  "secondaryViewType": "back"
}
```

### 54. `jeans_camel_straight-fit_twill-cotton_16.png` &nbsp;·&nbsp; **primary**

Camel straight-fit twill cotton trousers, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 54. `jeans_camel_straight-fit_twill-cotton_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Camel straight-fit twill cotton trousers, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "trousers",
  "displayName": "Camel Trousers Pants",
  "color": "camel",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "twill cotton"
  },
  "primaryImageUrl": "/static/img/jeans_camel_straight-fit_twill-cotton_16.png",
  "secondaryImageUrl": "/static/img/jeans_camel_straight-fit_twill-cotton_16_back.png",
  "secondaryViewType": "back"
}
```

### 55. `jeans_forest-green_slim-fit_chino-cotton_17.png` &nbsp;·&nbsp; **primary**

Forest Green slim-fit chino cotton chinos, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 55. `jeans_forest-green_slim-fit_chino-cotton_17_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green slim-fit chino cotton chinos, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "chinos",
  "displayName": "Forest Green Chinos Pants",
  "color": "forest green",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "chino cotton"
  },
  "primaryImageUrl": "/static/img/jeans_forest-green_slim-fit_chino-cotton_17.png",
  "secondaryImageUrl": "/static/img/jeans_forest-green_slim-fit_chino-cotton_17_back.png",
  "secondaryViewType": "back"
}
```

### 56. `jeans_burgundy_straight-fit_twill-cotton_20.png` &nbsp;·&nbsp; **primary**

Burgundy straight-fit twill cotton trousers, dark wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 56. `jeans_burgundy_straight-fit_twill-cotton_20_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Burgundy straight-fit twill cotton trousers, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "trousers",
  "displayName": "Burgundy Trousers Pants",
  "color": "burgundy",
  "attributes": {
    "fit": "straight-fit",
    "fabric": "twill cotton"
  },
  "primaryImageUrl": "/static/img/jeans_burgundy_straight-fit_twill-cotton_20.png",
  "secondaryImageUrl": "/static/img/jeans_burgundy_straight-fit_twill-cotton_20_back.png",
  "secondaryViewType": "back"
}
```

### 57. `jeans_white_slim-fit_chino-cotton_21.png` &nbsp;·&nbsp; **primary**

White slim-fit chino cotton chinos, light wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 57. `jeans_white_slim-fit_chino-cotton_21_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of White slim-fit chino cotton chinos, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "chinos",
  "displayName": "White Chinos Pants",
  "color": "white",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "chino cotton"
  },
  "primaryImageUrl": "/static/img/jeans_white_slim-fit_chino-cotton_21.png",
  "secondaryImageUrl": "/static/img/jeans_white_slim-fit_chino-cotton_21_back.png",
  "secondaryViewType": "back"
}
```

### 58. `jeans_tan_slim-fit_twill-cotton_24.png` &nbsp;·&nbsp; **primary**

Tan slim-fit twill cotton trousers, mid wash, displayed flat-lay on the backdrop, legs straightened with subtle natural drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 58. `jeans_tan_slim-fit_twill-cotton_24_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Tan slim-fit twill cotton trousers, displayed flat-lay top-down with back side facing up, back yoke and welt pockets visible, legs straightened. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "pants",
  "subcategory": "trousers",
  "displayName": "Tan Trousers Pants",
  "color": "tan",
  "attributes": {
    "fit": "slim-fit",
    "fabric": "twill cotton"
  },
  "primaryImageUrl": "/static/img/jeans_tan_slim-fit_twill-cotton_24.png",
  "secondaryImageUrl": "/static/img/jeans_tan_slim-fit_twill-cotton_24_back.png",
  "secondaryViewType": "back"
}
```

## Jackets & Blazers — `jackets`

**API category slug:** `jackets`  ·  **Products:** 16  ·  **Images:** 32 (primary + secondary)

### 59. `jacket_navy_tailored_travel-blazer_01.png` &nbsp;·&nbsp; **primary**

Navy tailored travel blazer in wool-poly blend, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 59. `jacket_navy_tailored_travel-blazer_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy tailored travel blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "travel blazer",
  "displayName": "Navy Travel Blazer Jackets",
  "color": "navy",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_navy_tailored_travel-blazer_01.png",
  "secondaryImageUrl": "/static/img/jacket_navy_tailored_travel-blazer_01_back.png",
  "secondaryViewType": "back"
}
```

### 60. `jacket_charcoal_relaxed_lightweight-bomber_02.png` &nbsp;·&nbsp; **primary**

Charcoal relaxed lightweight bomber in technical nylon-cotton, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 60. `jacket_charcoal_relaxed_lightweight-bomber_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal relaxed lightweight bomber, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "lightweight bomber",
  "displayName": "Charcoal Lightweight Bomber Jackets",
  "color": "charcoal",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_charcoal_relaxed_lightweight-bomber_02.png",
  "secondaryImageUrl": "/static/img/jacket_charcoal_relaxed_lightweight-bomber_02_back.png",
  "secondaryViewType": "back"
}
```

### 61. `jacket_camel_tailored_soft-shoulder-blazer_03.png` &nbsp;·&nbsp; **primary**

Camel tailored soft-shoulder blazer in merino wool, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 61. `jacket_camel_tailored_soft-shoulder-blazer_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Camel tailored soft shoulder blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "soft shoulder blazer",
  "displayName": "Camel Soft Shoulder Blazer Jackets",
  "color": "camel",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_camel_tailored_soft-shoulder-blazer_03.png",
  "secondaryImageUrl": "/static/img/jacket_camel_tailored_soft-shoulder-blazer_03_back.png",
  "secondaryViewType": "back"
}
```

### 62. `jacket_olive_relaxed_packable-jacket_04.png` &nbsp;·&nbsp; **primary**

Olive relaxed packable jacket in recycled polyester, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 62. `jacket_olive_relaxed_packable-jacket_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive relaxed packable jacket, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "packable jacket",
  "displayName": "Olive Packable Jacket Jackets",
  "color": "olive",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_olive_relaxed_packable-jacket_04.png",
  "secondaryImageUrl": "/static/img/jacket_olive_relaxed_packable-jacket_04_back.png",
  "secondaryViewType": "back"
}
```

### 63. `jacket_slate-gray_tailored_travel-blazer_05.png` &nbsp;·&nbsp; **primary**

Slate Gray tailored travel blazer in wool-poly blend, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 63. `jacket_slate-gray_tailored_travel-blazer_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Slate Gray tailored travel blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "travel blazer",
  "displayName": "Slate Gray Travel Blazer Jackets",
  "color": "slate gray",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_slate-gray_tailored_travel-blazer_05.png",
  "secondaryImageUrl": "/static/img/jacket_slate-gray_tailored_travel-blazer_05_back.png",
  "secondaryViewType": "back"
}
```

### 64. `jacket_deep-burgundy_tailored_soft-shoulder-blazer_06.png` &nbsp;·&nbsp; **primary**

Deep Burgundy tailored soft-shoulder blazer in merino wool, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 64. `jacket_deep-burgundy_tailored_soft-shoulder-blazer_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Deep Burgundy tailored soft shoulder blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "soft shoulder blazer",
  "displayName": "Deep Burgundy Soft Shoulder Blazer Jackets",
  "color": "deep burgundy",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_deep-burgundy_tailored_soft-shoulder-blazer_06.png",
  "secondaryImageUrl": "/static/img/jacket_deep-burgundy_tailored_soft-shoulder-blazer_06_back.png",
  "secondaryViewType": "back"
}
```

### 65. `jacket_black_relaxed_lightweight-bomber_07.png` &nbsp;·&nbsp; **primary**

Black relaxed lightweight bomber in technical nylon-cotton, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 65. `jacket_black_relaxed_lightweight-bomber_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black relaxed lightweight bomber, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "lightweight bomber",
  "displayName": "Black Lightweight Bomber Jackets",
  "color": "black",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_black_relaxed_lightweight-bomber_07.png",
  "secondaryImageUrl": "/static/img/jacket_black_relaxed_lightweight-bomber_07_back.png",
  "secondaryViewType": "back"
}
```

### 66. `jacket_sand_relaxed_packable-jacket_08.png` &nbsp;·&nbsp; **primary**

Sand relaxed packable jacket in recycled polyester, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 66. `jacket_sand_relaxed_packable-jacket_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sand relaxed packable jacket, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "packable jacket",
  "displayName": "Sand Packable Jacket Jackets",
  "color": "sand",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_sand_relaxed_packable-jacket_08.png",
  "secondaryImageUrl": "/static/img/jacket_sand_relaxed_packable-jacket_08_back.png",
  "secondaryViewType": "back"
}
```

### 67. `jacket_midnight-blue_tailored_travel-blazer_09.png` &nbsp;·&nbsp; **primary**

Midnight Blue tailored travel blazer in wool-poly blend, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 67. `jacket_midnight-blue_tailored_travel-blazer_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Midnight Blue tailored travel blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "travel blazer",
  "displayName": "Midnight Blue Travel Blazer Jackets",
  "color": "midnight blue",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_midnight-blue_tailored_travel-blazer_09.png",
  "secondaryImageUrl": "/static/img/jacket_midnight-blue_tailored_travel-blazer_09_back.png",
  "secondaryViewType": "back"
}
```

### 68. `jacket_forest-green_relaxed_packable-jacket_10.png` &nbsp;·&nbsp; **primary**

Forest Green relaxed packable jacket in recycled polyester, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 68. `jacket_forest-green_relaxed_packable-jacket_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green relaxed packable jacket, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "packable jacket",
  "displayName": "Forest Green Packable Jacket Jackets",
  "color": "forest green",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_forest-green_relaxed_packable-jacket_10.png",
  "secondaryImageUrl": "/static/img/jacket_forest-green_relaxed_packable-jacket_10_back.png",
  "secondaryViewType": "back"
}
```

### 69. `jacket_stone_tailored_soft-shoulder-blazer_11.png` &nbsp;·&nbsp; **primary**

Stone tailored soft-shoulder blazer in merino wool, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 69. `jacket_stone_tailored_soft-shoulder-blazer_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Stone tailored soft shoulder blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "soft shoulder blazer",
  "displayName": "Stone Soft Shoulder Blazer Jackets",
  "color": "stone",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_stone_tailored_soft-shoulder-blazer_11.png",
  "secondaryImageUrl": "/static/img/jacket_stone_tailored_soft-shoulder-blazer_11_back.png",
  "secondaryViewType": "back"
}
```

### 70. `jacket_teal_relaxed_lightweight-bomber_12.png` &nbsp;·&nbsp; **primary**

Teal relaxed lightweight bomber in technical nylon-cotton, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 70. `jacket_teal_relaxed_lightweight-bomber_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Teal relaxed lightweight bomber, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "lightweight bomber",
  "displayName": "Teal Lightweight Bomber Jackets",
  "color": "teal",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_teal_relaxed_lightweight-bomber_12.png",
  "secondaryImageUrl": "/static/img/jacket_teal_relaxed_lightweight-bomber_12_back.png",
  "secondaryViewType": "back"
}
```

### 71. `jacket_graphite_tailored_travel-blazer_13.png` &nbsp;·&nbsp; **primary**

Graphite tailored travel blazer in wool-poly blend, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 71. `jacket_graphite_tailored_travel-blazer_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Graphite tailored travel blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "travel blazer",
  "displayName": "Graphite Travel Blazer Jackets",
  "color": "graphite",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_graphite_tailored_travel-blazer_13.png",
  "secondaryImageUrl": "/static/img/jacket_graphite_tailored_travel-blazer_13_back.png",
  "secondaryViewType": "back"
}
```

### 72. `jacket_tan_relaxed_packable-jacket_14.png` &nbsp;·&nbsp; **primary**

Tan relaxed packable jacket in recycled polyester, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 72. `jacket_tan_relaxed_packable-jacket_14_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Tan relaxed packable jacket, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "packable jacket",
  "displayName": "Tan Packable Jacket Jackets",
  "color": "tan",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_tan_relaxed_packable-jacket_14.png",
  "secondaryImageUrl": "/static/img/jacket_tan_relaxed_packable-jacket_14_back.png",
  "secondaryViewType": "back"
}
```

### 73. `jacket_wine_tailored_soft-shoulder-blazer_15.png` &nbsp;·&nbsp; **primary**

Wine tailored soft-shoulder blazer in merino wool, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 73. `jacket_wine_tailored_soft-shoulder-blazer_15_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Wine tailored soft shoulder blazer, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "soft shoulder blazer",
  "displayName": "Wine Soft Shoulder Blazer Jackets",
  "color": "wine",
  "attributes": {
    "fit": "tailored"
  },
  "primaryImageUrl": "/static/img/jacket_wine_tailored_soft-shoulder-blazer_15.png",
  "secondaryImageUrl": "/static/img/jacket_wine_tailored_soft-shoulder-blazer_15_back.png",
  "secondaryViewType": "back"
}
```

### 74. `jacket_steel-blue_relaxed_lightweight-bomber_16.png` &nbsp;·&nbsp; **primary**

Steel Blue relaxed lightweight bomber in technical nylon-cotton, hung on a clean wooden hanger against the backdrop, three-quarter angle, lapels visible, stitching detail clearly rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 74. `jacket_steel-blue_relaxed_lightweight-bomber_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Steel Blue relaxed lightweight bomber, hung on a wooden hanger against the backdrop, photographed from directly behind, center back seam and yoke visible, sleeves resting straight. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "jackets",
  "subcategory": "lightweight bomber",
  "displayName": "Steel Blue Lightweight Bomber Jackets",
  "color": "steel blue",
  "attributes": {
    "fit": "relaxed"
  },
  "primaryImageUrl": "/static/img/jacket_steel-blue_relaxed_lightweight-bomber_16.png",
  "secondaryImageUrl": "/static/img/jacket_steel-blue_relaxed_lightweight-bomber_16_back.png",
  "secondaryViewType": "back"
}
```

## Dresses — `dresses`

**API category slug:** `dresses`  ·  **Products:** 18  ·  **Images:** 36 (primary + secondary)

### 75. `dress_black_a-line_midi_01.png` &nbsp;·&nbsp; **primary**

Black A-line midi jersey dress with V-neck and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 75. `dress_black_a-line_midi_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Black a-line midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "a-line",
  "displayName": "Black A Line Dresses",
  "color": "black",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_black_a-line_midi_01.png",
  "secondaryImageUrl": "/static/img/dress_black_a-line_midi_01_back.png",
  "secondaryViewType": "back"
}
```

### 76. `dress_navy_sheath_knee-length_02.png` &nbsp;·&nbsp; **primary**

Navy sheath knee-length jersey dress with crew neck and three-quarter sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 76. `dress_navy_sheath_knee-length_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy sheath knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "sheath",
  "displayName": "Navy Sheath Dresses",
  "color": "navy",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_navy_sheath_knee-length_02.png",
  "secondaryImageUrl": "/static/img/dress_navy_sheath_knee-length_02_back.png",
  "secondaryViewType": "back"
}
```

### 77. `dress_sage_wrap_midi_03.png` &nbsp;·&nbsp; **primary**

Sage wrap midi jersey dress with wrap neckline and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 77. `dress_sage_wrap_midi_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sage wrap midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "wrap",
  "displayName": "Sage Wrap Dresses",
  "color": "sage",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_sage_wrap_midi_03.png",
  "secondaryImageUrl": "/static/img/dress_sage_wrap_midi_03_back.png",
  "secondaryViewType": "back"
}
```

### 78. `dress_dusty-rose_shift_knee-length_04.png` &nbsp;·&nbsp; **primary**

Dusty Rose shift knee-length jersey dress with square neck and sleeveless, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 78. `dress_dusty-rose_shift_knee-length_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Dusty Rose shift knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "shift",
  "displayName": "Dusty Rose Shift Dresses",
  "color": "dusty rose",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_dusty-rose_shift_knee-length_04.png",
  "secondaryImageUrl": "/static/img/dress_dusty-rose_shift_knee-length_04_back.png",
  "secondaryViewType": "back"
}
```

### 79. `dress_terracotta_tiered_maxi_05.png` &nbsp;·&nbsp; **primary**

Terracotta tiered maxi jersey dress with V-neck and long sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 79. `dress_terracotta_tiered_maxi_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Terracotta tiered maxi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "tiered",
  "displayName": "Terracotta Tiered Dresses",
  "color": "terracotta",
  "attributes": {
    "length": "maxi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_terracotta_tiered_maxi_05.png",
  "secondaryImageUrl": "/static/img/dress_terracotta_tiered_maxi_05_back.png",
  "secondaryViewType": "back"
}
```

### 80. `dress_ivory_a-line_knee-length_06.png` &nbsp;·&nbsp; **primary**

Ivory A-line knee-length jersey dress with crew neck and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 80. `dress_ivory_a-line_knee-length_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Ivory a-line knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "a-line",
  "displayName": "Ivory A Line Dresses",
  "color": "ivory",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_ivory_a-line_knee-length_06.png",
  "secondaryImageUrl": "/static/img/dress_ivory_a-line_knee-length_06_back.png",
  "secondaryViewType": "back"
}
```

### 81. `dress_deep-teal_sheath_midi_07.png` &nbsp;·&nbsp; **primary**

Deep Teal sheath midi jersey dress with square neck and sleeveless, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 81. `dress_deep-teal_sheath_midi_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Deep Teal sheath midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "sheath",
  "displayName": "Deep Teal Sheath Dresses",
  "color": "deep teal",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_deep-teal_sheath_midi_07.png",
  "secondaryImageUrl": "/static/img/dress_deep-teal_sheath_midi_07_back.png",
  "secondaryViewType": "back"
}
```

### 82. `dress_burgundy_wrap_knee-length_08.png` &nbsp;·&nbsp; **primary**

Burgundy wrap knee-length jersey dress with wrap neckline and three-quarter sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 82. `dress_burgundy_wrap_knee-length_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Burgundy wrap knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "wrap",
  "displayName": "Burgundy Wrap Dresses",
  "color": "burgundy",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_burgundy_wrap_knee-length_08.png",
  "secondaryImageUrl": "/static/img/dress_burgundy_wrap_knee-length_08_back.png",
  "secondaryViewType": "back"
}
```

### 83. `dress_charcoal_shift_midi_09.png` &nbsp;·&nbsp; **primary**

Charcoal shift midi jersey dress with V-neck and long sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 83. `dress_charcoal_shift_midi_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal shift midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "shift",
  "displayName": "Charcoal Shift Dresses",
  "color": "charcoal",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_charcoal_shift_midi_09.png",
  "secondaryImageUrl": "/static/img/dress_charcoal_shift_midi_09_back.png",
  "secondaryViewType": "back"
}
```

### 84. `dress_coral_a-line_maxi_10.png` &nbsp;·&nbsp; **primary**

Coral A-line maxi jersey dress with crew neck and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 84. `dress_coral_a-line_maxi_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Coral a-line maxi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "a-line",
  "displayName": "Coral A Line Dresses",
  "color": "coral",
  "attributes": {
    "length": "maxi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_coral_a-line_maxi_10.png",
  "secondaryImageUrl": "/static/img/dress_coral_a-line_maxi_10_back.png",
  "secondaryViewType": "back"
}
```

### 85. `dress_plum_sheath_knee-length_11.png` &nbsp;·&nbsp; **primary**

Plum sheath knee-length jersey dress with square neck and three-quarter sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 85. `dress_plum_sheath_knee-length_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Plum sheath knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "sheath",
  "displayName": "Plum Sheath Dresses",
  "color": "plum",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_plum_sheath_knee-length_11.png",
  "secondaryImageUrl": "/static/img/dress_plum_sheath_knee-length_11_back.png",
  "secondaryViewType": "back"
}
```

### 86. `dress_olive_wrap_midi_12.png` &nbsp;·&nbsp; **primary**

Olive wrap midi jersey dress with wrap neckline and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 86. `dress_olive_wrap_midi_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive wrap midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "wrap",
  "displayName": "Olive Wrap Dresses",
  "color": "olive",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_olive_wrap_midi_12.png",
  "secondaryImageUrl": "/static/img/dress_olive_wrap_midi_12_back.png",
  "secondaryViewType": "back"
}
```

### 87. `dress_midnight-blue_tiered_maxi_13.png` &nbsp;·&nbsp; **primary**

Midnight Blue tiered maxi jersey dress with V-neck and long sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 87. `dress_midnight-blue_tiered_maxi_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Midnight Blue tiered maxi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "tiered",
  "displayName": "Midnight Blue Tiered Dresses",
  "color": "midnight blue",
  "attributes": {
    "length": "maxi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_midnight-blue_tiered_maxi_13.png",
  "secondaryImageUrl": "/static/img/dress_midnight-blue_tiered_maxi_13_back.png",
  "secondaryViewType": "back"
}
```

### 88. `dress_blush-pink_a-line_knee-length_14.png` &nbsp;·&nbsp; **primary**

Blush Pink A-line knee-length jersey dress with crew neck and sleeveless, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 88. `dress_blush-pink_a-line_knee-length_14_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Blush Pink a-line knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "a-line",
  "displayName": "Blush Pink A Line Dresses",
  "color": "blush pink",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_blush-pink_a-line_knee-length_14.png",
  "secondaryImageUrl": "/static/img/dress_blush-pink_a-line_knee-length_14_back.png",
  "secondaryViewType": "back"
}
```

### 89. `dress_forest-green_sheath_midi_15.png` &nbsp;·&nbsp; **primary**

Forest Green sheath midi jersey dress with square neck and short sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 89. `dress_forest-green_sheath_midi_15_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green sheath midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "sheath",
  "displayName": "Forest Green Sheath Dresses",
  "color": "forest green",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_forest-green_sheath_midi_15.png",
  "secondaryImageUrl": "/static/img/dress_forest-green_sheath_midi_15_back.png",
  "secondaryViewType": "back"
}
```

### 90. `dress_mustard_shift_knee-length_16.png` &nbsp;·&nbsp; **primary**

Mustard shift knee-length jersey dress with V-neck and three-quarter sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 90. `dress_mustard_shift_knee-length_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Mustard shift knee length dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "shift",
  "displayName": "Mustard Shift Dresses",
  "color": "mustard",
  "attributes": {
    "length": "knee length",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_mustard_shift_knee-length_16.png",
  "secondaryImageUrl": "/static/img/dress_mustard_shift_knee-length_16_back.png",
  "secondaryViewType": "back"
}
```

### 91. `dress_lavender_wrap_midi_17.png` &nbsp;·&nbsp; **primary**

Lavender wrap midi jersey dress with wrap neckline and long sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 91. `dress_lavender_wrap_midi_17_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Lavender wrap midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "wrap",
  "displayName": "Lavender Wrap Dresses",
  "color": "lavender",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_lavender_wrap_midi_17.png",
  "secondaryImageUrl": "/static/img/dress_lavender_wrap_midi_17_back.png",
  "secondaryViewType": "back"
}
```

### 92. `dress_cream_tiered_midi_20.png` &nbsp;·&nbsp; **primary**

Cream tiered midi jersey dress with V-neck and three-quarter sleeves, displayed on a minimal wooden hanger against the backdrop, fabric falling naturally with slight movement. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 92. `dress_cream_tiered_midi_20_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Cream tiered midi dress, displayed flat-lay top-down with back side facing up, back zip placket or open-back detail visible along the spine, hem fanned softly. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "dresses",
  "subcategory": "tiered",
  "displayName": "Cream Tiered Dresses",
  "color": "cream",
  "attributes": {
    "length": "midi",
    "fabric": "jersey"
  },
  "primaryImageUrl": "/static/img/dress_cream_tiered_midi_20.png",
  "secondaryImageUrl": "/static/img/dress_cream_tiered_midi_20_back.png",
  "secondaryViewType": "back"
}
```

## Sweaters & Cardigans — `sweaters`

**API category slug:** `sweaters`  ·  **Products:** 14  ·  **Images:** 28 (primary + secondary)

### 93. `winter_charcoal_crew-neck-sweater_merino-wool_01.png` &nbsp;·&nbsp; **primary**

Charcoal midweight crew-neck sweater in merino wool, ribbed cuffs, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 93. `winter_charcoal_crew-neck-sweater_merino-wool_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal crew neck sweater in merino wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "crew-neck-sweater",
  "displayName": "Charcoal Crew Neck Sweater Sweaters",
  "color": "charcoal",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_charcoal_crew-neck-sweater_merino-wool_01.png",
  "secondaryImageUrl": "/static/img/winter_charcoal_crew-neck-sweater_merino-wool_01_back.png",
  "secondaryViewType": "back"
}
```

### 94. `winter_oatmeal_half-zip-pullover_lambswool_02.png` &nbsp;·&nbsp; **primary**

Oatmeal chunky half-zip pullover in lambswool, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 94. `winter_oatmeal_half-zip-pullover_lambswool_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Oatmeal half zip pullover in lambswool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "half-zip-pullover",
  "displayName": "Oatmeal Half Zip Pullover Sweaters",
  "color": "oatmeal",
  "attributes": {
    "fabric": "lambswool"
  },
  "primaryImageUrl": "/static/img/winter_oatmeal_half-zip-pullover_lambswool_02.png",
  "secondaryImageUrl": "/static/img/winter_oatmeal_half-zip-pullover_lambswool_02_back.png",
  "secondaryViewType": "back"
}
```

### 95. `winter_forest-green_cardigan_cashmere-blend_03.png` &nbsp;·&nbsp; **primary**

Forest Green lightweight cardigan in cashmere blend, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 95. `winter_forest-green_cardigan_cashmere-blend_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green cardigan in cashmere blend, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "cardigan",
  "displayName": "Forest Green Cardigan Sweaters",
  "color": "forest green",
  "attributes": {
    "fabric": "cashmere blend"
  },
  "primaryImageUrl": "/static/img/winter_forest-green_cardigan_cashmere-blend_03.png",
  "secondaryImageUrl": "/static/img/winter_forest-green_cardigan_cashmere-blend_03_back.png",
  "secondaryViewType": "back"
}
```

### 96. `winter_burgundy_crew-neck-sweater_merino-wool_06.png` &nbsp;·&nbsp; **primary**

Burgundy midweight crew-neck sweater in merino wool, raglan sleeve, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 96. `winter_burgundy_crew-neck-sweater_merino-wool_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Burgundy crew neck sweater in merino wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "crew-neck-sweater",
  "displayName": "Burgundy Crew Neck Sweater Sweaters",
  "color": "burgundy",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_burgundy_crew-neck-sweater_merino-wool_06.png",
  "secondaryImageUrl": "/static/img/winter_burgundy_crew-neck-sweater_merino-wool_06_back.png",
  "secondaryViewType": "back"
}
```

### 97. `winter_slate_half-zip-pullover_lambswool_07.png` &nbsp;·&nbsp; **primary**

Slate lightweight half-zip pullover in lambswool, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 97. `winter_slate_half-zip-pullover_lambswool_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Slate half zip pullover in lambswool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "half-zip-pullover",
  "displayName": "Slate Half Zip Pullover Sweaters",
  "color": "slate",
  "attributes": {
    "fabric": "lambswool"
  },
  "primaryImageUrl": "/static/img/winter_slate_half-zip-pullover_lambswool_07.png",
  "secondaryImageUrl": "/static/img/winter_slate_half-zip-pullover_lambswool_07_back.png",
  "secondaryViewType": "back"
}
```

### 98. `winter_cream_cardigan_cashmere-blend_08.png` &nbsp;·&nbsp; **primary**

Cream chunky cardigan in cashmere blend, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 98. `winter_cream_cardigan_cashmere-blend_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Cream cardigan in cashmere blend, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "cardigan",
  "displayName": "Cream Cardigan Sweaters",
  "color": "cream",
  "attributes": {
    "fabric": "cashmere blend"
  },
  "primaryImageUrl": "/static/img/winter_cream_cardigan_cashmere-blend_08.png",
  "secondaryImageUrl": "/static/img/winter_cream_cardigan_cashmere-blend_08_back.png",
  "secondaryViewType": "back"
}
```

### 99. `winter_rust_crew-neck-sweater_lambswool_11.png` &nbsp;·&nbsp; **primary**

Rust midweight crew-neck sweater in lambswool, raglan sleeve, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 99. `winter_rust_crew-neck-sweater_lambswool_11_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Rust crew neck sweater in lambswool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "crew-neck-sweater",
  "displayName": "Rust Crew Neck Sweater Sweaters",
  "color": "rust",
  "attributes": {
    "fabric": "lambswool"
  },
  "primaryImageUrl": "/static/img/winter_rust_crew-neck-sweater_lambswool_11.png",
  "secondaryImageUrl": "/static/img/winter_rust_crew-neck-sweater_lambswool_11_back.png",
  "secondaryViewType": "back"
}
```

### 100. `winter_graphite_half-zip-pullover_brushed-alpaca_12.png` &nbsp;·&nbsp; **primary**

Graphite chunky half-zip pullover in brushed alpaca, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 100. `winter_graphite_half-zip-pullover_brushed-alpaca_12_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Graphite half zip pullover in brushed alpaca, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "half-zip-pullover",
  "displayName": "Graphite Half Zip Pullover Sweaters",
  "color": "graphite",
  "attributes": {
    "fabric": "brushed alpaca"
  },
  "primaryImageUrl": "/static/img/winter_graphite_half-zip-pullover_brushed-alpaca_12.png",
  "secondaryImageUrl": "/static/img/winter_graphite_half-zip-pullover_brushed-alpaca_12_back.png",
  "secondaryViewType": "back"
}
```

### 101. `winter_ivory_cardigan_merino-wool_13.png` &nbsp;·&nbsp; **primary**

Ivory midweight cardigan in merino wool, ribbed cuffs, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 101. `winter_ivory_cardigan_merino-wool_13_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Ivory cardigan in merino wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "cardigan",
  "displayName": "Ivory Cardigan Sweaters",
  "color": "ivory",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_ivory_cardigan_merino-wool_13.png",
  "secondaryImageUrl": "/static/img/winter_ivory_cardigan_merino-wool_13_back.png",
  "secondaryViewType": "back"
}
```

### 102. `winter_steel-blue_crew-neck-sweater_merino-wool_16.png` &nbsp;·&nbsp; **primary**

Steel Blue midweight crew-neck sweater in merino wool, raglan sleeve, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 102. `winter_steel-blue_crew-neck-sweater_merino-wool_16_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Steel Blue crew neck sweater in merino wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "crew-neck-sweater",
  "displayName": "Steel Blue Crew Neck Sweater Sweaters",
  "color": "steel blue",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_steel-blue_crew-neck-sweater_merino-wool_16.png",
  "secondaryImageUrl": "/static/img/winter_steel-blue_crew-neck-sweater_merino-wool_16_back.png",
  "secondaryViewType": "back"
}
```

### 103. `winter_mustard_half-zip-pullover_lambswool_17.png` &nbsp;·&nbsp; **primary**

Mustard lightweight half-zip pullover in lambswool, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 103. `winter_mustard_half-zip-pullover_lambswool_17_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Mustard half zip pullover in lambswool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "half-zip-pullover",
  "displayName": "Mustard Half Zip Pullover Sweaters",
  "color": "mustard",
  "attributes": {
    "fabric": "lambswool"
  },
  "primaryImageUrl": "/static/img/winter_mustard_half-zip-pullover_lambswool_17.png",
  "secondaryImageUrl": "/static/img/winter_mustard_half-zip-pullover_lambswool_17_back.png",
  "secondaryViewType": "back"
}
```

### 104. `winter_plum_cardigan_brushed-alpaca_18.png` &nbsp;·&nbsp; **primary**

Plum chunky cardigan in brushed alpaca, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 104. `winter_plum_cardigan_brushed-alpaca_18_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Plum cardigan in brushed alpaca, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "cardigan",
  "displayName": "Plum Cardigan Sweaters",
  "color": "plum",
  "attributes": {
    "fabric": "brushed alpaca"
  },
  "primaryImageUrl": "/static/img/winter_plum_cardigan_brushed-alpaca_18.png",
  "secondaryImageUrl": "/static/img/winter_plum_cardigan_brushed-alpaca_18_back.png",
  "secondaryViewType": "back"
}
```

### 105. `winter_maroon_crew-neck-sweater_recycled-wool_21.png` &nbsp;·&nbsp; **primary**

Maroon midweight crew-neck sweater in recycled wool, raglan sleeve, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 105. `winter_maroon_crew-neck-sweater_recycled-wool_21_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Maroon crew neck sweater in recycled wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "crew-neck-sweater",
  "displayName": "Maroon Crew Neck Sweater Sweaters",
  "color": "maroon",
  "attributes": {
    "fabric": "recycled wool"
  },
  "primaryImageUrl": "/static/img/winter_maroon_crew-neck-sweater_recycled-wool_21.png",
  "secondaryImageUrl": "/static/img/winter_maroon_crew-neck-sweater_recycled-wool_21_back.png",
  "secondaryViewType": "back"
}
```

### 106. `winter_pebble-gray_half-zip-pullover_merino-wool_22.png` &nbsp;·&nbsp; **primary**

Pebble Gray chunky half-zip pullover in merino wool, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 106. `winter_pebble-gray_half-zip-pullover_merino-wool_22_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Pebble Gray half zip pullover in merino wool, displayed flat-lay top-down with back side facing up, knit pattern and ribbed hem visible, neatly folded with subtle drape. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sweaters",
  "subcategory": "half-zip-pullover",
  "displayName": "Pebble Gray Half Zip Pullover Sweaters",
  "color": "pebble gray",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_pebble-gray_half-zip-pullover_merino-wool_22.png",
  "secondaryImageUrl": "/static/img/winter_pebble-gray_half-zip-pullover_merino-wool_22_back.png",
  "secondaryViewType": "back"
}
```

## Raincoats — `raincoats`

**API category slug:** `raincoats`  ·  **Products:** 10  ·  **Images:** 20 (primary + secondary)

### 107. `raincoat_olive_mid-length_packable_01.png` &nbsp;·&nbsp; **primary**

Olive mid-length packable raincoat in recycled nylon shell, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 107. `raincoat_olive_mid-length_packable_01_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Olive mid length packable raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "packable",
  "displayName": "Olive Packable Raincoats",
  "color": "olive",
  "attributes": {
    "length": "mid length"
  },
  "primaryImageUrl": "/static/img/raincoat_olive_mid-length_packable_01.png",
  "secondaryImageUrl": "/static/img/raincoat_olive_mid-length_packable_01_back.png",
  "secondaryViewType": "back"
}
```

### 108. `raincoat_navy_hip-length_technical-shell_02.png` &nbsp;·&nbsp; **primary**

Navy hip-length technical shell raincoat in breathable membrane, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 108. `raincoat_navy_hip-length_technical-shell_02_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Navy hip length technical shell raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "technical shell",
  "displayName": "Navy Technical Shell Raincoats",
  "color": "navy",
  "attributes": {
    "length": "hip length"
  },
  "primaryImageUrl": "/static/img/raincoat_navy_hip-length_technical-shell_02.png",
  "secondaryImageUrl": "/static/img/raincoat_navy_hip-length_technical-shell_02_back.png",
  "secondaryViewType": "back"
}
```

### 109. `raincoat_translucent-black_longline_double-breasted-trench_03.png` &nbsp;·&nbsp; **primary**

Translucent Black longline double-breasted trench raincoat in waxed cotton, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 109. `raincoat_translucent-black_longline_double-breasted-trench_03_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Translucent Black longline double breasted trench raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "double breasted trench",
  "displayName": "Translucent Black Double Breasted Trench Raincoats",
  "color": "translucent black",
  "attributes": {
    "length": "longline"
  },
  "primaryImageUrl": "/static/img/raincoat_translucent-black_longline_double-breasted-trench_03.png",
  "secondaryImageUrl": "/static/img/raincoat_translucent-black_longline_double-breasted-trench_03_back.png",
  "secondaryViewType": "back"
}
```

### 110. `raincoat_sand_mid-length_packable_04.png` &nbsp;·&nbsp; **primary**

Sand mid-length packable raincoat in recycled nylon shell, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 110. `raincoat_sand_mid-length_packable_04_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Sand mid length packable raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "packable",
  "displayName": "Sand Packable Raincoats",
  "color": "sand",
  "attributes": {
    "length": "mid length"
  },
  "primaryImageUrl": "/static/img/raincoat_sand_mid-length_packable_04.png",
  "secondaryImageUrl": "/static/img/raincoat_sand_mid-length_packable_04_back.png",
  "secondaryViewType": "back"
}
```

### 111. `raincoat_slate-gray_hip-length_technical-shell_05.png` &nbsp;·&nbsp; **primary**

Slate Gray hip-length technical shell raincoat in breathable membrane, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 111. `raincoat_slate-gray_hip-length_technical-shell_05_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Slate Gray hip length technical shell raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "technical shell",
  "displayName": "Slate Gray Technical Shell Raincoats",
  "color": "slate gray",
  "attributes": {
    "length": "hip length"
  },
  "primaryImageUrl": "/static/img/raincoat_slate-gray_hip-length_technical-shell_05.png",
  "secondaryImageUrl": "/static/img/raincoat_slate-gray_hip-length_technical-shell_05_back.png",
  "secondaryViewType": "back"
}
```

### 112. `raincoat_butter-yellow_longline_packable_06.png` &nbsp;·&nbsp; **primary**

Butter Yellow longline packable raincoat in recycled nylon shell, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 112. `raincoat_butter-yellow_longline_packable_06_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Butter Yellow longline packable raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "packable",
  "displayName": "Butter Yellow Packable Raincoats",
  "color": "butter yellow",
  "attributes": {
    "length": "longline"
  },
  "primaryImageUrl": "/static/img/raincoat_butter-yellow_longline_packable_06.png",
  "secondaryImageUrl": "/static/img/raincoat_butter-yellow_longline_packable_06_back.png",
  "secondaryViewType": "back"
}
```

### 113. `raincoat_forest-green_mid-length_double-breasted-trench_07.png` &nbsp;·&nbsp; **primary**

Forest Green mid-length double-breasted trench raincoat in waxed cotton, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 113. `raincoat_forest-green_mid-length_double-breasted-trench_07_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Forest Green mid length double breasted trench raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "double breasted trench",
  "displayName": "Forest Green Double Breasted Trench Raincoats",
  "color": "forest green",
  "attributes": {
    "length": "mid length"
  },
  "primaryImageUrl": "/static/img/raincoat_forest-green_mid-length_double-breasted-trench_07.png",
  "secondaryImageUrl": "/static/img/raincoat_forest-green_mid-length_double-breasted-trench_07_back.png",
  "secondaryViewType": "back"
}
```

### 114. `raincoat_charcoal_hip-length_packable_08.png` &nbsp;·&nbsp; **primary**

Charcoal hip-length packable raincoat in recycled nylon shell, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 114. `raincoat_charcoal_hip-length_packable_08_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Charcoal hip length packable raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "packable",
  "displayName": "Charcoal Packable Raincoats",
  "color": "charcoal",
  "attributes": {
    "length": "hip length"
  },
  "primaryImageUrl": "/static/img/raincoat_charcoal_hip-length_packable_08.png",
  "secondaryImageUrl": "/static/img/raincoat_charcoal_hip-length_packable_08_back.png",
  "secondaryViewType": "back"
}
```

### 115. `raincoat_midnight-blue_longline_technical-shell_09.png` &nbsp;·&nbsp; **primary**

Midnight Blue longline technical shell raincoat in breathable membrane, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 115. `raincoat_midnight-blue_longline_technical-shell_09_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Midnight Blue longline technical shell raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "technical shell",
  "displayName": "Midnight Blue Technical Shell Raincoats",
  "color": "midnight blue",
  "attributes": {
    "length": "longline"
  },
  "primaryImageUrl": "/static/img/raincoat_midnight-blue_longline_technical-shell_09.png",
  "secondaryImageUrl": "/static/img/raincoat_midnight-blue_longline_technical-shell_09_back.png",
  "secondaryViewType": "back"
}
```

### 116. `raincoat_camel_mid-length_double-breasted-trench_10.png` &nbsp;·&nbsp; **primary**

Camel mid-length double-breasted trench raincoat in waxed cotton, hung on a wooden hanger against the backdrop, three-quarter angle, hood visible, water-repellent surface texture rendered. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 116. `raincoat_camel_mid-length_double-breasted-trench_10_back.png` &nbsp;·&nbsp; **secondary (back)**

Back view of Camel mid length double breasted trench raincoat, hung on a wooden hanger against the backdrop, photographed from behind, storm flap and center vent visible, water-repellent surface texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "raincoats",
  "subcategory": "double breasted trench",
  "displayName": "Camel Double Breasted Trench Raincoats",
  "color": "camel",
  "attributes": {
    "length": "mid length"
  },
  "primaryImageUrl": "/static/img/raincoat_camel_mid-length_double-breasted-trench_10.png",
  "secondaryImageUrl": "/static/img/raincoat_camel_mid-length_double-breasted-trench_10_back.png",
  "secondaryViewType": "back"
}
```

## Sneakers — `sneakers`

**API category slug:** `sneakers`  ·  **Products:** 16  ·  **Images:** 32 (primary + secondary)

### 117. `sneakers_white_low-top_knit-textile_01.png` &nbsp;·&nbsp; **primary**

White low-top walking sneaker, knit textile upper, white rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 117. `sneakers_white_low-top_knit-textile_01_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of White low top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "low top",
  "displayName": "White Low Top Sneakers",
  "color": "white",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_white_low-top_knit-textile_01.png",
  "secondaryImageUrl": "/static/img/sneakers_white_low-top_knit-textile_01_detail.png",
  "secondaryViewType": "detail"
}
```

### 118. `sneakers_off-white_minimalist_leather_02.png` &nbsp;·&nbsp; **primary**

Off-White minimalist walking sneaker, leather upper, cushioned EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 118. `sneakers_off-white_minimalist_leather_02_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Off White minimalist sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium leather grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "minimalist",
  "displayName": "Off White Minimalist Sneakers",
  "color": "off white",
  "attributes": {
    "material": "leather"
  },
  "primaryImageUrl": "/static/img/sneakers_off-white_minimalist_leather_02.png",
  "secondaryImageUrl": "/static/img/sneakers_off-white_minimalist_leather_02_detail.png",
  "secondaryViewType": "detail"
}
```

### 119. `sneakers_cream_retro_suede_03.png` &nbsp;·&nbsp; **primary**

Cream retro walking sneaker, suede upper, gum rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 119. `sneakers_cream_retro_suede_03_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Cream retro sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium suede grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "retro",
  "displayName": "Cream Retro Sneakers",
  "color": "cream",
  "attributes": {
    "material": "suede"
  },
  "primaryImageUrl": "/static/img/sneakers_cream_retro_suede_03.png",
  "secondaryImageUrl": "/static/img/sneakers_cream_retro_suede_03_detail.png",
  "secondaryViewType": "detail"
}
```

### 120. `sneakers_navy_low-top_recycled-mesh_04.png` &nbsp;·&nbsp; **primary**

Navy low-top walking sneaker, recycled mesh upper, treaded EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 120. `sneakers_navy_low-top_recycled-mesh_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Navy low top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium recycled mesh grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "low top",
  "displayName": "Navy Low Top Sneakers",
  "color": "navy",
  "attributes": {
    "material": "recycled mesh"
  },
  "primaryImageUrl": "/static/img/sneakers_navy_low-top_recycled-mesh_04.png",
  "secondaryImageUrl": "/static/img/sneakers_navy_low-top_recycled-mesh_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 121. `sneakers_all-black_mid-top_knit-textile_05.png` &nbsp;·&nbsp; **primary**

All-Black mid-top walking sneaker, knit textile upper, black rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 121. `sneakers_all-black_mid-top_knit-textile_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of All Black mid top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "mid top",
  "displayName": "All Black Mid Top Sneakers",
  "color": "all black",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_all-black_mid-top_knit-textile_05.png",
  "secondaryImageUrl": "/static/img/sneakers_all-black_mid-top_knit-textile_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 122. `sneakers_gray_minimalist_leather_06.png` &nbsp;·&nbsp; **primary**

Gray minimalist walking sneaker, leather upper, white rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 122. `sneakers_gray_minimalist_leather_06_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Gray minimalist sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium leather grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "minimalist",
  "displayName": "Gray Minimalist Sneakers",
  "color": "gray",
  "attributes": {
    "material": "leather"
  },
  "primaryImageUrl": "/static/img/sneakers_gray_minimalist_leather_06.png",
  "secondaryImageUrl": "/static/img/sneakers_gray_minimalist_leather_06_detail.png",
  "secondaryViewType": "detail"
}
```

### 123. `sneakers_olive_low-top_suede_07.png` &nbsp;·&nbsp; **primary**

Olive low-top walking sneaker, suede upper, gum rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 123. `sneakers_olive_low-top_suede_07_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Olive low top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium suede grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "low top",
  "displayName": "Olive Low Top Sneakers",
  "color": "olive",
  "attributes": {
    "material": "suede"
  },
  "primaryImageUrl": "/static/img/sneakers_olive_low-top_suede_07.png",
  "secondaryImageUrl": "/static/img/sneakers_olive_low-top_suede_07_detail.png",
  "secondaryViewType": "detail"
}
```

### 124. `sneakers_sand_retro_recycled-mesh_08.png` &nbsp;·&nbsp; **primary**

Sand retro walking sneaker, recycled mesh upper, cushioned EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 124. `sneakers_sand_retro_recycled-mesh_08_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sand retro sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium recycled mesh grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "retro",
  "displayName": "Sand Retro Sneakers",
  "color": "sand",
  "attributes": {
    "material": "recycled mesh"
  },
  "primaryImageUrl": "/static/img/sneakers_sand_retro_recycled-mesh_08.png",
  "secondaryImageUrl": "/static/img/sneakers_sand_retro_recycled-mesh_08_detail.png",
  "secondaryViewType": "detail"
}
```

### 125. `sneakers_charcoal_low-top_knit-textile_09.png` &nbsp;·&nbsp; **primary**

Charcoal low-top walking sneaker, knit textile upper, treaded EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 125. `sneakers_charcoal_low-top_knit-textile_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Charcoal low top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "low top",
  "displayName": "Charcoal Low Top Sneakers",
  "color": "charcoal",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_charcoal_low-top_knit-textile_09.png",
  "secondaryImageUrl": "/static/img/sneakers_charcoal_low-top_knit-textile_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 126. `sneakers_light-gray_minimalist_recycled-mesh_10.png` &nbsp;·&nbsp; **primary**

Light Gray minimalist walking sneaker, recycled mesh upper, white rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 126. `sneakers_light-gray_minimalist_recycled-mesh_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Light Gray minimalist sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium recycled mesh grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "minimalist",
  "displayName": "Light Gray Minimalist Sneakers",
  "color": "light gray",
  "attributes": {
    "material": "recycled mesh"
  },
  "primaryImageUrl": "/static/img/sneakers_light-gray_minimalist_recycled-mesh_10.png",
  "secondaryImageUrl": "/static/img/sneakers_light-gray_minimalist_recycled-mesh_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 127. `sneakers_beige_low-top_leather_11.png` &nbsp;·&nbsp; **primary**

Beige low-top walking sneaker, leather upper, gum rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 127. `sneakers_beige_low-top_leather_11_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Beige low top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium leather grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "low top",
  "displayName": "Beige Low Top Sneakers",
  "color": "beige",
  "attributes": {
    "material": "leather"
  },
  "primaryImageUrl": "/static/img/sneakers_beige_low-top_leather_11.png",
  "secondaryImageUrl": "/static/img/sneakers_beige_low-top_leather_11_detail.png",
  "secondaryViewType": "detail"
}
```

### 128. `sneakers_sky-blue_retro_knit-textile_12.png` &nbsp;·&nbsp; **primary**

Sky Blue retro walking sneaker, knit textile upper, cushioned EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 128. `sneakers_sky-blue_retro_knit-textile_12_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sky Blue retro sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "retro",
  "displayName": "Sky Blue Retro Sneakers",
  "color": "sky blue",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_sky-blue_retro_knit-textile_12.png",
  "secondaryImageUrl": "/static/img/sneakers_sky-blue_retro_knit-textile_12_detail.png",
  "secondaryViewType": "detail"
}
```

### 129. `sneakers_taupe_minimalist_suede_14.png` &nbsp;·&nbsp; **primary**

Taupe minimalist walking sneaker, suede upper, white rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 129. `sneakers_taupe_minimalist_suede_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Taupe minimalist sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium suede grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "minimalist",
  "displayName": "Taupe Minimalist Sneakers",
  "color": "taupe",
  "attributes": {
    "material": "suede"
  },
  "primaryImageUrl": "/static/img/sneakers_taupe_minimalist_suede_14.png",
  "secondaryImageUrl": "/static/img/sneakers_taupe_minimalist_suede_14_detail.png",
  "secondaryViewType": "detail"
}
```

### 130. `sneakers_ivory_retro_knit-textile_16.png` &nbsp;·&nbsp; **primary**

Ivory retro walking sneaker, knit textile upper, gum rubber sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 130. `sneakers_ivory_retro_knit-textile_16_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Ivory retro sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "retro",
  "displayName": "Ivory Retro Sneakers",
  "color": "ivory",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_ivory_retro_knit-textile_16.png",
  "secondaryImageUrl": "/static/img/sneakers_ivory_retro_knit-textile_16_detail.png",
  "secondaryViewType": "detail"
}
```

### 131. `sneakers_slate_mid-top_leather_17.png` &nbsp;·&nbsp; **primary**

Slate mid-top walking sneaker, leather upper, cushioned EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 131. `sneakers_slate_mid-top_leather_17_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Slate mid top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium leather grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "mid top",
  "displayName": "Slate Mid Top Sneakers",
  "color": "slate",
  "attributes": {
    "material": "leather"
  },
  "primaryImageUrl": "/static/img/sneakers_slate_mid-top_leather_17.png",
  "secondaryImageUrl": "/static/img/sneakers_slate_mid-top_leather_17_detail.png",
  "secondaryViewType": "detail"
}
```

### 132. `sneakers_white_mid-top_knit-textile_42.png` &nbsp;·&nbsp; **primary**

White mid-top walking sneaker, knit textile upper, cushioned EVA sole, photographed at a slight three-quarter angle on the backdrop, laces neatly tied, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 132. `sneakers_white_mid-top_knit-textile_42_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of White mid top sneakers, focusing on the toe box, eyelet row, lacing, and side-panel stitching, premium knit textile grain visible, subtle reflection on metal eyelets, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sneakers",
  "subcategory": "mid top",
  "displayName": "White Mid Top Sneakers",
  "color": "white",
  "attributes": {
    "material": "knit textile"
  },
  "primaryImageUrl": "/static/img/sneakers_white_mid-top_knit-textile_42.png",
  "secondaryImageUrl": "/static/img/sneakers_white_mid-top_knit-textile_42_detail.png",
  "secondaryViewType": "detail"
}
```

## Formal Shoes — `formal-shoes`

**API category slug:** `formal-shoes`  ·  **Products:** 14  ·  **Images:** 28 (primary + secondary)

### 133. `formal-shoes_black_oxford_smooth_01.png` &nbsp;·&nbsp; **primary**

Black oxford formal shoe in smooth leather, cap-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 133. `formal-shoes_black_oxford_smooth_01_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Black oxford formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished smooth grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "oxford",
  "displayName": "Black Oxford Formal Shoes",
  "color": "black",
  "attributes": {
    "leather": "smooth"
  },
  "primaryImageUrl": "/static/img/formal-shoes_black_oxford_smooth_01.png",
  "secondaryImageUrl": "/static/img/formal-shoes_black_oxford_smooth_01_detail.png",
  "secondaryViewType": "detail"
}
```

### 134. `formal-shoes_dark-brown_derby_full-grain_02.png` &nbsp;·&nbsp; **primary**

Dark Brown derby formal shoe in full-grain leather, plain-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 134. `formal-shoes_dark-brown_derby_full-grain_02_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Dark Brown derby formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished full grain grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "derby",
  "displayName": "Dark Brown Derby Formal Shoes",
  "color": "dark brown",
  "attributes": {
    "leather": "full grain"
  },
  "primaryImageUrl": "/static/img/formal-shoes_dark-brown_derby_full-grain_02.png",
  "secondaryImageUrl": "/static/img/formal-shoes_dark-brown_derby_full-grain_02_detail.png",
  "secondaryViewType": "detail"
}
```

### 135. `formal-shoes_oxblood_loafer_suede_03.png` &nbsp;·&nbsp; **primary**

Oxblood loafer formal shoe in suede leather, penny-strap, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 135. `formal-shoes_oxblood_loafer_suede_03_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Oxblood loafer formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished suede grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "loafer",
  "displayName": "Oxblood Loafer Formal Shoes",
  "color": "oxblood",
  "attributes": {
    "leather": "suede"
  },
  "primaryImageUrl": "/static/img/formal-shoes_oxblood_loafer_suede_03.png",
  "secondaryImageUrl": "/static/img/formal-shoes_oxblood_loafer_suede_03_detail.png",
  "secondaryViewType": "detail"
}
```

### 136. `formal-shoes_tan_monk-strap_pebbled_04.png` &nbsp;·&nbsp; **primary**

Tan monk-strap formal shoe in pebbled leather, brogued perforations, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 136. `formal-shoes_tan_monk-strap_pebbled_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Tan monk-strap formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished pebbled grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "monk-strap",
  "displayName": "Tan Monk Strap Formal Shoes",
  "color": "tan",
  "attributes": {
    "leather": "pebbled"
  },
  "primaryImageUrl": "/static/img/formal-shoes_tan_monk-strap_pebbled_04.png",
  "secondaryImageUrl": "/static/img/formal-shoes_tan_monk-strap_pebbled_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 137. `formal-shoes_walnut_oxford_full-grain_05.png` &nbsp;·&nbsp; **primary**

Walnut oxford formal shoe in full-grain leather, cap-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 137. `formal-shoes_walnut_oxford_full-grain_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Walnut oxford formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished full grain grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "oxford",
  "displayName": "Walnut Oxford Formal Shoes",
  "color": "walnut",
  "attributes": {
    "leather": "full grain"
  },
  "primaryImageUrl": "/static/img/formal-shoes_walnut_oxford_full-grain_05.png",
  "secondaryImageUrl": "/static/img/formal-shoes_walnut_oxford_full-grain_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 138. `formal-shoes_black_derby_smooth_06.png` &nbsp;·&nbsp; **primary**

Black derby formal shoe in smooth leather, plain-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 138. `formal-shoes_black_derby_smooth_06_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Black derby formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished smooth grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "derby",
  "displayName": "Black Derby Formal Shoes",
  "color": "black",
  "attributes": {
    "leather": "smooth"
  },
  "primaryImageUrl": "/static/img/formal-shoes_black_derby_smooth_06.png",
  "secondaryImageUrl": "/static/img/formal-shoes_black_derby_smooth_06_detail.png",
  "secondaryViewType": "detail"
}
```

### 139. `formal-shoes_cognac_loafer_full-grain_07.png` &nbsp;·&nbsp; **primary**

Cognac loafer formal shoe in full-grain leather, penny-strap, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 139. `formal-shoes_cognac_loafer_full-grain_07_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Cognac loafer formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished full grain grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "loafer",
  "displayName": "Cognac Loafer Formal Shoes",
  "color": "cognac",
  "attributes": {
    "leather": "full grain"
  },
  "primaryImageUrl": "/static/img/formal-shoes_cognac_loafer_full-grain_07.png",
  "secondaryImageUrl": "/static/img/formal-shoes_cognac_loafer_full-grain_07_detail.png",
  "secondaryViewType": "detail"
}
```

### 140. `formal-shoes_charcoal_monk-strap_suede_08.png` &nbsp;·&nbsp; **primary**

Charcoal monk-strap formal shoe in suede leather, plain-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 140. `formal-shoes_charcoal_monk-strap_suede_08_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Charcoal monk-strap formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished suede grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "monk-strap",
  "displayName": "Charcoal Monk Strap Formal Shoes",
  "color": "charcoal",
  "attributes": {
    "leather": "suede"
  },
  "primaryImageUrl": "/static/img/formal-shoes_charcoal_monk-strap_suede_08.png",
  "secondaryImageUrl": "/static/img/formal-shoes_charcoal_monk-strap_suede_08_detail.png",
  "secondaryViewType": "detail"
}
```

### 141. `formal-shoes_midnight-blue_oxford_pebbled_09.png` &nbsp;·&nbsp; **primary**

Midnight Blue oxford formal shoe in pebbled leather, brogued perforations, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 141. `formal-shoes_midnight-blue_oxford_pebbled_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Midnight Blue oxford formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished pebbled grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "oxford",
  "displayName": "Midnight Blue Oxford Formal Shoes",
  "color": "midnight blue",
  "attributes": {
    "leather": "pebbled"
  },
  "primaryImageUrl": "/static/img/formal-shoes_midnight-blue_oxford_pebbled_09.png",
  "secondaryImageUrl": "/static/img/formal-shoes_midnight-blue_oxford_pebbled_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 142. `formal-shoes_espresso_derby_smooth_10.png` &nbsp;·&nbsp; **primary**

Espresso derby formal shoe in smooth leather, cap-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 142. `formal-shoes_espresso_derby_smooth_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Espresso derby formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished smooth grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "derby",
  "displayName": "Espresso Derby Formal Shoes",
  "color": "espresso",
  "attributes": {
    "leather": "smooth"
  },
  "primaryImageUrl": "/static/img/formal-shoes_espresso_derby_smooth_10.png",
  "secondaryImageUrl": "/static/img/formal-shoes_espresso_derby_smooth_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 143. `formal-shoes_sand_loafer_suede_11.png` &nbsp;·&nbsp; **primary**

Sand loafer formal shoe in suede leather, plain-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 143. `formal-shoes_sand_loafer_suede_11_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sand loafer formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished suede grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "loafer",
  "displayName": "Sand Loafer Formal Shoes",
  "color": "sand",
  "attributes": {
    "leather": "suede"
  },
  "primaryImageUrl": "/static/img/formal-shoes_sand_loafer_suede_11.png",
  "secondaryImageUrl": "/static/img/formal-shoes_sand_loafer_suede_11_detail.png",
  "secondaryViewType": "detail"
}
```

### 144. `formal-shoes_burgundy_monk-strap_full-grain_12.png` &nbsp;·&nbsp; **primary**

Burgundy monk-strap formal shoe in full-grain leather, brogued perforations, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 144. `formal-shoes_burgundy_monk-strap_full-grain_12_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Burgundy monk-strap formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished full grain grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "monk-strap",
  "displayName": "Burgundy Monk Strap Formal Shoes",
  "color": "burgundy",
  "attributes": {
    "leather": "full grain"
  },
  "primaryImageUrl": "/static/img/formal-shoes_burgundy_monk-strap_full-grain_12.png",
  "secondaryImageUrl": "/static/img/formal-shoes_burgundy_monk-strap_full-grain_12_detail.png",
  "secondaryViewType": "detail"
}
```

### 145. `formal-shoes_graphite_oxford_smooth_13.png` &nbsp;·&nbsp; **primary**

Graphite oxford formal shoe in smooth leather, plain-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 145. `formal-shoes_graphite_oxford_smooth_13_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Graphite oxford formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished smooth grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "oxford",
  "displayName": "Graphite Oxford Formal Shoes",
  "color": "graphite",
  "attributes": {
    "leather": "smooth"
  },
  "primaryImageUrl": "/static/img/formal-shoes_graphite_oxford_smooth_13.png",
  "secondaryImageUrl": "/static/img/formal-shoes_graphite_oxford_smooth_13_detail.png",
  "secondaryViewType": "detail"
}
```

### 146. `formal-shoes_camel_derby_pebbled_14.png` &nbsp;·&nbsp; **primary**

Camel derby formal shoe in pebbled leather, cap-toe, photographed at a slight three-quarter angle on the backdrop, polished and centered, minimal shadow. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 146. `formal-shoes_camel_derby_pebbled_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Camel derby formal shoe, focusing on the toe cap, brogue perforations or vamp stitching, and welted edge, polished pebbled grain visible, soft directional light. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "formal-shoes",
  "subcategory": "derby",
  "displayName": "Camel Derby Formal Shoes",
  "color": "camel",
  "attributes": {
    "leather": "pebbled"
  },
  "primaryImageUrl": "/static/img/formal-shoes_camel_derby_pebbled_14.png",
  "secondaryImageUrl": "/static/img/formal-shoes_camel_derby_pebbled_14_detail.png",
  "secondaryViewType": "detail"
}
```

## Backpacks — `backpacks`

**API category slug:** `backpacks`  ·  **Products:** 12  ·  **Images:** 24 (primary + secondary)

### 147. `backpack_black_minimalist-commuter_recycled-nylon_01.png` &nbsp;·&nbsp; **primary**

Black minimalist commuter travel backpack in recycled nylon, with padded laptop sleeve panel, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 147. `backpack_black_minimalist-commuter_recycled-nylon_01_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Black minimalist commuter backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and recycled nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "minimalist commuter",
  "displayName": "Black Minimalist Commuter Backpacks",
  "color": "black",
  "attributes": {
    "material": "recycled nylon"
  },
  "primaryImageUrl": "/static/img/backpack_black_minimalist-commuter_recycled-nylon_01.png",
  "secondaryImageUrl": "/static/img/backpack_black_minimalist-commuter_recycled-nylon_01_detail.png",
  "secondaryViewType": "detail"
}
```

### 148. `backpack_charcoal_technical-travel_ripstop_02.png` &nbsp;·&nbsp; **primary**

Charcoal technical travel travel backpack in ripstop, with double-zip main compartment, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 148. `backpack_charcoal_technical-travel_ripstop_02_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Charcoal technical travel backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and ripstop weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "technical travel",
  "displayName": "Charcoal Technical Travel Backpacks",
  "color": "charcoal",
  "attributes": {
    "material": "ripstop"
  },
  "primaryImageUrl": "/static/img/backpack_charcoal_technical-travel_ripstop_02.png",
  "secondaryImageUrl": "/static/img/backpack_charcoal_technical-travel_ripstop_02_detail.png",
  "secondaryViewType": "detail"
}
```

### 149. `backpack_olive_daypack_waxed-canvas_03.png` &nbsp;·&nbsp; **primary**

Olive daypack travel backpack in waxed canvas, with stowable mesh side pockets, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 149. `backpack_olive_daypack_waxed-canvas_03_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Olive daypack backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and waxed canvas weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "daypack",
  "displayName": "Olive Daypack Backpacks",
  "color": "olive",
  "attributes": {
    "material": "waxed canvas"
  },
  "primaryImageUrl": "/static/img/backpack_olive_daypack_waxed-canvas_03.png",
  "secondaryImageUrl": "/static/img/backpack_olive_daypack_waxed-canvas_03_detail.png",
  "secondaryViewType": "detail"
}
```

### 150. `backpack_navy_roll-top_technical-mesh-and-nylon_04.png` &nbsp;·&nbsp; **primary**

Navy roll-top travel backpack in technical mesh and nylon, with ergonomic top handle, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 150. `backpack_navy_roll-top_technical-mesh-and-nylon_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Navy roll top backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and technical mesh and nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "roll top",
  "displayName": "Navy Roll Top Backpacks",
  "color": "navy",
  "attributes": {
    "material": "technical mesh and nylon"
  },
  "primaryImageUrl": "/static/img/backpack_navy_roll-top_technical-mesh-and-nylon_04.png",
  "secondaryImageUrl": "/static/img/backpack_navy_roll-top_technical-mesh-and-nylon_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 151. `backpack_sand_minimalist-commuter_recycled-nylon_05.png` &nbsp;·&nbsp; **primary**

Sand minimalist commuter travel backpack in recycled nylon, with double-zip main compartment, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 151. `backpack_sand_minimalist-commuter_recycled-nylon_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sand minimalist commuter backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and recycled nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "minimalist commuter",
  "displayName": "Sand Minimalist Commuter Backpacks",
  "color": "sand",
  "attributes": {
    "material": "recycled nylon"
  },
  "primaryImageUrl": "/static/img/backpack_sand_minimalist-commuter_recycled-nylon_05.png",
  "secondaryImageUrl": "/static/img/backpack_sand_minimalist-commuter_recycled-nylon_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 152. `backpack_slate_technical-travel_ripstop_06.png` &nbsp;·&nbsp; **primary**

Slate technical travel travel backpack in ripstop, with padded laptop sleeve panel, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 152. `backpack_slate_technical-travel_ripstop_06_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Slate technical travel backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and ripstop weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "technical travel",
  "displayName": "Slate Technical Travel Backpacks",
  "color": "slate",
  "attributes": {
    "material": "ripstop"
  },
  "primaryImageUrl": "/static/img/backpack_slate_technical-travel_ripstop_06.png",
  "secondaryImageUrl": "/static/img/backpack_slate_technical-travel_ripstop_06_detail.png",
  "secondaryViewType": "detail"
}
```

### 153. `backpack_forest-green_daypack_recycled-nylon_07.png` &nbsp;·&nbsp; **primary**

Forest Green daypack travel backpack in recycled nylon, with stowable mesh side pockets, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 153. `backpack_forest-green_daypack_recycled-nylon_07_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Forest Green daypack backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and recycled nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "daypack",
  "displayName": "Forest Green Daypack Backpacks",
  "color": "forest green",
  "attributes": {
    "material": "recycled nylon"
  },
  "primaryImageUrl": "/static/img/backpack_forest-green_daypack_recycled-nylon_07.png",
  "secondaryImageUrl": "/static/img/backpack_forest-green_daypack_recycled-nylon_07_detail.png",
  "secondaryViewType": "detail"
}
```

### 154. `backpack_tan_minimalist-commuter_waxed-canvas_08.png` &nbsp;·&nbsp; **primary**

Tan minimalist commuter travel backpack in waxed canvas, with ergonomic top handle, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 154. `backpack_tan_minimalist-commuter_waxed-canvas_08_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Tan minimalist commuter backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and waxed canvas weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "minimalist commuter",
  "displayName": "Tan Minimalist Commuter Backpacks",
  "color": "tan",
  "attributes": {
    "material": "waxed canvas"
  },
  "primaryImageUrl": "/static/img/backpack_tan_minimalist-commuter_waxed-canvas_08.png",
  "secondaryImageUrl": "/static/img/backpack_tan_minimalist-commuter_waxed-canvas_08_detail.png",
  "secondaryViewType": "detail"
}
```

### 155. `backpack_graphite_roll-top_ripstop_09.png` &nbsp;·&nbsp; **primary**

Graphite roll-top travel backpack in ripstop, with double-zip main compartment, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 155. `backpack_graphite_roll-top_ripstop_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Graphite roll top backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and ripstop weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "roll top",
  "displayName": "Graphite Roll Top Backpacks",
  "color": "graphite",
  "attributes": {
    "material": "ripstop"
  },
  "primaryImageUrl": "/static/img/backpack_graphite_roll-top_ripstop_09.png",
  "secondaryImageUrl": "/static/img/backpack_graphite_roll-top_ripstop_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 156. `backpack_burgundy_daypack_recycled-nylon_10.png` &nbsp;·&nbsp; **primary**

Burgundy daypack travel backpack in recycled nylon, with padded laptop sleeve panel, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 156. `backpack_burgundy_daypack_recycled-nylon_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Burgundy daypack backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and recycled nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "daypack",
  "displayName": "Burgundy Daypack Backpacks",
  "color": "burgundy",
  "attributes": {
    "material": "recycled nylon"
  },
  "primaryImageUrl": "/static/img/backpack_burgundy_daypack_recycled-nylon_10.png",
  "secondaryImageUrl": "/static/img/backpack_burgundy_daypack_recycled-nylon_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 157. `backpack_stone_technical-travel_technical-mesh-and-nylon_11.png` &nbsp;·&nbsp; **primary**

Stone technical travel travel backpack in technical mesh and nylon, with stowable mesh side pockets, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 157. `backpack_stone_technical-travel_technical-mesh-and-nylon_11_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Stone technical travel backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and technical mesh and nylon weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "technical travel",
  "displayName": "Stone Technical Travel Backpacks",
  "color": "stone",
  "attributes": {
    "material": "technical mesh and nylon"
  },
  "primaryImageUrl": "/static/img/backpack_stone_technical-travel_technical-mesh-and-nylon_11.png",
  "secondaryImageUrl": "/static/img/backpack_stone_technical-travel_technical-mesh-and-nylon_11_detail.png",
  "secondaryViewType": "detail"
}
```

### 158. `backpack_steel-blue_roll-top_ripstop_14.png` &nbsp;·&nbsp; **primary**

Steel Blue roll-top travel backpack in ripstop, with padded laptop sleeve panel, photographed standing upright at a slight three-quarter angle on the backdrop, straps neatly arranged, all hardware visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 158. `backpack_steel-blue_roll-top_ripstop_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Steel Blue roll top backpack front, focusing on the YKK zipper pull, stitched bartack reinforcement, and ripstop weave texture, hardware crisp in focus, three-quarter angle. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "backpacks",
  "subcategory": "roll top",
  "displayName": "Steel Blue Roll Top Backpacks",
  "color": "steel blue",
  "attributes": {
    "material": "ripstop"
  },
  "primaryImageUrl": "/static/img/backpack_steel-blue_roll-top_ripstop_14.png",
  "secondaryImageUrl": "/static/img/backpack_steel-blue_roll-top_ripstop_14_detail.png",
  "secondaryViewType": "detail"
}
```

## Sunglasses — `sunglasses`

**API category slug:** `sunglasses`  ·  **Products:** 14  ·  **Images:** 28 (primary + secondary)

### 159. `sunglasses_tortoise_rectangular_gradient-brown_01.png` &nbsp;·&nbsp; **primary**

Tortoise rectangular sunglasses with gradient brown lenses in acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 159. `sunglasses_tortoise_rectangular_gradient-brown_01_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Tortoise rectangular sunglasses, focusing on the temple hinge, frame texture, and gradient brown lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "rectangular",
  "displayName": "Tortoise Rectangular Sunglasses",
  "color": "tortoise",
  "attributes": {
    "lens": "gradient brown"
  },
  "primaryImageUrl": "/static/img/sunglasses_tortoise_rectangular_gradient-brown_01.png",
  "secondaryImageUrl": "/static/img/sunglasses_tortoise_rectangular_gradient-brown_01_detail.png",
  "secondaryViewType": "detail"
}
```

### 160. `sunglasses_matte-black_round_smoke-gray_02.png` &nbsp;·&nbsp; **primary**

Matte Black round sunglasses with smoke gray lenses in lightweight metal frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 160. `sunglasses_matte-black_round_smoke-gray_02_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Matte Black round sunglasses, focusing on the temple hinge, frame texture, and smoke gray lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "round",
  "displayName": "Matte Black Round Sunglasses",
  "color": "matte black",
  "attributes": {
    "lens": "smoke gray"
  },
  "primaryImageUrl": "/static/img/sunglasses_matte-black_round_smoke-gray_02.png",
  "secondaryImageUrl": "/static/img/sunglasses_matte-black_round_smoke-gray_02_detail.png",
  "secondaryViewType": "detail"
}
```

### 161. `sunglasses_gunmetal_aviator_polarized-green_03.png` &nbsp;·&nbsp; **primary**

Gunmetal aviator sunglasses with polarized green lenses in lightweight metal frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 161. `sunglasses_gunmetal_aviator_polarized-green_03_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Gunmetal aviator sunglasses, focusing on the temple hinge, frame texture, and polarized green lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "aviator",
  "displayName": "Gunmetal Aviator Sunglasses",
  "color": "gunmetal",
  "attributes": {
    "lens": "polarized green"
  },
  "primaryImageUrl": "/static/img/sunglasses_gunmetal_aviator_polarized-green_03.png",
  "secondaryImageUrl": "/static/img/sunglasses_gunmetal_aviator_polarized-green_03_detail.png",
  "secondaryViewType": "detail"
}
```

### 162. `sunglasses_clear_wayfarer_mirrored-silver_04.png` &nbsp;·&nbsp; **primary**

Clear wayfarer sunglasses with mirrored silver lenses in recycled bio-acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 162. `sunglasses_clear_wayfarer_mirrored-silver_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Clear wayfarer sunglasses, focusing on the temple hinge, frame texture, and mirrored silver lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "wayfarer",
  "displayName": "Clear Wayfarer Sunglasses",
  "color": "clear",
  "attributes": {
    "lens": "mirrored silver"
  },
  "primaryImageUrl": "/static/img/sunglasses_clear_wayfarer_mirrored-silver_04.png",
  "secondaryImageUrl": "/static/img/sunglasses_clear_wayfarer_mirrored-silver_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 163. `sunglasses_brown_oversized-square_gradient-brown_05.png` &nbsp;·&nbsp; **primary**

Brown oversized square sunglasses with gradient brown lenses in acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 163. `sunglasses_brown_oversized-square_gradient-brown_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Brown oversized square sunglasses, focusing on the temple hinge, frame texture, and gradient brown lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "oversized square",
  "displayName": "Brown Oversized Square Sunglasses",
  "color": "brown",
  "attributes": {
    "lens": "gradient brown"
  },
  "primaryImageUrl": "/static/img/sunglasses_brown_oversized-square_gradient-brown_05.png",
  "secondaryImageUrl": "/static/img/sunglasses_brown_oversized-square_gradient-brown_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 164. `sunglasses_matte-black_rimless_smoke-gray_06.png` &nbsp;·&nbsp; **primary**

Matte Black rimless sunglasses with smoke gray lenses in lightweight metal frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 164. `sunglasses_matte-black_rimless_smoke-gray_06_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Matte Black rimless sunglasses, focusing on the temple hinge, frame texture, and smoke gray lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "rimless",
  "displayName": "Matte Black Rimless Sunglasses",
  "color": "matte black",
  "attributes": {
    "lens": "smoke gray"
  },
  "primaryImageUrl": "/static/img/sunglasses_matte-black_rimless_smoke-gray_06.png",
  "secondaryImageUrl": "/static/img/sunglasses_matte-black_rimless_smoke-gray_06_detail.png",
  "secondaryViewType": "detail"
}
```

### 165. `sunglasses_tortoise_round_polarized-green_07.png` &nbsp;·&nbsp; **primary**

Tortoise round sunglasses with polarized green lenses in recycled bio-acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 165. `sunglasses_tortoise_round_polarized-green_07_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Tortoise round sunglasses, focusing on the temple hinge, frame texture, and polarized green lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "round",
  "displayName": "Tortoise Round Sunglasses",
  "color": "tortoise",
  "attributes": {
    "lens": "polarized green"
  },
  "primaryImageUrl": "/static/img/sunglasses_tortoise_round_polarized-green_07.png",
  "secondaryImageUrl": "/static/img/sunglasses_tortoise_round_polarized-green_07_detail.png",
  "secondaryViewType": "detail"
}
```

### 166. `sunglasses_gunmetal_rectangular_mirrored-silver_08.png` &nbsp;·&nbsp; **primary**

Gunmetal rectangular sunglasses with mirrored silver lenses in acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 166. `sunglasses_gunmetal_rectangular_mirrored-silver_08_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Gunmetal rectangular sunglasses, focusing on the temple hinge, frame texture, and mirrored silver lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "rectangular",
  "displayName": "Gunmetal Rectangular Sunglasses",
  "color": "gunmetal",
  "attributes": {
    "lens": "mirrored silver"
  },
  "primaryImageUrl": "/static/img/sunglasses_gunmetal_rectangular_mirrored-silver_08.png",
  "secondaryImageUrl": "/static/img/sunglasses_gunmetal_rectangular_mirrored-silver_08_detail.png",
  "secondaryViewType": "detail"
}
```

### 167. `sunglasses_charcoal_wayfarer_smoke-gray_09.png` &nbsp;·&nbsp; **primary**

Charcoal wayfarer sunglasses with smoke gray lenses in lightweight metal frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 167. `sunglasses_charcoal_wayfarer_smoke-gray_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Charcoal wayfarer sunglasses, focusing on the temple hinge, frame texture, and smoke gray lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "wayfarer",
  "displayName": "Charcoal Wayfarer Sunglasses",
  "color": "charcoal",
  "attributes": {
    "lens": "smoke gray"
  },
  "primaryImageUrl": "/static/img/sunglasses_charcoal_wayfarer_smoke-gray_09.png",
  "secondaryImageUrl": "/static/img/sunglasses_charcoal_wayfarer_smoke-gray_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 168. `sunglasses_amber_aviator_gradient-brown_10.png` &nbsp;·&nbsp; **primary**

Amber aviator sunglasses with gradient brown lenses in acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 168. `sunglasses_amber_aviator_gradient-brown_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Amber aviator sunglasses, focusing on the temple hinge, frame texture, and gradient brown lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "aviator",
  "displayName": "Amber Aviator Sunglasses",
  "color": "amber",
  "attributes": {
    "lens": "gradient brown"
  },
  "primaryImageUrl": "/static/img/sunglasses_amber_aviator_gradient-brown_10.png",
  "secondaryImageUrl": "/static/img/sunglasses_amber_aviator_gradient-brown_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 169. `sunglasses_navy_oversized-square_polarized-green_11.png` &nbsp;·&nbsp; **primary**

Navy oversized square sunglasses with polarized green lenses in recycled bio-acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 169. `sunglasses_navy_oversized-square_polarized-green_11_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Navy oversized square sunglasses, focusing on the temple hinge, frame texture, and polarized green lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "oversized square",
  "displayName": "Navy Oversized Square Sunglasses",
  "color": "navy",
  "attributes": {
    "lens": "polarized green"
  },
  "primaryImageUrl": "/static/img/sunglasses_navy_oversized-square_polarized-green_11.png",
  "secondaryImageUrl": "/static/img/sunglasses_navy_oversized-square_polarized-green_11_detail.png",
  "secondaryViewType": "detail"
}
```

### 170. `sunglasses_silver_rimless_mirrored-silver_12.png` &nbsp;·&nbsp; **primary**

Silver rimless sunglasses with mirrored silver lenses in lightweight metal frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 170. `sunglasses_silver_rimless_mirrored-silver_12_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Silver rimless sunglasses, focusing on the temple hinge, frame texture, and mirrored silver lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "rimless",
  "displayName": "Silver Rimless Sunglasses",
  "color": "silver",
  "attributes": {
    "lens": "mirrored silver"
  },
  "primaryImageUrl": "/static/img/sunglasses_silver_rimless_mirrored-silver_12.png",
  "secondaryImageUrl": "/static/img/sunglasses_silver_rimless_mirrored-silver_12_detail.png",
  "secondaryViewType": "detail"
}
```

### 171. `sunglasses_olive_rectangular_smoke-gray_13.png` &nbsp;·&nbsp; **primary**

Olive rectangular sunglasses with smoke gray lenses in acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 171. `sunglasses_olive_rectangular_smoke-gray_13_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Olive rectangular sunglasses, focusing on the temple hinge, frame texture, and smoke gray lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "rectangular",
  "displayName": "Olive Rectangular Sunglasses",
  "color": "olive",
  "attributes": {
    "lens": "smoke gray"
  },
  "primaryImageUrl": "/static/img/sunglasses_olive_rectangular_smoke-gray_13.png",
  "secondaryImageUrl": "/static/img/sunglasses_olive_rectangular_smoke-gray_13_detail.png",
  "secondaryViewType": "detail"
}
```

### 172. `sunglasses_cream_round_gradient-brown_14.png` &nbsp;·&nbsp; **primary**

Cream round sunglasses with gradient brown lenses in recycled bio-acetate frame, displayed flat-lay top-down on the backdrop, arms slightly open, subtle reflection on the lens. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 172. `sunglasses_cream_round_gradient-brown_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Cream round sunglasses, focusing on the temple hinge, frame texture, and gradient brown lens edge, subtle reflection on the lens, hardware in sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "sunglasses",
  "subcategory": "round",
  "displayName": "Cream Round Sunglasses",
  "color": "cream",
  "attributes": {
    "lens": "gradient brown"
  },
  "primaryImageUrl": "/static/img/sunglasses_cream_round_gradient-brown_14.png",
  "secondaryImageUrl": "/static/img/sunglasses_cream_round_gradient-brown_14_detail.png",
  "secondaryViewType": "detail"
}
```

## Accessories — `accessories`

**API category slug:** `accessories`  ·  **Products:** 28  ·  **Images:** 56 (primary + secondary)

### 173. `winter_navy_beanie_recycled-wool_04.png` &nbsp;·&nbsp; **primary**

Navy midweight beanie in recycled wool, ribbed cuffs, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 173. `winter_navy_beanie_recycled-wool_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Navy beanie accessory, close-up of the ribbed cuff and crown knit pattern, fiber texture and stitch loops crisp in focus, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "beanie",
  "displayName": "Navy Beanie Accessories",
  "color": "navy",
  "attributes": {
    "fabric": "recycled wool"
  },
  "primaryImageUrl": "/static/img/winter_navy_beanie_recycled-wool_04.png",
  "secondaryImageUrl": "/static/img/winter_navy_beanie_recycled-wool_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 174. `winter_camel_scarf_brushed-alpaca_05.png` &nbsp;·&nbsp; **primary**

Camel chunky scarf in brushed alpaca, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 174. `winter_camel_scarf_brushed-alpaca_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Camel scarf accessory, close-up of the cable knit pattern and fringed edge, individual fibers visible, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "scarf",
  "displayName": "Camel Scarf Accessories",
  "color": "camel",
  "attributes": {
    "fabric": "brushed alpaca"
  },
  "primaryImageUrl": "/static/img/winter_camel_scarf_brushed-alpaca_05.png",
  "secondaryImageUrl": "/static/img/winter_camel_scarf_brushed-alpaca_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 175. `winter_black_beanie_recycled-wool_09.png` &nbsp;·&nbsp; **primary**

Black midweight beanie in recycled wool, ribbed cuffs, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 175. `winter_black_beanie_recycled-wool_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Black beanie accessory, close-up of the ribbed cuff and crown knit pattern, fiber texture and stitch loops crisp in focus, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "beanie",
  "displayName": "Black Beanie Accessories",
  "color": "black",
  "attributes": {
    "fabric": "recycled wool"
  },
  "primaryImageUrl": "/static/img/winter_black_beanie_recycled-wool_09.png",
  "secondaryImageUrl": "/static/img/winter_black_beanie_recycled-wool_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 176. `winter_deep-teal_scarf_merino-wool_10.png` &nbsp;·&nbsp; **primary**

Deep Teal lightweight scarf in merino wool, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 176. `winter_deep-teal_scarf_merino-wool_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Deep Teal scarf accessory, close-up of the cable knit pattern and fringed edge, individual fibers visible, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "scarf",
  "displayName": "Deep Teal Scarf Accessories",
  "color": "deep teal",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_deep-teal_scarf_merino-wool_10.png",
  "secondaryImageUrl": "/static/img/winter_deep-teal_scarf_merino-wool_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 177. `winter_olive_beanie_cashmere-blend_14.png` &nbsp;·&nbsp; **primary**

Olive lightweight beanie in cashmere blend, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 177. `winter_olive_beanie_cashmere-blend_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Olive beanie accessory, close-up of the ribbed cuff and crown knit pattern, fiber texture and stitch loops crisp in focus, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "beanie",
  "displayName": "Olive Beanie Accessories",
  "color": "olive",
  "attributes": {
    "fabric": "cashmere blend"
  },
  "primaryImageUrl": "/static/img/winter_olive_beanie_cashmere-blend_14.png",
  "secondaryImageUrl": "/static/img/winter_olive_beanie_cashmere-blend_14_detail.png",
  "secondaryViewType": "detail"
}
```

### 178. `winter_wine_scarf_recycled-wool_15.png` &nbsp;·&nbsp; **primary**

Wine chunky scarf in recycled wool, cable knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 178. `winter_wine_scarf_recycled-wool_15_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Wine scarf accessory, close-up of the cable knit pattern and fringed edge, individual fibers visible, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "scarf",
  "displayName": "Wine Scarf Accessories",
  "color": "wine",
  "attributes": {
    "fabric": "recycled wool"
  },
  "primaryImageUrl": "/static/img/winter_wine_scarf_recycled-wool_15.png",
  "secondaryImageUrl": "/static/img/winter_wine_scarf_recycled-wool_15_detail.png",
  "secondaryViewType": "detail"
}
```

### 179. `winter_espresso_beanie_merino-wool_19.png` &nbsp;·&nbsp; **primary**

Espresso midweight beanie in merino wool, ribbed cuffs, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 179. `winter_espresso_beanie_merino-wool_19_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Espresso beanie accessory, close-up of the ribbed cuff and crown knit pattern, fiber texture and stitch loops crisp in focus, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "beanie",
  "displayName": "Espresso Beanie Accessories",
  "color": "espresso",
  "attributes": {
    "fabric": "merino wool"
  },
  "primaryImageUrl": "/static/img/winter_espresso_beanie_merino-wool_19.png",
  "secondaryImageUrl": "/static/img/winter_espresso_beanie_merino-wool_19_detail.png",
  "secondaryViewType": "detail"
}
```

### 180. `winter_sage_scarf_cashmere-blend_20.png` &nbsp;·&nbsp; **primary**

Sage lightweight scarf in cashmere blend, fine gauge knit, displayed flat-lay on the backdrop, neatly folded with visible knit pattern and fiber texture. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 180. `winter_sage_scarf_cashmere-blend_20_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sage scarf accessory, close-up of the cable knit pattern and fringed edge, individual fibers visible, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "scarf",
  "displayName": "Sage Scarf Accessories",
  "color": "sage",
  "attributes": {
    "fabric": "cashmere blend"
  },
  "primaryImageUrl": "/static/img/winter_sage_scarf_cashmere-blend_20.png",
  "secondaryImageUrl": "/static/img/winter_sage_scarf_cashmere-blend_20_detail.png",
  "secondaryViewType": "detail"
}
```

### 181. `travel_compact_black_ripstop-nylon_01.png` &nbsp;·&nbsp; **primary**

Compact Travel Umbrella (Closed) in black ripstop nylon, zip pulls visible, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 181. `travel_compact_black_ripstop-nylon_01_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Black umbrella accessory, close-up of the canopy seam, tip cap, and ripstop fabric weave, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "umbrella",
  "displayName": "Black Umbrella Accessories",
  "color": "black",
  "attributes": {
    "material": "ripstop nylon"
  },
  "primaryImageUrl": "/static/img/travel_compact_black_ripstop-nylon_01.png",
  "secondaryImageUrl": "/static/img/travel_compact_black_ripstop-nylon_01_detail.png",
  "secondaryViewType": "detail"
}
```

### 182. `travel_set_charcoal_recycled-polyester_02.png` &nbsp;·&nbsp; **primary**

Set Of Three Packing Cubes in charcoal recycled polyester, mesh window panels, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 182. `travel_set_charcoal_recycled-polyester_02_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Charcoal packing cubes accessory, close-up of the YKK zipper, webbing handle, and ripstop fabric panel, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "packing-cubes",
  "displayName": "Charcoal Packing Cubes Accessories",
  "color": "charcoal",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_set_charcoal_recycled-polyester_02.png",
  "secondaryImageUrl": "/static/img/travel_set_charcoal_recycled-polyester_02_detail.png",
  "secondaryViewType": "detail"
}
```

### 183. `travel_merino_olive_merino-wool_03.png` &nbsp;·&nbsp; **primary**

Merino Travel Socks in olive merino wool, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 183. `travel_merino_olive_merino-wool_03_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Olive socks accessory, close-up of the heel reinforcement and ribbed cuff, knit grid sharply focused, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "socks",
  "displayName": "Olive Socks Accessories",
  "color": "olive",
  "attributes": {
    "material": "merino wool"
  },
  "primaryImageUrl": "/static/img/travel_merino_olive_merino-wool_03.png",
  "secondaryImageUrl": "/static/img/travel_merino_olive_merino-wool_03_detail.png",
  "secondaryViewType": "detail"
}
```

### 184. `travel_leather_navy_full-grain-leather_04.png` &nbsp;·&nbsp; **primary**

Leather Card Wallet in navy full-grain leather, woven label, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 184. `travel_leather_navy_full-grain-leather_04_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Navy wallet accessory, close-up of the corner stitch, beveled edge finishing, and full-grain leather texture, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "wallet",
  "displayName": "Navy Wallet Accessories",
  "color": "navy",
  "attributes": {
    "material": "full grain leather"
  },
  "primaryImageUrl": "/static/img/travel_leather_navy_full-grain-leather_04.png",
  "secondaryImageUrl": "/static/img/travel_leather_navy_full-grain-leather_04_detail.png",
  "secondaryViewType": "detail"
}
```

### 185. `travel_microfiber_sand_microfiber_05.png` &nbsp;·&nbsp; **primary**

Microfiber Travel Towel in sand microfiber, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 185. `travel_microfiber_sand_microfiber_05_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sand towel accessory, close-up of the looped pile texture and stitched edge binding, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "towel",
  "displayName": "Sand Towel Accessories",
  "color": "sand",
  "attributes": {
    "material": "microfiber"
  },
  "primaryImageUrl": "/static/img/travel_microfiber_sand_microfiber_05.png",
  "secondaryImageUrl": "/static/img/travel_microfiber_sand_microfiber_05_detail.png",
  "secondaryViewType": "detail"
}
```

### 186. `travel_travel_slate_recycled-polyester_06.png` &nbsp;·&nbsp; **primary**

Travel Cable Organizer Pouch in slate recycled polyester, zip pulls visible, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 186. `travel_travel_slate_recycled-polyester_06_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Slate cable organizer accessory, close-up of the elastic loop array, zipper teeth, and webbing handle, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "cable-organizer",
  "displayName": "Slate Cable Organizer Accessories",
  "color": "slate",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_travel_slate_recycled-polyester_06.png",
  "secondaryImageUrl": "/static/img/travel_travel_slate_recycled-polyester_06_detail.png",
  "secondaryViewType": "detail"
}
```

### 187. `travel_compact_forest-green_ripstop-nylon_07.png` &nbsp;·&nbsp; **primary**

Compact Travel Umbrella (Closed) in forest green ripstop nylon, mesh window panels, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 187. `travel_compact_forest-green_ripstop-nylon_07_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Forest Green umbrella accessory, close-up of the canopy seam, tip cap, and ripstop fabric weave, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "umbrella",
  "displayName": "Forest Green Umbrella Accessories",
  "color": "forest green",
  "attributes": {
    "material": "ripstop nylon"
  },
  "primaryImageUrl": "/static/img/travel_compact_forest-green_ripstop-nylon_07.png",
  "secondaryImageUrl": "/static/img/travel_compact_forest-green_ripstop-nylon_07_detail.png",
  "secondaryViewType": "detail"
}
```

### 188. `travel_set_tan_recycled-polyester_08.png` &nbsp;·&nbsp; **primary**

Set Of Three Packing Cubes in tan recycled polyester, woven label, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 188. `travel_set_tan_recycled-polyester_08_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Tan packing cubes accessory, close-up of the YKK zipper, webbing handle, and ripstop fabric panel, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "packing-cubes",
  "displayName": "Tan Packing Cubes Accessories",
  "color": "tan",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_set_tan_recycled-polyester_08.png",
  "secondaryImageUrl": "/static/img/travel_set_tan_recycled-polyester_08_detail.png",
  "secondaryViewType": "detail"
}
```

### 189. `travel_merino_graphite_merino-wool_09.png` &nbsp;·&nbsp; **primary**

Merino Travel Socks in graphite merino wool, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 189. `travel_merino_graphite_merino-wool_09_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Graphite socks accessory, close-up of the heel reinforcement and ribbed cuff, knit grid sharply focused, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "socks",
  "displayName": "Graphite Socks Accessories",
  "color": "graphite",
  "attributes": {
    "material": "merino wool"
  },
  "primaryImageUrl": "/static/img/travel_merino_graphite_merino-wool_09.png",
  "secondaryImageUrl": "/static/img/travel_merino_graphite_merino-wool_09_detail.png",
  "secondaryViewType": "detail"
}
```

### 190. `travel_leather_burgundy_full-grain-leather_10.png` &nbsp;·&nbsp; **primary**

Leather Card Wallet in burgundy full-grain leather, zip pulls visible, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 190. `travel_leather_burgundy_full-grain-leather_10_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Burgundy wallet accessory, close-up of the corner stitch, beveled edge finishing, and full-grain leather texture, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "wallet",
  "displayName": "Burgundy Wallet Accessories",
  "color": "burgundy",
  "attributes": {
    "material": "full grain leather"
  },
  "primaryImageUrl": "/static/img/travel_leather_burgundy_full-grain-leather_10.png",
  "secondaryImageUrl": "/static/img/travel_leather_burgundy_full-grain-leather_10_detail.png",
  "secondaryViewType": "detail"
}
```

### 191. `travel_microfiber_stone_microfiber_11.png` &nbsp;·&nbsp; **primary**

Microfiber Travel Towel in stone microfiber, mesh window panels, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 191. `travel_microfiber_stone_microfiber_11_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Stone towel accessory, close-up of the looped pile texture and stitched edge binding, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "towel",
  "displayName": "Stone Towel Accessories",
  "color": "stone",
  "attributes": {
    "material": "microfiber"
  },
  "primaryImageUrl": "/static/img/travel_microfiber_stone_microfiber_11.png",
  "secondaryImageUrl": "/static/img/travel_microfiber_stone_microfiber_11_detail.png",
  "secondaryViewType": "detail"
}
```

### 192. `travel_travel_midnight-blue_recycled-polyester_12.png` &nbsp;·&nbsp; **primary**

Travel Cable Organizer Pouch in midnight blue recycled polyester, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 192. `travel_travel_midnight-blue_recycled-polyester_12_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Midnight Blue cable organizer accessory, close-up of the elastic loop array, zipper teeth, and webbing handle, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "cable-organizer",
  "displayName": "Midnight Blue Cable Organizer Accessories",
  "color": "midnight blue",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_travel_midnight-blue_recycled-polyester_12.png",
  "secondaryImageUrl": "/static/img/travel_travel_midnight-blue_recycled-polyester_12_detail.png",
  "secondaryViewType": "detail"
}
```

### 193. `travel_compact_camel_ripstop-nylon_13.png` &nbsp;·&nbsp; **primary**

Compact Travel Umbrella (Closed) in camel ripstop nylon, woven label, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 193. `travel_compact_camel_ripstop-nylon_13_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Camel umbrella accessory, close-up of the canopy seam, tip cap, and ripstop fabric weave, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "umbrella",
  "displayName": "Camel Umbrella Accessories",
  "color": "camel",
  "attributes": {
    "material": "ripstop nylon"
  },
  "primaryImageUrl": "/static/img/travel_compact_camel_ripstop-nylon_13.png",
  "secondaryImageUrl": "/static/img/travel_compact_camel_ripstop-nylon_13_detail.png",
  "secondaryViewType": "detail"
}
```

### 194. `travel_set_steel-blue_recycled-polyester_14.png` &nbsp;·&nbsp; **primary**

Set Of Three Packing Cubes in steel blue recycled polyester, zip pulls visible, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 194. `travel_set_steel-blue_recycled-polyester_14_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Steel Blue packing cubes accessory, close-up of the YKK zipper, webbing handle, and ripstop fabric panel, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "packing-cubes",
  "displayName": "Steel Blue Packing Cubes Accessories",
  "color": "steel blue",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_set_steel-blue_recycled-polyester_14.png",
  "secondaryImageUrl": "/static/img/travel_set_steel-blue_recycled-polyester_14_detail.png",
  "secondaryViewType": "detail"
}
```

### 195. `travel_merino_espresso_merino-wool_15.png` &nbsp;·&nbsp; **primary**

Merino Travel Socks in espresso merino wool, mesh window panels, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 195. `travel_merino_espresso_merino-wool_15_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Espresso socks accessory, close-up of the heel reinforcement and ribbed cuff, knit grid sharply focused, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "socks",
  "displayName": "Espresso Socks Accessories",
  "color": "espresso",
  "attributes": {
    "material": "merino wool"
  },
  "primaryImageUrl": "/static/img/travel_merino_espresso_merino-wool_15.png",
  "secondaryImageUrl": "/static/img/travel_merino_espresso_merino-wool_15_detail.png",
  "secondaryViewType": "detail"
}
```

### 196. `travel_leather_sage_full-grain-leather_16.png` &nbsp;·&nbsp; **primary**

Leather Card Wallet in sage full-grain leather, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 196. `travel_leather_sage_full-grain-leather_16_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Sage wallet accessory, close-up of the corner stitch, beveled edge finishing, and full-grain leather texture, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "wallet",
  "displayName": "Sage Wallet Accessories",
  "color": "sage",
  "attributes": {
    "material": "full grain leather"
  },
  "primaryImageUrl": "/static/img/travel_leather_sage_full-grain-leather_16.png",
  "secondaryImageUrl": "/static/img/travel_leather_sage_full-grain-leather_16_detail.png",
  "secondaryViewType": "detail"
}
```

### 197. `travel_microfiber_pewter_microfiber_17.png` &nbsp;·&nbsp; **primary**

Microfiber Travel Towel in pewter microfiber, woven label, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 197. `travel_microfiber_pewter_microfiber_17_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Pewter towel accessory, close-up of the looped pile texture and stitched edge binding, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "towel",
  "displayName": "Pewter Towel Accessories",
  "color": "pewter",
  "attributes": {
    "material": "microfiber"
  },
  "primaryImageUrl": "/static/img/travel_microfiber_pewter_microfiber_17.png",
  "secondaryImageUrl": "/static/img/travel_microfiber_pewter_microfiber_17_detail.png",
  "secondaryViewType": "detail"
}
```

### 198. `travel_travel_rust_recycled-polyester_18.png` &nbsp;·&nbsp; **primary**

Travel Cable Organizer Pouch in rust recycled polyester, zip pulls visible, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 198. `travel_travel_rust_recycled-polyester_18_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Rust cable organizer accessory, close-up of the elastic loop array, zipper teeth, and webbing handle, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "cable-organizer",
  "displayName": "Rust Cable Organizer Accessories",
  "color": "rust",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_travel_rust_recycled-polyester_18.png",
  "secondaryImageUrl": "/static/img/travel_travel_rust_recycled-polyester_18_detail.png",
  "secondaryViewType": "detail"
}
```

### 199. `travel_compact_ivory_ripstop-nylon_19.png` &nbsp;·&nbsp; **primary**

Compact Travel Umbrella (Closed) in ivory ripstop nylon, contrast stitching, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 199. `travel_compact_ivory_ripstop-nylon_19_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Ivory umbrella accessory, close-up of the canopy seam, tip cap, and ripstop fabric weave, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "umbrella",
  "displayName": "Ivory Umbrella Accessories",
  "color": "ivory",
  "attributes": {
    "material": "ripstop nylon"
  },
  "primaryImageUrl": "/static/img/travel_compact_ivory_ripstop-nylon_19.png",
  "secondaryImageUrl": "/static/img/travel_compact_ivory_ripstop-nylon_19_detail.png",
  "secondaryViewType": "detail"
}
```

### 200. `travel_set_teal_recycled-polyester_20.png` &nbsp;·&nbsp; **primary**

Set Of Three Packing Cubes in teal recycled polyester, mesh window panels, displayed flat-lay top-down on the backdrop, neatly arranged with hardware and stitching visible. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

### 200. `travel_set_teal_recycled-polyester_20_detail.png` &nbsp;·&nbsp; **secondary (detail)**

Extreme close-up macro detail shot of Teal packing cubes accessory, close-up of the YKK zipper, webbing handle, and ripstop fabric panel, soft directional light, sharp focus. Studio e-commerce catalog photography, seamless warm light gray backdrop, soft diffused overhead lighting, neutral color balance, sharp focus, visible fabric texture, minimal premium aesthetic, centered composition, no text, no logos, no branding, no people, no patterned background.

**Seed metadata:**

```json
{
  "category": "accessories",
  "subcategory": "packing-cubes",
  "displayName": "Teal Packing Cubes Accessories",
  "color": "teal",
  "attributes": {
    "material": "recycled polyester"
  },
  "primaryImageUrl": "/static/img/travel_set_teal_recycled-polyester_20.png",
  "secondaryImageUrl": "/static/img/travel_set_teal_recycled-polyester_20_detail.png",
  "secondaryViewType": "detail"
}
```

## Category Hero Banners — 16:9 Lifestyle

**Aspect:** 16:9 widescreen lifestyle  ·  **Count:** 15  ·  **Filename family:** `cat-*.png` per API contract §3.4.1

These banners appear in the C5 mega-menu (`heroImageUrl` on parent rows) and on the C9 category landing page hero. Style is **lifestyle interior** (no people) so the storefront feels editorial rather than catalog.

### H1. `cat-tshirts.png` &nbsp;·&nbsp; `tshirts`

An oak side table with a neat stack of three folded t-shirts in cream, navy, and sage green, a leather watchband resting on top, soft window light from the left, warm minimalist styling on a warm light gray wall. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "tshirts",
  "heroImageUrl": "/static/img/cat-tshirts.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H2. `cat-shirts.png` &nbsp;·&nbsp; `shirts`

An open oak shelving unit with three neatly folded button-down shirts in white, soft pink, and chambray blue arranged on the middle shelf, a single dried botanical sprig in a small ceramic vessel beside them, soft side window light, warm light gray wall behind. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "shirts",
  "heroImageUrl": "/static/img/cat-shirts.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H3. `cat-jeans.png` &nbsp;·&nbsp; `jeans`

A simple oak wooden chair with a folded pair of indigo denim jeans draped over the seat, a tan leather belt coiled on top, soft afternoon window light, warm light gray wall behind, premium minimalist composition. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "jeans",
  "heroImageUrl": "/static/img/cat-jeans.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H4. `cat-pants.png` &nbsp;·&nbsp; `pants`

A wooden valet stand with a neatly folded pair of stone chinos and a pair of brown leather loafers placed on the floor below, soft directional window light from the right, warm light gray wall, refined minimalist palette. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "pants",
  "heroImageUrl": "/static/img/cat-pants.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H5. `cat-jackets.png` &nbsp;·&nbsp; `jackets`

A rustic oak coat rack with three blazers hung in earthy tones (charcoal, navy, and olive), garments slightly overlapping, soft afternoon light filtering from the right, warm light gray wall behind, premium minimalist composition. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "jackets",
  "heroImageUrl": "/static/img/cat-jackets.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H6. `cat-dresses.png` &nbsp;·&nbsp; `dresses`

A bright dressing-area corner with a sage-green silk a-line dress hung from a brass wall hook, a folded ivory wrap dress resting on a low oak bench beneath, a large potted fig plant softly out of focus on the right, warm light gray walls. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "dresses",
  "heroImageUrl": "/static/img/cat-dresses.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H7. `cat-sweaters.png` &nbsp;·&nbsp; `sweaters`

A round oak coffee table with three folded knitwear pieces stacked at left (cream cardigan, charcoal crew-neck, oatmeal half-zip), a ceramic mug of tea with steam rising on the right, soft window light, warm light gray wall behind. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "sweaters",
  "heroImageUrl": "/static/img/cat-sweaters.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H8. `cat-raincoats.png` &nbsp;·&nbsp; `raincoats`

A foyer scene with a beige trench coat hung from a wall hook, a long umbrella resting against the wall beneath, a pair of dark leather rain boots placed on the oak floorboards, soft side window light, warm light gray walls, premium minimalist composition. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "raincoats",
  "heroImageUrl": "/static/img/cat-raincoats.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H9. `cat-sneakers.png` &nbsp;·&nbsp; `sneakers`

A polished oak sideboard with two pairs of premium leather sneakers (white low-top and tan retro) placed at left, a folded chambray pocket square beside them, soft directional window light, warm light gray wall behind, refined minimalist editorial aesthetic. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "sneakers",
  "heroImageUrl": "/static/img/cat-sneakers.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H10. `cat-formal-shoes.png` &nbsp;·&nbsp; `formal-shoes`

A classic oak shoeshine bench with two pairs of polished leather shoes (black oxford and brown loafer) arranged at left, a horsehair brush and a small tin of polish beside them, soft directional window light, warm light gray wall behind. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "formal-shoes",
  "heroImageUrl": "/static/img/cat-formal-shoes.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H11. `cat-backpacks.png` &nbsp;·&nbsp; `backpacks`

A wooden hallway bench with a structured leather commuter backpack leaning against the wall on the left, a folded wool scarf draped beside it and a pair of leather gloves on the bench, soft morning window light, warm light gray walls. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "backpacks",
  "heroImageUrl": "/static/img/cat-backpacks.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H12. `cat-sunglasses.png` &nbsp;·&nbsp; `sunglasses`

An oak desk surface with three pairs of sunglasses arranged diagonally at left (rectangular, round, aviator), arms slightly open, soft shadows beneath them, a single dried wildflower stem to the right, warm light gray wall behind, soft directional light. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "sunglasses",
  "heroImageUrl": "/static/img/cat-sunglasses.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H13. `cat-accessories.png` &nbsp;·&nbsp; `accessories`

A circular oak tray with assorted small leather goods at left (card wallet, sunglasses case, key fob), a folded merino scarf and a beanie next to them, soft side window light, warm light gray wall behind, refined neutral premium palette. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "accessories",
  "heroImageUrl": "/static/img/cat-accessories.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H14. `cat-menswear.png` &nbsp;·&nbsp; `menswear`

A sunlit walk-in closet corner with a row of neatly hung shirts and a folded sweater on the shelf above, a pair of leather loafers on the lower oak shelf, warm light gray walls, soft afternoon light filtering from the right, premium minimalist closet styling. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "menswear",
  "heroImageUrl": "/static/img/cat-menswear.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```

### H15. `cat-womenswear.png` &nbsp;·&nbsp; `womenswear`

A bright open dressing-area corner with hung silk blouses on the left, a folded knit cardigan on a low oak bench, a large potted fig plant softly out of focus on the right, warm light gray walls, soft natural window light, refined editorial styling. Lifestyle interior photography, warm light gray walls and natural oak surfaces, soft directional window light, no people, no faces, no text, no logos, no branding, premium minimalist editorial aesthetic, 16:9 horizontal composition with generous negative space on the right for category-name overlay, sharp focus on featured items, shallow depth of field on background, neutral warm color balance.

**Seed metadata:**

```json
{
  "categorySlug": "womenswear",
  "heroImageUrl": "/static/img/cat-womenswear.png",
  "fileFamily": "cat-*.png",
  "aspectRatio": "16:9"
}
```
