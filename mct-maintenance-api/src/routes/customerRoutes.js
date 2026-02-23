const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const customerController = require('../controllers/customerController');
const { Contract, User, InstallationService, RepairService } = require('../models');
const { 
  listCustomers, 
  getCustomer, 
  createCustomer, 
  updateCustomer, 
  deleteCustomer,
  deactivateCustomer,
  purgeDeletedCustomers
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
    const { Quote, CustomerProfile, Order, OrderItem, Intervention, User } = require('../models');
    const { notifyQuoteAccepted } = require('../services/notificationHelpers');
    const notificationService = require('../services/notificationService');
    const userId = req.user.id;
    const quoteId = req.params.id;
    const { execute_now, scheduled_date, second_contact } = req.body;
    
    console.log(`✅ Acceptation du devis ${quoteId} par user_id: ${userId}`);
    console.log('📅 Paramètres:', { execute_now, scheduled_date, second_contact });
    
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

    // Déterminer la date d'exécution
    let scheduledDateTime = null;
    if (execute_now === true) {
      scheduledDateTime = new Date();
      console.log('⚡ Exécution immédiate demandée');
    } else if (scheduled_date) {
      scheduledDateTime = new Date(scheduled_date);
      console.log('📅 Intervention planifiée pour:', scheduledDateTime);
    }

    // Déterminer le statut de paiement
    const paymentStatus = execute_now ? 'pending' : 'deferred';
    
    // Mettre à jour le statut du devis avec tous les champs
    await quote.update({ 
      status: 'accepted',
      scheduled_date: scheduledDateTime,
      execute_now: execute_now || false,
      second_contact: second_contact || null,
      payment_status: paymentStatus
    });
    
    console.log(`✅ Devis ${quoteId} accepté (paiement: ${paymentStatus})`);
    
    // 📬 Notifier les admins de l'acceptation
    try {
      await notifyQuoteAccepted(quote, customerProfile);
      console.log('✅ Notification envoyée aux admins : devis accepté');
    } catch (notifError) {
      console.error('⚠️  Erreur notification acceptation devis:', notifError.message);
    }

    // 🔧 Si exécution immédiate, notifier le technicien du diagnostic et mettre à jour l'intervention
    if (execute_now === true && quote.intervention_id) {
      try {
        // Note: intervention.technician_id référence User.id directement
        const intervention = await Intervention.findByPk(quote.intervention_id, {
          include: [{
            model: User,
            as: 'technician'
          }]
        });
        
        if (intervention && intervention.technician_id) {
          // 🔄 Exécution immédiate = technicien déjà sur place → passer à execution_confirmed
          // Le technicien devra cliquer sur "Exécuter la tâche" pour passer à in_progress
          await intervention.update({
            status: 'execution_confirmed',  // Technicien doit confirmer le démarrage de l'exécution
            intervention_type: 'execution', // Nouveau type: exécution suite au diagnostic
            notes: `${intervention.notes || ''}\n\n[${new Date().toISOString()}] ⚡ EXÉCUTION IMMÉDIATE - Client a confirmé - Devis ${quote.reference} accepté - En attente démarrage technicien`
          });
          
          console.log(`🔄 Intervention ${intervention.id} mise à jour: status = execution_confirmed (exécution immédiate - en attente démarrage)`);
          
          // L'id du technicien est directement dans intervention.technician_id (= User.id)
          const technicianUserId = intervention.technician_id;
          const technicianName = intervention.technician?.firstName || 'Technicien';
          
          await notificationService.create({
            userId: technicianUserId,
            type: 'quote_execution_confirmed',
            title: '✅ Exécution confirmée',
            message: `Le client a accepté le devis ${quote.reference} et demande une exécution immédiate. Vous pouvez procéder à l'intervention.`,
            data: {
              quote_id: quote.id,
              quote_reference: quote.reference,
              intervention_id: intervention.id,
              execute_now: true
            },
            priority: 'high',
            actionUrl: `/interventions/${intervention.id}`
          });
          
          console.log(`📲 Notification envoyée au technicien ${technicianName} (user_id: ${technicianUserId})`);
        } else {
          console.log('⚠️  Aucun technicien assigné à cette intervention');
        }
      } catch (techNotifError) {
        console.error('⚠️  Erreur notification technicien:', techNotifError.message);
      }
    }

    // 🛒 Créer automatiquement une commande à partir du devis accepté
    try {
      // Recharger le devis complet avec tous les champs
      const fullQuote = await Quote.findByPk(quoteId);
      
      console.log('🔍 DEBUG Quote pour création commande:', {
        id: fullQuote.id,
        customerId: fullQuote.customerId,
        customer_id: fullQuote.customer_id,
        total: fullQuote.total,
        totalAmount: fullQuote.totalAmount,
        subtotal: fullQuote.subtotal,
        reference: fullQuote.reference,
        line_items: typeof fullQuote.line_items,
        lineItems: typeof fullQuote.lineItems
      });
      
      // Parser line_items si c'est un string JSON
      let lineItems = fullQuote.line_items || fullQuote.lineItems;
      if (typeof lineItems === 'string') {
        try {
          lineItems = JSON.parse(lineItems);
        } catch (e) {
          lineItems = [];
        }
      }
      if (!Array.isArray(lineItems)) {
        lineItems = [];
      }

      // Générer une référence unique pour la commande
      const orderReference = `CMD-${Date.now()}-${fullQuote.id}`;

      // Extraire les valeurs avec fallback
      const customerId = fullQuote.customerId || fullQuote.customer_id;
      const totalAmount = fullQuote.total || fullQuote.totalAmount || fullQuote.subtotal || 0;

      console.log('🔍 Valeurs pour création commande:', {
        customerId,
        totalAmount,
        orderReference
      });

      // Créer la commande
      const order = await Order.create({
        reference: orderReference,
        customerId: customerId,
        quoteId: fullQuote.id,
        totalAmount: totalAmount,
        status: execute_now ? 'pending' : 'scheduled',
        paymentStatus: execute_now ? 'pending' : 'deferred',
        paymentMethod: null,
        lineItems: JSON.stringify(lineItems),
        notes: execute_now 
          ? `Commande créée automatiquement - Exécution immédiate`
          : `Commande créée automatiquement - Intervention planifiée, paiement différé`,
        scheduledDate: scheduledDateTime
      });

      // Mettre à jour le statut de paiement du devis
      await fullQuote.update({ payment_status: execute_now ? 'pending' : 'deferred' });

      console.log(`✅ Commande ${orderReference} créée automatiquement pour le devis ${fullQuote.reference}`);
    } catch (orderError) {
      console.error('⚠️  Erreur création commande automatique:', orderError.message);
      // On ne bloque pas l'acceptation si la création de commande échoue
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
      items: quote.items || [],
      // Champs pour le paiement différé
      payment_status: quote.payment_status,
      scheduled_date: quote.scheduled_date,
      execute_now: quote.execute_now,
      second_contact: quote.second_contact
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
    const { Intervention, User, TechnicianProfile, CustomerProfile } = require('../models');
    const { Op } = require('sequelize');
    const userId = req.user.id;

    console.log(`📋 Client user_id ${userId}: Récupération des rapports de maintenance`);

    // Récupérer le CustomerProfile pour obtenir le customer_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }

    const customerId = customerProfile.id;
    console.log(`🔄 Conversion User.id ${userId} → CustomerProfile.id ${customerId} pour rapports`);

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
        // Mesures techniques
        pression: reportData.pression || '',
        temperature: reportData.temperature || '',
        intensite: reportData.intensite || '',
        tension: reportData.tension || '',
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

// Détails d'un rapport de maintenance spécifique
router.get('/maintenance-reports/:reportId', async (req, res) => {
  try {
    const { Intervention, User, TechnicianProfile, CustomerProfile, InterventionImage } = require('../models');
    const { Op } = require('sequelize');
    const userId = req.user.id;
    const reportId = req.params.reportId;

    console.log(`📋 Client user_id ${userId}: Récupération du rapport ${reportId}`);

    // Récupérer le CustomerProfile pour obtenir le customer_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }

    const customerId = customerProfile.id;

    // Récupérer l'intervention avec rapport
    const intervention = await Intervention.findOne({
      where: {
        id: reportId,
        customer_id: customerId,
        report_submitted_at: { [Op.not]: null }
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
        },
        {
          model: InterventionImage,
          as: 'images',
          attributes: ['id', 'image_url', 'image_type', 'created_at']
        }
      ],
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Rapport non trouvé',
      });
    }

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

    // Extraire les URLs des images
    const imageUrls = intervention.images ? intervention.images.map(img => img.image_url) : [];

    const report = {
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
      photosCount: imageUrls.length,
      imageUrls: imageUrls,
      createdAt: intervention.created_at,
      // Mesures techniques
      pression: reportData.pression || '',
      temperature: reportData.temperature || '',
      intensite: reportData.intensite || '',
      tension: reportData.tension || '',
    };

    console.log(`✅ Rapport ${reportId} récupéré`);

    res.json({
      success: true,
      data: report,
      message: 'Détails du rapport récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting maintenance report details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du rapport',
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
    const { Subscription, MaintenanceOffer, InstallationService, RepairService, User } = require('../models');
    const { maintenance_offer_id, installation_service_id, repair_service_id } = req.body;
    const customerId = req.user.id;
    
    console.log(`📝 POST /api/customer/subscriptions - Customer ${customerId}`);
    
    let serviceData = null;
    let serviceType = null;
    let duration = 1; // Par défaut 1 mois pour les services ponctuels
    
    // Déterminer le type de service et récupérer ses données
    if (maintenance_offer_id) {
      serviceType = 'maintenance';
      serviceData = await MaintenanceOffer.findByPk(maintenance_offer_id);
      
      if (!serviceData) {
        return res.status(404).json({
          success: false,
          message: 'Offre d\'entretien non trouvée'
        });
      }
      
      if (!serviceData.isActive) {
        return res.status(400).json({
          success: false,
          message: 'Cette offre n\'est plus active'
        });
      }
      
      duration = serviceData.duration;
      console.log(`   Type: Maintenance Offer ${maintenance_offer_id}`);
    } else if (installation_service_id) {
      serviceType = 'installation';
      serviceData = await InstallationService.findByPk(installation_service_id);
      
      if (!serviceData) {
        return res.status(404).json({
          success: false,
          message: 'Service d\'installation non trouvé'
        });
      }
      
      if (!serviceData.isActive) {
        return res.status(400).json({
          success: false,
          message: 'Ce service n\'est plus actif'
        });
      }
      
      console.log(`   Type: Installation Service ${installation_service_id}`);
    } else if (repair_service_id) {
      serviceType = 'repair';
      serviceData = await RepairService.findByPk(repair_service_id);
      
      if (!serviceData) {
        return res.status(404).json({
          success: false,
          message: 'Service de réparation non trouvé'
        });
      }
      
      if (!serviceData.isActive) {
        return res.status(400).json({
          success: false,
          message: 'Ce service n\'est plus actif'
        });
      }
      
      console.log(`   Type: Repair Service ${repair_service_id}`);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Aucun service spécifié (maintenance_offer_id, installation_service_id ou repair_service_id requis)'
      });
    }
    
    // Calculer les dates
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + duration);
    
    // Créer la souscription avec les bons champs selon le type
    const subscriptionData = {
      customer_id: customerId,
      status: 'active',
      start_date: startDate,
      end_date: endDate,
      price: serviceData.price,
      payment_status: 'pending'
    };
    
    if (maintenance_offer_id) {
      subscriptionData.maintenance_offer_id = maintenance_offer_id;
    } else if (installation_service_id) {
      subscriptionData.installation_service_id = installation_service_id;
    } else if (repair_service_id) {
      subscriptionData.repair_service_id = repair_service_id;
    }
    
    const subscription = await Subscription.create(subscriptionData);
    
    console.log(`✅ Subscription created: ${subscription.id} (${serviceType})`);
    
    // 🔔 Envoyer une notification au client
    try {
      const user = await User.findByPk(customerId);
      const notificationService = require('../services/notificationService');
      
      await notificationService.create({
        userId: customerId,
        type: 'subscription_created',
        title: 'Paiement initié',
        message: `Votre souscription à "${serviceData.title}" est en attente de confirmation de paiement`,
        data: {
          subscriptionId: subscription.id,
          serviceName: serviceData.title,
          serviceType: serviceType,
          amount: serviceData.price,
          paymentStatus: 'pending'
        },
        priority: 'medium',
        actionUrl: `/dashboard`
      });
      
      console.log(`✅ Notification envoyée au client`);
      
      // 🔔 Notifier les admins
      await notificationService.notifyAdmins({
        type: 'subscription_created',
        title: '💳 Nouvelle souscription',
        message: `${user.first_name || user.email} a souscrit à "${serviceData.title}" (${serviceData.price} FCFA)`,
        data: {
          subscriptionId: subscription.id,
          customerId: customerId,
          customerName: user.first_name || user.email,
          serviceName: serviceData.title,
          serviceType: serviceType,
          amount: serviceData.price,
          paymentStatus: 'pending'
        },
        priority: 'high',
        actionUrl: `/maintenance-offers`
      });
      
      console.log(`✅ Notification envoyée aux admins`);
    } catch (notifError) {
      console.error('❌ Erreur notification:', notifError);
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
    const { Subscription, MaintenanceOffer, InstallationService, RepairService } = require('../models');
    const customerId = req.user.id;
    
    console.log(`🔍 GET /api/customer/subscriptions - Customer ${customerId}`);
    
    const subscriptions = await Subscription.findAll({
      where: { customer_id: customerId },
      include: [
        {
          model: MaintenanceOffer,
          as: 'offer'
        },
        {
          model: InstallationService,
          as: 'installationService'
        },
        {
          model: RepairService,
          as: 'repairService'
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
    const { Subscription, MaintenanceOffer, InstallationService, RepairService } = require('../models');
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
        },
        {
          model: InstallationService,
          as: 'installationService'
        },
        {
          model: RepairService,
          as: 'repairService'
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
      address,
      maintenance_offer_id
    } = req.body;
    
    console.log(`🔧 Création d'une intervention pour user_id: ${userId}`);
    
    // Créer l'intervention
    const interventionData = {
      customerId: userId,
      equipmentId,
      type: type || 'maintenance',
      status: 'pending',
      priority: priority || 'normal',
      description,
      scheduledDate,
      address
    };
    
    // Ajouter l'offre d'entretien si fournie
    if (maintenance_offer_id) {
      interventionData.maintenanceOfferId = maintenance_offer_id;
    }
    
    const intervention = await Intervention.create(interventionData);
    
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
      quoteId: order.quoteId, // 🆕 Ajouter le quoteId pour lier à un devis
      totalAmount: order.totalAmount,
      status: order.status,
      paymentStatus: order.paymentStatus, // Ajouter le statut de paiement
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
    const { Order, OrderItem, Product, CustomerProfile, User } = require('../models');
    const userId = req.user.id;
    const orderId = req.params.id;
    
    console.log(`📦 Récupération de la commande ${orderId} pour user_id: ${userId}`);
    
    // Trouver le CustomerProfile pour obtenir le customerId
    const customerProfile = await CustomerProfile.findOne({ 
      where: { user_id: userId } 
    });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé'
      });
    }
    
    // Récupérer la commande avec ses items
    const order = await Order.findOne({
      where: { 
        id: orderId,
        customerId: customerProfile.id 
      },
      include: [
        { 
          model: OrderItem, 
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        },
        { 
          model: CustomerProfile, 
          as: 'customer',
          include: [{ model: User, as: 'user' }]
        }
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
      paymentStatus: order.paymentStatus,
      notes: order.notes,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      customer: order.customer?.user ? {
        id: order.customer.user.id,
        firstName: order.customer.first_name || order.customer.user.first_name,
        lastName: order.customer.last_name || order.customer.user.last_name,
        email: order.customer.user.email
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
      items: quote.items || [],
      // Champs pour le paiement différé
      payment_status: quote.payment_status,
      scheduled_date: quote.scheduled_date,
      execute_now: quote.execute_now,
      second_contact: quote.second_contact
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

/**
 * @swagger
 * /customers:
 *   get:
 *     summary: Liste paginée des clients
 *     description: Récupère la liste de tous les clients avec pagination, recherche et filtres (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Numéro de page
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre d'éléments par page
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Recherche par nom, prénom ou email
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, suspended]
 *         description: Filtrer par statut
 *     responses:
 *       200:
 *         description: Liste des clients récupérée avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                     page:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.get('/', authorize('admin'), listCustomers);

/**
 * @swagger
 * /customers:
 *   post:
 *     summary: Créer un nouveau client
 *     description: Crée un nouveau compte client avec profil (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - first_name
 *               - last_name
 *               - phone
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: client@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password123!
 *               first_name:
 *                 type: string
 *                 example: Jean
 *               last_name:
 *                 type: string
 *                 example: Dupont
 *               phone:
 *                 type: string
 *                 example: +221771234567
 *               address:
 *                 type: string
 *                 example: 123 Rue de la Paix, Dakar
 *               city:
 *                 type: string
 *                 example: Dakar
 *     responses:
 *       201:
 *         description: Client créé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.post('/', authorize('admin'), createCustomer);

/**
 * @swagger
 * /customers/{id}:
 *   get:
 *     summary: Détails d'un client
 *     description: Récupère les informations complètes d'un client (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du client
 *     responses:
 *       200:
 *         description: Détails du client récupérés
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/:id', authorize('admin'), getCustomer);

/**
 * @swagger
 * /customers/{id}:
 *   put:
 *     summary: Modifier un client
 *     description: Met à jour les informations d'un client (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du client
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *               phone:
 *                 type: string
 *               address:
 *                 type: string
 *               city:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [active, inactive, suspended]
 *     responses:
 *       200:
 *         description: Client modifié avec succès
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.put('/:id', authorize('admin'), updateCustomer);

/**
 * @swagger
 * /customers/{id}/deactivate:
 *   put:
 *     summary: Désactiver un client (Soft Delete)
 *     description: |
 *       Désactive un compte client sans supprimer les données.
 *       - Status → 'inactive'
 *       - Email → 'deleted_timestamp_original@email.com'
 *       - FCM token → null
 *       - Les données sont conservées pour l'historique (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du client à désactiver
 *     responses:
 *       200:
 *         description: Client désactivé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Client désactivé avec succès
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     email:
 *                       type: string
 *                       example: deleted_1703420000000_client@example.com
 *                     status:
 *                       type: string
 *                       example: inactive
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       500:
 *         $ref: '#/components/responses/InternalServerError'
 */
router.put('/:id/deactivate', authorize('admin'), deactivateCustomer);

/**
 * @swagger
 * /customers/{id}:
 *   delete:
 *     summary: Supprimer COMPLÈTEMENT un client (Hard Delete)
 *     description: |
 *       ⚠️ **ATTENTION : SUPPRESSION IRRÉVERSIBLE**
 *       
 *       Supprime définitivement un client et TOUTES ses données associées dans un ordre précis :
 *       1. Interventions (avec images)
 *       2. Commandes (avec items)
 *       3. Devis (avec items)
 *       4. Réclamations
 *       5. Contrats de maintenance
 *       6. Notifications
 *       7. Profil client (CustomerProfile)
 *       8. Compte utilisateur (User)
 *       
 *       **Gestion transactionnelle :** Rollback automatique en cas d'erreur
 *       
 *       **Recommandation :** Utiliser `/deactivate` (soft delete) par défaut
 *       
 *       (Admin uniquement)
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du client à supprimer définitivement
 *     responses:
 *       200:
 *         description: Client et toutes ses données supprimés avec succès
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/DeleteCustomerResponse'
 *       404:
 *         description: Client non trouvé
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Client non trouvé
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       500:
 *         description: Erreur lors de la suppression (transaction rollback)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Erreur lors de la suppression du client
 *                 error:
 *                   type: string
 */

/**
 * @swagger
 * /api/customers/purge-deleted:
 *   delete:
 *     summary: Supprimer définitivement tous les clients marqués comme supprimés
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Purge réussie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 total:
 *                   type: number
 *                 successCount:
 *                   type: number
 *                 errorCount:
 *                   type: number
 */
router.delete('/purge-deleted', authorize('admin'), purgeDeletedCustomers);

router.delete('/:id', authorize('admin'), deleteCustomer);

module.exports = router;
