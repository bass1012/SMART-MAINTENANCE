const axios = require('axios');

async function testUpdatePaymentStatus() {
  try {
    // 1. Login admin
    console.log('🔐 Login admin...');
    const loginResponse = await axios.post('http://127.0.0.1:3000/api/auth/login', {
      email: 'admin@mct-maintenance.com',
      password: 'P@ssword'
    });
    
    const token = loginResponse.data.data.accessToken;
    console.log('✅ Token admin obtenu\n');
    
    // 2. Trouver une commande
    console.log('📋 Récupération des commandes...');
    const ordersResponse = await axios.get('http://127.0.0.1:3000/api/orders', {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const order = ordersResponse.data.data[0]; // Prendre la première commande
    
    if (!order) {
      console.log('❌ Aucune commande trouvée');
      return;
    }
    
    console.log(`✅ Commande trouvée: ID=${order.id}, Reference=${order.reference}`);
    console.log(`   Customer ID: ${order.customerId}`);
    console.log(`   Payment status actuel: ${order.paymentStatus}\n`);
    
    // Trouver le user_id du client
    const cpResponse = await axios.get(`http://127.0.0.1:3000/api/customer-profiles/${order.customerId}`, {
      headers: { Authorization: `Bearer ${token}` }
    }).catch(() => null);
    
    if (cpResponse) {
      console.log(`   Client user ID: ${cpResponse.data.data.userId}\n`);
    }
    
    // 3. Changer le statut de paiement
    console.log('💳 Changement du statut de paiement...');
    const updateResponse = await axios.patch(
      `http://127.0.0.1:3000/api/orders/${order.id}/payment-status`,
      { paymentStatus: 'paid' },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    console.log('✅ Statut de paiement mis à jour');
    console.log('Response:', updateResponse.data);
    console.log('\n⏳ Attente de 3 secondes pour la notification push...');
    
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    console.log('✅ Test terminé. Vérifiez votre téléphone!');
    
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testUpdatePaymentStatus();
