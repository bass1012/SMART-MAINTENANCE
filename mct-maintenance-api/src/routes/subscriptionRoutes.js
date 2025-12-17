const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');

// GET /api/subscriptions - Récupérer toutes les souscriptions (admin)
router.get('/', authenticate, authorize('admin'), async (req, res) => {
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
router.get('/:id', authenticate, authorize('admin'), async (req, res) => {
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

// PATCH /api/subscriptions/:id/cancel - Annuler une souscription (admin)
router.patch('/:id/cancel', authenticate, authorize('admin'), async (req, res) => {
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
router.patch('/:id/payment-status', authenticate, authorize('admin'), async (req, res) => {
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

// DELETE /api/subscriptions/:id - Supprimer une souscription (admin)
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
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
    
    // Vérifier que la souscription peut être supprimée (annulée ou échec de paiement)
    if (subscription.status === 'active' && subscription.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Impossible de supprimer une souscription active et payée. Annulez-la d\'abord.'
      });
    }
    
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
router.post('/:id/renew', authenticate, authorize('admin'), async (req, res) => {
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
