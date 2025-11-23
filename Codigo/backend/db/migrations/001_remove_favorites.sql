-- Migration: Remove favorites and views functionality
-- Date: 2024-11-25
-- Description: Removes favorites_count, views_count columns and favorites table

-- Remove favorites_count column from vehicles table
ALTER TABLE vehicles DROP COLUMN IF EXISTS favorites_count;

-- Remove views_count column from vehicles table
ALTER TABLE vehicles DROP COLUMN IF EXISTS views_count;

-- Drop favorites table and related indexes
DROP TABLE IF EXISTS favorites CASCADE;

