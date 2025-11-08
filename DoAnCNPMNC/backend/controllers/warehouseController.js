const { pool } = require('../config/database');

// Get all warehouse orders (pending, received, classified, ready)
exports.getWarehouseOrders = async (req, res) => {
  try {
    const query = `
      SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone as customer_phone,
        u.email as customer_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.status IN ('pending', 'received_at_warehouse', 'classified', 'ready_for_pickup')
      ORDER BY o.created_at DESC
    `;
    
    const result = await pool.query(query);
    
    res.json({
      success: true,
      orders: result.rows
    });
  } catch (error) {
    console.error('Error getting warehouse orders:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Search order by code (QR scan)
exports.searchOrderByCode = async (req, res) => {
  try {
    const { code } = req.query;
    
    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Mã đơn hàng không được để trống'
      });
    }
    
    const query = `
      SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone as customer_phone,
        u.email as customer_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.order_code = $1 OR o.order_number = $1
    `;
    const result = await pool.query(query, [code]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng'
      });
    }
    
    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error searching order by code:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #8: Receive order at warehouse
exports.receiveOrder = async (req, res) => {
  try {
    const {
      order_id,
      package_size,
      package_type,
      weight,
      description,
      images
    } = req.body;
    
    // Validation
    if (!order_id || !package_size || !package_type || !weight) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (order_id, package_size, package_type, weight)'
      });
    }
    
    // Get staff info from database (JWT only has id, email, role)
    const staffQuery = 'SELECT full_name FROM users WHERE id = $1';
    const staffResult = await pool.query(staffQuery, [req.user.id]);
    
    const warehouseId = req.user.warehouse_id || null;
    const warehouseName = req.user.warehouse_name || null;
    const intakeStaffId = req.user.id;
    const intakeStaffName = staffResult.rows[0]?.full_name || 'Unknown Staff';
    
    const query = `
      UPDATE orders 
      SET 
        status = 'received_at_warehouse',
        package_size = $1,
        package_type = $2,
        weight = $3,
        description = $4,
        images = $5,
        warehouse_id = $6,
        warehouse_name = $7,
        intake_staff_id = $8,
        intake_staff_name = $9,
        received_at = NOW(),
        updated_at = NOW()
      WHERE id = $10 AND status = 'pending'
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      package_size,
      package_type,
      weight,
      description,
      JSON.stringify(images || []),
      warehouseId,
      warehouseName,
      intakeStaffId,
      intakeStaffName,
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể nhận đơn hàng. Đơn hàng không tồn tại hoặc đã được xử lý.'
      });
    }
    
    console.log(`Order ${order_id} received by ${intakeStaffName}`);
    
    res.json({
      success: true,
      message: 'Đã nhận đơn hàng thành công',
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error receiving order:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #9: Classify order
exports.classifyOrder = async (req, res) => {
  try {
    const {
      order_id,
      zone,
      recommended_vehicle
    } = req.body;
    
    // Validation
    if (!order_id || !zone || !recommended_vehicle) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (order_id, zone, recommended_vehicle)'
      });
    }
    
    const query = `
      UPDATE orders 
      SET 
        status = 'classified',
        zone = $1,
        recommended_vehicle = $2,
        classified_at = NOW(),
        updated_at = NOW()
      WHERE id = $3 AND status = 'received_at_warehouse'
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      zone,
      recommended_vehicle,
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể phân loại. Đơn hàng chưa được nhận tại kho.'
      });
    }
    
    console.log(`Order ${order_id} classified: ${zone}, ${recommended_vehicle}`);
    
    res.json({
      success: true,
      message: 'Đã phân loại đơn hàng thành công',
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error classifying order:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #21: Assign driver
exports.assignDriver = async (req, res) => {
  try {
    const { order_id, driver_id } = req.body;
    
    // Validation
    if (!order_id || !driver_id) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (order_id, driver_id)'
      });
    }
    
    // Get driver info
    const driverQuery = 'SELECT * FROM users WHERE id = $1 AND role = $2';
    const driverResult = await pool.query(driverQuery, [driver_id, 'driver']);
    
    if (driverResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài xế'
      });
    }
    
    const driver = driverResult.rows[0];
    
    const query = `
      UPDATE orders 
      SET 
        status = 'assigned_to_driver',
        driver_id = $1,
        driver_name = $2,
        driver_phone = $3,
        vehicle_type = $4,
        assigned_at = NOW(),
        updated_at = NOW()
      WHERE id = $5 AND status IN ('classified', 'ready_for_pickup')
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      driver.id,
      driver.name,
      driver.phone,
      driver.vehicle_type || 'bike',
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể phân tài xế. Đơn hàng chưa được phân loại.'
      });
    }
    
    console.log(`Order ${order_id} assigned to driver ${driver.name}`);
    
    res.json({
      success: true,
      message: 'Đã phân tài xế thành công',
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error assigning driver:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Get available drivers
exports.getAvailableDrivers = async (req, res) => {
  try {
    const { vehicle_type } = req.query;
    
    let query = `
      SELECT id, name, phone, vehicle_type, vehicle_number
      FROM users 
      WHERE role = 'driver' AND is_active = true
    `;
    
    const params = [];
    if (vehicle_type) {
      query += ' AND vehicle_type = $1';
      params.push(vehicle_type);
    }
    
    query += ' ORDER BY name';
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      drivers: result.rows
    });
  } catch (error) {
    console.error('Error getting available drivers:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #12: Collect COD at warehouse
exports.collectCOD = async (req, res) => {
  try {
    const { order_id, amount } = req.body;
    
    // Validation
    if (!order_id || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (order_id, amount)'
      });
    }
    
    const query = `
      UPDATE orders 
      SET 
        cod_collected_at_warehouse = true,
        cod_collected_at = NOW(),
        updated_at = NOW()
      WHERE id = $1 
        AND is_cod = true 
        AND cod_payment_type = 'sender_pays'
        AND cod_collected_at_warehouse = false
      RETURNING *
    `;
    
    const result = await pool.query(query, [order_id]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể thu COD. Đơn hàng không phải COD hoặc đã thu rồi hoặc người nhận trả.'
      });
    }
    
    console.log(`COD collected for order ${order_id}: ${amount} VND`);
    
    res.json({
      success: true,
      message: 'Đã xác nhận thu COD thành công',
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error collecting COD:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #11: Generate receipt
exports.generateReceipt = async (req, res) => {
  try {
    const { order_id } = req.body;
    
    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu order_id'
      });
    }
    
    const query = 'SELECT * FROM orders WHERE id = $1';
    const result = await pool.query(query, [order_id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng'
      });
    }
    
    const order = result.rows[0];
    
    // TODO: Generate PDF receipt here using a PDF library
    // For now, return order data for client-side PDF generation
    
    console.log(`Receipt generated for order ${order_id}`);
    
    res.json({
      success: true,
      message: 'Đã tạo biên nhận',
      order: order,
      receipt: {
        order_code: order.order_code,
        generated_at: new Date(),
        generated_by: req.user.name
      }
    });
  } catch (error) {
    console.error('Error generating receipt:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Get statistics
exports.getStatistics = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    
    const query = `
      SELECT 
        COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
        COUNT(*) FILTER (WHERE status = 'received_at_warehouse') as received_count,
        COUNT(*) FILTER (WHERE status = 'classified') as classified_count,
        COUNT(*) FILTER (WHERE status = 'ready_for_pickup') as ready_count,
        COUNT(*) FILTER (WHERE DATE(received_at) = $1) as today_received
      FROM orders
    `;
    
    const result = await pool.query(query, [today]);
    
    res.json({
      success: true,
      statistics: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting statistics:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
