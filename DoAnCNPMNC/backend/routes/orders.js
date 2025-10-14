const express = require('express');
const { createOrder, getUserOrders, getOrderDetails, updateOrderStatus, getOrderStatistics } = require('../controllers/orderController');

const router = express.Router();

// Get order statistics (public endpoint for admin)
router.get('/stats', getOrderStatistics);

// Create new order
router.post('/', createOrder);

// Get user's orders
router.get('/', getUserOrders);

// Get order details
router.get('/:orderId', getOrderDetails);

// Update order status (for admin/shipper)
router.put('/:orderId/status', updateOrderStatus);

module.exports = router;
