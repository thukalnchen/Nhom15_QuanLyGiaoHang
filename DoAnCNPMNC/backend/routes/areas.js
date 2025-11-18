const express = require('express');
const router = express.Router();
const {
  getAllAreas,
  getAreaById,
  createArea,
  updateArea,
  deleteArea
} = require('../controllers/areaController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// Apply authentication middleware to all area routes
router.use(authenticateToken, authorizeRoles('admin'));

// CRUD routes
router.get('/', getAllAreas);
router.get('/:id', getAreaById);
router.post('/', createArea);
router.put('/:id', updateArea);
router.delete('/:id', deleteArea);

module.exports = router;

