const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const customerController = require('../controllers/customerController');
const { Contract, User } = require('../models');
const { 
  listCustomers, 
  getCustomer, 
  createCustomer, 
  updateCustomer, 
  deleteCustomer 
} = require('../controllers/customer/customerController');

const router = express.Router();

// All customer routes require authentication
router.use(authenticate);

// ==================== TABLEAU DE BORD ====================

const dashboardController = require('../controllers/customer/dashboardController');

// Statistiques du tableau de bord client
router.get('/dashboard/stats', dashboardController.getDashboardStats);

// ==================== DEVIS ET CONTRATS ====================

// IMPORTANT: Les routes spécifiques doivent être AVANT les routes génériques

// Accepter un devis
router.post('/quotes/:id/accept', async (req, res) => {
  try {
    const { Quote, CustomerProfile } = require('../models');
    const { notifyQuoteAccepted } = require('../services/notificationHelpers');
    const userId = req.user.id;
    const quoteId = req.params.id;
    
    console.log(`✅ Acceptation du devis ${quoteId} par user_id: ${userId}`);
    
    // Vérifier que le devis appartient au client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    const quote = await Quote.findOne({
      where: { 
        id: quoteId,
        customerId: customerProfile.id 
      }
    });
    
    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Devis non trouvé',
      });
    }
    
    // Mettre à jour le statut
    await quote.update({ status: 'accepted' });
    
    console.log(`✅ Devis ${quoteId} accepté`);
    
    // 📬 Notifier les admins de l'acceptation
    try {
      await notifyQuoteAccepted(quote, customerProfile);
      console.log('✅ Notification envoyée aux admins : devis accepté');
    } catch (notifError) {
      console.error('⚠️  Erreur notification acceptation devis:', notifError.message);
    }
    
    res.json({
      success: true,
      message: 'Devis accepté avec succès',
      data: quote
    });
  } catch (error) {
    console.error('❌ Error accepting quote:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'acceptation du devis',
      error: error.message
    });
  }
});

// Refuser un devis
router.post('/quotes/:id/reject', async (req, res) => {
  try {
    const { Quote, CustomerProfile } = require('../models');
    const { notifyQuoteRejected } = require('../services/notificationHelpers');
    const userId = req.user.id;
    const quoteId = req.params.id;
    const { reason } = req.body;
    
    console.log(`❌ Refus du devis ${quoteId} par user_id: ${userId}`);
    
    // Vérifier que le devis appartient au client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    const quote = await Quote.findOne({
      where: { 
        id: quoteId,
        customerId: customerProfile.id 
      }
    });
    
    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Devis non trouvé',
      });
    }
    
    // Mettre à jour le statut et ajouter la raison
    const updateData = { 
      status: 'rejected',
      rejection_reason: reason || 'Refusé par le client'
    };
    
    await quote.update(updateData);
    
    console.log(`✅ Devis ${quoteId} refusé`);
    
    // 📬 Notifier les admins du rejet
    try {
      await notifyQuoteRejected(quote, customerProfile);
      console.log('✅ Notification envoyée aux admins : devis rejeté');
    } catch (notifError) {
      console.error('⚠️  Erreur notification rejet devis:', notifError.message);
    }
    
    res.json({
      success: true,
      message: 'Devis refusé',
      data: quote
    });
  } catch (error) {
    console.error('❌ Error rejecting quote:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du refus du devis',
      error: error.message
    });
  }
});

