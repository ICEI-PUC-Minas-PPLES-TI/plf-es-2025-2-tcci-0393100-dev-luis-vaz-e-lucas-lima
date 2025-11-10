-- Initial seed data for BusCars Backend
-- This file is loaded ONLY on first database initialization
-- Creates initial users so the API can be used
--
-- For vehicle data, use: ./backend/db/seed.sh (which calls the API)

-- Create initial users (password: 123456 for all)
INSERT INTO users (name, email, password_hash, phone, subscription_tier, is_verified) VALUES
    ('Admin User', 'admin@buscar.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 99999-0000', 'business', TRUE),
    ('Carlos Silva', 'carlos.silva@email.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 99999-9999', 'professional', TRUE),
    ('Maria Santos', 'maria.santos@gmail.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 88888-8888', 'individual', TRUE)
ON CONFLICT (email) DO NOTHING;

-- That's it! Vehicles will be created via API (test CRUD)

