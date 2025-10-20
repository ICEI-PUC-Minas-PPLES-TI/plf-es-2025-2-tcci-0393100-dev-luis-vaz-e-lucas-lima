-- BusCar Database Schema
-- PostgreSQL initialization script

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    price VARCHAR(50) NOT NULL, -- Stored as string to handle formatting
    mileage VARCHAR(50) NOT NULL, -- Stored as string to handle formatting
    fuel_type VARCHAR(50) NOT NULL,
    color VARCHAR(50),
    transmission VARCHAR(50),
    description TEXT,
    image TEXT, -- Main image URL
    seller_name VARCHAR(255) NOT NULL,
    seller_phone VARCHAR(20),
    seller_email VARCHAR(255),
    condition VARCHAR(20) DEFAULT 'used', -- 'new', 'used', 'certified'
    source VARCHAR(50) DEFAULT 'buscar', -- 'buscar', 'webmotors', 'localiza', etc.
    engine VARCHAR(100),
    doors INTEGER DEFAULT 4,
    body_style VARCHAR(50), -- 'sedan', 'suv', 'hatchback', etc.
    location_city VARCHAR(100),
    location_state VARCHAR(2), -- Brazilian state code (SP, RJ, etc.)
    detailed_description_md TEXT, -- Markdown description
    financing_available BOOLEAN DEFAULT false,
    trade_accepted BOOLEAN DEFAULT false,
    test_drive_available BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create vehicle images table
CREATE TABLE IF NOT EXISTS vehicle_images (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create vehicle features table
CREATE TABLE IF NOT EXISTS vehicle_features (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE CASCADE,
    feature_name VARCHAR(100) NOT NULL,
    feature_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create service history table
CREATE TABLE IF NOT EXISTS service_history (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE CASCADE,
    service_date DATE NOT NULL,
    service_type VARCHAR(50) NOT NULL, -- 'Revisão', 'Reparo', 'Troca de óleo', etc.
    description TEXT,
    mileage_at_service VARCHAR(50),
    cost VARCHAR(50), -- Stored as string to handle formatting
    service_provider VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vehicles_brand ON vehicles(brand);
CREATE INDEX IF NOT EXISTS idx_vehicles_model ON vehicles(model);
CREATE INDEX IF NOT EXISTS idx_vehicles_year ON vehicles(year);
CREATE INDEX IF NOT EXISTS idx_vehicles_source ON vehicles(source);
CREATE INDEX IF NOT EXISTS idx_vehicles_condition ON vehicles(condition);
CREATE INDEX IF NOT EXISTS idx_vehicles_location_state ON vehicles(location_state);
CREATE INDEX IF NOT EXISTS idx_vehicles_created_at ON vehicles(created_at);
CREATE INDEX IF NOT EXISTS idx_vehicle_images_vehicle_id ON vehicle_images(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_images_sort_order ON vehicle_images(vehicle_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_vehicle_features_vehicle_id ON vehicle_features(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_service_history_vehicle_id ON service_history(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_service_history_date ON service_history(service_date);
