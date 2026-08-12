const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const xss = require('xss-clean');
const hpp = require('hpp');
const mongoSanitize = require('express-mongo-sanitize');
const { createRedisRateLimitStore } = require('../config/redis');

// Configuration du rate limiting
const createRateLimiter = (prefix, windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
    validate: false,
    ...(process.env.REDIS_URL ? {
      store: createRedisRateLimitStore({ prefix, windowMs })
    } : {}),
    message: {
      success: false,
      error: message || 'Trop de requêtes, veuillez réessayer plus tard'
    },
    standardHeaders: true,
    legacyHeaders: false
  });
};

// Rate limiting général
const generalLimiter = createRateLimiter(
  'general',
  15 * 60 * 1000, // 15 minutes
  process.env.NODE_ENV === 'development' ? 1000 : 500, // limite chaque IP (1000 en dev, 500 en prod)
  'Trop de requêtes depuis cette IP, veuillez réessayer après 15 minutes'
);

// Rate limiting pour l'authentification
const authLimiter = createRateLimiter(
  'auth',
  15 * 60 * 1000, // 15 minutes
  process.env.NODE_ENV === 'development' ? 1000 : 200, // limite en dev : 1000, prod : 200
  'Trop de tentatives de connexion, veuillez réessayer après 15 minutes'
);

// Rate limiting pour les routes sensibles
const sensitiveLimiter = createRateLimiter(
  'sensitive',
  60 * 60 * 1000, // 1 heure
  3, // limite chaque IP à 3 requêtes par heure
  'Trop de requêtes sur cette route sensible, veuillez réessayer plus tard'
);

// Liste blanche explicite des origines CORS autorisées
// Ne JAMAIS utiliser un miroir réfléchissant (origin || true) avec credentials:true
// car tout site malveillant pourrait effectuer des requêtes authentifiées.
const CORS_ALLOWED_ORIGINS = [
  // Production
  'https://dashboard.mct.ci',
  'https://app.mct.ci',
  // Sandbox / Staging
  'https://dashboard.sandbox.mct.ci',
  'https://sandbox.mct.ci',
  // Développement local
  'http://localhost:3001',
  'http://localhost:3000',
  'http://127.0.0.1:3001',
  'http://127.0.0.1:3000',
];

// Configuration CORS sécurisée avec liste blanche
const corsOptions = {
  origin: function (origin, callback) {
    // Autoriser les requêtes sans origine (mobile natif, Postman, curl, etc.)
    if (!origin) {
      return callback(null, true);
    }
    if (CORS_ALLOWED_ORIGINS.includes(origin)) {
      return callback(null, true);
    }
    // Bloquer toute origine non reconnue
    return callback(new Error(`CORS : origine non autorisée — ${origin}`));
  },
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Content-Type',
    'Accept',
    'Authorization',
    'authorization',
    'X-CSRF-Token',
    'X-API-Key',
    'Cache-Control',
    'Pragma'
  ],
  exposedHeaders: [
    'Content-Length',
    'Content-Range',
    'X-Content-Range',
    'Authorization',
    'authorization'
  ]
};

// Configuration Helmet (désactivation de ContentSecurityPolicy car il s'agit d'une API REST/WebSocket consommée par des frontends distants)
const helmetConfig = {
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginOpenerPolicy: { policy: "same-origin-allow-popups" },
  crossOriginResourcePolicy: { policy: "cross-origin" },
  dnsPrefetchControl: { allow: false },
  frameguard: { action: "deny" },
  hidePoweredBy: true,
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  ieNoOpen: true,
  noSniff: true,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" },
  xssFilter: true
};

// Middleware de sécurité principal
const securityMiddleware = (app) => {
  // 1. Protection Helmet
  app.use(helmet(helmetConfig));
  
  // 2. Configuration CORS
  app.use(cors(corsOptions));
  
  // 3. Protection contre les attaques XSS
  app.use(xss());
  
  // 4. Protection contre la pollution des paramètres HTTP
  app.use(hpp());
  
  // 5. Protection contre les injections NoSQL
  app.use(mongoSanitize());
  
  // 6. Rate limiting général
  app.use(generalLimiter);
  
  // 7. Headers de sécurité supplémentaires
  app.use((req, res, next) => {
    // Empêcher le clickjacking
    res.setHeader('X-Frame-Options', 'DENY');
    
    // Empêcher le MIME-type sniffing
    res.setHeader('X-Content-Type-Options', 'nosniff');
    
    // Politique de référérence
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    // Permissions Policy
    res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    
    // Enlever les headers sensibles
    res.removeHeader('X-Powered-By');
    
    next();
  });
};

// Middleware pour valider les entrées contre les injections
const validateInput = (req, res, next) => {
  const suspiciousPatterns = [
    /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, // XSS
    /javascript:/gi, // JavaScript in URLs
    /vbscript:/gi, // VBScript
    /onload=/gi, // Event handlers
    /onerror=/gi,
    /onclick=/gi,
    /onfocus=/gi,
    /onblur=/gi,
    /onchange=/gi,
    /onsubmit=/gi,
    /onreset=/gi,
    /onselect=/gi,
    /onunload=/gi,
    /onabort=/gi,
    /onkeydown=/gi,
    /onkeypress=/gi,
    /onkeyup=/gi,
    /onmousedown=/gi,
    /onmouseup=/gi,
    /onmouseover=/gi,
    /onmouseout=/gi,
    /onmousemove=/gi,
    /[\$\{\}]/gi // NoSQL injection
  ];

  const checkValue = (value) => {
    if (typeof value === 'string') {
      for (const pattern of suspiciousPatterns) {
        if (pattern.test(value)) {
          return false;
        }
      }
    } else if (typeof value === 'object' && value !== null) {
      for (const key in value) {
        if (!checkValue(value[key])) {
          return false;
        }
      }
    }
    return true;
  };

  if (!checkValue(req.body) || !checkValue(req.query) || !checkValue(req.params)) {
    return res.status(400).json({
      success: false,
      error: 'Entrée invalide détectée'
    });
  }

  next();
};

// Middleware pour vérifier la taille des requêtes
const checkRequestSize = (req, res, next) => {
  const maxSize = 10 * 1024 * 1024; // 10MB
  
  if (req.get('content-length') > maxSize) {
    return res.status(413).json({
      success: false,
      error: 'Taille de la requête trop importante'
    });
  }
  
  next();
};

module.exports = {
  securityMiddleware,
  generalLimiter,
  authLimiter,
  sensitiveLimiter,
  validateInput,
  checkRequestSize,
  corsOptions
};
