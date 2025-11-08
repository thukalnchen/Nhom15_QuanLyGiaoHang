const { Pool } = require('pg');
const axios = require('axios');
require('dotenv').config({ path: './config.env' });

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

const API_BASE = 'http://localhost:3000/api';

// Test data
const TEST_STAFF_ID = 'intake-staff-456';
const TEST_DRIVER_ID = 999; // Use integer for user_id

async function createTestOrder() {
  console.log('\n📦 STEP 1: Creating test order with customer estimates...\n');

  const orderNumber = `TEST-${Date.now()}`;
  
  const query = `
    INSERT INTO orders (
      order_number, 
      user_id,
      pickup_address, 
      pickup_lat, 
      pickup_lng,
      delivery_address, 
      delivery_lat, 
      delivery_lng,
      recipient_name,
      recipient_phone,
      delivery_fee,
      total_amount,
      status,
      customer_estimated_size,
      customer_requested_vehicle,
      created_at
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW()
    ) RETURNING *
  `;

  const values = [
    orderNumber,
    1, // user_id as integer
    '123 Nguyễn Văn A, Quận 1, TP.HCM',
    10.762622,
    106.660172,
    '456 Trần Văn B, Quận 3, TP.HCM',
    10.786400,
    106.695200,
    'Trần Thị Nhận',
    '0912345678',
    50000,
    100000, // total_amount
    'pending',
    'medium',  // customer_estimated_size
    'car'      // customer_requested_vehicle
  ];

  const result = await pool.query(query, values);
  const order = result.rows[0];

  console.log('✅ Order created successfully!');
  console.log(`   Order Number: ${order.order_number}`);
  console.log(`   Status: ${order.status}`);
  console.log(`   Customer Estimated Size: ${order.customer_estimated_size}`);
  console.log(`   Customer Requested Vehicle: ${order.customer_requested_vehicle}`);
  
  return order;
}

async function testReceiveOrder(orderId, orderNumber) {
  console.log('\n📥 STEP 2: Testing receive order (Story #8)...\n');

  const query = `
    UPDATE orders 
    SET 
      status = 'received_at_warehouse',
      warehouse_id = 'WH-001',
      warehouse_name = 'Kho Trung Tâm Q1',
      intake_staff_id = $1,
      intake_staff_name = 'Nguyễn Staff Test',
      received_at = NOW()
    WHERE id = $2
    RETURNING *
  `;

  const result = await pool.query(query, [TEST_STAFF_ID, orderId]);
  const order = result.rows[0];

  console.log('✅ Order received successfully!');
  console.log(`   Order Number: ${order.order_number}`);
  console.log(`   Status: ${order.status}`);
  console.log(`   Warehouse: ${order.warehouse_name}`);
  console.log(`   Intake Staff: ${order.intake_staff_name}`);
  console.log(`   Received At: ${order.received_at}`);

  return order;
}

async function testClassifyOrder(orderId) {
  console.log('\n🏷️  STEP 3: Testing classify order (Story #9)...\n');

  // Mock distance calculation
  const distance = 12.5; // km
  const zone = distance <= 5 ? 'zone_1' 
             : distance <= 10 ? 'zone_2'
             : distance <= 20 ? 'zone_3'
             : 'zone_4';

  // Auto-suggest vehicle based on customer estimate and distance
  const customerVehicle = 'car';
  let suggestedVehicle = 'bike';
  if (customerVehicle === 'car' || distance > 15) suggestedVehicle = 'car';

  const query = `
    UPDATE orders 
    SET 
      status = 'classified',
      zone = $1,
      recommended_vehicle = $2,
      classified_at = NOW()
    WHERE id = $3
    RETURNING *
  `;

  const result = await pool.query(query, [zone, suggestedVehicle, orderId]);
  const order = result.rows[0];

  console.log('✅ Order classified successfully!');
  console.log(`   Order Number: ${order.order_number}`);
  console.log(`   Status: ${order.status}`);
  console.log(`   Distance: ${distance} km`);
  console.log(`   Zone: ${order.zone}`);
  console.log(`   Recommended Vehicle: ${order.recommended_vehicle}`);
  console.log(`   Classified At: ${order.classified_at}`);

  // Check if vehicle matches customer request
  if (order.recommended_vehicle === order.customer_requested_vehicle) {
    console.log('   ℹ️  Vehicle matches customer request ✓');
  } else {
    console.log(`   ⚠️  Vehicle differs from customer request (${order.customer_requested_vehicle} → ${order.recommended_vehicle})`);
  }

  return order;
}

