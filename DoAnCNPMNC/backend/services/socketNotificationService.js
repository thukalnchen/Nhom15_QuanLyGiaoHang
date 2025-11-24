// Service to send notifications via Socket.IO
// This replaces Firebase Cloud Messaging

class SocketNotificationService {
  constructor(io) {
    this.io = io;
    // Map user_id to socket_id(s) - one user can have multiple devices
    this.userSockets = new Map();
  }

  // Register a socket connection for a user
  registerUserSocket(userId, socketId) {
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId).add(socketId);
    console.log(`[SocketNotification] Registered socket ${socketId} for user ${userId}`);
  }

  // Unregister a socket connection
  unregisterUserSocket(userId, socketId) {
    if (this.userSockets.has(userId)) {
      this.userSockets.get(userId).delete(socketId);
      if (this.userSockets.get(userId).size === 0) {
        this.userSockets.delete(userId);
      }
      console.log(`[SocketNotification] Unregistered socket ${socketId} for user ${userId}`);
    }
  }

  // Unregister socket by socketId (useful on disconnect)
  unregisterSocket(socketId) {
    for (const [userId, sockets] of this.userSockets.entries()) {
      if (sockets.has(socketId)) {
        sockets.delete(socketId);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
        }
        console.log(`[SocketNotification] Unregistered socket ${socketId} for user ${userId}`);
        break;
      }
    }
  }

  // Send notification to a specific user
  sendToUser(userId, notification) {
    // Ensure userId is an integer for consistency
    const userIdInt = typeof userId === 'string' ? parseInt(userId, 10) : userId;
    
    if (isNaN(userIdInt)) {
      console.error(`[SocketNotification] Invalid user ID: ${userId}`);
      return false;
    }
    
    const sockets = this.userSockets.get(userIdInt);
    
    if (!sockets || sockets.size === 0) {
      console.warn(`[SocketNotification] No active socket connections for user ${userIdInt}`);
      console.log(`[SocketNotification] Currently registered users: ${Array.from(this.userSockets.keys()).join(', ')}`);
      return false;
    }

    let sentCount = 0;
    for (const socketId of sockets) {
      const socket = this.io.sockets.sockets.get(socketId);
      if (socket && socket.connected) {
        socket.emit('notification', notification);
        sentCount++;
        console.log(`[SocketNotification] Emitted notification to socket ${socketId} for user ${userIdInt}`);
      } else {
        // Clean up disconnected socket
        sockets.delete(socketId);
        console.warn(`[SocketNotification] Socket ${socketId} not connected, removing from user ${userIdInt}`);
      }
    }

    if (sockets.size === 0) {
      this.userSockets.delete(userIdInt);
    }

    console.log(`[SocketNotification] Sent notification to user ${userIdInt} via ${sentCount} socket(s)`);
    return sentCount > 0;
  }

  // Send notification to multiple users
  sendToUsers(userIds, notification) {
    let successCount = 0;
    for (const userId of userIds) {
      if (this.sendToUser(userId, notification)) {
        successCount++;
      }
    }
    return successCount;
  }

  // Check if user is online
  isUserOnline(userId) {
    const sockets = this.userSockets.get(userId);
    return sockets && sockets.size > 0;
  }
}

module.exports = SocketNotificationService;

