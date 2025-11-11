const { pool } = require('../config/database');

// Get pricing table
const getPricingTable = async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        vehicle_type,
        base_price,
        price_per_km,
        minimum_price,
        surge_multiplier,
        description,
        is_active,
        created_at,
        updated_at
      FROM pricing_tables
      ORDER BY vehicle_type ASC
    `;

    const result = await pool.query(query);

    res.json({
      status: 'success',
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting pricing table:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải bảng giá',
      error: error.message
    });
  }
};

// Create or update pricing
const updatePricing = async (req, res) => {
  try {
    const {
      vehicleType,
      basePrice,
      pricePerKm,
      minimumPrice,
      surgeMultiplier,
      description
    } = req.body;

    if (!vehicleType || !basePrice || !pricePerKm) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng điền đầy đủ các trường bắt buộc'
      });
    }

    const query = `
      INSERT INTO pricing_tables (
        vehicle_type,
        base_price,
        price_per_km,
        minimum_price,
        surge_multiplier,
        description,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, true, NOW(), NOW())
      ON CONFLICT (vehicle_type)
      DO UPDATE SET
        base_price = $2,
        price_per_km = $3,
        minimum_price = $4,
        surge_multiplier = $5,
        description = $6,
        updated_at = NOW()
      RETURNING *
    `;

    const result = await pool.query(query, [
      vehicleType,
      parseFloat(basePrice),
      parseFloat(pricePerKm),
      parseFloat(minimumPrice) || 0,
      parseFloat(surgeMultiplier) || 1.0,
      description || null
    ]);

    res.json({
      status: 'success',
      message: 'Cập nhật giá thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating pricing:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật giá',
      error: error.message
    });
  }
};

// Get surcharge policies
const getSurchargePolicies = async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        name,
        type,
        value,
        percentage,
        conditions,
        is_active,
        created_at,
        updated_at
      FROM surcharge_policies
      WHERE is_active = true
      ORDER BY created_at DESC
    `;

    const result = await pool.query(query);

    res.json({
      status: 'success',
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting surcharge policies:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải chính sách phụ phí',
      error: error.message
    });
  }
};

// Create surcharge policy
const createSurchargePolicy = async (req, res) => {
  try {
    const {
      name,
      type,
      value,
      percentage,
      conditions,
      description
    } = req.body;

    if (!name || !type) {
      return res.status(400).json({
        status: 'error',
        message: 'Tên và loại phụ phí là bắt buộc'
      });
    }

    const query = `
      INSERT INTO surcharge_policies (
        name,
        type,
        value,
        percentage,
        conditions,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, true, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      name,
      type,
      parseFloat(value) || 0,
      parseFloat(percentage) || 0,
      conditions ? JSON.stringify(conditions) : null
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Tạo chính sách phụ phí thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating surcharge policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tạo chính sách phụ phí',
      error: error.message
    });
  }
};

// Update surcharge policy
const updateSurchargePolicy = async (req, res) => {
  try {
    const { policyId } = req.params;
    const {
      name,
      value,
      percentage,
      conditions,
      isActive
    } = req.body;

    const query = `
      UPDATE surcharge_policies
      SET 
        name = COALESCE($1, name),
        value = COALESCE($2::DECIMAL, value),
        percentage = COALESCE($3::DECIMAL, percentage),
        conditions = COALESCE($4, conditions),
        is_active = COALESCE($5, is_active),
        updated_at = NOW()
      WHERE id = $6
      RETURNING *
    `;

    const result = await pool.query(query, [
      name || null,
      value || null,
      percentage || null,
      conditions ? JSON.stringify(conditions) : null,
      isActive !== undefined ? isActive : null,
      policyId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy chính sách phụ phí'
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật chính sách phụ phí thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating surcharge policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật chính sách phụ phí',
      error: error.message
    });
  }
};

// Get discount policies
const getDiscountPolicies = async (req, res) => {
  try {
    const { isActive } = req.query;

    let query = `
      SELECT 
        id,
        code,
        name,
        type,
        discount_value,
        discount_percentage,
        max_discount,
        min_order_value,
        usage_limit,
        used_count,
        valid_from,
        valid_until,
        is_active,
        created_at,
        updated_at
      FROM discount_policies
      WHERE 1=1
    `;

    const params = [];

    if (isActive !== undefined) {
      query += ` AND is_active = $1`;
      params.push(isActive === 'true');
    }

    query += ` ORDER BY created_at DESC`;

    const result = await pool.query(query, params);

    res.json({
      status: 'success',
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting discount policies:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải chính sách giảm giá',
      error: error.message
    });
  }
};

// Create discount policy
const createDiscountPolicy = async (req, res) => {
  try {
    const {
      code,
      name,
      type,
      discountValue,
      discountPercentage,
      maxDiscount,
      minOrderValue,
      usageLimit,
      validFrom,
      validUntil
    } = req.body;

    if (!code || !name || !type) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã, tên và loại giảm giá là bắt buộc'
      });
    }

    const query = `
      INSERT INTO discount_policies (
        code,
        name,
        type,
        discount_value,
        discount_percentage,
        max_discount,
        min_order_value,
        usage_limit,
        used_count,
        valid_from,
        valid_until,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 0, $9, $10, true, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      code.toUpperCase(),
      name,
      type,
      parseFloat(discountValue) || 0,
      parseFloat(discountPercentage) || 0,
      parseFloat(maxDiscount) || 0,
      parseFloat(minOrderValue) || 0,
      parseInt(usageLimit) || null,
      validFrom || null,
      validUntil || null
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Tạo chính sách giảm giá thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating discount policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tạo chính sách giảm giá',
      error: error.message
    });
  }
};

