-- drop_all.sql
-- Drops all ProLogics tables and database. Run to reset from scratch.

USE prologics;

DROP TABLE IF EXISTS shipment_items;
DROP TABLE IF EXISTS shipment_events;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS customers;

DROP DATABASE IF EXISTS prologics;
