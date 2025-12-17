const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Complaint extends Model {}

Complaint.init({
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  reference: { 
    type: DataTypes.STRING(50), 
    allowNull: false,
    unique: true 
  },
  customerId: { 
    type: DataTypes.INTEGER, 
    allowNull: false,
    field: 'customer_id'
  },
  orderId: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    field: 'order_id'
  },
  productId: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    field: 'product_id'
  },
  interventionId: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    field: 'intervention_id'
  },
  subject: { 
    type: DataTypes.STRING(255), 
    allowNull: false 
  },
  description: { 
    type: DataTypes.TEXT, 
    allowNull: false 
  },
  status: { 
    type: DataTypes.STRING, // Utiliser STRING au lieu d'ENUM pour SQLite
    allowNull: false,
    defaultValue: 'open' 
  },
  priority: { 
    type: DataTypes.STRING, // Utiliser STRING au lieu d'ENUM pour SQLite
    allowNull: false,
    defaultValue: 'medium' 
  },
  category: { 
    type: DataTypes.STRING(100), 
    allowNull: true 
  },
  resolution: { 
    type: DataTypes.TEXT, 
    allowNull: true 
  },
  resolvedAt: { 
    type: DataTypes.DATE, 
    allowNull: true,
    field: 'resolved_at'
  },
  assignedTo: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    field: 'assigned_to'
  }
}, {
  sequelize,
  modelName: 'Complaint',
  tableName: 'complaints',
  timestamps: true,
  paranoid: true, // Active l'archivage (soft delete)
  underscored: true // Utilise snake_case pour les colonnes
});

// Associations pour inclure les objets liés dans les requêtes
const CustomerProfile = require('./CustomerProfile');
const Product = require('./Product');
const Order = require('./Order');

Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
Complaint.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

module.exports = Complaint;