const express = require('express');
const router = express.Router();
const {
  getAllHubs,
  getHubById,
  createHub,
  updateHub,
  deleteHub
} = require('../controllers/hubsController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// All routes require admin authentication
router.use(authenticateToken, authorizeRoles('admin'));

// Get all hubs
router.get('/', getAllHubs);

// Get hub by ID
router.get('/:id', getHubById);

// Create hub
router.post('/', createHub);

// Update hub
router.put('/:id', updateHub);

// Delete hub
router.delete('/:id', deleteHub);

module.exports = router;

