#!/bin/bash

# ============================================
# MOROCCOCHECK - DATABASE INSTALLATION SCRIPT
# Version: 1.0
# Date: 2026-01-16
# ============================================

echo "================================"
echo "MoroccoCheck Database Setup"
echo "================================"

# Database configuration
DB_NAME="moroccocheck"
DB_USER="moroccocheck_user"
DB_PASS="your_secure_password_here"
DB_HOST="localhost"

echo "Creating database and user..."

mysql -u root -p <<EOF
-- Create database
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' 
    IDENTIFIED BY '${DB_PASS}';

-- Grant privileges
GRANT ALL PRIVILEGES ON ${DB_NAME}.* 
    TO '${DB_USER}'@'${DB_HOST}';

-- Flush privileges
FLUSH PRIVILEGES;

-- Use database
USE ${DB_NAME};
EOF

echo "Installing database schema..."

# Execute SQL files in order
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_database.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_tables_part1.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_tables_part2.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_tables_part3.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_tables_part4.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_functions.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_triggers.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_procedures.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < create_views.sql
mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < seed_data.sql

echo "================================"
echo "Database installation completed!"
echo "Database: ${DB_NAME}"
echo "User: ${DB_USER}"
echo "Password: ${DB_PASS}"
echo "================================"