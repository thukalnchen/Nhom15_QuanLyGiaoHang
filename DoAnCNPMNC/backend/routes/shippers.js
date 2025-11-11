const express = require('express');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const {
  getMyOrders,
  getOrderDetails,
  updateOrderStatus,
} = require('../controllers/shipperController');

const router = express.Router();

router.use(authenticateToken, authorizeRoles('shipper', 'admin'));

router.get('/me/orders', getMyOrders);
router.get('/orders/:id', getOrderDetails);
router.patch('/orders/:id/status', updateOrderStatus);

module.exports = router;


