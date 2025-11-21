const express = require('express');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const {
  getMyOrders,
  getOrderDetails,
  updateOrderStatus,
  checkInLocation,
} = require('../controllers/shipperController');

const router = express.Router();

router.use(authenticateToken, authorizeRoles('shipper', 'admin'));

router.get('/me/orders', getMyOrders);
router.get('/orders/:id', getOrderDetails);
router.patch('/orders/:id/status', updateOrderStatus);
// US-17: Check-in location
router.post('/me/check-in', checkInLocation);

module.exports = router;


