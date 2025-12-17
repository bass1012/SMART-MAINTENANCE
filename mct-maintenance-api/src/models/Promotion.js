const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Promotion extends Model {}

Promotion.init({
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  code: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  type: {
    type: DataTypes.STRING, // 'percentage' ou 'fixed'
    allowNull: false
  },
  value: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    field: 'start_date'
  },
  endDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    field: 'end_date'
  },
  usageLimit: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'usage_limit'
  },
  usageCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'usage_count'
  },
  target: {
    type: DataTypes.STRING, // 'customers', 'products', 'all'
    allowNull: false,
    defaultValue: 'all'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'is_active'
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  sequelize,
  modelName: 'Promotion',
  tableName: 'promotions',
  timestamps: true,
  paranoid: false,
  underscored: false,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

// Surcharger toJSON pour retourner les données en snake_case
Promotion.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  return {
    id: values.id,
    name: values.name,
    code: values.code,
    type: values.type,
    value: values.value,
    start_date: values.startDate,
    end_date: values.endDate,
    usage_limit: values.usageLimit,
    used_count: values.usageCount,
    target: values.target,
    status: values.isActive ? 'active' : 'inactive',
    description: values.description,
    created_at: values.created_at,
    updated_at: values.updated_at
  };
};

module.exports = Promotion;
