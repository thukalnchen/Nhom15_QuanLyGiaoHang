const { pool } = require('../config/database');
const Joi = require('joi');

// Validation schema for hubs
const hubSchema = Joi.object({
  hub_code: Joi.string().required().max(50),
  hub_name: Joi.string().required().max(255),
  hub_type: Joi.string().valid('warehouse', 'post_office', 'checkpoint').required(),
  address: Joi.string().required(),
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  contact_phone: Joi.string().max(20).allow(null, '').optional(),
  contact_email: Joi.string().email().max(255).allow(null, '').optional(),
  manager_name: Joi.string().max(255).allow(null, '').optional(),
  operating_hours: Joi.string().max(255).allow(null, '').optional(),
  description: Joi.string().allow(null, '').optional(),
  is_active: Joi.boolean().default(true)
});

// Get all hubs
exports.getAllHubs = async (req, res) => {
  try {
    const { hub_type, is_active } = req.query;
    
    let query = `
      SELECT 
        id,
        hub_code,
        hub_name,
        hub_type,
        address,
        latitude,
        longitude,
        contact_phone,
        contact_email,
        manager_name,
        operating_hours,
        description,
        is_active,
        created_at,
        updated_at
      FROM hubs
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;
    
    if (hub_type) {
      query += ` AND hub_type = $${paramIndex}`;
      params.push(hub_type);
      paramIndex++;
    }
    
    if (is_active !== undefined) {
      query += ` AND is_active = $${paramIndex}`;
      params.push(is_active === 'true');
      paramIndex++;
    }
    
    query += ` ORDER BY hub_name ASC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting hubs:', error);
    console.error('Error stack:', error.stack);
    
    // Check if table doesn't exist
    if (error.code === '42P01') {
      return res.status(500).json({
        success: false,
        message: 'Bảng hubs chưa được tạo. Vui lòng chạy migration script migrate_sprint7.sql',
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải danh sách kho/bưu cục',
      error: error.message
    });
  }
};

// Get hub by ID
exports.getHubById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT 
        id,
        hub_code,
        hub_name,
        hub_type,
        address,
        latitude,
        longitude,
        contact_phone,
        contact_email,
        manager_name,
        operating_hours,
        description,
        is_active,
        created_at,
        updated_at
      FROM hubs
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kho/bưu cục'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting hub by ID:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải thông tin kho/bưu cục',
      error: error.message
    });
  }
};

// Create hub
exports.createHub = async (req, res) => {
  try {
    // Validate input
    const { error, value } = hubSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        errors: error.details.map(d => d.message)
      });
    }
    
    const {
      hub_code,
      hub_name,
      hub_type,
      address,
      latitude,
      longitude,
      contact_phone,
      contact_email,
      manager_name,
      operating_hours,
      description,
      is_active = true
    } = value;
    
    const query = `
      INSERT INTO hubs (
        hub_code,
        hub_name,
        hub_type,
        address,
        latitude,
        longitude,
        contact_phone,
        contact_email,
        manager_name,
        operating_hours,
        description,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      hub_code,
      hub_name,
      hub_type,
      address,
      latitude,
      longitude,
      contact_phone || null,
      contact_email || null,
      manager_name || null,
      operating_hours || null,
      description || null,
      is_active
    ]);
    
    res.status(201).json({
      success: true,
      message: 'Tạo kho/bưu cục thành công',
      data: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') { // Unique violation
      return res.status(400).json({
        success: false,
        message: 'Mã kho/bưu cục đã tồn tại'
      });
    }
    
    console.error('Error creating hub:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo kho/bưu cục',
      error: error.message
    });
  }
};

// Update hub
exports.updateHub = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate input (all fields optional for update)
    const updateSchema = hubSchema.fork(Object.keys(hubSchema.describe().keys), (schema) => schema.optional());
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
    
    if (value.hub_code !== undefined) {
      updateFields.push(`hub_code = $${paramIndex++}`);
      params.push(value.hub_code);
    }
    if (value.hub_name !== undefined) {
      updateFields.push(`hub_name = $${paramIndex++}`);
      params.push(value.hub_name);
    }
    if (value.hub_type !== undefined) {
      updateFields.push(`hub_type = $${paramIndex++}`);
      params.push(value.hub_type);
    }
    if (value.address !== undefined) {
      updateFields.push(`address = $${paramIndex++}`);
      params.push(value.address);
    }
    if (value.latitude !== undefined) {
      updateFields.push(`latitude = $${paramIndex++}`);
      params.push(value.latitude);
    }
    if (value.longitude !== undefined) {
      updateFields.push(`longitude = $${paramIndex++}`);
      params.push(value.longitude);
    }
    if (value.contact_phone !== undefined) {
      updateFields.push(`contact_phone = $${paramIndex++}`);
      params.push(value.contact_phone || null);
    }
    if (value.contact_email !== undefined) {
      updateFields.push(`contact_email = $${paramIndex++}`);
      params.push(value.contact_email || null);
    }
    if (value.manager_name !== undefined) {
      updateFields.push(`manager_name = $${paramIndex++}`);
      params.push(value.manager_name || null);
    }
    if (value.operating_hours !== undefined) {
      updateFields.push(`operating_hours = $${paramIndex++}`);
      params.push(value.operating_hours || null);
    }
    if (value.description !== undefined) {
      updateFields.push(`description = $${paramIndex++}`);
      params.push(value.description || null);
    }
    if (value.is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex++}`);
      params.push(value.is_active);
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
      UPDATE hubs
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kho/bưu cục'
      });
    }
    
    res.json({
      success: true,
      message: 'Cập nhật kho/bưu cục thành công',
      data: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') { // Unique violation
      return res.status(400).json({
        success: false,
        message: 'Mã kho/bưu cục đã tồn tại'
      });
    }
    
    console.error('Error updating hub:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật kho/bưu cục',
      error: error.message
    });
  }
};

// Delete hub (soft delete)
exports.deleteHub = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      UPDATE hubs
      SET is_active = false, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kho/bưu cục'
      });
    }
    
    res.json({
      success: true,
      message: 'Xóa kho/bưu cục thành công'
    });
  } catch (error) {
    console.error('Error deleting hub:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa kho/bưu cục',
      error: error.message
    });
  }
};

