const axios = require('axios');
const crypto = require('crypto');
const { Quote, Order, Intervention, DiagnosticReport, User, TechnicianProfile, CustomerProfile, PaymentLog, Subscription, Payment } = require('../../models');

// Configuration FineoPay - URLs OFFICIELLES de la documentation
// Sandbox: https://dev.fineopay.com/api/v1/business/dev/
// Production: https://api.fineopay.com/v1/business/dev/
const FINEOPAY_BASE_URL = process.env.FINEOPAY_ENV === 'production' 
  ? 'https://api.fineopay.com/v1/business/dev'
  : 'https://dev.fineopay.com/api/v1/business/dev';

const FINEOPAY_BUSINESS_CODE = process.env.FINEOPAY_BUSINESS_CODE;
const FINEOPAY_API_KEY = process.env.FINEOPAY_API_KEY;

console.log('🔧 Configuration FineoPay:');
console.log('  - Environment:', process.env.FINEOPAY_ENV || 'sandbox');
console.log('  - Base URL:', FINEOPAY_BASE_URL);
console.log('  - Business Code:', FINEOPAY_BUSINESS_CODE);
console.log('  - API Key:', FINEOPAY_API_KEY ? `${FINEOPAY_API_KEY.substring(0, 20)}...` : 'NON DÉFINIE');

/**
 * Créer un lien de paiement FineoPay
 */
const createPaymentLink = async (req, res) => {
  try {
    const { orderId, amount, title, description, customerInfo } = req.body;

    if (!orderId || !amount || !title) {
      return res.status(400).json({
        success: false,
        message: 'orderId, amount et title sont requis'
      });
    }

    // Construire l'URL de callback
    const callbackUrl = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/fineopay/callback`;

    // Préparer les champs additionnels pour le formulaire de paiement
    const inputs = [];
    if (customerInfo?.requirePhone) {
      inputs.push({
        key: 'phone',
        type: 'tel',
        label: 'Numéro de téléphone',
        required: true
      });
    }
    if (customerInfo?.requireName) {
      inputs.push({
        key: 'name',
        type: 'text',
        label: 'Nom complet',
        required: true
      });
    }

    // Créer le lien de paiement
    console.log('📤 Envoi requête à FineoPay:');
    console.log('  - URL:', `${FINEOPAY_BASE_URL}/checkout-link`);
    console.log('  - Business Code:', FINEOPAY_BUSINESS_CODE);
    console.log('  - Payload:', JSON.stringify({
      title,
      amount: parseFloat(amount),
      callbackUrl,
      syncRef: `ORDER_${orderId}`,
      inputs
    }, null, 2));

    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title,
        amount: parseFloat(amount),
        callbackUrl,
        syncRef: `ORDER_${orderId}`,
        inputs
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    console.log('📥 Réponse FineoPay:', JSON.stringify(response.data, null, 2));

    if (response.data.success) {
      const checkoutLink = response.data.data.checkoutLink;
      // Extraire l'ID du checkout link depuis l'URL (format: .../BUSINESS_CODE/CHECKOUT_ID/checkout)
      const checkoutLinkId = checkoutLink.split('/').slice(-2, -1)[0];
      
      console.log(`✅ Lien de paiement FineoPay créé pour commande #${orderId}`);
      console.log(`🔗 URL: ${checkoutLink}`);
      console.log(`🔑 Checkout ID: ${checkoutLinkId}`);

      // 🔒 Stocker le checkoutLinkId dans la commande pour un matching sécurisé
      const order = await Order.findByPk(orderId);
      if (order) {
        await order.update({
          fineopayCheckoutId: checkoutLinkId,
          paymentMethod: 'fineopay'
        });
        console.log(`💾 Checkout ID sauvegardé dans la commande #${orderId}`);
      }

      // 📝 Logger l'opération
      await PaymentLog.create({
        orderId,
        eventType: 'checkout_created',
        provider: 'fineopay',
        checkoutLinkId,
        amount: parseFloat(amount),
        paymentStatus: 'pending',
        sourceIp: req.ip,
        userAgent: req.get('User-Agent'),
        rawData: { checkoutLink, syncRef: `ORDER_${orderId}` },
        success: true,
        metadata: { title, description }
      });

      return res.status(200).json({
        success: true,
        message: 'Lien de paiement créé avec succès',
        data: {
          paymentUrl: checkoutLink,
          checkoutLinkId,
          orderId,
          amount
        }
      });
    } else {
      // 📝 Logger l'échec
      await PaymentLog.create({
        orderId,
        eventType: 'checkout_created',
        provider: 'fineopay',
        amount: parseFloat(amount),
        paymentStatus: 'pending',
        sourceIp: req.ip,
        success: false,
        errorMessage: response.data.message || 'Erreur inconnue'
      });
      
      throw new Error(response.data.message || 'Erreur lors de la création du lien de paiement');
    }

  } catch (error) {
    console.error('❌ Erreur création lien FineoPay:');
    console.error('  - Message:', error.message);
    console.error('  - Status:', error.response?.status);
    console.error('  - Réponse API:', JSON.stringify(error.response?.data, null, 2));
    console.error('  - Headers:', JSON.stringify(error.response?.headers, null, 2));
    
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du lien de paiement',
      error: error.response?.data || error.message,
      details: {
        status: error.response?.status,
        statusText: error.response?.statusText,
        apiMessage: error.response?.data?.message
      }
    });
  }
};

/**
 * Callback webhook FineoPay
 * Reçoit les notifications de paiement
 * 
 * 🔒 Sécurité:
 * - Validation de signature (si fournie par FineoPay)
 * - Vérification de la transaction auprès de l'API FineoPay
 * - Logging de tous les événements
 */
