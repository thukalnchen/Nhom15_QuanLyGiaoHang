-- ========================================
-- MOCK DATA: ORDERS TABLE
-- ========================================
-- Insert sample orders with various statuses

INSERT INTO orders (order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, vehicle_type, package_size, package_type, weight, description, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, payment_status, payment_method, refund_status, created_at, updated_at) VALUES

-- Pending Orders
('ORD001', 1, 'Pizza House', '{"items": [{"name": "Pizza Margherita", "quantity": 2, "price": 150000}]}', 320000, 20000, 'pending', '123 Đường Nguyễn Huệ, Q.1, TP.HCM', '0901234567', 'Giao sớm', NULL, 'M', 'package', 2.5, 'Pizza 2 hộp, sốt cà chua', 1, 'Warehouse HCM', 1, 'Ngô Thị J', 'pending', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('ORD002', 2, 'Burger King', '{"items": [{"name": "Whopper", "quantity": 1, "price": 120000}, {"name": "Coke", "quantity": 2, "price": 20000}]}', 160000, 20000, 'pending', '456 Đường Lê Lợi, Q.1, TP.HCM', '0902234567', 'Không ớt', NULL, 'S', 'package', 1.5, 'Burger combo', 1, 'Warehouse HCM', 2, 'Tạ Quang K', 'pending', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
('ORD003', 3, 'Pho Restaurant', '{"items": [{"name": "Phở Bò", "quantity": 2, "price": 100000}]}', 220000, 20000, 'pending', '789 Đường Đồng Khởi, Q.1, TP.HCM', '0903234567', NULL, NULL, 'L', 'liquid', 2.0, 'Phở 2 tô', 2, 'Warehouse Biên Hoà', 3, 'Vũ Đức L', 'pending', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),

-- Confirmed Orders
('ORD004', 4, 'Sushi House', '{"items": [{"name": "Sushi Mix", "quantity": 1, "price": 250000}]}', 270000, 20000, 'confirmed', '321 Đường Mạc Đĩnh Chi, Q.1, TP.HCM', '0904234567', 'Giao lúc 19:00', NULL, 'M', 'package', 1.8, 'Set sushi 24 miếng', 1, 'Warehouse HCM', 1, 'Ngô Thị J', 'completed', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '45 minutes', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
('ORD005', 5, 'Thai Restaurant', '{"items": [{"name": "Pad Thai", "quantity": 1, "price": 80000}, {"name": "Tom Yum", "quantity": 1, "price": 120000}]}', 220000, 20000, 'confirmed', '654 Đường Pasteur, Q.1, TP.HCM', '0905234567', NULL, NULL, 'M', 'package', 2.2, 'Cơm Thái 2 đĩa', 2, 'Warehouse Biên Hoà', 2, 'Tạ Quang K', 'completed', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '20 minutes', CURRENT_TIMESTAMP - INTERVAL '20 minutes'),

-- Processing Orders
('ORD006', 1, 'Pizza House', '{"items": [{"name": "Pizza Hawaiian", "quantity": 1, "price": 180000}]}', 200000, 20000, 'processing', '123 Đường Nguyễn Huệ, Q.1, TP.HCM', '0901234567', 'Extra cheese', NULL, 'M', 'package', 2.5, 'Pizza Hawaii 1 hộp', 1, 'Warehouse HCM', 1, 'Ngô Thị J', 'completed', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '15 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
('ORD007', 2, 'KFC', '{"items": [{"name": "Fried Chicken Combo", "quantity": 1, "price": 150000}]}', 170000, 20000, 'processing', '456 Đường Lê Lợi, Q.1, TP.HCM', '0902234567', NULL, NULL, 'M', 'package', 3.0, 'Gà rán combo 2 miếng', 1, 'Warehouse HCM', 3, 'Vũ Đức L', 'completed', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '10 minutes'),

-- Ready for Delivery Orders
('ORD008', 3, 'Banh Mi House', '{"items": [{"name": "Banh Mi Thit", "quantity": 3, "price": 25000}]}', 95000, 20000, 'ready_for_delivery', '789 Đường Đồng Khởi, Q.1, TP.HCM', '0903234567', 'Nhiều chả', NULL, 'S', 'package', 1.2, 'Bánh mì 3 cái', 2, 'Warehouse Biên Hoà', 2, 'Tạ Quang K', 'completed', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '5 minutes', CURRENT_TIMESTAMP - INTERVAL '5 minutes'),
('ORD009', 4, 'Steak House', '{"items": [{"name": "Beef Steak", "quantity": 2, "price": 250000}]}', 520000, 20000, 'ready_for_delivery', '321 Đường Mạc Đĩnh Chi, Q.1, TP.HCM', '0904234567', 'Rare', NULL, 'L', 'package', 4.5, 'Beefsteak 2 phần', 1, 'Warehouse HCM', 1, 'Ngô Thị J', 'completed', 'card', NULL, NOW(), NOW()),

-- On-way Orders
('ORD010', 5, 'Coffee Shop', '{"items": [{"name": "Cappuccino", "quantity": 4, "price": 45000}]}', 200000, 20000, 'on_the_way', '654 Đường Pasteur, Q.1, TP.HCM', '0905234567', NULL, 'bike', 'S', 'liquid', 2.0, 'Cà phê 4 ly', 2, 'Warehouse Biên Hoà', 3, 'Vũ Đức L', 'completed', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '3 minutes', CURRENT_TIMESTAMP - INTERVAL '3 minutes'),
('ORD011', 1, 'Dessert Palace', '{"items": [{"name": "Cake Chocolate", "quantity": 1, "price": 180000}]}', 200000, 20000, 'on_the_way', '123 Đường Nguyễn Huệ, Q.1, TP.HCM', '0901234567', 'Tập trung giao', 'bike', 'M', 'package', 2.8, 'Bánh chocolate 1 cái', 1, 'Warehouse HCM', 2, 'Tạ Quang K', 'completed', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '8 minutes', CURRENT_TIMESTAMP - INTERVAL '8 minutes'),

-- Delivered Orders
('ORD012', 2, 'Noodle House', '{"items": [{"name": "Mì Ý", "quantity": 2, "price": 75000}]}', 170000, 20000, 'delivered', '456 Đường Lê Lợi, Q.1, TP.HCM', '0902234567', NULL, 'car', 'M', 'package', 2.0, 'Mì Ý 2 tô', 2, 'Warehouse Biên Hoà', 1, 'Ngô Thị J', 'completed', 'cash', NULL, CURRENT_TIMESTAMP - INTERVAL '24 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('ORD013', 3, 'BBQ House', '{"items": [{"name": "Pork BBQ", "quantity": 1, "price": 200000}]}', 240000, 20000, 'delivered', '789 Đường Đồng Khởi, Q.1, TP.HCM', '0903234567', 'Nướng kỹ', 'car', 'M', 'package', 3.5, 'Thịt nướng 1 đĩa', 1, 'Warehouse HCM', 2, 'Tạ Quang K', 'completed', 'card', NULL, CURRENT_TIMESTAMP - INTERVAL '18 hours', CURRENT_TIMESTAMP - INTERVAL '1 hours'),

-- Cancelled Orders
('ORD014', 4, 'Salad Shop', '{"items": [{"name": "Salad Caesar", "quantity": 1, "price": 120000}]}', 140000, 20000, 'cancelled', '321 Đường Mạc Đĩnh Chi, Q.1, TP.HCM', '0904234567', NULL, NULL, 'S', 'package', 1.5, 'Salad Caesar 1 tô', 1, 'Warehouse HCM', 1, 'Ngô Thị J', 'pending', 'cash', 'pending', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '11 hours'),
('ORD015', 5, 'Donut Shop', '{"items": [{"name": "Donut Mix", "quantity": 6, "price": 60000}]}', 80000, 20000, 'cancelled', '654 Đường Pasteur, Q.1, TP.HCM', '0905234567', NULL, NULL, 'S', 'package', 1.0, 'Donut 6 cái', 2, 'Warehouse Biên Hoà', 3, 'Vũ Đức L', 'pending', 'card', 'completed', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '5 hours');
