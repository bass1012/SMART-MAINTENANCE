const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { body, query, param } = require('express-validator');
const promotionController = require('../controllers/promotion/promotionController');

/**
 * @swagger
 * /api/promotions:
 *   get:
 *     summary: Récupérer toutes les promotions
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, expired, upcoming, cancelled]
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [percentage, fixed_amount, free_service, bundle]
 *       - in: query
 *         name: target
 *         schema:
 *           type: string
 *           enum: [all, customers, technicians, new_users]
 *     responses:
 *       200:
 *         description: Liste des promotions
 */
router.get('/', authenticate, promotionController.getAllPromotions);

/**
 * @swagger
 * /api/promotions/public:
 *   get:
 *     summary: Récupérer les promotions actives pour le public
 *     tags: [Promotions]
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Liste des promotions actives
 */
router.get('/public', promotionController.getPublicPromotions);

/**
 * @swagger
 * /api/promotions/{id}:
 *   get:
 *     summary: Récupérer une promotion par ID
 *     tags: [Promotions]
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
 *         description: Détails de la promotion
 */
router.get('/:id', authenticate, promotionController.getPromotionById);

/**
 * @swagger
 * /api/promotions:
 *   post:
 *     summary: Créer une nouvelle promotion
 *     tags: [Promotions]
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
 *               - type
 *               - value
 *               - startDate
 *               - endDate
 *               - target
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               type:
 *                 type: string
 *                 enum: [percentage, fixed_amount, free_service, bundle]
 *               value:
 *                 type: number
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               target:
 *                 type: string
 *                 enum: [all, customers, technicians, new_users]
 *               minOrderAmount:
 *                 type: number
 *               maxUses:
 *                 type: integer
 *               code:
 *                 type: string
 *               conditions:
 *                 type: string
 *     responses:
 *       201:
 *         description: Promotion créée
 */
router.post('/', 
  authenticate,
  authorize('admin'),
  [
    body('title').notEmpty().withMessage('Le titre est requis'),
    body('description').notEmpty().withMessage('La description est requise'),
    body('type').isIn(['percentage', 'fixed_amount', 'free_service', 'bundle']).withMessage('Type de promotion invalide'),
    body('value').isFloat({ min: 0 }).withMessage('Valeur invalide'),
    body('startDate').isISO8601().withMessage('Date de début invalide'),
    body('endDate').isISO8601().withMessage('Date de fin invalide'),
    body('target').isIn(['all', 'customers', 'technicians', 'new_users']).withMessage('Cible invalide')
  ],
  promotionController.createPromotion
);

/**
 * @swagger
 * /api/promotions/{id}:
 *   put:
 *     summary: Mettre à jour une promotion
 *     tags: [Promotions]
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
 *               value:
 *                 type: number
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               status:
 *                 type: string
 *     responses:
 *       200:
 *         description: Promotion mise à jour
 */
router.put('/:id', 
  authenticate,
  authorize('admin'),
  promotionController.updatePromotion
);

/**
 * @swagger
 * /api/promotions/{id}:
 *   delete:
 *     summary: Supprimer une promotion
 *     tags: [Promotions]
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
 *         description: Promotion supprimée
 */
router.delete('/:id', 
  authenticate,
  authorize('admin'),
  promotionController.deletePromotion
);

/**
 * @swagger
 * /api/promotions/{id}/activate:
 *   post:
 *     summary: Activer une promotion
 *     tags: [Promotions]
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
 *         description: Promotion activée avec succès
 */
router.post('/:id/activate', 
  authenticate,
  authorize('admin'),
  promotionController.activatePromotion
);

/**
 * @swagger
 * /api/promotions/{id}/deactivate:
 *   post:
 *     summary: Désactiver une promotion
 *     tags: [Promotions]
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
 *         description: Promotion désactivée avec succès
 */
router.post('/:id/deactivate', 
  authenticate,
  authorize('admin'),
  promotionController.deactivatePromotion
);

/**
 * @swagger
 * /api/promotions/validate:
 *   post:
 *     summary: Valider un code promotionnel
 *     tags: [Promotions]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - code
 *             properties:
 *               code:
 *                 type: string
 *               orderAmount:
 *                 type: number
 *     responses:
 *       200:
 *         description: Code promotionnel valide
 */
router.post('/validate', 
  [
    body('code').notEmpty().withMessage('Le code promotionnel est requis')
  ],
  promotionController.validatePromotionCode
);

module.exports = router;
