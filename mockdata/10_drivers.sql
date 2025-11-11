-- Insert 10 drivers into users table
-- Password for all: Driver@123 (hashed with bcrypt)

INSERT INTO users (email, password, full_name, phone, address, role, vehicle_registration, created_at) VALUES
('driver1@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Nguyễn Văn A', '0901234567', '123 Lý Thường Kiệt, Q.10, TP.HCM', 'driver', '59A1-12345', NOW()),
('driver2@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Trần Văn B', '0902345678', '456 Lê Lợi, Q.1, TP.HCM', 'driver', '59B1-23456', NOW()),
('driver3@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Lê Văn C', '0903456789', '789 Nguyễn Huệ, Q.1, TP.HCM', 'driver', '59C1-34567', NOW()),
('driver4@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Phạm Văn D', '0904567890', '321 Trần Hưng Đạo, Q.5, TP.HCM', 'driver', '59D1-45678', NOW()),
('driver5@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Hoàng Văn E', '0905678901', '654 Hai Bà Trưng, Q.3, TP.HCM', 'driver', '59E1-56789', NOW()),
('driver6@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Vũ Văn F', '0906789012', '987 Võ Văn Tần, Q.3, TP.HCM', 'driver', '59F1-67890', NOW()),
('driver7@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Đặng Văn G', '0907890123', '147 Điện Biên Phủ, Q.Bình Thạnh, TP.HCM', 'driver', '59G1-78901', NOW()),
('driver8@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Bùi Văn H', '0908901234', '258 Nguyễn Thị Minh Khai, Q.1, TP.HCM', 'driver', '59H1-89012', NOW()),
('driver9@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Dương Văn I', '0909012345', '369 Pasteur, Q.1, TP.HCM', 'driver', '59I1-90123', NOW()),
('driver10@lalamove.com', '$2b$10$YourHashedPasswordHere', 'Lý Văn K', '0900123456', '741 Lê Văn Sỹ, Q.3, TP.HCM', 'driver', '59K1-01234', NOW());

-- Note: You need to replace $2b$10$YourHashedPasswordHere with actual bcrypt hash of 'Driver@123'
-- Run this in Node.js to generate:
-- const bcrypt = require('bcrypt');
-- bcrypt.hash('Driver@123', 10).then(hash => console.log(hash));
