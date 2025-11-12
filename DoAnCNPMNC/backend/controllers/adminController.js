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
    const { status, limit = 50, offset = 0 } = req.query;

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
        u.full_name as customer_name,
        u.email as customer_email,
        u.phone as customer_phone
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
    `;

    const params = [];
    if (status) {
      query += ' WHERE o.status = $1';
      params.push(status);
    }

    query += ' ORDER BY o.created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    const parsedLimit = parseInt(limit, 10);
    const parsedOffset = parseInt(offset, 10);
    params.push(parsedLimit, parsedOffset);

    const result = await pool.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as count FROM orders';
    if (status) {
      countQuery += ' WHERE status = $1';
    }
    const countResult = await pool.query(countQuery, status ? [status] : []);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      status: 'success',
      data: {
        orders: result.rows,
        pagination: {
          total: totalCount,
          limit: parseInt(limit),
          offset: parseInt(offset)
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

module.exports = {
  getDashboardStats,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  getActiveDeliveries,
  getAllUsers,
  getAnalytics,
  getShippers,
  getShipperById,
  updateShipperStatus
};
