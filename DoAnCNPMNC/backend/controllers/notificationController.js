const { pool } = require('../config/database');
const admin = require('firebase-admin');
const { sendEmail, sendBulkEmail } = require('../services/emailService');
const Joi = require('joi');

// Get socketNotificationService from server.js (will be set after server initialization)
let getSocketNotificationService = () => {
  try {
    // Try to get from app if available
    const app = require('../server');
    return app.socketNotificationService || null;
  } catch (e) {
    return null;
  }
};

// Initialize Firebase Admin (only if not already initialized)
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (!firebaseInitialized && !admin.apps.length) {
    try {
      // In production, use service account JSON file
      // For development, you can use environment variables
      if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
        const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      } else if (process.env.FIREBASE_PROJECT_ID) {
        // Use environment variables for Firebase config
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId: process.env.FIREBASE_PROJECT_ID
        });
      } else {
        console.warn('Firebase not configured. Push notifications will not work.');
        return false;
      }
      firebaseInitialized = true;
      console.log('Firebase Admin initialized successfully');
      return true;
    } catch (error) {
      console.error('Failed to initialize Firebase:', error.message);
      return false;
    }
  }
  return firebaseInitialized;
};

// Save FCM token
const saveToken = async (req, res) => {
  try {
    const { fcm_token } = req.body;
    const userId = req.user.id;

    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    const query = `
      UPDATE users 
      SET fcm_token = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, email, full_name
    `;

    const result = await pool.query(query, [fcm_token, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'FCM token saved successfully',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Save FCM token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save FCM token',
      error: error.message
    });
  }
};

// Send push notification to a user via Socket.IO
const sendPushNotification = async (userId, notification, req = null) => {
  try {
    // Try Socket.IO first (real-time, no external dependency)
    let socketService = null;
    if (req && req.app) {
      socketService = req.app.get('socketNotificationService');
    } else {
      // Try to get from global export (after server initialization)
      socketService = getSocketNotificationService();
    }
    
    if (socketService) {
      console.log(`[Notification] Attempting to send via Socket.IO to user ${userId}`);
      const sent = socketService.sendToUser(userId, {
        title: notification.title,
        body: notification.body,
        data: notification.data || {},
        timestamp: new Date().toISOString()
      });
      
      if (sent) {
        console.log(`[Notification] ✅ Successfully sent via Socket.IO to user ${userId}`);
        return true;
      } else {
        console.log(`[Notification] ⚠️ User ${userId} not online or Socket.IO connection not available`);
      }
    } else {
      console.log(`[Notification] ⚠️ Socket notification service not available`);
    }

    // Fallback: Try Firebase if configured (optional)
    if (initializeFirebase()) {
      try {
        const userQuery = await pool.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
        
        if (userQuery.rows.length > 0 && userQuery.rows[0].fcm_token) {
          const fcmToken = userQuery.rows[0].fcm_token;
          const message = {
            notification: {
              title: notification.title,
              body: notification.body
            },
            data: notification.data || {},
            token: fcmToken
          };

          await admin.messaging().send(message);
          console.log(`[Notification] Sent via Firebase FCM to user ${userId}`);
          return true;
        }
      } catch (firebaseError) {
        console.warn(`[Notification] Firebase fallback failed: ${firebaseError.message}`);
      }
    }

    console.warn(`[Notification] User ${userId} is not online and no FCM token available`);
    return false;
  } catch (error) {
    console.error('Error sending push notification:', error);
    return false;
  }
};

