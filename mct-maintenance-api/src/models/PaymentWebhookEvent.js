const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class PaymentWebhookEvent extends Model {}

PaymentWebhookEvent.init({
  provider: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  providerReference: {
    type: DataTypes.STRING(255),
    allowNull: false,
    field: 'provider_reference'
  },
  syncRef: {
    type: DataTypes.STRING(255),
    allowNull: false,
    field: 'sync_ref'
  },
  payloadHash: {
    type: DataTypes.STRING(64),
    allowNull: false,
    field: 'payload_hash'
  },
  status: {
    type: DataTypes.STRING(20),
    allowNull: false,
    defaultValue: 'processing',
    validate: {
      isIn: [['processing', 'completed', 'failed']]
    }
  },
  attemptCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    field: 'attempt_count'
  },
  processingStartedAt: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'processing_started_at'
  },
  processedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'processed_at'
  },
  lastError: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'last_error'
  }
}, {
  sequelize,
  modelName: 'PaymentWebhookEvent',
  tableName: 'payment_webhook_events',
  underscored: true,
  timestamps: true,
  indexes: [
    {
      name: 'payment_webhook_events_provider_reference_unique',
      unique: true,
      fields: ['provider', 'provider_reference']
    },
    {
      name: 'payment_webhook_events_status_idx',
      fields: ['status']
    }
  ]
});

module.exports = PaymentWebhookEvent;
