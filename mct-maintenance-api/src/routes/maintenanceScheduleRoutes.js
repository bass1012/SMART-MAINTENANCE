const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const maintenanceScheduleController = require('../controllers/maintenanceScheduleController');

// Liste des plannings
router.get('/', authenticate, maintenanceScheduleController.listSchedules);
// Détail d'un planning
router.get('/:id', authenticate, maintenanceScheduleController.getSchedule);
// Création
router.post('/', authenticate, maintenanceScheduleController.createSchedule);
// Mise à jour
router.put('/:id', authenticate, maintenanceScheduleController.updateSchedule);
// Suppression
router.delete('/:id', authenticate, maintenanceScheduleController.deleteSchedule);

module.exports = router;
