const express = require('express');
const router = express.Router();
const { MaintenanceOffer, User } = require('../models');
const { authenticate, authorize, adminOnly } = require('../middleware/auth');
const notificationService = require('../services/notificationService');

// GET all maintenance offers (admin and manager)
router.get('/', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    console.log('🔍 GET /api/maintenance-offers');
    
    const offers = await MaintenanceOffer.findAll({
      order: [['price', 'ASC']]
    });
    
    // Transformer les offres pour s'assurer que features est un tableau
    const transformedOffers = offers.map(offer => {
      const plainOffer = offer.toJSON();
      // S'assurer que features est un tableau (parser si c'est une chaîne JSON)
      if (typeof plainOffer.features === 'string') {
        try {
          plainOffer.features = JSON.parse(plainOffer.features);
        } catch {
          plainOffer.features = [];
        }
      }
      plainOffer.features = plainOffer.features || [];
      return plainOffer;
    });
    
    console.log(`✅ Found ${transformedOffers.length} maintenance offers`);
    
    res.json({
      success: true,
      data: transformedOffers,
      message: 'Offres récupérées avec succès'
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

// GET maintenance offer by ID (admin only)
router.get('/:id', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🔍 GET /api/maintenance-offers/${id}`);
    
    const offer = await MaintenanceOffer.findByPk(id);
    
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre non trouvée'
      });
    }
    
    // Transformer l'offre pour s'assurer que features est un tableau
    const plainOffer = offer.toJSON();
    if (typeof plainOffer.features === 'string') {
      try {
        plainOffer.features = JSON.parse(plainOffer.features);
      } catch {
        plainOffer.features = [];
      }
    }
    plainOffer.features = plainOffer.features || [];
    
    console.log(`✅ Offer found: ${plainOffer.title}, features: ${plainOffer.features.length}`);
    
    res.json({
      success: true,
      data: plainOffer,
      message: 'Offre récupérée avec succès'
    });
  } catch (error) {
    console.error('❌ Error getting maintenance offer:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'offre',
      error: error.message
    });
  }
});

// POST create new maintenance offer (admin only)
router.post('/', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { title, description, price, duration, features, isActive } = req.body;
    
    console.log('📝 POST /api/maintenance-offers - Creating new offer:', title);
    
    if (!title || !price) {
      return res.status(400).json({
        success: false,
        message: 'Le titre et le prix sont requis'
      });
    }
    
    const offer = await MaintenanceOffer.create({
      title,
      description,
      price,
      duration,
      features: features || [],
      isActive: isActive !== undefined ? isActive : true
    });
    
    console.log(`✅ Offer created: ${offer.title} (ID: ${offer.id})`);
    
    // Notifier tous les clients ET admins si l'offre est active
    if (offer.isActive) {
      try {
        // Notifier tous les clients
        const customers = await User.findAll({
          where: { role: 'customer', status: 'active' },
          attributes: ['id']
        });
        
        const customerIds = customers.map(customer => customer.id);
        
        if (customerIds.length > 0) {
          await notificationService.createBulk(customerIds, {
            type: 'maintenance_offer_created',
            title: '🎉 Nouvelle offre d\'entretien disponible !',
            message: `${offer.title} - ${offer.price} FCFA/${offer.duration}`,
            data: {
              offer_id: offer.id,
              offer_title: offer.title,
              offer_price: offer.price,
              offer_duration: offer.duration
            },
            priority: 'medium',
            actionUrl: '/maintenance-offers'
          });
          console.log(`📱 Notification envoyée à ${customerIds.length} client(s) pour la nouvelle offre`);
        }
        
        // Notifier aussi les admins
        await notificationService.notifyAdmins({
          type: 'maintenance_offer_created',
          title: '✅ Offre d\'entretien créée',
          message: `L'offre "${offer.title}" a été créée et activée`,
          data: {
            offer_id: offer.id,
            offer_title: offer.title,
            offer_price: offer.price,
            offer_duration: offer.duration
          },
          priority: 'low',
          actionUrl: '/maintenance-offers'
        });
        console.log(`📱 Notification envoyée aux admins pour la nouvelle offre`);
      } catch (notifError) {
        console.error('❌ Erreur envoi notification création offre:', notifError.message);
      }
    }
    
    res.status(201).json({
      success: true,
      data: offer,
      message: 'Offre créée avec succès'
    });
  } catch (error) {
    console.error('❌ Error creating maintenance offer:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de l\'offre',
      error: error.message
    });
  }
});

