const express = require('express');
const { getProfile, updateProfile } = require('../controllers/authController');

const router = express.Router();

// Get user profile
router.get('/profile', getProfile);

// Update user profile
router.put('/profile', updateProfile);

module.exports = router;
