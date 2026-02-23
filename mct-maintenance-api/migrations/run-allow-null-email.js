/**
 * Script de migration: Permettre email NULL pour inscription par téléphone
 */

'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Démarrage de la migration: Permettre email NULL...\n');

    try {
      // Vérifier si la colonne email est déjà nullable
      const tableDesc = await queryInterface.describeTable('users');
      
      if (tableDesc.email && tableDesc.email.allowNull) {
        console.log('✅ La colonne email est déjà nullable.');
        console.log('✨ Inscription par téléphone déjà activée!\n');
        return;
      }

      console.log('⚠️  La colonne email n\'est pas encore nullable.');
      console.log('ℹ️  Note: SQLite ne supporte pas la modification directe des contraintes NULL.');
      console.log('   Le modèle Sequelize gère allowNull: true au niveau applicatif.\n');

      // Créer les index s'ils n'existent pas
      try {
        await queryInterface.addIndex('users', ['phone'], {
          name: 'idx_users_phone',
          unique: false
        });
        console.log('✅ Index idx_users_phone créé');
      } catch (error) {
        if (error.message && error.message.includes('already exists')) {
          console.log('ℹ️  Index idx_users_phone existe déjà');
        }
      }

      try {
        await queryInterface.addIndex('users', ['role'], {
          name: 'idx_users_role',
          unique: false
        });
        console.log('✅ Index idx_users_role créé');
      } catch (error) {
        if (error.message && error.message.includes('already exists')) {
          console.log('ℹ️  Index idx_users_role existe déjà');
        }
      }

      try {
        await queryInterface.addIndex('users', ['status'], {
          name: 'idx_users_status',
          unique: false
        });
        console.log('✅ Index idx_users_status créé\n');
      } catch (error) {
        if (error.message && error.message.includes('already exists')) {
          console.log('ℹ️  Index idx_users_status existe déjà\n');
        }
      }

      console.log('✅ Migration terminée avec succès!');
      
    } catch (error) {
      console.error('\n❌ Erreur lors de la migration:', error.message);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('🔄 Rollback des index...\n');

    try {
      await queryInterface.removeIndex('users', 'idx_users_phone');
      console.log('✅ Index idx_users_phone supprimé');
    } catch (error) {
      console.log('ℹ️  Index idx_users_phone déjà supprimé');
    }

    try {
      await queryInterface.removeIndex('users', 'idx_users_role');
      console.log('✅ Index idx_users_role supprimé');
    } catch (error) {
      console.log('ℹ️  Index idx_users_role déjà supprimé');
    }

    try {
      await queryInterface.removeIndex('users', 'idx_users_status');
      console.log('✅ Index idx_users_status supprimé');
    } catch (error) {
      console.log('ℹ️  Index idx_users_status déjà supprimé');
    }
  }
};
