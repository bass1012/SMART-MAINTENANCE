const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class OutboxEvent extends Model {}

OutboxEvent.init({
  topic: { type: DataTypes.STRING(100), allowNull: false },
  aggregateType: {
    type: DataTypes.STRING(50),
    allowNull: false,
    field: 'aggregate_type'
  },
  aggregateId: {
    type: DataTypes.STRING(100),
    allowNull: false,
    field: 'aggregate_id'
  },
  idempotencyKey: {
    type: DataTypes.STRING(255),
    allowNull: false,
    field: 'idempotency_key'
  },
  payload: {
    type: DataTypes.TEXT,
    allowNull: false,
    get() {
      const value = this.getDataValue('payload');
      return value ? JSON.parse(value) : null;
    },
    set(value) {
      this.setDataValue('payload', JSON.stringify(value));
    }
  },
  status: {
    type: DataTypes.STRING(20),
    allowNull: false,
    defaultValue: 'pending',
    validate: { isIn: [['pending', 'processing', 'completed', 'dead']] }
  },
  attempts: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
  availableAt: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'available_at'
  },
  lockedAt: { type: DataTypes.DATE, allowNull: true, field: 'locked_at' },
  processedAt: { type: DataTypes.DATE, allowNull: true, field: 'processed_at' },
  lastError: { type: DataTypes.TEXT, allowNull: true, field: 'last_error' }
}, {
  sequelize,
  modelName: 'OutboxEvent',
  tableName: 'outbox_events',
  underscored: true,
  timestamps: true,
  paranoid: false,
  indexes: [
    {
      name: 'outbox_events_idempotency_key_uq',
      unique: true,
      fields: ['idempotency_key']
    },
    {
      name: 'outbox_events_dispatch_idx',
      fields: ['status', 'available_at']
    }
  ]
});

module.exports = OutboxEvent;
