require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function checkOrders() {
  try {
    // Check total orders
    const countResult = await pool.query('SELECT COUNT(*) FROM orders');
    console.log('\n📊 Total orders in database:', countResult.rows[0].count);
    
    // Get recent orders
    const result = await pool.query(`
      SELECT 
        id, 
        order_number, 
        vehicle_type,
        pickup_address,
        delivery_address,
        total_amount,
        status,
        created_at,
        user_id
      FROM orders 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    
    if (result.rows.length === 0) {
      console.log('\n❌ No orders found in database!');
      console.log('\nTry creating an order in the app first.');
    } else {
      console.log('\n✅ Recent orders:');
      console.log('='.repeat(100));
      result.rows.forEach((order, index) => {
        console.log(`\n${index + 1}. Order #${order.order_number}`);
        console.log(`   User ID: ${order.user_id}`);
        console.log(`   Vehicle: ${order.vehicle_type || 'N/A'}`);
        console.log(`   From: ${order.pickup_address?.substring(0, 50) || 'N/A'}...`);
        console.log(`   To: ${order.delivery_address?.substring(0, 50) || 'N/A'}...`);
        console.log(`   Amount: ${order.total_amount} đ`);
        console.log(`   Status: ${order.status}`);
        console.log(`   Created: ${order.created_at}`);
      });
      console.log('='.repeat(100));
    }
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    await pool.end();
  }
}

checkOrders();
