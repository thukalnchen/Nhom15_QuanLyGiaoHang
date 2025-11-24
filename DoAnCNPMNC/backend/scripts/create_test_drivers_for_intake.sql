-- ========================================
-- SCRIPT TẠO TẠI XẾ TEST CHO APP INTAKE
-- ========================================
-- Mục đích: Tạo 15 tài xế test với đầy đủ thông tin để test tính năng phân tài xế
-- Password: Driver@123 (đã hash bcrypt)
-- Role: driver
-- Vehicle types: bike, van_500, van_750, van_1000

-- BƯỚC 1: Thêm các cột cần thiết vào table users (nếu chưa có)
ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_number VARCHAR(50);

-- BƯỚC 2: Xóa drivers test cũ (nếu có)
DELETE FROM users WHERE email LIKE 'driver%@intake.test';

-- BƯỚC 3: Tạo 15 drivers test với phân bổ loại xe hợp lý
-- Password hash: $2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca (Driver@123)

INSERT INTO users (email, password, full_name, phone, address, role, vehicle_type, vehicle_number, vehicle_registration, created_at, updated_at)
VALUES 
  -- ===== 8 Tài xế xe máy (bike) =====
  (
    'driver1@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Nguyễn Văn Anh',
    '0901234501',
    '123 Nguyễn Huệ, Quận 1, TP.HCM',
    'driver',
    'bike',
    '59A-12301',
    '59A-12301',
    NOW(),
    NOW()
  ),
  (
    'driver2@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Trần Thị Bình',
    '0902234502',
    '456 Lê Lợi, Quận 1, TP.HCM',
    'driver',
    'bike',
    '59B-23402',
    '59B-23402',
    NOW(),
    NOW()
  ),
  (
    'driver3@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Lê Văn Cường',
    '0903234503',
    '789 Điện Biên Phủ, Quận 3, TP.HCM',
    'driver',
    'bike',
    '59C-34503',
    '59C-34503',
    NOW(),
    NOW()
  ),
  (
    'driver4@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Phạm Thị Dung',
    '0904234504',
    '321 Võ Văn Tần, Quận 3, TP.HCM',
    'driver',
    'bike',
    '59D-45604',
    '59D-45604',
    NOW(),
    NOW()
  ),
  (
    'driver5@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Hoàng Văn Em',
    '0905234505',
    '654 Pasteur, Quận 1, TP.HCM',
    'driver',
    'bike',
    '59E-56705',
    '59E-56705',
    NOW(),
    NOW()
  ),
  (
    'driver6@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Võ Thị Phương',
    '0906234506',
    '987 Cách Mạng Tháng 8, Quận 10, TP.HCM',
    'driver',
    'bike',
    '59F-67806',
    '59F-67806',
    NOW(),
    NOW()
  ),
  (
    'driver7@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Đặng Văn Giang',
    '0907234507',
    '147 Lý Thường Kiệt, Quận 10, TP.HCM',
    'driver',
    'bike',
    '59G-78907',
    '59G-78907',
    NOW(),
    NOW()
  ),
  (
    'driver8@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Bùi Thị Hoa',
    '0908234508',
    '258 Nguyễn Thị Minh Khai, Quận 1, TP.HCM',
    'driver',
    'bike',
    '59H-89008',
    '59H-89008',
    NOW(),
    NOW()
  ),
  
  -- ===== 3 Tài xế van 500kg (van_500) =====
  (
    'driver9@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Ngô Văn Inh',
    '0909234509',
    '369 Hai Bà Trưng, Quận 3, TP.HCM',
    'driver',
    'van_500',
    '51I-90109',
    '51I-90109',
    NOW(),
    NOW()
  ),
  (
    'driver10@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Lý Thị Kim',
    '0910234510',
    '741 Trần Hưng Đạo, Quận 5, TP.HCM',
    'driver',
    'van_500',
    '51K-01210',
    '51K-01210',
    NOW(),
    NOW()
  ),
  (
    'driver11@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Phan Văn Long',
    '0911234511',
    '852 Nguyễn Đình Chiểu, Quận 3, TP.HCM',
    'driver',
    'van_500',
    '51L-12311',
    '51L-12311',
    NOW(),
    NOW()
  ),
  
  -- ===== 2 Tài xế van 750kg (van_750) =====
  (
    'driver12@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Trương Văn Minh',
    '0912234512',
    '963 Võ Thị Sáu, Quận 3, TP.HCM',
    'driver',
    'van_750',
    '51M-23412',
    '51M-23412',
    NOW(),
    NOW()
  ),
  (
    'driver13@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Huỳnh Thị Nga',
    '0913234513',
    '147 Cống Quỳnh, Quận 1, TP.HCM',
    'driver',
    'van_750',
    '51N-34513',
    '51N-34513',
    NOW(),
    NOW()
  ),
  
  -- ===== 2 Tài xế van 1000kg (van_1000) =====
  (
    'driver14@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Đinh Văn Phúc',
    '0914234514',
    '258 Lê Thánh Tôn, Quận 1, TP.HCM',
    'driver',
    'van_1000',
    '51P-45614',
    '51P-45614',
    NOW(),
    NOW()
  ),
  (
    'driver15@intake.test',
    '$2b$10$YPNlrPXVLZWmDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca',
    'Mai Thị Quỳnh',
    '0915234515',
    '369 Nam Kỳ Khởi Nghĩa, Quận 3, TP.HCM',
    'driver',
    'van_1000',
    '51Q-56715',
    '51Q-56715',
    NOW(),
    NOW()
  )
ON CONFLICT (email) DO UPDATE SET
  password = EXCLUDED.password,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  address = EXCLUDED.address,
  vehicle_type = EXCLUDED.vehicle_type,
  vehicle_number = EXCLUDED.vehicle_number,
  vehicle_registration = EXCLUDED.vehicle_registration,
  updated_at = NOW();

-- BƯỚC 4: Hiển thị kết quả
SELECT 
  id,
  full_name,
  phone,
  vehicle_type,
  vehicle_number,
  email
FROM users 
WHERE email LIKE 'driver%@intake.test'
ORDER BY vehicle_type, full_name;

-- THÔNG TIN ĐĂNG NHẬP:
-- Email: driver1@intake.test đến driver15@intake.test
-- Password: Driver@123
-- Role: driver

-- PHÂN BỔ LOẠI XE:
-- - 8 xe máy (bike): driver1 - driver8
-- - 3 van 500kg: driver9 - driver11  
-- - 2 van 750kg: driver12 - driver13
-- - 2 van 1000kg: driver14 - driver15
