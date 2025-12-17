const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/auth');

/**
 * Routes pour les paiements
 */

// Initier un paiement (authentifié)
router.post('/initiate', authenticate, paymentController.initiatePayment);

// Confirmer un paiement (authentifié)
router.post('/:paymentId/confirm', authenticate, paymentController.confirmPayment);

// Obtenir l'historique des paiements d'une commande (authentifié)
router.get('/order/:orderId', authenticate, paymentController.getOrderPayments);

// Télécharger la facture en PDF (authentifié)
router.get('/invoice/:orderId/download', authenticate, paymentController.downloadInvoice);

// Envoyer la facture par email (authentifié)
router.post('/invoice/:orderId/email', authenticate, paymentController.emailInvoice);

// Webhooks (non authentifiés - validation par signature)
router.post('/webhook/wave', paymentController.waveWebhook);
router.post('/webhook/orange', paymentController.orangeMoneyWebhook);

// Routes pour les paiements de souscriptions
router.post('/subscription/initiate', authenticate, paymentController.initiateSubscriptionPayment);
router.post('/subscription/:paymentId/confirm', authenticate, paymentController.confirmSubscriptionPayment);

module.exports = router;