const handleCallback = async (req, res) => {
  const sourceIp = req.ip || req.connection.remoteAddress;
  const signature = req.headers['x-fineopay-signature'] || req.headers['x-signature'];
  
  try {
    const { reference, amount, status, clientAccountNumber, timestamp, syncRef: bodySyncRef } = req.body;

    console.log('📨 Callback FineoPay reçu:', {
      reference,
      amount,
      status,
      clientAccountNumber,
      timestamp,
      sourceIp,
      hasSignature: !!signature
    });

    // 📝 Logger immédiatement la réception du webhook
    const webhookLog = await PaymentLog.create({
      eventType: 'webhook_received',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      paymentStatus: status,
      sourceIp,
      userAgent: req.get('User-Agent'),
      signature,
      rawData: req.body,
      success: true
    });

    // 🔒 Vérification de signature (si FineoPay fournit une signature)
    if (signature && process.env.FINEOPAY_WEBHOOK_SECRET) {
      const expectedSignature = crypto
        .createHmac('sha256', process.env.FINEOPAY_WEBHOOK_SECRET)
        .update(JSON.stringify(req.body))
        .digest('hex');
      
      const signatureValid = crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
      
      await webhookLog.update({ signatureValid });
      
      if (!signatureValid) {
        console.log(`🚫 Signature webhook invalide depuis ${sourceIp}`);
        await PaymentLog.create({
          eventType: 'signature_invalid',
          provider: 'fineopay',
          fineopayReference: reference,
          sourceIp,
          signature,
          success: false,
          errorMessage: 'Signature invalide'
        });
        return res.status(401).json({ success: false, message: 'Signature invalide' });
      }
      console.log(`✅ Signature webhook valide`);
    }

    // Répondre immédiatement à FineoPay
    res.status(200).json({ success: true, message: 'Notification reçue' });

    // Traiter le paiement de manière asynchrone
    if (status !== 'success') {
      console.log(`⚠️ Paiement non réussi - Status: ${status}`);
      await PaymentLog.create({
        eventType: 'payment_failed',
        provider: 'fineopay',
        fineopayReference: reference,
        amount: parseFloat(amount),
        paymentStatus: status,
        sourceIp,
        success: false,
        errorMessage: `Statut de paiement: ${status}`
      });
      return;
    }

    // Vérifier la transaction auprès de FineoPay
    const verificationResponse = await axios.get(
      `${FINEOPAY_BASE_URL}/transactions/${reference}`,
      {
        headers: {
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    const transaction = verificationResponse.data.data;
    
    if (transaction.status !== 'success') {
      console.log(`⚠️ Vérification échouée - Transaction non validée`);
      return;
    }

    // Extraire l'ID de la commande depuis syncRef
    const syncRef = transaction.syncRef || '';
    
    // Vérifier si c'est une commande de devis (ORDER_xxx), une commande de boutique (SHOP_ORDER_xxx), une souscription (SUBSCRIPTION_xxx) ou un diagnostic (DIAGNOSTIC_xxx)
    let orderId;
    let isShopOrder = false;
    let isSubscription = false;
    let isDiagnostic = false;
    
    const shopOrderMatch = syncRef.match(/SHOP_ORDER_(\d+)/);
    const quoteOrderMatch = syncRef.match(/ORDER_(\d+)/);
    const subscriptionMatch = syncRef.match(/SUBSCRIPTION_(\d+)/);
    const diagnosticMatch = syncRef.match(/DIAGNOSTIC_(\d+)/);
    
    if (diagnosticMatch) {
      const interventionId = parseInt(diagnosticMatch[1]);
      isDiagnostic = true;
      console.log(`🔬 Traitement paiement diagnostic pour intervention #${interventionId}`);
      return await handleDiagnosticPayment(interventionId, reference, amount, sourceIp);
    } else if (shopOrderMatch) {
      orderId = parseInt(shopOrderMatch[1]);
      isShopOrder = true;
      console.log(`🛒 Traitement paiement boutique pour commande #${orderId}`);
    } else if (subscriptionMatch) {
      const subscriptionId = parseInt(subscriptionMatch[1]);
      isSubscription = true;
      console.log(`📋 Traitement paiement souscription #${subscriptionId}`);
      return await handleSubscriptionPayment(subscriptionId, reference, amount, sourceIp);
    } else if (quoteOrderMatch) {
      orderId = parseInt(quoteOrderMatch[1]);
      console.log(`📦 Traitement paiement devis pour commande #${orderId}`);
    } else {
      console.log(`⚠️ Impossible d'extraire l'ID de commande depuis syncRef: ${syncRef}`);
      return;
    }

    // Si c'est une commande de boutique, traiter différemment
    if (isShopOrder) {
      return await handleShopOrderPayment(orderId, reference, amount);
    }

    // Sinon, c'est une commande de devis (logique existante)
    console.log(`📦 Traitement paiement de devis pour commande #${orderId}`);

    // Récupérer la commande avec le devis et l'intervention
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Quote,
          as: 'quote',
          include: [
            {
              model: DiagnosticReport,
              as: 'diagnosticReport',
              required: false
            },
            {
              model: Intervention,
              as: 'intervention',
              include: [
                {
                  model: CustomerProfile,
                  as: 'customer',
                  include: [{
                    model: User,
                    as: 'user'
                  }]
                }
              ]
            }
          ]
        }
      ]
    });

    if (!order) {
      console.log(`❌ Commande #${orderId} introuvable`);
      await PaymentLog.create({
        orderId,
        eventType: 'webhook_received',
        provider: 'fineopay',
        fineopayReference: reference,
        amount: parseFloat(amount),
        sourceIp,
        success: false,
        errorMessage: 'Commande introuvable'
      });
      return;
    }

    if (order.paymentStatus === 'paid') {
      console.log(`ℹ️ Commande #${orderId} déjà payée`);
      await PaymentLog.create({
        orderId,
        eventType: 'duplicate_blocked',
        provider: 'fineopay',
        fineopayReference: reference,
        amount: parseFloat(amount),
        paymentStatus: 'paid',
        sourceIp,
        success: false,
        errorMessage: 'Commande déjà payée'
      });
      return;
    }

    console.log(`💰 Mise à jour du paiement pour commande #${orderId}`);

    // Mettre à jour le statut de paiement ET le statut de la commande
    await order.update({
      status: 'processing',         // 🆕 Mettre à jour le statut de la commande
      paymentStatus: 'paid',
      paymentMethod: 'fineopay',
      paymentDate: new Date(),
      fineopayReference: reference
    });

    // 📝 Logger la confirmation de paiement via webhook
    await PaymentLog.create({
      orderId,
      eventType: 'payment_confirmed',
      provider: 'fineopay',
      fineopayReference: reference,
      checkoutLinkId: order.fineopayCheckoutId,
      amount: parseFloat(amount),
      paymentStatus: 'paid',
      sourceIp,
      success: true,
      metadata: { source: 'webhook', clientAccountNumber }
    });

    console.log(`✅ Commande #${orderId} marquée comme payée`);

    // Mettre à jour le devis associé et gérer l'exécution différée
    if (order.quoteId) {
      const Quote = require('../../models').Quote;
      const Intervention = require('../../models').Intervention;
      const User = require('../../models').User;
      
      // Récupérer le devis avec ses informations
      const quote = await Quote.findByPk(order.quoteId);
      
      await Quote.update(
        { payment_status: 'paid' },
        { where: { id: order.quoteId } }
      );
      console.log(`✅ Devis #${order.quoteId} marqué comme payé`);

      // 🔧 Si paiement différé (execute_now = false), passer l'intervention en execution_confirmed
      if (quote && quote.execute_now === false && quote.intervention_id) {
        const intervention = await Intervention.findByPk(quote.intervention_id, {
          include: [{ model: User, as: 'technician' }]
        });
        
        if (intervention) {
          await intervention.update({
            status: 'execution_confirmed',
            intervention_type: 'execution',
            notes: `${intervention.notes || ''}\n\n[${new Date().toISOString()}] 📅 PAIEMENT REÇU (webhook) - Exécution différée confirmée - Devis ${quote.reference}`
          });
          console.log(`🔄 Intervention ${intervention.id} mise à jour: status = execution_confirmed (paiement différé via webhook)`);

          // Notifier le technicien
          const notificationService = require('../../services/notificationService');
          if (intervention.technician_id) {
            await notificationService.create({
              userId: intervention.technician_id,
              type: 'quote_execution_confirmed',
              title: '📅 Exécution planifiée confirmée',
              message: `Le client a payé le devis ${quote.reference}. L'intervention est planifiée pour le ${quote.scheduled_date ? new Date(quote.scheduled_date).toLocaleDateString('fr-FR') : 'bientôt'}. Préparez-vous pour l'intervention.`,
              data: {
                quote_id: quote.id,
                quote_reference: quote.reference,
                intervention_id: intervention.id,
                scheduled_date: quote.scheduled_date
              },
              priority: 'high',
              actionUrl: `/interventions/${intervention.id}`
            });
            console.log(`📲 Notification envoyée au technicien (user_id: ${intervention.technician_id})`);
          }
        }
      }
    }

    console.log(`✅ Commande #${orderId} traitée avec succès`);

    // Envoyer une notification de paiement réussi au client
    const notificationService = require('../../services/notificationService');
    const customer = order.quote?.intervention?.customer;
    
    if (customer && customer.user_id) {
      await notificationService.create({
        userId: customer.user_id,
        type: 'payment_success',
        title: '💳 Paiement confirmé',
        message: `Votre paiement de ${amount} FCFA pour la commande ${order.reference} a été traité avec succès.`,
        data: {
          order_id: orderId,
          amount: amount,
          reference: reference,
          payment_method: 'fineopay'
        },
        priority: 'high',
        actionUrl: `/commandes/${orderId}`
      });
      console.log(`📲 Notification de paiement envoyée au client`);

      // 📱 Notifier les admins du paiement reçu
      const customerName = customer.first_name ? 
        `${customer.first_name} ${customer.last_name || ''}`.trim() : 'Un client';
      await notificationService.notifyAdmins({
        type: 'payment_received',
        title: '💰 Paiement reçu',
        message: `Paiement de ${amount} FCFA reçu de ${customerName} (commande)`,
        data: {
          orderId,
          amount: parseFloat(amount),
          paymentType: 'order',
          reference,
          customerId: customer.id
        },
        priority: 'medium',
        actionUrl: `/commandes/${orderId}`
      });
      console.log(`📲 Notification de paiement envoyée aux admins`);
    } else {
      console.log(`⚠️ Impossible d'envoyer la notification - customer introuvable`);
    }

    // Si c'est un devis de diagnostic, créer l'intervention standard
    if (quote.diagnosticReport && quote.intervention) {
      const technicianId = quote.diagnosticReport.technician_id;
      
      if (technicianId) {
        // Calculer la date planifiée (2 jours ouvrables)
        let scheduledDate = new Date();
        scheduledDate.setDate(scheduledDate.getDate() + 2);
        
        while (scheduledDate.getDay() === 6 || scheduledDate.getDay() === 0) {
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

        console.log(`✅ Devis ${quote.id} payé - Intervention de diagnostic terminée, création intervention de suivi...`);

        // Créer une intervention standard basée sur les recommandations
        if (quote.diagnosticReport.recommended_solution) {
          const followUpDate = new Date(scheduledDate);
          followUpDate.setDate(followUpDate.getDate() + 7);
          
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

          console.log(`✅ Intervention standard créée (ID: ${standardIntervention.id})`);

          // Notifier le technicien
          const notificationService = require('../../services/notificationService');
          const technician = await User.findByPk(technicianId, {
            include: [{ model: TechnicianProfile, as: 'technicianProfile' }]
          });

          const customerName = quote.intervention.customer
            ? `${quote.intervention.customer.first_name} ${quote.intervention.customer.last_name}`
            : 'Client';

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
              scheduled_date: followUpDate.toISOString()
            },
            priority: 'high',
            actionUrl: `/interventions`
          });

          // Notifier le client
          await notificationService.create({
            userId: quote.intervention.customer.user_id,
            type: 'intervention_scheduled',
            title: '📅 Intervention planifiée',
            message: `Votre intervention de suivi a été planifiée pour le ${followUpDateStr} à ${followUpTimeStr}.`,
            data: {
              intervention_id: standardIntervention.id,
              scheduled_date: followUpDate.toISOString(),
              technician_id: technicianId
            },
            priority: 'high'
          });
        }
      }
    }

  } catch (error) {
    console.error('❌ Erreur traitement callback FineoPay:', error);
  }
};

