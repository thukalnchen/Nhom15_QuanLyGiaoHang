-- Tạo database (chạy lệnh này trong PostgreSQL trước)
-- CREATE DATABASE delivery_db;

-- Bảng users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    role VARCHAR(20) DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng orders
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_phone VARCHAR(20) NOT NULL,
    sender_address TEXT NOT NULL,
    sender_city VARCHAR(100),
    sender_district VARCHAR(100),
    sender_ward VARCHAR(100),
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    receiver_address TEXT NOT NULL,
    receiver_city VARCHAR(100),
    receiver_district VARCHAR(100),
    receiver_ward VARCHAR(100),
    package_type VARCHAR(100),
    service_type VARCHAR(100) DEFAULT 'standard',
    pickup_type VARCHAR(50) DEFAULT 'door_to_door',
    pickup_notes TEXT,
    parcel_weight DECIMAL(10, 2),
    parcel_length DECIMAL(10, 2),
    parcel_width DECIMAL(10, 2),
    parcel_height DECIMAL(10, 2),
    declared_value DECIMAL(12, 2),
    cod_amount DECIMAL(12, 2) DEFAULT 0,
    insurance_fee DECIMAL(10, 2) DEFAULT 0,
    shipping_fee DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(12, 2) DEFAULT 0,
    payment_method VARCHAR(30) DEFAULT 'cod',
    payment_status VARCHAR(30) DEFAULT 'pending',
    payment_reference VARCHAR(100),
    estimated_pickup TIMESTAMP,
    estimated_delivery TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng order_items
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity INTEGER DEFAULT 1,
    weight DECIMAL(10, 2),
    price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng feedbacks
CREATE TABLE IF NOT EXISTS feedbacks (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'complaint' or 'feedback'
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng notifications
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'order_status',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo index cho performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_tracking_number ON orders(tracking_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_id ON feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_order_id ON feedbacks(order_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- Bảng lưu lịch sử trạng thái đơn hàng
CREATE TABLE IF NOT EXISTS order_status_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    description TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_status ON order_status_history(status);

-- Bảng giao dịch thanh toán online (mock gateway)
CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    reference VARCHAR(100) NOT NULL,
    provider VARCHAR(50) DEFAULT 'jnt_mock_gateway',
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'VND',
    status VARCHAR(30) DEFAULT 'pending',
    payment_url TEXT,
    signature VARCHAR(128),
    expires_at TIMESTAMP,
    paid_amount DECIMAL(12, 2),
    gateway_payload JSONB,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_transactions_reference ON payment_transactions(reference);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

-- Function để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger để tự động cập nhật updated_at cho users
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger để tự động cập nhật updated_at cho orders
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger để tự động cập nhật updated_at cho feedbacks
CREATE TRIGGER update_feedbacks_updated_at BEFORE UPDATE ON feedbacks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger để tự động cập nhật updated_at cho payment_transactions
CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function và Trigger để tạo thông báo khi trạng thái đơn hàng thay đổi
CREATE OR REPLACE FUNCTION create_order_status_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Chỉ tạo thông báo khi status thay đổi
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO notifications (user_id, order_id, title, message, type)
        VALUES (
            NEW.user_id,
            NEW.id,
            'Trạng thái đơn hàng đã thay đổi',
            'Đơn hàng ' || NEW.tracking_number || ' đã chuyển sang trạng thái: ' || NEW.status,
            'order_status'
        );
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger để tạo thông báo khi orders.status thay đổi
CREATE TRIGGER order_status_change_notification
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION create_order_status_notification();

-- Function và Trigger để ghi lại lịch sử trạng thái đơn hàng
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO order_status_history (order_id, status, description, created_by)
        VALUES (NEW.id, NEW.status, 'Đơn hàng được tạo', 'system');
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.status IS DISTINCT FROM OLD.status THEN
            INSERT INTO order_status_history (order_id, status, description, created_by)
            VALUES (NEW.id, NEW.status, COALESCE(current_setting('order.status_change_description', true), 'Trạng thái được cập nhật'), current_setting('order.status_change_actor', true));
            PERFORM set_config('order.status_change_description', '', true);
            PERFORM set_config('order.status_change_actor', '', true);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger ghi lịch sử khi tạo đơn hàng
CREATE TRIGGER log_order_status_on_insert
    AFTER INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Trigger ghi lịch sử khi trạng thái đơn hàng thay đổi
CREATE TRIGGER log_order_status_on_update
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION log_order_status_change();

-- Function để tạo tracking_number tự động
CREATE OR REPLACE FUNCTION generate_tracking_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tracking_number IS NULL OR NEW.tracking_number = '' THEN
        NEW.tracking_number := 'JNT' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEW.id::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger để tạo tracking_number tự động
CREATE TRIGGER generate_tracking_number_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION generate_tracking_number();

