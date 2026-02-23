const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Subscription extends Model {}

Subscription.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'customer_id'
  },
  maintenance_offer_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'maintenance_offer_id'
  },
  installation_service_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'installation_service_id'
  },
  repair_service_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'repair_service_id'
  },
  split_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'split_id'
  },
  status: {
    type: DataTypes.ENUM('active', 'expired', 'cancelled'),
    defaultValue: 'active'
  },
  start_date: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'start_date'
  },
  end_date: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'end_date'
  },
  price: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  payment_status: {
    type: DataTypes.ENUM('pending', 'paid', 'failed'),
    defaultValue: 'pending',
    field: 'payment_status'
  }
}, {
  sequelize,
  modelName: 'Subscription',
  tableName: 'subscriptions',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at',
  paranoid: true
});

module.exports = Subscription;
