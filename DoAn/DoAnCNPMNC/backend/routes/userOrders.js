const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/database');

// GET /api/users/me/orders
router.get('/me/orders', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const ordersResult = await pool.query(
      `SELECT 
        o.id,
        o.tracking_number,
        o.sender_name,
        o.sender_phone,
        o.sender_address,
        o.sender_city,
        o.sender_district,
        o.sender_ward,
        o.receiver_name,
        o.receiver_phone,
        o.receiver_address,
        o.receiver_city,
        o.receiver_district,
        o.receiver_ward,
        o.status,
        o.package_type,
        o.service_type,
        o.pickup_type,
        o.pickup_notes,
        o.parcel_weight,
        o.parcel_length,
        o.parcel_width,
        o.parcel_height,
        o.declared_value,
        o.cod_amount,
        o.insurance_fee,
        o.shipping_fee,
        o.payment_method,
        o.payment_status,
        o.payment_reference,
        o.estimated_pickup,
        o.estimated_delivery,
        o.total_amount,
        o.notes,
        o.created_at,
        o.updated_at
      FROM orders o
      WHERE o.user_id = $1
      ORDER BY o.created_at DESC`,
      [userId]
    );

    const orders = ordersResult.rows;

    for (const order of orders) {
      const itemsResult = await pool.query(
        `SELECT 
          id, 
          item_name, 
          quantity, 
          weight, 
          price 
        FROM order_items 
        WHERE order_id = $1
        ORDER BY id ASC`,
        [order.id]
      );
      order.items = itemsResult.rows;
    }

    res.json({
      message: 'Orders retrieved successfully',
      orders
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;