/**
 * Vérifier le statut d'une transaction
 */
const checkTransactionStatus = async (req, res) => {
  try {
    const { reference } = req.params;

    const response = await axios.get(
      `${FINEOPAY_BASE_URL}/transactions/${reference}`,
      {
        headers: {
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    return res.status(200).json({
      success: true,
      data: response.data.data
    });

  } catch (error) {
    console.error('❌ Erreur vérification transaction FineoPay:', error.response?.data || error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification de la transaction',
      error: error.response?.data || error.message
    });
  }
};

/**
 * Lister toutes les transactions
 */
const listTransactions = async (req, res) => {
  try {
    const response = await axios.get(
      `${FINEOPAY_BASE_URL}/transactions`,
      {
        headers: {
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    return res.status(200).json({
      success: true,
      data: response.data.data
    });

  } catch (error) {
    console.error('❌ Erreur récupération transactions FineoPay:', error.response?.data || error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des transactions',
      error: error.response?.data || error.message
    });
  }
};

/**
 * Gérer le paiement d'une commande de boutique
 */
const handleShopOrderPayment = async (orderId, reference, amount) => {
  try {
    const { Order, Payment, CustomerProfile } = require('../../models');
    
    // Récupérer la commande
    const order = await Order.findByPk(orderId);
    
    if (!order) {
      console.log(`❌ Commande boutique #${orderId} introuvable`);
      return;
    }

    if (order.paymentStatus === 'paid') {
      console.log(`ℹ️ Commande boutique #${orderId} déjà payée`);
      return;
    }

    // Mettre à jour le statut de paiement de la commande
    await order.update({
      paymentStatus: 'paid',
      paymentMethod: 'fineopay',
      paymentDate: new Date()
    });

    // Enregistrer le paiement
    await Payment.create({
      orderId: order.id,
      amount: amount,
      currency: 'XOF',
      provider: 'fineopay',
      paymentId: reference,
      status: 'completed',
      metadata: {
        fineopay_reference: reference
      }
    });

    console.log(`✅ Commande boutique #${orderId} marquée comme payée`);

    // Notifier le client - order.customerId est un CustomerProfile.id, il faut récupérer le User.id
    const notificationService = require('../../services/notificationService');
    
    if (order.customerId) {
      // Récupérer le CustomerProfile pour obtenir le user_id
      const customerProfile = await CustomerProfile.findByPk(order.customerId);
      const userId = customerProfile ? customerProfile.user_id : null;
      
      if (userId) {
        await notificationService.create({
          userId: userId,
          type: 'payment_confirmed',
          title: '✅ Paiement confirmé',
          message: `Votre paiement de ${amount} FCFA pour la commande #${orderId} a été confirmé.`,
          data: {
            orderId: orderId,
            order_id: orderId,
            amount: amount,
            reference: reference
          },
          priority: 'high'
        });
      } else {
        console.log(`⚠️ User non trouvé pour CustomerProfile #${order.customerId}`);
      }
    }

  } catch (error) {
    console.error(`❌ Erreur traitement paiement boutique #${orderId}:`, error);
  }
};

/**
 * Gérer le paiement d'une souscription
 */
const handleSubscriptionPayment = async (subscriptionId, reference, amount, sourceIp) => {
  try {
    console.log(`📋 Traitement paiement souscription #${subscriptionId}`);
    
    // Récupérer la souscription avec ses relations
    const subscription = await Subscription.findByPk(subscriptionId, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        }
      ]
    });
    
    if (!subscription) {
      console.log(`❌ Souscription #${subscriptionId} introuvable`);
      return;
    }

    if (subscription.payment_status === 'paid') {
      console.log(`ℹ️ Souscription #${subscriptionId} déjà payée`);
      return;
    }

    // Mettre à jour le statut de paiement de la souscription
    await subscription.update({
      payment_status: 'paid',
      status: 'active' // Activer la souscription
    });

    // Enregistrer le paiement
    await Payment.create({
      subscriptionId: subscription.id,
      amount: amount,
      currency: 'XOF',
      provider: 'fineopay',
      paymentId: reference,
      status: 'completed',
      metadata: {
        fineopay_reference: reference,
        source_ip: sourceIp
      }
    });

    // Logger dans PaymentLog
    await PaymentLog.create({
      eventType: 'payment_confirmed',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      paymentStatus: 'paid',
      sourceIp,
      success: true,
      metadata: { subscriptionId, type: 'subscription' }
    });

    console.log(`✅ Souscription #${subscriptionId} marquée comme payée et activée`);

    // Notifier le client
    const notificationService = require('../../services/notificationService');
    
    if (subscription.customer_id) {
      await notificationService.create({
        userId: subscription.customer_id,
        type: 'payment_confirmed',
        title: '✅ Souscription activée',
        message: `Votre paiement de ${amount} FCFA a été confirmé. Votre souscription est maintenant active !`,
        data: {
          subscription_id: subscriptionId,
          amount: amount,
          reference: reference
        },
        priority: 'high'
      });
    }

    // 📱 Notifier les admins du paiement souscription reçu
    const customerProfile = subscription.customer;
    const customerName = customerProfile ? 
      `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() : 'Un client';
    const offerName = subscription.offer?.title || 'abonnement';
    await notificationService.notifyAdmins({
      type: 'payment_received',
      title: '💰 Paiement abonnement reçu',
      message: `Paiement de ${amount} FCFA reçu de ${customerName} (${offerName})`,
      data: {
        subscriptionId,
        amount: parseFloat(amount),
        paymentType: 'subscription',
        reference,
        offerName
      },
      priority: 'medium',
      actionUrl: `/dashboard`
    });
    console.log(`📲 Notification de paiement abonnement envoyée aux admins`);

  } catch (error) {
    console.error(`❌ Erreur traitement paiement souscription #${subscriptionId}:`, error);
    
    // Logger l'erreur
    await PaymentLog.create({
      eventType: 'payment_failed',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      success: false,
      errorMessage: error.message,
      metadata: { subscriptionId, type: 'subscription' }
    });
  }
};

/**
 * Gérer le paiement d'un diagnostic d'intervention
 */
const handleDiagnosticPayment = async (interventionId, reference, amount, sourceIp) => {
  try {
    console.log(`🔬 Traitement paiement diagnostic #${interventionId}`);
    
    // Récupérer l'intervention avec ses relations
    const intervention = await Intervention.findByPk(interventionId, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
          }]
        }
      ]
    });
    
    if (!intervention) {
      console.log(`❌ Intervention #${interventionId} introuvable`);
      return;
    }

    if (intervention.diagnostic_paid === true) {
      console.log(`ℹ️ Diagnostic intervention #${interventionId} déjà payé`);
      return;
    }

    // Mettre à jour le statut de paiement du diagnostic
    await intervention.update({
      diagnostic_paid: true,
      diagnostic_payment_date: new Date()
    });

    // Enregistrer le paiement
    await Payment.create({
      interventionId: intervention.id,
      amount: amount,
      currency: 'XOF',
      provider: 'fineopay',
      paymentId: reference,
      status: 'completed',
      metadata: {
        fineopay_reference: reference,
        source_ip: sourceIp,
        type: 'diagnostic'
      }
    });

    // Logger dans PaymentLog
    await PaymentLog.create({
      eventType: 'diagnostic_payment_confirmed',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      paymentStatus: 'paid',
      sourceIp,
      success: true,
      metadata: { interventionId, type: 'diagnostic' }
    });

    console.log(`✅ Diagnostic intervention #${interventionId} marqué comme payé`);

    // Notifier le client
    const notificationService = require('../../services/notificationService');
    const customer = intervention.customer?.user;
    
    if (customer) {
      await notificationService.create({
        userId: customer.id,
        type: 'diagnostic_payment_confirmed',
        title: '✅ Paiement diagnostic confirmé',
        message: `Votre paiement de ${amount} FCFA pour le diagnostic de l'intervention #${interventionId} a été confirmé. Le technicien peut maintenant intervenir.`,
        data: {
          intervention_id: interventionId,
          amount: amount,
          reference: reference
        },
        priority: 'high'
      });
    }

    // 📱 Notifier les admins du paiement diagnostic reçu
    const customerProfile = intervention.customer;
    const customerName = customerProfile ? 
      `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() : 'Un client';
    await notificationService.notifyAdmins({
      type: 'payment_received',
      title: '💰 Paiement diagnostic reçu',
      message: `Paiement diagnostic de ${amount} FCFA reçu de ${customerName}`,
      data: {
        interventionId,
        amount: parseFloat(amount),
        paymentType: 'diagnostic',
        reference
      },
      priority: 'medium',
      actionUrl: `/interventions`
    });
    console.log(`📲 Notification de paiement diagnostic envoyée aux admins`);

  } catch (error) {
    console.error(`❌ Erreur traitement paiement diagnostic #${interventionId}:`, error);
    
    // Logger l'erreur
    await PaymentLog.create({
      eventType: 'diagnostic_payment_failed',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      success: false,
      errorMessage: error.message,
      metadata: { interventionId, type: 'diagnostic' }
    });
  }
};

