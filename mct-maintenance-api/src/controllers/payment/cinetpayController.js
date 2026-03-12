const axios = require('axios');
const { Op } = require('sequelize');
const { Order, CustomerProfile, User, Intervention, Quote, DiagnosticReport } = require('../../models');

// Configuration CinetPay (à mettre dans les variables d'environnement)
const CINETPAY_API_KEY = process.env.CINETPAY_API_KEY || 'YOUR_API_KEY';
const CINETPAY_SITE_ID = process.env.CINETPAY_SITE_ID || 'YOUR_SITE_ID';
const CINETPAY_API_URL = 'https://api-checkout.cinetpay.com/v2/payment';
const CINETPAY_VERIFY_URL = 'https://api-checkout.cinetpay.com/v2/payment/check';

/**
 * Initialiser un paiement CinetPay
 */
const initializePayment = async (req, res) => {
  try {
    const { orderId } = req.body;
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement CinetPay - Order ${orderId}, User ${userId}`);

    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: userId },
      include: [{ model: User, as: 'user' }]
    });

    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé'
      });
    }

    // Récupérer la commande
    const order = await Order.findOne({
      where: {
        id: orderId,
        customerId: customerProfile.id
      }
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    // Vérifier que la commande n'est pas déjà payée
    if (order.paymentStatus === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Cette commande est déjà payée'
      });
    }

    // Générer un transaction_id unique
    const transactionId = `ORD-${order.id}-${Date.now()}`;

    // Préparer les données pour CinetPay
    const cinetpayData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transactionId,
      amount: Math.ceil(order.totalAmount / 5) * 5, // Arrondir au multiple de 5 supérieur
      currency: 'XOF', // F CFA
      description: `Commande #${order.reference || order.id}`.replace(/[#/$_&]/g, '-'), // Supprimer caractères spéciaux
      customer_id: customerProfile.id.toString(),
      customer_name: customerProfile.last_name || 'Client',
      customer_surname: customerProfile.first_name || 'MCT',
      customer_email: customerProfile.user?.email || 'contact@mct.ci',
      customer_phone_number: customerProfile.phone || '+2250708205263',
      customer_address: order.shippingAddress || 'Abidjan',
      customer_city: 'Abidjan',
      customer_country: 'CI', // Code ISO Côte d'Ivoire (2 caractères)
      customer_state: 'CI', // Code ISO État (2 caractères)
      customer_zip_code: '00225', // Code postal (5 caractères)
      notify_url: `${process.env.BACKEND_URL}/api/payments/cinetpay/notify`,
      return_url: `${process.env.FRONTEND_URL}/payment/success`,
      channels: 'ALL', // ALL, MOBILE_MONEY, CREDIT_CARD, WALLET
      metadata: JSON.stringify({
        orderId: order.id,
        userId: userId,
        customerProfileId: customerProfile.id
      }),
      lang: 'FR', // FR ou EN
      invoice_data: {
        "Commande": order.reference || `#${order.id}`,
        "Client": `${customerProfile.first_name} ${customerProfile.last_name}`,
        "Montant": `${Math.ceil(order.totalAmount / 5) * 5} FCFA`
      }
    };

    console.log('📤 Envoi requête CinetPay...');
    console.log('📦 Données envoyées:', JSON.stringify(cinetpayData, null, 2));

    // Appeler l'API CinetPay
    const response = await axios.post(CINETPAY_API_URL, cinetpayData, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MCT-Maintenance/1.0'
      }
    });

    console.log('📥 Réponse CinetPay:', response.data);

    if (response.data.code === '201') {
      // Succès - Sauvegarder le token de paiement
      await order.update({
        paymentStatus: 'pending',
        notes: order.notes ? 
          `${order.notes}\nTransaction CinetPay: ${transactionId}` : 
          `Transaction CinetPay: ${transactionId}`
      });

      console.log('✅ Paiement initialisé avec succès');

      return res.json({
        success: true,
        message: 'Paiement initialisé',
        data: {
          payment_url: response.data.data.payment_url,
          payment_token: response.data.data.payment_token,
          transaction_id: transactionId
        }
      });
    } else {
      console.error('❌ Erreur CinetPay:', response.data);
      return res.status(400).json({
        success: false,
        message: response.data.description || 'Erreur lors de l\'initialisation du paiement',
        error: response.data
      });
    }

  } catch (error) {
    console.error('❌ Erreur initialisation paiement CinetPay:', error.message);
    console.error('❌ Détails erreur:', error.response?.data || error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'initialisation du paiement',
      error: error.response?.data || error.message
    });
  }
};

