const { pool } = require('../config/database');

/**
 * Log system activity to system_logs table
 * Only logs important actions (not GET requests for viewing)
 * 
 * @param {Object} req - Express request object
 * @param {string} action - Action name (e.g., 'LOGIN', 'DELETE_ORDER', 'UPDATE_PRICE')
 * @param {string} targetType - Type of target entity (e.g., 'order', 'user', 'pricing_rule')
 * @param {number} targetId - ID of target entity
 * @param {Object} details - Additional details to log
 */
const logActivity = async (req, action, targetType = null, targetId = null, details = {}) => {
  try {
    const userId = req.user?.id || null;
    const ipAddress = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'] || null;
    const userAgent = req.headers['user-agent'] || null;

    await pool.query(
      `INSERT INTO system_logs (user_id, action, target_type, target_id, ip_address, user_agent, details)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [userId, action, targetType, targetId, ipAddress, userAgent, JSON.stringify(details)]
    );
  } catch (error) {
    // Don't throw error - logging should not break the application
    console.error('Error logging activity:', error.message);
  }
};

/**
 * Middleware to automatically log login attempts
 */
const logLogin = async (req, res, next) => {
  // Log after successful login (called from authController)
  res.on('finish', async () => {
    if (res.statusCode === 200 && req.body?.email) {
      try {
        const result = await pool.query(
          'SELECT id FROM users WHERE email = $1',
          [req.body.email]
        );
        const userId = result.rows[0]?.id || null;
        
        await logActivity(
          { user: { id: userId }, ip: req.ip, headers: req.headers },
          'LOGIN',
          'user',
          userId,
          { email: req.body.email, role: req.body.role }
        );
      } catch (error) {
        console.error('Error logging login:', error.message);
      }
    }
  });
  next();
};

/**
 * Middleware to log important admin actions
 * Use this middleware on routes that perform critical operations
 */
const logAdminAction = (action, targetType = null) => {
  return async (req, res, next) => {
    // Log after the action completes
    const originalSend = res.json;
    res.json = function(data) {
      // Only log if action was successful
      if (res.statusCode >= 200 && res.statusCode < 300) {
        const targetId = req.params.id || req.params.orderId || req.params.userId || req.body.id || null;
        logActivity(req, action, targetType, targetId, {
          method: req.method,
          path: req.path,
          body: req.method !== 'GET' ? req.body : undefined
        });
      }
      return originalSend.call(this, data);
    };
    next();
  };
};

module.exports = {
  logActivity,
  logLogin,
  logAdminAction
};

