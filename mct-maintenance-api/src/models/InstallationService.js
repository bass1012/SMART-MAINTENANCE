const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const InstallationService = sequelize.define('InstallationService', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Titre du service (ex: Climatiseurs, Ventilation)'
  },
  model: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Modèle ou marque (ex: Daikin, Mitsubishi, LG)'
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
  tableName: 'installation_services',
  timestamps: true,
  underscored: true,
  paranoid: false
});

module.exports = InstallationService;