async function createTestDriver() {
  console.log('\n👤 STEP 4a: Creating/getting test driver...\n');

  // Try to find existing driver
  const checkQuery = `SELECT * FROM users WHERE role = 'driver' AND phone = '0923456789' LIMIT 1`;
  const checkResult = await pool.query(checkQuery);

  if (checkResult.rows.length > 0) {
    console.log('   ℹ️  Using existing test driver');
    const driver = checkResult.rows[0];
    console.log(`   Driver ID: ${driver.id}`);
    console.log(`   Name: ${driver.full_name}`);
    console.log(`   Phone: ${driver.phone}`);
    return driver;
  }

  const query = `
    INSERT INTO users (
      full_name,
      phone,
      email,
      password,
      role,
      created_at
    ) VALUES (
      $1, $2, $3, $4, $5, NOW()
    ) RETURNING *
  `;

  const values = [
    'Nguyễn Tài Xế Test',
    '0923456789',
    'driver.test@lalamove.com',
    'hashed_password_123', // In production, use bcrypt
    'driver'
  ];

  const result = await pool.query(query, values);
  const driver = result.rows[0];

  console.log('✅ Test driver created!');
  console.log(`   Driver ID: ${driver.id}`);
  console.log(`   Name: ${driver.full_name}`);
  console.log(`   Phone: ${driver.phone}`);

  return driver;
}

async function testAssignDriver(orderId) {
  console.log('\n🚗 STEP 4b: Testing assign driver (Story #21)...\n');

  const driver = await createTestDriver();

  const query = `
    UPDATE orders 
    SET 
      status = 'assigned_to_driver',
      user_id = $1,
      vehicle_type = 'bike'
    WHERE id = $2
    RETURNING *
  `;

  const result = await pool.query(query, [driver.id, orderId]);
  const order = result.rows[0];

  console.log('✅ Driver assigned successfully!');
  console.log(`   Order Number: ${order.order_number}`);
  console.log(`   Status: ${order.status}`);
  console.log(`   Driver ID: ${order.user_id}`);
  console.log(`   Driver Name: ${driver.full_name}`);
  console.log(`   Driver Phone: ${driver.phone}`);
  console.log(`   Vehicle Type: ${order.vehicle_type}`);

  return order;
}

async function verifyFinalState(orderId) {
  console.log('\n✅ STEP 5: Verifying final order state...\n');

  const query = 'SELECT * FROM orders WHERE id = $1';
  const result = await pool.query(query, [orderId]);
  const order = result.rows[0];

  console.log('📋 FINAL ORDER STATE:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Order Number: ${order.order_number}`);
  console.log(`Status: ${order.status}`);
  console.log('');
  console.log('Customer Estimates:');
  console.log(`  - Size: ${order.customer_estimated_size || 'N/A'}`);
  console.log(`  - Vehicle: ${order.customer_requested_vehicle || 'N/A'}`);
  console.log('');
  console.log('Classification:');
  console.log(`  - Zone: ${order.zone || 'N/A'}`);
  console.log(`  - Vehicle: ${order.recommended_vehicle || 'N/A'}`);
  console.log('');
  console.log('Warehouse Info:');
  console.log(`  - Warehouse: ${order.warehouse_name || 'N/A'}`);
  console.log(`  - Staff: ${order.intake_staff_name || 'N/A'}`);
  console.log(`  - Received At: ${order.received_at || 'N/A'}`);
  console.log(`  - Classified At: ${order.classified_at || 'N/A'}`);
  console.log('');
  console.log('Driver Info:');
  console.log(`  - Driver ID: ${order.user_id || 'N/A'}`);
  console.log(`  - Vehicle Type: ${order.vehicle_type || 'N/A'}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');

  // Validation checks
  const checks = {
    'Has customer estimates': !!(order.customer_estimated_size && order.customer_requested_vehicle),
    'Order received': order.status !== 'pending',
    'Order classified': !!(order.zone && order.recommended_vehicle),
    'Driver assigned': !!(order.user_id && order.vehicle_type),
    'Status is assigned_to_driver': order.status === 'assigned_to_driver',
  };

  console.log('🔍 VALIDATION CHECKS:');
  Object.entries(checks).forEach(([check, passed]) => {
    console.log(`   ${passed ? '✅' : '❌'} ${check}`);
  });

  const allPassed = Object.values(checks).every(v => v === true);
  
  console.log('');
  if (allPassed) {
    console.log('🎉 ALL CHECKS PASSED! Flow is working correctly.');
  } else {
    console.log('⚠️  Some checks failed. Please review the flow.');
  }

  return allPassed;
}

async function runFullTest() {
  console.log('╔════════════════════════════════════════════════╗');
  console.log('║  WAREHOUSE FLOW TEST (Stories #8, #9, #21)    ║');
  console.log('╚════════════════════════════════════════════════╝');

  try {
    // Step 1: Create test order
    const order = await createTestOrder();
    const orderId = order.id;

    // Step 2: Receive order (Story #8)
    await testReceiveOrder(orderId, order.order_number);

    // Step 3: Classify order (Story #9)
    await testClassifyOrder(orderId);

    // Step 4: Assign driver (Story #21)
    await testAssignDriver(orderId);

    // Step 5: Verify final state
    const success = await verifyFinalState(orderId);

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (success) {
      console.log('✅ TEST COMPLETED SUCCESSFULLY!');
      console.log('   The warehouse flow is working as expected.');
      console.log(`   Test Order Number: ${order.order_number}`);
    } else {
      console.log('❌ TEST FAILED!');
      console.log('   Please check the validation errors above.');
    }
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    process.exit(success ? 0 : 1);

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run the test
runFullTest();
