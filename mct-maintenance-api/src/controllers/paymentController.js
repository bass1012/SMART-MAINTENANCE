const { Order, Payment, User, Subscription, CustomerProfile } = require('../models');
const paymentService = require('../services/paymentService');
const { generateInvoicePDF } = require('../services/pdfService');
const { sendInvoiceEmail, sendPaymentConfirmationEmail } = require('../services/emailService');

/**
 * Initier un paiement
 */
const initiatePayment = async (req, res, next) => {
  try {
    const { orderId, provider, phoneNumber } = req.body;

    // Récupérer la commande
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'user_id', 'first_name', 'last_name'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
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

    // Vérifier si la commande est déjà payée
    if (order.paymentStatus === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Cette commande a déjà été payée'
      });
    }

    let paymentResult;

    // Initier le paiement selon le provider
    switch (provider) {
      case paymentService.PAYMENT_PROVIDERS.STRIPE:
        paymentResult = await paymentService.initiateStripePayment(
          order.totalAmount,
          'xof',
          `Commande ${order.reference || order.id}`,
          { orderId: order.id }
        );
        break;

      case paymentService.PAYMENT_PROVIDERS.WAVE:
        paymentResult = await paymentService.initiateWavePayment(
          order.totalAmount,
          'XOF',
          phoneNumber || order.customer?.phone,
          `Commande ${order.reference || order.id}`
        );
        break;

      case paymentService.PAYMENT_PROVIDERS.ORANGE_MONEY:
        paymentResult = await paymentService.initiateOrangeMoneyPayment(
          order.totalAmount,
          'XOF',
          phoneNumber || order.customer?.phone,
          `Commande ${order.reference || order.id}`
        );
        break;

      case 'fineopay':
        // Utiliser FineoPay
        const axios = require('axios');
        const FINEOPAY_BASE_URL = process.env.FINEOPAY_ENV === 'production' 
          ? 'https://api.fineopay.com/v1/business/dev'
          : 'https://dev.fineopay.com/api/v1/business/dev';

        const callbackUrl = `${process.env.API_BASE_URL || process.env.BACKEND_URL}/api/fineopay/callback`;

        const response = await axios.post(
          `${FINEOPAY_BASE_URL}/checkout-link`,
          {
            title: `Commande ${order.reference || order.id}`,
            amount: parseFloat(order.totalAmount),
            callbackUrl,
            syncRef: `SHOP_ORDER_${order.id}`,
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

        if (!response.data.success) {
          throw new Error('Erreur lors de la création du lien FineoPay');
        }

        paymentResult = {
          paymentId: `FINEOPAY_${Date.now()}`,
          checkoutUrl: response.data.data.checkoutLink
        };
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Provider de paiement non supporté'
        });
    }

    // Enregistrer le paiement dans la base de données
    const payment = await Payment.create({
      orderId: order.id,
      amount: order.totalAmount,
      currency: 'XOF',
      provider: provider,
      paymentId: paymentResult.paymentId,
      status: 'pending',
      phoneNumber: phoneNumber,
      checkoutUrl: paymentResult.checkoutUrl,
      metadata: {
        clientSecret: paymentResult.clientSecret,
        simulation: paymentResult.simulation
      }
    });

    res.status(200).json({
      success: true,
      message: 'Paiement initié avec succès',
      data: {
        paymentId: payment.id,
        providerPaymentId: paymentResult.paymentId,
        checkoutUrl: paymentResult.checkoutUrl,
        clientSecret: paymentResult.clientSecret,
        status: paymentResult.status
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement:', error);
    next(error);
  }
};

/**
 * Confirmer un paiement
 */
const confirmPayment = async (req, res, next) => {
  try {
    const { paymentId } = req.params;

    const payment = await Payment.findByPk(paymentId, {
      include: [
        {
          model: Order,
          as: 'order',
          include: [
            {
              model: User,
              as: 'customer'
            }
          ]
        }
      ]
    });

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    // Vérifier le statut auprès du provider
    const statusResult = await paymentService.checkPaymentStatus(
      payment.paymentId,
      payment.provider
    );

    // Mettre à jour le paiement
    payment.status = statusResult.paid ? 'succeeded' : payment.status;
    if (statusResult.paid) {
      payment.paidAt = new Date();
    }
    await payment.save();

    // Mettre à jour la commande si le paiement est réussi
    if (statusResult.paid) {
      payment.order.paymentStatus = 'paid';
      payment.order.status = 'processing';
      await payment.order.save();

      // Envoyer l'email de confirmation
      try {
        await sendPaymentConfirmationEmail(payment.order, payment.order.customer?.email);
      } catch (emailError) {
        console.error('Erreur lors de l\'envoi de l\'email:', emailError);
      }
    }

    res.status(200).json({
      success: true,
      message: statusResult.paid ? 'Paiement confirmé' : 'Paiement en attente',
      data: {
        paymentId: payment.id,
        status: payment.status,
        paid: statusResult.paid
      }
    });

  } catch (error) {
    console.error('Erreur lors de la confirmation du paiement:', error);
    next(error);
  }
};

/**
 * Obtenir l'historique des paiements d'une commande
 */
const getOrderPayments = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    const payments = await Payment.findAll({
      where: { orderId },
      order: [['createdAt', 'DESC']]
    });

    res.status(200).json({
      success: true,
      count: payments.length,
      data: payments
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des paiements:', error);
    next(error);
  }
};

/**
 * Télécharger la facture en PDF
 */
const downloadInvoice = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    console.log('📄 Téléchargement facture pour commande:', orderId);

    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'user_id', 'first_name', 'last_name'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
          }]
        },
        {
          model: require('../models').OrderItem,
          as: 'items',
          include: [
            {
              model: require('../models').Product,
              as: 'product',
              attributes: ['id', 'nom', 'reference', 'prix']
            }
          ]
        }
      ]
    });

    if (!order) {
      console.error('❌ Commande non trouvée:', orderId);
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    // Vérifier que la commande est payée
    if (order.paymentStatus !== 'paid') {
      console.log('⚠️ Téléchargement refusé - Commande non payée:', order.paymentStatus);
      return res.status(403).json({
        success: false,
        message: 'Le téléchargement de la facture est disponible uniquement pour les commandes payées. Veuillez effectuer le paiement pour accéder à votre facture.'
      });
    }

    console.log('✅ Commande trouvée:', {
      id: order.id,
      reference: order.reference,
      customer: order.customer ? `${order.customer.first_name} ${order.customer.last_name}` : 'N/A',
      itemsCount: order.items?.length || 0,
      totalAmount: order.totalAmount
    });

    // Convertir en objet plain pour le PDF
    const orderData = order.toJSON();
    console.log('📦 Données de la commande:', JSON.stringify(orderData, null, 2));

    // Générer le PDF
    console.log('🔄 Génération du PDF...');
    const pdfData = await generateInvoicePDF(orderData);
    console.log('✅ PDF généré, taille:', pdfData.length, 'bytes');
    console.log('🔍 Type reçu:', typeof pdfData, '- isBuffer:', Buffer.isBuffer(pdfData));

    // S'assurer que c'est un Buffer Node.js (conversion si nécessaire)
    const pdfBuffer = Buffer.isBuffer(pdfData) ? pdfData : Buffer.from(pdfData);
    
    // Vérifier que le buffer n'est pas vide
    if (!pdfBuffer || pdfBuffer.length === 0) {
      console.error('❌ Le PDF est vide');
      throw new Error('PDF vide généré');
    }

    console.log('✅ Buffer prêt à envoyer, taille:', pdfBuffer.length, 'bytes');

    // Envoyer le PDF avec les bons headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Length', pdfBuffer.length);
    res.setHeader('Content-Disposition', `attachment; filename=facture-${order.reference || order.id}.pdf`);
    res.setHeader('Cache-Control', 'no-cache');
    
    // Utiliser res.end() au lieu de res.send() pour les buffers binaires
    res.end(pdfBuffer, 'binary');
    console.log('✅ PDF envoyé avec succès');

  } catch (error) {
    console.error('❌ Erreur lors du téléchargement de la facture:', error);
    console.error('Stack:', error.stack);
    next(error);
  }
};