// Create notification in database
const createNotification = async (req, res) => {
  try {
    const { user_id, title, body, type, reference_id, data } = req.body;

    if (!user_id || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'user_id, title, and body are required'
      });
    }

    const query = `
      INSERT INTO notifications (user_id, title, body, type, reference_id, data, is_read)
      VALUES ($1, $2, $3, $4, $5, $6, false)
      RETURNING *
    `;

    const result = await pool.query(query, [
      user_id,
      title,
      body,
      type || 'general',
      reference_id,
      JSON.stringify(data || {})
    ]);

    const notification = result.rows[0];

    // Send push notification via Socket.IO
    await sendPushNotification(user_id, {
      title,
      body,
      data: {
        type: type || 'general',
        reference_id: reference_id?.toString() || '',
        notification_id: notification.id.toString()
      }
    }, req);

    res.status(201).json({
      success: true,
      message: 'Notification created successfully',
      data: notification
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create notification',
      error: error.message
    });
  }
};

// Get user notifications
const getUserNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const { is_read, type, page = 1, limit = 20 } = req.query;

    let query = `
      SELECT * FROM notifications 
      WHERE user_id = $1
    `;
    const params = [userId];
    let paramIndex = 2;

    if (is_read !== undefined) {
      query += ` AND is_read = $${paramIndex}`;
      params.push(is_read === 'true');
      paramIndex++;
    }

    if (type) {
      query += ` AND type = $${paramIndex}`;
      params.push(type);
      paramIndex++;
    }

    query += ` ORDER BY created_at DESC`;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), (parseInt(page) - 1) * parseInt(limit));

    const result = await pool.query(query, params);

    // Get total count
    const countQuery = `
      SELECT COUNT(*) FROM notifications WHERE user_id = $1
      ${is_read !== undefined ? ' AND is_read = $2' : ''}
      ${type ? ` AND type = $${is_read !== undefined ? 3 : 2}` : ''}
    `;
    const countParams = [userId];
    if (is_read !== undefined) countParams.push(is_read === 'true');
    if (type) countParams.push(type);

    const countResult = await pool.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.status(200).json({
      success: true,
      data: {
        notifications: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notifications',
      error: error.message
    });
  }
};

// Mark notification as read
const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.id;

    const query = `
      UPDATE notifications 
      SET is_read = true, read_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(query, [notificationId, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification marked as read',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
      error: error.message
    });
  }
};

// Mark all notifications as read
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      UPDATE notifications 
      SET is_read = true, read_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND is_read = false
      RETURNING COUNT(*) as count
    `;

    const result = await pool.query(query, [userId]);

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all as read',
      error: error.message
    });
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.id;

    const query = 'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING *';
    const result = await pool.query(query, [notificationId, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification',
      error: error.message
    });
  }
};

// Get unread count
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const query = 'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false';
    const result = await pool.query(query, [userId]);

    res.status(200).json({
      success: true,
      data: {
        unread_count: parseInt(result.rows[0].count)
      }
    });
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get unread count',
      error: error.message
    });
  }
};

