/**
 * Test script to verify shipper location check-in and retrieval
 * Usage: node scripts/test_shipper_location.js <order_id>
 */

require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function testShipperLocation(orderId) {
  console.log('🧪 Testing shipper location for order:', orderId);
  console.log('='.repeat(60));
  console.log('');

  try {
    // 1. Check if order exists
    console.log('\n1️⃣ Checking order...');
    const orderResult = await pool.query(
      'SELECT id, order_number, user_id, shipper_id, status FROM orders WHERE id = $1',
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      console.log('❌ Order not found!');
      return;
    }

    const order = orderResult.rows[0];
    console.log('✅ Order found:');
    console.log('   ID:', order.id);
    console.log('   Order Number:', order.order_number);
    console.log('   Customer User ID:', order.user_id || 'NULL');
    console.log('   Shipper ID:', order.shipper_id || 'NULL');
    console.log('   Status:', order.status);
    
    if (!order.user_id) {
      console.log('\n⚠️  WARNING: Order does not have a customer user_id!');
    }

    if (!order.shipper_id) {
      console.log('\n⚠️  Order does not have a shipper assigned!');
      return;
    }

    // 2. Check shipper locations
    console.log('\n2️⃣ Checking shipper locations...');
    const locationResult = await pool.query(
      `SELECT 
        sl.id,
        sl.order_id,
        sl.shipper_id,
        sl.latitude,
        sl.longitude,
        sl.address,
        sl.created_at,
        u.full_name as shipper_name
       FROM shipper_locations sl
       LEFT JOIN users u ON u.id = sl.shipper_id
       WHERE sl.order_id = $1
       ORDER BY sl.created_at DESC`,
      [orderId]
    );

    console.log(`   Found ${locationResult.rows.length} location(s):`);
    if (locationResult.rows.length === 0) {
      console.log('   ❌ No locations found!');
    } else {
      locationResult.rows.forEach((loc, index) => {
        console.log(`\n   Location ${index + 1}:`);
        console.log('     ID:', loc.id);
        console.log('     Order ID:', loc.order_id);
        console.log('     Shipper ID:', loc.shipper_id);
        console.log('     Shipper Name:', loc.shipper_name || 'N/A');
        console.log('     Coordinates:', loc.latitude, ',', loc.longitude);
        console.log('     Address:', loc.address || 'N/A');
        console.log('     Created at:', loc.created_at);
      });
    }

    // 3. Check latest location
    console.log('\n3️⃣ Latest location (for API):');
    const latestResult = await pool.query(
      `SELECT 
        sl.id,
        sl.latitude,
        sl.longitude,
        sl.address,
        sl.created_at,
        u.full_name as shipper_name,
        u.phone as shipper_phone
       FROM shipper_locations sl
       LEFT JOIN users u ON u.id = sl.shipper_id
       WHERE sl.order_id = $1
       ORDER BY sl.created_at DESC
       LIMIT 1`,
      [orderId]
    );

    if (latestResult.rows.length > 0) {
      const latest = latestResult.rows[0];
      console.log('   ✅ Latest location found:');
      console.log('     ID:', latest.id);
      console.log('     Coordinates:', latest.latitude, ',', latest.longitude);
      console.log('     Shipper:', latest.shipper_name || 'N/A');
      console.log('     Created at:', latest.created_at);
    } else {
      console.log('   ❌ No latest location found!');
    }

    console.log('\n' + '='.repeat(60));
    console.log('✅ Test completed!');
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

// Get order_id from command line
const orderIdArg = process.argv[2];

if (!orderIdArg) {
  console.log('❌ Usage: node scripts/test_shipper_location.js <order_id>');
  console.log('   Example: node scripts/test_shipper_location.js 123');
  process.exit(1);
}

const orderId = parseInt(orderIdArg);

if (isNaN(orderId)) {
  console.log('❌ Error: order_id phải là số hợp lệ');
  console.log('   Bạn đã nhập:', orderIdArg);
  console.log('   Usage: node scripts/test_shipper_location.js <order_id>');
  console.log('   Example: node scripts/test_shipper_location.js 123');
  process.exit(1);
}

testShipperLocation(orderId);

