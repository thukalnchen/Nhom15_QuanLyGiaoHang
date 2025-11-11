const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getRevenueReport,
  getDeliveryStatistics,
  getDriverPerformanceReport,
  getCustomerAnalytics,
  getDashboardSummary
} = require('../controllers/reportingController');

// Middleware to check admin or manager role
const checkAdminOrManager = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  if (!['admin', 'manager'].includes(req.user.role)) {
    return res.status(403).json({ status: 'error', message: 'Forbidden' });
  }

  next();
};

// Revenue reports
router.get('/revenue', authenticateToken, checkAdminOrManager, getRevenueReport);

// Delivery statistics
router.get('/delivery-stats', authenticateToken, checkAdminOrManager, getDeliveryStatistics);

// Driver performance
router.get('/driver-performance', authenticateToken, checkAdminOrManager, getDriverPerformanceReport);

// Customer analytics
router.get('/customer-analytics', authenticateToken, checkAdminOrManager, getCustomerAnalytics);

// Dashboard summary
router.get('/dashboard', authenticateToken, checkAdminOrManager, getDashboardSummary);

module.exports = router;