/**
 * Vérifier le statut de paiement d'une commande
 */
const checkOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findByPk(orderId);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    // Si la commande est liée à un devis, récupérer les infos du devis
    let quoteInfo = null;
    if (order.quoteId) {
      const quote = await Quote.findByPk(order.quoteId);
      if (quote) {
        quoteInfo = {
          id: quote.id,
          paymentStatus: quote.paymentStatus,
          paymentDate: quote.paymentDate
        };
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        orderId: order.id,
        reference: order.reference,
        paymentStatus: order.paymentStatus,
        paymentMethod: order.paymentMethod,
        amount: order.totalAmount,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        quote: quoteInfo
      }
    });

  } catch (error) {
    console.error('❌ Erreur vérification statut commande:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du statut',
      error: error.message
    });
  }
};

/**
 * Vérifier activement le statut de paiement auprès de FineoPay
 * Interroge directement l'API FineoPay au lieu d'attendre le webhook
 */
const verifyPaymentStatus = async (req, res) => {
  try {
    const { orderId } = req.params;

    console.log(`🔍 Vérification active du paiement pour commande #${orderId}`);

    // Récupérer la commande (simple, sans include complexe)
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user'
          }]
        }
      ]
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    // Si déjà payé, retourner le statut
    if (order.paymentStatus === 'paid') {
      console.log(`✅ Commande #${orderId} déjà marquée comme payée`);
      return res.status(200).json({
        success: true,
        data: {
          orderId: order.id,
          reference: order.reference,
          paymentStatus: 'paid',
          paymentMethod: order.paymentMethod,
          amount: order.totalAmount
        }
      });
    }

    // Chercher la transaction dans FineoPay
    const syncRef = `ORDER_${orderId}`;
    const orderRef = order.reference; // e.g. CMD-1770745143471
    const checkoutLinkId = order.fineopayCheckoutId; // 🔒 ID sécurisé du checkout
    console.log(`🔍 Recherche transaction FineoPay pour commande #${orderId}`);
    console.log(`   📋 Ref: ${orderRef}, SyncRef: ${syncRef}, CheckoutId: ${checkoutLinkId || 'N/A'}`);

    try {
      // Récupérer toutes les transactions récentes
      const transactionsResponse = await axios.get(
        `${FINEOPAY_BASE_URL}/transactions`,
        {
          headers: {
            'businessCode': FINEOPAY_BUSINESS_CODE,
            'apiKey': FINEOPAY_API_KEY
          },
          params: {
            limit: 100
          }
        }
      );

      // IMPORTANT: FineoPay retourne les données dans data.data.transactions
      const transactions = transactionsResponse.data.data?.transactions || [];
      console.log(`📊 ${transactions.length} transactions récupérées de FineoPay`);

      // 📝 Logger la vérification
      await PaymentLog.create({
        orderId,
        eventType: 'status_check',
        provider: 'fineopay',
        checkoutLinkId,
        amount: order.totalAmount,
        paymentStatus: order.paymentStatus,
        sourceIp: req.ip,
        success: true,
        metadata: { transactionsChecked: transactions.length }
      });

      // Chercher une transaction correspondante par plusieurs critères (ordre de priorité)
      // 1. Par checkoutLinkId (le plus sécurisé - si disponible dans la transaction)
      // 2. Par syncRef (si présent dans la transaction)
      // 3. Par description contenant la référence de commande
      // 4. Par montant et date (créée après la commande) - fallback
      const orderCreatedAt = new Date(order.createdAt);
      const orderAmount = parseFloat(order.totalAmount);
      
      // 🔒 Fenêtre de temps: max 2 heures après création de la commande
      const maxPaymentWindow = new Date(orderCreatedAt.getTime() + 2 * 60 * 60 * 1000);

      const matchingTransaction = transactions.find(t => {
        // 1. Vérifier par checkoutLinkId (le plus sécurisé)
        if (checkoutLinkId && t.checkoutLinkId === checkoutLinkId) {
          console.log(`✅ Match par checkoutLinkId: ${t.reference}`);
          return true;
        }
        
        // 2. Vérifier par syncRef si disponible
        if (t.syncRef === syncRef) {
          console.log(`✅ Match par syncRef: ${t.reference}`);
          return true;
        }
        
        // 3. Vérifier par description contenant la référence
        if (t.description && (t.description.includes(orderRef) || t.description.includes(`ORDER_${orderId}`))) {
          console.log(`✅ Match par description: ${t.reference}`);
          return true;
        }
        
        // 4. Vérifier par montant exact + fenêtre de temps + status success
        const txDate = new Date(t.date);
        if (parseFloat(t.amount) === orderAmount && 
            txDate > orderCreatedAt && 
            txDate < maxPaymentWindow && 
            t.status === 'success') {
          console.log(`🔍 Match par montant/date (fenêtre 2h): ${t.reference}`);
          return true;
        }
        
        return false;
      });

      if (matchingTransaction) {
        console.log(`✅ Transaction trouvée:`, JSON.stringify(matchingTransaction, null, 2));

        if (matchingTransaction.status === 'success') {
          // 🔒 Protection anti-doublon: vérifier si déjà en cours de traitement
          if (order.paymentProcessing) {
            console.log(`⚠️ Paiement déjà en cours de traitement pour commande #${orderId}`);
            await PaymentLog.create({
              orderId,
              eventType: 'duplicate_blocked',
              provider: 'fineopay',
              fineopayReference: matchingTransaction.reference,
              amount: matchingTransaction.amount,
              paymentStatus: 'processing',
              success: false,
              errorMessage: 'Double traitement bloqué'
            });
            return res.status(200).json({
              success: true,
              data: {
                orderId: order.id,
                reference: order.reference,
                paymentStatus: 'processing',
                message: 'Paiement en cours de traitement'
              }
            });
          }

          // Marquer comme en cours de traitement
          await order.update({ paymentProcessing: true });

          // Mettre à jour le statut de la commande ET le statut de paiement
          await order.update({
            status: 'processing',         // 🆕 Mettre à jour le statut de la commande
            paymentStatus: 'paid',
            paymentMethod: 'fineopay',
            paymentDate: new Date(),
            fineopayReference: matchingTransaction.reference,
            paymentProcessing: false
          });

          // 📝 Logger la confirmation de paiement
          await PaymentLog.create({
            orderId,
            eventType: 'payment_confirmed',
            provider: 'fineopay',
            fineopayReference: matchingTransaction.reference,
            checkoutLinkId: order.fineopayCheckoutId,
            amount: matchingTransaction.amount,
            paymentStatus: 'paid',
            sourceIp: req.ip,
            success: true,
            rawData: matchingTransaction,
            metadata: { 
              canal: matchingTransaction.canal,
              clientPhone: matchingTransaction.clientAccountNumber
            }
          });

          // Mettre à jour le devis associé
          if (order.quoteId) {
            const Quote = require('../../models').Quote;
            const Intervention = require('../../models').Intervention;
            const User = require('../../models').User;
            
            // Récupérer le devis avec ses informations
            const quote = await Quote.findByPk(order.quoteId);
            
            await Quote.update(
              { payment_status: 'paid' },
              { where: { id: order.quoteId } }
            );
            console.log(`✅ Devis #${order.quoteId} marqué comme payé`);

            // 🔧 Si paiement différé (execute_now = false), passer l'intervention en execution_confirmed
            if (quote && quote.execute_now === false && quote.intervention_id) {
              const intervention = await Intervention.findByPk(quote.intervention_id, {
                include: [{ model: User, as: 'technician' }]
              });
              
              if (intervention) {
                await intervention.update({
                  status: 'execution_confirmed',
                  intervention_type: 'execution',
                  notes: `${intervention.notes || ''}\n\n[${new Date().toISOString()}] 📅 PAIEMENT REÇU - Exécution différée confirmée - Devis ${quote.reference}`
                });
                console.log(`🔄 Intervention ${intervention.id} mise à jour: status = execution_confirmed (paiement différé)`);

                // Notifier le technicien
                if (intervention.technician_id) {
                  await notificationService.create({
                    userId: intervention.technician_id,
                    type: 'quote_execution_confirmed',
                    title: '📅 Exécution planifiée confirmée',
                    message: `Le client a payé le devis ${quote.reference}. L'intervention est planifiée pour le ${quote.scheduled_date ? new Date(quote.scheduled_date).toLocaleDateString('fr-FR') : 'bientôt'}. Préparez-vous pour l'intervention.`,
                    data: {
                      quote_id: quote.id,
                      quote_reference: quote.reference,
                      intervention_id: intervention.id,
                      scheduled_date: quote.scheduled_date
                    },
                    priority: 'high',
                    actionUrl: `/interventions/${intervention.id}`
                  });
                  console.log(`📲 Notification envoyée au technicien (user_id: ${intervention.technician_id})`);
                }
              }
            }
          }

          console.log(`✅ Commande #${orderId} marquée comme payée`);

          // Envoyer une notification au client
          const notificationService = require('../../services/notificationService');
          const customer = order.customer;
          
          if (customer && customer.user_id) {
            await notificationService.create({
              userId: customer.user_id,
              type: 'payment_success',
              title: '💳 Paiement confirmé',
              message: `Votre paiement de ${matchingTransaction.amount} FCFA pour la commande ${order.reference} a été traité avec succès.`,
              data: {
                order_id: orderId,
                amount: matchingTransaction.amount,
                reference: matchingTransaction.reference,
                payment_method: 'fineopay'
              },
              priority: 'high',
              actionUrl: `/commandes/${orderId}`
            });
            console.log(`📲 Notification envoyée au client`);
          }

          return res.status(200).json({
            success: true,
            data: {
              orderId: order.id,
              reference: order.reference,
              paymentStatus: 'paid',
              paymentMethod: 'fineopay',
              amount: order.totalAmount
            }
          });
        } else {
          // Transaction trouvée mais pas encore réussie
          console.log(`⏳ Transaction trouvée mais statut: ${matchingTransaction.status}`);
          return res.status(200).json({
            success: true,
            data: {
              orderId: order.id,
              reference: order.reference,
              paymentStatus: 'pending',
              transactionStatus: matchingTransaction.status,
              amount: order.totalAmount
            }
          });
        }
      } else {
        // Aucune transaction trouvée pour cette commande
        console.log(`⚠️ Aucune transaction correspondante trouvée pour commande #${orderId} (montant: ${orderAmount}, créée: ${orderCreatedAt.toISOString()})`);
        return res.status(200).json({
          success: true,
          data: {
            orderId: order.id,
            reference: order.reference,
            paymentStatus: 'pending',
            message: 'Aucune transaction trouvée',
            amount: order.totalAmount
          }
        });
      }

    } catch (fineoError) {
      console.error(`❌ Erreur lors de la requête à FineoPay:`, fineoError.message);
      
      // 📝 Logger l'erreur
      await PaymentLog.create({
        orderId,
        eventType: 'status_check',
        provider: 'fineopay',
        checkoutLinkId: order.fineopayCheckoutId,
        amount: order.totalAmount,
        paymentStatus: order.paymentStatus,
        sourceIp: req.ip,
        success: false,
        errorMessage: fineoError.message
      });
      
      // En cas d'erreur FineoPay, retourner le statut local
      return res.status(200).json({
        success: true,
        data: {
          orderId: order.id,
          reference: order.reference,
          paymentStatus: order.paymentStatus,
          amount: order.totalAmount,
          error: 'Impossible de vérifier auprès de FineoPay'
        }
      });
    }

  } catch (error) {
    console.error('❌ Erreur vérification paiement:', error);
    
    // 📝 Logger l'erreur générale
    try {
      await PaymentLog.create({
        orderId: req.params.orderId,
        eventType: 'status_check',
        provider: 'fineopay',
        success: false,
        errorMessage: error.message
      });
    } catch (logError) {
      console.error('❌ Erreur lors du logging:', logError.message);
    }
    
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du paiement',
      error: error.message
    });
  }
};

