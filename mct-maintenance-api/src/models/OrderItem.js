const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class OrderItem extends Model {}

OrderItem.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  order_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'orders', key: 'id' }
  },
  product_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: { model: 'products', key: 'id' }
  },
  product_name: {
    type: DataTypes.STRING,
    allowNull: true
  },
  is_custom: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  unit_price: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  total: {
    type: DataTypes.FLOAT,
    allowNull: false
  }
}, {
  sequelize,
  modelName: 'OrderItem',
  tableName: 'order_items',
  timestamps: false,
  underscored: true,
  freezeTableName: true
});

module.exports = OrderItem;
