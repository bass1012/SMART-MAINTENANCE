/**
 * Script pour purger tous les clients avec email "deleted_"
 * Usage: node purge-all-deleted.js
 */

const { User, CustomerProfile } = require('./src/models');
const { deleteCustomerCompletely } = require('./src/services/customerDeletionService');
const { Op } = require('sequelize');

const purgeAllDeleted = async () => {
  try {
    console.log('🔍 Recherche des clients "deleted_"...\n');

    // Debug: afficher le chemin de la base de données
    const dbPath = User.sequelize.options.storage;
    console.log(`📁 Base de données: ${dbPath}\n`);

    // Trouver tous les utilisateurs avec email commençant par "deleted_"
    const deletedUsers = await User.findAll({
      where: {
        email: {
          [Op.startsWith]: 'deleted_'
        }
      },
      attributes: ['id', 'email', 'first_name', 'last_name'],
      order: [['id', 'ASC']]
    });

    console.log(`🔎 Requête SQL exécutée avec Op.startsWith: 'deleted_'`);
    console.log(`📊 Résultats trouvés: ${deletedUsers.length}\n`);

    if (deletedUsers.length === 0) {
      console.log('✅ Aucun client "deleted_" trouvé!\n');
      process.exit(0);
    }

    console.log(`🗑️  ${deletedUsers.length} client(s) "deleted_" trouvé(s):\n`);
    deletedUsers.forEach((user, index) => {
      console.log(`  ${index + 1}. [ID ${user.id}] ${user.first_name} ${user.last_name} - ${user.email}`);
    });
    console.log('');

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // Supprimer chaque client
    for (const user of deletedUsers) {
      try {
        console.log(`\n🗑️  Suppression de [ID ${user.id}] ${user.email}...`);
        await deleteCustomerCompletely(user.id);
        successCount++;
        console.log(`✅ Client ${user.id} supprimé avec succès`);
      } catch (error) {
        errorCount++;
        console.error(`❌ Erreur pour client ${user.id}: ${error.message}`);
        errors.push({
          userId: user.id,
          email: user.email,
          error: error.message
        });
      }
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 RÉSUMÉ DE LA PURGE');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Réussis: ${successCount}`);
    console.log(`❌ Échecs: ${errorCount}`);
    console.log(`📝 Total: ${deletedUsers.length}`);

    if (errors.length > 0) {
      console.log('\n❌ ERREURS:');
      errors.forEach((err, index) => {
        console.log(`  ${index + 1}. [User ${err.userId}] ${err.email}: ${err.error}`);
      });
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    process.exit(errorCount > 0 ? 1 : 0);

  } catch (error) {
    console.error('\n❌ Erreur fatale:', error);
    process.exit(1);
  }
};

// Exécuter le script
purgeAllDeleted();
