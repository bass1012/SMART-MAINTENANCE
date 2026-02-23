/**
 * Script de test pour la suppression complète d'un client
 * 
 * ATTENTION : Ce script supprime RÉELLEMENT les données !
 * À utiliser uniquement en développement avec précaution.
 */

require('dotenv').config();
const { deleteCustomerCompletely, softDeleteCustomer } = require('./src/services/customerDeletionService');
const { User, CustomerProfile } = require('./src/models');

async function listAllCustomers() {
  try {
    console.log('📋 LISTE DES CLIENTS\n');
    
    const customers = await User.findAll({
      where: { role: 'customer' },
      include: [{
        model: CustomerProfile,
        as: 'customerProfile'
      }],
      order: [['id', 'ASC']]
    });

    if (customers.length === 0) {
      console.log('ℹ️  Aucun client trouvé dans la base de données\n');
      return;
    }

    console.log(`Total: ${customers.length} client(s)\n`);
    console.log('┌──────┬─────────────────────────────┬──────────────────────────────────┬────────────┐');
    console.log('│ ID   │ Nom                         │ Email                            │ Statut     │');
    console.log('├──────┼─────────────────────────────┼──────────────────────────────────┼────────────┤');
    
    customers.forEach(customer => {
      const id = customer.id.toString().padEnd(4);
      const name = `${customer.first_name} ${customer.last_name}`.substring(0, 27).padEnd(27);
      const email = customer.email.substring(0, 32).padEnd(32);
      const status = customer.status.padEnd(10);
      
      console.log(`│ ${id} │ ${name} │ ${email} │ ${status} │`);
    });
    
    console.log('└──────┴─────────────────────────────┴──────────────────────────────────┴────────────┘\n');

  } catch (error) {
    console.error('❌ Erreur lors de la récupération des clients:', error.message);
  }
}

async function testCustomerDeletion() {
  try {
    console.log('\n🧪 TEST DE SUPPRESSION CLIENT\n');
    console.log('⚠️  ATTENTION : Ce test supprime réellement des données !\n');

    // Demander confirmation
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const customerId = await new Promise(resolve => {
      readline.question('Entrez l\'ID du client à supprimer (ou 0 pour annuler): ', answer => {
        readline.close();
        resolve(parseInt(answer));
      });
    });

    if (!customerId || customerId === 0) {
      console.log('❌ Suppression annulée\n');
      return;
    }

    // Vérifier que le client existe
    const user = await User.findByPk(customerId);
    if (!user) {
      console.log(`❌ Client avec l'ID ${customerId} non trouvé\n`);
      return;
    }

    console.log(`\n📋 Client trouvé :`);
    console.log(`   - Email: ${user.email}`);
    console.log(`   - Nom: ${user.first_name} ${user.last_name}`);
    console.log(`   - Rôle: ${user.role}`);
    console.log(`   - Statut: ${user.status}`);

    const readline2 = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const confirm = await new Promise(resolve => {
      readline2.question('\n⚠️  Confirmer la suppression COMPLÈTE ? (oui/non): ', answer => {
        readline2.close();
        resolve(answer.toLowerCase() === 'oui');
      });
    });

    if (!confirm) {
      console.log('❌ Suppression annulée\n');
      return;
    }

    // SUPPRESSION COMPLÈTE
    console.log('\n🗑️  Suppression en cours...\n');
    const result = await deleteCustomerCompletely(customerId);

    if (result.success) {
      console.log(`\n✅ ${result.message}`);
      console.log('\n📊 Éléments supprimés :');
      console.log(JSON.stringify(result.deletedItems, null, 2));
    }

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
    console.error(error.stack);
  }
}

