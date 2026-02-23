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
 * /api/interventions/unrated:
 *   get:
 *     summary: Récupérer les interventions terminées non notées
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des interventions non notées
 */
router.get('/unrated', 
  authenticate, 
  authorize('customer'),
  interventionController.getUnratedInterventions
);

/**
 * @swagger
 * /api/interventions/pending-diagnostic-payment:
 *   get:
 *     summary: Récupérer les interventions avec diagnostic non payé
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des interventions avec paiement en attente
 */
router.get('/pending-diagnostic-payment', 
  authenticate, 
  authorize('customer'),
  interventionController.getPendingDiagnosticPayments
);

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

// ==================== PLANIFICATION AUTOMATIQUE ====================

/**
 * @swagger
 * /api/interventions/{id}/suggest-technicians:
 *   post:
 *     summary: Suggérer les meilleurs techniciens pour une intervention
 *     description: Algorithme de scoring multi-critères (distance, compétences, disponibilité, charge, performance)
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'intervention
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               max_results:
 *                 type: integer
 *                 default: 5
 *                 description: Nombre maximum de suggestions
 *               weights:
 *                 type: object
 *                 description: Poids personnalisés pour chaque critère
 *                 properties:
 *                   distance:
 *                     type: integer
 *                     default: 30
 *                   skills:
 *                     type: integer
 *                     default: 25
 *                   availability:
 *                     type: integer
 *                     default: 20
 *                   workload:
 *                     type: integer
 *                     default: 15
 *                   performance:
 *                     type: integer
 *                     default: 10
 *     responses:
 *       200:
 *         description: Suggestions générées avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     intervention_id:
 *                       type: integer
 *                     suggestions:
 *                       type: array
 *                       items:
 *                         type: object
 *                     computed_at:
 *                       type: string
 *                     computation_time_ms:
 *                       type: integer
 *       400:
 *         description: Intervention déjà assignée
 *       404:
 *         description: Intervention non trouvée
 */
router.post('/:id/suggest-technicians',
  authenticate,
  authorize('admin'),
  [
    param('id').isInt().withMessage('ID intervention invalide'),
    body('max_results').optional().isInt({ min: 1, max: 20 }),
    body('weights').optional().isObject()
  ],
  validate,
  interventionController.suggestTechnicians
);

/**
 * @swagger
 * /api/interventions/{id}/auto-assign:
 *   post:
 *     summary: Assigner automatiquement le meilleur technicien
 *     description: Utilise l'algorithme de scoring pour assigner automatiquement
 *     tags: [Interventions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'intervention
 *     responses:
 *       200:
 *         description: Assignation automatique réussie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     intervention_id:
 *                       type: integer
 *                     assigned_technician:
 *                       type: object
 *                     score:
 *                       type: integer
 *                     assigned_at:
 *                       type: string
 *       400:
 *         description: Intervention déjà assignée
 *       404:
 *         description: Aucun technicien disponible
 */
router.post('/:id/auto-assign',
  authenticate,
  authorize('admin'),
  [
    param('id').isInt().withMessage('ID intervention invalide')
  ],
  validate,
  interventionController.autoAssignIntervention
);

/**
 * @swagger
 * /api/interventions/{id}/send-payment-link:
 *   post:
 *     summary: Envoyer un lien de paiement pour l'offre d'entretien
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
 *         description: Lien de paiement envoyé au client
 */
router.post('/:id/send-payment-link',
  authenticate,
  authorize('admin'),
  [
    param('id').isInt().withMessage('ID intervention invalide')
  ],
  validate,
  interventionController.sendPaymentLink
);


module.exports = router;
