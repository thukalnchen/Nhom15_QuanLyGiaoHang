const { pool } = require('../config/database');
const { sendNotificationToUser } = require('./notificationController');
const multer = require('multer');
const path = require('path');

// Configure multer for file upload
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/complaints/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'complaint-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only images (JPEG, PNG) and PDF files are allowed!'));
    }
  }
}).array('evidence_images', 4); // Max 4 images

// Create complaint
const createComplaint = async (req, res) => {
  try {
    const {
      order_id,
      complaint_type,
      subject,
      description,
      priority
    } = req.body;

    const userId = req.user.id;

    // Validation
    if (!order_id || !complaint_type || !subject || !description) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc'
      });
    }

    // Verify order belongs to user
    const orderCheck = await pool.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [order_id, userId]
    );

    if (orderCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng hoặc bạn không có quyền khiếu nại đơn này'
      });
    }

    const query = `
      INSERT INTO complaints (
        user_id, order_id, complaint_type, subject, description, 
        priority, status, evidence_images
      )
      VALUES ($1, $2, $3, $4, $5, $6, 'open', $7)
      RETURNING *
    `;

    const evidenceImages = req.files ? req.files.map(f => f.path) : [];

    const result = await pool.query(query, [
      userId,
      order_id,
      complaint_type,
      subject,
      description,
      priority || 'medium',
      JSON.stringify(evidenceImages)
    ]);

    const complaint = result.rows[0];

    // Send notification to user
    await sendNotificationToUser(
      userId,
      'Khiếu nại đã được tiếp nhận',
      `Khiếu nại #${complaint.id} của bạn đã được tiếp nhận và đang được xử lý.`,
      'complaint',
      complaint.id
    );

    res.status(201).json({
      success: true,
      message: 'Khiếu nại đã được tạo thành công',
      data: complaint
    });
  } catch (error) {
    console.error('Create complaint error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể tạo khiếu nại',
      error: error.message
    });
  }
};

// Get user complaints
const getUserComplaints = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;

    let query = `
      SELECT 
        c.*,
        o.id as order_id_full,
        CONCAT('ORDER-', o.id) as order_code,
        o.status as order_status,
        o.restaurant_name as pickup_address,
        o.delivery_address,
        o.total_amount as total_cost,
        (SELECT COUNT(*) FROM complaint_responses WHERE complaint_id = c.id) as response_count
      FROM complaints c
      LEFT JOIN orders o ON c.order_id = o.id
      WHERE c.user_id = $1
    `;

    const params = [userId];
    let paramIndex = 2;

    if (status) {
      query += ` AND c.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    query += ` ORDER BY c.created_at DESC`;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), (parseInt(page) - 1) * parseInt(limit));

    const result = await pool.query(query, params);

    // Get total count
    const countQuery = `
      SELECT COUNT(*) FROM complaints WHERE user_id = $1 ${status ? 'AND status = $2' : ''}
    `;
    const countParams = status ? [userId, status] : [userId];
    const countResult = await pool.query(countQuery, countParams);

    res.status(200).json({
      success: true,
      data: {
        complaints: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get complaints error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể lấy danh sách khiếu nại',
      error: error.message
    });
  }
};

// Get complaint detail
const getComplaintDetail = async (req, res) => {
  try {
    const { complaintId } = req.params;
    const userId = req.user.id;

    const query = `
      SELECT 
        c.*,
        CONCAT('ORDER-', o.id) as order_code,
        o.status as order_status,
        o.restaurant_name as pickup_address,
        o.delivery_address,
        o.total_amount as total_cost,
        u.full_name as user_name,
        u.email as user_email,
        u.phone_number as user_phone
      FROM complaints c
      LEFT JOIN orders o ON c.order_id = o.id
      LEFT JOIN users u ON c.user_id = u.id
      WHERE c.id = $1 AND c.user_id = $2
    `;

    const result = await pool.query(query, [complaintId, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khiếu nại'
      });
    }

    // Get responses
    const responsesQuery = `
      SELECT * FROM complaint_responses 
      WHERE complaint_id = $1 
      ORDER BY created_at ASC
    `;
    const responsesResult = await pool.query(responsesQuery, [complaintId]);

    res.status(200).json({
      success: true,
      data: {
        complaint: result.rows[0],
        responses: responsesResult.rows
      }
    });
  } catch (error) {
    console.error('Get complaint detail error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể lấy chi tiết khiếu nại',
      error: error.message
    });
  }
};

// Add response to complaint
const addResponse = async (req, res) => {
  try {
    const { complaintId } = req.params;
    const { message } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung phản hồi không được để trống'
      });
    }

    // Check if complaint exists
    const complaintQuery = await pool.query(
      'SELECT * FROM complaints WHERE id = $1',
      [complaintId]
    );

    if (complaintQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khiếu nại'
      });
    }

    const complaint = complaintQuery.rows[0];

    // Insert response
    const query = `
      INSERT INTO complaint_responses (
        complaint_id, user_id, user_role, message
      )
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;

    const result = await pool.query(query, [
      complaintId,
      userId,
      userRole,
      message
    ]);

    // Update complaint last_updated
    await pool.query(
      'UPDATE complaints SET updated_at = CURRENT_TIMESTAMP WHERE id = $1',
      [complaintId]
    );

    // Send notification
    const notificationUserId = userRole === 'customer' ? complaint.user_id : complaint.user_id;
    if (userRole !== 'customer') {
      await sendNotificationToUser(
        complaint.user_id,
        'Có phản hồi mới cho khiếu nại',
        `Khiếu nại #${complaintId} của bạn đã có phản hồi mới.`,
        'complaint',
        complaintId
      );
    }

    res.status(201).json({
      success: true,
      message: 'Đã thêm phản hồi thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Add response error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể thêm phản hồi',
      error: error.message
    });
  }
};

