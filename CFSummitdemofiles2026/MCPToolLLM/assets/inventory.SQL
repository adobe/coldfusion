IF OBJECT_ID('dbo.inventory_reorder_view', 'V') IS NOT NULL
    DROP VIEW dbo.inventory_reorder_view;
GO

IF OBJECT_ID('dbo.inventory_items', 'U') IS NOT NULL
    DROP TABLE dbo.inventory_items;
GO

CREATE TABLE dbo.inventory_items (
    item_id INT IDENTITY(1,1) PRIMARY KEY,

    item_name NVARCHAR(150) NOT NULL,
    sku NVARCHAR(40) NOT NULL UNIQUE,

    category NVARCHAR(80) NOT NULL,
    warehouse NVARCHAR(80) NOT NULL,

    quantity_on_hand INT NOT NULL DEFAULT 0,
    reorder_threshold INT NOT NULL DEFAULT 5,
    reorder_quantity INT NOT NULL DEFAULT 10,

    stock_status NVARCHAR(30) NOT NULL,
    lead_time_days INT NOT NULL,

    supplier NVARCHAR(120) NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    last_ordered_date DATE NULL,
    notes NVARCHAR(MAX) NULL,

    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX idx_inventory_category
ON dbo.inventory_items(category);

CREATE INDEX idx_inventory_warehouse
ON dbo.inventory_items(warehouse);

CREATE INDEX idx_inventory_stock_status
ON dbo.inventory_items(stock_status);

CREATE INDEX idx_inventory_supplier
ON dbo.inventory_items(supplier);
GO

INSERT INTO dbo.inventory_items
(
    item_name,
    sku,
    category,
    warehouse,
    quantity_on_hand,
    reorder_threshold,
    reorder_quantity,
    stock_status,
    lead_time_days,
    supplier,
    unit_cost,
    last_ordered_date,
    notes
)
VALUES
('USB-C Hub 7-port', 'MUC-EL-001', 'Electronics', 'Munich', 4, 6, 12, 'Low Stock', 18, 'TechDist GmbH', 39.99, '2026-04-28', 'Visible in mockup. Low stock item.'),
('Mechanical Keyboard MX', 'MUC-EL-002', 'Electronics', 'Munich', 0, 5, 10, 'Out of Stock', 21, 'KeyCo Europe', 89.99, '2026-04-20', 'Visible in mockup. Out of stock item requiring reorder.'),
('27in 4K Monitor', 'MUC-EL-003', 'Electronics', 'Munich', 8, 10, 12, 'Low Stock', 14, 'DisplayPro', 249.99, '2026-04-26', 'Visible in mockup. Low stock display item.'),
('Webcam HD 1080p', 'MUC-EL-004', 'Electronics', 'Munich', 23, 8, 20, 'In Stock', 7, 'TechDist GmbH', 49.99, '2026-05-03', 'Visible in mockup. Standard video accessory.'),
('Standing Desk Pro', 'MUC-OF-001', 'Office', 'Munich', 6, 8, 10, 'Low Stock', 16, 'FurnishCo', 399.00, '2026-04-22', 'Visible in mockup. Low stock office furniture.'),
('Ergonomic Chair', 'MUC-OF-002', 'Office', 'Munich', 14, 6, 12, 'In Stock', 9, 'FurnishCo', 219.00, '2026-05-02', 'Visible in mockup. Office seating.'),

('Laptop Stand Aluminium', 'BER-EL-001', 'Electronics', 'Berlin', 3, 6, 12, 'Critical', 22, 'TechDist GmbH', 44.99, '2026-04-18', 'Visible in mockup. Critical stock item.'),
('Noise-Cancel Headphones', 'BER-EL-002', 'Electronics', 'Berlin', 11, 6, 10, 'In Stock', 11, 'AudioPro', 129.99, '2026-04-30', 'Visible in mockup. Audio accessory.'),
('Wireless Mouse', 'BER-EL-003', 'Electronics', 'Berlin', 7, 10, 20, 'Low Stock', 8, 'PeriphX', 24.99, '2026-05-01', 'Visible in mockup. Low stock peripheral.'),
('Monitor Arm Dual', 'BER-OF-001', 'Office', 'Berlin', 0, 4, 8, 'Out of Stock', 19, 'MountCo', 79.99, '2026-04-21', 'Visible in mockup. Out of stock item requiring reorder.'),
('Cable Management Kit', 'BER-OF-002', 'Office', 'Berlin', 34, 10, 25, 'In Stock', 5, 'OfficeSup', 14.99, '2026-05-05', 'Visible in mockup. Desk organization supply.'),
('Storage Cabinet A4', 'BER-ST-001', 'Storage', 'Berlin', 9, 10, 10, 'In Stock', 12, 'StorePlus', 149.00, '2026-04-25', 'Visible in mockup. Storage item near reorder threshold.'),

('USB-C Dock Thunderbolt', 'VIE-EL-001', 'Electronics', 'Vienna', 2, 6, 12, 'Critical', 24, 'TechDist GmbH', 119.99, '2026-04-17', 'Visible in mockup. Critical stock item.'),
('Smart Power Strip', 'VIE-EL-002', 'Electronics', 'Vienna', 18, 8, 20, 'In Stock', 7, 'PowerPro', 34.50, '2026-05-02', 'Visible in mockup. Desk power accessory.'),
('Raspberry Pi 4 Kit', 'VIE-EL-003', 'Electronics', 'Vienna', 5, 8, 15, 'Low Stock', 16, 'MakerDist', 74.99, '2026-04-19', 'Visible in mockup. Low stock lab/prototype kit.'),
('Whiteboard Magnetic 120cm', 'VIE-OF-001', 'Office', 'Vienna', 12, 4, 10, 'In Stock', 8, 'OfficeWorld', 59.00, '2026-05-07', 'Visible in mockup. Meeting room supply.');
GO

CREATE VIEW dbo.inventory_reorder_view AS
SELECT
    item_id,
    item_name,
    sku,
    category,
    warehouse,
    quantity_on_hand,
    reorder_threshold,
    reorder_quantity,
    stock_status,
    lead_time_days,
    supplier,
    unit_cost,
    CAST(reorder_quantity * unit_cost AS DECIMAL(10,2)) AS estimated_reorder_cost,
    notes
FROM dbo.inventory_items
WHERE
    quantity_on_hand <= reorder_threshold
    OR stock_status IN ('Critical', 'Low Stock', 'Out of Stock');
GO