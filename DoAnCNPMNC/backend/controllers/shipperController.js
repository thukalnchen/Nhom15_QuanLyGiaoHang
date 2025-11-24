const Joi = require('joi');
const { pool } = require('../config/database');
const { sendNotificationToUser } = require('./notificationController');

const statusUpdateSchema = Joi.object({
  status: Joi.string().required(),
  notes: Joi.string().allow('', null),
  reason: Joi.string().allow('', null), // US-18: Reason for failed delivery
});

const statusMap = {
  DELIVERING: 'in_transit',
  IN_TRANSIT: 'in_transit',
  ASSIGNED: 'assigned_to_driver',
  START_DELIVERY: 'in_transit',
  DELIVERED: 'delivered',
  DELIVERED_SUCCESS: 'delivered',
  SUCCESS: 'delivered',
  COMPLETED: 'delivered',
  FAILED: 'failed_delivery',
  DELIVERY_FAILED: 'failed_delivery',
  FAILED_DELIVERY: 'failed_delivery',
  RETURNING: 'returning',
  RETURNED: 'returned',
};

const buildOrderResponse = (row) => ({
  id: row.id,
  order_number: row.order_number,
  status: row.status,
  delivery_status: row.delivery_status || row.status,
  delivery_address: row.delivery_address,
  delivery_lat: row.delivery_lat ? parseFloat(row.delivery_lat) : null,
  delivery_lng: row.delivery_lng ? parseFloat(row.delivery_lng) : null,
  pickup_address: row.pickup_address,
  pickup_lat: row.pickup_lat ? parseFloat(row.pickup_lat) : null,
  pickup_lng: row.pickup_lng ? parseFloat(row.pickup_lng) : null,
  recipient_name: row.recipient_name,
  recipient_phone: row.recipient_phone,
  delivery_phone: row.delivery_phone,
  distance: row.distance ? parseFloat(row.distance) : null,
  duration: row.duration,
  total_amount: row.total_amount ? parseFloat(row.total_amount) : null,
  delivery_fee: row.delivery_fee ? parseFloat(row.delivery_fee) : null,
  notes: row.notes,
  created_at: row.created_at,
  updated_at: row.updated_at,
  customer: row.customer_id
    ? {
        id: row.customer_id,
        full_name: row.customer_name,
        phone: row.customer_phone,
        email: row.customer_email,
      }
    : null,
});

