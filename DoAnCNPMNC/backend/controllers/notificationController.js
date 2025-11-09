const { pool } = require('../config/database');
const admin = require('firebase-admin');

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

// Send push notification to a user
const sendPushNotification = async (userId, notification) => {
  try {
    if (!initializeFirebase()) {
      console.warn('Firebase not initialized. Skipping push notification.');
      return false;
    }

    // Get user's FCM token
    const userQuery = await pool.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
    
    if (userQuery.rows.length === 0 || !userQuery.rows[0].fcm_token) {
      console.warn(`No FCM token found for user ${userId}`);
      return false;
    }

    const fcmToken = userQuery.rows[0].fcm_token;

    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: notification.data || {},
      token: fcmToken
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return true;
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

    // Send push notification
    await sendPushNotification(user_id, {
      title,
      body,
      data: {
        type: type || 'general',
        reference_id: reference_id?.toString() || '',
        notification_id: notification.id.toString()
      }
    });

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
const sendNotificationToUser = async (userId, title, body, type, referenceId, data) => {
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

    // Send push notification
    await sendPushNotification(userId, {
      title,
      body,
      data: {
        type: type || 'general',
        reference_id: referenceId?.toString() || '',
        notification_id: notification.id.toString(),
        ...data
      }
    });

    return notification;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
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
  initializeFirebase
};