/**
 * Notification de paiement (webhook CinetPay)
 */
const handleNotification = async (req, res) => {
  try {
    console.log('🔔 Notification CinetPay reçue:', req.body);

    const { cpm_trans_id, cpm_trans_status, cpm_custom } = req.body;

    // Vérifier le statut du paiement auprès de CinetPay
    const verifyData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: cpm_trans_id
    };

    const verifyResponse = await axios.post(CINETPAY_VERIFY_URL, verifyData, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MCT-Maintenance/1.0'
      }
    });

    console.log('✅ Vérification paiement:', verifyResponse.data);

    if (verifyResponse.data.code === '00') {
      // Paiement confirmé
      const metadata = JSON.parse(cpm_custom || '{}');
      const orderId = metadata.orderId;

      if (orderId) {
        const { Equipment, Product, Category, Brand } = require('../../models');
        
        const order = await Order.findByPk(orderId, {
          include: [{
            model: OrderItem,
            as: 'items',
            include: [{
              model: Product,
              as: 'product',
              include: [
                { model: Category, as: 'category' },
                { model: Brand, as: 'brand' }
              ]
            }]
          }]
        });
        
        if (order && order.paymentStatus !== 'paid') {
          await order.update({
            paymentStatus: 'paid',
            status: 'processing'
          });

          console.log(`✅ Commande ${orderId} marquée comme payée`);

          // Créer automatiquement des équipements pour les produits achetés
          if (order.items && order.items.length > 0) {
            for (const item of order.items) {
              try {
                const product = item.product;
                
                // Créer un équipement pour chaque produit acheté
                const equipmentData = {
                  customer_id: order.customerId,
                  name: item.product_name || product?.nom || 'Équipement',
                  type: product?.category?.nom || 'Autre',
                  brand: product?.brand?.nom || null,
                  model: product?.reference || null,
                  serial_number: null, // Peut être ajouté manuellement par le client
                  purchase_date: new Date(),
                  location: null,
                  status: 'active',
                  notes: `Acheté via la commande #${order.reference || orderId}`
                };

                await Equipment.create(equipmentData);
                console.log(`✅ Équipement créé pour le produit: ${equipmentData.name}`);
              } catch (equipError) {
                console.error(`⚠️ Erreur création équipement pour item ${item.id}:`, equipError.message);
              }
            }
          }

          // TODO: Envoyer notification au client
        }
      }

      return res.json({ success: true, message: 'Paiement confirmé' });
    } else {
      console.log('⚠️ Paiement non confirmé:', verifyResponse.data);
      return res.json({ success: false, message: 'Paiement non confirmé' });
    }

  } catch (error) {
    console.error('❌ Erreur notification CinetPay:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du traitement de la notification',
      error: error.message
    });
  }
};

/**
 * Vérifier le statut d'un paiement
 */
const checkPaymentStatus = async (req, res) => {
  try {
    const { transactionId } = req.params;

    console.log(`🔍 Vérification statut paiement: ${transactionId}`);

    const verifyData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transactionId
    };

    const response = await axios.post(CINETPAY_VERIFY_URL, verifyData, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MCT-Maintenance/1.0'
      }
    });

    console.log('📥 Statut:', response.data);

    return res.json({
      success: true,
      data: response.data
    });

  } catch (error) {
    console.error('❌ Erreur vérification:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification',
      error: error.message
    });
  }
};

/**
 * Initialiser un paiement pour les frais de diagnostic (4000 FCFA)
 */
