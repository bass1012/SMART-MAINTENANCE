const { validationResult, matchedData } = require('express-validator');
const createError = require('http-errors');

// Middleware pour gérer les résultats de validation
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(error => ({
      field: error.path,
      message: error.msg,
      value: error.value
    }));

    return res.status(400).json({
      success: false,
      error: 'Erreur de validation',
      details: formattedErrors
    });
  }
  
  next();
};

// Middleware pour nettoyer les données validées
const sanitizeData = (req, res, next) => {
  // Obtenir uniquement les données qui ont été validées
  const sanitizedData = matchedData(req, { locations: ['body'] });
  
  // Remplacer req.body par les données nettoyées
  if (Object.keys(sanitizedData).length > 0) {
    req.body = sanitizedData;
  }
  
  next();
};

// Validation des emails
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Validation des numéros de téléphone
const validatePhone = (phone) => {
  const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
  return phoneRegex.test(phone.replace(/[\s\-\(\)]/g, ''));
};

// Validation des mots de passe
const validatePassword = (password) => {
  const minLength = 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  
  return {
    isValid: password.length >= minLength && hasUpperCase && hasLowerCase && hasNumbers && hasSpecialChar,
    errors: {
      length: password.length < minLength ? 'Le mot de passe doit contenir au moins 8 caractères' : null,
      uppercase: !hasUpperCase ? 'Le mot de passe doit contenir au moins une majuscule' : null,
      lowercase: !hasLowerCase ? 'Le mot de passe doit contenir au moins une minuscule' : null,
      numbers: !hasNumbers ? 'Le mot de passe doit contenir au moins un chiffre' : null,
      special: !hasSpecialChar ? 'Le mot de passe doit contenir au moins un caractère spécial' : null
    }
  };
};

// Validation des montants monétaires
const validateAmount = (amount) => {
  const amountRegex = /^\d+(\.\d{1,2})?$/;
  return amountRegex.test(amount.toString()) && parseFloat(amount) >= 0;
};

// Validation des dates
const validateDate = (dateString) => {
  const date = new Date(dateString);
  return !isNaN(date.getTime()) && date > new Date();
};

// Validation des URLs
const validateUrl = (url) => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

// Middleware pour valider les fichiers uploadés
const validateFileUpload = (req, res, next) => {
  if (!req.file) {
    return next();
  }

  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];

  const maxSize = 5 * 1024 * 1024; // 5MB

  if (!allowedMimeTypes.includes(req.file.mimetype)) {
    return res.status(400).json({
      success: false,
      error: 'Type de fichier non autorisé'
    });
  }

  if (req.file.size > maxSize) {
    return res.status(400).json({
      success: false,
      error: 'Taille du fichier trop importante (max 5MB)'
    });
  }

  next();
};

// Middleware pour valider les IDs
const validateId = (paramName = 'id') => {
  return (req, res, next) => {
    const id = req.params[paramName];
    
    if (!id || isNaN(parseInt(id)) || parseInt(id) <= 0) {
      return res.status(400).json({
        success: false,
        error: 'ID invalide'
      });
    }
    
    next();
  };
};

// Middleware pour valider les paramètres de pagination
const validatePagination = (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  
  const pageNum = parseInt(page);
  const limitNum = parseInt(limit);
  
  if (isNaN(pageNum) || pageNum < 1) {
    return res.status(400).json({
      success: false,
      error: 'Le numéro de page doit être un entier positif'
    });
  }
  
  if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
    return res.status(400).json({
      success: false,
      error: 'La limite doit être un entier entre 1 et 100'
    });
  }
  
  // Ajouter les valeurs validées à la requête
  req.pagination = {
    page: pageNum,
    limit: limitNum,
    offset: (pageNum - 1) * limitNum
  };
  
  next();
};

// Middleware pour valider les coordonnées GPS
const validateCoordinates = (req, res, next) => {
  const { latitude, longitude } = req.body;
  
  if (latitude !== undefined) {
    if (typeof latitude !== 'number' || latitude < -90 || latitude > 90) {
      return res.status(400).json({
        success: false,
        error: 'Latitude invalide (doit être entre -90 et 90)'
      });
    }
  }
  
  if (longitude !== undefined) {
    if (typeof longitude !== 'number' || longitude < -180 || longitude > 180) {
      return res.status(400).json({
        success: false,
        error: 'Longitude invalide (doit être entre -180 et 180)'
      });
    }
  }
  
  next();
};

// Middleware pour valider les statuts
const validateStatus = (allowedStatuses) => {
  return (req, res, next) => {
    const { status } = req.body;
    
    if (status && !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: `Statut invalide. Valeurs autorisées: ${allowedStatuses.join(', ')}`
      });
    }
    
    next();
  };
};

module.exports = {
  handleValidationErrors,
  sanitizeData,
  validateEmail,
  validatePhone,
  validatePassword,
  validateAmount,
  validateDate,
  validateUrl,
  validateFileUpload,
  validateId,
  validatePagination,
  validateCoordinates,
  validateStatus
};
