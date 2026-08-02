'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('outbox_events', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      topic: { type: Sequelize.STRING(100), allowNull: false },
      aggregate_type: { type: Sequelize.STRING(50), allowNull: false },
      aggregate_id: { type: Sequelize.STRING(100), allowNull: false },
      idempotency_key: { type: Sequelize.STRING(255), allowNull: false },
      payload: { type: Sequelize.TEXT, allowNull: false },
      status: { type: Sequelize.STRING(20), allowNull: false, defaultValue: 'pending' },
      attempts: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      available_at: { type: Sequelize.DATE, allowNull: false },
      locked_at: { type: Sequelize.DATE, allowNull: true },
      processed_at: { type: Sequelize.DATE, allowNull: true },
      last_error: { type: Sequelize.TEXT, allowNull: true },
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
    await queryInterface.addIndex('outbox_events', ['idempotency_key'], {
      name: 'outbox_events_idempotency_key_uq',
      unique: true
    });
    await queryInterface.addIndex('outbox_events', ['status', 'available_at'], {
      name: 'outbox_events_dispatch_idx'
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('outbox_events');
  }
};
