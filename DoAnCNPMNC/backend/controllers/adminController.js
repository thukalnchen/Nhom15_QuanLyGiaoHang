const Joi = require('joi');
const { pool } = require('../config/database');
const { sendNotificationToUser } = require('./notificationController');

// Get dashboard statistics
const getDashboardStats = async (req, res) => {
  try {
    // Get total orders count
    const totalOrdersResult = await pool.query(
      'SELECT COUNT(*) as count FROM orders'
    );
    const totalOrders = parseInt(totalOrdersResult.rows[0].count);

    // Get delivered orders count
    const deliveredOrdersResult = await pool.query(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'delivered'"
    );
    const deliveredOrders = parseInt(deliveredOrdersResult.rows[0].count);

    // Get processing orders count (pending + processing + shipped)
    const processingOrdersResult = await pool.query(
      "SELECT COUNT(*) as count FROM orders WHERE status IN ('pending', 'processing', 'shipped')"
    );
    const processingOrders = parseInt(processingOrdersResult.rows[0].count);

    // Get total revenue from delivered orders
    const revenueResult = await pool.query(
      "SELECT COALESCE(SUM(total_amount + delivery_fee), 0) as revenue FROM orders WHERE status = 'delivered'"
    );
    const totalRevenue = parseFloat(revenueResult.rows[0].revenue);

    // Get orders by status
    const statusResult = await pool.query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM orders
      GROUP BY status
    `);

    const statusCounts = {
      pending: 0,
      processing: 0,
      shipped: 0,
      delivered: 0,
      cancelled: 0
    };

    statusResult.rows.forEach(row => {
      statusCounts[row.status] = parseInt(row.count);
    });

    // Get recent orders (last 7 days) grouped by date
    const ordersChartResult = await pool.query(`
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as count
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '7 days'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `);

    const ordersChart = ordersChartResult.rows.map(row => ({
      date: row.date,
      count: parseInt(row.count)
    }));

    res.json({
      status: 'success',
      data: {
        totalOrders,
        deliveredOrders,
        processingOrders,
        totalRevenue,
        statusCounts,
        ordersChart
      }
    });
  } catch (error) {
    console.error('Error getting dashboard stats:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thống kê dashboard',
      error: error.message
    });
  }
};

// Get all orders with filters
const getAllOrders = async (req, res) => {
  try {
    const { 
      status, 
      search, 
      startDate, 
      endDate, 
      limit = 50, 
      offset = 0 
    } = req.query;

    let query = `
      SELECT 
        o.id,
        o.order_number,
        o.restaurant_name,
        o.items,
        o.total_amount,
        o.delivery_fee,
        o.delivery_address,
        o.delivery_phone,
        o.status,
        o.created_at,
        o.updated_at,
        o.shipper_id,
        o.is_cod_collected,
        o.is_cod_received,
        o.cod_collected_at,
        o.cod_received_at,
        o.payment_method,
        u.full_name as customer_name,
        u.email as customer_email,
        u.phone as customer_phone,
        s.full_name as shipper_name,
        s.phone as shipper_phone
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      LEFT JOIN users s ON o.shipper_id = s.id
    `;

    const conditions = [];
    const params = [];
    let paramCount = 1;

    // Filter by status
    if (status) {
      conditions.push(`o.status = $${paramCount}`);
      params.push(status);
      paramCount++;
    }

    // Filter by date range
    if (startDate) {
      conditions.push(`DATE(o.created_at) >= $${paramCount}`);
      params.push(startDate);
      paramCount++;
    }
    if (endDate) {
      conditions.push(`DATE(o.created_at) <= $${paramCount}`);
      params.push(endDate);
      paramCount++;
    }

    // Search by order number, customer name, phone, or address
    if (search) {
      conditions.push(`(
        o.order_number ILIKE $${paramCount} OR
        u.full_name ILIKE $${paramCount} OR
        u.phone ILIKE $${paramCount} OR
        o.delivery_address ILIKE $${paramCount} OR
        o.delivery_phone ILIKE $${paramCount}
      )`);
      params.push(`%${search}%`);
      paramCount++;
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY o.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    const parsedLimit = parseInt(limit, 10);
    const parsedOffset = parseInt(offset, 10);
    params.push(parsedLimit, parsedOffset);

    const result = await pool.query(query, params);

    // Get total count with same filters
    let countQuery = `
      SELECT COUNT(*) as count 
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
    `;
    const countConditions = [];
    const countParams = [];
    let countParamCount = 1;

    if (status) {
      countConditions.push(`o.status = $${countParamCount}`);
      countParams.push(status);
      countParamCount++;
    }
    if (startDate) {
      countConditions.push(`DATE(o.created_at) >= $${countParamCount}`);
      countParams.push(startDate);
      countParamCount++;
    }
    if (endDate) {
      countConditions.push(`DATE(o.created_at) <= $${countParamCount}`);
      countParams.push(endDate);
      countParamCount++;
    }
    if (search) {
      countConditions.push(`(
        o.order_number ILIKE $${countParamCount} OR
        u.full_name ILIKE $${countParamCount} OR
        u.phone ILIKE $${countParamCount} OR
        o.delivery_address ILIKE $${countParamCount} OR
        o.delivery_phone ILIKE $${countParamCount}
      )`);
      countParams.push(`%${search}%`);
      countParamCount++;
    }

    if (countConditions.length > 0) {
      countQuery += ' WHERE ' + countConditions.join(' AND ');
    }

    const countResult = await pool.query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    // Format orders with customer and shipper info
    const formattedOrders = result.rows.map(row => ({
      id: row.id,
      order_number: row.order_number,
      restaurant_name: row.restaurant_name,
      items: typeof row.items === 'string' ? JSON.parse(row.items) : row.items,
      total_amount: parseFloat(row.total_amount || 0),
      delivery_fee: parseFloat(row.delivery_fee || 0),
      delivery_address: row.delivery_address,
      delivery_phone: row.delivery_phone,
      status: row.status,
      created_at: row.created_at,
      updated_at: row.updated_at,
      payment_method: row.payment_method || 'cod',
      is_cod: (row.payment_method === 'cod' || row.payment_method === 'COD'), // Derive from payment_method
      is_cod_collected: row.is_cod_collected || false,
      is_cod_received: row.is_cod_received || false,
      cod_collected_at: row.cod_collected_at,
      cod_received_at: row.cod_received_at,
      cod_amount: parseFloat(row.total_amount || 0), // COD amount equals total amount for COD orders
      customer: row.customer_name ? {
        full_name: row.customer_name,
        email: row.customer_email,
        phone: row.customer_phone
      } : null,
      shipper: row.shipper_name ? {
        full_name: row.shipper_name,
        phone: row.shipper_phone
      } : null
    }));

    res.json({
      status: 'success',
      data: {
        orders: formattedOrders,
        pagination: {
          total: totalCount,
          limit: parsedLimit,
          offset: parsedOffset,
          pages: Math.ceil(totalCount / parsedLimit)
        }
      }
    });
  } catch (error) {
    console.error('Error getting orders:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách đơn hàng',
      error: error.message
    });
  }
};

// Get order by ID
const getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;

    const result = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.email as customer_email,
        u.phone as customer_phone,
        u.address as customer_address
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.id = $1`,
      [orderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    // Get tracking history if exists
    const trackingResult = await pool.query(
      `SELECT * FROM delivery_tracking 
       WHERE order_id = $1 
       ORDER BY created_at DESC`,
      [orderId]
    );

    res.json({
      status: 'success',
      data: {
        order: result.rows[0],
        tracking: trackingResult.rows
      }
    });
  } catch (error) {
    console.error('Error getting order:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thông tin đơn hàng',
      error: error.message
    });
  }
};

