const { pool } = require('../config/database');
const Joi = require('joi');

// Validation schema for pricing rules
const pricingRuleSchema = Joi.object({
  rule_name: Joi.string().required().max(255),
  rule_type: Joi.string().valid('base_price', 'service_fee', 'weight_factor', 'distance_factor').required(),
  vehicle_type: Joi.string().valid('motorcycle', 'van_500', 'van_750', 'van_1000').required(),
  base_price_per_km: Joi.number().min(0).required(),
  minimum_fare: Joi.number().min(0).required(),
  train_station_fee: Joi.number().min(0).default(0),
  extra_weight_per_kg: Joi.number().min(0).default(0),
  helper_small_fee: Joi.number().min(0).default(0),
  helper_large_fee: Joi.number().min(0).default(0),
  round_trip_percentage: Joi.number().min(0).max(1).default(0),
  weight_factor: Joi.number().min(0).default(1.0),
  distance_factor: Joi.number().min(0).default(1.0),
  description: Joi.string().allow(null, '').optional(),
  is_active: Joi.boolean().default(true),
  effective_from: Joi.date().optional(),
  effective_until: Joi.date().allow(null).optional()
});

// Get all pricing rules
exports.getAllPricingRules = async (req, res) => {
  try {
    const { vehicle_type, is_active } = req.query;
    
    let query = `
      SELECT 
        id,
        rule_name,
        rule_type,
        vehicle_type,
        base_price_per_km,
        minimum_fare,
        train_station_fee,
        extra_weight_per_kg,
        helper_small_fee,
        helper_large_fee,
        round_trip_percentage,
        weight_factor,
        distance_factor,
        description,
        is_active,
        effective_from,
        effective_until,
        created_at,
        updated_at
      FROM pricing_rules
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;
    
    if (vehicle_type) {
      query += ` AND vehicle_type = $${paramIndex}`;
      params.push(vehicle_type);
      paramIndex++;
    }
    
    if (is_active !== undefined) {
      query += ` AND is_active = $${paramIndex}`;
      params.push(is_active === 'true');
      paramIndex++;
    }
    
    query += ` ORDER BY vehicle_type, created_at DESC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting pricing rules:', error);
    console.error('Error stack:', error.stack);
    
    // Check if table doesn't exist
    if (error.code === '42P01') {
      return res.status(500).json({
        success: false,
        message: 'Bảng pricing_rules chưa được tạo. Vui lòng chạy migration script migrate_sprint7.sql',
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải bảng giá',
      error: error.message
    });
  }
};

// Get active pricing rule for a vehicle type
exports.getActivePricingRule = async (req, res) => {
  try {
    const { vehicleType } = req.params;
    
    const query = `
      SELECT 
        id,
        rule_name,
        rule_type,
        vehicle_type,
        base_price_per_km,
        minimum_fare,
        train_station_fee,
        extra_weight_per_kg,
        helper_small_fee,
        helper_large_fee,
        round_trip_percentage,
        weight_factor,
        distance_factor,
        description,
        is_active,
        effective_from,
        effective_until
      FROM pricing_rules
      WHERE vehicle_type = $1 
        AND is_active = true
        AND (effective_from IS NULL OR effective_from <= NOW())
        AND (effective_until IS NULL OR effective_until >= NOW())
      ORDER BY created_at DESC
      LIMIT 1
    `;
    
    const result = await pool.query(query, [vehicleType]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Không tìm thấy bảng giá cho loại xe ${vehicleType}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting active pricing rule:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải bảng giá',
      error: error.message
    });
  }
};

// Get pricing rule by ID
exports.getPricingRuleById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT 
        id,
        rule_name,
        rule_type,
        vehicle_type,
        base_price_per_km,
        minimum_fare,
        train_station_fee,
        extra_weight_per_kg,
        helper_small_fee,
        helper_large_fee,
        round_trip_percentage,
        weight_factor,
        distance_factor,
        description,
        is_active,
        effective_from,
        effective_until,
        created_by,
        created_at,
        updated_at
      FROM pricing_rules
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bảng giá'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting pricing rule by ID:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải bảng giá',
      error: error.message
    });
  }
};

