/**
 * Test API endpoint for shipper location
 * Usage: node scripts/test_api_shipper_location.js <order_id> <customer_user_id>
 */

require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');
const jwt = require('jsonwebtoken');

async function testApiShipperLocation(orderId, customerUserId) {
  console.log('🧪 Testing API endpoint for shipper location');
  console.log('='.repeat(60));
  console.log('Order ID:', orderId);
  console.log('Customer User ID:', customerUserId);
  console.log('');

  try {
    // 1. Check order ownership
    console.log('1️⃣ Checking order ownership...');
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
    console.log('   Customer User ID:', order.user_id);
    console.log('   Shipper ID:', order.shipper_id || 'NULL');
    console.log('   Status:', order.status);

    if (order.user_id != customerUserId) {
      console.log('\n⚠️  WARNING: Order does not belong to this customer!');
      console.log('   Order user_id:', order.user_id);
      console.log('   Customer user_id:', customerUserId);
      console.log('   This will cause API to return 404!');
    }

    if (!order.shipper_id) {
      console.log('\n⚠️  Order does not have a shipper assigned!');
      return;
    }

    // 2. Check locations
    console.log('\n2️⃣ Checking shipper locations...');
    const locationResult = await pool.query(
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

    if (locationResult.rows.length === 0) {
      console.log('   ❌ No locations found!');
      return;
    }

    const location = locationResult.rows[0];
    console.log('   ✅ Latest location found:');
    console.log('     ID:', location.id);
    console.log('     Coordinates:', location.latitude, ',', location.longitude);
    console.log('     Shipper:', location.shipper_name || 'N/A');
    console.log('     Created at:', location.created_at);

    // 3. Simulate API response
    console.log('\n3️⃣ Expected API Response:');
    const expectedResponse = {
      status: 'success',
      data: {
        location: {
          id: location.id,
          latitude: parseFloat(location.latitude),
          longitude: parseFloat(location.longitude),
          address: location.address,
          created_at: location.created_at,
          shipper: location.shipper_name ? {
            name: location.shipper_name,
            phone: location.shipper_phone
          } : null
        }
      }
    };
    console.log(JSON.stringify(expectedResponse, null, 2));

    // 4. Test query (same as API)
    console.log('\n4️⃣ Testing API query...');
    const apiQueryResult = await pool.query(
      'SELECT id, shipper_id FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, customerUserId]
    );

    if (apiQueryResult.rows.length === 0) {
      console.log('   ❌ API query will return 404!');
      console.log('   Reason: Order does not belong to this customer');
      console.log('   Solution: Use the correct customer user_id');
    } else {
      console.log('   ✅ API query will succeed');
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

// Get parameters from command line
const orderIdArg = process.argv[2];
const customerUserIdArg = process.argv[3];

if (!orderIdArg || !customerUserIdArg) {
  console.log('❌ Usage: node scripts/test_api_shipper_location.js <order_id> <customer_user_id>');
  console.log('   Example: node scripts/test_api_shipper_location.js 38 5');
  console.log('');
  console.log('   To find customer_user_id for an order:');
  console.log('   SELECT id, user_id, order_number FROM orders WHERE id = <order_id>;');
  process.exit(1);
}

const orderId = parseInt(orderIdArg);
const customerUserId = parseInt(customerUserIdArg);

if (isNaN(orderId) || isNaN(customerUserId)) {
  console.log('❌ Error: order_id and customer_user_id must be valid numbers');
  process.exit(1);
}

testApiShipperLocation(orderId, customerUserId);

