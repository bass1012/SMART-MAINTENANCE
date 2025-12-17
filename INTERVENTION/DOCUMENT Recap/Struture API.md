mct-maintenance-api/
├── src/
│   ├── config/
│   │   ├── database.js          # Configuration MariaDB
│   │   ├── redis.js            # Configuration Redis
│   │   ├── firebase.js         # Configuration Firebase
│   │   ├── payment.js          # Configuration Mobile Money/Stripe
│   │   └── environment.js      # Variables d'environnement
│   │
│   ├── controllers/
│   │   ├── auth/
│   │   │   ├── authController.js
│   │   │   └── middleware.js   # JWT, OAuth2
│   │   ├── admin/
│   │   │   ├── adminController.js
│   │   │   ├── dashboardController.js
│   │   │   └── settingsController.js
│   │   ├── customer/
│   │   │   ├── customerController.js
│   │   │   ├── profileController.js
│   │   │   ├── contractController.js
│   │   │   └── complaintController.js
│   │   ├── technician/
│   │   │   ├── technicianController.js
│   │   │   ├── interventionController.js
│   │   │   └── reportController.js
│   │   ├── product/
│   │   │   ├── productController.js
│   │   │   ├── categoryController.js
│   │   │   └── brandController.js
│   │   ├── order/
│   │   │   ├── orderController.js
│   │   │   ├── quoteController.js
│   │   │   └── paymentController.js
│   │   └── notification/
│   │       ├── notificationController.js
│   │       └── pushController.js
│   │
│   ├── models/
│   │   ├── User.js             # Modèle utilisateur (Admin, Client, Technicien)
│   │   ├── CustomerProfile.js
│   │   ├── TechnicianProfile.js
│   │   ├── Product.js
│   │   ├── Category.js
│   │   ├── Brand.js
│   │   ├── MaintenanceContract.js
│   │   ├── InterventionRequest.js
│   │   ├── TechnicianAssignment.js
│   │   ├── InterventionReport.js
│   │   ├── Order.js
│   │   ├── OrderItem.js
│   │   ├── Quote.js
│   │   ├── QuoteItem.js
│   │   ├── Promotion.js
│   │   ├── Complaint.js
│   │   ├── Notification.js
│   │   └── SystemSetting.js
│   │
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── adminRoutes.js
│   │   ├── customerRoutes.js
│   │   ├── technicianRoutes.js
│   │   ├── productRoutes.js
│   │   ├── orderRoutes.js
│   │   └── notificationRoutes.js
│   │
│   ├── services/
│   │   ├── emailService.js     # Service d'envoi d'emails
│   │   ├── smsService.js       # Service SMS
│   │   ├── paymentService.js   # Service Mobile Money/Stripe
│   │   ├── cacheService.js     # Service Redis
│   │   ├── uploadService.js    # Service upload fichiers
│   │   └── pdfService.js       # Service génération PDF
│   │
│   ├── middleware/
│   │   ├── auth.js             # Middleware authentification
│   │   ├── roleAccess.js       # Middleware contrôle d'accès
│   │   ├── rateLimiter.js      # Middleware rate limiting
│   │   ├── cors.js             # Middleware CORS
│   │   ├── validation.js       # Middleware validation
│   │   └── errorHandler.js     # Middleware gestion erreurs
│   │
│   ├── utils/
│   │   ├── validators.js       # Validateurs personnalisés
│   │   ├── formatters.js       # Formateurs de données
│   │   ├── constants.js        # Constantes de l'application
│   │   └── helpers.js          # Fonctions utilitaires
│   │
│   └── app.js                  # Point d'entrée principal
│
├── tests/
│   ├── unit/                   # Tests unitaires
│   ├── integration/            # Tests d'intégration
│   └── e2e/                    # Tests end-to-end
│
├── docs/
│   ├── api/                    # Documentation API
│   ├── database/               # Documentation base de données
│   └── deployment/             # Documentation déploiement
│
├── scripts/
│   ├── migrate.js              # Scripts migration
│   ├── seed.js                 # Scripts seed
│   └── deploy.js               # Scripts déploiement
│
├── .env.example                # Variables d'environnement exemple
├── package.json
├── Dockerfile
└── docker-compose.yml