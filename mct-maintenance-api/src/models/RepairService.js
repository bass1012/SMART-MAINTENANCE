const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const RepairService = sequelize.define('RepairService', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Titre du service (ex: Fuite de Gaz, Dépannage Urgent)'
  },
  model: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Modèle ou type (ex: R410A, R32, R22)'
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    comment: 'Prix en FCFA'
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Description détaillée du service'
  },
  duration: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'Durée du contrat en mois'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    comment: 'Service actif ou non'
  }
}, {
  tableName: 'repair_services',
  timestamps: true,
  underscored: true,
  paranoid: false
});

module.exports = RepairService;
