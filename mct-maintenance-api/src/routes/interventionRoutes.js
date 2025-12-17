const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { body, query, param, validationResult } = require('express-validator');
const interventionController = require('../controllers/intervention/interventionController');
const upload = require('../config/multer');

// Middleware pour valider les erreurs
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Erreur de validation',
      errors: errors.array()
    });
  }
  next();
};

/**
 * @swagger
 * /api/interventions:
 *   get:
 *     summary: Récupérer toutes les demandes d'intervention
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, assigned, in_progress, completed, cancelled]
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [low, medium, high, urgent]
 *       - in: query
 *         name: technicianId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: customerId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Liste des demandes d'intervention
 */
router.get('/', authenticate, interventionController.getAllInterventions);

// Rapports d'intervention (basé sur les plannings pour l'instant)
// Place this BEFORE parameterized routes like '/:id' to avoid conflicts
router.get('/reports', authenticate, interventionController.listReports);

/**
 * @swagger
 * /api/interventions/{id}:
 *   get:
 *     summary: Récupérer une demande d'intervention par ID
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Détails de la demande d'intervention
 */
router.get('/:id', authenticate, interventionController.getInterventionById);

/**
 * @swagger
 * /api/interventions:
 *   post:
 *     summary: Créer une nouvelle demande d'intervention
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - description
 *               - priority
 *               - productId
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *               productId:
 *                 type: integer
 *               preferredDate:
 *                 type: string
 *                 format: date
 *               preferredTime:
 *                 type: string
 *     responses:
 *       201:
 *         description: Demande d'intervention créée
 */
router.post('/', 
  authenticate,
  [
    body('title').notEmpty().withMessage('Le titre est requis'),
    body('description').notEmpty().withMessage('La description est requise'),
    body('priority').isIn(['low', 'medium', 'high', 'urgent']).withMessage('Priorité invalide'),
    body('productId').isInt().withMessage('ID produit invalide')
  ],
  interventionController.createIntervention
);

/**
 * @swagger
 * /api/interventions/{id}:
 *   put:
 *     summary: Mettre à jour une demande d'intervention
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               priority:
 *                 type: string
 *               status:
 *                 type: string
 *     responses:
 *       200:
 *         description: Demande d'intervention mise à jour
 */
router.put('/:id', authenticate, interventionController.updateIntervention);

/**
 * @swagger
 * /api/interventions/{id}/status:
 *   patch:
 *     summary: Mettre à jour le statut d'une intervention
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, assigned, in_progress, completed, cancelled]
 *     responses:
 *       200:
 *         description: Statut de l'intervention mis à jour
 */
router.patch('/:id/status', 
  authenticate,
  [
    body('status').isIn(['pending', 'assigned', 'in_progress', 'completed', 'cancelled']).withMessage('Statut invalide')
  ],
  interventionController.updateInterventionStatus
);

/**
 * @swagger
 * /api/interventions/{id}:
 *   delete:
 *     summary: Supprimer une demande d'intervention
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Demande d'intervention supprimée
 */
router.delete('/:id', authenticate, interventionController.deleteIntervention);

// Routes pour les techniciens
// Support POST et PATCH pour l'assignation (compatibilité dashboard web)
router.post('/:id/assign', 
  authenticate, 
  authorize('technician', 'admin'), 
  interventionController.assignIntervention
);

router.patch('/:id/assign', 
  authenticate, 
  authorize('technician', 'admin'), 
  interventionController.assignIntervention
);

// Workflow complet technicien
router.post('/:id/accept', 
  authenticate, 
  authorize('technician'), 
  interventionController.acceptIntervention
);

router.post('/:id/on-the-way', 
  authenticate, 
  authorize('technician'), 
  interventionController.markOnTheWay
);

router.post('/:id/arrived', 
  authenticate, 
  authorize('technician'), 
  interventionController.markArrived
);

router.post('/:id/start', 
  authenticate, 
  authorize('technician'), 
  interventionController.startIntervention
);

router.post('/:id/complete', 
  authenticate, 
  authorize('technician'), 
  interventionController.completeIntervention
);

router.post('/:id/report', 
  authenticate, 
  authorize('technician'),
  (req, res, next) => {
    console.log('📥 Réception rapport intervention:', req.params.id);
    console.log('📦 Content-Type:', req.headers['content-type']);
    next();
  },
  upload.array('images', 10), // Accepter jusqu'à 10 images
  (err, req, res, next) => {
    if (err) {
      console.error('❌ Erreur upload multer:', err.message);
      return res.status(400).json({
        success: false,
        message: `Erreur d'upload: ${err.message}`
      });
    }
    next();
  },
  interventionController.submitReport
);

/**
 * @swagger
 * /api/interventions/{id}/rate:
 *   post:
 *     summary: Noter une intervention (client uniquement)
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - rating
 *             properties:
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               review:
 *                 type: string
 *     responses:
 *       200:
 *         description: Évaluation enregistrée
 */
router.post('/:id/rate', 
  authenticate, 
  authorize('customer'), 
  [
    param('id').isInt().withMessage('ID intervention invalide'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('La note doit être entre 1 et 5'),
    body('review').optional().isString().trim()
  ],
  validate,
  interventionController.rateIntervention
);


module.exports = router;