const getMyOrders = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

    let baseQuery = `
      SELECT 
        o.*, 
        dt.status AS delivery_status,
        dt.latitude,
        dt.longitude,
        u.id AS customer_id,
        u.full_name AS customer_name,
        u.phone AS customer_phone,
        u.email AS customer_email
      FROM orders o
      LEFT JOIN LATERAL (
        SELECT status, latitude, longitude
        FROM delivery_tracking
        WHERE order_id = o.id
        ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST
        LIMIT 1
      ) dt ON true
      LEFT JOIN users u ON u.id = o.user_id
      WHERE o.shipper_id = $1
    `;
    const params = [req.user.id];
    let paramIndex = 2;

    if (status) {
      baseQuery += ` AND o.status = $${paramIndex}`;
      params.push(status);
      paramIndex += 1;
    }

    baseQuery += ` ORDER BY o.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit, 10), offset);

    const result = await pool.query(baseQuery, params);

    const countQuery = `
      SELECT COUNT(*) 
      FROM orders 
      WHERE shipper_id = $1 ${status ? 'AND status = $2' : ''}
    `;
    const countParams = status ? [req.user.id, status] : [req.user.id];
    const countResult = await pool.query(countQuery, countParams);

    res.json({
      status: 'success',
      data: {
        orders: result.rows.map(buildOrderResponse),
        pagination: {
          current_page: parseInt(page, 10),
          total_pages: Math.ceil(parseInt(countResult.rows[0].count, 10) / parseInt(limit, 10)),
          total_orders: parseInt(countResult.rows[0].count, 10),
          limit: parseInt(limit, 10),
        },
      },
    });
  } catch (error) {
    console.error('getMyOrders error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể tải danh sách đơn hàng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

const getOrderDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const shipperId = req.user.id;

    const orderResult = await pool.query(
      `
        SELECT 
          o.*,
          dt.status AS delivery_status,
          dt.latitude,
          dt.longitude,
          dt.address AS tracking_address,
          u.id AS customer_id,
          u.full_name AS customer_name,
          u.phone AS customer_phone,
          u.email AS customer_email
        FROM orders o
        LEFT JOIN LATERAL (
          SELECT status, latitude, longitude, address
          FROM delivery_tracking
          WHERE order_id = o.id
          ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST
          LIMIT 1
        ) dt ON true
        LEFT JOIN users u ON u.id = o.user_id
        WHERE o.id = $1 AND o.shipper_id = $2
      `,
      [id, shipperId],
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng hoặc bạn không có quyền truy cập',
      });
    }

    const historyResult = await pool.query(
      `
        SELECT status, notes, reason, created_at
        FROM order_status_history
        WHERE order_id = $1
        ORDER BY created_at ASC
      `,
      [id],
    );

    const order = buildOrderResponse(orderResult.rows[0]);

    res.json({
      status: 'success',
      data: {
        order: {
          ...order,
          tracking: orderResult.rows[0].tracking_address
            ? {
                address: orderResult.rows[0].tracking_address,
                latitude: orderResult.rows[0].latitude ? parseFloat(orderResult.rows[0].latitude) : null,
                longitude: orderResult.rows[0].longitude ? parseFloat(orderResult.rows[0].longitude) : null,
              }
            : null,
          status_history: historyResult.rows.map((row) => ({
            status: row.status,
            notes: row.notes,
            reason: row.reason,
            created_at: row.created_at,
          })),
        },
      },
    });
  } catch (error) {
    console.error('getOrderDetails error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể tải chi tiết đơn hàng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

const mapStatus = (status) => {
  if (!status) return null;
  const key = status.toUpperCase();
  if (statusMap[key]) {
    return statusMap[key];
  }
  return null;
};

const buildNotificationContent = (status, orderNumber) => {
  switch (status) {
    case 'in_transit':
      return {
        title: 'Đơn hàng đang được giao',
        body: `Đơn ${orderNumber} đã được shipper bắt đầu giao.`,
      };
    case 'delivered':
      return {
        title: 'Đơn hàng đã giao thành công',
        body: `Đơn ${orderNumber} đã được giao tới người nhận.`,
      };
    case 'failed_delivery':
      return {
        title: 'Đơn hàng giao không thành công',
        body: `Shipper không thể giao đơn ${orderNumber}. Vui lòng kiểm tra lại.`,
      };
    default:
      return {
        title: 'Cập nhật trạng thái đơn hàng',
        body: `Đơn ${orderNumber} đã được cập nhật trạng thái: ${status}`,
      };
  }
};

const updateOrderStatus = async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const shipperId = req.user.id;

    const { error, value } = statusUpdateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message,
      });
    }

    const normalizedStatus = mapStatus(value.status);
    if (!normalizedStatus) {
      return res.status(400).json({
        status: 'error',
        message: 'Trạng thái không hợp lệ',
      });
    }

    await client.query('BEGIN');

    const orderResult = await client.query(
      `
        SELECT id, order_number, user_id, shipper_id, status
        FROM orders
        WHERE id = $1
        FOR UPDATE
      `,
      [id],
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng',
      });
    }

    const order = orderResult.rows[0];

    if (order.shipper_id !== shipperId) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        status: 'error',
        message: 'Bạn không được phép cập nhật đơn hàng này',
      });
    }

    await client.query(
      `
        UPDATE orders
        SET status = $1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
      `,
      [normalizedStatus, id],
    );

    await client.query(
      `
        INSERT INTO order_status_history (order_id, status, notes, reason)
        VALUES ($1, $2, $3, $4)
      `,
      [id, normalizedStatus, value.notes || null, value.reason || null],
    );

    await client.query(
      `
        UPDATE delivery_tracking
        SET status = $1,
            shipper_id = $2,
            updated_at = CURRENT_TIMESTAMP
        WHERE order_id = $3
      `,
      [normalizedStatus, shipperId, id],
    );

    await client.query('COMMIT');

    // Notify customer
    const notification = buildNotificationContent(normalizedStatus, order.order_number);
    sendNotificationToUser(order.user_id, notification.title, notification.body, 'order_status', order.id, {
      order_number: order.order_number,
      status: normalizedStatus,
    }).catch((notifyError) => {
      console.error('sendNotificationToUser error:', notifyError);
    });

    res.json({
      status: 'success',
      message: 'Cập nhật trạng thái thành công',
      data: {
        order: {
          id: order.id,
          order_number: order.order_number,
          status: normalizedStatus,
        },
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('updateOrderStatus error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể cập nhật trạng thái đơn hàng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  } finally {
    client.release();
  }
};

// US-17: Check-in location
const checkInLocation = async (req, res) => {
  const client = await pool.connect();
  try {
    const shipperId = req.user.id;
    let { order_id, lat, long } = req.body;
    
    // Ensure order_id is an integer
    order_id = parseInt(order_id);
    if (isNaN(order_id)) {
      return res.status(400).json({
        status: 'error',
        message: 'order_id phải là số',
      });
    }

    // Validation
    if (!order_id || lat === undefined || long === undefined) {
      return res.status(400).json({
        status: 'error',
        message: 'order_id, lat, và long là bắt buộc',
      });
    }

    // Validate coordinates
    if (lat < -90 || lat > 90 || long < -180 || long > 180) {
      return res.status(400).json({
        status: 'error',
        message: 'Tọa độ không hợp lệ',
      });
    }

    await client.query('BEGIN');

    // Verify order belongs to this shipper
    const orderResult = await client.query(
      `
        SELECT id, order_number, shipper_id
        FROM orders
        WHERE id = $1
        FOR UPDATE
      `,
      [order_id],
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng',
      });
    }

    const order = orderResult.rows[0];
    if (order.shipper_id !== shipperId) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        status: 'error',
        message: 'Bạn không có quyền check-in cho đơn hàng này',
      });
    }

    // Insert location check-in
    console.log('📍 [CHECK-IN] Starting location check-in...');
    console.log('   shipperId:', shipperId);
    console.log('   order_id:', order_id, '(type:', typeof order_id, ')');
    console.log('   lat:', lat, 'long:', long);
    console.log('   Order info:', {
      id: order.id,
      order_number: order.order_number,
      shipper_id: order.shipper_id
    });
    
    const locationResult = await client.query(
      `
        INSERT INTO shipper_locations (shipper_id, order_id, latitude, longitude)
        VALUES ($1, $2, $3, $4)
        RETURNING id, order_id, shipper_id, latitude, longitude, created_at
      `,
      [shipperId, order_id, lat, long],
    );

    const insertedLocation = locationResult.rows[0];
    console.log('✅ [CHECK-IN] Location inserted successfully!');
    console.log('   Location ID:', insertedLocation.id);
    console.log('   Order ID:', insertedLocation.order_id);
    console.log('   Shipper ID:', insertedLocation.shipper_id);
    console.log('   Coordinates:', insertedLocation.latitude, ',', insertedLocation.longitude);
    console.log('   Created at:', insertedLocation.created_at);
    
    // Verify the insert by querying it back
    const verifyResult = await client.query(
      'SELECT * FROM shipper_locations WHERE id = $1',
      [insertedLocation.id]
    );
    console.log('✅ [CHECK-IN] Verification query result:', verifyResult.rows.length > 0 ? 'FOUND' : 'NOT FOUND');
    if (verifyResult.rows.length > 0) {
      console.log('   Verified location:', JSON.stringify(verifyResult.rows[0], null, 2));
    }

    await client.query('COMMIT');

    res.json({
      status: 'success',
      message: 'Check-in vị trí thành công',
      data: {
        location: {
          id: locationResult.rows[0].id,
          order_id,
          latitude: parseFloat(lat),
          longitude: parseFloat(long),
          created_at: locationResult.rows[0].created_at,
        },
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('checkInLocation error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể check-in vị trí',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  } finally {
    client.release();
  }
};

module.exports = {
  getMyOrders,
  getOrderDetails,
  updateOrderStatus,
  checkInLocation,
};