// Liste des devis du client
router.get('/quotes', async (req, res) => {
  try {
    const { Quote, QuoteItem, CustomerProfile } = require('../models');
    const userId = req.user.id;
    
    console.log(`📋 Récupération des devis pour user_id: ${userId}`);
    
    // Trouver le customer_id depuis le user_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      console.log('❌ Aucun profil client trouvé pour cet utilisateur');
      return res.json({
        success: true,
        data: [],
        message: 'Aucun devis trouvé',
      });
    }
    
    const customerId = customerProfile.id;
    console.log(`✅ Customer ID trouvé: ${customerId}`);
    
    // Récupérer tous les devis du client
    const quotes = await Quote.findAll({
      where: { customerId: customerId },
      include: [{ model: QuoteItem, as: 'items' }],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ ${quotes.length} devis trouvés`);
    
    // Formater les données pour le mobile
    const formattedQuotes = quotes.map(quote => ({
      id: quote.id.toString(),
      reference: quote.reference,
      title: quote.notes || 'Devis',
      description: quote.termsAndConditions || '',
      amount: parseFloat(quote.total),
      status: quote.status,
      validUntil: quote.expiryDate,
      createdAt: quote.created_at || quote.createdAt,
      issueDate: quote.issueDate,
      expiryDate: quote.expiryDate,
      subtotal: parseFloat(quote.subtotal),
      taxAmount: parseFloat(quote.taxAmount),
      discountAmount: parseFloat(quote.discountAmount),
      items: quote.items || []
    }));
    
    res.json({
      success: true,
      data: formattedQuotes,
      message: 'Devis récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting customer quotes:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des devis',
      error: error.message
    });
  }
});

// ==================== RAPPORTS DE MAINTENANCE ====================

// Liste des rapports de maintenance du client
router.get('/maintenance-reports', async (req, res) => {
  try {
    const { Intervention, User, TechnicianProfile } = require('../models');
    const { Op } = require('sequelize');
    const customerId = req.user.id;

    console.log(`📋 Client ${customerId}: Récupération des rapports de maintenance`);

    // Récupérer les interventions avec rapport soumis
    const interventions = await Intervention.findAll({
      where: {
        customer_id: customerId,
        report_submitted_at: { [Op.not]: null } // Seulement avec rapport
      },
      include: [
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
          include: [{
            model: TechnicianProfile,
            as: 'technicianProfile',
            attributes: ['first_name', 'last_name', 'phone']
          }]
        }
      ],
      order: [['report_submitted_at', 'DESC']],
    });

    // Formater les données pour le mobile
    const reports = interventions.map(intervention => {
      const reportData = intervention.report_data ?
        (typeof intervention.report_data === 'string' ?
          JSON.parse(intervention.report_data) : intervention.report_data)
        : {};

      // Enrichir le technicien
      const technician = intervention.technician;
      const technicianName = technician ?
        (technician.technicianProfile ?
          `${technician.technicianProfile.first_name} ${technician.technicianProfile.last_name}` :
          `${technician.first_name || ''} ${technician.last_name || ''}`.trim() || technician.email
        ) : 'Technicien non assigné';

      return {
        id: intervention.id,
        reference: `MAINT-${intervention.id}`,
        title: intervention.title,
        description: reportData.work_description || intervention.description || '',
        status: intervention.status,
        technicianName: technicianName,
        technicianNotes: reportData.observations || '',
        scheduledDate: intervention.scheduled_date,
        completedDate: intervention.completed_at || intervention.report_submitted_at,
        duration: reportData.duration || 0,
        materialsUsed: reportData.materials_used || [],
        photosCount: reportData.photos_count || 0,
        imageUrls: [], // TODO: Ajouter les URLs des photos si disponibles
        createdAt: intervention.created_at,
      };
    });

    console.log(`✅ ${reports.length} rapport(s) de maintenance trouvé(s)`);

    res.json({
      success: true,
      data: reports,
      message: 'Rapports de maintenance récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting maintenance reports:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des rapports',
      error: error.message
    });
  }
});

// ==================== RÉCLAMATIONS ====================

// Liste des réclamations du client
router.get('/complaints', async (req, res) => {
  try {
    const { Complaint, CustomerProfile } = require('../models');
    const userId = req.user.id;
    
    console.log('🔍 GET /api/customer/complaints - User ID:', userId);
    
    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    if (!customerProfile) {
      console.log('❌ Profil client non trouvé pour user_id:', userId);
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    console.log('✅ Customer profile found:', customerProfile.id);
    
    // Récupérer les réclamations du client
    const complaints = await Complaint.findAll({
      where: { customerId: customerProfile.id },
      order: [['created_at', 'DESC']]
    });
    
    console.log(`📋 Found ${complaints.length} complaints for customer ${customerProfile.id}`);
    
    res.json({
      success: true,
      data: complaints,
      message: 'Réclamations récupérées avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting complaints:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des réclamations',
      error: error.message
    });
  }
});

// ==================== OFFRES D'ENTRETIEN ====================

// Liste des offres d'entretien pour le client
router.get('/maintenance-offers', async (req, res) => {
  try {
    const { MaintenanceOffer } = require('../models');
    
    console.log('🔍 GET /api/customer/maintenance-offers');
    
    // Récupérer toutes les offres actives
    const offers = await MaintenanceOffer.findAll({
      where: { isActive: true },
      order: [['price', 'ASC']]
    });
    
    console.log(`✅ Found ${offers.length} active maintenance offers`);
    
    res.json({
      success: true,
      data: offers,
      message: 'Offres d\'entretien récupérées avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting maintenance offers:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des offres',
      error: error.message
    });
  }
});

// POST /api/customer/subscriptions - Créer une souscription
router.post('/subscriptions', authenticate, async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer, User } = require('../models');
    const { maintenance_offer_id } = req.body;
    const customerId = req.user.id;
    
    console.log(`📝 POST /api/customer/subscriptions - Customer ${customerId}, Offer ${maintenance_offer_id}`);
    
    // Vérifier que l'offre existe et est active
    const offer = await MaintenanceOffer.findByPk(maintenance_offer_id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre d\'entretien non trouvée'
      });
    }
    
    if (!offer.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cette offre n\'est plus active'
      });
    }
    
    // Calculer les dates
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + offer.duration);
    
    // Créer la souscription
    const subscription = await Subscription.create({
      customer_id: customerId,
      maintenance_offer_id: maintenance_offer_id,
      status: 'active', // Statut actif mais paiement en attente
      start_date: startDate,
      end_date: endDate,
      price: offer.price,
      payment_status: 'pending' // En attente de paiement
    });
    
    console.log(`✅ Subscription created: ${subscription.id}`);
    
    // 🔔 Envoyer une notification au client (paiement en attente)
    try {
      const user = await User.findByPk(customerId);
      
      const notificationService = require('../services/notificationService');
      
      await notificationService.create({
        userId: customerId,
        type: 'subscription_created',
        title: 'Paiement initié',
        message: `Votre souscription à "${offer.title}" est en attente de confirmation de paiement`,
        data: {
          subscriptionId: subscription.id,
          offerName: offer.title,
          amount: offer.price,
          paymentStatus: 'pending'
        },
        priority: 'medium',
        actionUrl: `/dashboard`
      });
      
      console.log(`✅ Notification paiement en attente envoyée au client`);
      
      // 🔔 Notifier les admins de la nouvelle souscription
      await notificationService.notifyAdmins({
        type: 'subscription_created',
        title: '💳 Nouvelle souscription',
        message: `${user.first_name || user.email} a souscrit à "${offer.title}" (${offer.price}€)`,
        data: {
          subscriptionId: subscription.id,
          customerId: customerId,
          customerName: user.first_name || user.email,
          offerName: offer.title,
          amount: offer.price,
          paymentStatus: 'pending'
        },
        priority: 'high',
        actionUrl: `/maintenance-offers`
      });
      
      console.log(`✅ Notification nouvelle souscription envoyée aux admins`);
    } catch (notifError) {
      console.error('❌ Erreur notification souscription:', notifError);
    }
    
    res.status(201).json({
      success: true,
      data: subscription,
      message: 'Souscription créée avec succès, en attente de paiement'
    });
  } catch (error) {
    console.error('❌ Error creating subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la souscription',
      error: error.message
    });
  }
});

// GET /api/customer/subscriptions - Récupérer les souscriptions du client
router.get('/subscriptions', authenticate, async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer } = require('../models');
    const customerId = req.user.id;
    
    console.log(`🔍 GET /api/customer/subscriptions - Customer ${customerId}`);
    
    const subscriptions = await Subscription.findAll({
      where: { customer_id: customerId },
      include: [
        {
          model: MaintenanceOffer,
          as: 'offer'
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ Found ${subscriptions.length} subscriptions`);
    
    res.json({
      success: true,
      data: subscriptions,
      message: 'Souscriptions récupérées avec succès'
    });
  } catch (error) {
    console.error('❌ Error getting subscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des souscriptions',
      error: error.message
    });
  }
});

