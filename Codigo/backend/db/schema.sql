-- BusCars Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    subscription_tier VARCHAR(50) DEFAULT 'individual' CHECK (subscription_tier IN ('individual', 'professional', 'business'))
);

-- Create index on email for faster lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Vehicles table (immutable with audit trail)
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    version INTEGER DEFAULT 1,  -- For versioning/audit
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL CHECK (year >= 1900 AND year <= 2100),
    price VARCHAR(50) NOT NULL,
    mileage VARCHAR(50) NOT NULL,
    fuel_type VARCHAR(50) NOT NULL,
    color VARCHAR(100) NOT NULL,
    transmission VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    image TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',
    seller_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    seller_name VARCHAR(255) NOT NULL,
    seller_phone VARCHAR(50) NOT NULL,
    seller_email VARCHAR(255) NOT NULL,
    condition VARCHAR(20) NOT NULL CHECK (condition IN ('used', 'new')),
    source VARCHAR(50) DEFAULT 'buscar',
    engine VARCHAR(200),
    doors INTEGER DEFAULT 4,
    body_style VARCHAR(100),
    features TEXT[] DEFAULT '{}',
    detailed_description_md TEXT,
    
    -- Additional detailed fields
    vin VARCHAR(50),
    license_plate VARCHAR(20),
    previous_owners INTEGER DEFAULT 1,
    service_history TEXT[] DEFAULT '{}',
    modifications TEXT[] DEFAULT '{}',
    included_items TEXT[] DEFAULT '{}',
    exterior_condition VARCHAR(50),
    interior_condition VARCHAR(50),
    mechanical_condition VARCHAR(50),
    inspection_notes TEXT,
    location_city VARCHAR(100) NOT NULL,
    location_state VARCHAR(50) NOT NULL,
    financing_available BOOLEAN DEFAULT FALSE,
    trade_accepted BOOLEAN DEFAULT FALSE,
    test_drive_available BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,  -- Soft delete: false = deleted
    deleted_at TIMESTAMP WITH TIME ZONE,  -- When soft deleted
    views_count INTEGER DEFAULT 0,
    favorites_count INTEGER DEFAULT 0,
    
    -- Audit fields
    created_by INTEGER REFERENCES users(user_id),
    updated_by INTEGER REFERENCES users(user_id),
    
    -- Immutability: track original version for audit
    original_id INTEGER REFERENCES vehicles(id)  -- Points to first version
);

-- Create indexes for common queries
CREATE INDEX idx_vehicles_slug ON vehicles(slug);
CREATE INDEX idx_vehicles_seller_id ON vehicles(seller_id);
CREATE INDEX idx_vehicles_brand ON vehicles(brand);
CREATE INDEX idx_vehicles_model ON vehicles(model);
CREATE INDEX idx_vehicles_year ON vehicles(year);
CREATE INDEX idx_vehicles_condition ON vehicles(condition);
CREATE INDEX idx_vehicles_source ON vehicles(source);
CREATE INDEX idx_vehicles_location_state ON vehicles(location_state);
CREATE INDEX idx_vehicles_is_active ON vehicles(is_active);
CREATE INDEX idx_vehicles_created_at ON vehicles(created_at DESC);

-- Composite indexes for common filter combinations
CREATE INDEX idx_vehicles_brand_model ON vehicles(brand, model);
CREATE INDEX idx_vehicles_condition_source ON vehicles(condition, source);

-- Full text search index on description
CREATE INDEX idx_vehicles_description_fts ON vehicles USING gin(to_tsvector('portuguese', description));

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- Favorites table (for future use)
CREATE TABLE IF NOT EXISTS favorites (
    favorite_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, vehicle_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_vehicle_id ON favorites(vehicle_id);

-- Contact requests table (for future use)
CREATE TABLE IF NOT EXISTS contact_requests (
    contact_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    requester_name VARCHAR(255) NOT NULL,
    requester_email VARCHAR(255) NOT NULL,
    requester_phone VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_contact_requests_vehicle_id ON contact_requests(vehicle_id);
CREATE INDEX idx_contact_requests_created_at ON contact_requests(created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to increment view count
CREATE OR REPLACE FUNCTION increment_vehicle_views(vehicle_slug VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE vehicles 
    SET views_count = views_count + 1 
    WHERE slug = vehicle_slug;
END;
$$ LANGUAGE plpgsql;

