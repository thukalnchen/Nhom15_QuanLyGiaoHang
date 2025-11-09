const express = require('express');
const router = express.Router();
const complaintController = require('../controllers/complaintController');
const { authenticateToken } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// Create complaint (with file upload)
router.post('/', (req, res) => {
  complaintController.upload(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    complaintController.createComplaint(req, res);
  });
});

// Get user's complaints
router.get('/my-complaints', complaintController.getUserComplaints);

// Get all complaints (admin only)
router.get('/all', complaintController.getAllComplaints);

// Get complaint detail
router.get('/:complaintId', complaintController.getComplaintDetail);

// Add response to complaint
router.post('/:complaintId/responses', complaintController.addResponse);

// Update complaint status (admin/staff only)
router.put('/:complaintId/status', complaintController.updateComplaintStatus);

module.exports = router;
