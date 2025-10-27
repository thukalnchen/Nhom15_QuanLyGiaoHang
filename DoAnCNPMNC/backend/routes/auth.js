const express = require('express');
const { register, login, getProfile, updateProfile } = require('../controllers/authController');

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);

// Protected routes
router.get('/profile', getProfile);
router.put('/profile', updateProfile);

module.exports = router;
