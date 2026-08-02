'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('payment_webhook_events', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      provider: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      provider_reference: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      sync_ref: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      payload_hash: {
        type: Sequelize.STRING(64),
        allowNull: false
      },
      status: {
        type: Sequelize.STRING(20),
        allowNull: false,
        defaultValue: 'processing'
      },
      attempt_count: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1
      },
      processing_started_at: {
        type: Sequelize.DATE,
        allowNull: false
      },
      processed_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      last_error: {
        type: Sequelize.TEXT,
        allowNull: true
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

    await queryInterface.addIndex(
      'payment_webhook_events',
      ['provider', 'provider_reference'],
      {
        name: 'payment_webhook_events_provider_reference_unique',
        unique: true
      }
    );
    await queryInterface.addIndex('payment_webhook_events', ['status'], {
      name: 'payment_webhook_events_status_idx'
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('payment_webhook_events');
  }
};