// GET /api/customer/subscriptions/:id - Récupérer une souscription par ID
router.get('/subscriptions/:id', authenticate, async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer } = require('../models');
    const { id } = req.params;
    const customerId = req.user.id;
    
    console.log(`🔍 GET /api/customer/subscriptions/${id}`);
    
    const subscription = await Subscription.findOne({
      where: { 
        id: id,
        customer_id: customerId 
      },
      include: [
        {
          model: MaintenanceOffer,
          as: 'offer'
        }
      ]
    });
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    res.json({
      success: true,
      data: subscription,
      message: 'Souscription récupérée avec succès'
    });
  } catch (error) {
    console.error('❌ Error getting subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la souscription',
      error: error.message
    });
  }
});

// PATCH /api/customer/subscriptions/:id/cancel - Annuler une souscription
router.patch('/subscriptions/:id/cancel', authenticate, async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    const customerId = req.user.id;
    
    console.log(`📝 PATCH /api/customer/subscriptions/${id}/cancel`);
    
    const subscription = await Subscription.findOne({
      where: { 
        id: id,
        customer_id: customerId 
      }
    });
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    if (subscription.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Cette souscription est déjà annulée'
      });
    }
    
    subscription.status = 'cancelled';
    await subscription.save();
    
    console.log(`✅ Subscription ${id} cancelled`);
    
    res.json({
      success: true,
      data: subscription,
      message: 'Souscription annulée avec succès'
    });
  } catch (error) {
    console.error('❌ Error cancelling subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation de la souscription',
      error: error.message
    });
  }
});