// Update order status
const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        status: 'error',
        message: 'Trạng thái không hợp lệ'
      });
    }

    const result = await pool.query(
      `UPDATE orders 
       SET status = $1, updated_at = NOW() 
       WHERE id = $2 
       RETURNING *`,
      [status, orderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    // Emit socket event for real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('order-status-updated', {
        orderId,
        status,
        order: result.rows[0]
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật trạng thái thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating order status:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật trạng thái đơn hàng',
      error: error.message
    });
  }
};

// Update order information (Admin can edit order details)
const updateOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const {
      restaurant_name,
      delivery_address,
      delivery_phone,
      delivery_lat,
      delivery_lng,
      pickup_address,
      pickup_lat,
      pickup_lng,
      recipient_name,
      recipient_phone,
      total_amount,
      delivery_fee,
      notes
    } = req.body;

    // Build dynamic update query
    const updates = [];
    const params = [];
    let paramCount = 1;

    if (restaurant_name !== undefined) {
      updates.push(`restaurant_name = $${paramCount}`);
      params.push(restaurant_name);
      paramCount++;
    }
    if (delivery_address !== undefined) {
      updates.push(`delivery_address = $${paramCount}`);
      params.push(delivery_address);
      paramCount++;
    }
    if (delivery_phone !== undefined) {
      updates.push(`delivery_phone = $${paramCount}`);
      params.push(delivery_phone);
      paramCount++;
    }
    if (delivery_lat !== undefined) {
      updates.push(`delivery_lat = $${paramCount}`);
      params.push(delivery_lat);
      paramCount++;
    }
    if (delivery_lng !== undefined) {
      updates.push(`delivery_lng = $${paramCount}`);
      params.push(delivery_lng);
      paramCount++;
    }
    if (pickup_address !== undefined) {
      updates.push(`pickup_address = $${paramCount}`);
      params.push(pickup_address);
      paramCount++;
    }
    if (pickup_lat !== undefined) {
      updates.push(`pickup_lat = $${paramCount}`);
      params.push(pickup_lat);
      paramCount++;
    }
    if (pickup_lng !== undefined) {
      updates.push(`pickup_lng = $${paramCount}`);
      params.push(pickup_lng);
      paramCount++;
    }
    if (recipient_name !== undefined) {
      updates.push(`recipient_name = $${paramCount}`);
      params.push(recipient_name);
      paramCount++;
    }
    if (recipient_phone !== undefined) {
      updates.push(`recipient_phone = $${paramCount}`);
      params.push(recipient_phone);
      paramCount++;
    }
    if (total_amount !== undefined) {
      updates.push(`total_amount = $${paramCount}`);
      params.push(parseFloat(total_amount));
      paramCount++;
    }
    if (delivery_fee !== undefined) {
      updates.push(`delivery_fee = $${paramCount}`);
      params.push(parseFloat(delivery_fee));
      paramCount++;
    }
    if (notes !== undefined) {
      updates.push(`notes = $${paramCount}`);
      params.push(notes);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Không có thông tin nào để cập nhật'
      });
    }

    updates.push(`updated_at = NOW()`);
    params.push(orderId);

    const query = `
      UPDATE orders 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    // Emit socket event for real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('order-updated', {
        orderId,
        order: result.rows[0]
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật thông tin đơn hàng thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating order:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật thông tin đơn hàng',
      error: error.message
    });
  }
};

// Get active deliveries
const getActiveDeliveries = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        o.id,
        o.order_number,
        o.restaurant_name,
        o.delivery_address,
        o.status,
        o.created_at,
        u.full_name as customer_name,
        u.phone as customer_phone,
        dt.latitude,
        dt.longitude,
        dt.updated_at as last_location_update
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      LEFT JOIN (
        SELECT DISTINCT ON (order_id) *
        FROM delivery_tracking
        ORDER BY order_id, created_at DESC
      ) dt ON o.id = dt.order_id
      WHERE o.status IN ('processing', 'shipped')
      ORDER BY o.created_at DESC`
    );

    res.json({
      status: 'success',
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting active deliveries:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách giao hàng',
      error: error.message
    });
  }
};

