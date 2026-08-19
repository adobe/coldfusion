-- ProLogics SQLite bootstrap — single-file build (DDL + seed).
-- Run with:  rm -f prologics.db && sqlite3 prologics.db < prologics.sql
--
-- SQLite notes:
--  - No CREATE DATABASE / USE — the .db file IS the database.
--  - MySQL VARCHAR(N) → TEXT (SQLite ignores length hints anyway).
--  - MySQL `KEY idx_x (col)` inline index → separate CREATE INDEX statements.
--  - TIMESTAMP DEFAULT CURRENT_TIMESTAMP → TEXT with strftime default
--    (matches StyleMart pattern; CF dateTimeFormat parses both formats).
--  - DATE columns kept as TEXT in 'YYYY-MM-DD' form (CF cf_sql_date binds fine).

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;

BEGIN;

CREATE TABLE customers (
    customer_id   TEXT PRIMARY KEY,
    shopper_id    TEXT NOT NULL,
    full_name     TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT DEFAULT '',
    city          TEXT NOT NULL,
    state         TEXT DEFAULT '',
    postal_code   TEXT NOT NULL,
    country       TEXT NOT NULL DEFAULT 'US',
    phone         TEXT,
    email         TEXT,
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now'))
);
CREATE INDEX idx_customers_shopper ON customers(shopper_id);

CREATE TABLE shipments (
    shipment_id        TEXT PRIMARY KEY,
    order_id           TEXT NOT NULL,
    tracking_number    TEXT,
    carrier            TEXT DEFAULT 'prologics',
    status             TEXT NOT NULL DEFAULT 'received',
    created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
    updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
    estimated_delivery TEXT,
    actual_delivery    TEXT
);
CREATE INDEX idx_shipments_order ON shipments(order_id);

CREATE TABLE shipment_events (
    event_id    TEXT PRIMARY KEY,
    shipment_id TEXT NOT NULL,
    status      TEXT NOT NULL,
    location    TEXT,
    notes       TEXT,
    occurred_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f','now')),
    CONSTRAINT fk_events_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);
CREATE INDEX idx_events_shipment ON shipment_events(shipment_id);

CREATE TABLE shipment_items (
    shipment_id TEXT NOT NULL,
    product_id  TEXT NOT NULL,
    variant_id  TEXT NOT NULL DEFAULT '',
    quantity    INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (shipment_id, product_id, variant_id),
    CONSTRAINT fk_items_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

-- Seed: demo customer (correlates with StyleMart usr_demo_001)
INSERT INTO customers (customer_id, shopper_id, full_name, address_line1, city, state, postal_code, country, email)
VALUES ('cst_001', 'usr_demo_001', 'Jordan Demo', '123 Fashion Ave', 'New York', 'NY', '10001', 'US', 'jordan@demo.com');

-- Seed: shipments (order_ids must match StyleMart orders table)
INSERT INTO shipments (shipment_id, order_id, tracking_number, carrier, status, estimated_delivery, actual_delivery) VALUES
  ('shp_001', 'ord_ecd33f2507af7011a043aa9a7c9c0f3c', 'PL-2026-78432', 'prologics', 'in_transit', '2026-06-08', NULL),
  ('shp_002', 'ord_ec80fdc2d02880f2165444ccc59aa143', 'PL-2026-78433', 'prologics', 'delivered',  '2026-05-30', '2026-05-29'),
  ('shp_003', 'ord_8061c7feb657d30b04e0bb1af40aa434', 'PL-2026-78434', 'prologics', 'processing', '2026-06-10', NULL);

-- Seed: shipment event timeline
INSERT INTO shipment_events (event_id, shipment_id, status, location, notes, occurred_at) VALUES
  ('evt_001', 'shp_001', 'received',   'ProLogics NYC Hub', 'Order received from StyleMart', '2026-06-01 09:00:00'),
  ('evt_002', 'shp_001', 'processing', 'ProLogics NYC Hub', 'Picking items',                 '2026-06-02 14:00:00'),
  ('evt_003', 'shp_001', 'packed',     'ProLogics NYC Hub', 'Package sealed',                '2026-06-03 10:00:00'),
  ('evt_004', 'shp_001', 'in_transit', 'ProLogics Sort NJ', 'In transit to destination',     '2026-06-04 06:00:00'),
  ('evt_005', 'shp_002', 'received',   'ProLogics NYC Hub', 'Order received',                '2026-05-25 08:00:00'),
  ('evt_006', 'shp_002', 'in_transit', 'ProLogics Sort NJ', 'Shipped',                       '2026-05-27 10:00:00'),
  ('evt_007', 'shp_002', 'delivered',  'Customer doorstep', 'Delivered - signed',            '2026-05-29 14:30:00'),
  ('evt_008', 'shp_003', 'received',   'ProLogics NYC Hub', 'Order received from StyleMart', '2026-06-04 11:00:00'),
  ('evt_009', 'shp_003', 'processing', 'ProLogics NYC Hub', 'Picking items from warehouse',  '2026-06-05 08:00:00');

-- Seed: items in each shipment
INSERT INTO shipment_items (shipment_id, product_id, variant_id, quantity) VALUES
  ('shp_001', 'prd_01HZX01T001', 'prd_01HZX01T001-M-navy',  1),
  ('shp_001', 'prd_01HZX01T005', 'prd_01HZX01T005-32-dark', 1),
  ('shp_002', 'prd_01HZX01T003', 'prd_01HZX01T003-M-white', 2),
  ('shp_003', 'prd_01HZX01T002', 'prd_01HZX01T002-L-black', 1);

COMMIT;