/**
 * Vérifier le statut de paiement d'une souscription
 * Interroge directement l'API FineoPay
 */
const verifySubscriptionPaymentStatus = async (req, res) => {
  try {
    const { subscriptionId } = req.params;

    console.log(`🔍 Vérification paiement souscription #${subscriptionId}`);

    const subscription = await Subscription.findByPk(subscriptionId, {
      include: [{
        model: User,
        as: 'customer',
        attributes: ['id', 'email', 'first_name', 'last_name']
      }]
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }

    // Si déjà payé, retourner le statut
    if (subscription.payment_status === 'paid') {
      console.log(`✅ Souscription #${subscriptionId} déjà marquée comme payée`);
      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: 'paid',
          status: subscription.status
        }
      });
    }

    // Chercher la transaction FineoPay
    const syncRef = `SUBSCRIPTION_${subscriptionId}`;
    console.log(`🔍 Recherche transaction FineoPay pour syncRef: ${syncRef}`);

    try {
      const transactionsResponse = await axios.get(
        `${FINEOPAY_BASE_URL}/transactions`,
        {
          headers: {
            'businessCode': FINEOPAY_BUSINESS_CODE,
            'apiKey': FINEOPAY_API_KEY
          },
          params: { limit: 100 }
        }
      );

      const transactions = transactionsResponse.data.data?.transactions || [];
      console.log(`📊 ${transactions.length} transactions récupérées`);

      // Chercher une transaction correspondante
      const subscriptionAmount = parseFloat(subscription.price || 0);
      const subscriptionCreatedAt = new Date(subscription.created_at);
      const maxPaymentWindow = new Date(subscriptionCreatedAt.getTime() + 24 * 60 * 60 * 1000); // 24h

      const matchingTransaction = transactions.find(t => {
        // Par syncRef
        if (t.syncRef === syncRef) {
          console.log(`✅ Match par syncRef: ${t.reference}`);
          return true;
        }
        
        // Par description
        if (t.description && t.description.includes(`SUBSCRIPTION_${subscriptionId}`)) {
          console.log(`✅ Match par description: ${t.reference}`);
          return true;
        }
        
        // Par montant + fenêtre de temps
        const txDate = new Date(t.date);
        if (parseFloat(t.amount) === subscriptionAmount && 
            txDate > subscriptionCreatedAt && 
            txDate < maxPaymentWindow && 
            t.status === 'success') {
          console.log(`🔍 Match potentiel par montant/date: ${t.reference}`);
          return true;
        }
        
        return false;
      });

      if (matchingTransaction && matchingTransaction.status === 'success') {
        console.log(`✅ Transaction trouvée: ${matchingTransaction.reference}`);

        // Mettre à jour la souscription
        await subscription.update({
          payment_status: 'paid',
          status: 'active'
        });

        // Créer enregistrement Payment
        await Payment.create({
          subscriptionId: subscription.id,
          amount: matchingTransaction.amount,
          currency: 'XOF',
          provider: 'fineopay',
          paymentId: matchingTransaction.reference,
          status: 'completed',
          metadata: {
            fineopay_reference: matchingTransaction.reference,
            canal: matchingTransaction.canal,
            clientPhone: matchingTransaction.clientAccountNumber
          }
        });

        // Logger
        await PaymentLog.create({
          eventType: 'payment_confirmed',
          provider: 'fineopay',
          fineopayReference: matchingTransaction.reference,
          amount: matchingTransaction.amount,
          paymentStatus: 'paid',
          sourceIp: req.ip,
          success: true,
          metadata: { subscriptionId, type: 'subscription' }
        });

        console.log(`✅ Souscription #${subscriptionId} activée`);

        return res.status(200).json({
          success: true,
          data: {
            subscriptionId: subscription.id,
            payment_status: 'paid',
            status: 'active',
            reference: matchingTransaction.reference
          }
        });
      }

      // Aucune transaction trouvée
      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: 'pending',
          status: subscription.status
        }
      });

    } catch (apiError) {
      console.error('❌ Erreur API FineoPay:', apiError.message);
      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: subscription.payment_status,
          status: subscription.status
        }
      });
    }

  } catch (error) {
    console.error('❌ Erreur vérification souscription:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification',
      error: error.message
    });
  }
};

