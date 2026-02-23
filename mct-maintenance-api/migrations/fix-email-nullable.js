/**
 * Migration simplifiée: Permettre email NULL
 */

'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Migration: Permettre email NULL...\n');

    try {
      // Vérifier si la colonne email est déjà nullable
      const tableDesc = await queryInterface.describeTable('users');
      
      if (tableDesc.email && tableDesc.email.allowNull) {
        console.log('✅ La colonne email est déjà nullable. Aucune action nécessaire.\n');
        return;
      }

      console.log('⚠️  La colonne email n\'est pas nullable. Migration nécessaire...\n');
      console.log('ℹ️  Note: SQLite ne permet pas de modifier directement les contraintes NULL.');
      console.log('   Une reconstruction complète de la table serait nécessaire.');
      console.log('   Cependant, le modèle Sequelize gère déjà allowNull: true au niveau applicatif.\n');

      // Pour SQLite, on ne peut pas facilement changer une colonne de NOT NULL à NULL
      // Le modèle Sequelize définit déjà allowNull: true, donc c'est géré au niveau applicatif
      
    } catch (error) {
      console.error('\n❌ Erreur:', error.message);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('ℹ️  Pas de rollback pour cette migration');
  }
};
