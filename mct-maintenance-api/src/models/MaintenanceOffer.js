const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class MaintenanceOffer extends Model {}

MaintenanceOffer.init({
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  duration: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Durée en mois'
  },
  features: {
    type: DataTypes.TEXT,
    allowNull: true,
    get() {
      const rawValue = this.getDataValue('features');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('features', JSON.stringify(value));
    },
    comment: 'JSON array des fonctionnalités incluses'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
    field: 'is_active'
  }
}, {
  sequelize,
  modelName: 'MaintenanceOffer',
  tableName: 'maintenance_offers',
  timestamps: true,
  paranoid: true,
  underscored: true
});

module.exports = MaintenanceOffer;
