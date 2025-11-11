-- ========================================
-- MOCK DATA: NOTIFICATIONS TABLE
-- ========================================
-- Insert sample notifications for various users

INSERT INTO notifications (user_id, title, body, type, reference_id, data, is_read, read_at, created_at, updated_at) VALUES

-- Order Notifications for Customer 1
(1, 'Đơn hàng được xác nhận', 'Đơn hàng #ORD001 đã được xác nhận bởi nhà hàng', 'order', 1, '{"order_id": 1, "order_number": "ORD001", "action": "confirmed"}', true, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(1, 'Đơn hàng đang được chuẩn bị', 'Nhà hàng đang chuẩn bị đơn hàng của bạn', 'order', 1, '{"order_id": 1, "order_number": "ORD001", "action": "processing"}', true, CURRENT_TIMESTAMP - INTERVAL '90 minutes', CURRENT_TIMESTAMP - INTERVAL '90 minutes', CURRENT_TIMESTAMP - INTERVAL '90 minutes'),
(1, 'Đơn hàng sẵn sàng giao', 'Đơn hàng #ORD001 đã sẵn sàng để giao', 'order', 1, '{"order_id": 1, "order_number": "ORD001", "action": "ready"}', true, CURRENT_TIMESTAMP - INTERVAL '60 minutes', CURRENT_TIMESTAMP - INTERVAL '60 minutes', CURRENT_TIMESTAMP - INTERVAL '60 minutes'),
(1, 'Tài xế đang trên đường', 'Tài xế Đỗ Anh F đang giao đơn hàng của bạn', 'driver', 1, '{"order_id": 1, "driver_name": "Đỗ Anh F", "driver_id": 6}', true, CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(1, 'Đơn hàng đã giao thành công', 'Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi', 'order', 1, '{"order_id": 1, "order_number": "ORD001", "action": "delivered"}', true, CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),

-- Payment Notifications for Customer 2
(2, 'Thanh toán thành công', 'Thanh toán cho đơn hàng #ORD002 đã được xử lý', 'payment', 2, '{"order_id": 2, "order_number": "ORD002", "amount": 180000, "method": "card"}', true, CURRENT_TIMESTAMP - INTERVAL '50 minutes', CURRENT_TIMESTAMP - INTERVAL '50 minutes', CURRENT_TIMESTAMP - INTERVAL '50 minutes'),
(2, 'Đơn hàng đang được chuẩn bị', 'Nhà hàng Burger King đang chuẩn bị đơn hàng của bạn', 'order', 2, '{"order_id": 2, "order_number": "ORD002", "restaurant": "Burger King"}', true, CURRENT_TIMESTAMP - INTERVAL '40 minutes', CURRENT_TIMESTAMP - INTERVAL '40 minutes', CURRENT_TIMESTAMP - INTERVAL '40 minutes'),
(2, 'Tài xế Dương Hữu G đã nhận đơn', 'Tài xế sẽ tới đơn vị nước khác sau', 'driver', 2, '{"order_id": 2, "driver_name": "Dương Hữu G", "driver_id": 7}', true, CURRENT_TIMESTAMP - INTERVAL '25 minutes', CURRENT_TIMESTAMP - INTERVAL '25 minutes', CURRENT_TIMESTAMP - INTERVAL '25 minutes'),

-- System Notifications
(3, 'Khuyến mãi mới', 'Giảm 30% cho đơn đầu tiên của bạn! Sử dụng mã: NEW30', 'system', NULL, '{"promo_code": "NEW30", "discount": 30}', false, NULL, CURRENT_TIMESTAMP - INTERVAL '4 hours', CURRENT_TIMESTAMP - INTERVAL '4 hours'),
(4, 'Cảnh báo tài khoản', 'Vui lòng cập nhật số điện thoại để nhận thông báo giao hàng', 'system', NULL, '{"action": "update_profile"}', false, NULL, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),

-- Notifications for Driver 1
(6, 'Có đơn giao mới', 'Có một đơn giao mới từ ORD006, hãy nhận ngay', 'order', 6, '{"order_id": 6, "order_number": "ORD006", "restaurant": "Pizza House"}', true, CURRENT_TIMESTAMP - INTERVAL '12 minutes', CURRENT_TIMESTAMP - INTERVAL '12 minutes', CURRENT_TIMESTAMP - INTERVAL '12 minutes'),
(6, 'Đơn hàng đã được giao', 'Bạn đã hoàn thành 1 đơn giao hôm nay', 'order', 6, '{"order_id": 6, "status": "delivered"}', true, CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),

-- Notifications for Intake Staff 1
(9, 'Hàng mới cần nhập kho', 'Có 3 đơn hàng chờ nhập kho từ các nhà cung cấp', 'order', NULL, '{"warehouse": "HCM", "pending_orders": 3}', true, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(9, 'Nhận đơn hàng thành công', 'Bạn đã nhận 3 đơn hàng từ ORD001, ORD004, ORD006', 'order', NULL, '{"action": "received", "count": 3}', true, CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),

-- More Customer Notifications
(5, 'Đơn hàng mới được tạo', 'Đơn hàng #ORD005 đã được tạo thành công', 'order', 5, '{"order_id": 5, "order_number": "ORD005"}', true, CURRENT_TIMESTAMP - INTERVAL '22 minutes', CURRENT_TIMESTAMP - INTERVAL '22 minutes', CURRENT_TIMESTAMP - INTERVAL '22 minutes'),
(5, 'Thanh toán được xác nhận', 'Thanh toán tiền mặt sẽ được nhận tại điểm giao', 'payment', 5, '{"order_id": 5, "payment_method": "cash"}', true, CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),
(3, 'Đơn hàng đã được hủy', 'Đơn hàng #ORD014 đã được hủy thành công. Hoàn tiền sẽ được xử lý trong 3-5 ngày', 'order', 14, '{"order_id": 14, "order_number": "ORD014", "status": "cancelled"}', false, NULL, CURRENT_TIMESTAMP - INTERVAL '11 hours', CURRENT_TIMESTAMP - INTERVAL '11 hours');
