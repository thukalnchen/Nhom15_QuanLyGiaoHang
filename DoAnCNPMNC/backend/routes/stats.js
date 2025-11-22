const express = require('express');
const router = express.Router();
const {
  getRevenueStats,
  getPerformanceStats
} = require('../controllers/statsController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// All routes require admin authentication
router.use(authenticateToken, authorizeRoles('admin'));

// Get revenue statistics
router.get('/revenue', getRevenueStats);

// Get performance statistics
router.get('/performance', getPerformanceStats);

module.exports = router;

