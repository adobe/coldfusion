#!/usr/bin/env bash
# ProLogics SQLite bootstrap.
# Builds prologics.db from scratch using prologics.sql (DDL + seed in one file).
#
# Usage:
#   bash init.sh                    # rebuilds ./prologics.db
#   bash init.sh /path/to/file.db   # rebuilds an arbitrary path

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${1:-${SCRIPT_DIR}/prologics.db}"
SQL_PATH="${SCRIPT_DIR}/prologics.sql"

echo "==> Removing existing DB at ${DB_PATH}"
rm -f "${DB_PATH}" "${DB_PATH}-wal" "${DB_PATH}-shm"

echo "==> Building DB from ${SQL_PATH}"
sqlite3 "${DB_PATH}" < "${SQL_PATH}"

echo "==> Verification"
sqlite3 "${DB_PATH}" <<'SQL'
.headers on
.mode column
SELECT 'customers'       AS tbl, COUNT(*) AS n FROM customers
UNION ALL SELECT 'shipments',       COUNT(*) FROM shipments
UNION ALL SELECT 'shipment_events', COUNT(*) FROM shipment_events
UNION ALL SELECT 'shipment_items',  COUNT(*) FROM shipment_items;
SQL

echo
echo "==> Done. DB at: ${DB_PATH}"
