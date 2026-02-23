const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { Order, Quote, Intervention, CustomerProfile, User } = require('./mct-maintenance-api/src/models');

// Charger les variables d'environnement depuis le fichier .env
const envPath = path.join(__dirname, 'mct-maintenance-api', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=:#]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim().replace(/^['"](.*)['"]$/, '$1');
      process.env[key] = value;
    }
  });
}

// Configuration FineoPay
const FINEOPAY_BASE_URL = 'https://dev.fineopay.com/api/v1/business/dev';
const FINEOPAY_BUSINESS_CODE = process.env.FINEOPAY_BUSINESS_CODE || 'smart_maintenance_by_mct';
const FINEOPAY_API_KEY = process.env.FINEOPAY_API_KEY;

const orderId = process.argv[2] || '61';

async function checkAndSync() {
  try {
    console.log('\n🔍 Vérification et synchronisation du paiement FineoPay\n');
    console.log('================================================\n');

    // 1. Vérifier la configuration
    console.log('1️⃣ Configuration FineoPay:');
    console.log(`   Business Code: ${FINEOPAY_BUSINESS_CODE}`);
    console.log(`   API Key: ${FINEOPAY_API_KEY ? FINEOPAY_API_KEY.substring(0, 20) + '...' : '❌ NON DÉFINIE'}`);
    console.log('');

    if (!FINEOPAY_API_KEY) {
      console.error('   ❌ FINEOPAY_API_KEY non définie dans .env\n');
      process.exit(1);
    }

    // 2. Récupérer la commande depuis la DB
    console.log(`2️⃣ Recherche de la commande #${orderId}...`);
    const order = await Order.findByPk(orderId);

    if (!order) {
      console.error(`   ❌ Commande #${orderId} introuvable\n`);
      process.exit(1);
    }

    // Récupérer le devis séparément si nécessaire
    const quote = order.quoteId ? await Quote.findByPk(order.quoteId) : null;

    console.log(`   ✅ Commande trouvée`);
    console.log(`   Référence: ${order.reference}`);
    console.log(`   Statut actuel: ${order.paymentStatus}`);
    console.log(`   Montant: ${order.totalAmount} FCFA`);
    console.log(`   Référence FineoPay: ${order.fineopayReference || 'N/A'}`);
    console.log('');

    // 3. Vérifier les transactions FineoPay
    console.log('3️⃣ Récupération des transactions FineoPay...');
    try {
      const response = await axios.get(
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

      console.log('   DEBUG - Réponse complète:', JSON.stringify(response.data, null, 2));
      
      const transactions = response.data.data || response.data.transactions || response.data || [];
      console.log(`   📊 ${Array.isArray(transactions) ? transactions.length : 'Format inattendu'} transaction(s) récupérée(s)\n`);

      // 4. Chercher la transaction correspondante
      console.log('4️⃣ Recherche de correspondance...');
      const syncRef = `ORDER_${orderId}`;
      console.log(`   SyncRef recherché: ${syncRef}\n`);

      const matchBySyncRef = transactions.find(tx => tx.syncRef === syncRef);

      if (matchBySyncRef) {
        console.log('   ✅ Transaction trouvée par syncRef !');
        console.log(`   Référence FineoPay: ${matchBySyncRef.reference}`);
        console.log(`   Status: ${matchBySyncRef.status}`);
        console.log(`   Montant: ${matchBySyncRef.amount} FCFA`);
        console.log(`   Date: ${new Date(matchBySyncRef.timestamp).toLocaleString('fr-FR')}`);
        console.log('');

        if (matchBySyncRef.status === 'success') {
          if (order.paymentStatus !== 'paid') {
            console.log('5️⃣ Mise à jour de la commande...');
            await order.update({
              paymentStatus: 'paid',
              paymentMethod: 'fineopay',
              paymentDate: new Date(matchBySyncRef.timestamp),
              fineopayReference: matchBySyncRef.reference
            });
            console.log('   ✅ Commande mise à jour\n');

            if (quote) {
              await quote.update({
                paymentStatus: 'paid',
                payment_date: new Date(matchBySyncRef.timestamp)
              });
              console.log('   ✅ Devis mis à jour\n');
            }

            console.log('✅ ============================================');
            console.log('✅ PAIEMENT SYNCHRONISÉ AVEC SUCCÈS !');
            console.log('✅ ============================================\n');
          } else {
            console.log('   ℹ️ La commande est déjà marquée comme payée\n');
          }
        } else {
          console.log(`   ⚠️ Transaction trouvée mais statut: ${matchBySyncRef.status}`);
          console.log('   Le paiement n\'a pas encore été validé par FineoPay\n');
        }
      } else {
        console.log('   ⚠️ Aucune transaction trouvée avec ce syncRef\n');
        console.log('   Transactions réussies récentes:\n');
        
        const successTx = transactions
          .filter(tx => tx.status === 'success')
          .slice(0, 5);

        if (successTx.length === 0) {
          console.log('   ❌ Aucune transaction réussie trouvée\n');
          console.log('   💡 Le paiement n\'a peut-être pas encore été effectué sur le lien:');
          console.log('      https://demo.fineopay.com/smart_maintenance_by_mct/wucoqblwwpjekjksabqqhsidvpjawr/checkout\n');
        } else {
          successTx.forEach((tx, i) => {
            console.log(`   ${i + 1}. Référence: ${tx.reference}`);
            console.log(`      Montant: ${tx.amount} FCFA`);
            console.log(`      Date: ${new Date(tx.timestamp).toLocaleString('fr-FR')}`);
            console.log(`      SyncRef: ${tx.syncRef || '⚠️ AUCUN'}`);
            console.log(`      Client: ${tx.clientAccountNumber || 'N/A'}`);
            console.log('');
          });

          console.log('\n   💡 Si une transaction correspond à votre paiement, utilisez:');
          console.log(`      node manual-sync-payment.js ${orderId} <reference_fineopay>\n`);
        }
      }

    } catch (fineoError) {
      console.error('   ❌ Erreur lors de la requête FineoPay:', fineoError.message);
      if (fineoError.response) {
        console.error('   Détails:', fineoError.response.data);
      }
      console.log('');
    }

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
    console.error(error);
  } finally {
    const { sequelize } = require('./mct-maintenance-api/src/models');
    await sequelize.close();
  }
}

checkAndSync();
