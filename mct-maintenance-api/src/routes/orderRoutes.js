const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// All order routes require authentication
router.use(authenticate);


// Customer order routes
const orderController = require('../controllers/order/orderController');
router.get('/', orderController.getAllOrders);
router.get('/:id', orderController.getOrderById);

router.post('/', orderController.createOrder);

router.put('/:id', orderController.updateOrder);

router.delete('/:id', orderController.deleteOrder);

// Order payment routes
router.post('/:id/fineopay-payment', async (req, res) => {
  try {
    const { id } = req.params;
    const { Order, Quote } = require('../models');
    
    // Récupérer la commande avec le devis
    const order = await Order.findByPk(id, {
      include: [{
        model: Quote,
        as: 'quote'
      }]
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande introuvable'
      });
    }

    if (!order.quote) {
      return res.status(404).json({
        success: false,
        message: 'Aucun devis associé à cette commande'
      });
    }

    // Créer un lien de paiement FineoPay
    const axios = require('axios');
    const FINEOPAY_BASE_URL = process.env.FINEOPAY_ENV === 'production' 
      ? 'https://api.fineopay.com/v1/business/dev'
      : 'https://dev.fineopay.com/api/v1/business/dev';

    const callbackUrl = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/fineopay/callback`;

    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title: `Commande #${id} - ${order.quote.title || 'Paiement'}`,
        amount: parseFloat(order.quote.total),
        callbackUrl,
        syncRef: `ORDER_${id}`,
        inputs: [
          {
            key: 'phone',
            type: 'tel',
            label: 'Numéro de téléphone',
            required: true
          }
        ]
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'businessCode': process.env.FINEOPAY_BUSINESS_CODE,
          'apiKey': process.env.FINEOPAY_API_KEY
        }
      }
    );

    if (response.data.success) {
      return res.json({
        success: true,
        message: 'Lien de paiement FineoPay créé',
        data: {
          paymentUrl: response.data.data.checkoutLink,
          amount: order.quote.total
        }
      });
    } else {
      throw new Error('Erreur création lien FineoPay');
    }

  } catch (error) {
    console.error('❌ Erreur création paiement FineoPay:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du lien de paiement',
      error: error.message
    });
  }
});

router.get('/:id/payment-status', (req, res) => {
  res.json({
    success: true,
    message: 'Order payment status retrieved successfully',
    data: {
      status: 'pending',
      paymentMethod: '',
      transactionId: ''
    }
  });
});

