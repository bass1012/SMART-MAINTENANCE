const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Product = sequelize.define('Product', {
  nom: {
    type: DataTypes.STRING,
    allowNull: false
  },
  reference: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  prix: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  base_price: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0,
    comment: 'Prix de base de l équipement sans offre'
  },
  quantite_stock: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  seuil_alerte: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  marque_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  categorie_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  actif: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true
  },
  offer_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    defaultValue: null,
    comment: 'ID de l offre de maintenance associée à ce produit'
  },
  images: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: []
  },
  specifications: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: {}
  }
}, {
  tableName: 'products',
  timestamps: true,
  paranoid: true,
  underscored: true
});

module.exports = Product;
