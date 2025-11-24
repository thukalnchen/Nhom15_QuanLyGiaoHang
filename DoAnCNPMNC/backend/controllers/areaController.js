const Joi = require('joi');
const { pool } = require('../config/database');

// Validation schemas
const createAreaSchema = Joi.object({
  name: Joi.string().required().max(255),
  code: Joi.string().required().max(50),
  description: Joi.string().allow('', null),
  center_latitude: Joi.number().min(-90).max(90).allow(null).optional(),
  center_longitude: Joi.number().min(-180).max(180).allow(null).optional(),
  service_radius_km: Joi.number().min(0).default(10.0).optional(),
  is_active: Joi.boolean().default(true).optional()
});

const updateAreaSchema = Joi.object({
  name: Joi.string().max(255),
  code: Joi.string().max(50),
  description: Joi.string().allow('', null),
  center_latitude: Joi.number().min(-90).max(90).allow(null).optional(),
  center_longitude: Joi.number().min(-180).max(180).allow(null).optional(),
  service_radius_km: Joi.number().min(0).optional(),
  is_active: Joi.boolean().optional()
});

// Get all areas
const getAllAreas = async (req, res) => {
  try {
    const { limit = 100, offset = 0 } = req.query;

    const result = await pool.query(
      `SELECT id, name, code, description, center_latitude, center_longitude, service_radius_km, is_active, created_at, updated_at
       FROM delivery_areas
       ORDER BY name ASC
       LIMIT $1 OFFSET $2`,
      [parseInt(limit, 10), parseInt(offset, 10)]
    );

    const countResult = await pool.query('SELECT COUNT(*) as count FROM delivery_areas');
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      status: 'success',
      data: {
        areas: result.rows,
        pagination: {
          total: totalCount,
          limit: parseInt(limit, 10),
          offset: parseInt(offset, 10),
          pages: Math.ceil(totalCount / parseInt(limit, 10))
        }
      }
    });
  } catch (error) {
    console.error('Error getting areas:', error);
    console.error('Error stack:', error.stack);
    
    // Check if table doesn't exist
    if (error.code === '42P01') {
      return res.status(500).json({
        status: 'error',
        message: 'Bảng delivery_areas chưa được tạo. Vui lòng chạy migration script migrate_sprint7.sql',
        error: error.message
      });
    }
    
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách khu vực',
      error: error.message
    });
  }
};

// Get area by ID
const getAreaById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT id, name, code, description, center_latitude, center_longitude, service_radius_km, is_active, created_at, updated_at
       FROM delivery_areas
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực'
      });
    }

    res.json({
      status: 'success',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting area:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thông tin khu vực',
      error: error.message
    });
  }
};

// Create new area
const createArea = async (req, res) => {
  try {
    const { error, value } = createAreaSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    // Check if code already exists
    const existingArea = await pool.query(
      'SELECT id FROM delivery_areas WHERE code = $1',
      [value.code]
    );

    if (existingArea.rows.length > 0) {
      return res.status(409).json({
        status: 'error',
        message: 'Mã khu vực đã tồn tại'
      });
    }

    const result = await pool.query(
      `INSERT INTO delivery_areas (name, code, description, center_latitude, center_longitude, service_radius_km, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, name, code, description, center_latitude, center_longitude, service_radius_km, is_active, created_at, updated_at`,
      [
        value.name, 
        value.code, 
        value.description || null,
        value.center_latitude || null,
        value.center_longitude || null,
        value.service_radius_km || 10.0,
        value.is_active !== undefined ? value.is_active : true
      ]
    );

    res.status(201).json({
      status: 'success',
      message: 'Tạo khu vực thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating area:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tạo khu vực',
      error: error.message
    });
  }
};

// Update area
const updateArea = async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateAreaSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    // Check if area exists
    const existingArea = await pool.query(
      'SELECT id FROM delivery_areas WHERE id = $1',
      [id]
    );

    if (existingArea.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực'
      });
    }

    // Check if code is being updated and if it conflicts
    if (value.code) {
      const codeCheck = await pool.query(
        'SELECT id FROM delivery_areas WHERE code = $1 AND id != $2',
        [value.code, id]
      );

      if (codeCheck.rows.length > 0) {
        return res.status(409).json({
          status: 'error',
          message: 'Mã khu vực đã tồn tại'
        });
      }
    }

    // Build update query
    const updates = [];
    const params = [];
    let paramCount = 1;

    if (value.name !== undefined) {
      updates.push(`name = $${paramCount}`);
      params.push(value.name);
      paramCount++;
    }
    if (value.code !== undefined) {
      updates.push(`code = $${paramCount}`);
      params.push(value.code);
      paramCount++;
    }
    if (value.description !== undefined) {
      updates.push(`description = $${paramCount}`);
      params.push(value.description || null);
      paramCount++;
    }
    if (value.center_latitude !== undefined) {
      updates.push(`center_latitude = $${paramCount}`);
      params.push(value.center_latitude || null);
      paramCount++;
    }
    if (value.center_longitude !== undefined) {
      updates.push(`center_longitude = $${paramCount}`);
      params.push(value.center_longitude || null);
      paramCount++;
    }
    if (value.service_radius_km !== undefined) {
      updates.push(`service_radius_km = $${paramCount}`);
      params.push(value.service_radius_km);
      paramCount++;
    }
    if (value.is_active !== undefined) {
      updates.push(`is_active = $${paramCount}`);
      params.push(value.is_active);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Không có thông tin nào để cập nhật'
      });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `
      UPDATE delivery_areas 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, code, description, center_latitude, center_longitude, service_radius_km, is_active, created_at, updated_at
    `;

    const result = await pool.query(query, params);

    res.json({
      status: 'success',
      message: 'Cập nhật khu vực thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating area:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật khu vực',
      error: error.message
    });
  }
};

// Delete area
const deleteArea = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if area exists
    const existingArea = await pool.query(
      'SELECT id, name FROM delivery_areas WHERE id = $1',
      [id]
    );

    if (existingArea.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực'
      });
    }

    // Check if area is being used in orders (optional check)
    // For now, we'll allow deletion but you can add this check if needed

    await pool.query('DELETE FROM delivery_areas WHERE id = $1', [id]);

    res.json({
      status: 'success',
      message: 'Xóa khu vực thành công'
    });
  } catch (error) {
    console.error('Error deleting area:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xóa khu vực',
      error: error.message
    });
  }
};

module.exports = {
  getAllAreas,
  getAreaById,
  createArea,
  updateArea,
  deleteArea
};

