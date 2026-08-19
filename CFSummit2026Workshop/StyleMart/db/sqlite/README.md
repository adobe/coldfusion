# StyleMart — SQLite build

This directory ships a SQLite build of the StyleMart app. Only the StyleMart app uses SQLite; the `prologics` external service stays on MySQL.

## Why SQLite?

Workshop attendees can clone the repo, run one script, and have a working dev DB without installing MySQL. The schema, seed data, and behavior match the MySQL build closely enough that the CF code is unchanged on read paths and trivially patched on the writes that used MySQL-specific syntax (`ON DUPLICATE KEY UPDATE` → `ON CONFLICT … DO UPDATE`, `JSON_EXTRACT`/`JSON_UNQUOTE` → `json_extract`).

## Files in this directory

| File | Role |
|---|---|
| `stylemart.sql` | Single-file build script — DDL + seed + post-seed cleanup. |
| `stylemart.db`  | Pre-built SQLite database (committed for one-step setup). |
| `init.sh`       | Drops + rebuilds `stylemart.db` from `stylemart.sql`. |
| `README.md`     | This file. |

## Quick start

`stylemart.db` is checked in, so you can point CF at it immediately. To rebuild from scratch:

```bash
cd StyleMart/db/sqlite
bash init.sh
# → writes stylemart.db here
```

The default DB path is `StyleMart/db/sqlite/stylemart.db`. Pass an absolute path if you want it elsewhere.

Counts after bootstrap:

| Table | Rows |
|---|---|
| categories       |  15 |
| loyalty_tiers    |   3 |
| users            |   5 |
| products         | 200 |
| product_variants | 770 |
| product_images   | 400 |
| inventory        | 770 |
| coupons          |   3 |
| promotions       |   2 |
| product_reviews  | 600 |

## Pointing CF at the SQLite DB

ColdFusion talks to SQLite via the xerial `sqlite-jdbc` driver as a generic "Other" datasource.

### One-time install

1. Download `sqlite-jdbc-3.45.x.jar` from [github.com/xerial/sqlite-jdbc/releases](https://github.com/xerial/sqlite-jdbc/releases).
2. Drop it in `cfusion/lib/`.
3. Restart ColdFusion.

### Datasource setup (CF Admin → Data Sources → Add)

- **Name**: `stylemart`
- **Driver**: Other
- **JDBC URL**: `jdbc:sqlite:/Users/vikyada/Adobe/CodeBase/cf-main/cfusion/wwwroot/CFSummit2026Workshop/StyleMart/db/sqlite/stylemart.db?journal_mode=WAL&busy_timeout=5000&foreign_keys=on`
  - Adjust the absolute path if your checkout is elsewhere.
- **Driver Class**: `org.sqlite.JDBC`
- **Driver Name**: `SQLite`
- **CF SQL Type**: leave blank
- **Username** / **Password**: leave blank

Click *Verify*. Should be green.

### Why those URL params

| Param | Effect |
|---|---|
| `journal_mode=WAL`     | One writer + N concurrent readers (vs default rollback journal which serializes). |
| `busy_timeout=5000`    | When the DB is locked by another writer, block up to 5 s before throwing `database is locked`. |
| `foreign_keys=on`      | Enforce FK constraints (off by default in SQLite). |

## Concurrency caveats

`agent_traces` is the only write-hot table — every SSE event from the chat pipeline `INSERT`s a row. Under WAL, concurrent writers serialize; `busy_timeout=5000` makes that block up to 5 s before erroring. Fine for workshop demo loads (1–5 attendees). If contention shows up beyond ~20 concurrent chats:

- Bump `busy_timeout` higher.
- Or batch trace inserts in `api/agent/common/TraceEmitter.cfc` (write per turn instead of per frame).

## Rolling back to MySQL

The MySQL build (`db/mysql/`) is untouched. To revert: in CF Admin, edit the `stylemart` datasource and change Type back to MySQL with the original JDBC URL. No CFML code changes needed.

## What's inside `stylemart.sql`

In order:

1. `PRAGMA` setup (`foreign_keys=OFF` during seed, WAL, busy_timeout).
2. DDL — all 16 tables (`categories`, `products`, `product_variants`, `product_images`, `users`, `loyalty_tiers`, `user_preferences`, `product_reviews`, `inventory`, `prices`, `coupons`, `promotions`, `carts`/`cart_items`, `orders`/`order_items`/`order_addresses`, `transactional_emails`, `idempotency_keys`, `agent_traces`, `rag_documents`/`rag_chunks`, `generated_assets`, `guardrail_events`).
3. Seed data — 200 products, 770 variants, 400 images, 770 inventory rows, 5 users, 600 reviews, 3 coupons, 2 promotions.
4. Post-seed cleanup — strips rogue-color variants (mirrors `db/mysql/migrations/2026-05-29-…`), prunes orphan inventory/cart/price rows, then `PRAGMA foreign_keys = ON`.

A handful of MySQL seed `INSERT`s reference duplicate-SKU variants that SQLite's stricter UNIQUE handling rejects (10 rows out of 780). The build uses `INSERT OR IGNORE` for variants and inventory, then deletes orphan inventory rows before turning FKs back on. Net data invariants (single distinct color per product) hold.
