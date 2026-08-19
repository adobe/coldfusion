-- 20_create_prologics.sql
-- ProLogics LLC — Third-party logistics database for S4 MCP demo.
-- Separate datasource "prologics" must be configured in CF Admin.

CREATE DATABASE IF NOT EXISTS prologics
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE prologics;

CREATE TABLE IF NOT EXISTS customers (
    customer_id   VARCHAR(64) PRIMARY KEY,
    shopper_id    VARCHAR(64) NOT NULL,
    full_name     VARCHAR(128) NOT NULL,
    address_line1 VARCHAR(256) NOT NULL,
    address_line2 VARCHAR(256) DEFAULT '',
    city          VARCHAR(64) NOT NULL,
    state         VARCHAR(64) DEFAULT '',
    postal_code   VARCHAR(16) NOT NULL,
    country       VARCHAR(2) NOT NULL DEFAULT 'US',
    phone         VARCHAR(20),
    email         VARCHAR(128),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_customers_shopper (shopper_id)
);

CREATE TABLE IF NOT EXISTS shipments (
    shipment_id        VARCHAR(64) PRIMARY KEY,
    order_id           VARCHAR(64) NOT NULL,
    tracking_number    VARCHAR(64),
    carrier            VARCHAR(32) DEFAULT 'prologics',
    status             VARCHAR(32) NOT NULL DEFAULT 'received',
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estimated_delivery DATE,
    actual_delivery    DATE,
    KEY idx_shipments_order (order_id)
);

CREATE TABLE IF NOT EXISTS shipment_events (
    event_id    VARCHAR(64) PRIMARY KEY,
    shipment_id VARCHAR(64) NOT NULL,
    status      VARCHAR(32) NOT NULL,
    location    VARCHAR(128),
    notes       VARCHAR(256),
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_events_shipment (shipment_id),
    CONSTRAINT fk_events_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

CREATE TABLE IF NOT EXISTS shipment_items (
    shipment_id VARCHAR(64) NOT NULL,
    product_id  VARCHAR(64) NOT NULL,
    variant_id  VARCHAR(64),
    quantity    INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (shipment_id, product_id, variant_id),
    CONSTRAINT fk_items_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

-- Seed: demo customer (correlates with StyleMart usr_demo_001)
INSERT INTO customers (customer_id, shopper_id, full_name, address_line1, city, state, postal_code, country, email)
VALUES ('cst_001', 'usr_demo_001', 'Jordan Demo', '123 Fashion Ave', 'New York', 'NY', '10001', 'US', 'jordan@demo.com');

-- Seed: shipments (order_ids must match StyleMart orders table)
INSERT INTO shipments (shipment_id, order_id, tracking_number, carrier, status, estimated_delivery, actual_delivery)
VALUES
  ('shp_001', 'ord_01HZX_RECENT1', 'PL-2026-78432', 'prologics', 'in_transit', '2026-06-07', NULL),
  ('shp_002', 'ord_01HZX_RECENT2', 'PL-2026-78433', 'prologics', 'delivered',  '2026-05-28', '2026-05-27');

-- Seed: shipment event timeline
INSERT INTO shipment_events (event_id, shipment_id, status, location, notes, occurred_at) VALUES
  ('evt_001', 'shp_001', 'received',   'ProLogics NYC Hub',    'Order received from StyleMart', '2026-06-01 09:00:00'),
  ('evt_002', 'shp_001', 'processing', 'ProLogics NYC Hub',    'Picking items',                 '2026-06-01 14:00:00'),
  ('evt_003', 'shp_001', 'packed',     'ProLogics NYC Hub',    'Package sealed',                '2026-06-02 10:00:00'),
  ('evt_004', 'shp_001', 'in_transit', 'ProLogics Sort NJ',    'In transit to destination',     '2026-06-03 06:00:00'),
  ('evt_005', 'shp_002', 'received',   'ProLogics NYC Hub',    'Order received',                '2026-05-24 08:00:00'),
  ('evt_006', 'shp_002', 'delivered',  'Customer doorstep',    'Delivered — signed',            '2026-05-27 14:30:00');

-- Seed: items in each shipment
INSERT INTO shipment_items (shipment_id, product_id, variant_id, quantity) VALUES
  ('shp_001', 'prd_01HZX01T001', 'prd_01HZX01T001-M-navy',  1),
  ('shp_001', 'prd_01HZX01T005', 'prd_01HZX01T005-32-dark', 1),
  ('shp_002', 'prd_01HZX01T003', 'prd_01HZX01T003-M-white', 2);
