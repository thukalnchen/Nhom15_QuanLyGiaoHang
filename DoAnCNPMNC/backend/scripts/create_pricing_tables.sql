-- Create pricing_tables if not exists
CREATE TABLE IF NOT EXISTS pricing_tables (
  id SERIAL PRIMARY KEY,
  vehicle_type VARCHAR(50) UNIQUE NOT NULL,
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_per_km DECIMAL(10,2) NOT NULL DEFAULT 0,
  minimum_price DECIMAL(10,2) DEFAULT 0,
  surge_multiplier DECIMAL(5,2) DEFAULT 1.0,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default pricing data
INSERT INTO pricing_tables (vehicle_type, base_price, price_per_km, minimum_price, surge_multiplier, description)
VALUES 
  ('bike', 15000, 3000, 15000, 1.0, 'Xe máy - Giao hàng nhanh trong nội thành'),
  ('motorcycle', 15000, 3000, 15000, 1.0, 'Xe máy - Phù hợp đơn hàng nhỏ'),
  ('car', 25000, 5000, 25000, 1.0, 'Xe hơi - An toàn, tiện lợi'),
  ('van', 40000, 8000, 40000, 1.2, 'Xe tải nhỏ - Chở hàng cồng kềnh'),
  ('truck', 60000, 12000, 60000, 1.5, 'Xe tải lớn - Vận chuyển số lượng lớn')
ON CONFLICT (vehicle_type) DO NOTHING;

-- Create surcharges table
CREATE TABLE IF NOT EXISTS surcharges (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL, -- percentage, fixed, multiplier
  value DECIMAL(10,2) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default surcharges
INSERT INTO surcharges (name, type, value, description)
VALUES 
  ('Phí giờ cao điểm', 'percentage', 20, 'Áp dụng từ 7h-9h và 17h-19h'),
  ('Phí đêm', 'percentage', 30, 'Áp dụng từ 22h-6h sáng'),
  ('Phí ngày lễ', 'percentage', 50, 'Áp dụng ngày lễ, Tết'),
  ('Phí xăng dầu', 'fixed', 5000, 'Phụ phí xăng dầu'),
  ('Phí vượt quá 10km', 'percentage', 15, 'Áp dụng khi quãng đường > 10km')
ON CONFLICT DO NOTHING;

-- Create discounts table  
CREATE TABLE IF NOT EXISTS discounts (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL, -- percentage, fixed
  value DECIMAL(10,2) NOT NULL,
  min_order_value DECIMAL(10,2) DEFAULT 0,
  max_discount DECIMAL(10,2),
  usage_limit INTEGER,
  usage_count INTEGER DEFAULT 0,
  valid_from TIMESTAMP,
  valid_to TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default discounts
INSERT INTO discounts (code, name, type, value, min_order_value, max_discount, usage_limit, valid_from, valid_to)
VALUES 
  ('NEWUSER', 'Khách hàng mới', 'percentage', 20, 0, 30000, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 year'),
  ('SAVE10K', 'Giảm 10K', 'fixed', 10000, 50000, NULL, 1000, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '3 months'),
  ('FREESHIP', 'Miễn phí vận chuyển', 'percentage', 100, 100000, 50000, 500, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 month'),
  ('VIP20', 'Khách VIP', 'percentage', 20, 0, 100000, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 year')
ON CONFLICT (code) DO NOTHING;
