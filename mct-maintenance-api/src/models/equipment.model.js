const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Equipment = sequelize.define('Equipment', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Type d\'équipement (Climatiseur, Réfrigérateur, etc.)'
  },
  brand: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Marque de l\'équipement'
  },
  model: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Modèle de l\'équipement'
  },
  serial_number: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
    comment: 'Numéro de série unique'
  },
  location: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Emplacement de l\'équipement'
  },
  installation_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date d\'installation'
  },
  purchase_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date d\'achat'
  },
  warranty_end_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date de fin de garantie'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Notes additionnelles'
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'maintenance', 'retired'),
    defaultValue: 'active',
    comment: 'Statut de l\'équipement'
  },
  deleted_at: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'equipments',
  timestamps: true,
  underscored: true,
  paranoid: false,
  indexes: [
    {
      fields: ['customer_id']
    },
    {
      fields: ['serial_number']
    },
    {
      fields: ['status']
    }
  ]
});

module.exports = Equipment;
