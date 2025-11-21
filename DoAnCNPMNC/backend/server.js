const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config({ path: './config.env' });

const authRoutes = require('./routes/auth');
const orderRoutes = require('./routes/orders');
const userRoutes = require('./routes/users');
const trackingRoutes = require('./routes/tracking');
const adminRoutes = require('./routes/admin');
const warehouseRoutes = require('./routes/warehouse');
const shipperRoutes = require('./routes/shippers');
const notificationRoutes = require('./routes/notifications');
const complaintRoutes = require('./routes/complaints');
const ordersManagementRoutes = require('./routes/ordersManagement');
const driverAssignmentRoutes = require('./routes/driverAssignment');
const routeManagementRoutes = require('./routes/routeManagement');
const pricingPolicyRoutes = require('./routes/pricingPolicy');
const reportingRoutes = require('./routes/reporting');
const areaRoutes = require('./routes/areas');
const { connectDB } = require('./config/database');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all origins for development
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    credentials: true
  },
  // Connection stability settings - optimized for multiple clients and development
  pingTimeout: 180000, // 180 seconds (3 minutes) - wait longer for pong response
  pingInterval: 20000, // 20 seconds - ping frequency (more frequent to prevent timeout)
  upgradeTimeout: 120000, // 120 seconds - longer timeout for transport upgrade
  maxHttpBufferSize: 10 * 1e6, // 10MB - max message size (increased for development)
  allowEIO3: true, // Support older Engine.IO clients
  // Transport options - use polling only for better stability with multiple clients
  transports: ['polling'], // Use polling only - more stable for multiple clients
  // Connection pooling
  perMessageDeflate: false, // Disable compression to reduce overhead
  // Keep connection alive
  serveClient: false, // Don't serve Socket.IO client files
  // Error handling - disable auto-upgrade to prevent websocket issues
  allowUpgrades: false, // Disable auto-upgrade to websocket (keep polling stable)
  // Reconnection settings (applied server-side)
  cookie: false, // Don't use cookies for sticky sessions
  // Connection management - optimized for development
  connectTimeout: 90000, // 90 seconds connection timeout (longer for development)
  // Handle multiple connections from same origin
  httpCompression: false, // Disable HTTP compression for better compatibility
  // Allow multiple connections from same origin (for testing multiple clients)
  allowRequest: (req, callback) => {
    // Allow all connections in development
    callback(null, true);
  },
});

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS configuration (always allow during development)
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, curl, etc.)
    if (!origin) return callback(null, true);

    // Auto allow localhost / 127.0.0.1
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }

    // In production, check whitelist from env (optional)
    const whitelistRaw = process.env.CORS_ORIGIN;
    if (whitelistRaw) {
      const whitelist = whitelistRaw.split(',').map(item => item.trim()).filter(Boolean);
      if (whitelist.includes(origin)) {
        return callback(null, true);
      }
      console.error(`Blocked by CORS policy: ${origin}`);
      return callback(new Error('Not allowed by CORS'));
    }

    // Fallback: allow all
    callback(null, true);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));

// Rate limiting configuration
const isDevelopment = process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;

// Rate limiting for admin routes - very lenient in development
const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: isDevelopment ? 10000 : 1000, // Very high limit in development for testing
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      status: 'error',
      message: 'Too many requests. Please wait a moment and try again.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  },
  // Skip rate limiting completely in development if DISABLE_RATE_LIMIT is set
  skip: (req) => {
    return isDevelopment && process.env.DISABLE_RATE_LIMIT === 'true';
  }
});

// Rate limiting - stricter for general API (exclude admin routes)
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: isDevelopment ? 5000 : parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // Higher limit in development
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for admin routes (they have their own limiter)
    if (req.path.startsWith('/api/admin')) return true;
    // Skip completely in development if DISABLE_RATE_LIMIT is set
    if (isDevelopment && process.env.DISABLE_RATE_LIMIT === 'true') return true;
    return false;
  },
  handler: (req, res) => {
    res.status(429).json({
      status: 'error',
      message: 'Too many requests from this IP, please try again later.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  }
});

// Apply rate limiting - admin first, then general API (disabled in development if DISABLE_RATE_LIMIT=true)
if (!(isDevelopment && process.env.DISABLE_RATE_LIMIT === 'true')) {
  app.use('/api/admin', adminLimiter); // Admin routes get higher limit (applied first)
  app.use('/api/', limiter); // General API rate limit (excludes admin routes)
} else {
  console.log('⚠️  Rate limiting DISABLED in development mode');
}

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', authenticateToken, orderRoutes);
app.use('/api/users', authenticateToken, userRoutes);
app.use('/api/tracking', authenticateToken, trackingRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/warehouse', warehouseRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/shippers', shipperRoutes);
// Story #20-24 routes
app.use('/api/orders-management', authenticateToken, ordersManagementRoutes);
app.use('/api/driver-assignment', authenticateToken, driverAssignmentRoutes);
app.use('/api/routes', authenticateToken, routeManagementRoutes);
app.use('/api/pricing', authenticateToken, pricingPolicyRoutes);
app.use('/api/reports', authenticateToken, reportingRoutes);
app.use('/api/admin/areas', areaRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Food Delivery API is running',
    timestamp: new Date().toISOString()
  });
});

// Socket.IO for real-time tracking
// Track active connections to prevent memory leaks
const activeConnections = new Map();

