# StyleMart Database Schema Diagram

## Entity Relationship Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FOUNDATION TABLES                                   │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────┐          ┌─────────────────┐
    │  loyalty_tiers  │          │   categories    │
    │─────────────────│          │─────────────────│
    │ tier_id (PK)    │          │ slug (PK)       │◄───┐
    │ display_name    │          │ display_name    │    │ self-reference
    │ discount_pct    │          │ parent_slug     │────┘ (hierarchy)
    │ spend_threshold │          │ hero_image      │
    └────────┬────────┘          └────────┬────────┘
             │                            │
             │ FK                         │ FK
             │                            │
    ┌────────▼────────┐          ┌────────▼────────────────────┐
    │     users       │          │        products             │
    │─────────────────│          │─────────────────────────────│
    │ user_id (PK)    │          │ product_id (PK)             │
    │ display_name    │          │ slug (UNIQUE)               │
    │ email           │          │ name                        │
    │ loyalty_tier_id │          │ brand                       │
    │ created_at      │          │ category ───────────────────┘
    └────┬─────┬──────┘          │ base_price_cents            │
         │     │                 │ image_url                   │
         │     │                 │ average_rating              │
         │     │                 │ attributes (JSON)           │
         │     │                 └──┬────────────┬─────────────┘
         │     │                    │            │
         │     │                    │ FK         │ FK
         │     │                    │            │

┌────────┴─────────────────────────┼────────────┼─────────────────────────────┐
│                    PRODUCT DETAILS                                           │
└──────────────────────────────────────────────────────────────────────────────┘

         │     │            ┌───────▼────────┐  ┌──────▼──────────┐
         │     │            │ product_images │  │product_variants │
         │     │            │────────────────│  │─────────────────│
         │     │            │ image_id (PK)  │  │ variant_id (PK) │
         │     │            │ product_id     │  │ product_id      │
         │     │            │ url            │  │ size            │
         │     │            │ position       │  │ color           │
         │     │            └────────────────┘  │ sku (UNIQUE)    │
         │     │                                └──┬───────────┬──┘
         │     │                                   │ FK        │ FK
         │     │                                   │           │
         │     │            ┌──────────────────────┼───────────┼────────────┐
         │     │            │                      │           │            │
         │     │            │              ┌───────▼─────┐ ┌───▼────────┐  │
         │     │            │              │  inventory  │ │   prices   │  │
         │     │            │              │─────────────│ │────────────│  │
         │     │            │              │variant_id PK│ │ price_id PK│  │
         │     │            │              │ quantity    │ │ product_id │  │
         │     │            │              │ updated_at  │ │ variant_id │  │
         │     │            │              └─────────────┘ │ segment    │  │
         │     │            │                              │ price_cents│  │
         │     │            │                              │ valid_from │  │
         │     │            │                              └────────────┘  │

┌────────┴──────────────────┬──────┴──────────────────────────────────────────┐
│            USER-GENERATED CONTENT                                            │
└──────────────────────────────────────────────────────────────────────────────┘

         │                   │
         │ FK                │ FK (both users & products)
         │                   │
    ┌────▼───────────────┐  │          ┌──────────────────┐
    │user_preferences    │  └──────────►│product_reviews   │
    │────────────────────│              │──────────────────│
    │ user_id (PK,FK)    │              │ review_id (PK)   │
    │ preferences (JSON) │              │ product_id (FK)  │
    │ schema_version     │              │ user_id (FK)     │
    │ updated_at         │              │ rating (1-5)     │
    └────────────────────┘              │ title            │
                                        │ body             │
                                        │ verified         │
                                        └──────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                      DISCOUNTS & PROMOTIONS                                  │
└─────────────────────────────────────────────────────────────────────────────┘

         ┌──────────────┐              ┌───────────────┐
         │   coupons    │              │  promotions   │
         │──────────────│              │───────────────│
         │ coupon_id PK │              │promotion_id PK│
         │ code (UNIQUE)│              │ name          │
         │ type         │              │ type          │
         │ value        │              │ value         │
         │ valid_from   │              │ scope_json    │
         │ valid_to     │              │ priority      │
         │ scope (JSON) │              │ valid_from    │
         └──────┬───────┘              │ valid_to      │
                │                      └───────────────┘
                │ FK

┌───────────────┴──────────────────────────────────────────────────────────────┐
│                      SHOPPING CART & CHECKOUT                                 │
└───────────────────────────────────────────────────────────────────────────────┘

         │                   ┌────────────────┐
         │              ┌────┤     carts      │
         │              │    │────────────────│
         │              │    │ cart_id (PK)   │
         │          FK  │    │ user_id (FK) ──┼──────┐
         │              │    │ status         │      │
         │              │    │ created_at     │      │ FK to users
         │              │    └───┬─────┬──────┘      │
         │              │        │     │             │
         │              │    FK  │     │ FK          │
         │              │        │     │             │
         │      ┌───────▼────────▼──┐  │             │
         │      │ applied_coupons   │  │             │
         │      │───────────────────│  │             │
         └──────┤ cart_id (PK,FK)   │  │             │
                │ coupon_id (FK)    │  │             │
                │ applied_at        │  │             │
                └───────────────────┘  │             │
                                       │             │
                                  ┌────▼─────────┐   │
                                  │  cart_items  │   │
                                  │──────────────│   │
                                  │cart_item_id  │   │
                                  │ cart_id (FK) │   │
                                  │ variant_id ──┼───┼─── FK to product_variants
                                  │ quantity     │   │
                                  └──────────────┘   │

