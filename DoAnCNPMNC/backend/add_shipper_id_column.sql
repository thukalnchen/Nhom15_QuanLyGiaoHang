-- Add shipper_id column to orders table
-- This column links orders to the assigned shipper/driver

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS shipper_id INTEGER;

-- Add foreign key constraint
ALTER TABLE orders 
ADD CONSTRAINT fk_orders_shipper 
FOREIGN KEY (shipper_id) 
REFERENCES users(id) 
ON DELETE SET NULL;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_orders_shipper_id ON orders(shipper_id);

-- Update description
COMMENT ON COLUMN orders.shipper_id IS 'ID của tài xế/shipper được phân công giao đơn hàng này';

-- Show result
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'orders' 
  AND column_name = 'shipper_id';
