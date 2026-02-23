'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Début de la migration add_climatiseur_type...');
    
    try {
      // Vérifier si la colonne existe déjà
      const tableDesc = await queryInterface.describeTable('interventions');
      
      if (!tableDesc.climatiseur_type) {
        // Ajouter la colonne climatiseur_type
        await queryInterface.addColumn('interventions', 'climatiseur_type', {
          type: Sequelize.STRING(50),
          allowNull: true
        });
        console.log('✅ Colonne climatiseur_type ajoutée avec succès');
        console.log('   Types possibles: Mural, Allège, K7, Gainable, Armoire');
      } else {
        console.log('ℹ️  La colonne climatiseur_type existe déjà');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la migration:', error.message);
      throw error;
    }
    
    console.log('✅ Migration terminée');
  },

  down: async (queryInterface, Sequelize) => {
    console.log('🔄 Rollback de la migration add_climatiseur_type...');
    
    try {
      const tableDesc = await queryInterface.describeTable('interventions');
      
      if (tableDesc.climatiseur_type) {
        await queryInterface.removeColumn('interventions', 'climatiseur_type');
        console.log('✅ Colonne climatiseur_type supprimée');
      }
    } catch (error) {
      console.error('❌ Erreur lors du rollback:', error.message);
      throw error;
    }
  }
};
