const axios = require('axios');

/**
 * Script pour vérifier les transactions FineoPay et associer manuellement un paiement
 * Usage: node check-fineopay-transactions.js [orderId]
 */

const API_URL = 'http://localhost:3000';
const orderId = process.argv[2] || '61';

async function getAuthToken() {
  // Utiliser un compte admin pour accéder à l'API
  // Vous pouvez remplacer par vos credentials admin
  const loginResponse = await axios.post(`${API_URL}/api/auth/login`, {
    email: 'admin@mct.com', // Remplacer par votre email admin
    password: 'admin123' // Remplacer par votre mot de passe
  });
  
  if (loginResponse.data.success) {
    return loginResponse.data.data.token;
  }
  throw new Error('Impossible de se connecter');
}

async function checkTransactions() {
  try {
    console.log('\n🔍 Vérification des transactions FineoPay\n');
    console.log(`📦 Commande cible: #${orderId}\n`);

    // 1. Obtenir un token d'authentification
    console.log('1️⃣ Authentification...');
    const token = await getAuthToken();
    console.log('   ✅ Connecté\n');

    // 2. Vérifier le statut actuel de la commande
    console.log('2️⃣ Statut actuel de la commande...');
    const orderResponse = await axios.get(
      `${API_URL}/api/fineopay/order-status/${orderId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const order = orderResponse.data.data;
    console.log('   Référence:', order.reference);
    console.log('   Statut:', order.paymentStatus);
    console.log('   Montant:', order.amount, 'FCFA\n');

    // 3. Récupérer toutes les transactions FineoPay
    console.log('3️⃣ Récupération des transactions FineoPay...');
    const transactionsResponse = await axios.get(
      `${API_URL}/api/fineopay/transactions`,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    const transactions = transactionsResponse.data.data || [];
    console.log(`   📊 ${transactions.length} transaction(s) trouvée(s)\n`);

    // 4. Afficher les transactions récentes (10 dernières)
    console.log('4️⃣ Dernières transactions:\n');
    transactions.slice(0, 10).forEach((tx, index) => {
      console.log(`   ${index + 1}. Transaction #${tx.reference || tx.id}`);
      console.log(`      Status: ${tx.status}`);
      console.log(`      Montant: ${tx.amount} FCFA`);
      console.log(`      SyncRef: ${tx.syncRef || 'N/A'}`);
      console.log(`      Date: ${new Date(tx.timestamp || tx.createdAt).toLocaleString('fr-FR')}`);
      console.log(`      Client: ${tx.clientAccountNumber || 'N/A'}`);
      console.log('');
    });

    // 5. Chercher une transaction qui correspond à notre commande
    console.log('5️⃣ Recherche de correspondance...\n');
    
    const targetSyncRef = `ORDER_${orderId}`;
    const matchBySyncRef = transactions.find(tx => tx.syncRef === targetSyncRef);
    
    if (matchBySyncRef) {
      console.log('   ✅ Transaction trouvée par syncRef!');
      console.log(`      Référence: ${matchBySyncRef.reference}`);
      console.log(`      Status: ${matchBySyncRef.status}`);
      console.log(`      Montant: ${matchBySyncRef.amount} FCFA\n`);
      
      if (matchBySyncRef.status === 'success' && order.paymentStatus !== 'paid') {
        console.log('   🔄 Le paiement est réussi mais la commande n\'est pas marquée comme payée');
        console.log('   💡 Utilisez: node sync-payment.js ' + orderId);
      }
    } else {
      console.log('   ⚠️ Aucune transaction trouvée avec syncRef:', targetSyncRef);
      console.log('\n   Transactions réussies récentes (possibles correspondances):\n');
      
      const successTransactions = transactions.filter(tx => tx.status === 'success').slice(0, 5);
      
      if (successTransactions.length === 0) {
        console.log('   ❌ Aucune transaction réussie trouvée');
        console.log('\n   💡 Le paiement n\'a peut-être pas encore été effectué ou');
        console.log('      le checkout a été créé sans syncRef (directement sur FineoPay)');
      } else {
        successTransactions.forEach((tx, index) => {
          console.log(`   ${index + 1}. Ref: ${tx.reference || tx.id}`);
          console.log(`      Montant: ${tx.amount} FCFA`);
          console.log(`      Date: ${new Date(tx.timestamp || tx.createdAt).toLocaleString('fr-FR')}`);
          console.log(`      SyncRef: ${tx.syncRef || '⚠️ AUCUN (créé manuellement)'}`);
          console.log('');
        });
        
        console.log('\n   💡 Si une de ces transactions correspond à votre paiement,');
        console.log('      vous devez associer manuellement la référence FineoPay à votre commande.');
        console.log('\n   Pour associer manuellement:');
        console.log(`      node manual-sync-payment.js ${orderId} <reference_fineopay>`);
      }
    }

    // 6. Vérification active auprès de FineoPay
    console.log('\n6️⃣ Vérification active auprès de FineoPay...');
    try {
      const verifyResponse = await axios.get(
        `${API_URL}/api/fineopay/verify-payment/${orderId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      const verifiedOrder = verifyResponse.data.data;
      console.log('   Statut après vérification:', verifiedOrder.paymentStatus);
      
      if (verifiedOrder.paymentStatus === 'paid') {
        console.log('\n   ✅✅✅ PAIEMENT CONFIRMÉ ! ✅✅✅');
        console.log('   La commande a été mise à jour automatiquement.\n');
      } else {
        console.log('\n   ⏳ Paiement toujours en attente\n');
      }
    } catch (error) {
      console.error('   ❌ Erreur lors de la vérification:', error.message);
    }

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
    if (error.response) {
      console.error('Détails:', error.response.data);
    }
  }
}

checkTransactions();
