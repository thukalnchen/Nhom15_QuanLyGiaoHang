const { pool } = require('./config/database');

async function checkWeights() {
  try {
    const result = await pool.query(
      "SELECT id, order_code, weight, package_size, status FROM orders WHERE status='received_at_warehouse' ORDER BY created_at DESC LIMIT 5"
    );
    
    console.log('Orders ready for classification:');
    console.log(JSON.stringify(result.rows, null, 2));
    
    // Check data types
    if (result.rows.length > 0) {
      const firstOrder = result.rows[0];
      console.log('\n--- Type Check ---');
      console.log('weight value:', firstOrder.weight);
      console.log('weight type:', typeof firstOrder.weight);
      console.log('package_size type:', typeof firstOrder.package_size);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit();
  }
}

checkWeights();
