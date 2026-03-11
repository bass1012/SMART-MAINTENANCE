/**
 * Migration: Add equipment_used to subscriptions
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('📦 Ajout de la colonne equipment_used à la table subscriptions...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (!tableInfo.equipment_used) {
      await queryInterface.addColumn('subscriptions', 'equipment_used', {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      });
      console.log('✅ Colonne equipment_used ajoutée');
    } else {
      console.log('⏭️ equipment_used existe déjà');
    }
    
    console.log('✅ Migration terminée');
  },

  async down(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('subscriptions');
    if (tableInfo.equipment_used) {
      await queryInterface.removeColumn('subscriptions', 'equipment_used');
    }
  }
};