const initializeDiagnosticPayment = async (req, res) => {
  try {
    const { interventionId } = req.body;
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement diagnostic - Intervention ${interventionId}, User ${userId}`);

    const { Intervention } = require('../../models');

    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: userId },
      include: [{ model: User, as: 'user' }]
    });

    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé'
      });
    }

    // Récupérer l'intervention
    const intervention = await Intervention.findOne({
      where: {
        id: interventionId,
        customer_id: customerProfile.id
      }
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Vérifier que c'est bien un diagnostic avec des frais
    if (intervention.diagnostic_fee <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Cette intervention n\'a pas de frais de diagnostic'
      });
    }

    // Vérifier si le diagnostic n'est pas déjà payé
    if (intervention.diagnostic_paid === true) {
      return res.status(400).json({
        success: false,
        message: 'Les frais de diagnostic sont déjà payés'
      });
    }

    // Générer un transaction_id unique
    const transactionId = `DIAG-${intervention.id}-${Date.now()}`;

    // Arrondir au multiple de 5 supérieur (requis par CinetPay)
    const amount = Math.ceil(intervention.diagnostic_fee / 5) * 5;

    // Préparer les données pour CinetPay
    const cinetpayData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transactionId,
      amount: amount,
      currency: 'XOF', // F CFA
      description: `Frais de diagnostic - Intervention ${intervention.id}`.replace(/[#/$_&]/g, '-'),
      customer_id: customerProfile.id.toString(),
      customer_name: customerProfile.last_name || 'Client',
      customer_surname: customerProfile.first_name || 'MCT',
      customer_email: customerProfile.user?.email || 'contact@mct.ci',
      customer_phone_number: customerProfile.phone || '+2250708205263',
      customer_address: intervention.address || 'Abidjan',
      customer_city: 'Abidjan',
      customer_country: 'CI',
      customer_state: 'CI',
      customer_zip_code: '00225',
      notify_url: `${process.env.BACKEND_URL}/api/payments/cinetpay/notify-diagnostic`,
      return_url: `${process.env.FRONTEND_URL}/payment/success`,
      channels: 'ALL',
      metadata: JSON.stringify({
        interventionId: intervention.id,
        userId: userId,
        customerProfileId: customerProfile.id,
        type: 'diagnostic'
      }),
      lang: 'FR',
      invoice_data: {
        "Intervention": `#${intervention.id}`,
        "Type": "Frais de diagnostic",
        "Client": `${customerProfile.first_name} ${customerProfile.last_name}`,
        "Montant": `${amount} FCFA`
      }
    };

    console.log('📤 Envoi requête CinetPay pour diagnostic...');

    // Appeler l'API CinetPay
    const response = await axios.post(CINETPAY_API_URL, cinetpayData, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MCT-Maintenance/1.0'
      }
    });

    console.log('📥 Réponse CinetPay:', response.data);

    if (response.data.code === '201') {
      // Succès - Marquer le paiement comme en attente
      await intervention.update({
        notes: intervention.notes ? 
          `${intervention.notes}\nTransaction diagnostic: ${transactionId}` : 
          `Transaction diagnostic: ${transactionId}`
      });

      console.log('✅ Paiement diagnostic initialisé avec succès');

      return res.json({
        success: true,
        message: 'Paiement du diagnostic initialisé',
        data: {
          payment_url: response.data.data.payment_url,
          payment_token: response.data.data.payment_token,
          transaction_id: transactionId,
          amount: amount
        }
      });
    } else {
      console.error('❌ Erreur CinetPay:', response.data);
      return res.status(400).json({
        success: false,
        message: response.data.description || 'Erreur lors de l\'initialisation du paiement',
        error: response.data
      });
    }

  } catch (error) {
    console.error('❌ Erreur initialisation paiement diagnostic:', error.message);
    console.error('❌ Détails erreur:', error.response?.data || error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'initialisation du paiement',
      error: error.response?.data || error.message
    });
  }
};

/**
 * Notification de paiement diagnostic (webhook CinetPay)
 */
const handleDiagnosticNotification = async (req, res) => {
  try {
    console.log('🔔 Notification paiement diagnostic reçue:', req.body);

    const { cpm_trans_id, cpm_trans_status, cpm_custom } = req.body;

    // Vérifier le statut du paiement auprès de CinetPay
    const verifyData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: cpm_trans_id
    };

    const verifyResponse = await axios.post(CINETPAY_VERIFY_URL, verifyData, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MCT-Maintenance/1.0'
      }
    });

    console.log('✅ Vérification paiement diagnostic:', verifyResponse.data);

    if (verifyResponse.data.code === '00') {
      // Paiement confirmé
      const metadata = JSON.parse(cpm_custom || '{}');
      const interventionId = metadata.interventionId;

      if (interventionId) {
        const { Intervention } = require('../../models');
        
        const intervention = await Intervention.findByPk(interventionId, {
          include: [
            { 
              model: CustomerProfile, 
              as: 'customer',
              include: [{
                model: User,
                as: 'user',
                attributes: ['id', 'email', 'phone', 'first_name', 'last_name']
              }]
            }
          ]
        });
        
        if (intervention && intervention.diagnostic_paid !== true) {
          await intervention.update({
            diagnostic_paid: true,
            diagnostic_payment_date: new Date()
          });

          console.log(`✅ Frais de diagnostic payés pour intervention ${interventionId}`);

          // TODO: Envoyer notification au client et au technicien
        }
      }

      return res.json({ success: true, message: 'Paiement diagnostic confirmé' });
    } else {
      console.log('⚠️ Paiement diagnostic non confirmé:', verifyResponse.data);
      return res.json({ success: false, message: 'Paiement non confirmé' });
    }

  } catch (error) {
    console.error('❌ Erreur notification paiement diagnostic:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du traitement de la notification',
      error: error.message
    });
  }
};

