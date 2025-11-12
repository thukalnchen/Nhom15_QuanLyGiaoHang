-- Create 10 test drivers for driver assignment testing
-- Password for all: Driver@123

-- Clear existing test drivers (optional)
-- DELETE FROM users WHERE email LIKE 'driver%@test.com';

-- Insert 10 drivers
INSERT INTO users (email, password, full_name, phone, address, role, vehicle_registration, created_at, updated_at)
VALUES 
  -- Driver 1: Xe máy
  ('driver1@test.com', '$2b$10$YourHashedPasswordHere', 'Nguyễn Văn An', '0901234567', '123 Nguyễn Huệ, Q.1, TP.HCM', 'driver', '59A-12345', NOW(), NOW()),
  
  -- Driver 2: Xe máy  
  ('driver2@test.com', '$2b$10$YourHashedPasswordHere', 'Trần Thị Bình', '0902234567', '456 Lê Lợi, Q.1, TP.HCM', 'driver', '59B-23456', NOW(), NOW()),
  
  -- Driver 3: Van 500kg
  ('driver3@test.com', '$2b$10$YourHashedPasswordHere', 'Lê Văn Cường', '0903234567', '789 Điện Biên Phủ, Q.3, TP.HCM', 'driver', '51C-34567', NOW(), NOW()),
  
  -- Driver 4: Xe máy
  ('driver4@test.com', '$2b$10$YourHashedPasswordHere', 'Phạm Thị Dung', '0904234567', '321 Võ Văn Tần, Q.3, TP.HCM', 'driver', '59D-45678', NOW(), NOW()),
  
  -- Driver 5: Van 750kg
  ('driver5@test.com', '$2b$10$YourHashedPasswordHere', 'Hoàng Văn Em', '0905234567', '654 Pasteur, Q.1, TP.HCM', 'driver', '51E-56789', NOW(), NOW()),
  
  -- Driver 6: Xe máy
  ('driver6@test.com', '$2b$10$YourHashedPasswordHere', 'Võ Thị Phương', '0906234567', '987 Cách Mạng Tháng 8, Q.10, TP.HCM', 'driver', '59F-67890', NOW(), NOW()),
  
  -- Driver 7: Van 1000kg
  ('driver7@test.com', '$2b$10$YourHashedPasswordHere', 'Đặng Văn Giang', '0907234567', '147 Lý Thường Kiệt, Q.10, TP.HCM', 'driver', '51G-78901', NOW(), NOW()),
  
  -- Driver 8: Xe máy
  ('driver8@test.com', '$2b$10$YourHashedPasswordHere', 'Bùi Thị Hoa', '0908234567', '258 Nguyễn Thị Minh Khai, Q.1, TP.HCM', 'driver', '59H-89012', NOW(), NOW()),
  
  -- Driver 9: Van 500kg
  ('driver9@test.com', '$2b$10$YourHashedPasswordHere', 'Ngô Văn Inh', '0909234567', '369 Hai Bà Trưng, Q.3, TP.HCM', 'driver', '51I-90123', NOW(), NOW()),
  
  -- Driver 10: Xe máy
  ('driver10@test.com', '$2b$10$YourHashedPasswordHere', 'Lý Thị Kim', '0910234567', '741 Trần Hưng Đạo, Q.5, TP.HCM', 'driver', '59K-01234', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Note: You need to hash the password first using bcrypt
-- For testing, you can use: Driver@123
-- Run this in Node.js to get hashed password:
-- const bcrypt = require('bcrypt');
-- bcrypt.hash('Driver@123', 10).then(console.log);
