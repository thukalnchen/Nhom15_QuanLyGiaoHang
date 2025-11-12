const express = require('express');
const router = express.Router();
const {
  getDashboardStats,
  getAllOrders,
  getAllUsers,
  updateOrderStatus,
  getOrderById,
  getAnalytics,
  getActiveDeliveries,
  getShippers,
  getShipperById,
  updateShipperStatus
} = require('../controllers/adminController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// Apply authentication middleware to all admin routes
router.use(authenticateToken, authorizeRoles('admin'));

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

// Shipper management
router.get('/shippers', getShippers);
router.get('/shippers/:shipperId', getShipperById);
router.patch('/shippers/:shipperId/status', updateShipperStatus);

// Analytics
router.get('/analytics', getAnalytics);

module.exports = router;
