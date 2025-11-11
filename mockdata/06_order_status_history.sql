-- ========================================
-- MOCK DATA: ORDER_STATUS_HISTORY TABLE
-- ========================================
-- Insert sample order status history tracking

INSERT INTO order_status_history (order_id, status, notes, created_at) VALUES

-- Order 1 (ORD001) Status History
(1, 'pending', 'Đơn hàng mới được tạo', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(1, 'confirmed', 'Nhà hàng xác nhận đơn hàng', CURRENT_TIMESTAMP - INTERVAL '110 minutes'),
(1, 'processing', 'Nhà hàng bắt đầu chuẩn bị đơn hàng', CURRENT_TIMESTAMP - INTERVAL '100 minutes'),
(1, 'ready_for_delivery', 'Đơn hàng sẵn sàng giao', CURRENT_TIMESTAMP - INTERVAL '60 minutes'),
(1, 'on_the_way', 'Tài xế Đỗ Anh F đã nhận đơn và đang trên đường', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(1, 'delivered', 'Đơn hàng đã giao thành công', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),

-- Order 2 (ORD002) Status History
(2, 'pending', 'Đơn hàng mới được tạo', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(2, 'confirmed', 'Nhà hàng xác nhận đơn hàng', CURRENT_TIMESTAMP - INTERVAL '55 minutes'),
(2, 'processing', 'Nhà hàng đang chuẩn bị', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(2, 'ready_for_delivery', 'Đơn hàng sẵn sàng giao', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),

-- Order 3 (ORD003) Status History
(3, 'pending', 'Đơn hàng mới từ khách', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(3, 'confirmed', 'Nhà hàng nhận đơn', CURRENT_TIMESTAMP - INTERVAL '28 minutes'),

-- Order 4 (ORD004) Status History
(4, 'pending', 'Đơn hàng mới', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(4, 'confirmed', 'Nhà hàng xác nhận', CURRENT_TIMESTAMP - INTERVAL '40 minutes'),
(4, 'processing', 'Đang chuẩn bị sushi', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(4, 'ready_for_delivery', 'Sushi sẵn sàng giao', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
(4, 'on_the_way', 'Tài xế Bùi Tấn H đang giao', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),

-- Order 5 (ORD005) Status History
(5, 'pending', 'Đơn hàng mới', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),
(5, 'confirmed', 'Nhà hàng xác nhận', CURRENT_TIMESTAMP - INTERVAL '18 minutes'),
(5, 'processing', 'Chuẩn bị cơm Thái', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),

-- Order 6 (ORD006) Status History
(6, 'pending', 'Đơn pizza mới', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
(6, 'confirmed', 'Nhà hàng xác nhận', CURRENT_TIMESTAMP - INTERVAL '13 minutes'),
(6, 'processing', 'Đang làm pizza với phô mai thêm', CURRENT_TIMESTAMP - INTERVAL '10 minutes'),

-- Order 12 (ORD012) - Delivered
(12, 'pending', 'Đơn hàng mới từ khách hàng', CURRENT_TIMESTAMP - INTERVAL '24 hours'),
(12, 'confirmed', 'Nhà hàng xác nhận đơn hàng noodle', CURRENT_TIMESTAMP - INTERVAL '23 hours'),
(12, 'processing', 'Bắt đầu nấu mỳ', CURRENT_TIMESTAMP - INTERVAL '22 hours'),
(12, 'ready_for_delivery', 'Mỳ đã xong, sẵn sàng giao', CURRENT_TIMESTAMP - INTERVAL '21 hours'),
(12, 'on_the_way', 'Tài xế Võ Văn I nhận và đang giao', CURRENT_TIMESTAMP - INTERVAL '20 hours'),
(12, 'delivered', 'Giao thành công lúc 20:30', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Order 13 (ORD013) - Delivered with complaint
(13, 'pending', 'Đơn BBQ mới', CURRENT_TIMESTAMP - INTERVAL '18 hours'),
(13, 'confirmed', 'Nhà hàng xác nhận nướng BBQ', CURRENT_TIMESTAMP - INTERVAL '17 hours'),
(13, 'processing', 'Đang nướng thịt', CURRENT_TIMESTAMP - INTERVAL '15 hours'),
(13, 'ready_for_delivery', 'BBQ nướng kỹ, sẵn sàng giao', CURRENT_TIMESTAMP - INTERVAL '13 hours'),
(13, 'on_the_way', 'Tài xế Dương Hữu G đang giao', CURRENT_TIMESTAMP - INTERVAL '12 hours'),
(13, 'delivered', 'Giao thành công lúc 19:00', CURRENT_TIMESTAMP - INTERVAL '1 hour'),

-- Order 14 (ORD014) - Cancelled
(14, 'pending', 'Đơn hàng mới', CURRENT_TIMESTAMP - INTERVAL '12 hours'),
(14, 'confirmed', 'Nhà hàng xác nhận salad', CURRENT_TIMESTAMP - INTERVAL '11.5 hours'),
(14, 'processing', 'Bắt đầu làm salad', CURRENT_TIMESTAMP - INTERVAL '11 hours'),
(14, 'cancelled', 'Khách hàng yêu cầu hủy đơn - không cần nữa', CURRENT_TIMESTAMP - INTERVAL '11 hours'),

-- Order 15 (ORD015) - Cancelled
(15, 'pending', 'Đơn hàng donut mới', CURRENT_TIMESTAMP - INTERVAL '6 hours'),
(15, 'confirmed', 'Shop xác nhận đơn', CURRENT_TIMESTAMP - INTERVAL '5.5 hours'),
(15, 'cancelled', 'Khách yêu cầu hủy vì có việc khác', CURRENT_TIMESTAMP - INTERVAL '5 hours');
