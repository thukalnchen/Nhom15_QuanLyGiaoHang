const { pool } = require('./config/database');

async function updateToDelivered() {
  try {
    // Update van orders to delivered
    const van = await pool.query(`
      UPDATE orders 
      SET status = 'delivered' 
      WHERE vehicle_type = 'van' AND status IN ('assigned', 'in_transit')
      RETURNING id, vehicle_type, status, total_amount
    `);
    
    console.log('\n=== Đã cập nhật đơn Van sang Delivered ===');
    console.table(van.rows);
    
    // Update truck orders to delivered
    const truck = await pool.query(`
      UPDATE orders 
      SET status = 'delivered' 
      WHERE vehicle_type = 'truck' AND status IN ('assigned', 'processing')
      RETURNING id, vehicle_type, status, total_amount
    `);
    
    console.log('\n=== Đã cập nhật đơn Truck sang Delivered ===');
    console.table(truck.rows);
    
    // Show summary
    const summary = await pool.query(`
      SELECT vehicle_type, COUNT(*) as count, SUM(total_amount) as revenue
      FROM orders 
      WHERE status = 'delivered'
      GROUP BY vehicle_type 
      ORDER BY revenue DESC
    `);
    
    console.log('\n=== Tổng hợp đơn đã giao theo loại xe ===');
    console.table(summary.rows);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

updateToDelivered();
