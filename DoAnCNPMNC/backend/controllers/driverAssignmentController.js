const { pool } = require('../config/database');

// Get available drivers for assignment
const getAvailableDrivers = async (req, res) => {
  try {
    const {
      vehicleType,
      zone,
      rating,
      limit = 50,
      offset = 0
    } = req.query;

    let query = `
      SELECT 
        u.id,
        u.full_name,
        u.phone,
        u.email,
        u.vehicle_registration,
        u.role,
        COUNT(o.id) FILTER (WHERE o.status IN ('assigned', 'picked_up', 'in_delivery')) as current_orders
      FROM users u
      LEFT JOIN orders o ON o.driver_id = u.id AND o.status IN ('assigned', 'picked_up', 'in_delivery')
      WHERE u.role = 'driver'
      GROUP BY u.id, u.full_name, u.phone, u.email, u.vehicle_registration, u.role
    `;

    const params = [];
    let paramCount = 1;

    // No additional filters for now - return all drivers

    // Sort by current workload (drivers with fewer orders first)
    query += ` ORDER BY current_orders ASC, u.full_name ASC`;

    // Pagination
    query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    res.json({
      status: 'success',
      data: {
        drivers: result.rows,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    console.error('Error getting available drivers:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách tài xế',
      error: error.message
    });
  }
};

// Assign driver to order
const assignDriverToOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { driverId } = req.body;

    if (!driverId) {
      return res.status(400).json({
        status: 'error',
        message: 'ID tài xế là bắt buộc'
      });
    }

    // Get order
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

    const order = orderResult.rows[0];

    // Check if order can be assigned (must be classified)
    if (order.status !== 'classified' && order.status !== 'assigned') {
      return res.status(400).json({
        status: 'error',
        message: `Không thể phân công đơn ở trạng thái: ${order.status}`
      });
    }

    // Verify driver exists and is available
    const driverResult = await pool.query(
      'SELECT * FROM users WHERE id = $1 AND role = $2',
      [driverId, 'driver']
    );

    if (driverResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy tài xế'
      });
    }

    const driver = driverResult.rows[0];

    // Start transaction
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Update order with driver assignment
      const updateOrderQuery = `
        UPDATE orders
        SET driver_id = $1, status = 'assigned', updated_at = NOW()
        WHERE id = $2
        RETURNING *
      `;

      const updatedOrder = await client.query(updateOrderQuery, [driverId, orderId]);

      // Record assignment history
      const historyQuery = `
        INSERT INTO driver_assignments (order_id, driver_id, assigned_by, assigned_at, notes)
        VALUES ($1, $2, $3, NOW(), $4)
        RETURNING *
      `;

      await client.query(historyQuery, [
        orderId,
        driverId,
        req.user?.id || 'system',
        `Assigned to driver: ${driver.full_name}`
      ]);

      // Create notification for driver - COMMENTED OUT due to schema mismatch
      // const notificationQuery = `
      //   INSERT INTO notifications (
      //     user_id,
      //     type,
      //     title,
      //     message,
      //     data,
      //     created_at
      //   ) VALUES (
      //     $1,
      //     'order_assignment',
      //     'Có đơn hàng mới',
      //     'Bạn được phân công một đơn hàng mới',
      //     jsonb_build_object(
      //       'order_id', $2,
      //       'order_number', $3,
      //       'pickup_location', $4,
      //       'delivery_location', $5
      //     ),
      //     NOW()
      //   )
      // `;
      //
      // await client.query(notificationQuery, [
      //   driverId,
      //   orderId,
      //   order.order_number,
      //   order.pickup_location,
      //   order.delivery_location
      // ]);

      await client.query('COMMIT');

      res.json({
        status: 'success',
        message: 'Phân công đơn hàng thành công',
        data: {
          order: updatedOrder.rows[0],
          driver: {
            id: driver.id,
            name: driver.full_name,
            phone: driver.phone,
            vehicle: driver.vehicle_registration
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
    console.error('Error assigning driver:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi phân công tài xế',
      error: error.message
    });
  }
};

// Reassign order to different driver
const reassignDriver = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { newDriverId, reason } = req.body;

    if (!newDriverId) {
      return res.status(400).json({
        status: 'error',
        message: 'ID tài xế mới là bắt buộc'
      });
    }

    // Get order
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

    const order = orderResult.rows[0];

    // Can only reassign if not yet delivered
    if (['delivered', 'cancelled'].includes(order.status)) {
      return res.status(400).json({
        status: 'error',
        message: `Không thể phân công lại đơn ở trạng thái: ${order.status}`
      });
    }

    // Verify new driver exists and is available
    const driverResult = await pool.query(
      'SELECT * FROM users WHERE id = $1 AND role = $2',
      [newDriverId, 'driver']
    );

    if (driverResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy tài xế mới'
      });
    }

    const newDriver = driverResult.rows[0];

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Update order
      const updateQuery = `
        UPDATE orders
        SET driver_id = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING *
      `;

      const updatedOrder = await client.query(updateQuery, [newDriverId, orderId]);

      // Record reassignment
      const reassignQuery = `
        INSERT INTO driver_reassignments (
          order_id,
          old_driver_id,
          new_driver_id,
          reassigned_by,
          reason,
          reassigned_at
        ) VALUES ($1, $2, $3, $4, $5, NOW())
      `;

      await client.query(reassignQuery, [
        orderId,
        order.driver_id,
        newDriverId,
        req.user?.id || 'system',
        reason || null
      ]);

      // Notify old driver (if any)
      if (order.driver_id) {
        const oldDriverNotification = `
          INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            created_at
          ) VALUES (
            $1,
            'order_reassignment',
            'Đơn hàng được phân công lại',
            'Một đơn hàng của bạn được phân công cho tài xế khác',
            jsonb_build_object(
              'order_id', $2,
              'order_number', $3
            ),
            NOW()
          )
        `;

        await client.query(oldDriverNotification, [
          order.driver_id,
          orderId,
          order.order_number
        ]);
      }

      // Notify new driver
      const newDriverNotification = `
        INSERT INTO notifications (
          user_id,
          type,
          title,
          message,
          data,
          created_at
        ) VALUES (
          $1,
          'order_assignment',
          'Bạn được phân công một đơn hàng',
          'Có đơn hàng mới được giao cho bạn',
          jsonb_build_object(
            'order_id', $2,
            'order_number', $3,
            'pickup_location', $4,
            'delivery_location', $5
          ),
          NOW()
        )
      `;

      await client.query(newDriverNotification, [
        newDriverId,
        orderId,
        order.order_number,
        order.pickup_location,
        order.delivery_location
      ]);

      await client.query('COMMIT');

      res.json({
        status: 'success',
        message: 'Phân công lại đơn hàng thành công',
        data: {
          order: updatedOrder.rows[0],
          newDriver: {
            id: newDriver.id,
            name: newDriver.full_name,
            phone: newDriver.phone
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
    console.error('Error reassigning driver:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi phân công lại tài xế',
      error: error.message
    });
  }
};

// Get driver workload
const getDriverWorkload = async (req, res) => {
  try {
    const { driverId } = req.params;

    const query = `
      SELECT 
        COUNT(CASE WHEN status IN ('pending', 'confirmed', 'assigned', 'picked_up', 'in_delivery') THEN 1 END) as active_orders,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as completed_orders,
        SUM(CASE WHEN status = 'delivered' THEN delivery_fee ELSE 0 END) as total_earnings,
        AVG(CASE WHEN status = 'delivered' THEN delivery_fee ELSE NULL END) as avg_order_value
      FROM orders
      WHERE driver_id = $1
    `;

    const result = await pool.query(query, [driverId]);

    res.json({
      status: 'success',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting driver workload:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thông tin công việc tài xế',
      error: error.message
    });
  }
};

module.exports = {
  getAvailableDrivers,
  assignDriverToOrder,
  reassignDriver,
  getDriverWorkload
};
