-- Initialize admin user and first referral code
-- This script should be run after migration 002

-- First, update the existing admin user to be an admin
UPDATE users 
SET is_admin = TRUE,
    document_number = '000.000.000-00',
    address_street = 'Rua Admin',
    address_number = '1',
    address_neighborhood = 'Centro',
    address_city = 'São Paulo',
    address_state = 'SP',
    address_zipcode = '01000-000'
WHERE email = 'admin@buscar.com';

-- Create first referral code for admin
-- Note: This will fail if admin user doesn't exist, so we use a subquery
INSERT INTO referral_codes (code, created_by_user_id, is_active)
SELECT 'ADMIN001', user_id, TRUE
FROM users
WHERE email = 'admin@buscar.com' AND is_admin = TRUE
ON CONFLICT (code) DO NOTHING;

-- Create a few more referral codes for testing
INSERT INTO referral_codes (code, created_by_user_id, is_active)
SELECT 'TEST001', user_id, TRUE
FROM users
WHERE email = 'admin@buscar.com' AND is_admin = TRUE
ON CONFLICT (code) DO NOTHING;

INSERT INTO referral_codes (code, created_by_user_id, is_active)
SELECT 'TEST002', user_id, TRUE
FROM users
WHERE email = 'admin@buscar.com' AND is_admin = TRUE
ON CONFLICT (code) DO NOTHING;

