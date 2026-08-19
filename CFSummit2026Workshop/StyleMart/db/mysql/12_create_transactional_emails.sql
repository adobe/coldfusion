-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 12_create_transactional_emails.sql
-- Description: Transactional emails table (depends on orders and users)

USE stylemart;

CREATE TABLE transactional_emails (
  email_id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(50) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  type VARCHAR(50) NOT NULL,
  to_address VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  body_html LONGTEXT NOT NULL,
  rendered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_emails_type
    CHECK (type IN ('order-confirmation')),
  CONSTRAINT fk_emails_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_emails_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX ix_emails_order ON transactional_emails(order_id);

-- Comments
ALTER TABLE transactional_emails COMMENT = 'Template-rendered transactional emails (Layer 1)';
