const axios = require('axios');
const { Quote, Order, Intervention, DiagnosticReport, User, TechnicianProfile, CustomerProfile, PaymentLog, Subscription, Payment } = require('../../models');
const {
  resolveOrderPaymentInitiation,
  PaymentInitiationError
} = require('../../services/payment/orderPaymentInitiationService');
const {
  verifyFineoPayWebhook,
  FineoPayWebhookVerificationError
} = require('../../services/payment/fineoPayWebhookVerificationService');
const {
  claimPaymentWebhook,
  markPaymentWebhookCompleted,
  markPaymentWebhookFailed
} = require('../../services/payment/paymentWebhookIdempotencyService');
const {
  recordShopPayment,
  recordDiagnosticPayment,
  recordSubscriptionPayment,
  recordQuoteOrderPayment
} = require('../../services/payment/fineoPayFinancialTransactionService');

// Configuration FineoPay - URLs OFFICIELLES de la documentation
// Sandbox: https://dev.fineopay.com/api/v1/business/dev
// Production: https://fineopay.com/api/v1/business/prod
const FINEOPAY_BASE_URL = process.env.FINEOPAY_BASE_URL || (
  process.env.FINEOPAY_ENV === 'production'
    ? 'https://fineopay.com/api/v1/business/prod'
    : 'https://dev.fineopay.com/api/v1/business/dev'
);

const FINEOPAY_BUSINESS_CODE = process.env.FINEOPAY_BUSINESS_CODE;
const FINEOPAY_API_KEY = process.env.FINEOPAY_API_KEY;

console.log('🔧 Configuration FineoPay:');
console.log('  - Environment:', process.env.FINEOPAY_ENV || 'sandbox');
console.log('  - Base URL:', FINEOPAY_BASE_URL);
console.log('  - Business Code:', FINEOPAY_BUSINESS_CODE);
console.log('  - API Key configurée:', Boolean(FINEOPAY_API_KEY));

const getCallbackUrl = () => {
  let baseUrl = process.env.API_BASE_URL || process.env.BACKEND_URL;
  if (!baseUrl || baseUrl.includes('localhost') || baseUrl.includes('127.0.0.1') || baseUrl.includes('192.168.')) {
    baseUrl = 'https://api.sandbox.mct.ci';
  }
  return `${baseUrl}/api/fineopay/callback`;
};

/**
 * Créer un lien de paiement FineoPay
 */
