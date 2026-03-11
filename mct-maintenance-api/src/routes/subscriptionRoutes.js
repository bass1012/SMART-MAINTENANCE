const express = require('express');
const router = express.Router();
const { authenticate, authorize, adminOnly } = require('../middleware/auth');

// GET /api/subscriptions - Récupérer toutes les souscriptions (admin/manager)
router.get('/', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer, User } = require('../models');
    
    console.log('🔍 GET /api/subscriptions - Admin fetching all subscriptions');
    
    const subscriptions = await Subscription.findAll({
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'description', 'price', 'duration', 'features']
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ Found ${subscriptions.length} subscriptions`);
    
    res.json({
      success: true,
      data: subscriptions
    });
  } catch (error) {
    console.error('❌ Error getting subscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des souscriptions',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/subscriptions/:id - Récupérer une souscription par ID (admin)
router.get('/:id', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer, User } = require('../models');
    const { id } = req.params;
    
    console.log(`🔍 GET /api/subscriptions/${id}`);
    
    const subscription = await Subscription.findByPk(id, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'description', 'price', 'duration', 'features']
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
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error getting subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/subscriptions - Créer une souscription à la demande (admin)
router.post('/', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription, CustomerProfile, Equipment } = require('../models');
    const { customer_id, equipment_id, equipment_count = 1, contract_type = 'on_demand', status = 'active' } = req.body;
    
    console.log('📝 POST /api/subscriptions - Admin creating subscription');
    console.log('Body:', req.body);
    
    // Vérifier que le client existe
    const customer = await CustomerProfile.findByPk(customer_id);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Client non trouvé'
      });
    }
    
    // Vérifier que l'équipement existe (optionnel)
    if (equipment_id) {
      const equipment = await Equipment.findByPk(equipment_id);
      if (!equipment) {
        return res.status(404).json({
          success: false,
          message: 'Équipement non trouvé'
        });
      }
    }
    
    // Calculer dates
    const startDate = new Date();
    const endDate = new Date();
    endDate.setFullYear(endDate.getFullYear() + 1);
    
    // Créer la souscription
    const subscription = await Subscription.create({
      customer_id,
      equipment_id,
      equipment_count,
      equipment_used: 0,
      contract_type,
      status,
      payment_status: 'paid', // Admin créé = payé
      start_date: startDate,
      end_date: endDate,
      visits_total: 1,
      visits_completed: 0,
      visit_interval_months: 12,
    });
    
    console.log(`✅ Subscription ${subscription.id} created by admin (type: ${contract_type})`);
    
    res.status(201).json({
      success: true,
      message: `Contrat ${contract_type === 'on_demand' ? 'à la demande' : 'programmé'} créé avec succès`,
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error creating subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// PATCH /api/subscriptions/:id - Modifier une souscription (admin)
router.patch('/:id', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    const updateData = req.body;
    
    console.log(`📝 PATCH /api/subscriptions/${id} - Admin updating subscription`);
    console.log('Update data:', updateData);
    
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // Champs autorisés à modifier
    const allowedFields = [
      'equipment_description', 'equipment_model', 'equipment_count',
      'visits_total', 'visit_interval_months', 'status', 'price'
    ];
    
    const filteredData = {};
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        filteredData[field] = updateData[field];
      }
    }
    
    await subscription.update(filteredData);
    
    console.log(`✅ Subscription ${id} updated`);
    
    res.json({
      success: true,
      message: 'Souscription modifiée avec succès',
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error updating subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la modification de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// PATCH /api/subscriptions/:id/cancel - Annuler une souscription (admin)
router.patch('/:id/cancel', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    
    console.log(`📝 PATCH /api/subscriptions/${id}/cancel - Admin`);
    
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    if (subscription.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'La souscription est déjà annulée'
      });
    }
    
    await subscription.update({ status: 'cancelled' });
    
    console.log(`✅ Subscription ${id} cancelled by admin`);
    
    res.json({
      success: true,
      message: 'Souscription annulée avec succès',
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error cancelling subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// PATCH /api/subscriptions/:id/payment-status - Mettre à jour le statut de paiement (admin)
router.patch('/:id/payment-status', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    const { payment_status } = req.body;
    
    console.log(`📝 PATCH /api/subscriptions/${id}/payment-status - New status: ${payment_status}`);
    
    // Valider le statut
    const validStatuses = ['pending', 'paid', 'failed'];
    if (!validStatuses.includes(payment_status)) {
      return res.status(400).json({
        success: false,
        message: 'Statut de paiement invalide. Doit être: pending, paid, ou failed'
      });
    }
    
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    const oldPaymentStatus = subscription.payment_status;
    
    await subscription.update({ payment_status });
    
    // Si le paiement passe à "paid", activer la souscription et envoyer les notifications
    if (payment_status === 'paid' && oldPaymentStatus !== 'paid') {
      // Activer la souscription
      await subscription.update({ status: 'active' });
      
      // 🔔 Envoyer les notifications
      try {
        const { MaintenanceOffer, User, CustomerProfile } = require('../models');
        const { notifyNewSubscription } = require('../services/notificationHelpers');
        
        // Charger l'offre et le client
        const offer = await MaintenanceOffer.findByPk(subscription.maintenance_offer_id);
        const customerProfile = await CustomerProfile.findOne({
          where: { user_id: subscription.customer_id }, // CORRECTION: user_id au lieu de id
          include: [{ model: User, as: 'user' }]
        });
        
        if (offer && customerProfile && customerProfile.user) {
          const customer = {
            id: customerProfile.user.id,
            first_name: customerProfile.first_name,
            last_name: customerProfile.last_name,
            email: customerProfile.user.email
          };
          
          // Notifier admins ET client
          await notifyNewSubscription(subscription, customer, offer);
          console.log(`✅ Notifications souscription payée envoyées (admins + client)`);
        }
      } catch (notifError) {
        console.error('❌ Erreur notification paiement confirmé:', notifError);
      }
    }
    
    console.log(`✅ Subscription ${id} payment status updated to ${payment_status}`);
    
    res.json({
      success: true,
      message: 'Statut de paiement mis à jour avec succès',
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error updating payment status:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut de paiement',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// PUT /api/subscriptions/:id - Mettre à jour une souscription (admin)
router.put('/:id', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    const { status, payment_status, visits_total, visit_interval_months, end_date } = req.body;
    
    console.log(`✏️ PUT /api/subscriptions/${id} - Admin`);
    
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // Préparer les champs à mettre à jour
    const updateData = {};
    if (status !== undefined) updateData.status = status;
    if (payment_status !== undefined) updateData.payment_status = payment_status;
    if (visits_total !== undefined) updateData.visits_total = visits_total;
    if (visit_interval_months !== undefined) updateData.visit_interval_months = visit_interval_months;
    if (end_date !== undefined) updateData.end_date = end_date;
    
    await subscription.update(updateData);
    
    console.log(`✅ Subscription ${id} updated:`, updateData);
    
    res.json({
      success: true,
      message: 'Souscription mise à jour avec succès',
      data: subscription
    });
  } catch (error) {
    console.error('❌ Error updating subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// DELETE /api/subscriptions/:id - Supprimer une souscription (admin seulement)
router.delete('/:id', authenticate, adminOnly, async (req, res) => {
  try {
    const { Subscription } = require('../models');
    const { id } = req.params;
    
    console.log(`🗑️ DELETE /api/subscriptions/${id} - Admin`);
    
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // Vérifier que la souscription peut être supprimée
    // Empêcher uniquement la suppression des souscriptions actives et payées
    if (subscription.status === 'active' && subscription.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Impossible de supprimer une souscription active et payée. Annulez-la d\'abord.'
      });
    }
    
    // Permettre suppression pour: pending_payment, cancelled, expired, pending payment_status
    console.log(`📋 Subscription status: ${subscription.status}, payment_status: ${subscription.payment_status}`);
    
    await subscription.destroy();
    
    console.log(`✅ Subscription ${id} deleted`);
    
    res.json({
      success: true,
      message: 'Souscription supprimée avec succès'
    });
  } catch (error) {
    console.error('❌ Error deleting subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/subscriptions/:id/renew - Renouveler une souscription (admin)
router.post('/:id/renew', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer } = require('../models');
    const { id } = req.params;
    
    console.log(`🔄 POST /api/subscriptions/${id}/renew - Admin`);
    
    const oldSubscription = await Subscription.findByPk(id, {
      include: [
        {
          model: MaintenanceOffer,
          as: 'offer'
        }
      ]
    });
    
    if (!oldSubscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // Vérifier que la souscription peut être renouvelée (expirée ou annulée)
    if (oldSubscription.status === 'active') {
      return res.status(400).json({
        success: false,
        message: 'Impossible de renouveler une souscription active. Attendez son expiration ou annulez-la.'
      });
    }
    
    // Vérifier que l'offre existe toujours et est active
    const offer = await MaintenanceOffer.findByPk(oldSubscription.maintenance_offer_id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'L\'offre d\'entretien n\'existe plus'
      });
    }
    
    if (!offer.isActive) {
      return res.status(400).json({
        success: false,
        message: 'L\'offre d\'entretien n\'est plus active'
      });
    }
    
    // Créer une nouvelle souscription
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + offer.duration);
    
    const newSubscription = await Subscription.create({
      customer_id: oldSubscription.customer_id,
      maintenance_offer_id: oldSubscription.maintenance_offer_id,
      status: 'active',
      start_date: startDate,
      end_date: endDate,
      price: offer.price,
      payment_status: 'pending'
    });
    
    console.log(`✅ Subscription ${id} renewed - New ID: ${newSubscription.id}`);
    
    // Recharger avec les relations
    const renewedSubscription = await Subscription.findByPk(newSubscription.id, {
      include: [
        {
          model: MaintenanceOffer,
          as: 'offer'
        }
      ]
    });
    
    res.json({
      success: true,
      message: 'Souscription renouvelée avec succès',
      data: renewedSubscription
    });
  } catch (error) {
    console.error('❌ Error renewing subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du renouvellement de la souscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;
