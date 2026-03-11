const express = require('express');
const router = express.Router();
const { authenticate, authorize, adminOnly } = require('../middleware/auth');
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

// ============================================
// CONTRATS PROGRAMMÉS (Maintenance planifiée)
// IMPORTANT: Ces routes doivent être AVANT /:id
// ============================================

/**
 * @swagger
 * /api/contracts/scheduled:
 *   get:
 *     summary: Récupérer tous les contrats programmés
 *     tags: [Contracts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: customerId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, expired, cancelled]
 *     responses:
 *       200:
 *         description: Liste des contrats programmés
 */
router.get('/scheduled', authenticate, contractController.getScheduledContracts);

/**
 * @swagger
 * /api/contracts/upcoming-visits:
 *   get:
 *     summary: Récupérer toutes les visites à venir
 *     tags: [Contracts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Nombre de jours à regarder
 *     responses:
 *       200:
 *         description: Liste des visites à venir
 */
router.get('/upcoming-visits', authenticate, authorize('admin', 'manager'), contractController.getUpcomingVisits);

/**
 * @swagger
 * /api/contracts/scheduled:
 *   post:
 *     summary: Créer un contrat programmé avec visites automatiques
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
 *               - equipmentId
 *               - firstInterventionDate
 *             properties:
 *               customerId:
 *                 type: integer
 *                 description: ID du client (CustomerProfile.id)
 *               equipmentId:
 *                 type: integer
 *                 description: ID de l'équipement
 *               firstInterventionDate:
 *                 type: string
 *                 format: date
 *                 description: Date de la première intervention
 *               visitsTotal:
 *                 type: integer
 *                 default: 4
 *                 description: Nombre total de visites dans l'année
 *               visitIntervalMonths:
 *                 type: integer
 *                 default: 3
 *                 description: Intervalle entre chaque visite (en mois)
 *               durationMonths:
 *                 type: integer
 *                 default: 12
 *                 description: Durée totale du contrat (en mois)
 *     responses:
 *       201:
 *         description: Contrat programmé créé avec première intervention planifiée
 */
router.post('/scheduled', 
  authenticate,
  authorize('admin', 'manager'),
  [
    body('customerId').isInt().withMessage('ID client invalide'),
    body('equipmentId').isInt().withMessage('ID équipement invalide'),
    body('firstInterventionDate').isISO8601().withMessage('Date de première intervention invalide'),
    body('visitsTotal').optional().isInt({ min: 1, max: 12 }).withMessage('Nombre de visites invalide'),
    body('visitIntervalMonths').optional().isInt({ min: 1, max: 12 }).withMessage('Intervalle invalide')
  ],
  contractController.createScheduledContract
);

/**
 * @swagger
 * /api/contracts/scheduled/{id}/visits:
 *   get:
 *     summary: Récupérer les visites planifiées d'un contrat
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
 *         description: Liste des visites du contrat
 */
router.get('/scheduled/:id/visits', authenticate, contractController.getScheduledVisits);

/**
 * @swagger
 * /api/contracts/scheduled/renewal-requests:
 *   get:
 *     summary: Récupérer les demandes de renouvellement de contrats
 *     tags: [Scheduled Contracts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des demandes de renouvellement
 */
