const express = require('express');
const router = express.Router();
const installationServiceController = require('../controllers/installationServiceController');
const { authenticate } = require('../middleware/auth');

// Routes publiques (pour l'application mobile)
router.get('/active', installationServiceController.getActiveInstallationServices);
router.get('/:id', installationServiceController.getInstallationServiceById);

// Routes protégées (pour le dashboard admin)
router.get('/', authenticate, installationServiceController.getAllInstallationServices);
router.post('/', authenticate, installationServiceController.createInstallationService);
router.put('/:id', authenticate, installationServiceController.updateInstallationService);
router.delete('/:id', authenticate, installationServiceController.deleteInstallationService);
router.patch('/:id/toggle', authenticate, installationServiceController.toggleInstallationServiceStatus);

module.exports = router;
