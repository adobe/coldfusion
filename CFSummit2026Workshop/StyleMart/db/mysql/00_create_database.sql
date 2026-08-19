-- StyleMart Database Schema for MySQL
-- File: 00_create_database.sql
-- Description: Create database and set up basic configuration

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS stylemart
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Switch to the database
USE stylemart;

-- Set SQL mode for stricter validation
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Display confirmation
SELECT 'Database stylemart created successfully' AS status;
