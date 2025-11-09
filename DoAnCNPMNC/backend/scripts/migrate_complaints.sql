-- Complaints table migration
-- Run this SQL to add complaint management support

-- Create complaints table
CREATE TABLE IF NOT EXISTS complaints (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    complaint_type VARCHAR(50) NOT NULL, -- product_issue, delivery_issue, driver_issue, payment_issue, other
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, urgent
    status VARCHAR(20) DEFAULT 'open', -- open, in_progress, resolved, closed
    evidence_images JSONB DEFAULT '[]', -- Array of image paths
    resolution_note TEXT,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create complaint_responses table for conversation history
CREATE TABLE IF NOT EXISTS complaint_responses (
    id SERIAL PRIMARY KEY,
    complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_role VARCHAR(20) NOT NULL, -- customer, admin, intake_staff, driver
    message TEXT NOT NULL,
    attachments JSONB DEFAULT '[]', -- Array of attachment paths
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_complaints_user_id ON complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_order_id ON complaints(order_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON complaints(priority);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON complaints(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_complaint_responses_complaint_id ON complaint_responses(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_responses_created_at ON complaint_responses(created_at ASC);

-- Add constraints
ALTER TABLE complaints ADD CONSTRAINT chk_complaint_type 
    CHECK (complaint_type IN ('product_issue', 'delivery_issue', 'driver_issue', 'payment_issue', 'service_issue', 'other'));

ALTER TABLE complaints ADD CONSTRAINT chk_priority 
    CHECK (priority IN ('low', 'medium', 'high', 'urgent'));

ALTER TABLE complaints ADD CONSTRAINT chk_status 
    CHECK (status IN ('open', 'in_progress', 'resolved', 'closed'));

COMMENT ON TABLE complaints IS 'Store customer complaints and feedback';
COMMENT ON TABLE complaint_responses IS 'Store complaint conversation history';
COMMENT ON COLUMN complaints.complaint_type IS 'Type of complaint: product_issue, delivery_issue, driver_issue, payment_issue, service_issue, other';
COMMENT ON COLUMN complaints.priority IS 'Priority level: low, medium, high, urgent';
COMMENT ON COLUMN complaints.status IS 'Status: open, in_progress, resolved, closed';
COMMENT ON COLUMN complaints.evidence_images IS 'JSON array of evidence image file paths';
