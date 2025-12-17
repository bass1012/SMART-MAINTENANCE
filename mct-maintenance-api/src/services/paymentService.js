const axios = require('axios');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || 'sk_test_dummy');

/**
 * Service de gestion des paiements
 * Supporte: Stripe, Wave, Orange Money
 */

// Configuration des providers de paiement
const PAYMENT_PROVIDERS = {
  STRIPE: 'stripe',
  WAVE: 'wave',
  ORANGE_MONEY: 'orange_money',
  MTN_MONEY: 'mtn_money',
  MOOV_MONEY: 'moov_money'
};

/**
 * Initier un paiement Stripe
 */
const initiateStripePayment = async (amount, currency, description, metadata) => {
  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Stripe utilise les centimes
      currency: currency || 'xof', // Franc CFA
      description,
      metadata
    });

    return {
      success: true,
      provider: PAYMENT_PROVIDERS.STRIPE,
      paymentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status
    };
  } catch (error) {
    console.error('Erreur Stripe:', error);
    throw new Error(`Erreur de paiement Stripe: ${error.message}`);
  }
};

/**
 * Initier un paiement Wave (Côte d'Ivoire)
 * Documentation: https://developer.wave.com/
 */
const initiateWavePayment = async (amount, currency, phoneNumber, description) => {
  try {
    // Configuration Wave pour la Côte d'Ivoire
    const waveApiUrl = process.env.WAVE_API_URL || 'https://api.wave.com/v1';
    const waveApiKey = process.env.WAVE_API_KEY;

    if (!waveApiKey) {
      throw new Error('Clé API Wave non configurée');
    }

    const response = await axios.post(
      `${waveApiUrl}/checkout/sessions`,
      {
        amount: amount,
        currency: currency || 'XOF', // Franc CFA (Côte d'Ivoire)
        success_url: `${process.env.FRONTEND_URL}/payment/success`,
        cancel_url: `${process.env.FRONTEND_URL}/payment/cancel`,
        client_reference: description,
        mobile_number: phoneNumber // Format: +2250701234567
      },
      {
        headers: {
          'Authorization': `Bearer ${waveApiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return {
      success: true,
      provider: PAYMENT_PROVIDERS.WAVE,
      paymentId: response.data.id,
      checkoutUrl: response.data.wave_launch_url,
      status: 'pending'
    };
  } catch (error) {
    console.error('Erreur Wave:', error.response?.data || error.message);
    // En mode développement, retourner une simulation
    if (process.env.NODE_ENV === 'development') {
      return {
        success: true,
        provider: PAYMENT_PROVIDERS.WAVE,
        paymentId: `wave_sim_${Date.now()}`,
        checkoutUrl: `${process.env.FRONTEND_URL}/payment/wave-simulator`,
        status: 'pending',
        simulation: true
      };
    }
    throw new Error(`Erreur de paiement Wave: ${error.message}`);
  }
};

/**
 * Initier un paiement Orange Money
 * Documentation: https://developer.orange.com/apis/orange-money-webpay/
 */
const initiateOrangeMoneyPayment = async (amount, currency, phoneNumber, description) => {
  try {
    const orangeApiUrl = process.env.ORANGE_API_URL || 'https://api.orange.com/orange-money-webpay/';
    const orangeApiKey = process.env.ORANGE_API_KEY;

    if (!orangeApiKey) {
      throw new Error('Clé API Orange Money non configurée');
    }

    // Obtenir un token d'accès
    const tokenResponse = await axios.post(
      `${orangeApiUrl}/oauth/v2/token`,
      {
        grant_type: 'client_credentials'
      },
      {
        headers: {
          'Authorization': `Basic ${Buffer.from(`${process.env.ORANGE_CLIENT_ID}:${process.env.ORANGE_CLIENT_SECRET}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    const accessToken = tokenResponse.data.access_token;

    // Initier le paiement
    const paymentResponse = await axios.post(
      `${orangeApiUrl}/webpayment/v1/webpayment`,
      {
        merchant_key: process.env.ORANGE_MERCHANT_KEY,
        currency: currency || 'XOF',
        order_id: `order_${Date.now()}`,
        amount: amount,
        return_url: `${process.env.FRONTEND_URL}/payment/success`,
        cancel_url: `${process.env.FRONTEND_URL}/payment/cancel`,
        notif_url: `${process.env.API_URL}/api/payments/orange-webhook`,
        lang: 'fr',
        reference: description
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return {
      success: true,
      provider: PAYMENT_PROVIDERS.ORANGE_MONEY,
      paymentId: paymentResponse.data.payment_token,
      checkoutUrl: paymentResponse.data.payment_url,
      status: 'pending'
    };
  } catch (error) {
    console.error('Erreur Orange Money:', error.response?.data || error.message);
    // En mode développement, retourner une simulation
    if (process.env.NODE_ENV === 'development') {
      return {
        success: true,
        provider: PAYMENT_PROVIDERS.ORANGE_MONEY,
        paymentId: `orange_sim_${Date.now()}`,
        checkoutUrl: `${process.env.FRONTEND_URL}/payment/orange-simulator`,
        status: 'pending',
        simulation: true
      };
    }
    throw new Error(`Erreur de paiement Orange Money: ${error.message}`);
  }
};

/**
 * Vérifier le statut d'un paiement
 */
const checkPaymentStatus = async (paymentId, provider) => {
  try {
    switch (provider) {
      case PAYMENT_PROVIDERS.STRIPE:
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentId);
        return {
          status: paymentIntent.status,
          paid: paymentIntent.status === 'succeeded'
        };

      case PAYMENT_PROVIDERS.WAVE:
        // Implémenter la vérification Wave
        // const waveStatus = await axios.get(`${waveApiUrl}/checkout/sessions/${paymentId}`);
        return { status: 'pending', paid: false };

      case PAYMENT_PROVIDERS.ORANGE_MONEY:
        // Implémenter la vérification Orange Money
        return { status: 'pending', paid: false };

      case 'cash':
        // Paiement en espèces - reste en attente jusqu'à confirmation manuelle au bureau
        return { status: 'pending', paid: false };

      default:
        throw new Error('Provider de paiement non supporté');
    }
  } catch (error) {
    console.error('Erreur lors de la vérification du paiement:', error);
    throw error;
  }
};

/**
 * Rembourser un paiement
 */
const refundPayment = async (paymentId, provider, amount) => {
  try {
    switch (provider) {
      case PAYMENT_PROVIDERS.STRIPE:
        const refund = await stripe.refunds.create({
          payment_intent: paymentId,
          amount: amount ? Math.round(amount * 100) : undefined
        });
        return {
          success: true,
          refundId: refund.id,
          status: refund.status
        };

      case PAYMENT_PROVIDERS.WAVE:
      case PAYMENT_PROVIDERS.ORANGE_MONEY:
        // Implémenter les remboursements pour Wave et Orange Money
        throw new Error('Remboursement non implémenté pour ce provider');

      default:
        throw new Error('Provider de paiement non supporté');
    }
  } catch (error) {
    console.error('Erreur lors du remboursement:', error);
    throw error;
  }
};

module.exports = {
  PAYMENT_PROVIDERS,
  initiateStripePayment,
  initiateWavePayment,
  initiateOrangeMoneyPayment,
  checkPaymentStatus,
  refundPayment
};
