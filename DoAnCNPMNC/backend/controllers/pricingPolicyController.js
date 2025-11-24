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
        description,
        is_active,
        created_at,
        updated_at
      FROM surcharges
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
      description
    } = req.body;

    if (!name || !type || value === undefined) {
      return res.status(400).json({
        status: 'error',
        message: 'Tên, loại và giá trị phụ phí là bắt buộc'
      });
    }

    const query = `
      INSERT INTO surcharges (
        name,
        type,
        value,
        description,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, true, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      name,
      type,
      parseFloat(value),
      description || null
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
    const { id } = req.params;
    const {
      name,
      type,
      value,
      description,
      isActive
    } = req.body;

    const query = `
      UPDATE surcharges
      SET 
        name = COALESCE($1, name),
        type = COALESCE($2, type),
        value = COALESCE($3::DECIMAL, value),
        description = COALESCE($4, description),
        is_active = COALESCE($5, is_active),
        updated_at = NOW()
      WHERE id = $6
      RETURNING *
    `;

    const result = await pool.query(query, [
      name || null,
      type || null,
      value !== undefined ? parseFloat(value) : null,
      description || null,
      isActive !== undefined ? isActive : null,
      id
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
        value,
        min_order_value,
        max_discount,
        usage_limit,
        usage_count,
        valid_from,
        valid_to,
        is_active,
        created_at,
        updated_at
      FROM discounts
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
      value,
      maxDiscount,
      minOrderValue,
      usageLimit,
      validFrom,
      validTo
    } = req.body;

    if (!code || !name || !type || value === undefined) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã, tên, loại và giá trị giảm giá là bắt buộc'
      });
    }

    const query = `
      INSERT INTO discounts (
        code,
        name,
        type,
        value,
        min_order_value,
        max_discount,
        usage_limit,
        usage_count,
        valid_from,
        valid_to,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, 0, $8, $9, true, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      code.toUpperCase(),
      name,
      type,
      parseFloat(value),
      parseFloat(minOrderValue) || 0,
      parseFloat(maxDiscount) || null,
      parseInt(usageLimit) || null,
      validFrom || null,
      validTo || null
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
        value,
        max_discount,
        min_order_value,
        usage_limit,
        usage_count,
        valid_from,
        valid_to,
        is_active
      FROM discounts
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
    if (discount.usage_limit && discount.usage_count >= discount.usage_limit) {
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

    if (discount.valid_to && new Date(discount.valid_to) < now) {
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
      discountAmount = discount.value;
    } else if (discount.type === 'percentage') {
      discountAmount = (orderValue * discount.value) / 100;
      if (discount.max_discount && discount.max_discount > 0) {
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

// Delete surcharge policy
const deleteSurchargePolicy = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      DELETE FROM surcharges
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy chính sách phụ phí'
      });
    }

    res.json({
      status: 'success',
      message: 'Xóa chính sách phụ phí thành công'
    });
  } catch (error) {
    console.error('Error deleting surcharge policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xóa chính sách phụ phí',
      error: error.message
    });
  }
};

// Update discount policy
const updateDiscountPolicy = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      code,
      name,
      type,
      value,
      minOrderValue,
      maxDiscount,
      usageLimit,
      validFrom,
      validTo,
      isActive
    } = req.body;

    const query = `
      UPDATE discounts
      SET 
        code = COALESCE($1, code),
        name = COALESCE($2, name),
        type = COALESCE($3, type),
        value = COALESCE($4::DECIMAL, value),
        min_order_value = COALESCE($5::DECIMAL, min_order_value),
        max_discount = COALESCE($6::DECIMAL, max_discount),
        usage_limit = COALESCE($7::INTEGER, usage_limit),
        valid_from = COALESCE($8::TIMESTAMP, valid_from),
        valid_to = COALESCE($9::TIMESTAMP, valid_to),
        is_active = COALESCE($10, is_active),
        updated_at = NOW()
      WHERE id = $11
      RETURNING *
    `;

    const result = await pool.query(query, [
      code ? code.toUpperCase() : null,
      name || null,
      type || null,
      value !== undefined ? parseFloat(value) : null,
      minOrderValue !== undefined ? parseFloat(minOrderValue) : null,
      maxDiscount !== undefined ? parseFloat(maxDiscount) : null,
      usageLimit !== undefined ? parseInt(usageLimit) : null,
      validFrom || null,
      validTo || null,
      isActive !== undefined ? isActive : null,
      id
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy chính sách giảm giá'
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật chính sách giảm giá thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating discount policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật chính sách giảm giá',
      error: error.message
    });
  }
};

// Delete discount policy
const deleteDiscountPolicy = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      DELETE FROM discounts
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy chính sách giảm giá'
      });
    }

    res.json({
      status: 'success',
      message: 'Xóa chính sách giảm giá thành công'
    });
  } catch (error) {
    console.error('Error deleting discount policy:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xóa chính sách giảm giá',
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
  deleteSurchargePolicy,
  getDiscountPolicies,
  createDiscountPolicy,
  updateDiscountPolicy,
  deleteDiscountPolicy,
  validateDiscountCode
};
