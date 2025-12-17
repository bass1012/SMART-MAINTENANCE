'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('password_reset_codes', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      code: {
        type: Sequelize.STRING(6),
        allowNull: false
      },
      expires_at: {
        type: Sequelize.DATE,
        allowNull: false
      },
      used: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Add index on user_id and code for faster lookups
    await queryInterface.addIndex('password_reset_codes', ['user_id']);
    await queryInterface.addIndex('password_reset_codes', ['code']);
    await queryInterface.addIndex('password_reset_codes', ['user_id', 'code', 'used']);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('password_reset_codes');
  }
};