const createPaymentLink = async (req, res) => {
  try {
    const { orderId, customerInfo, redirectUrl, autoRedirect } = req.body;

    const paymentContext = await resolveOrderPaymentInitiation({
      orderId,
      user: req.user
    });
    const {
      order,
      amount,
      paymentStep,
      title,
      description
    } = paymentContext;

    // Construire l'URL de callback
    const callbackUrl = getCallbackUrl();

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
      redirectUrl,
      autoRedirect,
      syncRef: `ORDER_${orderId}`,
      inputs
    }, null, 2));

    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title,
        amount: parseFloat(amount),
        callbackUrl,
        ...(redirectUrl && { redirectUrl }),
        ...(autoRedirect !== undefined && { autoRedirect }),
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

    console.log(`📥 Réponse FineoPay reçue (success=${response.data?.success === true})`);

    if (response.data.success) {
      const checkoutLink = response.data.data.checkoutLink;
      // Extraire l'ID du checkout link depuis l'URL (format: .../BUSINESS_CODE/CHECKOUT_ID/checkout)
      const checkoutLinkId = checkoutLink.split('/').slice(-2, -1)[0];

      console.log(`✅ Lien de paiement FineoPay créé pour commande #${orderId}`);
      console.log(`🔑 Checkout ID: ${checkoutLinkId}`);

      // 🔒 Stocker le checkoutLinkId dans la commande pour un matching sécurisé
      const updateData = {
        fineopayCheckoutId: checkoutLinkId,
        paymentMethod: 'fineopay',
        syncRef: `ORDER_${orderId}`,
        paymentStep
      };
      await order.update(updateData);
      console.log(`📌 Paiement FineoPay - paymentStep=${paymentStep} pour commande #${orderId}`);
      console.log(`💾 Checkout ID et syncRef sauvegardés dans la commande #${orderId}`);

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
        rawData: { checkoutLink, syncRef: `ORDER_${orderId}`, paymentStep },
        success: true,
        metadata: { title, description, paymentStep }
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
    if (error instanceof PaymentInitiationError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }

    console.error(`❌ Erreur création lien FineoPay: ${error.message}`);
    console.error(`❌ Statut fournisseur: ${error.response?.status || 'indisponible'}`);

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
  const sourceIp = req.ip || req.connection?.remoteAddress;
  const signature = req.headers['x-fineopay-signature'] || req.headers['x-signature'];
  let webhookEvent = null;

  try {
    let verifiedWebhook;
    try {
      verifiedWebhook = await verifyFineoPayWebhook({
        body: req.body,
        rawBody: req.rawBody,
        signature,
        webhookSecret: process.env.FINEOPAY_WEBHOOK_SECRET,
        fetchTransaction: async (reference) => {
          const response = await axios.get(
            `${FINEOPAY_BASE_URL}/transactions/${encodeURIComponent(reference)}`,
            {
              headers: {
                businessCode: FINEOPAY_BUSINESS_CODE,
                apiKey: FINEOPAY_API_KEY
              },
              timeout: 10000
            }
          );
          return response.data;
        }
      });
    } catch (error) {
      if (!(error instanceof FineoPayWebhookVerificationError)) {
        throw error;
      }

      try {
        const receivedAmount = Number(req.body?.amount);
        await PaymentLog.create({
          eventType: error.code === 'INVALID_SIGNATURE'
            ? 'signature_invalid'
            : 'webhook_received',
          provider: 'fineopay',
          fineopayReference: req.body?.reference || null,
          amount: Number.isFinite(receivedAmount) ? receivedAmount : null,
          paymentStatus: req.body?.status || null,
          sourceIp,
          userAgent: req.get('User-Agent'),
          signatureValid: error.code === 'INVALID_SIGNATURE' ? false : null,
          rawData: {
            reference: req.body?.reference,
            syncRef: req.body?.syncRef,
            status: req.body?.status
          },
          success: false,
          errorMessage: `${error.code}: ${error.message}`
        });
      } catch (loggingError) {
        console.error('⚠️ Impossible de journaliser le webhook FineoPay refusé:', loggingError.message);
      }

      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
        code: error.code,
        retryable: error.retryable
      });
    }

    const {
      reference,
      amount,
      status,
      syncRef: bodySyncRef,
      transaction,
      signatureValid
    } = verifiedWebhook;
    const clientAccountNumber = transaction.clientAccountNumber
      || transaction.clientAccount
      || req.body?.clientAccountNumber
      || req.body?.clientAccount;
    const timestamp = transaction.timestamp || req.body?.timestamp;

    const claim = await claimPaymentWebhook({
      provider: 'fineopay',
      reference,
      syncRef: bodySyncRef,
      status,
      amount
    });

    if (!claim.acquired) {
      await PaymentLog.create({
        eventType: 'duplicate_blocked',
        provider: 'fineopay',
        fineopayReference: reference,
        amount,
        paymentStatus: status,
        sourceIp,
        success: claim.reason !== 'payload_mismatch',
        errorMessage: `Webhook non retraité: ${claim.reason}`,
        metadata: { syncRef: bodySyncRef }
      });

      if (claim.reason === 'payload_mismatch') {
        return res.status(409).json({
          success: false,
          message: 'Référence FineoPay rejouée avec des données différentes',
          code: 'WEBHOOK_PAYLOAD_MISMATCH'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Notification déjà prise en compte',
        duplicate: true
      });
    }

    webhookEvent = claim.event;
    const completeAndAcknowledge = async () => {
      await markPaymentWebhookCompleted(webhookEvent);
      return res.status(200).json({ success: true, message: 'Notification traitée' });
    };

    console.log('📨 Callback FineoPay reçu:', {
      reference,
      amount,
      status,
      clientAccountNumber,
      timestamp,
      sourceIp,
      hasSignature: !!signature
    });

    // Journaliser uniquement les champs utiles après confirmation par FineoPay.
    await PaymentLog.create({
      eventType: 'webhook_received',
      provider: 'fineopay',
      fineopayReference: reference,
      amount,
      paymentStatus: status,
      sourceIp,
      userAgent: req.get('User-Agent'),
      signatureValid,
      rawData: { reference, syncRef: bodySyncRef, status },
      success: true
    });

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

      // 📱 Envoyer des notifications d'échec de paiement
      try {
        const notificationService = require('../../services/notificationService');
        const { Order, Quote, Intervention, CustomerProfile, Subscription } = require('../../models');

        // Parser le syncRef pour identifier le type de paiement
        const syncRef = bodySyncRef || '';
        const shopOrderMatch = syncRef.match(/SHOP_ORDER_(\d+)/);
        const diagnosticMatch = syncRef.match(/DIAGNOSTIC_(\d+)/);
        const subscriptionMatch = syncRef.match(/SUBSCRIPTION_(\d+)/);
        const quoteOrderMatch = syncRef.match(/ORDER_(\d+)/);

        let userId = null;
        let customerName = 'Un client';
        let failureMessage = '';
        let failureData = {};

        if (diagnosticMatch) {
          // Échec paiement diagnostic
          const interventionId = parseInt(diagnosticMatch[1]);
          const intervention = await Intervention.findByPk(interventionId, {
            include: [{ model: CustomerProfile, as: 'customer', include: [{ model: User, as: 'user' }] }]
          });
          if (intervention?.customer?.user) {
            userId = intervention.customer.user.id;
            customerName = `${intervention.customer.first_name || ''} ${intervention.customer.last_name || ''}`.trim() || 'Un client';
            failureMessage = `Votre paiement de ${amount} FCFA pour le diagnostic de l'intervention #${interventionId} a échoué. Veuillez réessayer.`;
            failureData = { intervention_id: interventionId, amount: parseFloat(amount), reference, status };
          }
        } else if (subscriptionMatch) {
          // Échec paiement souscription
          const subscriptionId = parseInt(subscriptionMatch[1]);
          const subscription = await Subscription.findByPk(subscriptionId, {
            include: [{ model: User, as: 'customer' }]
          });
          if (subscription?.customer) {
            userId = subscription.customer.id;
            customerName = `${subscription.customer.first_name || ''} ${subscription.customer.last_name || ''}`.trim() || 'Un client';
            failureMessage = `Votre paiement de ${amount} FCFA pour votre abonnement a échoué. Veuillez réessayer.`;
            failureData = { subscription_id: subscriptionId, amount: parseFloat(amount), reference, status };
          }
        } else if (shopOrderMatch) {
          // Échec paiement boutique
          const orderId = parseInt(shopOrderMatch[1]);
          const order = await Order.findByPk(orderId);
          if (order?.customerId) {
            const customerProfile = await CustomerProfile.findByPk(order.customerId);
            userId = customerProfile?.user_id;
            customerName = customerProfile ? `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() || 'Un client' : 'Un client';
            failureMessage = `Votre paiement de ${amount} FCFA pour la commande #${orderId} a échoué. Veuillez réessayer.`;
            failureData = { order_id: orderId, amount: parseFloat(amount), reference, status };
          }
        } else if (quoteOrderMatch) {
          // Échec paiement devis (logique existante via fineopayReference)
          const order = await Order.findOne({
            where: { fineopayReference: reference },
            include: [{ model: Quote, as: 'quote', include: [{ model: Intervention, as: 'intervention', include: [{ model: CustomerProfile, as: 'customer' }] }] }]
          });
          if (order?.quote?.intervention?.customer) {
            const customer = order.quote.intervention.customer;
            userId = customer.user_id;
            customerName = customer.first_name ? `${customer.first_name} ${customer.last_name || ''}`.trim() : 'Un client';
            failureMessage = `Votre paiement de ${amount} FCFA pour la commande ${order.reference} a échoué. Veuillez réessayer.`;
            failureData = { order_id: order.id, amount: parseFloat(amount), reference, status };
          }
        }

        // Notification au client
        if (userId) {
          await notificationService.create({
            userId,
            type: 'payment_failed',
            title: '❌ Échec de paiement',
            message: failureMessage,
            data: failureData,
            priority: 'high'
          });
          console.log(`📲 Notification d'échec envoyée au client`);
        }

        // Notification aux admins
        await notificationService.notifyAdmins({
          type: 'payment_failed',
          title: '❌ Échec de paiement',
          message: `Paiement de ${amount} FCFA échoué pour ${customerName} (réf: ${syncRef || reference})`,
          data: { ...failureData, syncRef, customerId: userId },
          priority: 'high'
        });
        console.log(`📲 Notification d'échec envoyée aux admins`);
      } catch (notifError) {
        console.error('⚠️ Erreur envoi notification d\'échec:', notifError.message);
      }

      return completeAndAcknowledge();
    }

    const syncRef = bodySyncRef;
    console.log(`✅ Transaction vérifiée auprès de FineoPay: ${reference}`);

    // Si on n'a pas de syncRef, on ne peut pas traiter
    if (!syncRef) {
      console.log(`⚠️ Aucun syncRef disponible pour traiter le callback`);
      await PaymentLog.create({
        eventType: 'callback_error',
        provider: 'fineopay',
        fineopayReference: reference,
        amount: parseFloat(amount),
        paymentStatus: status,
        sourceIp,
        success: false,
        errorMessage: 'Aucun syncRef disponible'
      });
      throw new Error('Aucun syncRef disponible pour traiter le callback');
    }

    console.log(`📋 Traitement avec syncRef: ${syncRef}`);

    // Extraire l'ID de la commande depuis syncRef

    // Vérifier si c'est une commande de devis (ORDER_xxx), une commande de boutique (SHOP_ORDER_xxx), une souscription (SUBSCRIPTION_xxx) ou un diagnostic (DIAGNOSTIC_xxx)
    let orderId;
    let isShopOrder = false;
    let isSubscription = false;
    let isDiagnostic = false;

    const shopOrderMatch = syncRef.match(/^SHOP_ORDER_(\d+)$/);
    const quoteOrderMatch = syncRef.match(/^ORDER_(\d+)$/);
    const subscriptionMatch = syncRef.match(/^SUBSCRIPTION_(\d+)$/);
    const diagnosticMatch = syncRef.match(/^DIAGNOSTIC_(\d+)$/);

    if (diagnosticMatch) {
      const interventionId = parseInt(diagnosticMatch[1]);
      isDiagnostic = true;
      console.log(`🔬 Traitement paiement diagnostic pour intervention #${interventionId}`);
      await handleDiagnosticPayment(interventionId, reference, amount, sourceIp);
      return completeAndAcknowledge();
    } else if (shopOrderMatch) {
      orderId = parseInt(shopOrderMatch[1]);
      isShopOrder = true;
      console.log(`🛒 Traitement paiement boutique pour commande #${orderId}`);
    } else if (subscriptionMatch) {
      const subscriptionId = parseInt(subscriptionMatch[1]);
      isSubscription = true;
      console.log(`📋 Traitement paiement souscription #${subscriptionId}`);
      await handleSubscriptionPayment(subscriptionId, reference, amount, sourceIp);
      return completeAndAcknowledge();
    } else if (quoteOrderMatch) {
      orderId = parseInt(quoteOrderMatch[1]);
      console.log(`📦 Traitement paiement devis pour commande #${orderId}`);
    } else {
      throw new Error(`syncRef FineoPay non reconnu: ${syncRef}`);
    }

    // Si c'est une commande de boutique, traiter différemment
    if (isShopOrder) {
      await handleShopOrderPayment(orderId, reference, amount);
      return completeAndAcknowledge();
    }

    // Sinon, c'est une commande de devis (logique existante)
    console.log(`📦 Traitement paiement de devis pour commande #${orderId}`);

    const quoteFinancialResult = await recordQuoteOrderPayment({
      orderId,
      reference,
      amount,
      sourceIp,
      clientAccountNumber
    });
    if (quoteFinancialResult.duplicate) {
      console.log(`ℹ️ Paiement devis ${reference} déjà enregistré`);
      return completeAndAcknowledge();
    }

    // Les notifications, l'assignation et les actions post-paiement sont
    // inscrites atomiquement dans l'outbox par recordQuoteOrderPayment.
    // Le callback ne doit pas produire d'effet externe directement.
    console.log(`📤 Effets du devis ${orderId} confiés à l’outbox pour ${reference}`);
    return completeAndAcknowledge();

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
      throw new Error(`Commande #${orderId} introuvable`);
    }

    // 💰 Vérifier le contexte de paiement split
    // Note: Quote est déjà importé en haut du fichier
    // 🔧 FIX: Utiliser order.quoteId OU order.quote_id (selon le mapping Sequelize)
    const orderQuoteId = order.quoteId || order.quote_id;
    const orderPaymentStep = order.paymentStep ?? order.payment_step ?? 1;
    const orderPaymentType = order.paymentType || order.payment_type || 'full';

    console.log(`📋 Callback debug - orderId: ${orderId}, quoteId: ${orderQuoteId}, paymentStep: ${orderPaymentStep}, paymentType: ${orderPaymentType}`);

    const quote = orderQuoteId ? await Quote.findByPk(orderQuoteId) : null;
    // Priorité à l'Order.paymentType car c'est le choix actuel du client
    // Ne pas se fier au Quote.payment_type qui peut être obsolète
    const isSplitPayment = quoteFinancialResult.isSplitPayment;
    const paymentStep = quoteFinancialResult.paymentStep;
    const quoteFirstPaymentPending = quote && (quote.first_payment_status === 'pending' || quote.first_payment_status == null);
    const quoteSecondPaymentPending = quote && (quote.second_payment_status === 'pending' || quote.second_payment_status == null);

    console.log(`📋 Split check - isSplitPayment: ${isSplitPayment}, orderPaymentType: ${orderPaymentType}, quote: ${quote ? 'found' : 'null'}, quote.payment_type: ${quote?.payment_type}, firstPending: ${quoteFirstPaymentPending}, secondPending: ${quoteSecondPaymentPending}, resolvedStep: ${paymentStep}`);

    console.log(`💰 Mise à jour du paiement pour commande #${orderId} (step ${paymentStep}, split: ${isSplitPayment})`);

    console.log(`✅ Commande #${orderId} marquée comme payée`);

    // Mettre à jour le devis associé et gérer l'exécution différée
    if (orderQuoteId && quote) {
      // Note: Intervention, User sont déjà importés en haut du fichier
      const notificationService = require('../../services/notificationService');

      let quoteUpdateData = {};
      if (isSplitPayment && paymentStep === 1) {
        // Premier paiement (50%) reçu
        quoteUpdateData = {
          first_payment_status: 'paid',
          first_payment_date: new Date(),
          first_payment_transaction_id: reference,
          payment_status: 'partial' // Partiellement payé
        };
        console.log(`✅ Devis #${orderQuoteId} - Premier paiement (50%) marqué comme payé via webhook`);
      } else if (isSplitPayment && paymentStep === 2) {
        // Second paiement (50%) reçu
        quoteUpdateData = {
          second_payment_status: 'paid',
          second_payment_date: new Date(),
          second_payment_transaction_id: reference,
          payment_status: 'paid' // Totalement payé
        };
        console.log(`✅ Devis #${orderQuoteId} - Second paiement (50%) marqué comme payé via webhook - COMPLET`);
      } else {
        // Paiement intégral (non-split)
        quoteUpdateData = {
          payment_status: 'paid',
          payment_type: 'full' // S'assurer que le type est bien 'full'
        };
        console.log(`✅ Devis #${orderQuoteId} marqué comme payé via webhook (paiement intégral)`);
      }

      console.log(`✅ Devis #${orderQuoteId} mis à jour:`, quoteUpdateData); // nosemgrep: unsafe-formatstring

      // 📬 Notifier les admins de l'acceptation et de la planification APRÈS le paiement
      try {
        const { notifyQuoteAccepted } = require('../../services/notificationHelpers');
        const customerProfile = await CustomerProfile.findByPk(quote.customerId || quote.customer_id, {
          include: [{ model: User, as: 'user' }]
        });
        if (customerProfile && quoteFinancialResult.executionActivated) {
          await notifyQuoteAccepted(quote, customerProfile);
          console.log('✅ Notification envoyée aux admins (post-paiement) : devis accepté et intervention planifiée');
        }
      } catch (notifErr) {
        console.error('⚠️ Erreur notification admin post-paiement:', notifErr.message);
      }

      // 🔧 Si paiement différé (execute_now = false), passer l'intervention en execution_confirmed
      if (quoteFinancialResult.executionActivated && quote && quote.execute_now === false && quote.intervention_id) {
        const intervention = await Intervention.findByPk(quote.intervention_id, {
          include: [{ model: User, as: 'technician' }]
        });

        if (intervention) {
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
                interventionId: intervention.id,
                scheduled_date: quote.scheduled_date,
                role: 'technician'
              },
              priority: 'high',
              actionUrl: `/interventions/${intervention.id}`
            });
            console.log(`📲 Notification envoyée au technicien (user_id: ${intervention.technician_id})`);
          } else {
            // Assignation automatique si aucun technicien n'est assigné
            try {
              const schedulingService = require('../../services/schedulingService');
              await schedulingService.autoAssignIntervention(intervention.id);
            } catch (err) {
              console.error(`⚠️ Assignation automatique échouée pour l'intervention ${intervention.id}: ${err.message}`);

              // Notifier le client qu'on cherche une équipe
              if (intervention.customer && intervention.customer.user_id) {
                await notificationService.create({
                  userId: intervention.customer.user_id,
                  type: 'technician_search',
                  title: '🔍 Recherche d\'équipe',
                  message: `Votre demande est confirmée ! Nous recherchons actuellement l'équipe la plus proche et vous tiendrons informé.`,
                  data: { intervention_id: intervention.id, role: 'client' },
                  priority: 'high'
                });
              }

              // TODO: Notifier les managers (Nécessite la liste des managers ou un broadcast)
              // Pour l'instant, c'est tracé dans les logs
            }
          }
        }
      }

      // 🔧 Si exécution immédiate (execute_now = true), passer l'intervention en execution_confirmed après paiement
      if (quoteFinancialResult.executionActivated && quote && quote.execute_now === true && quote.intervention_id) {
        const intervention = await Intervention.findByPk(quote.intervention_id, {
          include: [{ model: User, as: 'technician' }]
        });

        if (intervention) {
          console.log(`🔄 Intervention ${intervention.id} mise à jour: status = execution_confirmed (exécution immédiate via webhook)`);

          // Notifier le technicien maintenant que le paiement est confirmé
          const notificationService = require('../../services/notificationService');
          if (intervention.technician_id) {
            await notificationService.create({
              userId: intervention.technician_id,
              type: 'quote_execution_confirmed',
              title: '✅ Paiement confirmé - Exécution immédiate',
              message: `Le client a payé le devis ${quote.reference}. Vous pouvez procéder à l'intervention immédiatement.`,
              data: {
                quote_id: quote.id,
                quote_reference: quote.reference,
                intervention_id: intervention.id,
                interventionId: intervention.id,
                execute_now: true,
                role: 'technician'
              },
              priority: 'high',
              actionUrl: `/interventions/${intervention.id}`
            });
            console.log(`📲 Notification envoyée au technicien pour exécution immédiate (user_id: ${intervention.technician_id})`);
          } else {
            // Assignation automatique si aucun technicien n'est assigné
            try {
              const schedulingService = require('../../services/schedulingService');
              await schedulingService.autoAssignIntervention(intervention.id);
            } catch (err) {
              console.error(`⚠️ Assignation automatique échouée pour l'intervention ${intervention.id}: ${err.message}`);

              // Notifier le client qu'on cherche une équipe
              if (intervention.customer && intervention.customer.user_id) {
                await notificationService.create({
                  userId: intervention.customer.user_id,
                  type: 'technician_search',
                  title: '🔍 Recherche d\'équipe',
                  message: `Votre demande est confirmée ! Nous recherchons actuellement l'équipe la plus proche et vous tiendrons informé.`,
                  data: { intervention_id: intervention.id, role: 'client' },
                  priority: 'high'
                });
              }
            }
          }
        }
      }

      // Notifier les admins et managers (Dashboard) que le paiement du devis est confirmé
      try {
        const { User } = require('../../models');
        const { Op } = require('sequelize');
        const admins = await User.findAll({ where: { role: { [Op.in]: ['admin', 'manager'] }, status: 'active' } });
        for (const admin of admins) {
          await notificationService.create({
            userId: admin.id,
            type: 'quote_paid',
            title: '✅ Devis payé - Exécution autorisée',
            message: `Le devis ${quote.reference} pour l'intervention #${quote.intervention_id} a été payé par le client. Exécution autorisée.`,
            data: { quote_id: quote.id, intervention_id: quote.intervention_id, role: 'admin' },
            priority: 'high',
            actionUrl: `/interventions/${quote.intervention_id}`
          });
        }
      } catch (adminNotifErr) {
        console.error('⚠️ Erreur notification admin paiement devis:', adminNotifErr.message);
      }
    }

    console.log(`✅ Commande #${orderId} traitée avec succès`);

    // Envoyer une notification de paiement réussi au client
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
    if (quoteFinancialResult.executionActivated && quote.diagnosticReport && quote.intervention) {
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

    return completeAndAcknowledge();

  } catch (error) {
    console.error('❌ Erreur traitement callback FineoPay:', error);
    if (webhookEvent) {
      try {
        await markPaymentWebhookFailed(webhookEvent, error);
      } catch (trackingError) {
        console.error(`⚠️ Impossible de marquer le webhook FineoPay en échec: ${trackingError.message}`);
      }
    }
    if (!res.headersSent) {
      return res.status(500).json({
        success: false,
        message: 'Le traitement du paiement a échoué et peut être réessayé',
        code: 'WEBHOOK_PROCESSING_FAILED',
        retryable: true
      });
    }
  }
};