// Create pricing rule
exports.createPricingRule = async (req, res) => {
  try {
    // Validate input
    const { error, value } = pricingRuleSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        errors: error.details.map(d => d.message)
      });
    }
    
    const {
      rule_name,
      rule_type,
      vehicle_type,
      base_price_per_km,
      minimum_fare,
      train_station_fee = 0,
      extra_weight_per_kg = 0,
      helper_small_fee = 0,
      helper_large_fee = 0,
      round_trip_percentage = 0,
      weight_factor = 1.0,
      distance_factor = 1.0,
      description,
      is_active = true,
      effective_from,
      effective_until
    } = value;
    
    // Get user ID from token
    const userId = req.user?.id;
    
    const query = `
      INSERT INTO pricing_rules (
        rule_name,
        rule_type,
        vehicle_type,
        base_price_per_km,
        minimum_fare,
        train_station_fee,
        extra_weight_per_kg,
        helper_small_fee,
        helper_large_fee,
        round_trip_percentage,
        weight_factor,
        distance_factor,
        description,
        is_active,
        effective_from,
        effective_until,
        created_by,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, NOW(), NOW())
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      rule_name,
      rule_type,
      vehicle_type,
      base_price_per_km,
      minimum_fare,
      train_station_fee,
      extra_weight_per_kg,
      helper_small_fee,
      helper_large_fee,
      round_trip_percentage,
      weight_factor,
      distance_factor,
      description || null,
      is_active,
      effective_from || null,
      effective_until || null,
      userId || null
    ]);
    
    res.status(201).json({
      success: true,
      message: 'Tạo bảng giá thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating pricing rule:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo bảng giá',
      error: error.message
    });
  }
};

// Update pricing rule
exports.updatePricingRule = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate input (all fields optional for update)
    const updateSchema = pricingRuleSchema.fork(Object.keys(pricingRuleSchema.describe().keys), (schema) => schema.optional());
    const { error, value } = updateSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        errors: error.details.map(d => d.message)
      });
    }
    
    // Build dynamic update query
    const updateFields = [];
    const params = [];
    let paramIndex = 1;
    
    if (value.rule_name !== undefined) {
      updateFields.push(`rule_name = $${paramIndex++}`);
      params.push(value.rule_name);
    }
    if (value.rule_type !== undefined) {
      updateFields.push(`rule_type = $${paramIndex++}`);
      params.push(value.rule_type);
    }
    if (value.vehicle_type !== undefined) {
      updateFields.push(`vehicle_type = $${paramIndex++}`);
      params.push(value.vehicle_type);
    }
    if (value.base_price_per_km !== undefined) {
      updateFields.push(`base_price_per_km = $${paramIndex++}`);
      params.push(value.base_price_per_km);
    }
    if (value.minimum_fare !== undefined) {
      updateFields.push(`minimum_fare = $${paramIndex++}`);
      params.push(value.minimum_fare);
    }
    if (value.train_station_fee !== undefined) {
      updateFields.push(`train_station_fee = $${paramIndex++}`);
      params.push(value.train_station_fee);
    }
    if (value.extra_weight_per_kg !== undefined) {
      updateFields.push(`extra_weight_per_kg = $${paramIndex++}`);
      params.push(value.extra_weight_per_kg);
    }
    if (value.helper_small_fee !== undefined) {
      updateFields.push(`helper_small_fee = $${paramIndex++}`);
      params.push(value.helper_small_fee);
    }
    if (value.helper_large_fee !== undefined) {
      updateFields.push(`helper_large_fee = $${paramIndex++}`);
      params.push(value.helper_large_fee);
    }
    if (value.round_trip_percentage !== undefined) {
      updateFields.push(`round_trip_percentage = $${paramIndex++}`);
      params.push(value.round_trip_percentage);
    }
    if (value.weight_factor !== undefined) {
      updateFields.push(`weight_factor = $${paramIndex++}`);
      params.push(value.weight_factor);
    }
    if (value.distance_factor !== undefined) {
      updateFields.push(`distance_factor = $${paramIndex++}`);
      params.push(value.distance_factor);
    }
    if (value.description !== undefined) {
      updateFields.push(`description = $${paramIndex++}`);
      params.push(value.description);
    }
    if (value.is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex++}`);
      params.push(value.is_active);
    }
    if (value.effective_from !== undefined) {
      updateFields.push(`effective_from = $${paramIndex++}`);
      params.push(value.effective_from || null);
    }
    if (value.effective_until !== undefined) {
      updateFields.push(`effective_until = $${paramIndex++}`);
      params.push(value.effective_until || null);
    }
    
    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có trường nào để cập nhật'
      });
    }
    
    updateFields.push(`updated_at = NOW()`);
    params.push(id);
    
    const query = `
      UPDATE pricing_rules
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bảng giá'
      });
    }
    
    res.json({
      success: true,
      message: 'Cập nhật bảng giá thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating pricing rule:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật bảng giá',
      error: error.message
    });
  }
};

// Delete pricing rule (soft delete by setting is_active = false)
exports.deletePricingRule = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      UPDATE pricing_rules
      SET is_active = false, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bảng giá'
      });
    }
    
    res.json({
      success: true,
      message: 'Xóa bảng giá thành công'
    });
  } catch (error) {
    console.error('Error deleting pricing rule:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa bảng giá',
      error: error.message
    });
  }
};

