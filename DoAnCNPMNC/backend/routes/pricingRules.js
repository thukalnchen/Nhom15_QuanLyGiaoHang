const express = require('express');
const router = express.Router();
const {
  getAllPricingRules,
  getActivePricingRule,
  getPricingRuleById,
  createPricingRule,
  updatePricingRule,
  deletePricingRule
} = require('../controllers/pricingRulesController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// Get all pricing rules (admin only)
router.get('/', authorizeRoles('admin'), getAllPricingRules);

// Get active pricing rule for vehicle type (public for authenticated users)
router.get('/active/:vehicleType', getActivePricingRule);

// Get pricing rule by ID (admin only)
router.get('/:id', authorizeRoles('admin'), getPricingRuleById);

// Create pricing rule (admin only)
router.post('/', authorizeRoles('admin'), createPricingRule);

// Update pricing rule (admin only)
router.put('/:id', authorizeRoles('admin'), updatePricingRule);

// Delete pricing rule (admin only)
router.delete('/:id', authorizeRoles('admin'), deletePricingRule);

module.exports = router;

