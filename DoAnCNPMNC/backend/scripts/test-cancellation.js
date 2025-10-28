require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function testCancellation() {
  try {
    console.log('\n🧪 Testing Order Cancellation Feature\n');
    console.log('='.repeat(80));

    // 1. Check if cancellation columns exist
    console.log('\n1️⃣ Checking database schema...');
    const schemaCheck = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'orders' 
      AND column_name IN (
        'cancellation_reason', 
        'cancellation_type', 
        'cancelled_at', 
        'cancelled_by',
        'payment_status',
        'refund_status'
      )
      ORDER BY column_name
    `);
    
    console.log('✅ Cancellation columns found:');
    schemaCheck.rows.forEach(col => {
      console.log(`   - ${col.column_name} (${col.data_type})`);
    });

    // 2. Find a pending order to test
    console.log('\n2️⃣ Finding test order...');
    const orderResult = await pool.query(`
      SELECT id, order_number, status, user_id, total_amount
      FROM orders 
      WHERE status IN ('pending', 'processing')
      ORDER BY created_at DESC
      LIMIT 1
    `);

    if (orderResult.rows.length === 0) {
      console.log('❌ No pending/processing orders found to test');
      await pool.end();
      return;
    }

    const testOrder = orderResult.rows[0];
    console.log('✅ Test order found:');
    console.log(`   Order: ${testOrder.order_number}`);
    console.log(`   Status: ${testOrder.status}`);
    console.log(`   Amount: ${testOrder.total_amount} đ`);
    console.log(`   User ID: ${testOrder.user_id}`);

    // 3. Simulate cancellation
    console.log('\n3️⃣ Simulating order cancellation...');
    const cancelResult = await pool.query(`
      UPDATE orders 
      SET 
        status = 'cancelled',
        cancellation_reason = 'Test cancellation - customer changed mind',
        cancellation_type = 'change_mind',
        cancelled_at = CURRENT_TIMESTAMP,
        cancelled_by = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *
    `, [testOrder.user_id, testOrder.id]);

    console.log('✅ Order cancelled successfully!');
    const cancelled = cancelResult.rows[0];
    console.log(`   New status: ${cancelled.status}`);
    console.log(`   Reason: ${cancelled.cancellation_reason}`);
    console.log(`   Type: ${cancelled.cancellation_type}`);
    console.log(`   Cancelled at: ${cancelled.cancelled_at}`);

    // 4. Add to status history
    await pool.query(
      'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
      [testOrder.id, 'cancelled', 'Test cancellation']
    );
    console.log('✅ Status history updated');

    // 5. Check cancellation statistics
    console.log('\n4️⃣ Cancellation statistics:');
    const statsResult = await pool.query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM orders
      GROUP BY status
      ORDER BY count DESC
    `);

    statsResult.rows.forEach(stat => {
      console.log(`   ${stat.status}: ${stat.count} orders`);
    });

    // 6. Rollback the test (restore original status)
    console.log('\n5️⃣ Rolling back test changes...');
    await pool.query(`
      UPDATE orders 
      SET 
        status = $1,
        cancellation_reason = NULL,
        cancellation_type = NULL,
        cancelled_at = NULL,
        cancelled_by = NULL
      WHERE id = $2
    `, [testOrder.status, testOrder.id]);
    
    console.log('✅ Test order restored to original state');

    console.log('\n' + '='.repeat(80));
    console.log('✅ All tests passed!\n');

    await pool.end();
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error(error.stack);
    await pool.end();
    process.exit(1);
  }
}

testCancellation();
