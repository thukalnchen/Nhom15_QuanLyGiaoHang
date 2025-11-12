const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getAvailableDrivers,
  assignDriverToOrder,
  reassignDriver,
  getDriverWorkload
} = require('../controllers/driverAssignmentController');

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

// GET available drivers
router.get('/available', authenticateToken, checkAdminOrStaff, getAvailableDrivers);

// POST assign driver to order
router.post('/orders/:orderId/assign', authenticateToken, checkAdminOrStaff, assignDriverToOrder);

// PUT reassign driver to order
router.put('/orders/:orderId/reassign', authenticateToken, checkAdminOrStaff, reassignDriver);

// GET driver workload
router.get('/drivers/:driverId/workload', authenticateToken, getDriverWorkload);

module.exports = router;
