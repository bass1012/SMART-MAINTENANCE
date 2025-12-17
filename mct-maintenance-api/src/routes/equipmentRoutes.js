const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const equipmentController = require('../controllers/equipment/equipmentController');

// Routes pour la gestion des équipements
router.get('/', authenticate, equipmentController.listEquipments);
router.get('/:id', authenticate, equipmentController.getEquipment);
router.post('/', authenticate, equipmentController.createEquipment);
router.put('/:id', authenticate, equipmentController.updateEquipment);
router.delete('/:id', authenticate, equipmentController.deleteEquipment);

module.exports = router;
