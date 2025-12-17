'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableName = 'customer_profiles';
    try {
      const table = await queryInterface.describeTable(tableName);
      if (!table.city) {
        await queryInterface.addColumn(tableName, 'city', {
          type: Sequelize.STRING(100),
          allowNull: true,
          after: 'country' // ignoré par SQLite
        });
      }
    } catch (err) {
      console.warn(`Skipping add city on ${tableName}: table not found.`);
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableName = 'customer_profiles';
    try {
      const table = await queryInterface.describeTable(tableName);
      if (table.city) {
        await queryInterface.removeColumn(tableName, 'city');
      }
    } catch (err) {
      console.warn(`Skipping remove city on ${tableName}: table not found.`);
    }
  }
};