// Validate and apply discount code
const validateDiscountCode = async (req, res) => {
  try {
    const { code, orderValue } = req.body;

    if (!code) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã giảm giá là bắt buộc'
      });
    }

    const query = `
      SELECT 
        id,
        code,
        name,
        type,
        discount_value,
        discount_percentage,
        max_discount,
        min_order_value,
        usage_limit,
        used_count,
        valid_from,
        valid_until,
        is_active
      FROM discount_policies
      WHERE UPPER(code) = UPPER($1) AND is_active = true
    `;

    const result = await pool.query(query, [code]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Mã giảm giá không tồn tại hoặc không hoạt động'
      });
    }

    const discount = result.rows[0];

    // Validate usage limit
    if (discount.usage_limit && discount.used_count >= discount.usage_limit) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã giảm giá đã hết lượt sử dụng'
      });
    }

    // Validate date
    const now = new Date();
    if (discount.valid_from && new Date(discount.valid_from) > now) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã giảm giá chưa được kích hoạt'
      });
    }

    if (discount.valid_until && new Date(discount.valid_until) < now) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã giảm giá đã hết hạn'
      });
    }

    // Validate minimum order value
    if (orderValue && discount.min_order_value && orderValue < discount.min_order_value) {
      return res.status(400).json({
        status: 'error',
        message: `Đơn hàng phải có giá trị tối thiểu ${discount.min_order_value} VNĐ`
      });
    }

    // Calculate discount amount
    let discountAmount = 0;
    if (discount.type === 'fixed') {
      discountAmount = discount.discount_value;
    } else if (discount.type === 'percentage') {
      discountAmount = (orderValue * discount.discount_percentage) / 100;
      if (discount.max_discount > 0) {
        discountAmount = Math.min(discountAmount, discount.max_discount);
      }
    }

    res.json({
      status: 'success',
      data: {
        code: discount.code,
        name: discount.name,
        discountAmount: discountAmount,
        type: discount.type
      }
    });
  } catch (error) {
    console.error('Error validating discount code:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xác nhận mã giảm giá',
      error: error.message
    });
  }
};

module.exports = {
  getPricingTable,
  updatePricing,
  getSurchargePolicies,
  createSurchargePolicy,
  updateSurchargePolicy,
  getDiscountPolicies,
  createDiscountPolicy,
  validateDiscountCode
};
