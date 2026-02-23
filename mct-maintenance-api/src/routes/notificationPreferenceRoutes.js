const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const notificationPreferenceController = require('../controllers/notifications/notificationPreferenceController');

/**
 * Routes pour les préférences de notifications
 * Toutes les routes nécessitent une authentification
 */

// GET /api/notification-preferences - Récupérer les préférences
router.get('/', authenticate, notificationPreferenceController.getPreferences);

// PUT /api/notification-preferences - Mettre à jour les préférences
router.put('/', authenticate, notificationPreferenceController.updatePreferences);

// POST /api/notification-preferences/reset - Réinitialiser aux valeurs par défaut
router.post('/reset', authenticate, notificationPreferenceController.resetPreferences);

// PUT /api/notification-preferences/toggle-email - Activer/Désactiver emails
router.put('/toggle-email', authenticate, notificationPreferenceController.toggleEmail);

// PUT /api/notification-preferences/toggle-push - Activer/Désactiver push
router.put('/toggle-push', authenticate, notificationPreferenceController.togglePush);

// PUT /api/notification-preferences/quiet-hours - Configurer heures de silence
router.put('/quiet-hours', authenticate, notificationPreferenceController.setQuietHours);

module.exports = router;
