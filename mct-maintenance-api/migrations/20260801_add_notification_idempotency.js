'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('notifications', 'dedupe_key', {
      type: Sequelize.STRING(191),
      allowNull: true
    });
    await queryInterface.addIndex('notifications', ['user_id', 'dedupe_key'], {
      name: 'notifications_user_dedupe_key_uq',
      unique: true
    });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('notifications', 'notifications_user_dedupe_key_uq');
    await queryInterface.removeColumn('notifications', 'dedupe_key');
  }
};
