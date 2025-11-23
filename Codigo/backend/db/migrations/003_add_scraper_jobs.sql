-- Migration: Add scraper jobs table
-- Date: 2024-11-25
-- Description: Adds table to manage scraper jobs (brand, model, source) for automated scraping

-- Scraper jobs table
CREATE TABLE IF NOT EXISTS scraper_jobs (
    scraper_job_id SERIAL PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    source VARCHAR(50) NOT NULL CHECK (source IN ('localiza', 'icarros', 'webmotors')),
    is_active BOOLEAN DEFAULT TRUE,
    last_run_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    UNIQUE(brand, model, source)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_scraper_jobs_source ON scraper_jobs(source);
CREATE INDEX IF NOT EXISTS idx_scraper_jobs_is_active ON scraper_jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_scraper_jobs_next_run ON scraper_jobs(next_run_at) WHERE is_active = TRUE;

