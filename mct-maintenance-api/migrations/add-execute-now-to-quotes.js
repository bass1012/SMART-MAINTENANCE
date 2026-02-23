'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Vérifier si la colonne existe déjà
    const tableInfo = await queryInterface.describeTable('quotes');
    
    if (!tableInfo.execute_now) {
      await queryInterface.addColumn('quotes', 'execute_now', {
        type: Sequelize.BOOLEAN,
        allowNull: true,
        defaultValue: false
      });
      console.log('✅ Colonne execute_now ajoutée à la table quotes');
    } else {
      console.log('ℹ️  Colonne execute_now existe déjà');
    }
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('quotes', 'execute_now');
  }
};