io.on('connection', (socket) => {
  console.log(`[Socket.IO] User connected: ${socket.id}, transport: ${socket.conn.transport.name}`);
  
  // Store connection info
  const connectionInfo = {
    id: socket.id,
    connectedAt: Date.now(),
    lastPong: Date.now(),
    transport: socket.conn.transport.name,
    rooms: new Set()
  };
  activeConnections.set(socket.id, connectionInfo);

  // Monitor transport changes with error handling (disabled since upgrades are off)
  socket.conn.on('upgrade', () => {
    const transport = socket.conn.transport.name;
    console.log(`[Socket.IO] ${socket.id} upgraded to ${transport}`);
    connectionInfo.transport = transport;
    // Reset lastPong after upgrade to avoid false warnings
    connectionInfo.lastPong = Date.now();
  });

  // Handle transport errors - improve error handling for polling
  socket.conn.on('error', (error) => {
    const errorMsg = error.message || error.toString();
    console.error(`[Socket.IO] Transport error for ${socket.id} (${connectionInfo.transport}):`, errorMsg);
    
    // Handle specific polling errors
    if (errorMsg.includes('poll connection closed prematurely')) {
      console.warn(`[Socket.IO] Poll connection closed prematurely for ${socket.id} - this may be due to timeout`);
      // Client should automatically reconnect
    }
  });

  // Handle transport upgrade errors (disabled but kept for compatibility)
  socket.conn.on('upgradeError', (error) => {
    console.warn(`[Socket.IO] Upgrade error for ${socket.id}:`, error.message || error);
    // Connection will stay on polling if upgrade fails (upgrades are disabled anyway)
  });

  // Send ping to keep connection alive - optimized for multiple clients
  const pingInterval = setInterval(() => {
    if (socket.connected) {
      try {
        socket.emit('ping', { timestamp: Date.now() });
        // Check if client is still responding (if last pong was too old)
        const timeSinceLastPong = Date.now() - connectionInfo.lastPong;
        if (timeSinceLastPong > 240000) { // 4 minutes without pong (very lenient for development)
          console.warn(`[Socket.IO] ${socket.id} (${connectionInfo.transport}) hasn't responded to ping for ${Math.floor(timeSinceLastPong / 1000)}s`);
        }
      } catch (error) {
        // If socket is not connected anymore, don't log error
        if (socket.connected) {
          console.error(`[Socket.IO] Error sending ping to ${socket.id}:`, error);
        }
        clearInterval(pingInterval);
      }
    } else {
      clearInterval(pingInterval);
    }
  }, 20000); // Send ping every 20 seconds (more frequent to prevent timeout)

  socket.on('pong', (data) => {
    // Client responded to ping
    connectionInfo.lastPong = Date.now();
  });

  socket.on('join-order', (orderId) => {
    socket.join(`order-${orderId}`);
    connectionInfo.rooms.add(`order-${orderId}`);
    console.log(`[Socket.IO] ${socket.id} joined order ${orderId}`);
  });

  socket.on('leave-order', (orderId) => {
    socket.leave(`order-${orderId}`);
    connectionInfo.rooms.delete(`order-${orderId}`);
    console.log(`[Socket.IO] ${socket.id} left order ${orderId}`);
  });

  socket.on('disconnect', (reason) => {
    clearInterval(pingInterval);
    activeConnections.delete(socket.id);
    
    const uptime = Math.floor((Date.now() - connectionInfo.connectedAt) / 1000);
    console.log(`[Socket.IO] User disconnected: ${socket.id}, reason: ${reason}, transport: ${connectionInfo.transport}, uptime: ${uptime}s`);
    
    // Log reason for debugging with more context
    if (reason === 'transport close') {
      console.log(`[Socket.IO] Transport closed for ${socket.id} (${connectionInfo.transport}) - connection was idle or network issue`);
      // This is normal for idle connections, client should reconnect automatically
    } else if (reason === 'ping timeout') {
      console.log(`[Socket.IO] Ping timeout for ${socket.id} (${connectionInfo.transport}) - client didn't respond to ping`);
    } else if (reason === 'transport error') {
      console.log(`[Socket.IO] Transport error for ${socket.id} (${connectionInfo.transport}) - connection error occurred`);
      // Client should automatically reconnect with fallback transport
    } else if (reason === 'client namespace disconnect') {
      console.log(`[Socket.IO] Client disconnected ${socket.id} - intentional disconnect`);
    } else {
      console.log(`[Socket.IO] Disconnect reason for ${socket.id}: ${reason}`);
    }
  });

  // Handle connection errors with better logging
  socket.on('error', (error) => {
    console.error(`[Socket.IO] Socket error for ${socket.id} (${connectionInfo.transport}):`, error.message || error);
  });

  // Handle connection state changes with more detail
  socket.conn.on('close', (reason, description) => {
    console.log(`[Socket.IO] Connection closed for ${socket.id} (${connectionInfo.transport}): ${reason}${description ? ` - ${description}` : ''}`);
  });

  // Monitor packet loss or connection quality
  socket.conn.on('drain', () => {
    // Buffer drained - connection is healthy
    connectionInfo.lastPong = Date.now(); // Update as healthy signal
  });
});

// Periodic cleanup and stats logging
setInterval(() => {
  const stats = {
    total: activeConnections.size,
    byTransport: {}
  };
  
  activeConnections.forEach((info) => {
    stats.byTransport[info.transport] = (stats.byTransport[info.transport] || 0) + 1;
  });
  
  if (stats.total > 0) {
    console.log(`[Socket.IO] Active connections: ${JSON.stringify(stats)}`);
  }
}, 60000); // Log stats every minute

// Make io available to routes
app.set('io', io);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    status: 'error',
    message: 'Something went wrong!',
    ...(process.env.NODE_ENV === 'development' && { error: err.message })
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 3000;

// Connect to database and start server
const startServer = async () => {
  try {
    await connectDB();
    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = { app, io };
