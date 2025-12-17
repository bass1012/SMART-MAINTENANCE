'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableName = 'customer_profiles';
    try {
      const table = await queryInterface.describeTable(tableName);
      const columnsToRemove = [
        'address', 'city', 'date_of_birth', 'id_card_number', 'id_card_type',
        'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relation', 'notes'
      ];
      for (const col of columnsToRemove) {
        if (table[col]) {
          await queryInterface.removeColumn(tableName, col);
        }
      }
    } catch (err) {
      console.warn(`Skipping removal of unused fields: ${tableName} not found.`);
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableName = 'customer_profiles';
    try {
      const table = await queryInterface.describeTable(tableName);
      const columnsToAdd = {
        address: { type: Sequelize.TEXT, allowNull: true },
        city: { type: Sequelize.STRING(100), allowNull: true },
        date_of_birth: { type: Sequelize.DATEONLY, allowNull: true },
        id_card_number: { type: Sequelize.STRING(50), allowNull: true },
        id_card_type: { type: Sequelize.ENUM('national_id', 'passport', 'driver_license'), allowNull: true },
        emergency_contact_name: { type: Sequelize.STRING(255), allowNull: true },
        emergency_contact_phone: { type: Sequelize.STRING(20), allowNull: true },
        emergency_contact_relation: { type: Sequelize.STRING(100), allowNull: true },
        notes: { type: Sequelize.TEXT, allowNull: true },
      };
      for (const [col, def] of Object.entries(columnsToAdd)) {
        if (!table[col]) {
          await queryInterface.addColumn(tableName, col, def);
        }
      }
    } catch (err) {
      console.warn(`Skipping rollback add unused fields: ${tableName} not found.`);
    }
  }
};