'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Ajout des colonnes rating et review à la table interventions...');

    try {
      // Vérifier si les colonnes existent déjà
      const tableDesc = await queryInterface.describeTable('interventions');

      // Ajouter la colonne rating si elle n'existe pas
      if (!tableDesc.rating) {
        await queryInterface.addColumn('interventions', 'rating', {
          type: Sequelize.INTEGER,
          allowNull: true,
          validate: {
            min: 1,
            max: 5
          }
        });
        console.log('✅ Colonne rating ajoutée');
      } else {
        console.log('ℹ️  Colonne rating existe déjà');
      }

      // Ajouter la colonne review si elle n'existe pas
      if (!tableDesc.review) {
        await queryInterface.addColumn('interventions', 'review', {
          type: Sequelize.TEXT,
          allowNull: true
        });
        console.log('✅ Colonne review ajoutée');
      } else {
        console.log('ℹ️  Colonne review existe déjà');
      }

      console.log('✅ Migration terminée avec succès');
    } catch (error) {
      console.error('❌ Erreur lors de la migration:', error);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('🔄 Rollback des colonnes rating et review...');

    try {
      const tableDesc = await queryInterface.describeTable('interventions');

      if (tableDesc.review) {
        await queryInterface.removeColumn('interventions', 'review');
        console.log('✅ Colonne review supprimée');
      }

      if (tableDesc.rating) {
        await queryInterface.removeColumn('interventions', 'rating');
        console.log('✅ Colonne rating supprimée');
      }
    } catch (error) {
      console.error('❌ Erreur lors du rollback:', error);
      throw error;
    }
  }
};
