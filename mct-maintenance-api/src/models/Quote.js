const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Quote extends Model {}

Quote.init({
  reference: { type: DataTypes.STRING, allowNull: false, unique: true },
  customerId: { type: DataTypes.INTEGER, allowNull: false, field: 'customerId' },
  customerName: { type: DataTypes.STRING, field: 'customerName' },
  issueDate: { type: DataTypes.DATEONLY, allowNull: false, field: 'issueDate' },
  expiryDate: { type: DataTypes.DATEONLY, allowNull: false, field: 'expiryDate' },
  status: { type: DataTypes.ENUM('draft', 'sent', 'accepted', 'rejected', 'expired', 'converted'), defaultValue: 'draft' },
  subtotal: { type: DataTypes.FLOAT, allowNull: false },
  taxAmount: { type: DataTypes.FLOAT, allowNull: false, field: 'taxAmount' },
  discountAmount: { type: DataTypes.FLOAT, allowNull: false, field: 'discountAmount' },
  total: { type: DataTypes.FLOAT, allowNull: false },
  notes: { type: DataTypes.TEXT },
  termsAndConditions: { type: DataTypes.TEXT, field: 'termsAndConditions' },
  rejection_reason: { type: DataTypes.TEXT, field: 'rejection_reason' }
}, {
  sequelize,
  modelName: 'Quote',
  tableName: 'quotes',
  timestamps: true,
  paranoid: false,
  underscored: false,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Quote;
