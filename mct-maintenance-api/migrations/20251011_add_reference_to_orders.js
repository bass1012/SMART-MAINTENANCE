// Migration pour ajouter la colonne 'reference' à la table 'orders'
'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    try {
      const table = await queryInterface.describeTable('orders');
      if (!table.reference) {
        await queryInterface.addColumn('orders', 'reference', {
          type: Sequelize.STRING,
          allowNull: true,
          unique: false
        });
      }
    } catch (err) {
      console.warn('Skipping add reference to orders: table not found.');
    }
  },

  down: async (queryInterface, Sequelize) => {
    try {
      const table = await queryInterface.describeTable('orders');
      if (table.reference) {
        await queryInterface.removeColumn('orders', 'reference');
      }
    } catch (err) {
      console.warn('Skipping remove reference from orders: table not found.');
    }
  }
};