// PUT update maintenance offer (admin only)
router.put('/:id', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, price, duration, features, isActive } = req.body;
    
    console.log(`📝 PUT /api/maintenance-offers/${id} - Updating offer`);
    
    const offer = await MaintenanceOffer.findByPk(id);
    
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre non trouvée'
      });
    }
    
    await offer.update({
      title: title || offer.title,
      description: description !== undefined ? description : offer.description,
      price: price || offer.price,
      duration: duration || offer.duration,
      features: features !== undefined ? features : offer.features,
      isActive: isActive !== undefined ? isActive : offer.isActive
    });
    
    console.log(`✅ Offer updated: ${offer.title}`);
    
    res.json({
      success: true,
      data: offer,
      message: 'Offre modifiée avec succès'
    });
  } catch (error) {
    console.error('❌ Error updating maintenance offer:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la modification de l\'offre',
      error: error.message
    });
  }
});

// PATCH toggle active status (admin only)
router.patch('/:id/toggle', authenticate, authorize('admin', 'manager'), async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;
    
    console.log(`📝 PATCH /api/maintenance-offers/${id}/toggle - isActive: ${isActive}`);
    
    const offer = await MaintenanceOffer.findByPk(id);
    
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre non trouvée'
      });
    }
    
    const wasInactive = !offer.isActive;
    await offer.update({ isActive });
    
    console.log(`✅ Offer ${isActive ? 'activated' : 'deactivated'}: ${offer.title}`);
    
    // Notifier tous les clients ET admins si l'offre est activée
    if (isActive && wasInactive) {
      try {
        // Notifier tous les clients
        const customers = await User.findAll({
          where: { role: 'customer', status: 'active' },
          attributes: ['id']
        });
        
        const customerIds = customers.map(customer => customer.id);
        
        if (customerIds.length > 0) {
          await notificationService.createBulk(customerIds, {
            type: 'maintenance_offer_activated',
            title: '✨ Offre d\'entretien maintenant disponible !',
            message: `${offer.title} est maintenant activée - ${offer.price} FCFA/${offer.duration}`,
            data: {
              offer_id: offer.id,
              offer_title: offer.title,
              offer_price: offer.price,
              offer_duration: offer.duration
            },
            priority: 'medium',
            actionUrl: '/maintenance-offers'
          });
          console.log(`📱 Notification envoyée à ${customerIds.length} client(s) pour l'activation de l'offre`);
        }
        
        // Notifier aussi les admins
        await notificationService.notifyAdmins({
          type: 'maintenance_offer_activated',
          title: '✅ Offre d\'entretien activée',
          message: `L'offre "${offer.title}" a été activée`,
          data: {
            offer_id: offer.id,
            offer_title: offer.title,
            offer_price: offer.price,
            offer_duration: offer.duration
          },
          priority: 'low',
          actionUrl: '/maintenance-offers'
        });
        console.log(`📱 Notification envoyée aux admins pour l'activation de l'offre`);
      } catch (notifError) {
        console.error('❌ Erreur envoi notification activation offre:', notifError.message);
      }
    }
    
    res.json({
      success: true,
      data: offer,
      message: `Offre ${isActive ? 'activée' : 'désactivée'} avec succès`
    });
  } catch (error) {
    console.error('❌ Error toggling maintenance offer:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la modification de l\'offre',
      error: error.message
    });
  }
});

// DELETE maintenance offer (admin only - suppression réservée aux admins)
router.delete('/:id', authenticate, adminOnly, async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🗑️ DELETE /api/maintenance-offers/${id}`);
    
    const offer = await MaintenanceOffer.findByPk(id);
    
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre non trouvée'
      });
    }
    
    await offer.destroy();
    
    console.log(`✅ Offer deleted: ${offer.title}`);
    
    res.json({
      success: true,
      message: 'Offre supprimée avec succès'
    });
  } catch (error) {
    console.error('❌ Error deleting maintenance offer:', error);
    
    // Si l'offre est référencée par des souscriptions/interventions, la désactiver au lieu de la supprimer
    if (error.name === 'SequelizeForeignKeyConstraintError') {
      try {
        const offer = await MaintenanceOffer.findByPk(req.params.id);
        if (offer) {
          await offer.update({ isActive: false });
          return res.json({ 
            success: true,
            message: 'Cette offre est utilisée par des souscriptions ou interventions. Elle a été désactivée au lieu d\'être supprimée.',
            softDeleted: true
          });
        }
      } catch (softDeleteError) {
        console.error('Erreur lors de la désactivation de l\'offre:', softDeleteError);
      }
    }
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de l\'offre',
      error: error.message
    });
  }
});

module.exports = router;
