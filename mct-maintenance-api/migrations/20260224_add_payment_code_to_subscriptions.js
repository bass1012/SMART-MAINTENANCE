'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Vérifier si la colonne existe déjà
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    if (!tableInfo.payment_code) {
      await queryInterface.addColumn('subscriptions', 'payment_code', {
        type: Sequelize.STRING(10),
        allowNull: true,
        unique: true
      });
      console.log('✅ Migration: Colonne payment_code ajoutée à la table subscriptions');
    } else {
      console.log('⏭️ Migration: Colonne payment_code existe déjà');
    }
  },

  async down(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('subscriptions');
    if (tableInfo.payment_code) {
      await queryInterface.removeColumn('subscriptions', 'payment_code');
      console.log('✅ Migration rollback: Colonne payment_code supprimée');
    }
  }
};
