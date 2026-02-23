/**
 * Routes pour la gestion des Splits (équipements individuels)
 * 
 * Endpoints:
 * - POST   /api/splits              - Créer un split
 * - GET    /api/splits              - Lister tous les splits (admin)
 * - GET    /api/splits/my           - Mes splits (client connecté)
 * - GET    /api/splits/:id          - Détails d'un split
 * - GET    /api/splits/code/:code   - Rechercher par code QR
 * - GET    /api/splits/customer/:customerId - Splits d'un client
 * - PUT    /api/splits/:id          - Mettre à jour un split
 * - DELETE /api/splits/:id          - Supprimer un split
 * - POST   /api/splits/:splitId/offer - Associer une offre
 * - POST   /api/splits/:id/regenerate-qr - Régénérer le QR code
 * - POST   /api/splits/scan/:interventionId - Scanner pour intervention
 */

const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const splitController = require('../controllers/split/splitController');

// ========================================
// ROUTES PUBLIQUES (authentification requise)
// ========================================

// Mes splits (client connecté)
router.get('/my', 
  authenticate, 
  splitController.getMySplits
);

// Rechercher par code QR (technicien ou admin)
router.get('/code/:code', 
  authenticate, 
  splitController.findByQRCode
);

// ========================================
// ROUTES ADMIN / MANAGER
// ========================================

// Créer un split
router.post('/', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.createSplit
);

// Lister tous les splits
router.get('/', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.getAllSplits
);

// Détails d'un split
router.get('/:id', 
  authenticate, 
  splitController.getSplitById
);

// Splits d'un client spécifique
router.get('/customer/:customerId', 
  authenticate, 
  authorize('admin', 'manager', 'technician'), 
  splitController.getCustomerSplits
);

// Splits pour une intervention (récupère les splits du client de l'intervention)
router.get('/intervention/:interventionId', 
  authenticate, 
  authorize('admin', 'manager', 'technician'), 
  splitController.getSplitsForIntervention
);

// Mettre à jour un split
router.put('/:id', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.updateSplit
);

// Supprimer un split
router.delete('/:id', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.deleteSplit
);

// Associer une offre à un split
router.post('/:splitId/offer', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.assignOfferToSplit
);

// Régénérer le QR code
router.post('/:id/regenerate-qr', 
  authenticate, 
  authorize('admin', 'manager'), 
  splitController.regenerateQRCode
);

// ========================================
// ROUTES TECHNICIEN
// ========================================

// Scanner un split pour une intervention
router.post('/scan/:interventionId', 
  authenticate, 
  authorize('technician', 'admin', 'manager'), 
  splitController.scanSplitForIntervention
);

module.exports = router;
