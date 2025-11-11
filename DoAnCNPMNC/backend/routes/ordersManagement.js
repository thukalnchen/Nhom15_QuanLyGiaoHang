const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  updateOrderDetails,
  getOrderStatistics
} = require('../controllers/ordersManagementController');

// Middleware to check admin or staff role
const checkAdminOrStaff = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  if (!['admin', 'intake_staff'].includes(req.user.role)) {
    return res.status(403).json({ status: 'error', message: 'Forbidden' });
  }

  next();
};

// GET all orders with advanced filters
router.get('/', authenticateToken, checkAdminOrStaff, getAllOrders);

// GET order by ID
router.get('/:orderId', authenticateToken, checkAdminOrStaff, getOrderById);

// PUT update order status
router.put('/:orderId/status', authenticateToken, checkAdminOrStaff, updateOrderStatus);

// PUT update order details
router.put('/:orderId/details', authenticateToken, checkAdminOrStaff, updateOrderDetails);

// GET order statistics
router.get('/stats/summary', authenticateToken, checkAdminOrStaff, getOrderStatistics);

module.exports = router;