// Get all users
const getAllUsers = async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const result = await pool.query(
      `SELECT 
        id,
        COALESCE(full_name, '') AS name,
        email,
        phone,
        address,
        created_at,
        updated_at,
        role,
        status
      FROM users
      ORDER BY created_at DESC
      LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    // Get total count
    const countResult = await pool.query('SELECT COUNT(*) as count FROM users');
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      status: 'success',
      data: {
        users: result.rows,
        pagination: {
          total: totalCount,
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    console.error('Error getting users:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách người dùng',
      error: error.message
    });
  }
};

const getShippers = async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    const params = ['shipper'];
    let whereClause = 'WHERE u.role = $1';

    if (status) {
      params.push(status);
      whereClause += ` AND u.status = $${params.length}`;
    }

    params.push(limit, offset);

    const result = await pool.query(
      `SELECT 
        u.id,
        u.full_name,
        u.email,
        u.phone,
        u.address,
        u.status,
        u.created_at,
        sp.vehicle_type,
        sp.vehicle_plate,
        sp.driver_license_number,
        sp.identity_card_number,
        sp.notes,
        sp.approved_at,
        sp.created_at AS profile_created_at,
        sp.updated_at AS profile_updated_at
      FROM users u
      LEFT JOIN shipper_profiles sp ON sp.user_id = u.id
      ${whereClause}
      ORDER BY u.created_at DESC
      LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({
      status: 'success',
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting shippers:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách shipper',
      error: error.message
    });
  }
};

