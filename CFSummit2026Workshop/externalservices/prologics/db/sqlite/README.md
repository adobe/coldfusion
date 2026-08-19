# ProLogics — SQLite build

This directory ships a SQLite build of the ProLogics third-party logistics service. The MySQL build (`db/mysql/`) remains untouched; SQLite is the new default so workshop attendees can run the app without installing MySQL.

## Files in this directory

| File | Role |
|---|---|
| `prologics.sql` | Single-file build script — DDL + seed. |
| `prologics.db`  | Pre-built SQLite database (committed for one-step setup). |
| `init.sh`       | Drops + rebuilds `prologics.db` from `prologics.sql`. |
| `README.md`     | This file. |

## Quick start

`prologics.db` is checked in, so CF will pick it up on app restart. To rebuild from scratch:

```bash
cd externalservices/prologics/db/sqlite
bash init.sh
# → writes prologics.db here
```

Counts after bootstrap:

| Table | Rows |
|---|---|
| customers       | 1 |
| shipments       | 3 |
| shipment_events | 9 |
| shipment_items  | 4 |

## How CF picks it up

`Application.cfc` calls `commonutils.db.DatasourceUtil.register("prologics", "config/db.properties")` on app start. The shared util reads `prologics.type` from `db.properties` and dispatches:

- `type=sqlite` → registers as a generic "Other" datasource using the xerial `sqlite-jdbc` driver.
- `type=mysql`  → registers via the MySQL5 helper.

The driver (`sqlite-jdbc-3.45.x.jar`) lives in `cfusion/lib/` and is shared with the StyleMart app — no separate install needed.

The JDBC URL is built as:

```
jdbc:sqlite:<absolute-path-to>/prologics.db?journal_mode=WAL&busy_timeout=5000&foreign_keys=on
```

| Param | Effect |
|---|---|
| `journal_mode=WAL`  | One writer + N concurrent readers. |
| `busy_timeout=5000` | When DB is locked, block up to 5 s before throwing. |
| `foreign_keys=on`   | Enforce FK constraints (off by default in SQLite). |

## Schema differences vs MySQL

- `VARCHAR(N)` → `TEXT` (SQLite ignores length hints anyway).
- Inline `KEY idx_x (col)` → separate `CREATE INDEX` statements.
- `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` → `TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now'))`. CF's `dateTimeFormat` parses this without changes.
- `DATE` columns stored as `'YYYY-MM-DD'` text. CF's `cf_sql_date` binding round-trips fine; `dateFormat` and `dateDiff` work as in MySQL.
- `shipment_items.variant_id` was `VARCHAR(64)` (nullable) in MySQL but is part of the composite PK — SQLite treats `NULL` PK parts as distinct, so it's now `TEXT NOT NULL DEFAULT ''` to match the existing CFML insert behaviour (which already passes `""` when missing).

CFML in `ShipmentService.cfc` is unchanged — all queries are standard SQL.

## Rolling back to MySQL

Edit `config/db.properties`:

1. Comment out the `prologics.type=sqlite` and `prologics.file=...` lines.
2. Uncomment the MySQL block.
3. Restart CF (or hit `?reload=1` to re-run `onApplicationStart`).

No CFML code changes needed.