/**
 * Envoyer la facture par email
 */
const emailInvoice = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { email } = req.body;

    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: User,
          as: 'customer'
        },
        {
          model: require('../models').OrderItem,
          as: 'items',
          include: [
            {
              model: require('../models').Product,
              as: 'product'
            }
          ]
        }
      ]
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    // Envoyer l'email
    const result = await sendInvoiceEmail(order, email || order.customer?.email);

    res.status(200).json({
      success: true,
      message: 'Facture envoyée par email avec succès',
      data: result
    });

  } catch (error) {
    console.error('Erreur lors de l\'envoi de la facture:', error);
    next(error);
  }
};

/**
 * Webhook pour Wave
 */
const waveWebhook = async (req, res) => {
  try {
    // Traiter le webhook Wave
    console.log('Webhook Wave reçu:', req.body);
    
    // TODO: Implémenter la logique de traitement du webhook
    
    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Erreur webhook Wave:', error);
    res.status(500).json({ error: error.message });
  }
};

/**
 * Webhook pour Orange Money
 */
const orangeMoneyWebhook = async (req, res) => {
  try {
    // Traiter le webhook Orange Money
    console.log('Webhook Orange Money reçu:', req.body);
    
    // TODO: Implémenter la logique de traitement du webhook
    
    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Erreur webhook Orange Money:', error);
    res.status(500).json({ error: error.message });
  }
};