const getShipperById = async (req, res) => {
  try {
    const { shipperId } = req.params;

    const result = await pool.query(
      `SELECT 
        u.id,
        u.full_name,
        u.email,
        u.phone,
        u.address,
        u.status,
        u.created_at,
        sp.vehicle_type,
        sp.vehicle_plate,
        sp.driver_license_number,
        sp.identity_card_number,
        sp.notes,
        sp.approved_at,
        sp.created_at AS profile_created_at,
        sp.updated_at AS profile_updated_at
      FROM users u
      LEFT JOIN shipper_profiles sp ON sp.user_id = u.id
      WHERE u.id = $1 AND u.role = 'shipper'`,
      [shipperId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy shipper'
      });
    }

    res.json({
      status: 'success',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting shipper details:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thông tin shipper',
      error: error.message
    });
  }
};

// Get available shippers (approved and not overloaded)
const getAvailableShippers = async (req, res) => {
  try {
    const { limit = 50 } = req.query;

    // Get shippers who are approved and have less than 3 active orders
    const result = await pool.query(
      `SELECT 
        u.id,
        u.full_name,
        u.email,
        u.phone,
        u.status,
        sp.vehicle_type,
        sp.vehicle_plate,
        COUNT(o.id) FILTER (WHERE o.status IN ('processing', 'shipped', 'assigned_to_driver')) as active_orders_count
      FROM users u
      LEFT JOIN shipper_profiles sp ON sp.user_id = u.id
      LEFT JOIN orders o ON o.shipper_id = u.id AND o.status IN ('processing', 'shipped', 'assigned_to_driver')
      WHERE u.role = 'shipper' 
        AND u.status = 'approved'
      GROUP BY u.id, u.full_name, u.email, u.phone, u.status, sp.vehicle_type, sp.vehicle_plate
      HAVING COUNT(o.id) FILTER (WHERE o.status IN ('processing', 'shipped', 'assigned_to_driver')) < 3
      ORDER BY active_orders_count ASC, u.full_name ASC
      LIMIT $1`,
      [parseInt(limit, 10)]
    );

    res.json({
      status: 'success',
      data: result.rows.map(row => ({
        id: row.id,
        full_name: row.full_name,
        email: row.email,
        phone: row.phone,
        vehicle_type: row.vehicle_type,
        vehicle_plate: row.vehicle_plate,
        active_orders_count: parseInt(row.active_orders_count || 0)
      }))
    });
  } catch (error) {
    console.error('Error getting available shippers:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách shipper có sẵn',
      error: error.message
    });
  }
};

// Assign orders to shipper
const assignOrders = async (req, res) => {
  const client = await pool.connect();
  try {
    const { order_ids, shipper_id } = req.body;

    // Validation
    if (!Array.isArray(order_ids) || order_ids.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Danh sách đơn hàng không hợp lệ'
      });
    }

    if (!shipper_id) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng chọn shipper'
      });
    }

    // Verify shipper exists and is approved
    const shipperResult = await client.query(
      `SELECT id, full_name, email, status FROM users 
       WHERE id = $1 AND role = 'shipper' AND status = 'approved'`,
      [shipper_id]
    );

    if (shipperResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Shipper không tồn tại hoặc chưa được duyệt'
      });
    }

    const shipper = shipperResult.rows[0];

    await client.query('BEGIN');

    // Verify all orders exist and can be assigned
    const ordersResult = await client.query(
      `SELECT id, order_number, status, shipper_id 
       FROM orders 
       WHERE id = ANY($1::int[])`,
      [order_ids]
    );

    if (ordersResult.rows.length !== order_ids.length) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: 'Một số đơn hàng không tồn tại'
      });
    }

    // Check if orders are already assigned or in invalid status
    const invalidOrders = ordersResult.rows.filter(
      order => order.shipper_id !== null || 
               !['pending', 'processing'].includes(order.status)
    );

    if (invalidOrders.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: `Một số đơn hàng đã được gán hoặc không thể gán: ${invalidOrders.map(o => o.order_number).join(', ')}`
      });
    }

    // Assign orders
    const updateResult = await client.query(
      `UPDATE orders 
       SET shipper_id = $1, 
           status = CASE WHEN status = 'pending' THEN 'processing' ELSE status END,
           updated_at = NOW()
       WHERE id = ANY($2::int[])
       RETURNING id, order_number, status`,
      [shipper_id, order_ids]
    );

    // Create status history entries
    for (const order of updateResult.rows) {
      await client.query(
        `INSERT INTO order_status_history (order_id, status, notes, created_at)
         VALUES ($1, $2, $3, NOW())`,
        [order.id, order.status, `Đơn hàng được gán cho shipper ${shipper.full_name} bởi admin`]
      );
    }

    await client.query('COMMIT');

    // Send notifications to shipper
    const { sendNotificationToUser } = require('./notificationController');
    const orderNumbers = updateResult.rows.map(o => o.order_number).join(', ');
    
    sendNotificationToUser(
      shipper_id,
      'Bạn có đơn hàng mới được gán',
      `Bạn đã được gán ${updateResult.rows.length} đơn hàng: ${orderNumbers}`,
      'order_assigned',
      null,
      { order_ids, order_count: updateResult.rows.length }
    ).catch(err => console.error('Notification error:', err));

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.emit('orders-assigned', {
        shipper_id,
        order_ids: updateResult.rows.map(o => o.id),
        orders: updateResult.rows
      });
    }

    res.json({
      status: 'success',
      message: `Đã gán ${updateResult.rows.length} đơn hàng cho shipper ${shipper.full_name}`,
      data: {
        shipper: {
          id: shipper.id,
          full_name: shipper.full_name
        },
        orders: updateResult.rows
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error assigning orders:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi gán đơn hàng',
      error: error.message
    });
  } finally {
    client.release();
  }
};

