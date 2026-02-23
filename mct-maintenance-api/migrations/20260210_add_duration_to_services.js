'use strict';

const { DataTypes } = require('sequelize');

module.exports = {
  async up(queryInterface, Sequelize) {
    const installationColumns = await queryInterface.describeTable('installation_services');
    const repairColumns = await queryInterface.describeTable('repair_services');
    
    if (!installationColumns.duration) {
      await queryInterface.addColumn('installation_services', 'duration', {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: 'Durée estimée en heures'
      });
    }
    
    if (!repairColumns.duration) {
      await queryInterface.addColumn('repair_services', 'duration', {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: 'Durée estimée en heures'
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const installationColumns = await queryInterface.describeTable('installation_services');
    const repairColumns = await queryInterface.describeTable('repair_services');
    
    if (installationColumns.duration) {
      await queryInterface.removeColumn('installation_services', 'duration');
    }
    
    if (repairColumns.duration) {
      await queryInterface.removeColumn('repair_services', 'duration');
    }
  }
};
