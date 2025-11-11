const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getAllZones,
  createZone,
  updateZone,
  deleteZone,
  getAllRoutes,
  createRoute,
  updateRoute,
  getZoneByCoordinates
} = require('../controllers/routeManagementController');

// Middleware to check admin role
const checkAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({ status: 'error', message: 'Forbidden' });
  }

  next();
};

// Zone routes
router.get('/zones', authenticateToken, getAllZones);
router.post('/zones', authenticateToken, checkAdmin, createZone);
router.put('/zones/:zoneId', authenticateToken, checkAdmin, updateZone);
router.delete('/zones/:zoneId', authenticateToken, checkAdmin, deleteZone);
router.get('/zones/by-coordinates', authenticateToken, getZoneByCoordinates);

// Route routes
router.get('/routes', authenticateToken, getAllRoutes);
router.post('/routes', authenticateToken, checkAdmin, createRoute);
router.put('/routes/:routeId', authenticateToken, checkAdmin, updateRoute);

module.exports = router;
