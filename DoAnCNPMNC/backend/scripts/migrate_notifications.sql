-- Notifications table migration
-- Run this SQL to add notifications support

-- Add fcm_token to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general', -- general, order, payment, driver, system
    reference_id INTEGER, -- Reference to order_id, payment_id, etc.
    data JSONB DEFAULT '{}', -- Additional data in JSON format
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_is_read ON notifications(user_id, is_read);

COMMENT ON TABLE notifications IS 'Store all user notifications including push notifications';
COMMENT ON COLUMN notifications.type IS 'Notification type: general, order, payment, driver, system';
COMMENT ON COLUMN notifications.reference_id IS 'Reference ID to related entity (order_id, etc)';
COMMENT ON COLUMN notifications.data IS 'Additional JSON data for the notification';