async function testMultipleCustomerDeletion() {
  try {
    console.log('\n🧪 TEST DE SUPPRESSION MULTIPLE\n');
    console.log('⚠️  ATTENTION : Ce test supprime réellement des données !\n');

    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const idsInput = await new Promise(resolve => {
      readline.question('Entrez les IDs des clients à supprimer (séparés par des virgules, ex: 5,7,12): ', answer => {
        readline.close();
        resolve(answer);
      });
    });

    if (!idsInput || idsInput.trim() === '') {
      console.log('❌ Suppression annulée\n');
      return;
    }

    // Parser les IDs
    const customerIds = idsInput.split(',')
      .map(id => parseInt(id.trim()))
      .filter(id => !isNaN(id) && id > 0);

    if (customerIds.length === 0) {
      console.log('❌ Aucun ID valide fourni\n');
      return;
    }

    console.log(`\n📋 ${customerIds.length} client(s) à supprimer: ${customerIds.join(', ')}\n`);

    // Vérifier que tous les clients existent
    const users = await User.findAll({
      where: { id: customerIds }
    });

    if (users.length === 0) {
      console.log('❌ Aucun client trouvé avec ces IDs\n');
      return;
    }

    if (users.length < customerIds.length) {
      console.log(`⚠️  Attention: Seulement ${users.length}/${customerIds.length} clients trouvés\n`);
    }

    console.log('Clients trouvés:');
    users.forEach(user => {
      console.log(`   - [ID ${user.id}] ${user.first_name} ${user.last_name} (${user.email})`);
    });

    const readline2 = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const confirm = await new Promise(resolve => {
      readline2.question(`\n⚠️  Confirmer la suppression de ${users.length} client(s) ? (oui/non): `, answer => {
        readline2.close();
        resolve(answer.toLowerCase() === 'oui');
      });
    });

    if (!confirm) {
      console.log('❌ Suppression annulée\n');
      return;
    }

    // SUPPRESSION MULTIPLE
    console.log('\n🗑️  Suppression en cours...\n');
    
    let successCount = 0;
    let failCount = 0;
    const results = [];

    for (const user of users) {
      try {
        const result = await deleteCustomerCompletely(user.id);
        if (result.success) {
          successCount++;
          results.push({ id: user.id, email: user.email, success: true, deletedItems: result.deletedItems });
          console.log(`✅ Client ${user.id} (${user.email}) supprimé`);
        } else {
          failCount++;
          results.push({ id: user.id, email: user.email, success: false, error: result.message });
          console.log(`❌ Échec pour client ${user.id}: ${result.message}`);
        }
      } catch (error) {
        failCount++;
        results.push({ id: user.id, email: user.email, success: false, error: error.message });
        console.log(`❌ Erreur pour client ${user.id}: ${error.message}`);
      }
    }

    console.log('\n📊 RÉSULTAT FINAL:');
    console.log(`   ✅ Réussis: ${successCount}`);
    console.log(`   ❌ Échecs: ${failCount}`);
    console.log(`   📝 Total: ${users.length}\n`);

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
    console.error(error.stack);
  }
}

async function testSoftDelete() {
  try {
    console.log('\n🧪 TEST DE DÉSACTIVATION CLIENT (SOFT DELETE)\n');

    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const customerId = await new Promise(resolve => {
      readline.question('Entrez l\'ID du client à désactiver (ou 0 pour annuler): ', answer => {
        readline.close();
        resolve(parseInt(answer));
      });
    });

    if (!customerId || customerId === 0) {
      console.log('❌ Désactivation annulée\n');
      return;
    }

    // SOFT DELETE
    console.log('\n⏸️  Désactivation en cours...\n');
    const result = await softDeleteCustomer(customerId);

    if (result.success) {
      console.log(`\n✅ ${result.message}`);
      console.log(`   - Email modifié: ${result.user.email}`);
      console.log(`   - Statut: ${result.user.status}\n`);
    }

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
  }
}

// Menu principal avec boucle
async function showMenu() {
  return new Promise((resolve) => {
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    console.log('\n╔════════════════════════════════════════╗');
    console.log('║  TEST SUPPRESSION CLIENT              ║');
    console.log('╚════════════════════════════════════════╝\n');
    console.log('1. Lister tous les clients');
    console.log('2. Suppression COMPLÈTE (hard delete)');
    console.log('3. Suppression MULTIPLE (hard delete)');
    console.log('4. Désactivation (soft delete)');
    console.log('0. Quitter\n');

    readline.question('Choisissez une option: ', (choice) => {
      readline.close();
      resolve(choice);
    });
  });
}

async function main() {
  let continuer = true;

  while (continuer) {
    const choice = await showMenu();

    switch (choice) {
      case '1':
        await listAllCustomers();
        break;
      case '2':
        await testCustomerDeletion();
        break;
      case '3':
        await testMultipleCustomerDeletion();
        break;
      case '4':
        await testSoftDelete();
        break;
      case '0':
        console.log('\n👋 Au revoir!\n');
        continuer = false;
        break;
      default:
        console.log('❌ Option invalide\n');
    }
  }

  process.exit(0);
}

// Lancer le menu principal
main().catch(error => {
  console.error('❌ Erreur fatale:', error.message);
  process.exit(1);
});
