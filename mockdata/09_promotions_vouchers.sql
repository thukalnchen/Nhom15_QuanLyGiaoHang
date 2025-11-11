-- ========================================
-- MOCK DATA: PROMOTIONS_VOUCHERS TABLE
-- ========================================
-- Insert sample promotions and voucher codes

INSERT INTO promotions_vouchers (code, description, discount_type, discount_value, min_order_amount, max_usage, used_count, valid_from, valid_until, is_active, created_at, updated_at) VALUES

-- Welcome Promotions
('NEW30', 'Giảm 30% cho đơn hàng đầu tiên', 'percentage', 30, 50000, 100, 25, CURRENT_TIMESTAMP - INTERVAL '30 days', CURRENT_TIMESTAMP + INTERVAL '60 days', true, CURRENT_TIMESTAMP - INTERVAL '30 days', CURRENT_TIMESTAMP - INTERVAL '30 days'),
('WELCOME100', 'Giảm 100.000đ cho khách hàng mới', 'fixed', 100000, 200000, 50, 10, CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP + INTERVAL '45 days', true, CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '15 days'),

-- Seasonal Promotions
('SUMMER20', 'Mùa hè giảm 20% - Hơi ngủi, hơi tươi mát', 'percentage', 20, 100000, 200, 85, CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP + INTERVAL '40 days', true, CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '20 days'),
('HALO2024', 'Tết Nguyên Đán 2024 - Giảm 50.000đ', 'fixed', 50000, 150000, 300, 120, CURRENT_TIMESTAMP - INTERVAL '60 days', CURRENT_TIMESTAMP + INTERVAL '10 days', true, CURRENT_TIMESTAMP - INTERVAL '60 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),

-- Category Specific Promotions
('PIZZA15', 'Pizza giảm 15% - Thứ tư và thứ năm đặc biệt', 'percentage', 15, 80000, 150, 65, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP + INTERVAL '50 days', true, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '10 days'),
('COFFEE25', 'Cà phê giảm 25% - Mỗi sáng từ 6h-10h', 'percentage', 25, 30000, 500, 250, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP + INTERVAL '60 days', true, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),
('SUSHI30', 'Sushi tươi ngon - Giảm 30% từ 17h-20h', 'percentage', 30, 150000, 100, 35, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP + INTERVAL '52 days', true, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '8 days'),

-- Loyalty Program
('LOYAL10', 'Khách hàng trung thành - Giảm 10% mỗi đơn', 'percentage', 10, 50000, 999, 200, CURRENT_TIMESTAMP - INTERVAL '90 days', CURRENT_TIMESTAMP + INTERVAL '270 days', true, CURRENT_TIMESTAMP - INTERVAL '90 days', CURRENT_TIMESTAMP - INTERVAL '90 days'),
('VIP5000', 'Thành viên VIP - Giảm 5.000đ cho mỗi đơn', 'fixed', 5000, 0, 999, 300, CURRENT_TIMESTAMP - INTERVAL '45 days', CURRENT_TIMESTAMP + INTERVAL '315 days', true, CURRENT_TIMESTAMP - INTERVAL '45 days', CURRENT_TIMESTAMP - INTERVAL '45 days'),

-- Time-Limited Flash Sales
('FLASH50', 'Flash Sale - Giảm 50.000đ - Hôm nay thôi!', 'fixed', 50000, 200000, 50, 45, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP + INTERVAL '1 day', true, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP),
('MIDNIGHT20', 'Giao nửa đêm - Giảm 20% (23h-6h)', 'percentage', 20, 80000, 100, 30, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP + INTERVAL '27 days', true, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),

-- Expired Promotions (for reference)
('EXPIREDCODE', 'Voucher này đã hết hạn', 'percentage', 15, 50000, 100, 100, CURRENT_TIMESTAMP - INTERVAL '60 days', CURRENT_TIMESTAMP - INTERVAL '1 day', false, CURRENT_TIMESTAMP - INTERVAL '60 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('NEWYEAR2023', 'Năm mới 2023 - Giảm 25% (HẾT HẠN)', 'percentage', 25, 100000, 200, 200, CURRENT_TIMESTAMP - INTERVAL '400 days', CURRENT_TIMESTAMP - INTERVAL '340 days', false, CURRENT_TIMESTAMP - INTERVAL '400 days', CURRENT_TIMESTAMP - INTERVAL '340 days');
