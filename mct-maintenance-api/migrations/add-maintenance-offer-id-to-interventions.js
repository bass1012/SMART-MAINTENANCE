'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Ajout de la colonne maintenance_offer_id à la table interventions...');

    try {
      // Vérifier si la colonne existe déjà
      const tableDesc = await queryInterface.describeTable('interventions');
      
      if (!tableDesc.maintenance_offer_id) {
        // Ajouter la colonne maintenance_offer_id (sans FK pour SQLite)
        await queryInterface.addColumn('interventions', 'maintenance_offer_id', {
          type: Sequelize.INTEGER,
          allowNull: true,
          references: {
            model: 'maintenance_offers',
            key: 'id'
          }
        });
        console.log('✅ Colonne maintenance_offer_id ajoutée');
      } else {
        console.log('✅ La colonne maintenance_offer_id existe déjà');
      }

      // Créer un index pour améliorer les performances
      try {
        await queryInterface.addIndex('interventions', ['maintenance_offer_id'], {
          name: 'idx_interventions_maintenance_offer_id',
          unique: false
        });
        console.log('✅ Index créé sur maintenance_offer_id');
      } catch (error) {
        if (error.message && error.message.includes('already exists')) {
          console.log('ℹ️  Index idx_interventions_maintenance_offer_id existe déjà');
        } else {
          throw error;
        }
      }

      console.log('✅ Migration terminée avec succès');
    } catch (error) {
      console.error('❌ Erreur lors de la migration:', error);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('🔄 Rollback de la colonne maintenance_offer_id...');

    try {
      const tableDesc = await queryInterface.describeTable('interventions');
      
      if (tableDesc.maintenance_offer_id) {
        // Supprimer l'index d'abord
        try {
          await queryInterface.removeIndex('interventions', 'idx_interventions_maintenance_offer_id');
          console.log('✅ Index supprimé');
        } catch (error) {
          console.log('ℹ️  Index déjà supprimé ou inexistant');
        }

        // Supprimer la colonne
        await queryInterface.removeColumn('interventions', 'maintenance_offer_id');
        console.log('✅ Colonne maintenance_offer_id supprimée');
      }
    } catch (error) {
      console.error('❌ Erreur lors du rollback:', error);
      throw error;
    }
  }
};
