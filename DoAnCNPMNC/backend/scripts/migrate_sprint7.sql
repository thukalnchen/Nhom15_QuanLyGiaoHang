-- Sprint 7 Migration Script
-- US-23: Pricing Rules Management
-- US-24: Statistics & Reporting
-- US-26: Hubs & Delivery Areas Configuration

-- ============================================
-- US-23: Pricing Rules Table
-- ============================================
CREATE TABLE IF NOT EXISTS pricing_rules (
  id SERIAL PRIMARY KEY,
  rule_name VARCHAR(255) NOT NULL,
  rule_type VARCHAR(50) NOT NULL, -- 'base_price', 'service_fee', 'weight_factor', 'distance_factor'
  vehicle_type VARCHAR(50) NOT NULL, -- 'motorcycle', 'van_500', 'van_750', 'van_1000'
  
  -- Base pricing
  base_price_per_km DECIMAL(10, 2) DEFAULT 0,
  minimum_fare DECIMAL(10, 2) DEFAULT 0,
  
  -- Service fees
  train_station_fee DECIMAL(10, 2) DEFAULT 0,
  extra_weight_per_kg DECIMAL(10, 2) DEFAULT 0,
  helper_small_fee DECIMAL(10, 2) DEFAULT 0,
  helper_large_fee DECIMAL(10, 2) DEFAULT 0,
  round_trip_percentage DECIMAL(5, 2) DEFAULT 0, -- e.g., 0.7 = 70%
  
  -- Factors
  weight_factor DECIMAL(5, 2) DEFAULT 1.0,
  distance_factor DECIMAL(5, 2) DEFAULT 1.0,
  
  -- Metadata
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  effective_from TIMESTAMP DEFAULT NOW(),
  effective_until TIMESTAMP,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for pricing_rules
CREATE INDEX IF NOT EXISTS idx_pricing_rules_vehicle ON pricing_rules(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_pricing_rules_active ON pricing_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_pricing_rules_type ON pricing_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_pricing_rules_dates ON pricing_rules(effective_from, effective_until);

-- Insert default pricing rules (matching current hardcoded values)
INSERT INTO pricing_rules (rule_name, rule_type, vehicle_type, base_price_per_km, minimum_fare, train_station_fee, extra_weight_per_kg, helper_small_fee, helper_large_fee, round_trip_percentage, is_active)
VALUES 
  ('Giá cơ bản xe máy', 'base_price', 'motorcycle', 5000, 15000, 20000, 10000, 50000, 70000, 0.7, true),
  ('Giá cơ bản xe tải 500kg', 'base_price', 'van_500', 8000, 30000, 20000, 10000, 50000, 70000, 0.7, true),
  ('Giá cơ bản xe tải 750kg', 'base_price', 'van_750', 10000, 40000, 20000, 10000, 50000, 70000, 0.7, true),
  ('Giá cơ bản xe tải 1000kg', 'base_price', 'van_1000', 12000, 50000, 20000, 10000, 50000, 70000, 0.7, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- US-26: Hubs Table (Kho/Bưu cục)
-- ============================================
CREATE TABLE IF NOT EXISTS hubs (
  id SERIAL PRIMARY KEY,
  hub_code VARCHAR(50) UNIQUE NOT NULL,
  hub_name VARCHAR(255) NOT NULL,
  hub_type VARCHAR(50) NOT NULL, -- 'warehouse', 'post_office', 'checkpoint'
  address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  contact_phone VARCHAR(20),
  contact_email VARCHAR(255),
  manager_name VARCHAR(255),
  operating_hours TEXT, -- e.g., "08:00-18:00"
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for hubs
CREATE INDEX IF NOT EXISTS idx_hubs_code ON hubs(hub_code);
CREATE INDEX IF NOT EXISTS idx_hubs_type ON hubs(hub_type);
CREATE INDEX IF NOT EXISTS idx_hubs_active ON hubs(is_active);
CREATE INDEX IF NOT EXISTS idx_hubs_location ON hubs(latitude, longitude);

-- ============================================
-- US-26: Create/Update Delivery Areas Table
-- ============================================
-- Create delivery_areas table if it doesn't exist
CREATE TABLE IF NOT EXISTS delivery_areas (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add columns to delivery_areas if they don't exist
DO $$ 
BEGIN
  BEGIN
    ALTER TABLE delivery_areas ADD COLUMN center_latitude DECIMAL(10, 8);
  EXCEPTION
    WHEN duplicate_column THEN NULL;
  END;
  
  BEGIN
    ALTER TABLE delivery_areas ADD COLUMN center_longitude DECIMAL(11, 8);
  EXCEPTION
    WHEN duplicate_column THEN NULL;
  END;
  
  BEGIN
    ALTER TABLE delivery_areas ADD COLUMN service_radius_km DECIMAL(10, 2) DEFAULT 10.0;
  EXCEPTION
    WHEN duplicate_column THEN NULL;
  END;
  
  BEGIN
    ALTER TABLE delivery_areas ADD COLUMN is_active BOOLEAN DEFAULT true;
  EXCEPTION
    WHEN duplicate_column THEN NULL;
  END;
END $$;

-- Create index for delivery_areas location
CREATE INDEX IF NOT EXISTS idx_delivery_areas_location ON delivery_areas(center_latitude, center_longitude);
CREATE INDEX IF NOT EXISTS idx_delivery_areas_active ON delivery_areas(is_active);

-- ============================================
-- US-24: Add indexes for statistics queries
-- ============================================
-- Indexes for orders table to optimize statistics queries
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders(status, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_total_amount ON orders(total_amount) WHERE total_amount > 0;

-- ============================================
-- Grant permissions
-- ============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON pricing_rules TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON hubs TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON delivery_areas TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- ============================================
-- Migration metadata
-- ============================================
-- Create migrations table if not exists
CREATE TABLE IF NOT EXISTS migrations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  executed_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO migrations (name, executed_at)
VALUES ('migrate_sprint7', NOW())
ON CONFLICT DO NOTHING;

-- Verify tables created
SELECT 'Sprint 7 migration completed successfully' as status;

