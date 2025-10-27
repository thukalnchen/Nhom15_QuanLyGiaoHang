const Joi = require('joi');
const { pool } = require('../config/database');

// Validation schemas
const updateLocationSchema = Joi.object({
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  address: Joi.string().optional(),
  status: Joi.string().valid('preparing', 'picked_up', 'on_the_way', 'delivered').optional()
});

// Update delivery location
const updateLocation = async (req, res) => {
  try {
    const { orderId } = req.params;
    
    // Validate input
    const { error, value } = updateLocationSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const { latitude, longitude, address, status } = value;

    // Check if order exists and user has permission
    const orderResult = await pool.query(
      'SELECT id FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }

    // Update delivery tracking
    const updateFields = ['latitude = $1', 'longitude = $2', 'updated_at = CURRENT_TIMESTAMP'];
    const updateValues = [latitude, longitude];
    let paramCount = 2;

    if (address) {
      paramCount++;
      updateFields.push(`address = $${paramCount}`);
      updateValues.push(address);
    }

    if (status) {
      paramCount++;
      updateFields.push(`status = $${paramCount}`);
      updateValues.push(status);
    }

    updateValues.push(orderId);

    const result = await pool.query(
      `UPDATE delivery_tracking 
       SET ${updateFields.join(', ')}
       WHERE order_id = $${paramCount + 1}
       RETURNING *`,
      updateValues
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Delivery tracking not found'
      });
    }

    const tracking = result.rows[0];

    // Emit real-time update via Socket.IO
    const io = req.app.get('io');
    io.to(`order-${orderId}`).emit('location-update', {
      order_id: orderId,
      latitude: parseFloat(tracking.latitude),
      longitude: parseFloat(tracking.longitude),
      address: tracking.address,
      status: tracking.status,
      updated_at: tracking.updated_at
    });

    res.json({
      status: 'success',
      message: 'Location updated successfully',
      data: {
        tracking: {
          order_id: orderId,
          latitude: parseFloat(tracking.latitude),
          longitude: parseFloat(tracking.longitude),
          address: tracking.address,
          status: tracking.status,
          updated_at: tracking.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get current delivery location
const getLocation = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Check if order exists and user has permission
    const orderResult = await pool.query(
      'SELECT id FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }

    // Get delivery tracking
    const trackingResult = await pool.query(
      'SELECT * FROM delivery_tracking WHERE order_id = $1 ORDER BY updated_at DESC LIMIT 1',
      [orderId]
    );

    if (trackingResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Delivery tracking not found'
      });
    }

    const tracking = trackingResult.rows[0];

    res.json({
      status: 'success',
      data: {
        tracking: {
          order_id: orderId,
          latitude: tracking.latitude ? parseFloat(tracking.latitude) : null,
          longitude: tracking.longitude ? parseFloat(tracking.longitude) : null,
          address: tracking.address,
          status: tracking.status,
          updated_at: tracking.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Get location error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

// Get delivery history
const getDeliveryHistory = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Check if order exists and user has permission
    const orderResult = await pool.query(
      'SELECT id FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }

    // Get delivery tracking history
    const historyResult = await pool.query(
      `SELECT dt.*, osh.status as order_status, osh.notes, osh.created_at as status_time
       FROM delivery_tracking dt
       LEFT JOIN order_status_history osh ON dt.order_id = osh.order_id
       WHERE dt.order_id = $1
       ORDER BY dt.updated_at ASC`,
      [orderId]
    );

    const history = historyResult.rows.map(record => ({
      latitude: record.latitude ? parseFloat(record.latitude) : null,
      longitude: record.longitude ? parseFloat(record.longitude) : null,
      address: record.address,
      status: record.status,
      order_status: record.order_status,
      notes: record.notes,
      updated_at: record.updated_at,
      status_time: record.status_time
    }));

    res.json({
      status: 'success',
      data: {
        order_id: orderId,
        history
      }
    });
  } catch (error) {
    console.error('Get delivery history error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  updateLocation,
  getLocation,
  getDeliveryHistory
};
