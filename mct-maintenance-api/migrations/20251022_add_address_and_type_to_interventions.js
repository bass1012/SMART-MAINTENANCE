// Migration pour ajouter les colonnes address et intervention_type à la table interventions

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('interventions', 'address', {
      type: Sequelize.STRING,
      allowNull: true,
      after: 'description'
    });

    await queryInterface.addColumn('interventions', 'intervention_type', {
      type: Sequelize.STRING,
      allowNull: true,
      after: 'priority'
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('interventions', 'address');
    await queryInterface.removeColumn('interventions', 'intervention_type');
  }
};
