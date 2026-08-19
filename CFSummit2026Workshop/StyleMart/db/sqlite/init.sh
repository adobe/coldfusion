#!/usr/bin/env bash
# StyleMart SQLite bootstrap.
# Builds stylemart.db from scratch using stylemart.sql (DDL + seed in one file).
#
# Usage:
#   bash init.sh                    # rebuilds ./stylemart.db
#   bash init.sh /path/to/file.db   # rebuilds an arbitrary path

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${1:-${SCRIPT_DIR}/stylemart.db}"
SQL_PATH="${SCRIPT_DIR}/stylemart.sql"

echo "==> Removing existing DB at ${DB_PATH}"
rm -f "${DB_PATH}" "${DB_PATH}-wal" "${DB_PATH}-shm"

echo "==> Building DB from ${SQL_PATH}"
sqlite3 "${DB_PATH}" < "${SQL_PATH}"

echo "==> Verification"
sqlite3 "${DB_PATH}" <<'SQL'
.headers on
.mode column
SELECT 'categories'        AS tbl, COUNT(*) AS n FROM categories
UNION ALL SELECT 'loyalty_tiers',     COUNT(*) FROM loyalty_tiers
UNION ALL SELECT 'users',             COUNT(*) FROM users
UNION ALL SELECT 'products',          COUNT(*) FROM products
UNION ALL SELECT 'product_variants',  COUNT(*) FROM product_variants
UNION ALL SELECT 'product_images',    COUNT(*) FROM product_images
UNION ALL SELECT 'inventory',         COUNT(*) FROM inventory
UNION ALL SELECT 'coupons',           COUNT(*) FROM coupons
UNION ALL SELECT 'promotions',        COUNT(*) FROM promotions
UNION ALL SELECT 'product_reviews',   COUNT(*) FROM product_reviews;
SELECT 'multi_color_products' AS check_name, COUNT(*) AS n
  FROM (SELECT product_id FROM product_variants GROUP BY product_id HAVING COUNT(DISTINCT color)>1);
SQL

echo
echo "==> Done. DB at: ${DB_PATH}"
