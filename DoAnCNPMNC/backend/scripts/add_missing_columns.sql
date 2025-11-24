-- Add missing columns to orders table for Lalamove integration
-- Run this script if you get 500 error when creating orders

-- Check if columns exist before adding them
DO $$ 
BEGIN
    -- Add sender_name if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='sender_name') THEN
        ALTER TABLE orders ADD COLUMN sender_name VARCHAR(255);
        RAISE NOTICE 'Added sender_name column';
    END IF;

    -- Add sender_phone if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='sender_phone') THEN
        ALTER TABLE orders ADD COLUMN sender_phone VARCHAR(20);
        RAISE NOTICE 'Added sender_phone column';
    END IF;

    -- Add receiver_name if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='receiver_name') THEN
        ALTER TABLE orders ADD COLUMN receiver_name VARCHAR(255);
        RAISE NOTICE 'Added receiver_name column';
    END IF;

    -- Add receiver_phone if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='receiver_phone') THEN
        ALTER TABLE orders ADD COLUMN receiver_phone VARCHAR(20);
        RAISE NOTICE 'Added receiver_phone column';
    END IF;

    -- Add pickup_location if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='pickup_location') THEN
        ALTER TABLE orders ADD COLUMN pickup_location TEXT;
        RAISE NOTICE 'Added pickup_location column';
    END IF;

    -- Add delivery_location if not exists (this might be same as delivery_address)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='delivery_location') THEN
        ALTER TABLE orders ADD COLUMN delivery_location TEXT;
        RAISE NOTICE 'Added delivery_location column';
    END IF;

    -- Add vehicle_type if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='vehicle_type') THEN
        ALTER TABLE orders ADD COLUMN vehicle_type VARCHAR(50);
        RAISE NOTICE 'Added vehicle_type column';
    END IF;

    -- Add payment_method if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='payment_method') THEN
        ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50) DEFAULT 'cod';
        RAISE NOTICE 'Added payment_method column';
    END IF;

    -- Add payment_status if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='payment_status') THEN
        ALTER TABLE orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending';
        RAISE NOTICE 'Added payment_status column';
    END IF;

    -- Add customer_estimated_size if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='customer_estimated_size') THEN
        ALTER TABLE orders ADD COLUMN customer_estimated_size VARCHAR(50);
        RAISE NOTICE 'Added customer_estimated_size column';
    END IF;

    -- Add customer_requested_vehicle if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='orders' AND column_name='customer_requested_vehicle') THEN
        ALTER TABLE orders ADD COLUMN customer_requested_vehicle VARCHAR(50);
        RAISE NOTICE 'Added customer_requested_vehicle column';
    END IF;

END $$;

-- Show current table structure
SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;