router.get('/scheduled/renewal-requests', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Notification, User, Subscription } = require('../models');
    const { Op } = require('sequelize');
    
    // Récupérer les IDs des admins/managers
    const adminUsers = await User.findAll({
      where: {
        role: { [Op.in]: ['admin', 'manager'] }
      },
      attributes: ['id']
    });
    const adminIds = adminUsers.map(u => u.id);
    
    // Récupérer les notifications de demande de renouvellement NON traitées, envoyées aux admins uniquement
    const renewalNotifications = await Notification.findAll({
      where: {
        type: 'contract_renewal_request',
        is_read: false,
        user_id: { [Op.in]: adminIds } // Seulement les notifications pour les admins
      },
      order: [['created_at', 'DESC']],
      limit: 50
    });

    // Parser les données et enrichir avec les infos du contrat
    const renewalRequests = await Promise.all(renewalNotifications.map(async (notif) => {
      let data = {};
      try {
        data = typeof notif.data === 'string' ? JSON.parse(notif.data) : (notif.data || {});
      } catch (e) {
        data = {};
      }
      
      // Récupérer les infos du client
      const customer = await User.findByPk(data.customerId, {
        attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
      });

      // Récupérer les infos de la souscription si c'est une subscription
      let subscription = null;
      if (data.isSubscription || data.contractId) {
        subscription = await Subscription.findByPk(data.contractId);
      }

      return {
        id: notif.id,
        contractId: data.contractId,
        contractReference: data.contractReference,
        customerId: data.customerId,
        customerName: data.customerName || (customer ? `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : ''),
        customerEmail: customer?.email,
        customerPhone: customer?.phone,
        isSubscription: data.isSubscription || false,
        equipmentDescription: subscription?.equipment_description,
        equipmentModel: subscription?.equipment_model,
        subscriptionStatus: subscription?.status,
        subscriptionEndDate: subscription?.end_date,
        requestedAt: notif.created_at,
        message: notif.message
      };
    }));

    res.json({
      success: true,
      data: renewalRequests,
      count: renewalRequests.length
    });
  } catch (error) {
    console.error('❌ Erreur récupération demandes renouvellement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des demandes',
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/contracts/scheduled/renewal-requests/{id}/process:
 *   post:
 *     summary: Traiter une demande de renouvellement
 *     tags: [Scheduled Contracts]
 */
router.post('/scheduled/renewal-requests/:id/process', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { id } = req.params;
    const { action, notes } = req.body; // action: 'approve' ou 'reject'
    const { Notification } = require('../models');

    const notification = await Notification.findByPk(id);
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Demande non trouvée'
      });
    }

    // Marquer comme lu (traité)
    await notification.update({ is_read: true });

    let data = {};
    try {
      data = typeof notification.data === 'string' ? JSON.parse(notification.data) : (notification.data || {});
    } catch (e) {
      data = {};
    }

    // Vérifier que customerId est présent
    if (!data.customerId) {
      console.error('❌ customerId manquant dans les données de notification:', data);
      return res.status(400).json({
        success: false,
        message: 'Données de notification incomplètes (customerId manquant)'
      });
    }

    // Notifier le client et renouveler si approuvé
    const notificationService = require('../services/notificationService');
    const { Subscription, Intervention } = require('../models');
    
    if (action === 'approve') {
      // Récupérer l'abonnement
      const subscription = await Subscription.findByPk(data.contractId);
      if (subscription) {
        // Calculer la nouvelle période (1 an à partir de la date de fin actuelle ou aujourd'hui)
        const currentEndDate = subscription.end_date ? new Date(subscription.end_date) : new Date();
        const newStartDate = new Date(Math.max(currentEndDate.getTime(), Date.now()));
        const newEndDate = new Date(newStartDate);
        newEndDate.setFullYear(newEndDate.getFullYear() + 1);

        // Réinitialiser les compteurs et remettre en attente de paiement
        await subscription.update({
          start_date: newStartDate,
          end_date: newEndDate,
          visits_completed: 0,
          status: 'pending_payment', // En attente du paiement pour activation
          payment_status: 'pending',
          first_payment_made: false,
          second_payment_made: false
        });

        // Supprimer les anciennes interventions non effectuées
        await Intervention.destroy({
          where: {
            subscription_id: subscription.id,
            status: { [require('sequelize').Op.in]: ['pending', 'scheduled'] }
          }
        });

        // Les nouvelles visites seront créées lors de l'activation après paiement
        console.log(`✅ Contrat ${subscription.id} prêt pour renouvellement: ${newStartDate.toISOString()} -> ${newEndDate.toISOString()}`);
      }

      await notificationService.create({
        userId: data.customerId,
        type: 'contract_renewal_approved',
        title: 'Demande de renouvellement approuvée',
        message: `Votre demande de renouvellement pour le contrat ${data.contractReference} a été approuvée. Veuillez procéder au paiement pour activer votre nouvelle période.`,
        data: { contractId: data.contractId },
        priority: 'high'
      });
    } else {
      await notificationService.create({
        userId: data.customerId,
        type: 'contract_renewal_rejected',
        title: 'Demande de renouvellement',
        message: notes || 'Votre demande de renouvellement a été examinée. Veuillez nous contacter pour plus d\'informations.',
        data: { contractId: data.contractId },
        priority: 'medium'
      });
    }

    console.log(`✅ Demande de renouvellement ${id} traitée: ${action}`);

    res.json({
      success: true,
      message: action === 'approve' 
        ? 'Demande approuvée. Le client a été notifié.'
        : 'Demande traitée. Le client a été notifié.',
      action
    });
  } catch (error) {
    console.error('❌ Erreur traitement demande renouvellement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du traitement',
      error: error.message
    });
  }
});

// ============================================
// FIN CONTRATS PROGRAMMÉS
// ============================================

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
  authorize('admin', 'manager'),
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
  authorize('admin', 'manager'),
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
  adminOnly,
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
  authorize('admin', 'manager'),
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
  authorize('admin', 'manager'),
  [
    body('reason').notEmpty().withMessage('La raison d\'annulation est requise')
  ],
  contractController.cancelContract
);

module.exports = router;
