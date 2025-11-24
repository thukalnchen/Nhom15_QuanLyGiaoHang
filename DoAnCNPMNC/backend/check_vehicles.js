const { pool } = require('./config/database');

async function checkVehicles() {
  try {
    // Check van and truck orders
    const result = await pool.query(`
      SELECT vehicle_type, status, COUNT(*) as count 
      FROM orders 
      WHERE vehicle_type IN ('van', 'truck') 
      GROUP BY vehicle_type, status 
      ORDER BY vehicle_type, status
    `);
    
    console.log('\n=== Đơn hàng Van và Truck ===');
    console.table(result.rows);
    
    // Check all vehicle types
    const allVehicles = await pool.query(`
      SELECT vehicle_type, COUNT(*) as count 
      FROM orders 
      GROUP BY vehicle_type 
      ORDER BY count DESC
    `);
    
    console.log('\n=== Tất cả loại xe ===');
    console.table(allVehicles.rows);
    
    // Check delivered orders by vehicle
    const delivered = await pool.query(`
      SELECT vehicle_type, COUNT(*) as count, SUM(total_amount) as revenue
      FROM orders 
      WHERE status = 'delivered'
      GROUP BY vehicle_type 
      ORDER BY revenue DESC
    `);
    
    console.log('\n=== Đơn đã giao theo loại xe ===');
    console.table(delivered.rows);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkVehicles();
