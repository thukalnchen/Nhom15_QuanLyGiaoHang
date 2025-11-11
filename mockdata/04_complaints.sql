-- ========================================
-- MOCK DATA: COMPLAINTS TABLE
-- ========================================
-- Insert sample complaints and feedback

INSERT INTO complaints (user_id, order_id, complaint_type, subject, description, priority, status, evidence_images, resolution_note, resolved_at, resolved_by, created_at, updated_at) VALUES

-- Product Issues
(1, 12, 'product_issue', 'Mỳ quá mềm', 'Khi nhận được đơn hàng, mỳ quá mềm, có vẻ bị ướt. Không thể ăn được.', 'high', 'resolved', '["uploads/complaints/IMG_20240101_001.jpg"]', 'Đã hoàn tiền 50%. Xin lỗi vì chất lượng không tốt.', CURRENT_TIMESTAMP - INTERVAL '10 hours', 13, CURRENT_TIMESTAMP - INTERVAL '14 hours', CURRENT_TIMESTAMP - INTERVAL '10 hours'),
(2, 13, 'product_issue', 'Thiếu topping', 'Đặt phô bò nhưng thiếu nước sốt và giá đỗ. Không như mô tả.', 'medium', 'in_progress', '[]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '8 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Delivery Issues
(3, 8, 'delivery_issue', 'Giao chậm hơn 1 giờ', 'Đơn hàng được đặt lúc 18:00, hứa giao lúc 19:30 nhưng đến 20:45 mới được giao', 'medium', 'resolved', '[]', 'Xin lỗi vì sự chậm trễ. Đã hoàn 20,000 đồng phí giao hàng.', CURRENT_TIMESTAMP - INTERVAL '2 hours', 13, CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(4, 11, 'delivery_issue', 'Đơn hàng giao sai địa chỉ', 'Giao nhầm sang tòa nhà B thay vì tòa nhà A, tôi phải tìm tài xế để lấy hàng', 'high', 'resolved', '["uploads/complaints/address_issue_001.jpg"]', 'Xin lỗi vui lòng ghi địa chỉ rõ ràng hơn. Hoàn tiền toàn bộ phí giao.', CURRENT_TIMESTAMP - INTERVAL '1 hour', 13, CURRENT_TIMESTAMP - INTERVAL '4 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour'),

-- Driver Issues
(1, 13, 'driver_issue', 'Tài xế thái độ xấu', 'Tài xế không thân thiện, nói chuyện gồng gConstraint không vui vẻ', 'medium', 'open', '[]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '3 hours', CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(5, 10, 'driver_issue', 'Tài xế không gọi điện xác nhận', 'Tài xế không gọi điện xác nhận vị trí giao, tôi chờ rồi lại phải ra cửa tìm', 'low', 'resolved', '[]', 'Đã cảnh báo tài xế về quy tắc giao hàng. Sẽ cải thiện lần sau.', CURRENT_TIMESTAMP - INTERVAL '5 days', 13, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),

-- Payment Issues
(2, 5, 'payment_issue', 'Trừ tiền sai số lượng', 'Đặt 2 cây nhưng bị trừ tiền cho 3 cây', 'high', 'in_progress', '["uploads/complaints/payment_receipt_001.jpg", "uploads/complaints/app_screenshot_001.jpg"]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '5 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(3, 15, 'payment_issue', 'Thanh toán bị lỗi nhưng vẫn bị trừ tiền', 'Lỗi thanh toán xảy ra, báo lỗi nhưng vẫn bị trừ tiền từ tài khoản', 'urgent', 'open', '[]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Service Issues
(4, 14, 'service_issue', 'App bị treo khi thanh toán', 'Khi thanh toán, app bị treo và không biết được thanh toán có thành công hay không', 'medium', 'resolved', '[]', 'Đã cập nhật phiên bản ứng dụng. Vui lòng cập nhật và thử lại.', CURRENT_TIMESTAMP - INTERVAL '8 hours', 13, CURRENT_TIMESTAMP - INTERVAL '10 hours', CURRENT_TIMESTAMP - INTERVAL '8 hours'),

-- Other Issues
(1, 13, 'other', 'Giao dịch không rõ ràng', 'Không hiểu rõ tại sao phí giao hàng lại cao như vậy, không có thông báo rõ ràng trước', 'low', 'open', '[]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(2, 12, 'other', 'Góp ý cải thiện dịch vụ', 'Nên thêm tính năng đặt lịch giao hàng trước để khách hàng biết thời gian chính xác', 'low', 'resolved', '[]', 'Cảm ơn bạn vì góp ý quý báu. Chúng tôi sẽ xem xét tính năng này trong bản cập nhật tiếp theo.', CURRENT_TIMESTAMP - INTERVAL '3 days', 13, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),

-- Additional Complaints
(5, 11, 'product_issue', 'Đồ uống bị đổ', 'Nắp cốc bị lỏng, đồ uống đổ ra hết trong túi, làm bẩn quần áo', 'urgent', 'in_progress', '["uploads/complaints/damaged_drink_001.jpg", "uploads/complaints/damaged_drink_002.jpg"]', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(3, 9, 'delivery_issue', 'Phục vụ không có bao gồm', 'Đơn hàng không được đặt vào hộp mà để lỏng lẻo trong túi', 'medium', 'resolved', '[]', 'Xin lỗi vì chất lượng dịch vụ. Đã huấn luyện lại tài xế.', CURRENT_TIMESTAMP - INTERVAL '7 days', 13, CURRENT_TIMESTAMP - INTERVAL '9 days', CURRENT_TIMESTAMP - INTERVAL '7 days');
