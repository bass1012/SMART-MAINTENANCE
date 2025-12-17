'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'fcm_token', {
      type: Sequelize.STRING(255),
      allowNull: true,
      comment: 'Token FCM pour les notifications push mobiles'
    });

    console.log('✅ Colonne fcm_token ajoutée à la table users');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('users', 'fcm_token');
    console.log('✅ Colonne fcm_token supprimée de la table users');
  }
};
