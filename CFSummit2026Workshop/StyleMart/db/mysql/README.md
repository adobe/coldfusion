# StyleMart MySQL Database Schema

This directory contains MySQL database schema scripts for the StyleMart e-commerce application, converted from the project's PostgreSQL schema design.

## Overview

The schema implements **Layer 1 - E-Commerce** tables only (commerce functionality without AI features). Layer 2 tables (chat, AI agent, RAG) are intentionally excluded from this initial implementation.

## Files

| File | Description |
|------|-------------|
| `00_create_database.sql` | Creates the `stylemart` database with UTF-8 configuration |
| `01_create_categories.sql` | Categories table (foundation for products) |
| `02_create_products.sql` | Products catalog table |
| `03_create_product_variants.sql` | Product size/color variants |
| `04_create_product_images.sql` | Product image gallery |
| `05_create_users_and_loyalty.sql` | Loyalty tiers and user accounts |
| `06_create_user_preferences.sql` | User shopping preferences |
| `07_create_product_reviews.sql` | Product reviews and ratings |
| `08_create_inventory_and_pricing.sql` | Inventory tracking and dynamic pricing |
| `09_create_coupons_and_promotions.sql` | Discount coupons and promotions |
| `10_create_carts.sql` | Shopping carts, cart items, and applied coupons |
| `11_create_orders.sql` | Orders and order line items |
| `12_create_transactional_emails.sql` | Transactional email audit log |
| `13_create_idempotency_keys.sql` | API request idempotency tracking |
| `99_run_all.sql` | Master script to run all files in order |

## Quick Start

### Option 1: Run Master Script (Recommended)

```bash
mysql -u root -p < 99_run_all.sql
```

This will create the database and all tables in the correct dependency order.

### Option 2: Run Individual Scripts

```bash
mysql -u root -p < 00_create_database.sql
mysql -u root -p stylemart < 01_create_categories.sql
mysql -u root -p stylemart < 02_create_products.sql
# ... continue in numerical order
```

## Table Dependencies

The tables must be created in this dependency order:

```
1. categories (foundation)
2. loyalty_tiers (foundation)
3. users (depends on: loyalty_tiers)
4. products (depends on: categories)
5. product_variants (depends on: products)
6. product_images (depends on: products)
7. user_preferences (depends on: users)
8. product_reviews (depends on: products, users)
9. inventory (depends on: product_variants)
10. prices (depends on: products, product_variants)
11. coupons (foundation)
12. promotions (foundation)
13. carts (depends on: users)
14. cart_items (depends on: carts, product_variants)
15. applied_coupons (depends on: carts, coupons)
16. orders (depends on: users, carts, coupons)
17. order_items (depends on: orders, products, product_variants)
18. transactional_emails (depends on: orders, users)
19. idempotency_keys (depends on: users)
```

## Key Schema Elements

### ID Prefixes (ULIDs)
All primary keys use prefixed ULIDs:
- `prd_*` - Products
- `var_*` - Variants
- `usr_*` - Users
- `crt_*` - Carts
- `ord_*` - Orders
- `cpn_*` - Coupons
- `pro_*` - Promotions
- `rev_*` - Reviews

### Money Storage
All monetary values are stored as **integer cents** in columns ending with `_cents`:
- `base_price_cents`, `unit_price_cents`, `total_cents`, etc.
- Currency is always `USD` in workshop scope

### JSON Columns
MySQL 5.7+ JSON type is used for:
- `products.attributes` - Product attributes
- `products.occasion_tags` - Occasion tags array
- `user_preferences.preferences` - User preference data
- `coupons.conditions_json` - Coupon conditions
- `promotions.scope_json` - Promotion scope rules

### Timestamps
All timestamp columns use MySQL `TIMESTAMP` type with:
- `DEFAULT CURRENT_TIMESTAMP` for creation timestamps
- `ON UPDATE CURRENT_TIMESTAMP` for update timestamps

## MySQL-Specific Adaptations

This schema has been adapted from PostgreSQL with the following changes:

### Data Types
- `TEXT` → `VARCHAR(n)` or `TEXT` (with explicit lengths where needed)
- `TIMESTAMPTZ` → `TIMESTAMP` (MySQL doesn't have timezone-aware type)
- `JSONB` → `JSON` (MySQL unified JSON type)
- `TEXT[]` → `JSON` (arrays stored as JSON arrays)
- `NUMERIC(p,s)` → `DECIMAL(p,s)` (equivalent)

### Constraints
- Regex constraints: `~` operator → `REGEXP` function
- Array operations: `cardinality()` → validation moved to application layer
- Complex CHECK constraints: Some multi-column checks simplified
- `WHERE` clauses in indexes: Not supported, removed partial indexes

### Indexes
- GIN indexes: Not supported in MySQL, removed full-text on JSONB
- Partial indexes: Converted to regular indexes or removed
- Full-text search: Added `FULLTEXT` index on products(name, description)

### Functions
- PostgreSQL `validate_preferences_v1()` function: Validation moved to application layer
- `to_tsvector()`: Replaced with FULLTEXT index

### String Operations
- `char_length()` → `CHAR_LENGTH()` (same in MySQL)
- Case sensitivity: MySQL is case-insensitive by default for strings

## Database Configuration

The schema assumes:
- MySQL 5.7+ or MySQL 8.0+
- Character set: `utf8mb4`
- Collation: `utf8mb4_unicode_ci`
- SQL Mode: `STRICT_TRANS_TABLES` (enabled in 00_create_database.sql)
- Storage engine: `InnoDB` (supports foreign keys and transactions)

## Verification

After running the scripts, verify the installation:

```sql
USE stylemart;

-- List all tables
SHOW TABLES;

-- Check table structure
DESCRIBE products;
DESCRIBE categories;

-- Verify foreign keys
SELECT
  TABLE_NAME,
  CONSTRAINT_NAME,
  REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'stylemart'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

## Next Steps

1. **Seed Data**: Load initial data for categories, products, users
2. **Configure ColdFusion Datasource**: Point to `stylemart` database
3. **Test Connections**: Verify CFML can query the tables
4. **API Development**: Build REST endpoints per spec

## Notes

- This schema includes **only Layer 1 (Commerce)** tables
- Layer 2 (AI Agent) tables are excluded and would need separate scripts
- All CHECK constraints are enforced where MySQL supports them
- Some PostgreSQL-specific validations moved to application layer
- Foreign key constraints use `ON DELETE CASCADE` or `ON DELETE RESTRICT` per spec

