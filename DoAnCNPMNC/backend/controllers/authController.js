const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { pool } = require('../config/database');
const { generateToken } = require('../middleware/auth');

// Validation schemas
const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  full_name: Joi.string().min(2).required(),
  phone: Joi.string().optional(),
  address: Joi.string().optional()
});

const shipperRegisterSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  full_name: Joi.string().min(2).required(),
  phone: Joi.string().pattern(/^[0-9]{9,11}$/).required(),
  address: Joi.string().optional(),
  vehicle_type: Joi.string().required(),
  vehicle_plate: Joi.string().required(),
  driver_license_number: Joi.string().required(),
  identity_card_number: Joi.string().required(),
  notes: Joi.string().allow('', null)
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
  role: Joi.string().valid('customer', 'shipper', 'intake_staff', 'admin').optional()
});

// Register new user
const register = async (req, res) => {
  try {
    // Log incoming request for debugging
    console.log('📝 Register request received:', {
      email: req.body.email,
      full_name: req.body.full_name,
      phone: req.body.phone,
      address: req.body.address,
      role: req.body.role
    });
    
    // Validate input
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      console.log('❌ Validation error:', error.details[0].message);
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const { email, password, full_name, phone, address } = value;

    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        status: 'error',
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password, full_name, phone, address, role)
       VALUES ($1, $2, $3, $4, $5, 'customer')
       RETURNING id, email, full_name, phone, address, role, status, created_at`,
      [email, hashedPassword, full_name, phone, address]
    );

    const user = result.rows[0];

    // Generate JWT token
    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role
    });

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          phone: user.phone,
          address: user.address,
          role: user.role,
          status: user.status,
          created_at: user.created_at
        },
        token
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Register new shipper (pending approval)
const registerShipper = async (req, res) => {
  const client = await pool.connect();
  try {
    const { error, value } = shipperRegisterSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const {
      email,
      password,
      full_name,
      phone,
      address,
      vehicle_type,
      vehicle_plate,
      driver_license_number,
      identity_card_number,
      notes
    } = value;

    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        status: 'error',
        message: 'Email đã được sử dụng'
      });
    }

    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    await client.query('BEGIN');

    const userResult = await client.query(
      `INSERT INTO users (email, password, full_name, phone, address, role, status)
       VALUES ($1, $2, $3, $4, $5, 'shipper', 'pending')
       RETURNING id, email, full_name, phone, address, role, status, created_at`,
      [email, hashedPassword, full_name, phone, address || null]
    );

    const shipper = userResult.rows[0];

    await client.query(
      `INSERT INTO shipper_profiles (
        user_id, vehicle_type, vehicle_plate, driver_license_number, identity_card_number, notes
      ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        shipper.id,
        vehicle_type,
        vehicle_plate,
        driver_license_number,
        identity_card_number,
        notes || null
      ]
    );

    await client.query('COMMIT');

    res.status(201).json({
      status: 'success',
      message: 'Đăng ký shipper thành công. Vui lòng chờ quản trị viên duyệt hồ sơ.',
      data: {
        user: shipper
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Register shipper error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Không thể đăng ký shipper. Vui lòng thử lại sau.'
    });
  } finally {
    client.release();
  }
};

// Login user
const login = async (req, res) => {
  try {
    // Validate input
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const { email, password, role: requestedRole } = value;

    // Find user
    const result = await pool.query(
      'SELECT id, email, password, full_name, phone, address, role, status FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    const user = result.rows[0];

    // Enforce role-based login when requested
    if (requestedRole && user.role !== requestedRole) {
      return res.status(403).json({
        status: 'error',
        message: 'Bạn không có quyền truy cập vào ứng dụng này'
      });
    }

    if (user.role === 'shipper') {
      if (user.status === 'pending') {
        return res.status(403).json({
          status: 'error',
          code: 'SHIPPER_PENDING',
          message: 'Tài khoản shipper đang chờ duyệt. Vui lòng liên hệ quản trị viên.'
        });
      }
      if (user.status === 'rejected') {
        return res.status(403).json({
          status: 'error',
          code: 'SHIPPER_REJECTED',
          message: 'Tài khoản shipper đã bị từ chối.'
        });
      }
      if (user.status === 'suspended') {
        return res.status(403).json({
          status: 'error',
          code: 'SHIPPER_SUSPENDED',
          message: 'Tài khoản shipper đang bị tạm khóa.'
        });
      }
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role
    });

    res.json({
      status: 'success',
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          phone: user.phone,
          address: user.address,
          role: user.role,
          status: user.status
        },
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, email, full_name, phone, address, role, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    res.json({
      status: 'success',
      data: { user }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Update user profile
const updateProfile = async (req, res) => {
  try {
    const { full_name, phone, address } = req.body;

    const result = await pool.query(
      `UPDATE users 
       SET full_name = $1, phone = $2, address = $3, updated_at = CURRENT_TIMESTAMP
       WHERE id = $4
       RETURNING id, email, full_name, phone, address, role, updated_at`,
      [full_name, phone, address, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    res.json({
      status: 'success',
      message: 'Profile updated successfully',
      data: { user }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  register,
  registerShipper,
  login,
  getProfile,
  updateProfile
};
