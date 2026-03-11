/**
 * Migration: Add equipment_count to subscriptions
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('📦 Starting migration: Add equipment_count to subscriptions...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (!tableInfo.equipment_count) {
      await queryInterface.addColumn('subscriptions', 'equipment_count', {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1
      });
      console.log('✅ Added equipment_count column');
    } else {
      console.log('⏭️ equipment_count column already exists');
    }
    
    console.log('✅ Migration completed successfully');
  },

  async down(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('subscriptions');
    if (tableInfo.equipment_count) {
      await queryInterface.removeColumn('subscriptions', 'equipment_count');
      console.log('✅ Removed equipment_count column');
    }
  }
};