/**
 * Vérifier le statut de paiement d'un diagnostic d'intervention
 * Interroge directement l'API FineoPay
 */
const verifyDiagnosticPaymentStatus = async (req, res) => {
  try {
    const { interventionId } = req.params;

    console.log(`🔍 Vérification paiement diagnostic intervention #${interventionId}`);

    const intervention = await Intervention.findByPk(interventionId, {
      include: [{
        model: CustomerProfile,
        as: 'customer',
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }]
      }]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Si déjà payé, retourner le statut
    if (intervention.diagnostic_paid === true) {
      console.log(`✅ Diagnostic intervention #${interventionId} déjà marqué comme payé`);
      return res.status(200).json({
        success: true,
        data: {
          interventionId: intervention.id,
          diagnostic_paid: true,
          status: intervention.status
        }
      });
    }

    // Chercher la transaction FineoPay
    const syncRef = `DIAGNOSTIC_${interventionId}`;
    console.log(`🔍 Recherche transaction FineoPay pour syncRef: ${syncRef}`);

    try {
      const transactionsResponse = await axios.get(
        `${FINEOPAY_BASE_URL}/transactions`,
        {
          headers: {
            'businessCode': FINEOPAY_BUSINESS_CODE,
            'apiKey': FINEOPAY_API_KEY
          },
          params: { limit: 100 }
        }
      );

      const transactions = transactionsResponse.data.data?.transactions || [];
      console.log(`📊 ${transactions.length} transactions récupérées`);

      // Chercher une transaction correspondante
      const diagnosticAmount = parseFloat(intervention.diagnostic_fee || 10);
      const interventionCreatedAt = new Date(intervention.created_at);
      const maxPaymentWindow = new Date(interventionCreatedAt.getTime() + 24 * 60 * 60 * 1000); // 24h

      const matchingTransaction = transactions.find(t => {
        // Par syncRef
        if (t.syncRef === syncRef) {
          console.log(`✅ Match par syncRef: ${t.reference}`);
          return true;
        }
        
        // Par description
        if (t.description && t.description.includes(`DIAGNOSTIC_${interventionId}`)) {
          console.log(`✅ Match par description: ${t.reference}`);
          return true;
        }
        
        // Par montant + fenêtre de temps
        const txDate = new Date(t.date);
        if (parseFloat(t.amount) === diagnosticAmount && 
            txDate > interventionCreatedAt && 
            txDate < maxPaymentWindow && 
            t.status === 'success') {
          console.log(`🔍 Match potentiel par montant/date: ${t.reference}`);
          return true;
        }
        
        return false;
      });

      if (matchingTransaction && matchingTransaction.status === 'success') {
        console.log(`✅ Transaction trouvée: ${matchingTransaction.reference}`);

        // Mettre à jour l'intervention
        await intervention.update({
          diagnostic_paid: true,
          diagnostic_payment_date: new Date()
        });

        // Créer enregistrement Payment
        await Payment.create({
          interventionId: intervention.id,
          amount: matchingTransaction.amount,
          currency: 'XOF',
          provider: 'fineopay',
          paymentId: matchingTransaction.reference,
          status: 'completed',
          metadata: {
            fineopay_reference: matchingTransaction.reference,
            canal: matchingTransaction.canal,
            clientPhone: matchingTransaction.clientAccountNumber,
            type: 'diagnostic'
          }
        });

        // Logger
        await PaymentLog.create({
          eventType: 'diagnostic_payment_confirmed',
          provider: 'fineopay',
          fineopayReference: matchingTransaction.reference,
          amount: matchingTransaction.amount,
          paymentStatus: 'paid',
          sourceIp: req.ip,
          success: true,
          metadata: { interventionId, type: 'diagnostic' }
        });

        console.log(`✅ Diagnostic intervention #${interventionId} marqué comme payé`);

        return res.status(200).json({
          success: true,
          data: {
            interventionId: intervention.id,
            diagnostic_paid: true,
            status: intervention.status,
            reference: matchingTransaction.reference
          }
        });
      }

      // Aucune transaction trouvée
      return res.status(200).json({
        success: true,
        data: {
          interventionId: intervention.id,
          diagnostic_paid: false,
          status: intervention.status
        }
      });

    } catch (apiError) {
      console.error('❌ Erreur API FineoPay:', apiError.message);
      return res.status(200).json({
        success: true,
        data: {
          interventionId: intervention.id,
          diagnostic_paid: intervention.diagnostic_paid,
          status: intervention.status
        }
      });
    }

  } catch (error) {
    console.error('❌ Erreur vérification diagnostic:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification',
      error: error.message
    });
  }
};

