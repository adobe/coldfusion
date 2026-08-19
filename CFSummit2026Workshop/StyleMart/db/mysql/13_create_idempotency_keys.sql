-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 13_create_idempotency_keys.sql
-- Description: Idempotency keys for API request deduplication (depends on users)

USE stylemart;

CREATE TABLE idempotency_keys (
  `key` VARCHAR(128) NOT NULL,
  user_id VARCHAR(50) NOT NULL,
  request_method VARCHAR(10) NOT NULL,
  request_path VARCHAR(500) NOT NULL,
  request_hash CHAR(64) NOT NULL,
  response_status INT NOT NULL,
  response_body JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_idempotency_method
    CHECK (request_method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_idempotency_hash_length
    CHECK (CHAR_LENGTH(request_hash) = 64),
  CONSTRAINT ck_idempotency_response_status
    CHECK (response_status BETWEEN 100 AND 599),
  CONSTRAINT fk_idempotency_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),

  -- Primary key on tuple
  PRIMARY KEY (`key`, user_id, request_method, request_path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for pruning old entries
CREATE INDEX ix_idempotency_keys_pruning ON idempotency_keys(created_at);

-- Comments
ALTER TABLE idempotency_keys COMMENT = 'Request deduplication for idempotent operations (24h retention)';
