const { pool } = require('../config/database');

// Zone-related operations

// Get all zones
const getAllZones = async (req, res) => {
  try {
    const { isActive, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT 
        id,
        zone_code,
        zone_name,
        description,
        base_price,
        price_per_km,
        is_active,
        polygon_coordinates,
        center_latitude,
        center_longitude,
        created_at,
        updated_at
      FROM zones
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (isActive !== undefined) {
      query += ` AND is_active = $${paramCount}`;
      params.push(isActive === 'true');
      paramCount++;
    }

    query += ` ORDER BY zone_code ASC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    res.json({
      status: 'success',
      data: {
        zones: result.rows,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    console.error('Error getting zones:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách khu vực',
      error: error.message
    });
  }
};

// Create zone
const createZone = async (req, res) => {
  try {
    const {
      zoneCode,
      zoneName,
      description,
      basePrice,
      pricePerKm,
      polygonCoordinates,
      centerLatitude,
      centerLongitude
    } = req.body;

    if (!zoneCode || !zoneName || !basePrice || !pricePerKm) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng điền đầy đủ các trường bắt buộc'
      });
    }

    const query = `
      INSERT INTO zones (
        zone_code,
        zone_name,
        description,
        base_price,
        price_per_km,
        polygon_coordinates,
        center_latitude,
        center_longitude,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      zoneCode,
      zoneName,
      description || null,
      parseFloat(basePrice),
      parseFloat(pricePerKm),
      polygonCoordinates ? JSON.stringify(polygonCoordinates) : null,
      parseFloat(centerLatitude) || null,
      parseFloat(centerLongitude) || null
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Tạo khu vực mới thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating zone:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tạo khu vực',
      error: error.message
    });
  }
};

// Update zone
const updateZone = async (req, res) => {
  try {
    const { zoneId } = req.params;
    const {
      zoneName,
      description,
      basePrice,
      pricePerKm,
      polygonCoordinates,
      centerLatitude,
      centerLongitude,
      isActive
    } = req.body;

    const query = `
      UPDATE zones
      SET 
        zone_name = COALESCE($1, zone_name),
        description = COALESCE($2, description),
        base_price = COALESCE($3::DECIMAL, base_price),
        price_per_km = COALESCE($4::DECIMAL, price_per_km),
        polygon_coordinates = COALESCE($5, polygon_coordinates),
        center_latitude = COALESCE($6::DECIMAL, center_latitude),
        center_longitude = COALESCE($7::DECIMAL, center_longitude),
        is_active = COALESCE($8, is_active),
        updated_at = NOW()
      WHERE id = $9
      RETURNING *
    `;

    const result = await pool.query(query, [
      zoneName || null,
      description || null,
      basePrice || null,
      pricePerKm || null,
      polygonCoordinates ? JSON.stringify(polygonCoordinates) : null,
      centerLatitude || null,
      centerLongitude || null,
      isActive !== undefined ? isActive : null,
      zoneId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực'
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật khu vực thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating zone:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật khu vực',
      error: error.message
    });
  }
};

// Delete zone
const deleteZone = async (req, res) => {
  try {
    const { zoneId } = req.params;

    // Check if zone has active orders
    const checkQuery = `
      SELECT COUNT(*) as count FROM orders
      WHERE delivery_zone_id = $1 AND status NOT IN ('delivered', 'cancelled')
    `;

    const checkResult = await pool.query(checkQuery, [zoneId]);

    if (parseInt(checkResult.rows[0].count) > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Không thể xóa khu vực có đơn hàng đang xử lý'
      });
    }

    const deleteQuery = `
      DELETE FROM zones WHERE id = $1 RETURNING id
    `;

    const result = await pool.query(deleteQuery, [zoneId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực'
      });
    }

    res.json({
      status: 'success',
      message: 'Xóa khu vực thành công'
    });
  } catch (error) {
    console.error('Error deleting zone:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xóa khu vực',
      error: error.message
    });
  }
};