// ==================== ROUTES EXISTANTES ====================

// Customer profile routes
router.get('/profile', (req, res) => {
  res.json({
    success: true,
    message: 'Customer profile retrieved successfully',
    data: {}
  });
});

router.put('/profile', (req, res) => {
  res.json({
    success: true,
    message: 'Customer profile updated successfully'
  });
});

// Customer contracts routes
router.get('/contracts', async (req, res) => {
  try {
    const userId = req.user.id;
    
    const contracts = await Contract.findAll({
      where: { customer_id: userId },
      include: [
        { 
          model: User, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      message: 'Customer contracts retrieved successfully',
      data: contracts
    });
  } catch (error) {
    console.error('Error fetching customer contracts:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
});

router.get('/contracts/:id', async (req, res) => {
  try {
    const userId = req.user.id;
    const contractId = req.params.id;
    
    const contract = await Contract.findOne({
      where: { 
        id: contractId,
        customer_id: userId  // Vérifier que le contrat appartient à l'utilisateur
      },
      include: [
        { 
          model: User, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        }
      ]
    });

    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    res.json({
      success: true,
      message: 'Contract details retrieved successfully',
      data: contract
    });
  } catch (error) {
    console.error('Error fetching contract details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
});

// POST /api/customer/contracts/:id/request-renewal - Demander le renouvellement d'un contrat
router.post('/contracts/:id/request-renewal', async (req, res) => {
  try {
    const userId = req.user.id;
    const contractId = req.params.id;
    const { Notification } = require('../models');
    
    console.log(`🔄 Demande de renouvellement contrat ${contractId} par client ${userId}`);
    
    // Vérifier que le contrat appartient au client
    const contract = await Contract.findOne({
      where: { 
        id: contractId,
        customer_id: userId
      },
      include: [
        { 
          model: User, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        }
      ]
    });

    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    // Vérifier que le contrat peut être renouvelé (expiré, bientôt expiré, ou terminé)
    const now = new Date();
    const daysUntilExpiry = Math.ceil((new Date(contract.end_date) - now) / (1000 * 60 * 60 * 24));
    
    if (contract.status === 'active' && daysUntilExpiry > 60) {
      return res.status(400).json({
        success: false,
        message: `Votre contrat est encore valide pour ${daysUntilExpiry} jours. Vous pourrez demander un renouvellement 60 jours avant l'expiration.`
      });
    }

    // Créer une notification pour les admins
    const notificationService = require('../services/notificationService');
    await notificationService.notifyAdmins({
      type: 'contract_renewal_request',
      title: 'Demande de renouvellement de contrat',
      message: `${contract.customer.first_name} ${contract.customer.last_name} souhaite renouveler le contrat ${contract.reference}`,
      data: {
        contractId: contract.id,
        contractReference: contract.reference,
        customerId: userId,
        customerName: `${contract.customer.first_name} ${contract.customer.last_name}`
      },
      priority: 'high',
      actionUrl: `/contrats`
    });

    // Créer une notification pour le client
    await Notification.create({
      user_id: userId,
      type: 'contract_renewal_request',
      title: 'Demande de renouvellement envoyée',
      message: `Votre demande de renouvellement pour le contrat ${contract.reference} a été envoyée à notre équipe.`,
      data: JSON.stringify({
        contractId: contract.id,
        contractReference: contract.reference
      }),
      priority: 'medium',
      is_read: false,
      action_url: `/contrats`
    });

    console.log(`✅ Demande de renouvellement envoyée pour contrat ${contract.reference}`);

    res.json({
      success: true,
      message: 'Votre demande de renouvellement a été envoyée avec succès. Notre équipe vous contactera prochainement.',
      data: {
        contractId: contract.id,
        reference: contract.reference,
        status: contract.status,
        endDate: contract.end_date
      }
    });
  } catch (error) {
    console.error('❌ Error requesting contract renewal:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la demande de renouvellement',
      error: error.message
    });
  }
});

// Customer interventions routes
router.get('/interventions', async (req, res) => {
  try {
    const { Intervention, User, Equipment } = require('../models');
    const userId = req.user.id;
    
    console.log(`🔧 Récupération des interventions pour user_id: ${userId}`);
    
    // Récupérer toutes les interventions du client
    const interventions = await Intervention.findAll({
      where: { customerId: userId },
      include: [
        { 
          model: User, 
          as: 'technician',
          attributes: ['id', 'firstName', 'lastName', 'email', 'phone']
        },
        { 
          model: Equipment, 
          as: 'equipment',
          attributes: ['id', 'name', 'type', 'brand', 'model']
        }
      ],
      order: [['scheduledDate', 'DESC']]
    });
    
    console.log(`✅ ${interventions.length} interventions trouvées`);
    
    // Formater les données pour le mobile
    const formattedInterventions = interventions.map(intervention => ({
      id: intervention.id,
      customerId: intervention.customerId,
      technicianId: intervention.technicianId,
      equipmentId: intervention.equipmentId,
      type: intervention.type,
      status: intervention.status,
      priority: intervention.priority,
      description: intervention.description,
      scheduledDate: intervention.scheduledDate,
      completedDate: intervention.completedDate,
      estimatedDuration: intervention.estimatedDuration,
      actualDuration: intervention.actualDuration,
      cost: intervention.cost,
      notes: intervention.notes,
      address: intervention.address,
      createdAt: intervention.createdAt,
      updatedAt: intervention.updatedAt,
      technician: intervention.technician ? {
        id: intervention.technician.id,
        firstName: intervention.technician.firstName,
        lastName: intervention.technician.lastName,
        email: intervention.technician.email,
        phone: intervention.technician.phone
      } : null,
      equipment: intervention.equipment ? {
        id: intervention.equipment.id,
        name: intervention.equipment.name,
        type: intervention.equipment.type,
        brand: intervention.equipment.brand,
        model: intervention.equipment.model
      } : null
    }));
    
    res.json({
      success: true,
      message: 'Interventions récupérées avec succès',
      data: formattedInterventions
    });
  } catch (error) {
    console.error('❌ Error fetching interventions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des interventions',
      error: error.message
    });
  }
});

router.post('/interventions', async (req, res) => {
  try {
    const { Intervention } = require('../models');
    const userId = req.user.id;
    const {
      equipmentId,
      type,
      priority,
      description,
      scheduledDate,
      address
    } = req.body;
    
    console.log(`🔧 Création d'une intervention pour user_id: ${userId}`);
    
    // Créer l'intervention
    const intervention = await Intervention.create({
      customerId: userId,
      equipmentId,
      type: type || 'maintenance',
      status: 'pending',
      priority: priority || 'normal',
      description,
      scheduledDate,
      address
    });
    
    console.log(`✅ Intervention ${intervention.id} créée`);
    
    res.json({
      success: true,
      message: 'Demande d\'intervention créée avec succès',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Error creating intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de l\'intervention',
      error: error.message
    });
  }
});

router.get('/interventions/:id', async (req, res) => {
  try {
    const { Intervention, User, Equipment } = require('../models');
    const userId = req.user.id;
    const interventionId = req.params.id;
    
    console.log(`🔧 Récupération de l'intervention ${interventionId} pour user_id: ${userId}`);
    
    // Récupérer l'intervention avec ses relations
    const intervention = await Intervention.findOne({
      where: { 
        id: interventionId,
        customerId: userId 
      },
      include: [
        { 
          model: User, 
          as: 'technician',
          attributes: ['id', 'firstName', 'lastName', 'email', 'phone']
        },
        { 
          model: Equipment, 
          as: 'equipment',
          attributes: ['id', 'name', 'type', 'brand', 'model']
        }
      ]
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    console.log(`✅ Intervention ${interventionId} trouvée`);
    
    // Formater les données
    const formattedIntervention = {
      id: intervention.id,
      customerId: intervention.customerId,
      technicianId: intervention.technicianId,
      equipmentId: intervention.equipmentId,
      type: intervention.type,
      status: intervention.status,
      priority: intervention.priority,
      description: intervention.description,
      scheduledDate: intervention.scheduledDate,
      completedDate: intervention.completedDate,
      estimatedDuration: intervention.estimatedDuration,
      actualDuration: intervention.actualDuration,
      cost: intervention.cost,
      notes: intervention.notes,
      address: intervention.address,
      createdAt: intervention.createdAt,
      updatedAt: intervention.updatedAt,
      technician: intervention.technician ? {
        id: intervention.technician.id,
        firstName: intervention.technician.firstName,
        lastName: intervention.technician.lastName,
        email: intervention.technician.email,
        phone: intervention.technician.phone
      } : null,
      equipment: intervention.equipment ? {
        id: intervention.equipment.id,
        name: intervention.equipment.name,
        type: intervention.equipment.type,
        brand: intervention.equipment.brand,
        model: intervention.equipment.model
      } : null
    };
    
    res.json({
      success: true,
      message: 'Intervention récupérée avec succès',
      data: formattedIntervention
    });
  } catch (error) {
    console.error('❌ Error fetching intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'intervention',
      error: error.message
    });
  }
});

// Customer orders routes
router.get('/orders', async (req, res) => {
  try {
    const { Order, OrderItem, Product, User } = require('../models');
    const userId = req.user.id;
    
    console.log(`📦 Récupération des commandes pour user_id: ${userId}`);
    
    // Récupérer toutes les commandes du client
    const orders = await Order.findAll({
      where: { customerId: userId },
      include: [
        { 
          model: OrderItem, 
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ ${orders.length} commandes trouvées`);
    
    // Formater les données pour le mobile
    const formattedOrders = orders.map(order => ({
      id: order.id,
      reference: order.reference,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items?.map(item => ({
        id: item.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unit_price || item.unitPrice,
        total: item.total,
        product: item.product ? {
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          imageUrl: item.product.imageUrl
        } : null
      })) || []
    }));
    
    res.json({
      success: true,
      message: 'Commandes récupérées avec succès',
      data: formattedOrders
    });
  } catch (error) {
    console.error('❌ Error fetching orders:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
});

router.get('/orders/:id', async (req, res) => {
  try {
    const { Order, OrderItem, Product, User } = require('../models');
    const userId = req.user.id;
    const orderId = req.params.id;
    
    console.log(`📦 Récupération de la commande ${orderId} pour user_id: ${userId}`);
    
    // Récupérer la commande avec ses items
    const order = await Order.findOne({
      where: { 
        id: orderId,
        customerId: userId 
      },
      include: [
        { 
          model: OrderItem, 
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        },
        { model: User, as: 'customer' }
      ]
    });
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    console.log(`✅ Commande ${orderId} trouvée`);
    
    // Formater les données
    const formattedOrder = {
      id: order.id,
      reference: order.reference,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      customer: order.customer ? {
        id: order.customer.id,
        firstName: order.customer.firstName,
        lastName: order.customer.lastName,
        email: order.customer.email
      } : null,
      items: order.items?.map(item => ({
        id: item.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unit_price || item.unitPrice,
        total: item.total,
        product: item.product ? {
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          imageUrl: item.product.imageUrl
        } : null
      })) || []
    };
    
    res.json({
      success: true,
      message: 'Commande récupérée avec succès',
      data: formattedOrder
    });
  } catch (error) {
    console.error('❌ Error fetching order:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la commande',
      error: error.message
    });
  }
});

// Customer quotes routes - Les routes spécifiques (accept/reject) sont définies AVANT

// Détails d'un devis
router.get('/quotes/:id', async (req, res) => {
  try {
    const { Quote, QuoteItem, CustomerProfile } = require('../models');
    const userId = req.user.id;
    const quoteId = req.params.id;
    
    console.log(`📋 Récupération du devis ${quoteId} pour user_id: ${userId}`);
    
    // Trouver le customer_id depuis le user_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    // Récupérer le devis
    const quote = await Quote.findOne({
      where: { 
        id: quoteId,
        customerId: customerProfile.id 
      },
      include: [{ model: QuoteItem, as: 'items' }]
    });
    
    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Devis non trouvé',
      });
    }
    
    // Formater les données
    const formattedQuote = {
      id: quote.id.toString(),
      reference: quote.reference,
      title: quote.notes || 'Devis',
      description: quote.termsAndConditions || '',
      amount: parseFloat(quote.total),
      status: quote.status,
      validUntil: quote.expiryDate,
      createdAt: quote.created_at || quote.createdAt,
      issueDate: quote.issueDate,
      expiryDate: quote.expiryDate,
      subtotal: parseFloat(quote.subtotal),
      taxAmount: parseFloat(quote.taxAmount),
      discountAmount: parseFloat(quote.discountAmount),
      items: quote.items || []
    };
    
    res.json({
      success: true,
      data: formattedQuote,
      message: 'Détails du devis récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting quote details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du devis',
      error: error.message
    });
  }
});

// Route POST /complaints déjà définie plus haut (ligne 233)

router.post('/complaints', async (req, res) => {
  console.log('🔵 POST /api/customer/complaints - Body:', req.body);
  
  try {
    const { Complaint, CustomerProfile } = require('../models');
    const userId = req.user.id;
    
    console.log('👤 User ID:', userId);
    
    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    if (!customerProfile) {
      console.log('❌ Profil client non trouvé pour user_id:', userId);
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    console.log('✅ Customer profile found:', customerProfile.id);
    
    const {
      title,
      description,
      priority = 'medium',
      relatedTo,
      relatedId
    } = req.body;
    
    if (!title || !description) {
      console.log('❌ Titre ou description manquant');
      return res.status(400).json({
        success: false,
        message: 'Le titre et la description sont requis',
      });
    }
    
    // Générer une référence unique
    const timestamp = Date.now();
    const reference = `REC-${timestamp}`;
    
    console.log('📝 Creating complaint with data:', {
      reference,
      customerId: customerProfile.id,
      subject: title,
      description,
      priority
    });
    
    const complaint = await Complaint.create({
      reference,
      customerId: customerProfile.id,
      subject: title,
      description,
      priority,
      status: 'open'
    });
    
    console.log(`✅ Réclamation ${reference} créée:`, complaint.toJSON());
    
    // 🔔 Envoyer la notification aux admins
    try {
      const { notifyNewComplaint } = require('../services/notificationHelpers');
      const { User } = require('../models');
      
      // Récupérer le user complet pour la notification
      const user = await User.findByPk(userId);
      if (user) {
        const customerData = {
          id: user.id,
          first_name: user.first_name || customerProfile.first_name,
          last_name: user.last_name || customerProfile.last_name,
          email: user.email
        };
        
        // Créer un objet complaint avec customer pour notifyNewComplaint
        const complaintForNotif = {
          ...complaint.toJSON(),
          customer: {
            first_name: customerProfile.first_name,
            last_name: customerProfile.last_name,
            user: user
          }
        };
        
        await notifyNewComplaint(complaintForNotif, customerData);
        console.log('✅ Notification envoyée aux admins pour réclamation', reference);
      } else {
        console.log('⚠️  User non trouvé pour notification, ID:', userId);
      }
    } catch (notifError) {
      console.error('❌ Erreur envoi notification réclamation:', notifError);
      // Ne pas bloquer la création de réclamation si notification échoue
    }
    
    const response = {
      success: true,
      message: 'Réclamation créée avec succès',
      data: complaint.toJSON()
    };
    
    console.log('📤 Sending response:', response);
    
    res.json(response);
  } catch (error) {
    console.error('❌ Error creating complaint:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la réclamation',
      error: error.message
    });
  }
});

router.get('/complaints/:id', async (req, res) => {
  try {
    const { Complaint, ComplaintNote, User } = require('../models');
    const { id } = req.params;
    const userId = req.user.id;
    
    console.log(`🔍 GET /api/customer/complaints/${id} - User ID:`, userId);
    
    const { CustomerProfile } = require('../models');
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    // Récupérer la réclamation avec les notes
    const complaint = await Complaint.findOne({
      where: { 
        id,
        customerId: customerProfile.id 
      },
      include: [
        {
          model: ComplaintNote,
          as: 'notes',
          where: { isInternal: false }, // Seulement les notes visibles par le client
          required: false,
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'first_name', 'last_name', 'role']
            }
          ],
          order: [['created_at', 'ASC']]
        }
      ]
    });
    
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Réclamation non trouvée',
      });
    }
    
    console.log(`✅ Complaint found with ${complaint.notes?.length || 0} notes`);
    
    res.json({
      success: true,
      message: 'Détails de la réclamation récupérés',
      data: complaint
    });
  } catch (error) {
    console.error('❌ Error getting complaint details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la réclamation',
      error: error.message
    });
  }
});

// POST /api/customer/complaints/:id/notes - Ajouter une note à une réclamation
router.post('/complaints/:id/notes', async (req, res) => {
  try {
    const { Complaint, ComplaintNote, User, CustomerProfile } = require('../models');
    const { id } = req.params;
    const { note } = req.body;
    const userId = req.user.id;
    
    console.log(`📝 POST /api/customer/complaints/${id}/notes - User ID:`, userId);
    
    if (!note || note.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Le contenu de la note est requis',
      });
    }
    
    // Vérifier que la réclamation appartient au client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    const complaint = await Complaint.findOne({
      where: { 
        id,
        customerId: customerProfile.id 
      }
    });
    
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Réclamation non trouvée',
      });
    }
    
    // Créer la note
    const complaintNote = await ComplaintNote.create({
      complaintId: id,
      userId: userId,
      note: note.trim(),
      isInternal: false // Note visible par tous
    });
    
    // Récupérer la note avec les informations de l'utilisateur
    const noteWithUser = await ComplaintNote.findByPk(complaintNote.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'first_name', 'last_name', 'role']
        }
      ]
    });
    
    console.log(`✅ Note added to complaint ${id}`);
    
    res.status(201).json({
      success: true,
      message: 'Note ajoutée avec succès',
      data: noteWithUser
    });
  } catch (error) {
    console.error('❌ Error adding note to complaint:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'ajout de la note',
      error: error.message
    });
  }
});

// === API REST pour gestion des clients (ADMIN UNIQUEMENT) ===
// Ces routes doivent être à la fin pour éviter les conflits avec les routes spécifiques

// Liste paginée des clients
router.get('/', authorize('admin'), listCustomers);
// Création d'un client
router.post('/', authorize('admin'), createCustomer);
// Détail d'un client
router.get('/:id', authorize('admin'), getCustomer);
// Mise à jour d'un client
router.put('/:id', authorize('admin'), updateCustomer);
// Suppression d'un client
router.delete('/:id', authorize('admin'), deleteCustomer);

module.exports = router;