/**
 * Vérifier le statut d'une transaction
 */
const checkTransactionStatus = async (req, res) => {
  try {
    const { reference } = req.params;
    const user = req.user;

    // SÉCURITÉ : vérifier que la transaction appartient à l'utilisateur,
    // sauf si c'est un admin ou manager (qui peuvent tout voir).
    if (user.role !== 'admin' && user.role !== 'manager') {
      const payment = await Payment.findOne({ where: { reference } });
      if (!payment) {
        return res.status(404).json({
          success: false,
          message: 'Transaction introuvable'
        });
      }
      // Vérifier que la transaction est liée à cet utilisateur
      const isOwner = payment.customer_id === user.id || payment.user_id === user.id;
      if (!isOwner) {
        return res.status(403).json({
          success: false,
          message: 'Accès refusé : cette transaction ne vous appartient pas'
        });
      }
    }

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
    const { order, duplicate } = await recordShopPayment({ orderId, reference, amount });
    if (duplicate) {
      console.log(`ℹ️ Paiement boutique ${reference} déjà enregistré`);
      return;
    }

    console.log(`✅ Commande boutique #${orderId} marquée comme payée`);
    console.log(`📤 Notifications boutique confiées à l’outbox pour ${reference}`);

  } catch (error) {
    console.error(`❌ Erreur traitement paiement boutique #${orderId}:`, error); // nosemgrep: unsafe-formatstring
    throw error;
  }
};

