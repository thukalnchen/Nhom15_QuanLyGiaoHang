-- ========================================
-- MOCK DATA: USERS TABLE
-- ========================================
-- Insert sample users with different roles
-- Password: password123 (hashed with bcrypt)
-- Hash: $2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca

INSERT INTO users (email, password, full_name, phone, address, role, created_at, updated_at) VALUES
-- Customers (Role: customer)
('customer1@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Nguyễn Văn A', '0901234567', '123 Đường Nguyễn Huệ, Q.1, TP.HCM', 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('customer2@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Trần Thị B', '0902234567', '456 Đường Lê Lợi, Q.1, TP.HCM', 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('customer3@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Phạm Minh C', '0903234567', '789 Đường Đồng Khởi, Q.1, TP.HCM', 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('customer4@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Lê Quang D', '0904234567', '321 Đường Mạc Đĩnh Chi, Q.1, TP.HCM', 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('customer5@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Hoàng Thị E', '0905234567', '654 Đường Pasteur, Q.1, TP.HCM', 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Drivers (Role: driver)
('driver1@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Đỗ Anh F', '0906234567', '111 Đường Nguyễn Văn Linh, Q.7, TP.HCM', 'driver', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('driver2@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Dương Hữu G', '0907234567', '222 Đường Võ Văn Kiệt, Q.5, TP.HCM', 'driver', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('driver3@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Bùi Tấn H', '0908234567', '333 Đường Trần Nhân Tông, Q.5, TP.HCM', 'driver', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('driver4@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Võ Văn I', '0909234567', '444 Đường Sư Vạn Hạnh, Q.10, TP.HCM', 'driver', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Intake Staff (Role: intake_staff)
('intake1@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Ngô Thị J', '0910234567', '555 Đường Phan Văn Trị, Q.Bình Thạnh, TP.HCM', 'intake_staff', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('intake2@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Tạ Quang K', '0911234567', '666 Đường Lương Nhu Học, Q.Gò Vấp, TP.HCM', 'intake_staff', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('intake3@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Vũ Đức L', '0912234567', '777 Đường Trường Chinh, Q.Tân Bình, TP.HCM', 'intake_staff', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Admin (Role: admin)
('admin@example.com', '$2b$10$YIjlrFxVHQWaDsvWyM4Gm.6wI9VQyoIYPa.cQ8qWS8QkQm5l2A6Ca', 'Trần Quản Trị', '0913234567', '888 Đường Thạch Thị Thanh, Q.1, TP.HCM', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
