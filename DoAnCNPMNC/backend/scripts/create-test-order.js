require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

async function createTestOrder() {
  try {
    // Get first user
    const userResult = await pool.query('SELECT id, email FROM users LIMIT 1');
    
    if (userResult.rows.length === 0) {
      console.log('No users found. Please register a user first.');
      await pool.end();
      return;
    }

    const user = userResult.rows[0];
    console.log('Creating test delivery order for user:', user.email);

    // Generate unique order number
    const orderNumber = `DLV-${Date.now()}-${uuidv4().substring(0, 8).toUpperCase()}`;

    // Create delivery order
    const orderData = {
      order_number: orderNumber,
      user_id: user.id,
      vehicle_type: 'motorcycle',
      pickup_address: 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM',
      pickup_lat: 10.7829,
      pickup_lng: 106.6893,
      delivery_address: 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM',
      delivery_lat: 10.7946,
      delivery_lng: 106.7218,
      recipient_name: 'Nguyễn Văn A',
      recipient_phone: '0901234567',
      distance: 3.78,
      duration: '8 phút',
      services: JSON.stringify(['Giao hàng nhanh', 'Gọi trước khi đến']),
      notes: 'Giao hàng giờ hành chính. Gọi trước 5 phút.',
      base_fare: 18904,
      service_fee: 5000,
      total_amount: 23904,
      status: 'pending'
    };

    const result = await pool.query(
      `INSERT INTO orders (
        order_number, user_id, vehicle_type, pickup_address, pickup_lat, pickup_lng,
        delivery_address, delivery_lat, delivery_lng, recipient_name, recipient_phone,
        distance, duration, services, notes, base_fare, service_fee, total_amount, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
      RETURNING *`,
      [
        orderData.order_number,
        orderData.user_id,
        orderData.vehicle_type,
        orderData.pickup_address,
        orderData.pickup_lat,
        orderData.pickup_lng,
        orderData.delivery_address,
        orderData.delivery_lat,
        orderData.delivery_lng,
        orderData.recipient_name,
        orderData.recipient_phone,
        orderData.distance,
        orderData.duration,
        orderData.services,
        orderData.notes,
        orderData.base_fare,
        orderData.service_fee,
        orderData.total_amount,
        orderData.status
      ]
    );

    const order = result.rows[0];

    // Add status history
    await pool.query(
      'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
      [order.id, 'pending', 'Đơn hàng đã được tạo']
    );

    // Initialize delivery tracking
    await pool.query(
      'INSERT INTO delivery_tracking (order_id, status) VALUES ($1, $2)',
      [order.id, 'preparing']
    );

    console.log('\n✅ Test order created successfully!');
    console.log('Order Number:', order.order_number);
    console.log('Order ID:', order.id);
    console.log('Vehicle:', order.vehicle_type);
    console.log('Route:', orderData.pickup_address, '→', orderData.delivery_address);
    console.log('Distance:', orderData.distance, 'km');
    console.log('Total:', orderData.total_amount, 'đ');
    console.log('Status:', order.status);

    await pool.end();
  } catch (error) {
    console.error('Error creating test order:', error);
    await pool.end();
  }
}

createTestOrder();
