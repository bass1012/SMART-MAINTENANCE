const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Contract = sequelize.define('Contract', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  reference: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: true // Rendu nullable car généré automatiquement via référence
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  type: {
    type: DataTypes.ENUM('maintenance', 'support', 'warranty', 'service'),
    allowNull: false,
    defaultValue: 'maintenance'
  },
  status: {
    type: DataTypes.ENUM('draft', 'active', 'expired', 'terminated', 'pending'),
    allowNull: false,
    defaultValue: 'draft'
  },
  start_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  end_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    defaultValue: 0
  },
  payment_frequency: {
    type: DataTypes.ENUM('monthly', 'quarterly', 'yearly', 'one_time'),
    allowNull: false,
    defaultValue: 'yearly'
  },
  terms_and_conditions: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'contracts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  paranoid: false
});

module.exports = Contract;
