'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('📝 Adding repair_service_id to interventions table...');
    
    const tableDesc = await queryInterface.describeTable('interventions');
    
    if (!tableDesc.repair_service_id) {
      await queryInterface.addColumn('interventions', 'repair_service_id', {
        type: Sequelize.INTEGER,
        allowNull: true
      });
      console.log('✅ repair_service_id column added to interventions');
    } else {
      console.log('⚠️ repair_service_id already exists in interventions');
    }
  },

  async down(queryInterface, Sequelize) {
    const tableDesc = await queryInterface.describeTable('interventions');
    
    if (tableDesc.repair_service_id) {
      await queryInterface.removeColumn('interventions', 'repair_service_id');
      console.log('✅ repair_service_id column removed from interventions');
    }
  }
};
