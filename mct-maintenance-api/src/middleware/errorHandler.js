const createError = require('http-errors');

// Middleware de gestion des erreurs centralisé
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log l'erreur pour le débogage
  console.error(err);

  // Erreurs de base de données
  if (err.name === 'SequelizeValidationError') {
    const message = err.errors.map(error => error.message).join(', ');
    error = createError(400, message);
  }

  if (err.name === 'SequelizeUniqueConstraintError') {
    const message = 'Une entrée avec ces valeurs existe déjà';
    error = createError(400, message);
  }

  if (err.name === 'SequelizeForeignKeyConstraintError') {
    const message = 'Référence invalide ou contrainte de clé étrangère violée';
    error = createError(400, message);
  }

  if (err.name === 'SequelizeDatabaseError') {
    const message = 'Erreur de base de données';
    error = createError(500, message);
  }

  // Erreurs JWT
  if (err.name === 'JsonWebTokenError') {
    const message = 'Token invalide';
    error = createError(401, message);
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expiré';
    error = createError(401, message);
  }

  // Erreurs de validation
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = createError(400, message);
  }

  // Erreurs de cast Mongoose (si utilisé)
  if (err.name === 'CastError') {
    const message = 'Ressource non trouvée';
    error = createError(404, message);
  }

  // Erreurs de duplication de clé
  if (err.code === 11000) {
    const message = 'Champ dupliqué';
    error = createError(400, message);
  }

  // Erreurs de réseau
  if (err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND') {
    const message = 'Erreur de connexion au service externe';
    error = createError(503, message);
  }

  // Erreurs de timeout
  if (err.code === 'ETIMEDOUT') {
    const message = 'Délai d\'attente dépassé';
    error = createError(504, message);
  }

  res.status(error.statusCode || 500).json({
    success: false,
    error: error.message || 'Erreur interne du serveur',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    timestamp: new Date().toISOString(),
    path: req.path,
    method: req.method
  });
};

// Middleware pour les routes non trouvées
const notFound = (req, res, next) => {
  // Ignorer les requêtes webpack hot-reload du dashboard React
  if (req.originalUrl.includes('.hot-update.json') || 
      req.originalUrl.includes('.hot-update.js') ||
      req.originalUrl.includes('sockjs-node')) {
    return res.status(404).end();
  }
  
  const error = createError(404, `Route non trouvée - ${req.originalUrl}`);
  next(error);
};

// Middleware pour capturer les erreurs asynchrones
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Classe d'erreur personnalisée
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Middleware pour logger les erreurs
const errorLogger = (err, req, res, next) => {
  const errorData = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user ? req.user.id : 'anonymous',
    error: {
      message: err.message,
      stack: err.stack,
      name: err.name
    }
  };

  // En production, envoyer à un service de logging
  if (process.env.NODE_ENV === 'production') {
    // Ici vous pourriez intégrer Sentry, LogRocket, etc.
    console.error('Production Error:', JSON.stringify(errorData, null, 2));
  } else {
    console.error('Development Error:', errorData);
  }

  next(err);
};

// Middleware pour gérer les erreurs de validation des fichiers
const fileUploadErrorHandler = (err, req, res, next) => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      success: false,
      error: 'Taille du fichier trop importante'
    });
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      success: false,
      error: 'Type de fichier non attendu'
    });
  }

  if (err.code === 'LIMIT_FILE_COUNT') {
    return res.status(400).json({
      success: false,
      error: 'Trop de fichiers uploadés'
    });
  }

  next(err);
};

// Middleware pour gérer les erreurs de rate limiting
const rateLimitErrorHandler = (err, req, res, next) => {
  if (err.status === 429) {
    return res.status(429).json({
      success: false,
      error: 'Trop de requêtes, veuillez réessayer plus tard',
      retryAfter: err.headers['Retry-After'] || '60'
    });
  }

  next(err);
};

module.exports = {
  errorHandler,
  notFound,
  asyncHandler,
  AppError,
  errorLogger,
  fileUploadErrorHandler,
  rateLimitErrorHandler
};