/**
 * Initialiser un paiement de diagnostic pour une intervention
 */
const initializeDiagnosticPayment = async (req, res) => {
  try {
    const { interventionId } = req.body;
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement diagnostic pour intervention #${interventionId}`);

    if (!interventionId) {
      return res.status(400).json({
        success: false,
        message: 'interventionId est requis'
      });
    }

    // Récupérer l'intervention
    const intervention = await Intervention.findByPk(interventionId, {
      include: [{
        model: CustomerProfile,
        as: 'customer',
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        }]
      }]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Montant du diagnostic (peut être configuré dans la BDD ou ici)
    const diagnosticFee = intervention.diagnostic_fee || 10; // 10 FCFA pour test

    // Construire l'URL de callback
    const callbackUrl = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/fineopay/callback`;

    // Créer le lien de paiement FineoPay
    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title: `Diagnostic Intervention #${interventionId}`,
        amount: parseFloat(diagnosticFee),
        callbackUrl,
        syncRef: `DIAGNOSTIC_${interventionId}`,
        inputs: []
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    console.log('📥 Réponse FineoPay:', JSON.stringify(response.data, null, 2));

    if (response.data.success) {
      const checkoutLink = response.data.data.checkoutLink;
      const checkoutLinkId = checkoutLink.split('/').slice(-2, -1)[0];

      console.log(`✅ Lien de paiement diagnostic créé pour intervention #${interventionId}`);
      console.log(`🔗 URL: ${checkoutLink}`);

      // Mettre à jour le montant du diagnostic si nécessaire
      if (intervention.diagnostic_fee !== diagnosticFee) {
        await intervention.update({
          diagnostic_fee: diagnosticFee
        });
      }

      // Logger
      await PaymentLog.create({
        eventType: 'diagnostic_checkout_created',
        provider: 'fineopay',
        checkoutLinkId,
        amount: diagnosticFee,
        paymentStatus: 'pending',
        sourceIp: req.ip,
        success: true,
        metadata: { interventionId, type: 'diagnostic' }
      });

      return res.status(200).json({
        success: true,
        message: 'Lien de paiement diagnostic créé',
        data: {
          payment_url: checkoutLink,
          checkout_link_id: checkoutLinkId,
          intervention_id: interventionId,
          amount: diagnosticFee,
          transaction_id: `DIAG-${interventionId}-${Date.now()}`
        }
      });
    } else {
      throw new Error(response.data.message || 'Erreur FineoPay');
    }

  } catch (error) {
    console.error('❌ Erreur création paiement diagnostic:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du paiement diagnostic',
      error: error.message
    });
  }
};

module.exports = {
  createPaymentLink,
  handleCallback,
  checkTransactionStatus,
  listTransactions,
  checkOrderStatus,
  verifyPaymentStatus,
  verifySubscriptionPaymentStatus,
  verifyDiagnosticPaymentStatus,
  initializeDiagnosticPayment
};
