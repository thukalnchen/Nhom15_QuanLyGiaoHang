-- ========================================
-- MOCK DATA: RATINGS_REVIEWS TABLE
-- ========================================
-- Insert sample ratings and reviews from customers

INSERT INTO ratings_reviews (order_id, user_id, rating, review_text, delivery_rating, food_quality_rating, driver_rating, created_at, updated_at) VALUES

-- 5-Star Reviews (Excellent)
(1, 1, 5, 'Đơn hàng giao nhanh, chất lượng tuyệt vời! Pizza nóng và ngon lắm. Tài xế rất lịch sự. Sẽ đặt lại lần sau!', 5, 5, 5, CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(4, 4, 5, 'Sushi tươi, giao đúng giờ, tài xế thân thiện. Rất hài lòng!', 5, 5, 5, CURRENT_TIMESTAMP - INTERVAL '3 hours', CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(10, 5, 5, 'Cà phê ngon, giao nhanh. Rất tốt!', 5, 5, 5, CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),

-- 4-Star Reviews (Good)
(2, 2, 4, 'Burger ngon nhưng giao hơi chậm khoảng 10 phút. Nhân viên tài xế tốt. Tổng thể ổn.', 4, 5, 4, CURRENT_TIMESTAMP - INTERVAL '50 minutes', CURRENT_TIMESTAMP - INTERVAL '50 minutes'),
(5, 5, 4, 'Cơm Thái ngon, giao đúng lịch. Hơi chốc chút khi giao.', 4, 4, 4, CURRENT_TIMESTAMP - INTERVAL '15 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
(6, 1, 4, 'Pizza tốt nhưng sốt ít hơn mong đợi. Giao nhanh. Tốt lắm!', 5, 4, 4, CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),

-- 3-Star Reviews (Average)
(11, 1, 3, 'Bánh ngon nhưng giao lâu. Hàng không được bảo vệ tốt, bị vỡ một chút.', 2, 4, 3, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(7, 2, 3, 'Cơm ổn nhưng không được nóng như mong đợi. Tài xế chưa thân thiện.', 3, 3, 3, CURRENT_TIMESTAMP - INTERVAL '25 hours', CURRENT_TIMESTAMP - INTERVAL '25 hours'),

-- 2-Star Reviews (Poor)
(13, 3, 2, 'Thịt nướng không theo yêu cầu (rare). Giao chậm. Tài xế không thân thiện. Không hài lòng.', 2, 2, 1, CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(8, 3, 2, 'Phở bị mất nước sốt. Giao sai địa chỉ. Rất tồi tệ lần này!', 1, 2, 1, CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours'),

-- 1-Star Reviews (Terrible)
(12, 2, 1, 'Mỳ quá mềm, không ăn được. Tài xế giao chậm. Thất vọng với dịch vụ.', 1, 1, 2, CURRENT_TIMESTAMP - INTERVAL '10 hours', CURRENT_TIMESTAMP - INTERVAL '10 hours'),
(9, 4, 1, 'Đơn hàng không được bảo vệ, đến nơi lạnh toàn bộ. Tài xế không lịch sự. Không được tốt!', 1, 1, 1, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '8 days');
