const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getPricingTable,
  updatePricing,
  getSurchargePolicies,
  createSurchargePolicy,
  updateSurchargePolicy,
  deleteSurchargePolicy,
  getDiscountPolicies,
  createDiscountPolicy,
  updateDiscountPolicy,
  deleteDiscountPolicy,
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
router.put('/surcharges/:id', authenticateToken, checkAdmin, updateSurchargePolicy);
router.delete('/surcharges/:id', authenticateToken, checkAdmin, deleteSurchargePolicy);

// Discount policy routes
router.get('/discounts', authenticateToken, getDiscountPolicies);
router.post('/discounts', authenticateToken, checkAdmin, createDiscountPolicy);
router.put('/discounts/:id', authenticateToken, checkAdmin, updateDiscountPolicy);
router.delete('/discounts/:id', authenticateToken, checkAdmin, deleteDiscountPolicy);

// Validate discount code (can be called by anyone)
router.post('/discounts/validate', validateDiscountCode);

module.exports = router;