const updateShipperStatus = async (req, res) => {
  const client = await pool.connect();
  try {
    const { shipperId } = req.params;
    const schema = Joi.object({
      status: Joi.string().valid('pending', 'approved', 'rejected', 'suspended').required(),
      notes: Joi.string().allow('', null)
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      `UPDATE users
       SET status = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND role = 'shipper'
       RETURNING id, full_name, email, status`,
      [value.status, shipperId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy shipper'
      });
    }

    const profileResult = await client.query(
      `UPDATE shipper_profiles
       SET notes = COALESCE($1, notes),
           approved_at = CASE WHEN $2 = 'approved' THEN CURRENT_TIMESTAMP ELSE approved_at END,
           updated_at = CURRENT_TIMESTAMP
       WHERE user_id = $3
       RETURNING id`,
      [value.notes || null, value.status, shipperId]
    );

    if (profileResult.rowCount === 0) {
      await client.query(
        `INSERT INTO shipper_profiles (
          user_id, notes, approved_at
        ) VALUES ($1, $2, CASE WHEN $3 = 'approved' THEN CURRENT_TIMESTAMP ELSE NULL END)
        ON CONFLICT (user_id) DO UPDATE SET
          notes = EXCLUDED.notes,
          approved_at = CASE WHEN $3 = 'approved' THEN CURRENT_TIMESTAMP ELSE shipper_profiles.approved_at END,
          updated_at = CURRENT_TIMESTAMP`,
        [shipperId, value.notes || null, value.status]
      );
    }

    await client.query('COMMIT');

    const shipper = userResult.rows[0];

    let notification = null;
    switch (value.status) {
      case 'approved':
        notification = {
          title: 'Tài khoản shipper đã được duyệt',
          body: 'Chúc mừng! Bạn đã có thể đăng nhập và sử dụng ứng dụng shipper.'
        };
        break;
      case 'rejected':
        notification = {
          title: 'Tài khoản shipper bị từ chối',
          body: 'Hồ sơ của bạn chưa được chấp thuận. Vui lòng liên hệ quản trị viên để biết thêm chi tiết.'
        };
        break;
      case 'suspended':
        notification = {
          title: 'Tài khoản shipper bị tạm khóa',
          body: 'Tài khoản shipper của bạn đang bị tạm khóa. Vui lòng liên hệ quản trị viên.'
        };
        break;
      default:
        break;
    }

    if (notification) {
      sendNotificationToUser(
        shipper.id,
        notification.title,
        notification.body,
        'shipper_status',
        shipper.id,
        { status: value.status }
      ).catch(err => console.error('Notification error:', err));
    }

    res.json({
      status: 'success',
      message: 'Cập nhật trạng thái shipper thành công',
      data: shipper
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating shipper status:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật trạng thái shipper',
      error: error.message
    });
  } finally {
    client.release();
  }
};