/**
 * Initialiser un paiement CinetPay pour un devis (après acceptation)
 * Paiement en deux étapes: 
 *   - payment_step=1 : 50% à l'acceptation du devis
 *   - payment_step=2 : 50% restant à la fin de l'intervention
 */
const initializeQuotePayment = async (req, res) => {
  try {
    const { quoteId, payment_step = 1 } = req.body; // payment_step: 1 ou 2
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement devis CinetPay - Quote ${quoteId}, Step ${payment_step}, User ${userId}`);

    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: userId },
      include: [{ model: User, as: 'user' }]
    });

    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé'
      });
    }

    // Récupérer le devis
    const quote = await Quote.findOne({
      where: { id: quoteId },
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [{ model: CustomerProfile, as: 'customer' }]
        },
        { model: DiagnosticReport, as: 'diagnosticReport' }
      ]
    });

    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Devis non trouvé'
      });
    }

    // Vérifier que c'est bien le client du devis
    if (quote.intervention.customer.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à payer ce devis'
      });
    }

    // Vérifier que le devis est accepté
    if (quote.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: 'Le devis doit être accepté avant de pouvoir être payé'
      });
    }

    // Déterminer le montant selon l'étape de paiement
    let paymentAmount;
    let paymentDescription;

    if (payment_step === 1) {
      // Premier paiement (50%)
      if (quote.first_payment_status === 'paid') {
        return res.status(400).json({
          success: false,
          message: 'Le premier paiement (50%) a déjà été effectué'
        });
      }
      paymentAmount = quote.first_payment_amount || Math.ceil(quote.total / 2);
      paymentDescription = `Acompte 50% - Devis ${quote.reference}`;
    } else if (payment_step === 2) {
      // Second paiement (50% restant)
      if (quote.first_payment_status !== 'paid') {
        return res.status(400).json({
          success: false,
          message: 'Le premier paiement (50%) doit être effectué avant le second'
        });
      }
      if (quote.second_payment_status === 'paid') {
        return res.status(400).json({
          success: false,
          message: 'Le second paiement (50%) a déjà été effectué'
        });
      }
      paymentAmount = quote.second_payment_amount || (quote.total - (quote.first_payment_amount || Math.ceil(quote.total / 2)));
      paymentDescription = `Solde 50% - Devis ${quote.reference} (Fin d'intervention)`;
    } else {
      return res.status(400).json({
        success: false,
        message: 'Étape de paiement invalide (1 ou 2 attendu)'
      });
    }

    // Vérifier que le devis n'est pas entièrement payé
    if (quote.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Ce devis a déjà été intégralement payé'
      });
    }

    // Arrondir le montant au multiple de 5 le plus proche (requis par CinetPay)
    const roundedAmount = Math.round(paymentAmount / 5) * 5;

    // Générer un ID de transaction unique
    const transactionId = `QTE-${quoteId}-S${payment_step}-${Date.now()}`;

    // Préparer les données pour CinetPay
    const cinetpayData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transactionId,
      amount: roundedAmount,
      currency: 'XOF', // Franc CFA
      description: paymentDescription,
      customer_name: customerProfile.first_name + ' ' + customerProfile.last_name,
      customer_surname: customerProfile.last_name,
      customer_email: customerProfile.user?.email || 'client@example.com',
      customer_phone_number: customerProfile.phone_number || '',
      customer_address: customerProfile.address || '',
      customer_city: 'Abidjan',
      customer_country: 'CI',
      customer_state: 'CI',
      customer_zip_code: '00225',
      notify_url: `${process.env.API_URL || 'http://localhost:3000'}/api/payments/cinetpay/notify-quote`,
      return_url: `${process.env.FRONTEND_URL || 'http://localhost:3001'}/payment-success`,
      channels: 'ALL', // Tous les moyens de paiement
      metadata: JSON.stringify({
        quote_id: quoteId,
        intervention_id: quote.intervention_id,
        customer_id: customerProfile.id,
        user_id: userId,
        payment_step: payment_step
      })
    };

    console.log('📤 Envoi requête CinetPay pour devis:', {
      transaction_id: transactionId,
      amount: roundedAmount,
      quote_reference: quote.reference,
      payment_step: payment_step
    });

    // Appeler l'API CinetPay
    const response = await axios.post(CINETPAY_API_URL, cinetpayData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('📥 Réponse CinetPay:', response.data);

    if (response.data.code === '201' && response.data.data?.payment_url) {
      // Mettre à jour le devis avec l'ID de transaction selon l'étape
      const updateData = payment_step === 1
        ? { first_payment_transaction_id: transactionId, payment_status: 'partial_pending' }
        : { second_payment_transaction_id: transactionId };
      
      await quote.update(updateData);

      return res.json({
        success: true,
        payment_url: response.data.data.payment_url,
        transaction_id: transactionId,
        amount: roundedAmount,
        payment_step: payment_step,
        payment_type: payment_step === 1 ? 'Acompte 50%' : 'Solde 50%'
      });
    } else {
      console.error('❌ Erreur CinetPay:', response.data);
      return res.status(400).json({
        success: false,
        message: 'Erreur lors de l\'initialisation du paiement',
        error: response.data.message || 'Erreur inconnue'
      });
    }

  } catch (error) {
    console.error('❌ Erreur initialisation paiement devis:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'initialisation du paiement',
      error: error.message
    });
  }
};

