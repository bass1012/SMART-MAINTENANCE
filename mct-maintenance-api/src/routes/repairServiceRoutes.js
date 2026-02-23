const express = require('express');
const router = express.Router();
const repairServiceController = require('../controllers/repairServiceController');
const { authenticate } = require('../middleware/auth');

// Routes publiques (pour l'application mobile)
router.get('/active', repairServiceController.getActiveRepairServices);
router.get('/:id', repairServiceController.getRepairServiceById);

// Routes protégées (pour le dashboard admin)
router.get('/', authenticate, repairServiceController.getAllRepairServices);
router.post('/', authenticate, repairServiceController.createRepairService);
router.put('/:id', authenticate, repairServiceController.updateRepairService);
router.delete('/:id', authenticate, repairServiceController.deleteRepairService);
router.patch('/:id/toggle', authenticate, repairServiceController.toggleRepairServiceStatus);

module.exports = router;
