const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { body, query, param } = require('express-validator');
const contractController = require('../controllers/contract/contractController');

/**
 * @swagger
 * /api/contracts:
 *   get:
 *     summary: Récupérer tous les contrats de maintenance
 *     tags: [Contracts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, expired, cancelled, pending]
 *       - in: query
 *         name: customerId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Liste des contrats de maintenance
 */
router.get('/', authenticate, contractController.getAllContracts);

/**
 * @swagger
 * /api/contracts/{id}:
 *   get:
 *     summary: Récupérer un contrat de maintenance par ID
 *     tags: [Contracts]
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
 *         description: Détails du contrat de maintenance
 */
router.get('/:id', authenticate, contractController.getContractById);

/**
 * @swagger
 * /api/contracts:
 *   post:
 *     summary: Créer un nouveau contrat de maintenance
 *     tags: [Contracts]
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
 *               - type
 *               - startDate
 *               - endDate
 *               - amount
 *             properties:
 *               customerId:
 *                 type: integer
 *               type:
 *                 type: string
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               amount:
 *                 type: number
 *               description:
 *                 type: string
 *               terms:
 *                 type: string
 *     responses:
 *       201:
 *         description: Contrat de maintenance créé
 */
router.post('/', 
  authenticate,
  authorize('admin'),
  [
    body('customerId').isInt().withMessage('ID client invalide'),
    body('type').notEmpty().withMessage('Le type de contrat est requis'),
    body('startDate').isISO8601().withMessage('Date de début invalide'),
    body('endDate').isISO8601().withMessage('Date de fin invalide'),
    body('amount').isFloat({ min: 0 }).withMessage('Montant invalide')
  ],
  contractController.createContract
);

/**
 * @swagger
 * /api/contracts/{id}:
 *   put:
 *     summary: Mettre à jour un contrat de maintenance
 *     tags: [Contracts]
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
 *               type:
 *                 type: string
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               amount:
 *                 type: number
 *               status:
 *                 type: string
 *     responses:
 *       200:
 *         description: Contrat de maintenance mis à jour
 */
router.put('/:id', 
  authenticate,
  authorize('admin'),
  contractController.updateContract
);

/**
 * @swagger
 * /api/contracts/{id}:
 *   delete:
 *     summary: Supprimer un contrat de maintenance
 *     tags: [Contracts]
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
 *         description: Contrat de maintenance supprimé
 */
router.delete('/:id', 
  authenticate,
  authorize('admin'),
  contractController.deleteContract
);

/**
 * @swagger
 * /api/contracts/{id}/renew:
 *   post:
 *     summary: Renouveler un contrat de maintenance
 *     tags: [Contracts]
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
 *               - newEndDate
 *               - newAmount
 *             properties:
 *               newEndDate:
 *                 type: string
 *                 format: date
 *               newAmount:
 *                 type: number
 *     responses:
 *       200:
 *         description: Contrat renouvelé avec succès
 */
router.post('/:id/renew', 
  authenticate,
  authorize('admin'),
  [
    body('newEndDate').isISO8601().withMessage('Nouvelle date de fin invalide'),
    body('newAmount').isFloat({ min: 0 }).withMessage('Nouveau montant invalide')
  ],
  contractController.renewContract
);

/**
 * @swagger
 * /api/contracts/{id}/cancel:
 *   post:
 *     summary: Annuler un contrat de maintenance
 *     tags: [Contracts]
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
 *         description: Contrat annulé avec succès
 */
router.post('/:id/cancel', 
  authenticate,
  authorize('admin'),
  [
    body('reason').notEmpty().withMessage('La raison d\'annulation est requise')
  ],
  contractController.cancelContract
);

module.exports = router;
