# StyleMart MySQL Database - Quick Start Guide

## Prerequisites

- MySQL 5.7+ or MySQL 8.0+
- MySQL root or admin access
- MySQL client (`mysql` command-line tool)

## Installation Steps

### 1. Create the Database and Tables

Run the master script to create everything:

```bash
cd /Applications/cf2025/cfusion/wwwroot/stylemart/db/mysql
mysql -u root -p < 99_run_all.sql
```

Enter your MySQL root password when prompted.

### 2. Verify Installation

Check that all tables were created:

```bash
mysql -u root -p -e "USE stylemart; SHOW TABLES;"
```

You should see 19 tables:
- applied_coupons
- cart_items
- carts
- categories
- coupons
- idempotency_keys
- inventory
- loyalty_tiers
- order_items
- orders
- prices
- product_images
- product_reviews
- product_variants
- products
- promotions
- transactional_emails
- user_preferences
- users

### 3. Create Application Database User (Recommended)

For security, create a dedicated user for the application:

```sql
-- Connect as root
mysql -u root -p

-- Create user
CREATE USER 'stylemart_app'@'localhost' IDENTIFIED BY 'your_secure_password';

-- Grant privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON stylemart.* TO 'stylemart_app'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Exit
EXIT;
```

### 4. Test Connection

```bash
mysql -u stylemart_app -p stylemart -e "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'stylemart';"
```

Should return: `table_count: 19`

## ColdFusion Datasource Configuration

### Using Administrator UI

1. Open ColdFusion Administrator: `http://localhost:8500/CFIDE/administrator/`
2. Navigate to: **Data & Services → Data Sources**
3. Add New Data Source:
   - **Data Source Name:** `stylemart`
   - **Driver:** MySQL (4/5)
   - Click **Add**

4. Configure Connection:
   - **Database:** `stylemart`
   - **Server:** `localhost` (or your MySQL host)
   - **Port:** `3306`
   - **Username:** `stylemart_app` (or your MySQL user)
   - **Password:** (your database password)
   
5. Advanced Settings (recommended):
   - **Limit Connections:** Check this
   - **Maintain Connections:** Check this
   - **Timeout:** 20 minutes
   - **Connection String:** (leave empty unless needed)

6. Click **Submit**

7. Verify by clicking **Verify** button

### Using Application.cfc

Alternatively, define the datasource in your `Application.cfc`:

```cfml
component {
    this.name = "StyleMart";
    this.datasource = "stylemart";
    
    this.datasources["stylemart"] = {
        class: 'com.mysql.cj.jdbc.Driver',
        connectionString: 'jdbc:mysql://localhost:3306/stylemart?useUnicode=true&characterEncoding=UTF-8',
        username: 'stylemart_app',
        password: encrypted('your_encrypted_password')
    };
}
```

## Sample Queries to Test

### Check Categories

```sql
SELECT * FROM categories LIMIT 5;
```

### Check Products

```sql
SELECT product_id, name, brand, base_price_cents/100 as price_dollars
FROM products
LIMIT 5;
```

### Check Users

```sql
SELECT user_id, display_name, email
FROM users
LIMIT 5;
```

## Loading Sample Data

The schema is now ready for data. You'll need to:

1. **Seed Foundation Tables First:**
   - `categories` (e.g., 'jackets', 'shirts', 'pants')
   - `loyalty_tiers` (e.g., 'tier_bronze', 'tier_silver', 'tier_gold')

2. **Seed Users:**
   - Test users with `usr_` prefix IDs

3. **Seed Products:**
   - Products with `prd_` prefix IDs
   - Must reference existing categories

4. **Seed Product Variants:**
   - Size/color combinations with `var_` prefix IDs
   - Must reference existing products

5. **Seed Inventory:**
   - Stock levels for each variant

Example seed order:
```sql
-- 1. Categories
INSERT INTO categories (slug, display_name, sort_order)
VALUES ('jackets', 'Jackets', 1);

-- 2. Loyalty tiers
INSERT INTO loyalty_tiers (tier_id, display_name, discount_pct, spend_threshold_cents, sort_order)
VALUES ('tier_bronze', 'Bronze', 5.00, 0, 1);

-- 3. Users
INSERT INTO users (user_id, display_name, email, loyalty_tier_id)
VALUES ('usr_demo_001', 'Demo User', 'demo@example.com', 'tier_bronze');

-- 4. Products
INSERT INTO products (product_id, slug, name, category, base_price_cents, image_url)
VALUES ('prd_01abc123', 'travel-blazer-01abc', 'Travel Blazer', 'jackets', 18900, '/img/blazer.jpg');

-- 5. Variants
INSERT INTO product_variants (variant_id, product_id, size, color, sku)
VALUES ('var_01xyz789', 'prd_01abc123', 'M', 'Navy', 'BLZ-M-NVY-001');

-- 6. Inventory
INSERT INTO inventory (variant_id, quantity)
VALUES ('var_01xyz789', 25);
```

## Troubleshooting

### Error: "Unknown database 'stylemart'"

The database wasn't created. Run:
```bash
mysql -u root -p < 00_create_database.sql
```

### Error: "Table 'X' doesn't exist"

Tables weren't created in order. Run the full master script:
```bash
mysql -u root -p < 99_run_all.sql
```

### Error: "Cannot add foreign key constraint"

Tables were created out of order. Drop and recreate:
```bash
mysql -u root -p < drop_all.sql
mysql -u root -p < 99_run_all.sql
```

### Error: "Access denied for user"

Check your MySQL credentials and user privileges:
```sql
SHOW GRANTS FOR 'your_username'@'localhost';
```

## Reset Database

To completely reset (WARNING: destroys all data):

```bash
mysql -u root -p < drop_all.sql
mysql -u root -p < 99_run_all.sql
```

## Next Steps

1. ✅ Database created
2. ✅ Tables created
3. ⬜ Load seed data (categories, products, users)
4. ⬜ Configure ColdFusion datasource
5. ⬜ Test CFML queries
6. ⬜ Build REST API endpoints
7. ⬜ Build frontend UI

## Support Files

- `README.md` - Detailed documentation
- `SCHEMA_DIAGRAM.md` - Visual entity relationships
- `99_run_all.sql` - Master installation script
- `drop_all.sql` - Reset/cleanup script
- Individual `0X_*.sql` files - Individual table creation scripts

## Getting Help

- Review schema documentation: `README.md`
- View relationships: `SCHEMA_DIAGRAM.md`
