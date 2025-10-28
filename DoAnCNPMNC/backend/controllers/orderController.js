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
          items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items,
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
    console.log('getUserOrders - User ID:', req.user?.id);
    console.log('getUserOrders - Query params:', req.query);
    
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

    console.log('getUserOrders - Executing query:', query);
    console.log('getUserOrders - Query params:', queryParams);

    const result = await pool.query(query, queryParams);

    console.log('getUserOrders - Found orders:', result.rows.length);

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
      items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items,
      total_amount: parseFloat(order.total_amount),
      delivery_fee: parseFloat(order.delivery_fee),
      status: order.status,
      delivery_status: order.delivery_status,
      pickup_address: order.pickup_address,
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
          total_orders: totalOrders,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Get user orders error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error',
      error: error.message
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
      items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items,
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

// Cancel order with validation
const cancelOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { reason, cancel_type } = req.body;

    // Validate cancellation reason
    if (!reason || reason.trim().length < 5) {
      return res.status(400).json({
        status: 'error',
        message: 'Cancellation reason is required (minimum 5 characters)'
      });
    }

    // Validate cancel_type
    const validCancelTypes = ['customer_request', 'out_of_stock', 'wrong_address', 'duplicate_order', 'change_mind', 'other'];
    if (!cancel_type || !validCancelTypes.includes(cancel_type)) {
      return res.status(400).json({
        status: 'error',
        message: `Cancel type must be one of: ${validCancelTypes.join(', ')}`
      });
    }

    // Get order details
    const orderResult = await pool.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found or you do not have permission to cancel this order'
      });
    }

    const order = orderResult.rows[0];

    // Validation rules for cancellation
    const cannotCancelStatuses = ['delivered', 'cancelled'];
    if (cannotCancelStatuses.includes(order.status)) {
      return res.status(400).json({
        status: 'error',
        message: `Cannot cancel order with status: ${order.status}`,
        current_status: order.status
      });
    }

    // Check if order is too old to cancel (e.g., more than 30 minutes for pending/processing)
    const orderAge = Date.now() - new Date(order.created_at).getTime();
    const thirtyMinutes = 30 * 60 * 1000;
    
    if (order.status === 'shipped' || order.status === 'in_transit') {
      return res.status(400).json({
        status: 'error',
        message: 'Cannot cancel order that is already being delivered. Please contact support.',
        current_status: order.status
      });
    }

    // Additional validation: if order is processing for more than 30 mins, require admin approval
    if (order.status === 'processing' && orderAge > thirtyMinutes) {
      return res.status(400).json({
        status: 'error',
        message: 'This order has been processing for too long. Please contact support to cancel.',
        current_status: order.status,
        requires_support: true
      });
    }

    // Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Update order status to cancelled
      const updateResult = await client.query(
        `UPDATE orders 
         SET status = 'cancelled', 
             updated_at = CURRENT_TIMESTAMP,
             cancellation_reason = $1,
             cancellation_type = $2,
             cancelled_at = CURRENT_TIMESTAMP,
             cancelled_by = $3
         WHERE id = $4
         RETURNING *`,
        [reason, cancel_type, req.user.id, orderId]
      );

      const cancelledOrder = updateResult.rows[0];

      // Add to status history
      await client.query(
        'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
        [orderId, 'cancelled', `Order cancelled by customer. Reason: ${reason} (${cancel_type})`]
      );

      // Update delivery tracking status
      await client.query(
        'UPDATE delivery_tracking SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE order_id = $2',
        ['cancelled', orderId]
      );

      // If payment was made, initiate refund (placeholder for payment integration)
      // TODO: Integrate with payment gateway for actual refund
      if (cancelledOrder.payment_status === 'paid') {
        await client.query(
          `UPDATE orders 
           SET refund_status = 'pending', 
               refund_initiated_at = CURRENT_TIMESTAMP 
           WHERE id = $1`,
          [orderId]
        );
      }

      await client.query('COMMIT');

      res.json({
        status: 'success',
        message: 'Order cancelled successfully',
        data: {
          order: {
            id: cancelledOrder.id,
            order_number: cancelledOrder.order_number,
            status: cancelledOrder.status,
            cancellation_reason: cancelledOrder.cancellation_reason,
            cancellation_type: cancelledOrder.cancellation_type,
            cancelled_at: cancelledOrder.cancelled_at,
            refund_status: cancelledOrder.refund_status || null,
            updated_at: cancelledOrder.updated_at
          }
        }
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get cancellation statistics (for admin)
const getCancellationStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    let query = 'SELECT cancellation_type, COUNT(*) as count FROM orders WHERE status = $1';
    const params = ['cancelled'];

    if (startDate && endDate) {
      query += ' AND cancelled_at BETWEEN $2 AND $3';
      params.push(startDate, endDate);
    }

    query += ' GROUP BY cancellation_type ORDER BY count DESC';

    const result = await pool.query(query, params);

    // Get total cancelled orders
    const totalResult = await pool.query(
      'SELECT COUNT(*) FROM orders WHERE status = $1',
      ['cancelled']
    );

    res.json({
      status: 'success',
      data: {
        total_cancelled: parseInt(totalResult.rows[0].count),
        by_type: result.rows.map(row => ({
          type: row.cancellation_type,
          count: parseInt(row.count)
        }))
      }
    });

  } catch (error) {
    console.error('Get cancellation stats error:', error);
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
  cancelOrder,
  getCancellationStats,
  getOrderStatistics
};
