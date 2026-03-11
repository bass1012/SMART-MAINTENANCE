/**
 * Migration: Add subscription used fields
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('📦 Starting migration: Add subscription used fields...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (!tableInfo.intervention_id) {
      await queryInterface.addColumn('subscriptions', 'intervention_id', {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'interventions',
          key: 'id'
        },
        onDelete: 'SET NULL'
      });
      console.log('✅ Added intervention_id column');
    } else {
      console.log('⏭️ intervention_id column already exists');
    }
    
    if (!tableInfo.used_at) {
      await queryInterface.addColumn('subscriptions', 'used_at', {
        type: Sequelize.DATE,
        allowNull: true
      });
      console.log('✅ Added used_at column');
    } else {
      console.log('⏭️ used_at column already exists');
    }
    
    console.log('✅ Migration completed successfully');
  },

  async down(queryInterface, Sequelize) {
    console.log('📦 Rolling back migration...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (tableInfo.intervention_id) {
      await queryInterface.removeColumn('subscriptions', 'intervention_id');
    }
    if (tableInfo.used_at) {
      await queryInterface.removeColumn('subscriptions', 'used_at');
    }
    
    console.log('✅ Rollback completed');
  }
};
