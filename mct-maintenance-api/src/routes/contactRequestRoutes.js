const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const contactRequestController = require('../controllers/contactRequestController');
const { authenticate, authorize } = require('../middleware/auth');

// Middleware d'authentification facultative pour la soumission
const optionalAuthenticate = async (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) {
    return next();
  }
  try {
    const jwt = require('jsonwebtoken');
    const { User } = require('../models');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findByPk(decoded.id);
    if (user && user.status !== 'deleted' && user.status !== 'inactive') {
      req.user = user;
    }
  } catch (err) {
    // Ignorer l'erreur pour rendre l'auth optionnelle
  }
  next();
};

const createContactRequestValidation = [
  body('name')
    .trim()
    .isLength({ min: 1, max: 255 })
    .withMessage('Le nom est requis'),
  body('phone')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Le numéro de téléphone est requis'),
  body('motive')
    .trim()
    .isIn(['entretien', 'reclamation', 'information_commerciale', 'autre'])
    .withMessage('Motif de contact invalide'),
  body('message')
    .trim()
    .isLength({ min: 1 })
    .withMessage('Le message est requis'),
  body('preferredChannel')
    .trim()
    .isIn(['phone', 'email', 'chat'])
    .withMessage('Canal de rappel invalide'),
  body('preferredTime')
    .trim()
    .isIn(['morning', 'afternoon'])
    .withMessage('Plage horaire invalide'),
  body('email')
    .optional({ checkFalsy: true })
    .trim()
    .isEmail()
    .withMessage('Adresse e-mail invalide')
];

// POST /api/contact-requests - Créer une demande (public / client connecté)
router.post('/', optionalAuthenticate, createContactRequestValidation, contactRequestController.createContactRequest);

// GET /api/contact-requests - Récupérer les demandes (admin/manager/tech)
router.get('/', authenticate, authorize('admin', 'manager', 'technician'), contactRequestController.getContactRequests);

// PATCH /api/contact-requests/:id - Mettre à jour une demande (admin/manager/tech)
router.patch('/:id', authenticate, authorize('admin', 'manager', 'technician'), contactRequestController.updateContactRequest);

module.exports = router;
