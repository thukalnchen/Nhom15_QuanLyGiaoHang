-- Create zones table for route management
CREATE TABLE IF NOT EXISTS zones (
  id SERIAL PRIMARY KEY,
  zone_code VARCHAR(50) UNIQUE NOT NULL,
  zone_name VARCHAR(100) NOT NULL,
  description TEXT,
  base_price DECIMAL(10,2) DEFAULT 0,
  price_per_km DECIMAL(10,2) DEFAULT 0,
  polygon_coordinates JSONB,
  center_latitude DECIMAL(11,8),
  center_longitude DECIMAL(11,8),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create routes table
CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  route_code VARCHAR(50) UNIQUE NOT NULL,
  route_name VARCHAR(100) NOT NULL,
  zone_id INTEGER REFERENCES zones(id),
  driver_id INTEGER REFERENCES users(id),
  start_point VARCHAR(255),
  end_point VARCHAR(255),
  waypoints JSONB,
  total_distance DECIMAL(10,2),
  estimated_duration INTEGER,
  status VARCHAR(50) DEFAULT 'planned',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample zones (Sai Gon areas)
INSERT INTO zones (zone_code, zone_name, description, base_price, price_per_km, center_latitude, center_longitude)
VALUES 
  ('Q1', 'Quan 1', 'Trung tam thanh pho', 15000, 3000, 10.7769, 106.7009),
  ('Q3', 'Quan 3', 'Khu vuc trung tam', 15000, 3000, 10.7829, 106.6920),
  ('Q5', 'Quan 5', 'Khu vuc Cho Lon', 12000, 2500, 10.7541, 106.6663),
  ('TD', 'Thu Duc', 'Khu dong thanh pho', 18000, 3500, 10.8542, 106.7629),
  ('BT', 'Binh Thanh', 'Khu vuc dong dan', 15000, 3000, 10.8098, 106.7053)
ON CONFLICT (zone_code) DO NOTHING;

-- Insert sample routes
INSERT INTO routes (route_code, route_name, zone_id, start_point, end_point, total_distance, estimated_duration, status)
VALUES 
  ('R001', 'Tuyen Q1-Q3', 1, 'Nha Opera', 'Cong Vien Tao Dan', 3.5, '15 minutes', 'active'),
  ('R002', 'Tuyen Q1-Q5', 1, 'Ben Thanh', 'Cho Lon', 5.2, '25 minutes', 'active'),
  ('R003', 'Tuyen Thu Duc', 4, 'Landmark 81', 'KCX Tan Thuan', 12.0, '45 minutes', 'planned')
ON CONFLICT (route_code) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_zones_active ON zones(is_active);
CREATE INDEX IF NOT EXISTS idx_routes_zone ON routes(zone_id);
CREATE INDEX IF NOT EXISTS idx_routes_driver ON routes(driver_id);
CREATE INDEX IF NOT EXISTS idx_routes_status ON routes(status);
