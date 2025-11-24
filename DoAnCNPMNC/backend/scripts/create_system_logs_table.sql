-- Create system_logs table for auditing system activities
-- Run this SQL script to create the system_logs table

CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- e.g., 'LOGIN', 'DELETE_ORDER', 'UPDATE_PRICE', 'CHANGE_PERMISSION'
    target_type VARCHAR(50), -- e.g., 'order', 'user', 'pricing_rule'
    target_id INTEGER, -- ID of the target entity (order_id, user_id, etc.)
    ip_address VARCHAR(45), -- IPv4 or IPv6
    user_agent TEXT, -- Browser/client information
    details JSONB DEFAULT '{}', -- Additional details in JSON format
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_system_logs_user_id ON system_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_action ON system_logs(action);
CREATE INDEX IF NOT EXISTS idx_system_logs_target ON system_logs(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON system_logs(created_at DESC);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_system_logs_user_action ON system_logs(user_id, action);
CREATE INDEX IF NOT EXISTS idx_system_logs_target_type_id ON system_logs(target_type, target_id);

COMMENT ON TABLE system_logs IS 'Audit log for system activities - tracks who did what and when';
COMMENT ON COLUMN system_logs.action IS 'Action performed: LOGIN, DELETE_ORDER, UPDATE_PRICE, CHANGE_PERMISSION, etc.';
COMMENT ON COLUMN system_logs.target_type IS 'Type of entity affected: order, user, pricing_rule, etc.';
COMMENT ON COLUMN system_logs.target_id IS 'ID of the affected entity';
COMMENT ON COLUMN system_logs.details IS 'Additional JSON data about the action';

