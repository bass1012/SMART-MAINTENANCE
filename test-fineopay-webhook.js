const axios = require('axios');

/**
 * Script de test pour simuler un callback FineoPay
 * Usage: node test-fineopay-webhook.js <orderId>
 */

const orderId = process.argv[2] || '61'; // ID de la commande par défaut
const API_URL = 'http://localhost:3000';

async function testWebhook() {
  try {
    console.log(`\n🧪 Test du webhook FineoPay pour commande #${orderId}\n`);

    // 1. Vérifier le statut actuel de la commande
    console.log('1️⃣ Vérification du statut actuel...');
    const statusBefore = await axios.get(`${API_URL}/api/fineopay/order-status/${orderId}`);
    console.log('   Statut avant:', statusBefore.data.data.paymentStatus);
    console.log('   Référence:', statusBefore.data.data.reference);

    // 2. Simuler un callback FineoPay (paiement réussi)
    console.log('\n2️⃣ Simulation du callback FineoPay...');
    const webhookPayload = {
      reference: `TEST_REF_${Date.now()}`,
      amount: statusBefore.data.data.amount || 10000,
      status: 'success',
      clientAccountNumber: '+22501234567',
      timestamp: new Date().toISOString()
    };

    console.log('   Payload:', JSON.stringify(webhookPayload, null, 2));

    const webhookResponse = await axios.post(
      `${API_URL}/api/fineopay/callback`,
      webhookPayload,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('   Réponse webhook:', webhookResponse.data);

    // 3. Attendre un peu pour le traitement asynchrone
    console.log('\n3️⃣ Attente du traitement (3 secondes)...');
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 4. Vérifier le statut après le webhook
    console.log('\n4️⃣ Vérification du statut après webhook...');
    const statusAfter = await axios.get(`${API_URL}/api/fineopay/order-status/${orderId}`);
    console.log('   Statut après:', statusAfter.data.data.paymentStatus);
    console.log('   Méthode:', statusAfter.data.data.paymentMethod);
    console.log('   Mis à jour:', statusAfter.data.data.updatedAt);

    // 5. Résultat
    console.log('\n✅ Test terminé !');
    if (statusAfter.data.data.paymentStatus === 'paid') {
      console.log('   ✅ Le paiement a été marqué comme payé avec succès !');
    } else {
      console.log('   ⚠️ Le statut n\'a pas changé. Vérifier les logs du serveur.');
    }

  } catch (error) {
    console.error('\n❌ Erreur lors du test:', error.message);
    if (error.response) {
      console.error('   Réponse:', error.response.data);
    }
  }
}

// Exécuter le test
testWebhook();
