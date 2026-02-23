const axios = require('axios');

/**
 * Script de test pour le paiement CinetPay
 */

const API_URL = 'http://localhost:3001'; // Votre URL backend
const TOKEN = 'VOTRE_TOKEN_JWT'; // Token d'authentification client

async function testPayment() {
  try {
    console.log('🧪 Test Paiement CinetPay\n');

    // 1. Récupérer ou créer une commande de test
    console.log('📦 Étape 1: Récupération des commandes...');
    const ordersResponse = await axios.get(`${API_URL}/api/orders`, {
      headers: { Authorization: `Bearer ${TOKEN}` }
    });

    if (!ordersResponse.data.orders || ordersResponse.data.orders.length === 0) {
      console.log('❌ Aucune commande trouvée');
      console.log('💡 Créez d\'abord une commande depuis l\'application mobile\n');
      return;
    }

    // Prendre la première commande non payée
    const order = ordersResponse.data.orders.find(o => o.paymentStatus === 'pending');
    
    if (!order) {
      console.log('❌ Aucune commande en attente de paiement');
      console.log('💡 Créez une nouvelle commande depuis l\'application\n');
      return;
    }

    console.log(`✅ Commande trouvée: #${order.id} - ${order.totalAmount} FCFA`);
    console.log(`   Statut paiement: ${order.paymentStatus}\n`);

    // 2. Initialiser le paiement
    console.log('💳 Étape 2: Initialisation du paiement...');
    const paymentResponse = await axios.post(
      `${API_URL}/api/payments/cinetpay/initialize`,
      { orderId: order.id },
      { headers: { Authorization: `Bearer ${TOKEN}` } }
    );

    if (!paymentResponse.data.success) {
      console.log('❌ Erreur initialisation:', paymentResponse.data.message);
      return;
    }

    console.log('✅ Paiement initialisé avec succès!\n');
    console.log('📋 Informations du paiement:');
    console.log(`   Transaction ID: ${paymentResponse.data.data.transaction_id}`);
    console.log(`   Payment Token: ${paymentResponse.data.data.payment_token}`);
    console.log(`   URL de paiement: ${paymentResponse.data.data.payment_url}\n`);

    // 3. Instructions pour le test
    console.log('🎯 PROCHAINES ÉTAPES:\n');
    console.log('1. Ouvrez cette URL dans un navigateur:');
    console.log(`   ${paymentResponse.data.data.payment_url}\n`);
    
    console.log('2. Pour tester en MODE TEST CinetPay, utilisez:');
    console.log('   📱 Mobile Money Orange:');
    console.log('      - Numéro: 0707070707');
    console.log('      - Code OTP: 1234');
    console.log('   💳 Carte Bancaire:');
    console.log('      - Numéro: 4000000000000002');
    console.log('      - Exp: 12/25');
    console.log('      - CVV: 123\n');
    
    console.log('3. Après paiement, vérifiez le statut:');
    console.log(`   GET ${API_URL}/api/payments/cinetpay/status/${paymentResponse.data.data.transaction_id}\n`);

    // 4. Attendre puis vérifier le statut
    console.log('⏳ Attendez 30 secondes pour effectuer le paiement...\n');
    
    await new Promise(resolve => setTimeout(resolve, 30000));

    console.log('🔍 Vérification du statut du paiement...');
    const statusResponse = await axios.get(
      `${API_URL}/api/payments/cinetpay/status/${paymentResponse.data.data.transaction_id}`,
      { headers: { Authorization: `Bearer ${TOKEN}` } }
    );

    console.log('📥 Statut:', JSON.stringify(statusResponse.data, null, 2));

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

// Exécuter le test
testPayment();