// Get routes (delivery routes)
const getAllRoutes = async (req, res) => {
  try {
    const { status, zoneId, driverId, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT 
        id,
        route_code,
        route_name,
        zone_id,
        driver_id,
        start_point,
        end_point,
        total_distance,
        estimated_duration,
        status,
        orders_count,
        created_at,
        updated_at
      FROM routes
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (status) {
      query += ` AND status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (zoneId) {
      query += ` AND zone_id = $${paramCount}`;
      params.push(zoneId);
      paramCount++;
    }

    if (driverId) {
      query += ` AND driver_id = $${paramCount}`;
      params.push(driverId);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    res.json({
      status: 'success',
      data: {
        routes: result.rows,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    console.error('Error getting routes:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải danh sách tuyến đường',
      error: error.message
    });
  }
};

// Create route
const createRoute = async (req, res) => {
  try {
    const {
      routeCode,
      routeName,
      zoneId,
      driverId,
      startPoint,
      endPoint,
      totalDistance,
      estimatedDuration
    } = req.body;

    if (!routeCode || !routeName || !zoneId) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng điền đầy đủ các trường bắt buộc'
      });
    }

    const query = `
      INSERT INTO routes (
        route_code,
        route_name,
        zone_id,
        driver_id,
        start_point,
        end_point,
        total_distance,
        estimated_duration,
        status,
        orders_count,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active', 0, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      routeCode,
      routeName,
      zoneId,
      driverId || null,
      startPoint || null,
      endPoint || null,
      totalDistance || 0,
      estimatedDuration || null
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Tạo tuyến đường mới thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating route:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tạo tuyến đường',
      error: error.message
    });
  }
};

// Update route
const updateRoute = async (req, res) => {
  try {
    const { routeId } = req.params;
    const {
      routeName,
      zoneId,
      driverId,
      startPoint,
      endPoint,
      totalDistance,
      estimatedDuration,
      status
    } = req.body;

    const query = `
      UPDATE routes
      SET 
        route_name = COALESCE($1, route_name),
        zone_id = COALESCE($2, zone_id),
        driver_id = COALESCE($3, driver_id),
        start_point = COALESCE($4, start_point),
        end_point = COALESCE($5, end_point),
        total_distance = COALESCE($6::DECIMAL, total_distance),
        estimated_duration = COALESCE($7, estimated_duration),
        status = COALESCE($8, status),
        updated_at = NOW()
      WHERE id = $9
      RETURNING *
    `;

    const result = await pool.query(query, [
      routeName || null,
      zoneId || null,
      driverId || null,
      startPoint || null,
      endPoint || null,
      totalDistance || null,
      estimatedDuration || null,
      status || null,
      routeId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy tuyến đường'
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật tuyến đường thành công',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating route:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi cập nhật tuyến đường',
      error: error.message
    });
  }
};

// Get location point by coordinates
const getZoneByCoordinates = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng cung cấp tọa độ (latitude, longitude)'
      });
    }

    // Using PostgreSQL GIS (if installed) or simple distance calculation
    const query = `
      SELECT 
        id,
        zone_code,
        zone_name,
        base_price,
        price_per_km,
        center_latitude,
        center_longitude
      FROM zones
      WHERE is_active = true
      ORDER BY 
        (center_latitude - $1)^2 + (center_longitude - $2)^2
      LIMIT 1
    `;

    const result = await pool.query(query, [
      parseFloat(latitude),
      parseFloat(longitude)
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy khu vực cho tọa độ này'
      });
    }

    res.json({
      status: 'success',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error getting zone by coordinates:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi xác định khu vực',
      error: error.message
    });
  }
};

module.exports = {
  getAllZones,
  createZone,
  updateZone,
  deleteZone,
  getAllRoutes,
  createRoute,
  updateRoute,
  getZoneByCoordinates
};