// Update complaint status
const updateComplaintStatus = async (req, res) => {
  try {
    const { complaintId } = req.params;
    const { status, resolution_note } = req.body;
    const userId = req.user.id;

    // Only admin/staff can update status
    if (req.user.role !== 'admin' && req.user.role !== 'intake_staff') {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền cập nhật trạng thái khiếu nại'
      });
    }

    const validStatuses = ['open', 'in_progress', 'resolved', 'closed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Trạng thái không hợp lệ'
      });
    }

    const query = `
      UPDATE complaints 
      SET 
        status = $1,
        resolution_note = $2,
        resolved_at = ${status === 'resolved' || status === 'closed' ? 'CURRENT_TIMESTAMP' : 'resolved_at'},
        resolved_by = ${status === 'resolved' || status === 'closed' ? '$3' : 'resolved_by'},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
    `;

    const result = await pool.query(query, [
      status,
      resolution_note || null,
      userId,
      complaintId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khiếu nại'
      });
    }

    const complaint = result.rows[0];

    // Send notification to user
    await sendNotificationToUser(
      complaint.user_id,
      'Cập nhật trạng thái khiếu nại',
      `Khiếu nại #${complaintId} của bạn đã được cập nhật: ${getStatusText(status)}`,
      'complaint',
      complaintId
    );

    res.status(200).json({
      success: true,
      message: 'Đã cập nhật trạng thái khiếu nại',
      data: complaint
    });
  } catch (error) {
    console.error('Update complaint status error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể cập nhật trạng thái',
      error: error.message
    });
  }
};

// Get all complaints (admin)
const getAllComplaints = async (req, res) => {
  try {
    // Only admin can access
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền truy cập'
      });
    }

    const { status, priority, page = 1, limit = 20 } = req.query;

    let query = `
      SELECT 
        c.*,
        CONCAT('ORDER-', o.id) as order_code,
        u.full_name as user_name,
        u.email as user_email,
        (SELECT COUNT(*) FROM complaint_responses WHERE complaint_id = c.id) as response_count
      FROM complaints c
      LEFT JOIN orders o ON c.order_id = o.id
      LEFT JOIN users u ON c.user_id = u.id
      WHERE 1=1
    `;

    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND c.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    if (priority) {
      query += ` AND c.priority = $${paramIndex}`;
      params.push(priority);
      paramIndex++;
    }

    query += ` ORDER BY c.created_at DESC`;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), (parseInt(page) - 1) * parseInt(limit));

    const result = await pool.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM complaints WHERE 1=1';
    const countParams = [];
    let countParamIndex = 1;

    if (status) {
      countQuery += ` AND status = $${countParamIndex}`;
      countParams.push(status);
      countParamIndex++;
    }

    if (priority) {
      countQuery += ` AND priority = $${countParamIndex}`;
      countParams.push(priority);
    }

    const countResult = await pool.query(countQuery, countParams);

    res.status(200).json({
      success: true,
      data: {
        complaints: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get all complaints error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể lấy danh sách khiếu nại',
      error: error.message
    });
  }
};

// Helper function
const getStatusText = (status) => {
  const statusMap = {
    'open': 'Đã mở',
    'in_progress': 'Đang xử lý',
    'resolved': 'Đã giải quyết',
    'closed': 'Đã đóng'
  };
  return statusMap[status] || status;
};

module.exports = {
  upload,
  createComplaint,
  getUserComplaints,
  getComplaintDetail,
  addResponse,
  updateComplaintStatus,
  getAllComplaints
};
