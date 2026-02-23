const express = require('express');
const router = express.Router();
const fineoPayController = require('../controllers/payment/fineoPayController');
const { authenticate } = require('../middleware/auth');

/**
 * @swagger
 * /api/fineopay/create-payment:
 *   post:
 *     summary: Créer un lien de paiement FineoPay
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - orderId
 *               - amount
 *               - title
 *             properties:
 *               orderId:
 *                 type: integer
 *               amount:
 *                 type: number
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               customerInfo:
 *                 type: object
 *                 properties:
 *                   requirePhone:
 *                     type: boolean
 *                   requireName:
 *                     type: boolean
 *     responses:
 *       200:
 *         description: Lien de paiement créé avec succès
 *       400:
 *         description: Paramètres manquants
 *       500:
 *         description: Erreur serveur
 */
router.post('/create-payment', authenticate, fineoPayController.createPaymentLink);

/**
 * @swagger
 * /api/fineopay/callback:
 *   post:
 *     summary: Webhook de notification de paiement FineoPay
 *     tags: [Paiements]
 *     description: Endpoint appelé par FineoPay pour notifier les paiements
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reference:
 *                 type: string
 *               amount:
 *                 type: number
 *               status:
 *                 type: string
 *               clientAccountNumber:
 *                 type: string
 *               timestamp:
 *                 type: string
 *     responses:
 *       200:
 *         description: Notification reçue
 */
router.post('/callback', fineoPayController.handleCallback);

/**
 * @swagger
 * /api/fineopay/transaction/{reference}:
 *   get:
 *     summary: Vérifier le statut d'une transaction
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reference
 *         required: true
 *         schema:
 *           type: string
 *         description: Référence de la transaction FineoPay
 *     responses:
 *       200:
 *         description: Détails de la transaction
 *       500:
 *         description: Erreur serveur
 */
router.get('/transaction/:reference', authenticate, fineoPayController.checkTransactionStatus);

/**
 * @swagger
 * /api/fineopay/transactions:
 *   get:
 *     summary: Lister toutes les transactions FineoPay
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des transactions
 *       500:
 *         description: Erreur serveur
 */
router.get('/transactions', authenticate, fineoPayController.listTransactions);

/**
 * @swagger
 * /api/fineopay/order-status/{orderId}:
 *   get:
 *     summary: Vérifier le statut de paiement d'une commande
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Statut de la commande
 */
router.get('/order-status/:orderId', authenticate, fineoPayController.checkOrderStatus);

/**
 * @swagger
 * /api/fineopay/verify-payment/{orderId}:
 *   get:
 *     summary: Vérifier activement le statut de paiement auprès de FineoPay
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     description: Interroge directement l'API FineoPay pour vérifier le statut de paiement (au lieu d'attendre le webhook)
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Statut de paiement vérifié
 */
router.get('/verify-payment/:orderId', authenticate, fineoPayController.verifyPaymentStatus);

/**
 * @swagger
 * /api/fineopay/verify-subscription-payment/{subscriptionId}:
 *   get:
 *     summary: Vérifier le statut de paiement d'une souscription
 *     tags: [FineoPay]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: subscriptionId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Statut de paiement vérifié
 */
router.get('/verify-subscription-payment/:subscriptionId', authenticate, fineoPayController.verifySubscriptionPaymentStatus);

/**
 * @swagger
 * /api/fineopay/verify-diagnostic-payment/{interventionId}:
 *   get:
 *     summary: Vérifier le statut de paiement d'un diagnostic d'intervention
 *     tags: [FineoPay]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: interventionId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Statut de paiement diagnostic vérifié
 */
router.get('/verify-diagnostic-payment/:interventionId', authenticate, fineoPayController.verifyDiagnosticPaymentStatus);

module.exports = router;
