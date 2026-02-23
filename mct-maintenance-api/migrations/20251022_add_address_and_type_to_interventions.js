// Migration pour ajouter les colonnes address et intervention_type à la table interventions

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableDesc = await queryInterface.describeTable('interventions');
    
    // Ajouter address seulement si elle n'existe pas
    if (!tableDesc.address) {
      await queryInterface.addColumn('interventions', 'address', {
        type: Sequelize.STRING,
        allowNull: true
      });
      console.log('✅ Column "address" added to interventions');
    } else {
      console.log('⚠️ Column "address" already exists, skipping...');
    }

    // Ajouter intervention_type seulement si elle n'existe pas
    if (!tableDesc.intervention_type) {
      await queryInterface.addColumn('interventions', 'intervention_type', {
        type: Sequelize.STRING,
        allowNull: true
      });
      console.log('✅ Column "intervention_type" added to interventions');
    } else {
      console.log('⚠️ Column "intervention_type" already exists, skipping...');
    }
  },

  down: async (queryInterface, Sequelize) => {
    const tableDesc = await queryInterface.describeTable('interventions');
    
    if (tableDesc.address) {
      await queryInterface.removeColumn('interventions', 'address');
    }
    
    if (tableDesc.intervention_type) {
      await queryInterface.removeColumn('interventions', 'intervention_type');
    }
  }
};
