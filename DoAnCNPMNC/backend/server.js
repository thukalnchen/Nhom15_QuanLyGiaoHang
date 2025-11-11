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
const { connectDB } = require('./config/database');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all origins for development
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
  }
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

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

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

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Food Delivery API is running',
    timestamp: new Date().toISOString()
  });
});

// Socket.IO for real-time tracking
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join-order', (orderId) => {
    socket.join(`order-${orderId}`);
    console.log(`User ${socket.id} joined order ${orderId}`);
  });

  socket.on('leave-order', (orderId) => {
    socket.leave(`order-${orderId}`);
    console.log(`User ${socket.id} left order ${orderId}`);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

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
