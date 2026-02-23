const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { body, query, param } = require('express-validator');
const quoteController = require('../controllers/quote/quoteController');
const quoteWorkflowController = require('../controllers/quoteWorkflowController');

/**
 * @swagger
 * /api/quotes:
 *   get:
 *     summary: Récupérer tous les devis
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, accepted, rejected, expired]
 *       - in: query
 *         name: customerId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: technicianId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Liste des devis
 */
router.get('/', authenticate, quoteController.getAllQuotes);

/**
 * Créer un devis à partir d'un rapport de diagnostic
 * POST /api/quotes/from-report
 */
router.post('/from-report', 
  authenticate, 
  authorize('admin'), 
  quoteWorkflowController.createQuoteFromReport
);

// Générer le PDF d'un devis
router.get('/:id/pdf', authenticate, quoteController.generateQuotePdf);

/**
 * @swagger
 * /api/quotes/{id}:
 *   get:
 *     summary: Récupérer un devis par ID
 *     tags: [Quotes]
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
 *         description: Détails du devis
 */
router.get('/:id', authenticate, quoteController.getQuoteById);

/**
 * @swagger
 * /api/quotes:
 *   post:
 *     summary: Créer un nouveau devis
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - customerId
 *               - title
 *               - description
 *               - items
 *               - totalAmount
 *               - validUntil
 *             properties:
 *               customerId:
 *                 type: integer
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               items:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     productId:
 *                       type: integer
 *                     description:
 *                       type: string
 *                     quantity:
 *                       type: integer
 *                     unitPrice:
 *                       type: number
 *                     totalPrice:
 *                       type: number
 *               totalAmount:
 *                 type: number
 *               validUntil:
 *                 type: string
 *                 format: date
 *               terms:
 *                 type: string
 *     responses:
 *       201:
 *         description: Devis créé
 */
router.post('/', 
  authenticate,
  authorize('admin', 'technician'),
  [
    body('customerId').isInt().withMessage('ID client invalide'),
    body('title').notEmpty().withMessage('Le titre est requis'),
    body('description').notEmpty().withMessage('La description est requise'),
    body('items').isArray().withMessage('Les items doivent être un tableau'),
    body('totalAmount').isFloat({ min: 0 }).withMessage('Montant total invalide'),
    body('validUntil').isISO8601().withMessage('Date de validité invalide')
  ],
  quoteController.createQuote
);

/**
 * @swagger
 * /api/quotes/{id}:
 *   put:
 *     summary: Mettre à jour un devis
 *     tags: [Quotes]
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
 *               items:
 *                 type: array
 *               totalAmount:
 *                 type: number
 *               validUntil:
 *                 type: string
 *                 format: date
 *               status:
 *                 type: string
 *     responses:
 *       200:
 *         description: Devis mis à jour
 */
router.put('/:id', 
  authenticate,
  authorize('admin', 'technician'),
  quoteController.updateQuote
);

/**
 * @swagger
 * /api/quotes/{id}:
 *   delete:
 *     summary: Supprimer un devis
 *     tags: [Quotes]
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
 *         description: Devis supprimé
 */
router.delete('/:id', 
  authenticate,
  authorize('admin'),
  quoteController.deleteQuote
);

/**
 * @swagger
 * /api/quotes/{id}/accept:
 *   post:
 *     summary: Accepter un devis
 *     tags: [Quotes]
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
 *         description: Devis accepté avec succès
 */
router.post('/:id/accept', 
  authenticate,
  authorize('customer'),
  quoteController.acceptQuote
);

/**
 * @swagger
 * /api/quotes/{id}/reject:
 *   post:
 *     summary: Rejeter un devis
 *     tags: [Quotes]
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
 *               - reason
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Devis rejeté avec succès
 */
router.post('/:id/reject', 
  authenticate,
  authorize('customer'),
  [
    body('reason').notEmpty().withMessage('La raison de rejet est requise')
  ],
  quoteController.rejectQuote
);

/**
 * @swagger
 * /api/quotes/{id}/convert-to-order:
 *   post:
 *     summary: Convertir un devis en commande
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       201:
 *         description: Devis converti en commande avec succès
 */
router.post('/:id/convert-to-order', 
  authenticate,
  authorize('admin'),
  quoteController.convertQuoteToOrder
);

module.exports = router;

// Nouvelle route pour mettre à jour uniquement le statut d'un devis
router.patch('/:id/status',
  authenticate,
  authorize('admin', 'technician'),
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      if (!status) {
        return res.status(400).json({ message: 'Le statut est requis.' });
      }
      const updated = await require('../controllers/quote/quoteController').updateQuoteStatus(id, status);
      if (!updated) {
        return res.status(404).json({ message: 'Devis non trouvé.' });
      }
      res.json({ message: 'Statut du devis mis à jour avec succès.' });
    } catch (error) {
      next(error);
    }
  }
);
