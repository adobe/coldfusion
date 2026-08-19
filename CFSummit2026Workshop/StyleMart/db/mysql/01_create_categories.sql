-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 01_create_categories.sql
-- Description: Categories table (foundation for product foreign keys)

USE stylemart;

CREATE TABLE categories (
  slug VARCHAR(80) PRIMARY KEY,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  hero_image VARCHAR(500),
  parent_slug VARCHAR(80),
  sort_order INT NOT NULL DEFAULT 0,

  -- Constraints
  CONSTRAINT ck_categories_slug_format
    CHECK (slug REGEXP '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT ck_categories_parent_not_self
    CHECK (parent_slug IS NULL OR parent_slug <> slug),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_slug) REFERENCES categories(slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_categories_parent ON categories(parent_slug);

-- Comments
ALTER TABLE categories COMMENT = 'Product categories with hierarchical structure';
