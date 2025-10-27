const express = require('express');
const { updateLocation, getLocation, getDeliveryHistory } = require('../controllers/trackingController');

const router = express.Router();

// Update delivery location
router.put('/:orderId/location', updateLocation);

// Get current delivery location
router.get('/:orderId/location', getLocation);

// Get delivery history
router.get('/:orderId/history', getDeliveryHistory);

module.exports = router;
