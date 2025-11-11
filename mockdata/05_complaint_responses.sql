-- ========================================
-- MOCK DATA: COMPLAINT_RESPONSES TABLE
-- ========================================
-- Insert sample complaint responses and conversations

INSERT INTO complaint_responses (complaint_id, user_id, user_role, message, attachments, created_at) VALUES

-- Responses for Complaint 1 (Product Issue - Noodles too soft)
(1, 1, 'customer', 'Mỳ quá mềm không ăn được. Yêu cầu hoàn tiền hoặc thay đổi.', '[]', CURRENT_TIMESTAMP - INTERVAL '14 hours'),
(1, 13, 'admin', 'Chúng tôi rất ti遺 lỗi vì chất lượng đơn hàng. Tôi sẽ xử lý hoàn tiền ngay.', '[]', CURRENT_TIMESTAMP - INTERVAL '13 hours'),
(1, 1, 'customer', 'Cảm ơn admin đã xử lý nhanh. Hoàn tiền đã vào tài khoản rồi.', '[]', CURRENT_TIMESTAMP - INTERVAL '10 hours'),

-- Responses for Complaint 2 (Product Issue - Missing toppings)
(2, 2, 'customer', 'Phô bị thiếu topping theo hình ảnh đơn hàng. Chất lượng kém.', '["uploads/complaints/order_detail.jpg"]', CURRENT_TIMESTAMP - INTERVAL '8 hours'),
(2, 12, 'intake_staff', 'Tôi kiểm tra lại đơn. Nó có vẻ như nhà hàng giao thiếu. Tôi sẽ liên hệ họ.', '[]', CURRENT_TIMESTAMP - INTERVAL '7 hours'),
(2, 13, 'admin', 'Chúng tôi đã liên hệ nhà hàng. Họ sẽ chuẩn bị một phần mới và giao trong 30 phút.', '[]', CURRENT_TIMESTAMP - INTERVAL '6 hours'),
(2, 2, 'customer', 'Đã nhận đơn mới. Cảm ơn đã xử lý!', '[]', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Responses for Complaint 3 (Delivery Issue - Late delivery)
(3, 3, 'customer', 'Giao muộn hơn 1 tiếng đồng hồ. Rất không hài lòng.', '[]', CURRENT_TIMESTAMP - INTERVAL '6 hours'),
(3, 7, 'driver', 'Xin lỗi, hôm đó đường tắc nên bị chậm. Tôi sẽ cảnh báo khách trước lần sau.', '[]', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
(3, 13, 'admin', 'Tôi xin lỗi vì sự chậm trễ. Đã hoàn 20,000đ phí giao hàng như bù đắp.', '[]', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Responses for Complaint 4 (Delivery Issue - Wrong address)
(4, 4, 'customer', 'Tài xế giao sai địa chỉ. Giao vào tòa B thay vì tòa A. Mất time đi tìm.', '["uploads/complaints/location_map.jpg"]', CURRENT_TIMESTAMP - INTERVAL '4 hours'),
(4, 8, 'driver', 'Tôi xin lỗi. Lúc đó GPS không tính toán chính xác. Tôi đã ghi chú lại địa chỉ.', '[]', CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(4, 13, 'admin', 'Chúng tôi đã cảnh báo tài xế. Đã hoàn phí giao. Cảm ơn vì hiểu biết.', '[]', CURRENT_TIMESTAMP - INTERVAL '1 hour'),

-- Responses for Complaint 5 (Driver Issue - Bad attitude)
(5, 1, 'customer', 'Tài xế có thái độ rất xấu, nói chuyện gân, không thân thiện.', '[]', CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(5, 13, 'admin', 'Chúng tôi rất tiếc vì trải nghiệm của bạn. Tôi sẽ nói chuyện với tài xế về vấn đề này.', '[]', CURRENT_TIMESTAMP - INTERVAL '2.5 hours'),
(5, 7, 'driver', 'Tôi xin lỗi vì hành động của mình. Tôi sẽ cải thiện thái độ phục vụ.', '[]', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(5, 1, 'customer', 'Tôi chấp nhận lời xin lỗi. Hãy cố gắng hơn lần sau.', '[]', CURRENT_TIMESTAMP - INTERVAL '1 hour'),

-- Responses for Complaint 6 (Driver Issue - No confirmation call)
(6, 5, 'customer', 'Tài xế không gọi điện xác nhận vị trí. Chờ lâu rồi phải tự tìm.', '[]', CURRENT_TIMESTAMP - INTERVAL '7 days'),
(6, 13, 'admin', 'Cảm ơn bạn đã báo cáo. Điều này sẽ được đưa vào huấn luyện cho tất cả tài xế.', '[]', CURRENT_TIMESTAMP - INTERVAL '6 days'),

-- Responses for Complaint 7 (Payment Issue - Wrong amount)
(7, 2, 'customer', 'Đặt 2 cây nhưng bị trừ tiền cho 3 cây. Kiểm tra hóa đơn trong app.', '["uploads/complaints/invoice_screenshot.jpg"]', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
(7, 13, 'admin', 'Tôi đang kiểm tra hệ thống. Phát hiện lỗi tính toán. Sẽ hoàn tiền ngay.', '[]', CURRENT_TIMESTAMP - INTERVAL '4 hours'),
(7, 2, 'customer', 'Chưa thấy hoàn tiền. Bao giờ sẽ nhận được?', '[]', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

-- Responses for Complaint 8 (Payment Issue - Payment error)
(8, 3, 'customer', 'Lỗi thanh toán nhưng tiền vẫn bị trừ. Cần hoàn tiền ngay.', '["uploads/complaints/transaction_error.jpg"]', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(8, 13, 'admin', 'Đây là vấn đề nghiêm trọng. Tôi sẽ xác minh với nhân viên tài chính ngay.', '[]', CURRENT_TIMESTAMP - INTERVAL '1.5 hours'),

-- Responses for Complaint 9 (Service Issue - App crash)
(9, 4, 'customer', 'App bị treo khi thanh toán. Không biết có thanh toán thành công hay không.', '[]', CURRENT_TIMESTAMP - INTERVAL '10 hours'),
(9, 13, 'admin', 'Tôi rất lấy làm tiếc. Đây là lỗi đã được sửa trong phiên bản mới. Vui lòng cập nhật app.', '[]', CURRENT_TIMESTAMP - INTERVAL '9 hours'),
(9, 4, 'customer', 'Cập nhật xong. App chạy mượt hơn rồi. Cảm ơn!', '[]', CURRENT_TIMESTAMP - INTERVAL '8 hours'),

-- Responses for Complaint 10 (Other - Unclear charges)
(10, 1, 'customer', 'Phí giao hàng quá cao. Không hiểu tại sao lại tính như vậy?', '[]', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(10, 13, 'admin', 'Phí giao hàng được tính dựa trên khoảng cách và thời gian cao điểm. Xin lỗi vì không rõ ràng.', '[]', CURRENT_TIMESTAMP - INTERVAL '22 hours');
