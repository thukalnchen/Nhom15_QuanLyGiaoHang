const { pool } = require('../config/database');

// Get all orders with advanced filtering and search
const getAllOrders = async (req, res) => {
  try {
    const {
      status,
      orderNumber,
      senderPhone,
      receiverPhone,
      dateFrom,
      dateTo,
      paymentStatus,
      vehicleType,
      minAmount,
      maxAmount,
      limit = 50,
      offset = 0,
      sortBy = 'created_at',
      sortOrder = 'DESC'
    } = req.query;

    let baseQuery = `
      SELECT 
        o.id,
        o.order_number,
        o.sender_name,
        o.sender_phone,
        o.receiver_name,
        o.receiver_phone,
        o.pickup_location,
        o.delivery_location,
        o.vehicle_type,
        o.status,
        o.total_amount,
        o.delivery_fee,
        o.payment_method,
        o.payment_status,
        o.created_at,
        o.updated_at,
        o.notes,
        u.id as driver_id,
        u.full_name as driver_name,
        u.phone as driver_phone,
        u.vehicle_registration as driver_vehicle
      FROM orders o
      LEFT JOIN users u ON o.driver_id = u.id AND u.role = 'driver'
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    // Status filter
    if (status) {
      baseQuery += ` AND o.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    // Order number search
    if (orderNumber) {
      baseQuery += ` AND o.order_number ILIKE $${paramCount}`;
      params.push(`%${orderNumber}%`);
      paramCount++;
    }

    // Sender phone search
    if (senderPhone) {
      baseQuery += ` AND o.sender_phone LIKE $${paramCount}`;
      params.push(`%${senderPhone}%`);
      paramCount++;
    }

    // Receiver phone search
    if (receiverPhone) {
      baseQuery += ` AND o.receiver_phone LIKE $${paramCount}`;
      params.push(`%${receiverPhone}%`);
      paramCount++;
    }

    // Date range filter
    if (dateFrom) {
      baseQuery += ` AND DATE(o.created_at) >= $${paramCount}`;
      params.push(dateFrom);
      paramCount++;
    }

    if (dateTo) {
      baseQuery += ` AND DATE(o.created_at) <= $${paramCount}`;
      params.push(dateTo);
      paramCount++;
    }

    // Payment status filter
    if (paymentStatus) {
      baseQuery += ` AND o.payment_status = $${paramCount}`;
      params.push(paymentStatus);
      paramCount++;
    }

    // Vehicle type filter
    if (vehicleType) {
      baseQuery += ` AND o.vehicle_type = $${paramCount}`;
      params.push(vehicleType);
      paramCount++;
    }

    // Amount range filter
    if (minAmount) {
      baseQuery += ` AND o.total_amount >= $${paramCount}`;
      params.push(parseFloat(minAmount));
      paramCount++;
    }

    if (maxAmount) {
      baseQuery += ` AND o.total_amount <= $${paramCount}`;
      params.push(parseFloat(maxAmount));
      paramCount++;
    }

    // Sort
    const allowedSortFields = [
      'created_at',
      'updated_at',
      'order_number',
      'total_amount',
      'payment_status',
      'status'
    ];
    const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'created_at';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    baseQuery += ` ORDER BY o.${sortField} ${sortDirection}`;

    // Get total count
    const countQuery = baseQuery.replace(
      /SELECT[\s\S]*?FROM/,
      'SELECT COUNT(*) as total FROM'
    ).split('ORDER BY')[0];

    const countResult = await pool.query(countQuery, params);
    const totalCount = parseInt(countResult.rows[0].total);

    // Apply pagination
    baseQuery += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(baseQuery, params);

    res.json({
      status: 'success',
      data: {
        orders: result.rows,
        pagination: {
          total: totalCount,
          limit: parseInt(limit),
          offset: parseInt(offset),
          pages: Math.ceil(totalCount / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error getting orders:', error);
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

    const query = `
      SELECT 
        o.id,
        o.order_number,
        o.sender_name,
        o.sender_phone,
        o.receiver_name,
        o.receiver_phone,
        o.pickup_location,
        o.delivery_location,
        o.vehicle_type,
        o.status,
        o.total_amount,
        o.delivery_fee,
        o.payment_method,
        o.payment_status,
        o.created_at,
        o.updated_at,
        o.notes,
        o.estimated_delivery_time,
        o.actual_delivery_time,
        d.id as driver_id,
        d.full_name as driver_name,
        d.phone as driver_phone,
        d.vehicle_registration as driver_vehicle
      FROM orders o
      LEFT JOIN drivers d ON o.driver_id = d.id
      WHERE o.id = $1
    `;

    const result = await pool.query(query, [orderId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    res.json({
      status: 'success',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting order:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thông tin đơn hàng',
      error: error.message
    });
  }
};

// Update order status with validation
const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        status: 'error',
        message: 'Trạng thái đơn hàng là bắt buộc'
      });
    }

    const validStatuses = [
      'pending',
      'confirmed',
      'received_at_warehouse',
      'classified',
      'assigned',
      'picked_up',
      'in_delivery',
      'delivered',
      'cancelled'
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        status: 'error',
        message: `Trạng thái không hợp lệ: ${status}`
      });
    }

    // Get current order
    const orderResult = await pool.query(
      'SELECT * FROM orders WHERE id = $1',
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    const currentOrder = orderResult.rows[0];
    const currentStatus = currentOrder.status;

    // Validation 1: Cannot update if order is delivered
    if (currentStatus === 'delivered') {
      return res.status(400).json({
        status: 'error',
        message: 'Không thể cập nhật đơn hàng đã giao thành công'
      });
    }

    // Validation 2: Cannot update if order is cancelled
    if (currentStatus === 'cancelled') {
      return res.status(400).json({
        status: 'error',
        message: 'Không thể cập nhật đơn hàng đã hủy'
      });
    }

    // Validation 3: Cannot cancel if order is in certain statuses
    const cannotCancelStatuses = [
      'received_at_warehouse',
      'classified', 
      'assigned',
      'picked_up',
      'in_delivery',
      'delivered'
    ];
    
    if (status === 'cancelled' && cannotCancelStatuses.includes(currentStatus)) {
      return res.status(400).json({
        status: 'error',
        message: `Không thể hủy đơn hàng ở trạng thái "${getStatusLabel(currentStatus)}". Đơn hàng đã quá xa trong quy trình giao hàng.`
      });
    }

    // Admin can freely change status (no flow restrictions)
    // Just prevent: delivered→X, cancelled→X, and cancel when too late

    // Update order
    const updateQuery = `
      UPDATE orders
      SET status = $1, updated_at = NOW(), notes = COALESCE($2, notes)
      WHERE id = $3
      RETURNING *
    `;

    const updateResult = await pool.query(updateQuery, [status, notes || null, orderId]);

    // Record status history (using current schema: order_id, status, notes, created_at)
    await pool.query(
      `INSERT INTO order_status_history (order_id, status, notes)
       VALUES ($1, $2, $3)`,
      [orderId, status, notes || `Changed from ${currentStatus} to ${status} by admin ${req.user?.id || 'system'}`]
    );

    res.json({
      status: 'success',
      message: 'Cập nhật trạng thái đơn hàng thành công',
      data: updateResult.rows[0]
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật trạng thái đơn hàng',
      error: error.message
    });
  }
};

// Helper function to get status label in Vietnamese
function getStatusLabel(status) {
  const labels = {
    'pending': 'Chờ xử lý',
    'confirmed': 'Đã xác nhận',
    'received_at_warehouse': 'Đã nhận tại kho',
    'classified': 'Đã phân loại',
    'assigned': 'Đã phân tài xế',
    'picked_up': 'Đã lấy hàng',
    'in_delivery': 'Đang giao',
    'delivered': 'Đã giao',
    'cancelled': 'Đã hủy'
  };
  return labels[status] || status;
}

// Update order details
const updateOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;
    const {
      senderName,
      senderPhone,
      receiverName,
      receiverPhone,
      pickupLocation,
      deliveryLocation,
      notes,
      estimatedDeliveryTime
    } = req.body;

    const updateQuery = `
      UPDATE orders
      SET 
        sender_name = COALESCE($1, sender_name),
        sender_phone = COALESCE($2, sender_phone),
        receiver_name = COALESCE($3, receiver_name),
        receiver_phone = COALESCE($4, receiver_phone),
        pickup_location = COALESCE($5, pickup_location),
        delivery_location = COALESCE($6, delivery_location),
        notes = COALESCE($7, notes),
        estimated_delivery_time = COALESCE($8, estimated_delivery_time),
        updated_at = NOW()
      WHERE id = $9
      RETURNING *
    `;

    const result = await pool.query(updateQuery, [
      senderName || null,
      senderPhone || null,
      receiverName || null,
      receiverPhone || null,
      pickupLocation || null,
      deliveryLocation || null,
      notes || null,
      estimatedDeliveryTime || null,
      orderId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy đơn hàng'
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật thông tin đơn hàng thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating order details:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật thông tin đơn hàng',
      error: error.message
    });
  }
};