/**
 * Gérer le paiement d'une souscription
 */
const handleSubscriptionPayment = async (subscriptionId, reference, amount, sourceIp) => {
  try {
    console.log(`📋 Traitement paiement souscription #${subscriptionId}`);
    const { subscription, paymentStep, duplicate } = await recordSubscriptionPayment({
      subscriptionId,
      reference,
      amount,
      sourceIp
    });
    if (duplicate) {
      console.log(`ℹ️ Paiement souscription ${reference} déjà enregistré`);
      return;
    }
    // L'activation éventuelle du contrat et les notifications sont confiées à
    // l'outbox, créée dans la même transaction que l'écriture de paiement.
    console.log(`📤 Effets de la souscription ${subscriptionId} confiés à l’outbox pour ${reference}`);
    return;

  } catch (error) {
    console.error(`❌ Erreur traitement paiement souscription #${subscriptionId}:`, error); // nosemgrep: unsafe-formatstring

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
    throw error;
  }
};

/**
 * Gérer le second paiement d'un contrat (50% à la dernière visite)
 */
const handleSecondSubscriptionPayment = async (subscription, reference, amount, sourceIp) => {
  try {
    const subscriptionId = subscription.id;
    console.log(`💳 Traitement second paiement (50%) souscription #${subscriptionId}`);

    console.log(`✅ Second paiement confirmé - Contrat #${subscriptionId} complété`);

    // Notifier le client
    const notificationService = require('../../services/notificationService');

    if (subscription.customer_id) {
      await notificationService.create({
        userId: subscription.customer_id,
        type: 'payment_received',
        title: '🎉 Contrat complété !',
        message: `Votre paiement final de ${amount} FCFA a été confirmé. Merci pour votre confiance ! Pensez à renouveler votre contrat.`,
        data: {
          subscription_id: subscriptionId,
          amount: amount,
          reference: reference,
          payment_phase: 2
        },
        priority: 'high',
        actionUrl: '/contrats'
      });
    }

    // 📱 Notifier les admins du second paiement reçu
    const customerProfile = subscription.customer;
    const customerName = customerProfile ?
      `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() : 'Un client';

    await notificationService.notifyAdmins({
      type: 'payment_received',
      title: '💰 Paiement final contrat reçu',
      message: `Second paiement (50%) de ${amount} FCFA reçu de ${customerName} - Contrat terminé`,
      data: {
        subscriptionId,
        amount: parseFloat(amount),
        paymentType: 'subscription_second_payment',
        reference
      },
      priority: 'medium',
      actionUrl: `/dashboard`
    });

    console.log(`📲 Notification second paiement envoyée aux admins`);

  } catch (error) {
    console.error(`❌ Erreur traitement second paiement souscription #${subscription.id}:`, error); // nosemgrep: unsafe-formatstring

    // Logger l'erreur
    await PaymentLog.create({
      eventType: 'payment_failed',
      provider: 'fineopay',
      fineopayReference: reference,
      amount: parseFloat(amount),
      success: false,
      errorMessage: error.message,
      metadata: { subscriptionId: subscription.id, type: 'subscription', payment_phase: 2 }
    });
    throw error;
  }
};

/**
 * Gérer le paiement d'un diagnostic d'intervention
 */
