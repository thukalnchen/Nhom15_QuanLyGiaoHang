const Joi = require('joi');
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

// Validation schemas
const createOrderSchema = Joi.object({
  restaurant_name: Joi.string().min(2).required(),
  items: Joi.array().items(
    Joi.object({
      name: Joi.string().required(),
      quantity: Joi.number().integer().min(1).required(),
      price: Joi.number().positive().required()
    })
  ).min(1).required(),
  total_amount: Joi.number().positive().required(),
  delivery_fee: Joi.number().min(0).default(0),
  delivery_address: Joi.string().min(10).required(),
  delivery_phone: Joi.string().optional(),
  notes: Joi.string().optional()
});

// Create new order
const createOrder = async (req, res) => {
  try {
    // Validate input
    const { error, value } = createOrderSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const {
      restaurant_name,
      items,
      total_amount,
      delivery_fee = 0,
      delivery_address,
      delivery_phone,
      notes
    } = value;

    // Generate unique order number
    const orderNumber = `ORD-${Date.now()}-${uuidv4().substring(0, 8).toUpperCase()}`;

    // Create order
    const result = await pool.query(
      `INSERT INTO orders (order_number, user_id, restaurant_name, items, total_amount, 
                          delivery_fee, delivery_address, delivery_phone, notes, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
       RETURNING *`,
      [
        orderNumber,
        req.user.id,
        restaurant_name,
        JSON.stringify(items),
        total_amount,
        delivery_fee,
        delivery_address,
        delivery_phone,
        notes
      ]
    );

    const order = result.rows[0];

    // Add initial status to history
    await pool.query(
      'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
      [order.id, 'pending', 'Order created']
    );

    // Initialize delivery tracking
    await pool.query(
      'INSERT INTO delivery_tracking (order_id, status) VALUES ($1, $2)',
      [order.id, 'preparing']
    );

    res.status(201).json({
      status: 'success',
      message: 'Order created successfully',
      data: {
        order: {
          id: order.id,
          order_number: order.order_number,
          restaurant_name: order.restaurant_name,
          items: JSON.parse(order.items),
          total_amount: parseFloat(order.total_amount),
          delivery_fee: parseFloat(order.delivery_fee),
          status: order.status,
          delivery_address: order.delivery_address,
          delivery_phone: order.delivery_phone,
          notes: order.notes,
          created_at: order.created_at
        }
      }
    });
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get user's orders
const getUserOrders = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT o.*, dt.status as delivery_status, dt.latitude, dt.longitude
      FROM orders o
      LEFT JOIN delivery_tracking dt ON o.id = dt.order_id
      WHERE o.user_id = $1
    `;
    const queryParams = [req.user.id];
    let paramCount = 1;

    if (status) {
      paramCount++;
      query += ` AND o.status = $${paramCount}`;
      queryParams.push(status);
    }

    query += ` ORDER BY o.created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    queryParams.push(limit, offset);

    const result = await pool.query(query, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM orders WHERE user_id = $1';
    const countParams = [req.user.id];
    
    if (status) {
      countQuery += ' AND status = $2';
      countParams.push(status);
    }

    const countResult = await pool.query(countQuery, countParams);
    const totalOrders = parseInt(countResult.rows[0].count);

    const orders = result.rows.map(order => ({
      id: order.id,
      order_number: order.order_number,
      restaurant_name: order.restaurant_name,
      items: JSON.parse(order.items),
      total_amount: parseFloat(order.total_amount),
      delivery_fee: parseFloat(order.delivery_fee),
      status: order.status,
      delivery_status: order.delivery_status,
      delivery_address: order.delivery_address,
      delivery_phone: order.delivery_phone,
      notes: order.notes,
      latitude: order.latitude ? parseFloat(order.latitude) : null,
      longitude: order.longitude ? parseFloat(order.longitude) : null,
      created_at: order.created_at,
      updated_at: order.updated_at
    }));

    res.json({
      status: 'success',
      data: {
        orders,
        pagination: {
          current_page: parseInt(page),
          total_pages: Math.ceil(totalOrders / limit),
          total_orders,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Get user orders error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get order details
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Get order details
    const orderResult = await pool.query(
      `SELECT o.*, dt.status as delivery_status, dt.latitude, dt.longitude, dt.address as tracking_address
       FROM orders o
       LEFT JOIN delivery_tracking dt ON o.id = dt.order_id
       WHERE o.id = $1 AND o.user_id = $2`,
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }

    const order = orderResult.rows[0];

    // Get order status history
    const historyResult = await pool.query(
      'SELECT * FROM order_status_history WHERE order_id = $1 ORDER BY created_at ASC',
      [orderId]
    );

    const orderDetails = {
      id: order.id,
      order_number: order.order_number,
      restaurant_name: order.restaurant_name,
      items: JSON.parse(order.items),
      total_amount: parseFloat(order.total_amount),
      delivery_fee: parseFloat(order.delivery_fee),
      status: order.status,
      delivery_status: order.delivery_status,
      delivery_address: order.delivery_address,
      delivery_phone: order.delivery_phone,
      notes: order.notes,
      latitude: order.latitude ? parseFloat(order.latitude) : null,
      longitude: order.longitude ? parseFloat(order.longitude) : null,
      tracking_address: order.tracking_address,
      created_at: order.created_at,
      updated_at: order.updated_at,
      status_history: historyResult.rows.map(history => ({
        status: history.status,
        notes: history.notes,
        created_at: history.created_at
      }))
    };

    res.json({
      status: 'success',
      data: { order: orderDetails }
    });
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Update order status (for admin/shipper)
const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        status: 'error',
        message: 'Status is required'
      });
    }

    // Update order status
    const orderResult = await pool.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, orderId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }

    // Add to status history
    await pool.query(
      'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
      [orderId, status, notes || `Status updated to ${status}`]
    );

    // Update delivery tracking status
    await pool.query(
      'UPDATE delivery_tracking SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE order_id = $2',
      [status, orderId]
    );

    const order = orderResult.rows[0];

    res.json({
      status: 'success',
      message: 'Order status updated successfully',
      data: {
        order: {
          id: order.id,
          order_number: order.order_number,
          status: order.status,
          updated_at: order.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get order statistics for admin
const getOrderStatistics = async (req, res) => {
  try {
    // Get total orders count
    const totalOrdersResult = await pool.query('SELECT COUNT(*) FROM orders');
    const totalOrders = parseInt(totalOrdersResult.rows[0].count);

    // Get delivered orders count
    const deliveredOrdersResult = await pool.query(
      'SELECT COUNT(*) FROM orders WHERE status = $1',
      ['delivered']
    );
    const deliveredOrders = parseInt(deliveredOrdersResult.rows[0].count);

    // Get processing orders count
    const processingOrdersResult = await pool.query(
      'SELECT COUNT(*) FROM orders WHERE status IN ($1, $2)',
      ['pending', 'processing']
    );
    const processingOrders = parseInt(processingOrdersResult.rows[0].count);

    // Get total revenue
    const revenueResult = await pool.query(
      'SELECT SUM(total_amount) FROM orders WHERE status = $1',
      ['delivered']
    );
    const totalRevenue = parseFloat(revenueResult.rows[0].sum || 0);

    const statistics = {
      totalOrders,
      deliveredOrders,
      processingOrders,
      totalRevenue
    };

    res.json({
      status: 'success',
      data: statistics
    });
  } catch (error) {
    console.error('Get order statistics error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  createOrder,
  getUserOrders,
  getOrderDetails,
  updateOrderStatus,
  getOrderStatistics
};
