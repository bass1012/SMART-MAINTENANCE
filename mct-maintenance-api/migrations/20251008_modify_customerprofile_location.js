"use strict";

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableName = "customer_profiles";
    try {
      const table = await queryInterface.describeTable(tableName);
      // Remove postal_code if exists
      if (table.postal_code) {
        await queryInterface.removeColumn(tableName, "postal_code");
      }
      // Add commune if missing
      if (!table.commune) {
        await queryInterface.addColumn(tableName, "commune", {
          type: Sequelize.STRING(100),
          allowNull: true,
        });
      }
      // Add latitude if missing
      if (!table.latitude) {
        await queryInterface.addColumn(tableName, "latitude", {
          type: Sequelize.DECIMAL(10, 7),
          allowNull: true,
        });
      }
      // Add longitude if missing
      if (!table.longitude) {
        await queryInterface.addColumn(tableName, "longitude", {
          type: Sequelize.DECIMAL(10, 7),
          allowNull: true,
        });
      }
    } catch (err) {
      // Table does not exist; skip gracefully in clean setups
      console.warn(`Skipping ${tableName} location modifications: table not found.`);
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableName = "customer_profiles";
    try {
      const table = await queryInterface.describeTable(tableName);
      // Add back postal_code if missing
      if (!table.postal_code) {
        await queryInterface.addColumn(tableName, "postal_code", {
          type: Sequelize.STRING(20),
          allowNull: true,
        });
      }
      // Remove commune if exists
      if (table.commune) {
        await queryInterface.removeColumn(tableName, "commune");
      }
      // Remove latitude if exists
      if (table.latitude) {
        await queryInterface.removeColumn(tableName, "latitude");
      }
      // Remove longitude if exists
      if (table.longitude) {
        await queryInterface.removeColumn(tableName, "longitude");
      }
    } catch (err) {
      console.warn(`Skipping rollback for ${tableName} location modifications: table not found.`);
    }
  },
};
