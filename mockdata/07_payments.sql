-- ========================================
-- MOCK DATA: PAYMENTS TABLE (if exists)
-- ========================================
-- Insert sample payment records

INSERT INTO payments (order_id, user_id, amount, payment_method, payment_status, transaction_id, paid_at, created_at, updated_at) VALUES

-- Cash on Delivery Payments
(3, 3, 220000, 'cash', 'pending', NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(5, 5, 220000, 'cash', 'completed', NULL, CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),
(14, 4, 140000, 'cash', 'cancelled', NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '11 hours'),

-- Card Payments
(1, 1, 320000, 'card', 'completed', 'TXN20240101001', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(2, 2, 160000, 'card', 'completed', 'TXN20240101002', CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(4, 4, 270000, 'card', 'completed', 'TXN20240101003', CURRENT_TIMESTAMP - INTERVAL '45 minutes', CURRENT_TIMESTAMP - INTERVAL '45 minutes', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(6, 1, 200000, 'card', 'completed', 'TXN20240101004', CURRENT_TIMESTAMP - INTERVAL '15 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
(7, 2, 170000, 'card', 'completed', 'TXN20240101005', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '10 minutes'),
(8, 3, 95000, 'card', 'completed', 'TXN20240101006', CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),
(9, 4, 520000, 'card', 'completed', 'TXN20240101007', NOW(), NOW(), NOW()),
(10, 5, 200000, 'card', 'completed', 'TXN20240101008', CURRENT_TIMESTAMP - INTERVAL '3 minutes', CURRENT_TIMESTAMP - INTERVAL '3 minutes', CURRENT_TIMESTAMP - INTERVAL '3 minutes'),
(11, 1, 200000, 'card', 'completed', 'TXN20240101009', CURRENT_TIMESTAMP - INTERVAL '8 minutes', CURRENT_TIMESTAMP - INTERVAL '8 minutes', CURRENT_TIMESTAMP - INTERVAL '8 minutes'),

-- Digital Wallet Payments
(12, 2, 170000, 'wallet', 'completed', 'TXN20231231010', CURRENT_TIMESTAMP - INTERVAL '24 hours', CURRENT_TIMESTAMP - INTERVAL '24 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(13, 3, 240000, 'wallet', 'completed', 'TXN20231230011', CURRENT_TIMESTAMP - INTERVAL '18 hours', CURRENT_TIMESTAMP - INTERVAL '18 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(15, 5, 80000, 'card', 'cancelled', 'TXN20240101012', NULL, CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '5 hours');
