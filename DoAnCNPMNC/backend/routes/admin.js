const express = require('express');
const router = express.Router();
const {
  getDashboardStats,
  getAllOrders,
  getAllUsers,
  updateOrderStatus,
  getOrderById,
  getAnalytics,
  getActiveDeliveries
} = require('../controllers/adminController');
const { authenticateToken } = require('../middleware/auth');

// Apply authentication middleware to all admin routes
router.use(authenticateToken);

// Dashboard statistics
router.get('/stats', getDashboardStats);

// Orders management
router.get('/orders', getAllOrders);
router.get('/orders/:orderId', getOrderById);
router.put('/orders/:orderId/status', updateOrderStatus);

// Active deliveries for tracking
router.get('/deliveries/active', getActiveDeliveries);

// Users management
router.get('/users', getAllUsers);

// Analytics
router.get('/analytics', getAnalytics);

module.exports = router;