/**
 * Gérer la notification de paiement pour un devis (webhook CinetPay)
 * Paiement en deux étapes: S1 = 50% à l'acceptation, S2 = 50% à la fin
 */
const handleQuoteNotification = async (req, res) => {
  try {
    const { transaction_id, cpm_trans_id } = req.body;
    
    console.log('🔔 Notification paiement devis reçue:', { transaction_id, cpm_trans_id });

    // Vérifier le paiement auprès de CinetPay
    const verifyResponse = await axios.post(CINETPAY_VERIFY_URL, {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transaction_id
    });

    console.log('📥 Vérification paiement devis:', verifyResponse.data);

    if (verifyResponse.data.code === '00' && verifyResponse.data.data?.status === 'ACCEPTED') {
      // Extraire l'ID du devis et l'étape de paiement depuis le transaction_id
      // Format: QTE-{quoteId}-S{step}-{timestamp} (nouveau) ou QTE-{quoteId}-{timestamp} (ancien)
      const parts = transaction_id.split('-');
      const quoteId = parts[1];
      
      // Détecter l'étape de paiement
      let paymentStep = 1; // Par défaut, c'est le premier paiement
      if (parts.length >= 3 && parts[2].startsWith('S')) {
        paymentStep = parseInt(parts[2].substring(1)) || 1;
      }
      
      console.log(`💰 Paiement devis ${quoteId} - Étape ${paymentStep}`);
      
      const quote = await Quote.findByPk(quoteId, {
        include: [
          { 
            model: Intervention, 
            as: 'intervention',
            include: [
              { model: CustomerProfile, as: 'customer' },
              { model: User, as: 'assignedTo' }
            ]
          },
          { 
            model: DiagnosticReport, 
            as: 'diagnosticReport',
            include: [{ model: User, as: 'technician' }]
          }
        ]
      });

      if (!quote) {
        console.error(`❌ Devis ${quoteId} non trouvé`);
        return res.status(404).json({ success: false, message: 'Devis non trouvé' });
      }

      const paymentMethod = verifyResponse.data.data.payment_method || 'CinetPay';
      const now = new Date();

      if (paymentStep === 1) {
        // ========== PREMIER PAIEMENT (50%) ==========
        if (quote.first_payment_status === 'paid') {
          console.log(`⚠️ Premier paiement déjà effectué pour le devis ${quoteId}`);
          return res.json({ success: true, message: 'Premier paiement déjà enregistré' });
        }

        // Mettre à jour le premier paiement
        await quote.update({
          first_payment_status: 'paid',
          first_payment_date: now,
          first_payment_transaction_id: transaction_id,
          payment_method: paymentMethod,
          payment_status: 'partial' // Partiellement payé (50%)
        });

        console.log(`✅ Premier paiement (50%) enregistré pour le devis ${quoteId}`);

        // Notifier le client
        if (quote.intervention?.customer?.user_id) {
          await notificationService.create({
            userId: quote.intervention.customer.user_id,
            type: 'payment_received',
            title: '💳 Acompte reçu',
            message: `Votre acompte de ${(quote.first_payment_amount || Math.ceil(quote.total / 2)).toLocaleString('fr-FR')} FCFA a été reçu. L'intervention peut être planifiée.`,
            data: { 
              quote_id: quote.id, 
              intervention_id: quote.intervention_id,
              amount: quote.first_payment_amount,
              payment_step: 1
            },
            priority: 'high'
          });
        }

        // Notifier les admins et managers
        const adminUsers = await User.findAll({ where: { role: { [Op.in]: ['admin', 'manager'] }, status: 'active' } });
        for (const admin of adminUsers) {
          await notificationService.create({
            userId: admin.id,
            type: 'payment_received',
            title: '💰 Acompte 50% reçu',
            message: `Acompte de ${(quote.first_payment_amount || Math.ceil(quote.total / 2)).toLocaleString('fr-FR')} FCFA reçu pour le devis ${quote.reference}. Intervention prête à démarrer.`,
            data: { quote_id: quote.id, intervention_id: quote.intervention_id, payment_step: 1 },
            priority: 'high'
          });
        }

        // Notifier le technicien que l'intervention peut commencer
        const technicianId = quote.diagnosticReport?.technician_id || quote.intervention?.assigned_to;
        if (technicianId) {
          await notificationService.create({
            userId: technicianId,
            type: 'payment_received',
            title: '✅ Acompte reçu - Intervention autorisée',
            message: `L'acompte de 50% a été reçu pour l'intervention #${quote.intervention_id}. Vous pouvez procéder.`,
            data: { quote_id: quote.id, intervention_id: quote.intervention_id },
            priority: 'high'
          });
        }

        return res.json({ success: true, message: 'Premier paiement (50%) enregistré', payment_step: 1 });

      } else if (paymentStep === 2) {
        // ========== SECOND PAIEMENT (50% restant) ==========
        if (quote.second_payment_status === 'paid') {
          console.log(`⚠️ Second paiement déjà effectué pour le devis ${quoteId}`);
          return res.json({ success: true, message: 'Second paiement déjà enregistré' });
        }

        // Mettre à jour le second paiement et marquer comme entièrement payé
        await quote.update({
          second_payment_status: 'paid',
          second_payment_date: now,
          second_payment_transaction_id: transaction_id,
          payment_status: 'paid', // Entièrement payé (100%)
          paid_at: now
        });

        console.log(`✅ Second paiement (50%) enregistré pour le devis ${quoteId} - ENTIÈREMENT PAYÉ`);

        // Notifier le client
        if (quote.intervention?.customer?.user_id) {
          await notificationService.create({
            userId: quote.intervention.customer.user_id,
            type: 'payment_completed',
            title: '✅ Paiement complet',
            message: `Le solde de ${(quote.second_payment_amount || (quote.total - (quote.first_payment_amount || 0))).toLocaleString('fr-FR')} FCFA a été reçu. Votre intervention est maintenant terminée et entièrement payée.`,
            data: { 
              quote_id: quote.id, 
              intervention_id: quote.intervention_id,
              amount: quote.second_payment_amount,
              payment_step: 2,
              total_paid: quote.total
            },
            priority: 'high'
          });
        }

        // Marquer l'intervention comme terminée et payée
        if (quote.intervention) {
          await quote.intervention.update({
            payment_status: 'paid',
            payment_date: now
          });
        }

        return res.json({ success: true, message: 'Paiement complet (100%) enregistré', payment_step: 2 });
      }

      return res.json({ success: true, message: 'Paiement devis traité' });
    } else {
      console.log('⚠️ Paiement devis non confirmé:', verifyResponse.data);
      return res.json({ success: false, message: 'Paiement non confirmé' });
    }

  } catch (error) {
    console.error('❌ Erreur notification paiement devis:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du traitement de la notification',
      error: error.message
    });
  }
};

module.exports = {
  initializePayment,
  handleNotification,
  checkPaymentStatus,
  initializeDiagnosticPayment,
  handleDiagnosticNotification,
  initializeQuotePayment,
  handleQuoteNotification
};
