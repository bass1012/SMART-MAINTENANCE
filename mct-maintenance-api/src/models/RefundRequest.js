'use strict';

const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const RefundRequest = sequelize.define('RefundRequest', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  intervention_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  order_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  payment_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  amount: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  reason: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('requested', 'approved', 'processed', 'rejected'),
    defaultValue: 'requested',
    allowNull: false
  },
  idempotency_key: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  },
  admin_note: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  processed_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  rejected_at: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'refund_requests',
  timestamps: true,
  underscored: true
});

module.exports = RefundRequest;
