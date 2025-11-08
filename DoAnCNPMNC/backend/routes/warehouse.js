const express = require('express');
const router = express.Router();
const warehouseController = require('../controllers/warehouseController');
const { authenticateToken } = require('../middleware/auth');

// Middleware: Only intake_staff can access
const intakeStaffOnly = (req, res, next) => {
  if (req.user.role !== 'intake_staff') {
    return res.status(403).json({
      success: false,
      message: 'Chỉ nhân viên kho mới có quyền truy cập'
    });
  }
  next();
};

// All routes require authentication
router.use(authenticateToken);
router.use(intakeStaffOnly);

// Get warehouse orders
router.get('/orders', warehouseController.getWarehouseOrders);

// Search order by code (for QR scan)
router.get('/orders/search', warehouseController.searchOrderByCode);

// Story #8: Receive order
router.post('/receive', warehouseController.receiveOrder);

// Story #9: Classify order
router.post('/classify', warehouseController.classifyOrder);

// Story #21: Assign driver
router.post('/assign-driver', warehouseController.assignDriver);

// Get available drivers
router.get('/drivers/available', warehouseController.getAvailableDrivers);

// Story #12: Collect COD at warehouse
router.post('/collect-cod', warehouseController.collectCOD);

// Story #11: Generate receipt
router.post('/generate-receipt', warehouseController.generateReceipt);

// Statistics
router.get('/statistics', warehouseController.getStatistics);

module.exports = router;
