require('dotenv').config({ path: './config.env' });
const readline = require('readline');
const { pool } = require('../config/database');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

async function assignOrder(orderNumber, shipperEmail) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const shipperResult = await client.query(
      `SELECT id, role, status FROM users WHERE email = $1`,
      [shipperEmail],
    );
    if (shipperResult.rows.length === 0) {
      throw new Error(`Không tìm thấy shipper với email ${shipperEmail}`);
    }
    const shipper = shipperResult.rows[0];
    if (shipper.role !== 'shipper') {
      throw new Error(`Người dùng ${shipperEmail} không có role shipper (role hiện tại: ${shipper.role})`);
    }
    if (shipper.status !== 'approved') {
      throw new Error(`Tài khoản shipper chưa được duyệt (trạng thái hiện tại: ${shipper.status || 'unknown'})`);
    }

    const orderResult = await client.query(
      `SELECT id, order_number FROM orders WHERE order_number = $1`,
      [orderNumber],
    );
    if (orderResult.rows.length === 0) {
      throw new Error(`Không tìm thấy đơn hàng với mã ${orderNumber}`);
    }
    const order = orderResult.rows[0];

    await client.query(
      `UPDATE orders
       SET shipper_id = $1,
           status = CASE WHEN status = 'pending' THEN 'assigned_to_driver' ELSE status END,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [shipper.id, order.id],
    );

    await client.query(
      `INSERT INTO order_status_history (order_id, status, notes)
       VALUES ($1, $2, $3)`,
      [order.id, 'assigned_to_driver', `Đơn hàng được gán cho ${shipperEmail}`],
    );

    await client.query('COMMIT');

    console.log(`✅ Đã gán đơn ${order.order_number} cho shipper ${shipperEmail}`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Lỗi:', error.message);
  } finally {
    client.release();
    await pool.end();
    rl.close();
  }
}

function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

async function main() {
  const orderNumber = await ask('Nhập mã đơn hàng (order_number): ');
  const shipperEmail = await ask('Nhập email shipper: ');
  if (!orderNumber || !shipperEmail) {
    console.error('❌ order_number và shipper email là bắt buộc');
    process.exit(1);
  }
  await assignOrder(orderNumber.trim(), shipperEmail.trim());
}

main();


