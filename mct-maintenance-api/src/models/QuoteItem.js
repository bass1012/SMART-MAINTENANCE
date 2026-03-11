const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class QuoteItem extends Model {}

QuoteItem.init({
  quoteId: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'quotes', key: 'id' }, field: 'quoteId' },
  productId: { type: DataTypes.INTEGER, allowNull: false, field: 'productId' },
  productName: { type: DataTypes.STRING, field: 'productName' },
  quantity: { type: DataTypes.INTEGER, allowNull: false },
  unitPrice: { type: DataTypes.FLOAT, allowNull: false, field: 'unitPrice' },
  discount: { type: DataTypes.FLOAT, defaultValue: 0 },
  taxRate: { type: DataTypes.FLOAT, defaultValue: 0, field: 'taxRate' },
  isCustom: { type: DataTypes.BOOLEAN, defaultValue: false, field: 'is_custom' }
}, {
  sequelize,
  modelName: 'QuoteItem',
  tableName: 'quote_items',
  timestamps: true,
  paranoid: false,
  underscored: false,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = QuoteItem;
