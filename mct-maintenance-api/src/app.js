const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const dotenv = require('dotenv');
dotenv.config(); // Charger les variables d'environnement depuis .env
const path = require('path');
const fs = require('fs');
const { testConnection, syncDatabase } = require('./config/database');
const { setupSwagger } = require('./config/swagger');
const notificationService = require('./services/notificationService');
const fcmService = require('./services/fcmService');
const cronService = require('./services/cronService');
const { registerPaymentOutboxHandlers } = require('./services/outboxHandlers/paymentHandlers');
const { createOutboxWorker } = require('./jobs/outboxWorker');
const outboxWorker = createOutboxWorker();

const { securityMiddleware, authLimiter, corsOptions } = require('./middleware/security');
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
const notificationPreferenceRoutes = require('./routes/notificationPreferenceRoutes');
const userRoutes = require('./routes/userRoutes');
const maintenanceScheduleRoutes = require('./routes/maintenanceScheduleRoutes');
const equipmentRoutes = require('./routes/equipmentRoutes');
const complaintRoutes = require('./routes/complaintRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const brandRoutes = require('./routes/brandRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const activityRoutes = require('./routes/activityRoutes');
const smsWebhookRoutes = require('./routes/smsWebhookRoutes');

const app = express(); // nosemgrep: express-check-csurf-middleware-usage - API REST JWT, pas de sessions/cookies de formulaire, CSRF non applicable

// Faire confiance au proxy (ngrok, nginx, etc.) pour rate limiting
app.set('trust proxy', 1);

const server = http.createServer(app); // nosemgrep: using-http-server - requis pour Socket.IO; en production, nginx gère le TLS
const PORT = process.env.PORT || 3000;

// Initialiser Socket.IO avec CORS
const io = new Server(server, {
  cors: corsOptions,
  path: '/socket.io/',
  transports: ['websocket', 'polling'],
  allowEIO3: true
});

// Connecter Socket.IO à Redis pour le mode cluster PM2
const { createAdapter } = require('@socket.io/redis-adapter');
const { createClient } = require('redis');

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const pubClient = createClient({ url: redisUrl });
const subClient = pubClient.duplicate();

Promise.all([pubClient.connect(), subClient.connect()])
  .then(() => {
    io.adapter(createAdapter(pubClient, subClient));
    console.log('✅ Socket.IO Redis adapter connecté');
  })
  .catch(err => {
    console.error('❌ CRITIQUE: Redis adapter non disponible — les notifications temps réel ne fonctionneront PAS entre les workers PM2:', err.message);
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

// Rendre Socket.IO accessible via socketService (pour les routes REST)
const socketService = require('./services/socketService');
socketService.setIO(io);

// Middleware de base
app.use(cors(corsOptions)); // Appliquer CORS globalement en premier
app.options('*', cors(corsOptions)); // Gérer explicitement les requêtes OPTIONS
app.use(compression());
app.use(morgan('dev'));

// Parsing JSON AVANT le logging pour voir les données
app.use(express.json({
  limit: '50mb',
  verify: (req, res, buffer) => {
    if (req.originalUrl?.includes('/fineopay/callback')) {
      req.rawBody = Buffer.from(buffer);
    }
  }
}));
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

const { correlationMiddleware } = require('./middleware/correlationMiddleware');
const { sequelize } = require('./models');

// Middleware correlation ID
app.use(correlationMiddleware);

// Liveness check (léger, sans fuite d'informations système)
app.get(['/live', '/api/live', '/health', '/api/health'], (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'MCT Maintenance API',
    version: '2.0.8',
    env: process.env.NODE_ENV || 'development'
  });
});

// Readiness check (vérification de la connectivité base de données)
app.get(['/ready', '/api/ready'], async (req, res) => {
  try {
    await sequelize.authenticate();
    res.status(200).json({
      status: 'READY',
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'NOT_READY',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});

// Configuration Swagger (avant les routes API)
setupSwagger(app);

// Middleware de sécurité (après les endpoints de santé)
securityMiddleware(app);

// Servir les fichiers uploadés (images des interventions, avatars, etc.) avec options de sécurité
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('📁 Dossier uploads créé');
}
app.use('/uploads', express.static(uploadsDir, {
  dotfiles: 'ignore',
  index: false,
  maxAge: '1d'
}));
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
app.use('/api/refunds', require('./routes/refundRoutes'));
app.use('/api/notifications', notificationRoutes);
app.use('/api/notification-preferences', notificationPreferenceRoutes);
app.use('/api/users', userRoutes);
app.use('/api/maintenance-schedules', maintenanceScheduleRoutes);
app.use('/api/maintenance-offers', require('./routes/maintenanceOfferRoutes'));
app.use('/api/subscriptions', require('./routes/subscriptionRoutes'));
app.use('/api/admin/subscriptions', require('./routes/subscriptionRoutes')); // Alias pour le dashboard
app.use('/api/installation-services', require('./routes/installationServiceRoutes'));
app.use('/api/repair-services', require('./routes/repairServiceRoutes'));
app.use('/api/diagnostic-reports', require('./routes/diagnosticRoutes'));
// Route de test FCM — disponible uniquement en environnement de développement
if (process.env.NODE_ENV !== 'production') {
  app.use('/api/test', require('./routes/testNotificationRoutes'));
}
app.use('/api/equipments', equipmentRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/brands', brandRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/fineopay', require('./routes/fineoPayRoutes'));
app.use('/api/chat', require('./routes/chatRoutes'));
app.use('/api/maintenance', require('./routes/maintenanceRoutes'));
app.use('/api/activities', activityRoutes);
app.use('/api/sms', smsWebhookRoutes); // Webhooks HSMS.ci
app.use('/api/splits', require('./routes/splitRoutes')); // Gestion des splits (QR code)
app.use('/api/config', require('./routes/configRoutes')); // Configuration serveur administrable (tarifs, garanties, contacts, contrats)

console.log('✅ Routes mounted: /api/users, /api/config available');

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

    // Migration automatique des colonnes 50% solde sur interventions
    try {
      const { sequelize } = require('./config/database');
      const { DataTypes } = require('sequelize');
      const queryInterface = sequelize.getQueryInterface();
      const tableDesc = await queryInterface.describeTable('interventions');

      if (!tableDesc.payment_option) {
        await queryInterface.addColumn('interventions', 'payment_option', { type: DataTypes.STRING, allowNull: true, defaultValue: 'full' });
      }
      if (!tableDesc.total_price) {
        await queryInterface.addColumn('interventions', 'total_price', { type: DataTypes.DECIMAL(10, 2), allowNull: true, defaultValue: 0 });
      }
      if (!tableDesc.second_payment_amount) {
        await queryInterface.addColumn('interventions', 'second_payment_amount', { type: DataTypes.DECIMAL(10, 2), allowNull: true, defaultValue: 0 });
      }
      if (!tableDesc.second_payment_status) {
        await queryInterface.addColumn('interventions', 'second_payment_status', { type: DataTypes.STRING, allowNull: true, defaultValue: 'none' });
      }
      console.log('✅ Auto-migration colonnes 50% solde interventions effectuée');
    } catch (migErr) {
      console.log('ℹ️ Remarque migration colonnes interventions:', migErr.message);
    }

    // Migration automatique des colonnes diagnostic_reports
    try {
      const { sequelize } = require('./config/database');
      const { DataTypes } = require('sequelize');
      const queryInterface = sequelize.getQueryInterface();
      const diagTableDesc = await queryInterface.describeTable('diagnostic_reports');
      if (!diagTableDesc.equipments) {
        await queryInterface.addColumn('diagnostic_reports', 'equipments', { type: DataTypes.TEXT, allowNull: true });
      }
      if (!diagTableDesc.materials_needed) {
        await queryInterface.addColumn('diagnostic_reports', 'materials_needed', { type: DataTypes.TEXT, allowNull: true });
      }
      console.log('✅ Auto-migration colonnes diagnostic_reports effectuée');
    } catch (diagMigErr) {
      console.log('ℹ️ Remarque migration colonnes diagnostic_reports:', diagMigErr.message);
    }
    
    // Auto-correction des souscriptions et interventions à 0 FCFA en attente
    try {
      const { Subscription, Intervention } = require('./models');
      const [updatedSubCount] = await Subscription.update(
        { payment_status: 'paid', first_payment_status: 'paid', second_payment_status: 'paid', status: 'active' },
        { where: { price: 0, payment_status: 'pending' } }
      );
      if (updatedSubCount > 0) {
        console.log(`✅ ${updatedSubCount} souscription(s) à 0 FCFA mise(s) à jour en "paid"`);
      }

      const [updatedIntervCount] = await Intervention.update(
        { diagnostic_paid: true, is_free_diagnosis: true },
        { where: { diagnostic_fee: 0, diagnostic_paid: false } }
      );
      if (updatedIntervCount > 0) {
        console.log(`✅ ${updatedIntervCount} intervention(s) à 0 FCFA mise(s) à jour en "paid"`);
      }

      // 🔧 Auto-correction: Si une intervention en mode 'split' n'est pas encore terminée/confirmée, son 2ème paiement (solde 50%) doit rester 'pending'
      const { Op } = require('sequelize');
      const [resetSecondCount] = await Intervention.update(
        { second_payment_status: 'pending' },
        { 
          where: { 
            payment_option: 'split',
            second_payment_status: 'paid',
            status: { [Op.ne]: 'completed' },
            customer_confirmed: { [Op.ne]: true }
          } 
        }
      );
      if (resetSecondCount > 0) {
        console.log(`🔧 ${resetSecondCount} intervention(s) split non-terminée(s) réinitialisée(s) -> second_payment_status: "pending"`);
      }
    } catch (err) {
      console.error('⚠️  Erreur auto-update 0 FCFA:', err.message);
    }
    
    // Initialize Firebase Cloud Messaging
    try {
      fcmService.initialize();
      console.log('🔥 Firebase Cloud Messaging initialisé');
    } catch (error) {
      console.error('⚠️  Firebase Cloud Messaging non disponible:', error.message);
      console.log('ℹ️  Les notifications push mobiles ne fonctionneront pas');
    }
    
    // Initialize CRON jobs (uniquement sur le worker 0 en mode cluster pour éviter les doublons)
    if (!process.env.NODE_APP_INSTANCE || process.env.NODE_APP_INSTANCE === '0') {
      cronService.initializeJobs();
      registerPaymentOutboxHandlers();
      outboxWorker.start();
    } else {
      console.log(`⏰ [Cron/Outbox] Worker ${process.env.NODE_APP_INSTANCE} - tâches différées désactivées (gérées par worker 0)`);
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
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  cronService.stopAllJobs();
  await outboxWorker.stop();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  cronService.stopAllJobs();
  await outboxWorker.stop();
  process.exit(0);
});

module.exports = app;
