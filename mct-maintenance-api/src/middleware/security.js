const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const xss = require('xss-clean');
const hpp = require('hpp');
const mongoSanitize = require('express-mongo-sanitize');

// Configuration du rate limiting
const createRateLimiter = (windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
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
  15 * 60 * 1000, // 15 minutes
  process.env.NODE_ENV === 'development' ? 1000 : 100, // limite chaque IP (1000 en dev, 100 en prod)
  'Trop de requêtes depuis cette IP, veuillez réessayer après 15 minutes'
);

// Rate limiting pour l'authentification
const authLimiter = createRateLimiter(
  15 * 60 * 1000, // 15 minutes
  process.env.NODE_ENV === 'development' ? 1000 : 100, // limite en dev : 1000, prod : 100
  'Trop de tentatives de connexion, veuillez réessayer après 15 minutes'
);

// Rate limiting pour les routes sensibles
const sensitiveLimiter = createRateLimiter(
  60 * 60 * 1000, // 1 heure
  3, // limite chaque IP à 3 requêtes par heure
  'Trop de requêtes sur cette route sensible, veuillez réessayer plus tard'
);

// Configuration CORS
const corsOptions = {
  origin: function (origin, callback) {
    // En développement, autoriser toutes les origines
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true);
    }
    
    // Liste des origines autorisées en production
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://localhost:8080',
      'https://mct-maintenance.com',
      'https://admin.mct-maintenance.com',
      'https://mobile.mct-maintenance.com'
    ];
    
    // Autoriser les requêtes sans origin (mobile apps, Postman)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    } else {
      return callback(new Error('Not allowed by CORS'));
    }
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
    'X-CSRF-Token',
    'X-API-Key'
  ]
};

// Configuration Helmet avec options personnalisées
const helmetConfig = {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://api.mct-maintenance.com"],
      fontSrc: ["'self'", "https:", "data:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
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
