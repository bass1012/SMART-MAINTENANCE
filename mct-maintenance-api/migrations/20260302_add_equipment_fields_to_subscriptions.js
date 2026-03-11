'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (!tableInfo.equipment_description) {
      await queryInterface.addColumn('subscriptions', 'equipment_description', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: 'Description de l\'équipement (ex: mural 1 cv)'
      });
      console.log('✅ Colonne equipment_description ajoutée à subscriptions');
    } else {
      console.log('⏭️ Colonne equipment_description existe déjà');
    }

    if (!tableInfo.equipment_model) {
      await queryInterface.addColumn('subscriptions', 'equipment_model', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: 'Marque de l\'équipement (LG, Carrier, etc.)'
      });
      console.log('✅ Colonne equipment_model ajoutée à subscriptions');
    } else {
      console.log('⏭️ Colonne equipment_model existe déjà');
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (tableInfo.equipment_description) {
      await queryInterface.removeColumn('subscriptions', 'equipment_description');
    }
    if (tableInfo.equipment_model) {
      await queryInterface.removeColumn('subscriptions', 'equipment_model');
    }
  }
};
