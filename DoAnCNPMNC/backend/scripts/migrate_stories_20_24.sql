-- Story #22: Zones and Routes tables
-- Migration script for route management

-- Create zones table
CREATE TABLE IF NOT EXISTS zones (
  id SERIAL PRIMARY KEY,
  zone_code VARCHAR(50) UNIQUE NOT NULL,
  zone_name VARCHAR(255) NOT NULL,
  description TEXT,
  base_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  price_per_km DECIMAL(10, 2) NOT NULL DEFAULT 0,
  polygon_coordinates JSONB,
  center_latitude DECIMAL(10, 8),
  center_longitude DECIMAL(10, 8),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create routes table
CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  route_code VARCHAR(50) UNIQUE NOT NULL,
  route_name VARCHAR(255) NOT NULL,
  zone_id INTEGER REFERENCES zones(id) ON DELETE SET NULL,
  driver_id INTEGER,
  start_point VARCHAR(255),
  end_point VARCHAR(255),
  total_distance DECIMAL(10, 2) DEFAULT 0,
  estimated_duration INTERVAL,
  status VARCHAR(50) DEFAULT 'active',
  orders_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add zone_id to orders table if not exists
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_zone_id INTEGER REFERENCES zones(id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_zones_code ON zones(zone_code);
CREATE INDEX IF NOT EXISTS idx_zones_active ON zones(is_active);
CREATE INDEX IF NOT EXISTS idx_routes_zone ON routes(zone_id);
CREATE INDEX IF NOT EXISTS idx_routes_driver ON routes(driver_id);
CREATE INDEX IF NOT EXISTS idx_routes_status ON routes(status);
CREATE INDEX IF NOT EXISTS idx_orders_zone ON orders(delivery_zone_id);

-- Story #23: Pricing and discount tables
-- Create pricing_tables
CREATE TABLE IF NOT EXISTS pricing_tables (
  id SERIAL PRIMARY KEY,
  vehicle_type VARCHAR(50) UNIQUE NOT NULL,
  base_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(10, 2) NOT NULL,
  minimum_price DECIMAL(10, 2) DEFAULT 0,
  surge_multiplier DECIMAL(5, 2) DEFAULT 1.0,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create surcharge_policies table
CREATE TABLE IF NOT EXISTS surcharge_policies (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  value DECIMAL(10, 2) DEFAULT 0,
  percentage DECIMAL(5, 2) DEFAULT 0,
  conditions JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create discount_policies table
CREATE TABLE IF NOT EXISTS discount_policies (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  discount_value DECIMAL(10, 2) DEFAULT 0,
  discount_percentage DECIMAL(5, 2) DEFAULT 0,
  max_discount DECIMAL(10, 2) DEFAULT 0,
  min_order_value DECIMAL(10, 2) DEFAULT 0,
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  valid_from TIMESTAMP,
  valid_until TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pricing_vehicle ON pricing_tables(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_pricing_active ON pricing_tables(is_active);
CREATE INDEX IF NOT EXISTS idx_surcharge_active ON surcharge_policies(is_active);
CREATE INDEX IF NOT EXISTS idx_discount_code ON discount_policies(code);
CREATE INDEX IF NOT EXISTS idx_discount_active ON discount_policies(is_active);

-- Story #21: Driver assignment history
CREATE TABLE IF NOT EXISTS driver_assignments (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  driver_id INTEGER NOT NULL,
  assigned_by INTEGER,
  assigned_at TIMESTAMP DEFAULT NOW(),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Driver reassignments history
CREATE TABLE IF NOT EXISTS driver_reassignments (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  old_driver_id INTEGER,
  new_driver_id INTEGER NOT NULL,
  reassigned_by INTEGER,
  reason TEXT,
  reassigned_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_driver_assignments_order ON driver_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_driver_assignments_driver ON driver_assignments(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_reassignments_order ON driver_reassignments(order_id);

-- Add columns to orders table if not exist
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_zone_id INTEGER REFERENCES zones(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS actual_delivery_time TIMESTAMP;

-- Order status history table (for Story #20)
CREATE TABLE IF NOT EXISTS order_status_history (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT,
  changed_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_status_history_order ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_status_history_date ON order_status_history(changed_at);

-- Insert default pricing if not exists
INSERT INTO pricing_tables (vehicle_type, base_price, price_per_km, minimum_price, surge_multiplier)
VALUES 
  ('bike', 10000, 5000, 10000, 1.0),
  ('car', 20000, 8000, 20000, 1.2),
  ('van', 30000, 10000, 30000, 1.3),
  ('truck', 40000, 12000, 40000, 1.5)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_assignments TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_reassignments TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON zones TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON routes TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON pricing_tables TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON surcharge_policies TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON discount_policies TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON order_status_history TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Migration metadata
INSERT INTO migrations (name, executed_at)
VALUES ('migrate_stories_20_24', NOW())
ON CONFLICT DO NOTHING;

-- Verify tables created
SELECT 'Migration completed successfully' as status;
