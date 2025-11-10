const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/database');

// POST /api/feedbacks
router.post('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { order_id, type, title, content } = req.body;

    // Validation
    if (!order_id || !type || !title || !content) {
      return res.status(400).json({ error: 'Order ID, type, title, and content are required' });
    }

    if (type !== 'complaint' && type !== 'feedback') {
      return res.status(400).json({ error: 'Type must be "complaint" or "feedback"' });
    }

    // Verify order belongs to user
    const orderResult = await pool.query(
      'SELECT id FROM orders WHERE id = $1 AND user_id = $2',
      [order_id, userId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Insert feedback
    const result = await pool.query(
      'INSERT INTO feedbacks (order_id, user_id, type, title, content) VALUES ($1, $2, $3, $4, $5) RETURNING id, order_id, user_id, type, title, content, status, created_at',
      [order_id, userId, type, title, content]
    );

    const feedback = result.rows[0];

    res.status(201).json({
      message: 'Feedback submitted successfully',
      feedback
    });
  } catch (error) {
    console.error('Create feedback error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

