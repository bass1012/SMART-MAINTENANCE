const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');
const { testConnection, syncDatabase } = require('./config/database');
const notificationService = require('./services/notificationService');
const fcmService = require('./services/fcmService');

const { securityMiddleware, authLimiter } = require('./middleware/security');
const { errorHandler, notFound, errorLogger, rateLimitErrorHandler } = require('./middleware/errorHandler');
const { asyncHandler } = require('./middleware/errorHandler');

const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const customerRoutes = require('./routes/customerRoutes');
const technicianRoutes = require('./routes/technicianRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const interventionRoutes = require('./routes/interventionRoutes');
const contractRoutes = require('./routes/contractRoutes');
const quoteRoutes = require('./routes/quoteRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const userRoutes = require('./routes/userRoutes');
const maintenanceScheduleRoutes = require('./routes/maintenanceScheduleRoutes');
const equipmentRoutes = require('./routes/equipmentRoutes');
const complaintRoutes = require('./routes/complaintRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const brandRoutes = require('./routes/brandRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Configuration CORS pour le développement
const corsOptions = {
  origin: function (origin, callback) {
    // Autoriser toutes les origines en développement
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true);
    }
    
    // En production, restreindre aux origines autorisées
    const allowedOrigins = [
      'http://localhost:3001', 
      'http://localhost:3000', 
      'http://192.168.1.139:3001',
      'http://192.168.1.139:3000'
    ];
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'X-Total-Count', 'Content-Range'],
  exposedHeaders: ['Content-Range', 'X-Total-Count'],
  optionsSuccessStatus: 204,
  preflightContinue: false
};

// Initialiser Socket.IO avec CORS
const io = new Server(server, {
  cors: corsOptions,
  path: '/socket.io/',
  transports: ['websocket', 'polling'],
  allowEIO3: true
});

// Initialiser le service de notifications avec Socket.IO
notificationService.initialize(io);
console.log('✅ Socket.IO initialisé');

// Initialiser le service de chat avec Socket.IO
const ChatService = require('./services/chatService');
const chatService = new ChatService(io);
console.log('💬 Service de chat initialisé');

// Rendre Socket.IO accessible dans les routes
app.set('io', io);

// Middleware de base
app.options('*', cors(corsOptions)); // Pré-vol des requêtes OPTIONS
app.use(cors(corsOptions));
app.use(compression());
app.use(morgan('dev'));

// Parsing JSON AVANT le logging pour voir les données
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Middleware de logging désactivé pour éviter la pollution des logs
// Décommentez pour déboguer en cas de besoin
// app.use((req, res, next) => {
//   console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
//   console.log('Headers:', req.headers);
//   console.log('Query:', req.query);
//   console.log('Body:', req.body);
//   next();
// });

// Health check endpoints
app.get(['/health', '/api/health'], (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'MCT Maintenance API',
    version: '1.0.0',
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    nodeVersion: process.version,
    platform: process.platform,
    env: process.env.NODE_ENV || 'development'
  });
});

// Middleware de sécurité (après les endpoints de santé)
securityMiddleware(app);

// Servir les fichiers uploadés (images des interventions)
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('📁 Dossier uploads créé');
}
app.use('/uploads', express.static(uploadsDir));
console.log('📁 Dossier uploads disponible sur /uploads');

// API routes
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/admin', adminRoutes);
// Utilisation du singulier 'customer' pour correspondre au frontend
app.use('/api/customer', customerRoutes);
app.use('/api/customers', customerRoutes);
// Utilisation du singulier 'technician' pour correspondre au frontend
app.use('/api/technician', technicianRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/interventions', interventionRoutes);
app.use('/api/contracts', contractRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/users', userRoutes);
app.use('/api/maintenance-schedules', maintenanceScheduleRoutes);
app.use('/api/maintenance-offers', require('./routes/maintenanceOfferRoutes'));
app.use('/api/subscriptions', require('./routes/subscriptionRoutes'));
app.use('/api/test', require('./routes/testNotificationRoutes'));
app.use('/api/equipments', equipmentRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/brands', brandRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/chat', require('./routes/chatRoutes'));

// Servir les fichiers statiques uploadés
app.use('/uploads', express.static('uploads'));

console.log('✅ Routes mounted: /api/users available');

// Error handling middleware
app.use(rateLimitErrorHandler);
app.use(errorLogger);
app.use(notFound);
app.use(errorHandler);

// Initialize database and start server
const startServer = async () => {
  try {
    // Test database connection
    await testConnection();
    
    // Sync database models
    await syncDatabase();
    
    // Initialize Firebase Cloud Messaging
    try {
      fcmService.initialize();
      console.log('🔥 Firebase Cloud Messaging initialisé');
    } catch (error) {
      console.error('⚠️  Firebase Cloud Messaging non disponible:', error.message);
      console.log('ℹ️  Les notifications push mobiles ne fonctionneront pas');
    }
    
    // Start server (utiliser server au lieu de app pour Socket.IO)
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 MCT Maintenance API server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`🔌 Socket.IO ready for real-time notifications`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

module.exports = app;