// Get analytics data
const getAnalytics = async (req, res) => {
  try {
    const { period = 7 } = req.query; // days

    // Revenue by day
    const revenueResult = await pool.query(
      `SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total_amount + delivery_fee), 0) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '${period} days'
        AND status = 'delivered'
      GROUP BY DATE(created_at)
      ORDER BY date ASC`
    );

    // Top restaurants by order count
    const restaurantsResult = await pool.query(
      `SELECT 
        restaurant_name,
        COUNT(*) as order_count,
        COALESCE(SUM(total_amount), 0) as total_revenue
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '${period} days'
      GROUP BY restaurant_name
      ORDER BY order_count DESC
      LIMIT 10`
    );

    // Orders by status in period
    const statusDistributionResult = await pool.query(
      `SELECT 
        status,
        COUNT(*) as count
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '${period} days'
      GROUP BY status`
    );

    // Average delivery time (for delivered orders)
    const avgDeliveryTimeResult = await pool.query(
      `SELECT 
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60) as avg_minutes
      FROM orders
      WHERE status = 'delivered'
        AND created_at >= NOW() - INTERVAL '${period} days'`
    );

    res.json({
      status: 'success',
      data: {
        revenueByDay: revenueResult.rows,
        topRestaurants: restaurantsResult.rows,
        statusDistribution: statusDistributionResult.rows,
        avgDeliveryTime: parseFloat(avgDeliveryTimeResult.rows[0]?.avg_minutes || 0).toFixed(2)
      }
    });
  } catch (error) {
    console.error('Error getting analytics:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải dữ liệu thống kê',
      error: error.message
    });
  }
};

// US-19: Confirm COD collection (Shipper đã thu COD từ khách)
const confirmCodCollection = async (req, res) => {
  const client = await pool.connect();
  try {
    const { order_id } = req.body;
    const adminId = req.user.id;

    if (!order_id) {
      return res.status(400).json({
        status: 'error',
        message: 'order_id là bắt buộc'
      });
    }

    await client.query('BEGIN');

    // Get order details
    const orderResult = await client.query(
      `SELECT id, order_number, total_amount, delivery_fee, is_cod_collected, status
       FROM orders
       WHERE id = $1
       FOR UPDATE`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    const order = orderResult.rows[0];

    if (order.is_cod_collected) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: 'COD đã được xác nhận thu trước đó'
      });
    }

    // Update order
    await client.query(
      `UPDATE orders
       SET is_cod_collected = TRUE,
           cod_collected_at = CURRENT_TIMESTAMP,
           cod_collected_by = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [adminId, order_id]
    );

    await client.query('COMMIT');

    res.json({
      status: 'success',
      message: 'Xác nhận thu COD thành công',
      data: {
        order: {
          id: order.id,
          order_number: order.order_number,
          is_cod_collected: true,
          cod_collected_at: new Date()
        }
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('confirmCodCollection error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể xác nhận thu COD',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    client.release();
  }
};

// US-12: Confirm COD received (Shipper đã nộp COD về công ty)
const confirmCodReceived = async (req, res) => {
  const client = await pool.connect();
  try {
    const { order_id } = req.body;
    const adminId = req.user.id;

    if (!order_id) {
      return res.status(400).json({
        status: 'error',
        message: 'order_id là bắt buộc'
      });
    }

    await client.query('BEGIN');

    // Get order details
    const orderResult = await client.query(
      `SELECT id, order_number, total_amount, delivery_fee, is_cod_collected, is_cod_received, status
       FROM orders
       WHERE id = $1
       FOR UPDATE`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    const order = orderResult.rows[0];

    if (!order.is_cod_collected) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: 'COD chưa được xác nhận thu. Vui lòng xác nhận thu trước.'
      });
    }

    if (order.is_cod_received) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: 'COD đã được xác nhận nhận trước đó'
      });
    }

    // Update order
    await client.query(
      `UPDATE orders
       SET is_cod_received = TRUE,
           cod_received_at = CURRENT_TIMESTAMP,
           cod_received_by = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [adminId, order_id]
    );

    await client.query('COMMIT');

    res.json({
      status: 'success',
      message: 'Xác nhận nhận COD thành công',
      data: {
        order: {
          id: order.id,
          order_number: order.order_number,
          is_cod_received: true,
          cod_received_at: new Date()
        }
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('confirmCodReceived error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể xác nhận nhận COD',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    client.release();
  }
};

module.exports = {
  getDashboardStats,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  updateOrder,
  getActiveDeliveries,
  getAllUsers,
  getAnalytics,
  getShippers,
  getShipperById,
  updateShipperStatus,
  getAvailableShippers,
  assignOrders,
  confirmCodCollection,
  confirmCodReceived
};
