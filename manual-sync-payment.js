const fs = require('fs');
const path = require('path');
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

/**
 * Script pour associer manuellement un paiement FineoPay à une commande
 * Usage: node manual-sync-payment.js <orderId> <fineopayReference>
 */

const orderId = process.argv[2];
const fineopayReference = process.argv[3];

if (!orderId || !fineopayReference) {
  console.error('\n❌ Usage: node manual-sync-payment.js <orderId> <fineopayReference>');
  console.error('\nExemple: node manual-sync-payment.js 61 wucoqblwwpjekjksabqqhsidvpjawr\n');
  process.exit(1);
}

async function syncPayment() {
  try {
    console.log('\n🔄 Synchronisation manuelle du paiement\n');
    console.log(`📦 Commande: #${orderId}`);
    console.log(`🔗 Référence FineoPay: ${fineopayReference}\n`);

    // 1. Récupérer la commande
    console.log('1️⃣ Recherche de la commande...');
    const order = await Order.findByPk(orderId);

    if (!order) {
      console.error(`   ❌ Commande #${orderId} introuvable\n`);
      process.exit(1);
    }

    // Récupérer le devis séparément
    const quote = order.quoteId ? await Quote.findByPk(order.quoteId) : null;

    console.log(`   ✅ Commande trouvée: ${order.reference}`);
    console.log(`   Statut actuel: ${order.paymentStatus}`);
    console.log(`   Montant: ${order.totalAmount} FCFA\n`);

    // 2. Vérifier si déjà payée
    if (order.paymentStatus === 'paid') {
      console.log('   ⚠️ Cette commande est déjà marquée comme payée');
      console.log(`   Date paiement: ${order.paymentDate}`);
      console.log(`   Référence: ${order.fineopayReference}\n`);
      
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });
      
      const answer = await new Promise(resolve => {
        readline.question('   Forcer la mise à jour ? (oui/non): ', resolve);
      });
      readline.close();
      
      if (answer.toLowerCase() !== 'oui') {
        console.log('\n   ❌ Opération annulée\n');
        process.exit(0);
      }
    }

    // 3. Mettre à jour la commande
    console.log('2️⃣ Mise à jour de la commande...');
    await order.update({
      paymentStatus: 'paid',
      paymentMethod: 'fineopay',
      paymentDate: new Date(),
      fineopayReference: fineopayReference
    });
    console.log('   ✅ Commande mise à jour\n');

    // 4. Mettre à jour le devis associé
    if (quote) {
      console.log('3️⃣ Mise à jour du devis...');
      await quote.update({
        paymentStatus: 'paid',
        payment_date: new Date()
      });
      console.log('   ✅ Devis mis à jour\n');
    }

    console.log('✅ ============================================');
    console.log('✅ PAIEMENT SYNCHRONISÉ AVEC SUCCÈS !');
    console.log('✅ ============================================\n');
    console.log(`   Commande #${orderId}: ${order.reference}`);
    console.log(`   Statut: PAYÉ`);
    console.log(`   Méthode: FineoPay`);
    console.log(`   Référence: ${fineopayReference}`);
    console.log(`   Date: ${new Date().toLocaleString('fr-FR')}\n`);

  } catch (error) {
    console.error('\n❌ Erreur lors de la synchronisation:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    // Fermer la connexion à la base de données
    const { sequelize } = require('./mct-maintenance-api/src/models');
    await sequelize.close();
  }
}

syncPayment();
