-- StyleMart Database Schema for MySQL
-- Layer 1 - Commerce Tables
-- File: 06_create_user_preferences.sql
-- Description: User preferences table (depends on users)

USE stylemart;

CREATE TABLE user_preferences (
  user_id VARCHAR(50) PRIMARY KEY,
  preferences JSON NOT NULL,
  schema_version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT ck_preferences_schema_version
    CHECK (schema_version = 1),
  CONSTRAINT fk_preferences_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: PostgreSQL has validate_preferences_v1() function
-- In MySQL, validation should be done at application layer

-- Comments
ALTER TABLE user_preferences COMMENT = 'User shopping preferences (style, size, communication)';