┌───────────────────────────────────────────────────────────────────────────────┐
│                      ORDERS & FULFILLMENT                                      │
└───────────────────────────────────────────────────────────────────────────────┘

                                       │
                            FK (users) │
                                       │
                              ┌────────▼───────────────┐
                              │       orders           │
                              │────────────────────────│
                              │ order_id (PK)          │
                              │ user_id (FK)           │
                              │ cart_id (FK) ──────────┼───┐ FK to carts
                              │ status                 │   │
                              │ subtotal_cents         │   │
                              │ discount_cents         │   │
                              │ total_cents            │   │
                              │ coupon_id (FK nullable)│   │
                              │ applied_coupon_* ──────┼───┼─ coupon snapshot
                              │ created_at             │   │
                              └──┬──────────────────┬──┘   │
                                 │                  │      │
                                 │ FK               │ FK   │
                                 │                  │      │
                        ┌────────▼────────┐  ┌──────▼──────▼──────────┐
                        │  order_items    │  │transactional_emails    │
                        │─────────────────│  │────────────────────────│
                        │order_item_id PK │  │ email_id (PK)          │
                        │ order_id (FK)   │  │ order_id (FK)          │
                        │ variant_id (FK) │  │ user_id (FK)           │
                        │ product_id (FK) │  │ type                   │
                        │ quantity        │  │ to_address             │
                        │ unit_price_cents│  │ subject                │
                        │ discount_cents  │  │ body_html              │
                        │ snapshot_*      │  │ rendered_at            │
                        └─────────────────┘  └────────────────────────┘
                        (frozen product
                         details at time
                         of purchase)

┌───────────────────────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE                                            │
└───────────────────────────────────────────────────────────────────────────────┘

                              ┌────────────────────┐
                              │ idempotency_keys   │
                              │────────────────────│
                              │ key (PK composite) │
                              │ user_id (PK,FK)    │
                              │ request_method PK  │
                              │ request_path PK    │
                              │ request_hash       │
                              │ response_status    │
                              │ response_body JSON │
                              │ created_at         │
                              └────────────────────┘
```

## Table Count by Category

| Category | Tables | Purpose |
|----------|--------|---------|
| **Foundation** | 2 | `categories`, `loyalty_tiers` |
| **User Management** | 2 | `users`, `user_preferences` |
| **Product Catalog** | 4 | `products`, `product_variants`, `product_images`, `product_reviews` |
| **Inventory & Pricing** | 2 | `inventory`, `prices` |
| **Promotions** | 2 | `coupons`, `promotions` |
| **Shopping Cart** | 3 | `carts`, `cart_items`, `applied_coupons` |
| **Orders** | 3 | `orders`, `order_items`, `transactional_emails` |
| **Infrastructure** | 1 | `idempotency_keys` |
| **Total** | **19** | Layer 1 Commerce only |

## Key Foreign Key Relationships

### Products & Variants
- `products.category` → `categories.slug`
- `product_variants.product_id` → `products.product_id`
- `product_images.product_id` → `products.product_id`
- `inventory.variant_id` → `product_variants.variant_id`
- `prices.product_id` → `products.product_id`
- `prices.variant_id` → `product_variants.variant_id` (nullable)

### Users
- `users.loyalty_tier_id` → `loyalty_tiers.tier_id`
- `user_preferences.user_id` → `users.user_id`
- `product_reviews.user_id` → `users.user_id`

### Shopping Flow
- `carts.user_id` → `users.user_id`
- `cart_items.cart_id` → `carts.cart_id` (CASCADE DELETE)
- `cart_items.variant_id` → `product_variants.variant_id`
- `applied_coupons.cart_id` → `carts.cart_id` (CASCADE DELETE)
- `applied_coupons.coupon_id` → `coupons.coupon_id`

### Orders
- `orders.user_id` → `users.user_id`
- `orders.cart_id` → `carts.cart_id` (UNIQUE)
- `orders.coupon_id` → `coupons.coupon_id` (nullable)
- `order_items.order_id` → `orders.order_id`
- `order_items.variant_id` → `product_variants.variant_id`
- `order_items.product_id` → `products.product_id`
- `transactional_emails.order_id` → `orders.order_id` (CASCADE DELETE)
- `transactional_emails.user_id` → `users.user_id`

## Cascade Delete Rules

| Parent → Child | Action | Reason |
|----------------|--------|--------|
| `carts` → `cart_items` | CASCADE | Cart items are owned by cart |
| `carts` → `applied_coupons` | CASCADE | Coupon application is cart-scoped |
| `orders` → `transactional_emails` | CASCADE | Email audit trail follows order |
| All other FKs | RESTRICT | Prevent orphaned references |

## Unique Constraints

| Table | Constraint | Purpose |
|-------|------------|---------|
| `categories` | `slug` | SEO-friendly URLs |
| `products` | `slug` | SEO-friendly URLs |
| `product_variants` | `sku` | Inventory tracking |
| `product_variants` | `(product_id, size, color)` | No duplicate variants |
| `coupons` | `code` | User-facing coupon codes |
| `carts` | `(user_id, status='active')` | One active cart per user |
| `cart_items` | `(cart_id, variant_id)` | One line per variant per cart |
| `orders` | `cart_id` | One order per cart |
| `order_items` | `(order_id, variant_id)` | One line per variant per order |
| `product_reviews` | `(user_id, product_id)` | One review per user per product |
| `loyalty_tiers` | `sort_order` | Tier hierarchy |

## Notes

- All monetary values stored as **integer cents** (`*_cents` columns)
- All IDs use **ULID format** with type prefixes (`prd_`, `usr_`, `ord_`, etc.)
- JSON columns use MySQL 5.7+ native JSON type
- Timestamps use `TIMESTAMP` (UTC recommended in application layer)
- Character set: `utf8mb4` for full Unicode support including emoji
