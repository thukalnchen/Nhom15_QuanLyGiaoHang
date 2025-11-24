-- Create test shipper accounts with various vehicle types
-- Password: Shipper@123 
-- Hash: $2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6

INSERT INTO users (email, password, full_name, phone, role, vehicle_type, vehicle_number, vehicle_registration, created_at, updated_at)
VALUES 
  -- Car shippers
  ('shipper.car1@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Nguyễn Văn Car 1', '0911111111', 'shipper', 'car', '51A-12345', 'ABC123', NOW(), NOW()),
  ('shipper.car2@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Trần Thị Car 2', '0911111112', 'shipper', 'car', '51B-67890', 'DEF456', NOW(), NOW()),
  ('shipper.car3@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Lê Văn Car 3', '0911111113', 'shipper', 'car', '51C-11111', 'GHI789', NOW(), NOW()),
  
  -- Bike shippers  
  ('shipper.bike1@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Phạm Văn Bike 1', '0922222221', 'shipper', 'bike', '51D-22222', 'JKL012', NOW(), NOW()),
  ('shipper.bike2@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Hoàng Thị Bike 2', '0922222222', 'shipper', 'bike', '51E-33333', 'MNO345', NOW(), NOW()),
  ('shipper.bike3@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Vũ Văn Bike 3', '0922222223', 'shipper', 'bike', '51F-44444', 'PQR678', NOW(), NOW()),
  
  -- Van shippers
  ('shipper.van1@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Đỗ Văn Van 1', '0933333331', 'shipper', 'van_500', '51G-55555', 'STU901', NOW(), NOW()),
  ('shipper.van2@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Bùi Thị Van 2', '0933333332', 'shipper', 'van_750', '51H-66666', 'VWX234', NOW(), NOW()),
  ('shipper.van3@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Mai Văn Van 3', '0933333333', 'shipper', 'van_1000', '51I-77777', 'YZA567', NOW(), NOW())
ON CONFLICT (email) DO UPDATE 
SET 
  role = 'shipper',
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  vehicle_type = EXCLUDED.vehicle_type,
  vehicle_number = EXCLUDED.vehicle_number,
  vehicle_registration = EXCLUDED.vehicle_registration,
  password = EXCLUDED.password,
  updated_at = NOW();

-- Verify created accounts
SELECT 
  id, 
  email, 
  full_name, 
  phone, 
  role,
  vehicle_type,
  vehicle_number,
  created_at
FROM users 
WHERE role = 'shipper'
ORDER BY vehicle_type, email;

-- Summary by vehicle type
SELECT 
  vehicle_type,
  COUNT(*) as total_shippers
FROM users 
WHERE role = 'shipper'
GROUP BY vehicle_type
ORDER BY vehicle_type;