/**
 * Initier un paiement pour une souscription
 */
const initiateSubscriptionPayment = async (req, res, next) => {
  try {
    const { subscriptionId, provider, phoneNumber } = req.body;

    // Récupérer la souscription
    const subscription = await Subscription.findByPk(subscriptionId, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: require('../models').MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'price']
        }
      ]
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }

    // Vérifier si la souscription est déjà payée
    if (subscription.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Cette souscription a déjà été payée'
      });
    }

    let paymentResult;

    // Initier le paiement selon le provider
    switch (provider) {
      case paymentService.PAYMENT_PROVIDERS.STRIPE:
        paymentResult = await paymentService.initiateStripePayment(
          subscription.price,
          'xof',
          `Souscription ${subscription.id}`,
          { subscriptionId: subscription.id }
        );
        break;

      case paymentService.PAYMENT_PROVIDERS.WAVE:
        paymentResult = await paymentService.initiateWavePayment(
          subscription.price,
          'XOF',
          phoneNumber || subscription.customer?.phone,
          `Souscription ${subscription.id}`
        );
        break;

      case paymentService.PAYMENT_PROVIDERS.ORANGE_MONEY:
        paymentResult = await paymentService.initiateOrangeMoneyPayment(
          subscription.price,
          'XOF',
          phoneNumber || subscription.customer?.phone,
          `Souscription ${subscription.id}`
        );
        break;

      case paymentService.PAYMENT_PROVIDERS.FINEOPAY:
      case 'fineopay':
        // Créer un lien de paiement FineoPay pour la souscription
        const axios = require('axios');
        const FINEOPAY_BASE_URL = process.env.FINEOPAY_ENV === 'production' 
          ? 'https://api.fineopay.com/v1/business/dev'
          : 'https://dev.fineopay.com/api/v1/business/dev';
        const FINEOPAY_BUSINESS_CODE = process.env.FINEOPAY_BUSINESS_CODE;
        const FINEOPAY_API_KEY = process.env.FINEOPAY_API_KEY;
        
        const callbackUrl = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/fineopay/callback`;
        const subscriptionTitle = subscription.offer?.title || `Souscription #${subscription.id}`;
        
        try {
          const fineoResponse = await axios.post(
            `${FINEOPAY_BASE_URL}/checkout-link`,
            {
              title: `Paiement: ${subscriptionTitle}`,
              amount: parseFloat(subscription.price),
              callbackUrl,
              syncRef: `SUBSCRIPTION_${subscription.id}`
            },
            {
              headers: {
                'Content-Type': 'application/json',
                'businessCode': FINEOPAY_BUSINESS_CODE,
                'apiKey': FINEOPAY_API_KEY
              }
            }
          );
          
          if (fineoResponse.data.success) {
            const checkoutLink = fineoResponse.data.data.checkoutLink;
            const checkoutLinkId = checkoutLink.split('/').slice(-2, -1)[0];
            
            paymentResult = {
              paymentId: `FINEO-SUB-${subscription.id}-${Date.now()}`,
              checkoutUrl: checkoutLink,
              checkoutLinkId: checkoutLinkId,
              clientSecret: null,
              simulation: false
            };
            console.log(`✅ Lien FineoPay créé pour souscription #${subscription.id}: ${checkoutLink}`);
          } else {
            throw new Error(fineoResponse.data.message || 'Erreur FineoPay');
          }
        } catch (fineoError) {
          console.error('❌ Erreur FineoPay:', fineoError.message);
          return res.status(500).json({
            success: false,
            message: 'Erreur lors de la création du lien de paiement FineoPay',
            error: fineoError.message
          });
        }
        break;

      case 'cash':
        // Paiement en espèces - pas de traitement externe
        paymentResult = {
          paymentId: `CASH-${Date.now()}-${subscription.id}`,
          checkoutUrl: null,
          clientSecret: null,
          simulation: false
        };
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Provider de paiement non supporté'
        });
    }

    // Enregistrer le paiement dans la base de données
    const payment = await Payment.create({
      subscriptionId: subscription.id,
      amount: subscription.price,
      currency: 'XOF',
      provider: provider,
      paymentId: paymentResult.paymentId,
      status: 'pending',
      phoneNumber: phoneNumber,
      checkoutUrl: paymentResult.checkoutUrl,
      metadata: {
        clientSecret: paymentResult.clientSecret,
        simulation: paymentResult.simulation
      }
    });

    res.status(200).json({
      success: true,
      message: 'Paiement initité avec succès',
      data: {
        paymentId: payment.id,
        providerPaymentId: paymentResult.paymentId,
        checkoutUrl: paymentResult.checkoutUrl,
        clientSecret: paymentResult.clientSecret,
        status: paymentResult.status
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement de souscription:', error);
    next(error);
  }
};

/**
 * Confirmer un paiement de souscription
 */
const confirmSubscriptionPayment = async (req, res, next) => {
  try {
    const { paymentId } = req.params;

    const payment = await Payment.findByPk(paymentId, {
      include: [
        {
          model: Subscription,
          as: 'subscription',
          include: [
            {
              model: User,
              as: 'customer'
            }
          ]
        }
      ]
    });

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    // Vérifier le statut auprès du provider
    const statusResult = await paymentService.checkPaymentStatus(
      payment.paymentId,
      payment.provider
    );

    // Mettre à jour le paiement
    payment.status = statusResult.paid ? 'succeeded' : payment.status;
    if (statusResult.paid) {
      payment.paidAt = new Date();
    }
    await payment.save();

    // Mettre à jour la souscription si le paiement est réussi
    if (statusResult.paid && payment.subscription) {
      payment.subscription.payment_status = 'paid';
      payment.subscription.status = 'active';
      await payment.subscription.save();

      // Envoyer notification
      try {
        const { notifyPaymentReceived } = require('../services/notificationHelpers');
        await notifyPaymentReceived(
          { 
            id: payment.subscription.id,
            amount: payment.amount,
            type: 'subscription'
          },
          payment.subscription.customer
        );
      } catch (notifError) {
        console.error('⚠️  Erreur notification paiement:', notifError.message);
      }
    }

    res.status(200).json({
      success: true,
      message: statusResult.paid ? 'Paiement confirmé' : 'Paiement en attente',
      data: {
        paymentId: payment.id,
        status: payment.status,
        paid: statusResult.paid
      }
    });

  } catch (error) {
    console.error('Erreur lors de la confirmation du paiement de souscription:', error);
    next(error);
  }
};

module.exports = {
  initiatePayment,
  confirmPayment,
  getOrderPayments,
  downloadInvoice,
  emailInvoice,
  waveWebhook,
  orangeMoneyWebhook,
  initiateSubscriptionPayment,
  confirmSubscriptionPayment
};
