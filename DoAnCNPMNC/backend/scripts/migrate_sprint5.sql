-- Sprint 5 Migration Script
-- US-17: Check-in location tracking
-- US-18: Reason for failed delivery
-- US-19 & US-12: COD confirmation

-- 1. Create shipper_locations table for check-in tracking
CREATE TABLE IF NOT EXISTS shipper_locations (
    id SERIAL PRIMARY KEY,
    shipper_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for shipper_locations
CREATE INDEX IF NOT EXISTS idx_shipper_locations_shipper_id ON shipper_locations(shipper_id);
CREATE INDEX IF NOT EXISTS idx_shipper_locations_order_id ON shipper_locations(order_id);
CREATE INDEX IF NOT EXISTS idx_shipper_locations_created_at ON shipper_locations(created_at DESC);

-- 2. Add reason column to order_status_history (for US-18)
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE order_status_history ADD COLUMN reason TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- 3. Add COD confirmation flags to orders table (for US-19 & US-12)
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE orders ADD COLUMN is_cod_collected BOOLEAN DEFAULT FALSE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE orders ADD COLUMN is_cod_received BOOLEAN DEFAULT FALSE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE orders ADD COLUMN cod_collected_at TIMESTAMP;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE orders ADD COLUMN cod_received_at TIMESTAMP;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE orders ADD COLUMN cod_collected_by INTEGER REFERENCES users(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE orders ADD COLUMN cod_received_by INTEGER REFERENCES users(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- Add comments
COMMENT ON TABLE shipper_locations IS 'Store shipper location check-ins for customer tracking';
COMMENT ON COLUMN order_status_history.reason IS 'Reason for status change, especially for failed deliveries';
COMMENT ON COLUMN orders.is_cod_collected IS 'Whether shipper has collected COD from customer';
COMMENT ON COLUMN orders.is_cod_received IS 'Whether shipper has submitted COD to company';
COMMENT ON COLUMN orders.cod_collected_at IS 'Timestamp when COD collection was confirmed by admin';
COMMENT ON COLUMN orders.cod_received_at IS 'Timestamp when COD submission was confirmed by admin';

