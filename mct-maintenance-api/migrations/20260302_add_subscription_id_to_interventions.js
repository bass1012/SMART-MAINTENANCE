'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableInfo = await queryInterface.describeTable('interventions');
    
    if (!tableInfo.subscription_id) {
      await queryInterface.addColumn('interventions', 'subscription_id', {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'subscriptions',
          key: 'id'
        },
        comment: 'ID de la souscription/contrat pour les visites planifiées'
      });
      console.log('✅ Colonne subscription_id ajoutée à interventions');
    } else {
      console.log('⏭️ Colonne subscription_id existe déjà');
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableInfo = await queryInterface.describeTable('interventions');
    
    if (tableInfo.subscription_id) {
      await queryInterface.removeColumn('interventions', 'subscription_id');
    }
  }
};
