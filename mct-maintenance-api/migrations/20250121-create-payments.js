'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('payments', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      order_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'orders',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT'
      },
      amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
      },
      currency: {
        type: Sequelize.STRING(3),
        defaultValue: 'XOF'
      },
      provider: {
        type: Sequelize.ENUM('stripe', 'wave', 'orange_money', 'mtn_money', 'moov_money', 'cash'),
        allowNull: false
      },
      payment_id: {
        type: Sequelize.STRING
      },
      status: {
        type: Sequelize.ENUM('pending', 'processing', 'succeeded', 'failed', 'refunded', 'cancelled'),
        defaultValue: 'pending'
      },
      payment_method: {
        type: Sequelize.STRING
      },
      phone_number: {
        type: Sequelize.STRING
      },
      transaction_id: {
        type: Sequelize.STRING
      },
      checkout_url: {
        type: Sequelize.TEXT
      },
      metadata: {
        type: Sequelize.JSON
      },
      error_message: {
        type: Sequelize.TEXT
      },
      paid_at: {
        type: Sequelize.DATE
      },
      refunded_at: {
        type: Sequelize.DATE
      },
      refund_amount: {
        type: Sequelize.DECIMAL(10, 2)
      },
      refund_reason: {
        type: Sequelize.TEXT
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Ajouter les index
    await queryInterface.addIndex('payments', ['order_id']);
    await queryInterface.addIndex('payments', ['payment_id']);
    await queryInterface.addIndex('payments', ['status']);
    await queryInterface.addIndex('payments', ['provider']);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('payments');
  }
};
