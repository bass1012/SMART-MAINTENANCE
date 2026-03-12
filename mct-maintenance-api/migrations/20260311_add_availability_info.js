'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const installationColumns = await queryInterface.describeTable('installation_services');
    
    if (!installationColumns.availability_info) {
      await queryInterface.addColumn('installation_services', 'availability_info', {
        type: Sequelize.STRING(255),
        allowNull: true,
        defaultValue: 'Tous les jours et week-ends jusqu\'à 17h',
        comment: 'Informations de disponibilité du service'
      });
    }
  },

  down: async (queryInterface, Sequelize) => {
    const installationColumns = await queryInterface.describeTable('installation_services');
    
    if (installationColumns.availability_info) {
      await queryInterface.removeColumn('installation_services', 'availability_info');
    }
  }
};