// PATCH /api/orders/:id/payment-status - Update payment status (admin only)
router.patch('/:id/payment-status', (req, res, next) => {
  console.log(`🔔 PATCH /api/orders/${req.params.id}/payment-status - Request received`);
  console.log(`   Headers:`, req.headers);
  console.log(`   Body:`, req.body);
  next();
}, authorize('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const { paymentStatus } = req.body;
    
    console.log(`📝 PATCH /api/orders/${id}/payment-status`);
    console.log(`   User ID: ${req.user.id}, Role: ${req.user.role}`);
    console.log(`   Request body:`, req.body);
    console.log(`   New status: ${paymentStatus}`);
    
    const { Order } = require('../models');
    
    // Valider le statut
    const validStatuses = ['pending', 'paid', 'failed', 'refunded'];
    if (!validStatuses.includes(paymentStatus)) {
      console.log(`❌ Invalid payment status: ${paymentStatus}`);
      return res.status(400).json({
        success: false,
        message: 'Statut de paiement invalide. Valeurs autorisées: pending, paid, failed, refunded'
      });
    }
    
    // Trouver la commande
    const order = await Order.findByPk(id);
    
    if (!order) {
      console.log(`❌ Order not found: ${id}`);
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    const oldPaymentStatus = order.paymentStatus;
    
    // Mettre à jour le statut de paiement
    await order.update({ paymentStatus });
    
    // Si le paiement est marqué comme payé ou remboursé, mettre la commande en terminée
    if (paymentStatus === 'paid' || paymentStatus === 'refunded') {
      await order.update({ status: 'completed' });
      console.log(`✅ Order ${id} status updated to completed (payment ${paymentStatus})`);
    }
    
    console.log(`✅ Order ${id} payment status updated: ${oldPaymentStatus} → ${paymentStatus}`);
    
    // 🔧 SI COMMANDE LIÉE À UN DEVIS : Assigner intervention au technicien
    if (paymentStatus === 'paid' && order.quoteId) {
      try {
        console.log(`🔍 Commande liée à un devis (quoteId: ${order.quoteId}), traitement intervention...`);
        
        const { Quote, Intervention, DiagnosticReport, User, TechnicianProfile, CustomerProfile } = require('../models');
        
        const quote = await Quote.findByPk(order.quoteId, {
          include: [
            { 
              model: Intervention, 
              as: 'intervention',
              include: [{ model: CustomerProfile, as: 'customer' }]
            },
            { 
              model: DiagnosticReport, 
              as: 'diagnosticReport',
              include: [{ model: User, as: 'technician' }]
            }
          ]
        });
        
        if (quote && quote.payment_status !== 'paid') {
          console.log(`✅ Devis trouvé (ID: ${quote.id}), mise à jour...`);
          
          // Mettre à jour le devis
          await quote.update({
            payment_status: 'paid',
            paid_at: new Date(),
            payment_method: 'Order Payment'
          });
          
          // 👨‍🔧 ASSIGNER LE TECHNICIEN DU DIAGNOSTIC À L'INTERVENTION
          const technicianId = quote.diagnosticReport?.technician_id;
          
          if (technicianId && quote.intervention) {
            // Planifier la date d'intervention (2 jours ouvrés après le paiement)
            const scheduledDate = new Date();
            scheduledDate.setDate(scheduledDate.getDate() + 2);
            
            // Éviter les week-ends
            if (scheduledDate.getDay() === 6) { // Samedi
              scheduledDate.setDate(scheduledDate.getDate() + 2);
            } else if (scheduledDate.getDay() === 0) { // Dimanche
              scheduledDate.setDate(scheduledDate.getDate() + 1);
            }
            
            scheduledDate.setHours(9, 0, 0, 0);
            
            // NE PAS modifier le statut de l'intervention de diagnostic (elle reste diagnostic_submitted)
            // On met seulement à jour la date de paiement du diagnostic
            await quote.intervention.update({
              diagnostic_payment_date: new Date(),
              diagnostic_paid: true
            });
            
            console.log(`✅ Paiement enregistré pour l'intervention de diagnostic ${quote.intervention_id}`);
            console.log(`ℹ️ L'intervention de diagnostic reste en statut: ${quote.intervention.status}`);
            
            // Mettre à jour le rapport de diagnostic
            if (quote.diagnosticReport) {
              await quote.diagnosticReport.update({ status: 'approved' });
            }
            
            // 🔔 NOTIFIER LE TECHNICIEN de la nouvelle intervention de suivi (pas de l'intervention de diagnostic)
            const notificationService = require('../services/notificationService');
            
            const technician = await User.findByPk(technicianId, {
              include: [{ model: TechnicianProfile, as: 'technicianProfile' }]
            });
            
            const customerName = quote.intervention.customer
              ? `${quote.intervention.customer.first_name} ${quote.intervention.customer.last_name}`
              : 'Client';
            
            console.log(`ℹ️ L'intervention de diagnostic #${quote.intervention_id} reste terminée, création de l'intervention de suivi...`);
            
            // 🆕 CRÉER INTERVENTION STANDARD BASÉE SUR LES RECOMMANDATIONS
            if (quote.diagnosticReport && quote.diagnosticReport.recommended_solution) {
              console.log('🔄 Création d\'une intervention standard basée sur les recommandations...');
              
              // Calculer la date de l'intervention standard (7 jours après l'intervention de réparation)
              const followUpDate = new Date(scheduledDate);
              followUpDate.setDate(followUpDate.getDate() + 7);
              // S'assurer que c'est un jour ouvrable
              while (followUpDate.getDay() === 0 || followUpDate.getDay() === 6) {
                followUpDate.setDate(followUpDate.getDate() + 1);
              }
              followUpDate.setHours(10, 0, 0, 0);
              
              const standardIntervention = await Intervention.create({
                title: 'Intervention de suivi - Recommandations du diagnostic',
                description: `Recommandations du diagnostic:\n${quote.diagnosticReport.recommended_solution}\n\nPièces nécessaires: ${quote.diagnosticReport.parts_needed || 'Aucune'}`,
                address: quote.intervention.address,
                customer_id: quote.intervention.customer_id,
                technician_id: technicianId,
                intervention_type: 'standard',
                status: 'assigned',
                priority: quote.diagnosticReport.urgency_level || 'normal',
                scheduled_date: followUpDate,
                equipment_count: quote.intervention.equipment_count || 1
              });
              
              console.log(`✅ Intervention standard créée (ID: ${standardIntervention.id}) - Date: ${followUpDate.toLocaleString('fr-FR')}`);
              console.log(`✅ Technicien ${technicianId} automatiquement assigné à l'intervention standard ${standardIntervention.id}`);
              
              // Notifier le technicien de la nouvelle intervention assignée
              const followUpDateStr = followUpDate.toLocaleDateString('fr-FR', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              });
              const followUpTimeStr = followUpDate.toLocaleTimeString('fr-FR', {
                hour: '2-digit',
                minute: '2-digit'
              });
              
              await notificationService.create({
                userId: technicianId,
                type: 'intervention_assigned',
                title: '🔧 Intervention de suivi assignée',
                message: `Suite au diagnostic de ${customerName}, une intervention de suivi vous a été assignée pour le ${followUpDateStr} à ${followUpTimeStr}.`,
                data: { 
                  intervention_id: standardIntervention.id,
                  original_intervention_id: quote.intervention_id,
                  diagnostic_report_id: quote.diagnosticReport.id,
                  customer_name: customerName,
                  scheduled_date: followUpDate.toISOString(),
                  address: quote.intervention.address || 'Non spécifiée'
                },
                priority: 'high',
                actionUrl: `/interventions`
              });
              
              console.log(`✅ Notification envoyée au technicien ${technicianId} pour l'intervention standard ${standardIntervention.id}`);
              
              // Notifier l'admin de la nouvelle intervention créée
              const adminUsers = await User.findAll({ where: { role: 'admin' } });
              for (const admin of adminUsers) {
                await notificationService.create({
                  userId: admin.id,
                  type: 'intervention_created',
                  title: '📋 Intervention de suivi créée',
                  message: `Intervention de suivi assignée à ${technician.technicianProfile?.first_name || 'technicien'} pour ${customerName} le ${followUpDateStr}.`,
                  data: {
                    intervention_id: standardIntervention.id,
                    original_intervention_id: quote.intervention_id,
                    diagnostic_report_id: quote.diagnosticReport.id,
                    technician_id: technicianId,
                    scheduled_date: followUpDate.toISOString()
                  },
                  priority: 'medium',
                  actionUrl: `/interventions`
                });
              }
              
              console.log(`✅ Notifications envoyées aux admins pour l'intervention standard ${standardIntervention.id}`);
            }
          } else {
            console.log(`⚠️ Pas de technicien ou intervention trouvés pour ce devis`);
          }
        } else {
          console.log(`⚠️ Devis déjà payé ou non trouvé`);
        }
      } catch (quoteError) {
        console.error('❌ Erreur lors du traitement de l\'intervention:', quoteError);
        // Ne pas bloquer la mise à jour de la commande
      }
    }
    
    // Envoyer une notification au client
    try {
      console.log('🔔 Début envoi notification au client...');
      const { User, CustomerProfile } = require('../models');
      const notificationService = require('../services/notificationService');
      
      console.log(`   Recherche CustomerProfile pour customerId: ${order.customerId}`);
      
      // Récupérer le profil client puis l'utilisateur
      const customerProfile = await CustomerProfile.findByPk(order.customerId, {
        include: [{
          model: User,
          as: 'user'
        }]
      });
      
      console.log(`   CustomerProfile trouvé:`, customerProfile ? `ID=${customerProfile.id}` : 'NON TROUVÉ');
      
      if (customerProfile && customerProfile.user) {
        const customer = customerProfile.user;
        console.log(`   User trouvé: ${customer.email} (ID: ${customer.id})`);
        
        const orderRef = order.reference ? ` (${order.reference})` : '';
        const statusMessages = {
          'paid': {
            title: 'Paiement confirmé',
            message: `Le paiement de votre commande #${order.id}${orderRef} a été confirmé. Montant: ${order.totalAmount} FCFA`,
            type: 'payment_confirmed'
          },
          'failed': {
            title: 'Paiement échoué',
            message: `Le paiement de votre commande #${order.id}${orderRef} a échoué. Veuillez réessayer ou nous contacter.`,
            type: 'payment_failed'
          },
          'refunded': {
            title: 'Paiement remboursé',
            message: `Le paiement de votre commande #${order.id}${orderRef} a été remboursé. Montant: ${order.totalAmount} FCFA`,
            type: 'payment_refunded'
          },
          'pending': {
            title: 'Paiement en attente',
            message: `Votre commande #${order.id} (${order.reference || ''}) est en attente de paiement. Montant: ${order.totalAmount} FCFA`,
            type: 'payment_pending'
          }
        };
        
        const notification = statusMessages[paymentStatus];
        console.log(`   Message de notification: "${notification.title}"`);
        
        if (notification) {
          const notifData = {
            userId: customer.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            priority: paymentStatus === 'failed' ? 'high' : paymentStatus === 'refunded' ? 'high' : 'medium',
            actionUrl: `/commandes/${order.id}`,
            data: {
              orderId: order.id,
              orderReference: order.reference,
              paymentStatus: paymentStatus,
              amount: order.totalAmount
            }
          };
          
          console.log(`   Appel createNotification avec:`, notifData);
          
          const createdNotif = await notificationService.create(notifData);
          
          console.log(`📧 ✅ Notification "${notification.title}" créée (ID: ${createdNotif?.id}) et envoyée au client ${customer.email} (User ID: ${customer.id})`);
        }
      } else {
        console.log(`⚠️  Profil client non trouvé pour customerId: ${order.customerId}`);
        console.log(`   Order data:`, {
          orderId: order.id,
          customerId: order.customerId,
          reference: order.reference
        });
      }
    } catch (notifError) {
      console.error('⚠️  Erreur lors de l\'envoi de la notification:', notifError.message);
      console.error('   Stack:', notifError.stack);
      // Ne pas faire échouer la requête si la notification échoue
    }
    
    res.json({
      success: true,
      message: 'Statut de paiement mis à jour avec succès',
      data: {
        id: order.id,
        paymentStatus: order.paymentStatus,
        status: order.status
      }
    });
  } catch (error) {
    console.error('❌ Error updating order payment status:', error);
    console.error('   Stack trace:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut de paiement',
      error: error.message
    });
  }
});

// Order tracking routes
router.get('/:id/tracking', (req, res) => {
  res.json({
    success: true,
    message: 'Order tracking information retrieved successfully',
    data: {
      status: 'pending',
      estimatedDelivery: '',
      trackingNumber: ''
    }
  });
});

// Admin order management routes
router.get('/admin/all', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'All orders retrieved successfully',
    data: []
  });
});

router.put('/admin/:id/status', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Order status updated successfully'
  });
});

router.put('/admin/:id/assign', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Order assigned successfully'
  });
});

// Order statistics routes
router.get('/statistics', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Order statistics retrieved successfully',
    data: {
      totalOrders: 0,
      pendingOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      totalRevenue: 0
    }
  });
});

// Order export routes
router.get('/export', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Order export data retrieved successfully',
    data: []
  });
});

module.exports = router;
