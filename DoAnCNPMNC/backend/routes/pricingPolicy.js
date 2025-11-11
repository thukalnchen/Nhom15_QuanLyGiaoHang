const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getPricingTable,
  updatePricing,
  getSurchargePolicies,
  createSurchargePolicy,
  updateSurchargePolicy,
  getDiscountPolicies,
  createDiscountPolicy,
  validateDiscountCode
} = require('../controllers/pricingPolicyController');

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

// Pricing routes (everyone can view, only admin can update)
router.get('/pricing', authenticateToken, getPricingTable);
router.put('/pricing', authenticateToken, checkAdmin, updatePricing);

// Surcharge policy routes
router.get('/surcharges', authenticateToken, getSurchargePolicies);
router.post('/surcharges', authenticateToken, checkAdmin, createSurchargePolicy);
router.put('/surcharges/:policyId', authenticateToken, checkAdmin, updateSurchargePolicy);

// Discount policy routes
router.get('/discounts', authenticateToken, getDiscountPolicies);
router.post('/discounts', authenticateToken, checkAdmin, createDiscountPolicy);

// Validate discount code (can be called by anyone)
router.post('/discounts/validate', validateDiscountCode);

module.exports = router;