const handleDiagnosticPayment = async (interventionId, reference, amount, sourceIp) => {
  try {
    console.log(`🔬 Traitement paiement diagnostic #${interventionId}`);
    const { intervention, paymentStep, duplicate } = await recordDiagnosticPayment({
      interventionId,
      reference,
      amount,
      sourceIp
    });
    if (duplicate) {
      console.log(`ℹ️ Paiement diagnostic ${reference} déjà enregistré`);
      return;
    }

    console.log(`✅ Paiement diagnostic étape ${paymentStep} de ${amount} FCFA enregistré pour l'intervention #${intervention.id}`);
    console.log(`📤 Effets diagnostic confiés à l’outbox pour ${reference}`);

  } catch (error) {
    console.error(`❌ Erreur traitement paiement diagnostic #${interventionId}:`, error); // nosemgrep: unsafe-formatstring
    throw error;
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
    const orderQuoteIdInfo = order.quoteId || order.quote_id;
    if (orderQuoteIdInfo) {
      const quote = await Quote.findByPk(orderQuoteIdInfo);
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

    if (req.user && req.user.role === 'customer') {
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: req.user.id } });
      const validProfileIds = customerProfile ? [req.user.id, customerProfile.id] : [req.user.id];
      const orderCustomerId = order.customerId || order.customer_id;
      const isOwner = validProfileIds.includes(orderCustomerId) || (order.customer && (validProfileIds.includes(order.customer.user_id) || validProfileIds.includes(order.customer.id)));
      if (!isOwner) {
        return res.status(404).json({
          success: false,
          message: 'Commande non trouvée'
        });
      }
    }

    // Vérifier l'état du devis associé pour les paiements split partiels
    const orderQuoteId = order.quoteId || order.quote_id;
    const quote = orderQuoteId ? await Quote.findByPk(orderQuoteId) : null;
    const isSplitPayment = (order.paymentType || order.payment_type) === 'split' && (order.paymentStep ?? 1) > 0;
    const isSplitPartial = isSplitPayment && quote && quote.payment_status === 'partial';

    if (order.paymentStatus === 'paid' && !isSplitPartial) {
      console.log(`✅ Commande #${orderId} déjà marquée comme payée`);
      // 🔧 S'assurer que le devis associé reflète aussi le statut paid
      if (quote && quote.payment_status !== 'paid') {
        const isFull = !isSplitPayment;
        await quote.update({
          payment_status: 'paid',
          ...(isFull ? { payment_type: 'full' } : {})
        });
        console.log(`🔧 Sync devis #${quote.id} payment_status => paid lors du check précoce`);
      }
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

    if (order.paymentStatus === 'paid' && isSplitPartial) {
      console.log(`⚠️ Commande split #${orderId} déjà payée côté ordre mais devis partiel, retour pending pour second paiement.`);
    }

    // Chercher la transaction dans FineoPay
    const syncRef = order.syncRef || `ORDER_${orderId}`;
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

      // La vérification active accepte uniquement l'identifiant de synchronisation
      // et le montant exacts. L'idempotence est assurée par le ledger transactionnel.
      const orderCreatedAt = new Date(order.createdAt);
      const orderAmount = parseFloat(order.totalAmount);
      const firstAmount = quote?.first_payment_amount != null
        ? parseFloat(quote.first_payment_amount)
        : Math.ceil(orderAmount / 2);
      const secondAmount = quote?.second_payment_amount != null
        ? parseFloat(quote.second_payment_amount)
        : (orderAmount - firstAmount);

      const matchingTransaction = transactions.find((transaction) => {
        const statusOk = transaction.status === 'success';
        const txAmount = Math.round(Number(transaction.amount) * 100);
        const amountOk = txAmount > 0 && (
          txAmount === Math.round(orderAmount * 100) ||
          txAmount === Math.round(firstAmount * 100) ||
          txAmount === Math.round(secondAmount * 100) ||
          txAmount === Math.round(orderAmount * 0.5 * 100)
        );
        const titleOk = (orderRef && transaction.payLink?.title?.includes(orderRef))
          || transaction.payLink?.title?.includes(`#${orderId}`);
        const syncRefOk = transaction.syncRef === syncRef;
        const checkoutIdOk = !checkoutLinkId || !transaction.checkoutLinkId || transaction.checkoutLinkId === checkoutLinkId;
        return statusOk && amountOk && checkoutIdOk && (titleOk || syncRefOk);
      });

      if (matchingTransaction) {
        console.log(`✅ Transaction trouvée:`, JSON.stringify(matchingTransaction, null, 2));

        if (matchingTransaction.status === 'success') {
          const financialResult = orderQuoteId
            ? await recordQuoteOrderPayment({
              orderId,
              reference: matchingTransaction.reference,
              amount: matchingTransaction.amount,
              sourceIp: req.ip,
              clientAccountNumber: matchingTransaction.clientAccountNumber
            })
            : await recordShopPayment({
              orderId,
              reference: matchingTransaction.reference,
              amount: matchingTransaction.amount
            });
          console.log(`📤 Vérification active ${matchingTransaction.reference} finalisée via transaction/outbox`);
          return res.status(200).json({
            success: true,
            data: {
              orderId: order.id,
              reference: order.reference,
              paymentStatus: 'paid',
              paymentMethod: 'fineopay',
              amount: order.totalAmount,
              duplicate: financialResult.duplicate
            }
          });

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

          const quoteForStatus = (order.quoteId || order.quote_id) ? await Quote.findByPk(order.quoteId || order.quote_id) : null;
          const targetOrderStatus = (quoteForStatus && quoteForStatus.execute_now === false) ? 'scheduled' : 'processing';

          // Mettre à jour le statut de la commande ET le statut de paiement
          await order.update({
            status: targetOrderStatus,
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

          // Import des services nécessaires
          const notificationService = require('../../services/notificationService');

          // Mettre à jour le devis associé
          const orderQuoteIdVerify = order.quoteId || order.quote_id;
          if (orderQuoteIdVerify) {
            // Récupérer le devis avec ses informations
            const quote = quoteForStatus || await Quote.findByPk(orderQuoteIdVerify);

            // Déterminer si c'est le premier ou second paiement (split payment)
            const paymentStep = order.paymentStep ?? order.payment_step ?? 0;
            const isSplitPayment = (order.paymentType || order.payment_type) === 'split' && paymentStep > 0;

            let quoteUpdateData = {};
            if (isSplitPayment && paymentStep === 1) {
              // Premier paiement (50%) reçu
              quoteUpdateData = {
                first_payment_status: 'paid',
                first_payment_date: new Date(),
                first_payment_transaction_id: matchingTransaction.reference,
                payment_status: 'partial' // Partiellement payé
              };
              console.log(`✅ Devis #${orderQuoteIdVerify} - Premier paiement (50%) marqué comme payé`);
            } else if (isSplitPayment && paymentStep === 2) {
              // Second paiement (50%) reçu
              quoteUpdateData = {
                second_payment_status: 'paid',
                second_payment_date: new Date(),
                second_payment_transaction_id: matchingTransaction.reference,
                payment_status: 'paid' // Totalement payé
              };
              console.log(`✅ Devis #${orderQuoteIdVerify} - Second paiement (50%) marqué comme payé - COMPLET`);
            } else {
              // Paiement intégral (100%)
              quoteUpdateData = {
                payment_status: 'paid',
                payment_type: 'full'
              };
              console.log(`✅ Devis #${orderQuoteIdVerify} marqué comme payé (100% intégral)`);
            }

            await Quote.update(quoteUpdateData, { where: { id: orderQuoteIdVerify } });

            // 📬 Notifier les admins de l'acceptation et de la planification APRÈS le paiement
            try {
              const { notifyQuoteAccepted } = require('../../services/notificationHelpers');
              const customerProfile = await CustomerProfile.findByPk(quote.customerId || quote.customer_id, {
                include: [{ model: User, as: 'user' }]
              });
              if (customerProfile) {
                await notifyQuoteAccepted(quote, customerProfile);
                console.log('✅ Notification envoyée aux admins (verifyPaymentStatus) : devis accepté et intervention planifiée');
              }
            } catch (notifErr) {
              console.error('⚠️ Erreur notification admin (verifyPaymentStatus):', notifErr.message);
            }

            // 🔧 Si paiement différé (execute_now = false), passer l'intervention en execution_confirmed
            if (quote && quote.execute_now === false && quote.intervention_id) {
              const intervention = await Intervention.findByPk(quote.intervention_id, {
                include: [{ model: User, as: 'technician' }]
              });

              if (intervention) {
                await intervention.update({
                  status: 'execution_confirmed',
                  intervention_type: intervention.intervention_type || 'execution',
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
                      interventionId: intervention.id,
                      scheduled_date: quote.scheduled_date,
                      role: 'technician'
                    },
                    priority: 'high',
                    actionUrl: `/interventions/${intervention.id}`
                  });
                  console.log(`📲 Notification envoyée au technicien (user_id: ${intervention.technician_id})`);
                }
              }
            }

            // 🔧 Si exécution immédiate (execute_now = true), passer l'intervention en execution_confirmed après paiement
            if (quote && quote.execute_now === true && quote.intervention_id) {
              const intervention = await Intervention.findByPk(quote.intervention_id, {
                include: [{ model: User, as: 'technician' }]
              });

              if (intervention) {
                await intervention.update({
                  status: 'execution_confirmed',
                  notes: `${intervention.notes || ''}\n\n[${new Date().toISOString()}] ⚡ PAIEMENT CONFIRMÉ - Exécution immédiate autorisée - Devis ${quote.reference}`
                });
                console.log(`🔄 Intervention ${intervention.id} mise à jour: status = execution_confirmed (exécution immédiate)`);

                // Notifier le technicien maintenant que le paiement est confirmé
                if (intervention.technician_id) {
                  await notificationService.create({
                    userId: intervention.technician_id,
                    type: 'quote_execution_confirmed',
                    title: '✅ Paiement confirmé - Exécution immédiate',
                    message: `Le client a payé le devis ${quote.reference}. Vous pouvez procéder à l'intervention immédiatement.`,
                    data: {
                      quote_id: quote.id,
                      quote_reference: quote.reference,
                      intervention_id: intervention.id,
                      interventionId: intervention.id,
                      execute_now: true,
                      role: 'technician'
                    },
                    priority: 'high',
                    actionUrl: `/interventions/${intervention.id}`
                  });
                  console.log(`📲 Notification envoyée au technicien pour exécution immédiate (user_id: ${intervention.technician_id})`);
                }
              }
            }
          }

          console.log(`✅ Commande #${orderId} marquée comme payée`);

          // Envoyer une notification au client (notificationService déjà importé plus haut)
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
 * Gère le système 50/50 : premier paiement à la validation, second à la dernière visite
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

    if (req.user && req.user.role === 'customer') {
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: req.user.id } });
      const validUserIds = customerProfile ? [req.user.id, customerProfile.id] : [req.user.id];
      const subCustomerId = subscription.customer_id || subscription.userId || subscription.user_id;
      if (!validUserIds.includes(subCustomerId)) {
        return res.status(404).json({
          success: false,
          message: 'Souscription non trouvée'
        });
      }
    }

    // Calculer les montants 50/50 s'ils ne sont pas définis
    const price = parseFloat(subscription.price || 0);
    const firstPaymentAmount = subscription.first_payment_amount || Math.ceil(price / 2);
    const secondPaymentAmount = subscription.second_payment_amount || Math.floor(price / 2);

    // Si premier paiement déjà fait, vérifier si le contrat est activé
    if (subscription.first_payment_status === 'paid') {
      console.log(`✅ Souscription #${subscriptionId} - Premier paiement déjà confirmé`);

      // Aucun appel passerelle n'est nécessaire pour un solde nul. L'état
      // persistant reste toutefois la seule source autorisée de confirmation.
      if (Number(secondPaymentAmount) <= 0 &&
        subscription.second_payment_status !== 'paid') {
        await subscription.update({
          payment_status: 'paid',
          second_payment_status: 'paid'
        });
      }

      // Si le contrat n'est pas encore activé malgré le paiement, l'activer maintenant
      if (subscription.status === 'pending_payment') {
        console.log(`⚠️ Contrat #${subscriptionId} non activé malgré paiement - Activation en cours...`);
        const contractSchedulingService = require('../../services/contractSchedulingService');
        try {
          await contractSchedulingService.activateContractAfterPayment(subscriptionId, null);
          await subscription.reload();
          console.log(`✅ Contrat #${subscriptionId} activé avec succès`);
        } catch (activationError) {
          console.error(`⚠️ Erreur activation contrat:`, activationError.message);
        }
      }

      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: subscription.payment_status,
          status: subscription.status,
          first_payment_status: 'paid',
          first_payment_amount: firstPaymentAmount,
          second_payment_status: subscription.second_payment_status || 'pending',
          second_payment_amount: secondPaymentAmount
        }
      });
    }

    // ── Chemin 1 : référence directe fournie par le deep link ──────────────
    // Le mobile passe ?reference=TRX... pour un lookup immédiat et fiable.
    const directReference = req.query.reference;
    if (directReference) {
      console.log(`⚡ Référence directe reçue: ${directReference} — lookup FineoPay direct`);
      try {
        const txResponse = await axios.get(
          `${FINEOPAY_BASE_URL}/transactions/${directReference}`,
          {
            headers: {
              'businessCode': FINEOPAY_BUSINESS_CODE,
              'apiKey': FINEOPAY_API_KEY
            }
          }
        );
        const tx = txResponse.data?.data?.transaction || txResponse.data?.data;
        console.log(`📦 Transaction directe:`, JSON.stringify(tx));

        if (tx && tx.status === 'success') {
          console.log(`✅ Transaction directe confirmée: ${directReference}`);
          const financialResult = await recordSubscriptionPayment({
            subscriptionId,
            reference: directReference,
            amount: tx.amount,
            sourceIp: req.ip
          });
          await subscription.reload();

          if (subscription.contract_type === 'scheduled' && subscription.status === 'pending_payment') {
            const contractSchedulingService = require('../../services/contractSchedulingService');
            try {
              await contractSchedulingService.activateContractAfterPayment(subscriptionId, directReference);
              await subscription.reload();
              console.log(`✅ Contrat #${subscriptionId} activé depuis référence directe`);
            } catch (ae) {
              console.error(`⚠️ Erreur activation depuis référence directe:`, ae.message);
            }
          }

          return res.status(200).json({
            success: true,
            data: {
              subscriptionId: subscription.id,
              payment_status: subscription.payment_status,
              status: subscription.status,
              reference: directReference,
              first_payment_status: subscription.first_payment_status,
              first_payment_amount: firstPaymentAmount,
              second_payment_status: subscription.second_payment_status || 'pending',
              second_payment_amount: secondPaymentAmount,
              duplicate: financialResult.duplicate
            }
          });
        }
      } catch (directErr) {
        // Transaction pas encore visible via l'endpoint direct → fallback scan liste
        console.log(`⚠️ Lookup direct échoué (${directErr.message}) — fallback scan liste`);
      }
    }

    // ── Chemin 2 : scan de la liste de transactions ─────────────────────────
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

      const matchingTransaction = transactions.find((transaction) => {
        const statusOk = transaction.status === 'success';
        if (!statusOk) return false;

        // Correspondance par syncRef
        const syncRefOk = transaction.syncRef === syncRef || transaction.payLink?.syncRef === syncRef;
        if (syncRefOk) return true;

        // Correspondance par titre du paylink
        const title = transaction.payLink?.title || '';
        const titleOk = title.includes(`SUBSCRIPTION_${subscriptionId}`)
          || title.includes(`#${subscriptionId}`)
          || title.includes(`Contrat ${subscription.reference || subscriptionId}`)
          || title.includes(`Contrat ${subscriptionId}`);
        return titleOk;
      });


      // Log pour diagnostic si non trouvée
      if (!matchingTransaction) {
        console.log(`⚠️ Transaction introuvable pour SUBSCRIPTION_${subscriptionId}. Transactions success:`,
          transactions
            .filter(t => t.status === 'success')
            .map(t => ({ syncRef: t.syncRef, title: t.payLink?.title, amount: t.amount, status: t.status }))
        );
      }


      if (matchingTransaction && matchingTransaction.status === 'success') {
        console.log(`✅ Transaction trouvée: ${matchingTransaction.reference} (${matchingTransaction.amount} FCFA)`);

        const financialResult = await recordSubscriptionPayment({
          subscriptionId,
          reference: matchingTransaction.reference,
          amount: matchingTransaction.amount,
          sourceIp: req.ip
        });
        await subscription.reload();

        if (subscription.contract_type === 'scheduled' && subscription.status === 'pending_payment') {
          const contractSchedulingService = require('../../services/contractSchedulingService');
          try {
            await contractSchedulingService.activateContractAfterPayment(
              subscriptionId,
              matchingTransaction.reference
            );
            await subscription.reload();
            console.log(`✅ Contrat #${subscriptionId} activé depuis le polling`);
          } catch (activationError) {
            console.error(`⚠️ Erreur activation contrat depuis polling:`, activationError.message);
          }
        }

        return res.status(200).json({
          success: true,
          data: {
            subscriptionId: subscription.id,
            payment_status: subscription.payment_status,
            status: subscription.status,
            reference: matchingTransaction.reference,
            first_payment_status: subscription.first_payment_status,
            first_payment_amount: firstPaymentAmount,
            second_payment_status: subscription.second_payment_status || 'pending',
            second_payment_amount: secondPaymentAmount,
            duplicate: financialResult.duplicate
          }
        });
      }

      // Aucune transaction trouvée
      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: 'pending',
          status: subscription.status,
          first_payment_status: 'pending',
          first_payment_amount: firstPaymentAmount,
          second_payment_status: 'pending',
          second_payment_amount: secondPaymentAmount
        }
      });

    } catch (apiError) {
      console.error('❌ Erreur API FineoPay:', apiError.message);
      return res.status(200).json({
        success: true,
        data: {
          subscriptionId: subscription.id,
          payment_status: subscription.payment_status,
          status: subscription.status,
          first_payment_status: subscription.first_payment_status || 'pending',
          first_payment_amount: firstPaymentAmount,
          second_payment_status: subscription.second_payment_status || 'pending',
          second_payment_amount: secondPaymentAmount
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

    if (req.user && req.user.role === 'customer') {
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: req.user.id } });
      if (!customerProfile || Number(intervention.customer_id) !== Number(customerProfile.id)) {
        return res.status(404).json({
          success: false,
          message: 'Intervention non trouvée'
        });
      }
    }

    // Si déjà payé intégralement (diagnostic et solde 50%), retourner le statut
    if (intervention.diagnostic_paid === true && intervention.second_payment_status !== 'pending') {
      console.log(`✅ Intervention #${interventionId} déjà marquée comme payée intégralement`);
      return res.status(200).json({
        success: true,
        data: {
          interventionId: intervention.id,
          diagnostic_paid: true,
          second_payment_status: intervention.second_payment_status || 'paid',
          status: intervention.status
        }
      });
    }

    // Chercher la transaction FineoPay
    const syncRef = `DIAGNOSTIC_${interventionId}`;
    console.log(`🔍 Recherche transaction FineoPay pour syncRef: ${syncRef} (second_payment_status: ${intervention.second_payment_status})`);

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

      // Chercher une transaction correspondante (solde 50% vs acompte initial)
      const isSecondStep = (intervention.diagnostic_paid === true && intervention.second_payment_status === 'pending' && parseFloat(intervention.second_payment_amount || 0) > 0);
      const expectedAmount = isSecondStep
        ? parseFloat(intervention.second_payment_amount)
        : parseFloat(intervention.diagnostic_fee || 0);

      // FineoPay ne retourne pas de champ syncRef dans /transactions.
      // On identifie la transaction par le titre du payLink (contient l'interventionId)
      // et le montant exact. On accepte aussi une correspondance par syncRef si présent.
      const expectedTitle = isSecondStep
        ? `Solde (50%) Intervention #${interventionId}`
        : `Diagnostic Intervention #${interventionId}`;

      const matchingTransaction = transactions.find((transaction) => {
        const statusOk = transaction.status === 'success';
        const amountOk = expectedAmount > 0
          ? Math.round(Number(transaction.amount) * 100) === Math.round(expectedAmount * 100)
          : true; // si diagnostic_fee=0, pas de vérification de montant
        const titleOk = transaction.payLink?.title === expectedTitle
          || transaction.payLink?.title?.includes(`#${interventionId}`);
        const syncRefOk = transaction.syncRef === syncRef;
        return statusOk && amountOk && (titleOk || syncRefOk);
      });

      console.log(`🔍 Matching: expectedTitle="${expectedTitle}", expectedAmount=${expectedAmount}, found=${!!matchingTransaction}`);

      if (matchingTransaction && matchingTransaction.status === 'success') {
        console.log(`✅ Transaction trouvée: ${matchingTransaction.reference}`);

        const financialResult = await recordDiagnosticPayment({
          interventionId,
          reference: matchingTransaction.reference,
          amount: matchingTransaction.amount,
          sourceIp: req.ip
        });
        await intervention.reload();
        return res.status(200).json({
          success: true,
          data: {
            interventionId: intervention.id,
            diagnostic_paid: intervention.diagnostic_paid,
            second_payment_status: intervention.second_payment_status,
            status: intervention.status,
            reference: matchingTransaction.reference,
            duplicate: financialResult.duplicate
          }
        });

        // Mettre à jour l'intervention (1er acompte vs 2ème solde 50%)
        if (intervention.diagnostic_paid !== true) {
          await intervention.update({
            diagnostic_paid: true,
            diagnostic_payment_date: new Date()
          });
          console.log(`✅ Premier paiement (acompte 50% / diagnostic) vérifié et marqué payé pour intervention #${intervention.id}`);
        } else if (intervention.second_payment_status === 'pending') {
          await intervention.update({
            second_payment_status: 'paid',
            second_payment_date: new Date()
          });
          console.log(`✅ Second paiement (50% solde) vérifié et marqué payé pour intervention #${intervention.id}`);
        }

        // Créer enregistrement Payment
        await Payment.create({
          interventionId: intervention.id,
          amount: matchingTransaction.amount,
          currency: 'XOF',
          provider: 'fineopay',
          paymentId: matchingTransaction.reference,
          status: 'succeeded',
          paymentStep: isSecondStep ? 2 : 1,
          purpose: 'diagnostic',
          syncRef: `DIAGNOSTIC_${intervention.id}`,
          verifiedAt: new Date(),
          paidAt: new Date(),
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

        // 📱 Envoyer les notifications
        const notificationService = require('../../services/notificationService');
        const customer = intervention.customer?.user;

        if (customer) {
          const numAmount = parseFloat(matchingTransaction.amount || 0);
          const clientTitle = numAmount === 0 ? '✅ Demande d\'intervention confirmée' : '✅ Paiement d\'intervention confirmé';
          const clientMessage = numAmount === 0
            ? `Votre demande d'intervention #${interventionId} a été confirmée.`
            : `Votre paiement de ${matchingTransaction.amount} FCFA pour l'intervention #${interventionId} a été confirmé. Le technicien peut maintenant intervenir.`;

          await notificationService.create({
            userId: customer.id,
            type: 'diagnostic_payment_confirmed',
            title: clientTitle,
            message: clientMessage,
            data: {
              intervention_id: interventionId,
              interventionId: parseInt(interventionId),
              amount: parseFloat(matchingTransaction.amount),
              reference: matchingTransaction.reference
            },
            priority: 'high'
          });
          console.log(`📲 Notification de paiement d'intervention envoyée au client`);
        }

        // Notifier le technicien
        if (intervention.technician_id) {
          await notificationService.create({
            userId: intervention.technician_id,
            type: 'diagnostic_payment_confirmed',
            title: '💳 Intervention confirmée',
            message: `Le client a validé le paiement/demande pour l'intervention #${interventionId}. Vous pouvez procéder.`,
            data: {
              intervention_id: interventionId,
              interventionId: parseInt(interventionId),
              role: 'technician'
            },
            priority: 'high'
          });
          console.log(`📲 Notification d'intervention envoyée au technicien`);
        }

        // Notifier les admins et managers
        const customerName = intervention.customer ?
          `${intervention.customer.first_name || ''} ${intervention.customer.last_name || ''}`.trim() : 'Un client';
        const numAmount = parseFloat(matchingTransaction.amount || 0);
        const adminTitle = numAmount === 0 ? '📋 Demande d\'intervention reçue' : '💰 Paiement d\'intervention reçu';
        const adminMessage = numAmount === 0
          ? `Demande d'intervention #${interventionId} reçue de ${customerName || 'client'} (Gratuit).`
          : `Paiement d'intervention de ${matchingTransaction.amount} FCFA reçu de ${customerName || 'client'} (#${interventionId}).`;

        await notificationService.notifyAdmins({
          type: 'diagnostic_payment_received',
          title: adminTitle,
          message: adminMessage,
          data: {
            interventionId: parseInt(interventionId),
            amount: parseFloat(matchingTransaction.amount),
            reference: matchingTransaction.reference,
            customerId: intervention.customer?.id
          },
          priority: 'medium',
          actionUrl: `/interventions/${interventionId}`
        });
        console.log(`📲 Notification de paiement diagnostic envoyée aux admins`);

        // Tenter l'assignation automatique (car l'intervention est maintenant payée et prête pour le technicien)
        if (!intervention.technician_id) {
          try {
            const schedulingService = require('../../services/schedulingService');
            await schedulingService.autoAssignIntervention(interventionId);
            // Recharger l'intervention pour renvoyer le nouveau statut
            await intervention.reload();
          } catch (err) {
            console.error(`⚠️ Assignation automatique échouée pour l'intervention diagnostic #${interventionId}: ${err.message}`);
            // Notifier le client qu'on cherche une équipe
            if (customer) {
              await notificationService.create({
                userId: customer.id,
                type: 'technician_search',
                title: '🔍 Recherche d\'équipe',
                message: `Votre paiement est confirmé ! Nous recherchons actuellement l'équipe la plus proche et vous tiendrons informé.`,
                data: { intervention_id: interventionId, role: 'client' },
                priority: 'high'
              });
            }
          }
        }

        return res.status(200).json({
          success: true,
          data: {
            interventionId: intervention.id,
            diagnostic_paid: true,
            second_payment_status: intervention.second_payment_status,
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
          diagnostic_paid: intervention.diagnostic_paid,
          second_payment_status: intervention.second_payment_status,
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
          second_payment_status: intervention.second_payment_status,
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
    const { interventionId, redirectUrl, autoRedirect } = req.body;
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

    // Montant du diagnostic ou du 2ème paiement (solde 50%)
    let diagnosticFee = intervention.diagnostic_fee || 10; // 10 FCFA pour test
    let paymentTitle = `Diagnostic Intervention #${interventionId}`;

    if (intervention.diagnostic_paid === true && intervention.second_payment_status === 'pending' && parseFloat(intervention.second_payment_amount || 0) > 0) {
      diagnosticFee = parseFloat(intervention.second_payment_amount);
      paymentTitle = `Solde (50%) Intervention #${interventionId}`;
      console.log(`📌 Initialisation du 2ème paiement (solde 50%) de ${diagnosticFee} FCFA pour l'intervention #${interventionId}`);
    }

    // Si le corps de la requête transmet un montant spécifique, s'assurer qu'il est cohérent avec l'intervention
    if (req.body.amount) {
      const reqAmountNum = parseFloat(req.body.amount);
      if (Math.round(reqAmountNum * 100) !== Math.round(diagnosticFee * 100)) {
        if (Math.round(reqAmountNum * 100) === Math.round(diagnosticFee * 0.5 * 100)) {
          diagnosticFee = reqAmountNum;
        } else {
          console.warn(`⚠️ Montant reçu (${reqAmountNum} FCFA) != attendu (${diagnosticFee} FCFA) pour diagnostic #${interventionId} -> Ajustement automatique à ${diagnosticFee} FCFA`);
        }
      }
    }

    // Construire l'URL de callback
    const callbackUrl = getCallbackUrl();

    // Créer le lien de paiement FineoPay
    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title: paymentTitle,
        amount: parseFloat(diagnosticFee),
        callbackUrl,
        ...(redirectUrl && { redirectUrl }),
        ...(autoRedirect !== undefined && { autoRedirect }),
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

/**
 * Initialiser un paiement FineoPay pour une souscription/contrat
 */
const initializeSubscriptionPayment = async (req, res) => {
  try {
    const { subscriptionId, amount, title, description, redirectUrl, autoRedirect } = req.body;
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement pour contrat #${subscriptionId}`);

    if (!subscriptionId || !amount) {
      return res.status(400).json({
        success: false,
        message: 'subscriptionId et amount sont requis'
      });
    }

    // Récupérer la souscription
    const subscription = await Subscription.findByPk(subscriptionId, {
      include: [{
        model: User,
        as: 'customer',
        attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
      }]
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    // Vérification et réconciliation du montant d'après le contrat en base
    const fullPrice = parseFloat(subscription.price || 0);
    const firstAmount = parseFloat(subscription.first_payment_amount || Math.ceil(fullPrice / 2));
    const secondAmount = parseFloat(subscription.second_payment_amount || Math.floor(fullPrice / 2));

    let expectedAmount;
    if (subscription.first_payment_status === 'paid' && subscription.second_payment_status !== 'paid') {
      expectedAmount = secondAmount;
    } else {
      const isFullOption = (req.body.paymentOption || req.body.payment_option) === 'full';
      expectedAmount = isFullOption ? fullPrice : firstAmount;
    }

    let finalAmount = expectedAmount;
    if (amount) {
      const reqAmountNum = parseFloat(amount);
      if (Math.round(reqAmountNum * 100) === Math.round(expectedAmount * 0.5 * 100)) {
        finalAmount = reqAmountNum; // Réduction parrainage 50%
      } else if (Math.round(reqAmountNum * 100) !== Math.round(expectedAmount * 100)) {
        console.warn(`⚠️ Montant reçu (${reqAmountNum} FCFA) != attendu (${expectedAmount} FCFA) pour contrat #${subscriptionId} -> Ajustement automatique à ${expectedAmount} FCFA`);
        finalAmount = expectedAmount;
      }
    }

    // Construire l'URL de callback
    const callbackUrl = getCallbackUrl();

    // Créer le lien de paiement FineoPay
    const paymentTitle = title || `Contrat ${subscription.reference || subscriptionId}`;
    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title: paymentTitle,
        amount: parseFloat(finalAmount),
        callbackUrl,
        ...(redirectUrl && { redirectUrl }),
        ...(autoRedirect !== undefined && { autoRedirect }),
        syncRef: `SUBSCRIPTION_${subscriptionId}`,
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

      console.log(`✅ Lien de paiement contrat créé pour souscription #${subscriptionId}`);
      console.log(`🔗 URL: ${checkoutLink}`);

      // Stocker le checkoutLinkId dans la souscription
      await subscription.update({
        checkout_link_id: checkoutLinkId,
        payment_status: 'pending'
      });

      // Logger
      await PaymentLog.create({
        eventType: 'subscription_checkout_created',
        provider: 'fineopay',
        checkoutLinkId,
        amount: parseFloat(amount),
        paymentStatus: 'pending',
        sourceIp: req.ip,
        success: true,
        metadata: { subscriptionId, type: 'subscription' }
      });

      return res.status(200).json({
        success: true,
        message: 'Lien de paiement contrat créé',
        data: {
          paymentUrl: checkoutLink,
          checkout_link_id: checkoutLinkId,
          subscription_id: subscriptionId,
          amount: parseFloat(amount),
          transaction_id: `SUB-${subscriptionId}-${Date.now()}`
        }
      });
    } else {
      throw new Error(response.data.message || 'Erreur FineoPay');
    }

  } catch (error) {
    console.error('❌ Erreur création paiement contrat:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du paiement contrat',
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
  initializeDiagnosticPayment,
  initializeSubscriptionPayment
};
