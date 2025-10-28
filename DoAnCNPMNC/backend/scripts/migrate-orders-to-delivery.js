require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function migrateOrdersTableToDelivery() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('\n🔧 Migrating orders table to support delivery service...\n');
    
    // Add new columns for delivery service
    const alterQueries = [
      // Vehicle information
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(50)`,
      
      // Pickup location
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_address TEXT`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_lat DECIMAL(10, 7)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_lng DECIMAL(10, 7)`,
      
      // Delivery location coordinates
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_lat DECIMAL(10, 7)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_lng DECIMAL(10, 7)`,
      
      // Recipient information
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS recipient_name VARCHAR(255)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS recipient_phone VARCHAR(20)`,
      
      // Distance and duration
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS distance DECIMAL(10, 2)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS duration VARCHAR(50)`,
      
      // Services
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS services JSONB DEFAULT '[]'::jsonb`,
      
      // Pricing breakdown
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS base_fare DECIMAL(10, 2)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_fee DECIMAL(10, 2) DEFAULT 0`,
      
      // Make restaurant_name optional (for delivery service)
      `ALTER TABLE orders ALTER COLUMN restaurant_name DROP NOT NULL`,
      
      // Make items optional (for delivery service)
      `ALTER TABLE orders ALTER COLUMN items DROP NOT NULL`
    ];
    
    for (let i = 0; i < alterQueries.length; i++) {
      console.log(`[${i + 1}/${alterQueries.length}] Executing: ${alterQueries[i].substring(0, 80)}...`);
      await client.query(alterQueries[i]);
    }
    
    await client.query('COMMIT');
    
    console.log('\n✅ Migration completed successfully!');
    console.log('\nNew columns added:');
    console.log('- vehicle_type (loại xe)');
    console.log('- pickup_address, pickup_lat, pickup_lng (điểm đón)');
    console.log('- delivery_lat, delivery_lng (tọa độ giao)');
    console.log('- recipient_name, recipient_phone (người nhận)');
    console.log('- distance, duration (khoảng cách, thời gian)');
    console.log('- services (dịch vụ thêm)');
    console.log('- base_fare, service_fee (giá cơ bản, phí dịch vụ)');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateOrdersTableToDelivery();