// Helper function to send notification (used by other controllers)
const sendNotificationToUser = async (userId, title, body, type, referenceId, data, req = null) => {
  try {
    const query = `
      INSERT INTO notifications (user_id, title, body, type, reference_id, data, is_read)
      VALUES ($1, $2, $3, $4, $5, $6, false)
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      title,
      body,
      type || 'general',
      referenceId,
      JSON.stringify(data || {})
    ]);

    const notification = result.rows[0];

    // Send push notification via Socket.IO
    await sendPushNotification(userId, {
      title,
      body,
      data: {
        type: type || 'general',
        reference_id: referenceId?.toString() || '',
        notification_id: notification.id.toString(),
        ...data
      }
    }, req);

    return notification;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
};

// Admin: Send broadcast notification (email + push notification)
// Can send to all users, specific role, or single user
const sendBroadcastNotification = async (req, res) => {
  try {
    const schema = Joi.object({
      title: Joi.string().required(),
      content: Joi.string().required(),
      recipient_type: Joi.string().valid('all', 'role', 'user').required(),
      recipient_value: Joi.when('recipient_type', {
        is: 'role',
        then: Joi.string().valid('customer', 'shipper', 'intake_staff', 'admin').required(),
        otherwise: Joi.when('recipient_type', {
          is: 'user',
          then: Joi.number().integer().required(),
          otherwise: Joi.optional()
        })
      }),
      send_email: Joi.boolean().default(true),
      send_push: Joi.boolean().default(true)
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.details[0].message
      });
    }

    const { title, content, recipient_type, recipient_value, send_email, send_push } = value;

    // Get recipient user IDs
    let userIds = [];
    let userEmails = [];

    if (recipient_type === 'all') {
      const result = await pool.query('SELECT id, email FROM users WHERE email IS NOT NULL');
      userIds = result.rows.map(row => row.id);
      userEmails = result.rows.map(row => row.email);
    } else if (recipient_type === 'role') {
      const result = await pool.query(
        'SELECT id, email FROM users WHERE role = $1 AND email IS NOT NULL',
        [recipient_value]
      );
      userIds = result.rows.map(row => row.id);
      userEmails = result.rows.map(row => row.email);
    } else if (recipient_type === 'user') {
      const result = await pool.query(
        'SELECT id, email FROM users WHERE id = $1 AND email IS NOT NULL',
        [recipient_value]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({
          status: 'error',
          message: 'Không tìm thấy người dùng'
        });
      }
      userIds = [result.rows[0].id];
      userEmails = [result.rows[0].email];
    }

    if (userIds.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Không có người dùng nào để gửi thông báo'
      });
    }

    // Limit for demo/testing (as mentioned in Sprint plan)
    const MAX_DEMO_RECIPIENTS = 10;
    if (userIds.length > MAX_DEMO_RECIPIENTS) {
      userIds = userIds.slice(0, MAX_DEMO_RECIPIENTS);
      userEmails = userEmails.slice(0, MAX_DEMO_RECIPIENTS);
      console.warn(`Limiting to ${MAX_DEMO_RECIPIENTS} recipients for demo`);
    }

    const results = {
      notifications_created: 0,
      emails_sent: 0,
      emails_failed: 0,
      push_sent: 0,
      push_failed: 0
    };

    // Create notifications in database and send push notifications
    if (send_push) {
      for (const userId of userIds) {
        try {
          // sendNotificationToUser already handles Socket.IO push notification
          await sendNotificationToUser(userId, title, content, 'system', null, {
            broadcast: true,
            recipient_type,
            recipient_value
          }, req);
          results.notifications_created++;
          results.push_sent++;
        } catch (error) {
          console.error(`Error sending push to user ${userId}:`, error.message);
          results.push_failed++;
        }
      }
    } else {
      // Just create notifications without push
      for (const userId of userIds) {
        try {
          await pool.query(
            `INSERT INTO notifications (user_id, title, body, type, data, is_read)
             VALUES ($1, $2, $3, 'system', $4, false)`,
            [userId, title, content, JSON.stringify({ broadcast: true })]
          );
          results.notifications_created++;
        } catch (error) {
          console.error(`Error creating notification for user ${userId}:`, error.message);
        }
      }
    }

    // Send emails
    if (send_email && userEmails.length > 0) {
      const emailHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">${title}</h2>
          <div style="color: #666; line-height: 1.6;">
            ${content.replace(/\n/g, '<br>')}
          </div>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #999; font-size: 12px;">
            Đây là thông báo từ hệ thống Lalamove Logistics
          </p>
        </div>
      `;

      const emailResults = await sendBulkEmail(
        userEmails,
        title,
        emailHtml,
        content,
        5, // batch size
        1000 // delay between batches (1 second)
      );

      results.emails_sent = emailResults.success;
      results.emails_failed = emailResults.failed;
    }

    res.json({
      status: 'success',
      message: `Đã gửi thông báo đến ${userIds.length} người dùng`,
      data: results
    });
  } catch (error) {
    console.error('Error sending broadcast notification:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi gửi thông báo',
      error: error.message
    });
  }
};

module.exports = {
  saveToken,
  createNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
  sendNotificationToUser,
  sendBroadcastNotification,
  initializeFirebase
};