// Get order statistics
const getOrderStatistics = async (req, res) => {
  try {
    const { dateFrom, dateTo } = req.query;

    let dateFilter = '';
    const params = [];

    if (dateFrom) {
      dateFilter += ` AND DATE(created_at) >= $1`;
      params.push(dateFrom);
    }

    if (dateTo) {
      const paramIndex = params.length + 1;
      dateFilter += ` AND DATE(created_at) <= $${paramIndex}`;
      params.push(dateTo);
    }

    // Orders by status
    const statusQuery = `
      SELECT 
        status,
        COUNT(*) as count
      FROM orders
      WHERE 1=1 ${dateFilter}
      GROUP BY status
    `;

    // Orders by vehicle type
    const vehicleQuery = `
      SELECT 
        vehicle_type,
        COUNT(*) as count
      FROM orders
      WHERE 1=1 ${dateFilter}
      GROUP BY vehicle_type
    `;

    // Orders by payment method
    const paymentQuery = `
      SELECT 
        payment_method,
        COUNT(*) as count,
        SUM(total_amount) as revenue
      FROM orders
      WHERE 1=1 ${dateFilter}
      GROUP BY payment_method
    `;

    // Daily orders trend
    const trendQuery = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_orders,
        SUM(total_amount) as daily_revenue
      FROM orders
      WHERE 1=1 ${dateFilter}
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `;

    const [statusResult, vehicleResult, paymentResult, trendResult] = await Promise.all([
      pool.query(statusQuery, params),
      pool.query(vehicleQuery, params),
      pool.query(paymentQuery, params),
      pool.query(trendQuery, params)
    ]);

    res.json({
      status: 'success',
      data: {
        byStatus: statusResult.rows,
        byVehicleType: vehicleResult.rows,
        byPaymentMethod: paymentResult.rows,
        dailyTrend: trendResult.rows
      }
    });
  } catch (error) {
    console.error('Error getting order statistics:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thống kê đơn hàng',
      error: error.message
    });
  }
};

module.exports = {
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  updateOrderDetails,
  getOrderStatistics
};
