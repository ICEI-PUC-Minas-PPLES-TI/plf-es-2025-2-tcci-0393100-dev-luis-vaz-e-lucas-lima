-- Migration: Allow NULL seller_id for scraper imports
-- This allows vehicles imported by scrapers (user_id = 0) to have NULL seller_id

-- First, drop the foreign key constraint
ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS vehicles_seller_id_fkey;

-- Alter the column to allow NULL
ALTER TABLE vehicles ALTER COLUMN seller_id DROP NOT NULL;

-- Re-add the foreign key constraint with ON DELETE SET NULL instead of CASCADE
-- This ensures that if a user is deleted, vehicles with that seller_id will have it set to NULL
ALTER TABLE vehicles 
  ADD CONSTRAINT vehicles_seller_id_fkey 
  FOREIGN KEY (seller_id) 
  REFERENCES users(user_id) 
  ON DELETE SET NULL;

