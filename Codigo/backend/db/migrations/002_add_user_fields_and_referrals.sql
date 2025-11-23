-- Migration: Add user fields and referral system
-- Date: 2024-11-25
-- Description: Adds document number, address fields, admin flag, and referral code system

-- Add new fields to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS document_number VARCHAR(20),
  ADD COLUMN IF NOT EXISTS address_street VARCHAR(255),
  ADD COLUMN IF NOT EXISTS address_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS address_complement VARCHAR(100),
  ADD COLUMN IF NOT EXISTS address_neighborhood VARCHAR(100),
  ADD COLUMN IF NOT EXISTS address_city VARCHAR(100),
  ADD COLUMN IF NOT EXISTS address_state VARCHAR(50),
  ADD COLUMN IF NOT EXISTS address_zipcode VARCHAR(10),
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS referred_by_code_id INTEGER;

-- Create index on document_number
CREATE INDEX IF NOT EXISTS idx_users_document_number ON users(document_number);
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin);

-- Referral codes table
CREATE TABLE IF NOT EXISTS referral_codes (
    referral_code_id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_by_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- User referrals table (tracks which user used which referral code)
CREATE TABLE IF NOT EXISTS user_referrals (
    user_referral_id SERIAL PRIMARY KEY,
    referral_code_id INTEGER NOT NULL REFERENCES referral_codes(referral_code_id) ON DELETE CASCADE,
    used_by_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(referral_code_id, used_by_user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_referral_codes_created_by ON referral_codes(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_user_referrals_code ON user_referrals(referral_code_id);
CREATE INDEX IF NOT EXISTS idx_user_referrals_user ON user_referrals(used_by_user_id);

-- Add foreign key constraint for referred_by_code_id
ALTER TABLE users 
  ADD CONSTRAINT fk_users_referred_by 
  FOREIGN KEY (referred_by_code_id) 
  REFERENCES referral_codes(referral_code_id) 
  ON DELETE SET NULL;

