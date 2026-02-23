const axios = require('axios');
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
 */
const initializeQuotePayment = async (req, res) => {
  try {
    const { quoteId } = req.body;
    const userId = req.user.id;

    console.log(`💳 Initialisation paiement devis CinetPay - Quote ${quoteId}, User ${userId}`);

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

    // Vérifier que le devis n'est pas déjà payé
    if (quote.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Ce devis a déjà été payé'
      });
    }

    // Arrondir le montant au multiple de 5 le plus proche (requis par CinetPay)
    const roundedAmount = Math.round(quote.total / 5) * 5;

    // Générer un ID de transaction unique
    const transactionId = `QTE-${quoteId}-${Date.now()}`;

    // Préparer les données pour CinetPay
    const cinetpayData = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: transactionId,
      amount: roundedAmount,
      currency: 'XOF', // Franc CFA
      description: `Paiement devis ${quote.reference} - Intervention #${quote.intervention_id}`,
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
        user_id: userId
      })
    };

    console.log('📤 Envoi requête CinetPay pour devis:', {
      transaction_id: transactionId,
      amount: roundedAmount,
      quote_reference: quote.reference
    });

    // Appeler l'API CinetPay
    const response = await axios.post(CINETPAY_API_URL, cinetpayData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('📥 Réponse CinetPay:', response.data);

    if (response.data.code === '201' && response.data.data?.payment_url) {
      // Mettre à jour le devis avec l'ID de transaction
      await quote.update({
        payment_transaction_id: transactionId,
        payment_status: 'pending'
      });

      return res.json({
        success: true,
        payment_url: response.data.data.payment_url,
        transaction_id: transactionId,
        amount: roundedAmount
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
      // Extraire l'ID du devis depuis le transaction_id (format: QTE-{quoteId}-{timestamp})
      const quoteId = transaction_id.split('-')[1];
      
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

      if (quote && quote.payment_status !== 'paid') {
        // Mettre à jour le devis
        await quote.update({
          payment_status: 'paid',
          paid_at: new Date(),
          payment_method: verifyResponse.data.data.payment_method || 'CinetPay'
        });

        // 👨‍🔧 ASSIGNER LE TECHNICIEN DU DIAGNOSTIC À L'INTERVENTION
        const technicianId = quote.diagnosticReport?.technician_id;
        
        if (technicianId) {
          // Planifier la date d'intervention (2 jours ouvrés après le paiement)
          const scheduledDate = new Date();
          scheduledDate.setDate(scheduledDate.getDate() + 2);
          
          // Éviter les week-ends : si samedi, passer à lundi
          if (scheduledDate.getDay() === 6) { // Samedi
            scheduledDate.setDate(scheduledDate.getDate() + 2);
          } else if (scheduledDate.getDay() === 0) { // Dimanche
            scheduledDate.setDate(scheduledDate.getDate() + 1);
          }
          
          // Définir l'heure à 9h du matin
          scheduledDate.setHours(9, 0, 0, 0);

          // NE PAS modifier le statut de l'intervention de diagnostic (elle reste diagnostic_submitted)
          // On met seulement à jour la date de paiement du diagnostic
          await quote.intervention.update({
            diagnostic_payment_date: new Date(),
            diagnostic_paid: true
          });

          console.log(`✅ Paiement enregistré pour l'intervention de diagnostic ${quote.intervention_id}`);
          console.log(`ℹ️ L'intervention de diagnostic reste en statut: ${quote.intervention.status}`);
        } else {
          // Si pas de technicien dans le diagnostic, juste marquer le paiement
          await quote.intervention.update({
            payment_date: new Date()
          });
          console.log(`⚠️ Pas de technicien trouvé dans le diagnostic pour l'intervention ${quote.intervention_id}`);
        }

        // Mettre à jour le rapport de diagnostic
        if (quote.diagnosticReport) {
          await quote.diagnosticReport.update({
            status: 'approved'
          });
        }

        console.log(`✅ Devis ${quoteId} payé - Intervention de diagnostic terminée, création intervention de suivi...`);

        // Pas de notification pour l'intervention de diagnostic (déjà terminée)
        // Les notifications seront envoyées pour la nouvelle intervention de suivi
        
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
          
          const customerName = `${quote.intervention.customer.first_name} ${quote.intervention.customer.last_name}`;
          
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
              message: `Intervention de suivi assignée à ${technicianName} pour ${customerName} le ${followUpDateStr}.`,
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
      }

      return res.json({ success: true, message: 'Paiement devis confirmé' });
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
