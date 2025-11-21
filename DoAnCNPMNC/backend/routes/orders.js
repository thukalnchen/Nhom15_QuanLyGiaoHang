const express = require('express');
const { 
  createOrder, 
  getUserOrders, 
  getOrderDetails, 
  getShipperLocation,
  updateOrderStatus, 
  cancelOrder,
  getCancellationStats,
  getOrderStatistics 
} = require('../controllers/orderController');
const { calculatePrice, createDeliveryOrder } = require('../controllers/deliveryController');

const router = express.Router();

// Calculate delivery price
router.post('/calculate-price', calculatePrice);

// Create delivery order
router.post('/delivery', createDeliveryOrder);

// Get order statistics (public endpoint for admin)
router.get('/stats', getOrderStatistics);

// Get cancellation statistics (admin)
router.get('/stats/cancellations', getCancellationStats);

// Create new order
router.post('/', createOrder);

// Get user's orders
router.get('/', getUserOrders);

// US-17: Get shipper location for customer tracking (must be before /:orderId)
router.get('/:orderId/shipper-location', getShipperLocation);

// Get order details
router.get('/:orderId', getOrderDetails);

// Cancel order
router.post('/:orderId/cancel', cancelOrder);

// Update order status (for admin/shipper)
router.put('/:orderId/status', updateOrderStatus);

module.exports = router;
