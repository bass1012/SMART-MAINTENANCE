const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Order extends Model {}

Order.init({
  customerId: { type: DataTypes.INTEGER, allowNull: false },
  quoteId: { type: DataTypes.INTEGER, allowNull: true }, // 🆕 Lien vers le devis
  totalAmount: { type: DataTypes.FLOAT, allowNull: false },
  status: { type: DataTypes.ENUM('pending', 'processing', 'completed', 'cancelled'), defaultValue: 'pending' },
  paymentStatus: { type: DataTypes.ENUM('pending', 'paid', 'failed', 'refunded'), defaultValue: 'pending' },
  notes: { type: DataTypes.TEXT },
  shippingAddress: { type: DataTypes.STRING },
  paymentMethod: { type: DataTypes.STRING },
  reference: { type: DataTypes.STRING, allowNull: true },
  trackingUrl: { type: DataTypes.STRING(500), allowNull: true },
  promoCode: { type: DataTypes.STRING, allowNull: true },
  promoDiscount: { type: DataTypes.FLOAT, defaultValue: 0 },
  promoId: { type: DataTypes.INTEGER, allowNull: true },
  // 🔒 Champs sécurité paiement FineoPay
  fineopayCheckoutId: { type: DataTypes.STRING, allowNull: true }, // ID du checkout link FineoPay
  fineopayReference: { type: DataTypes.STRING, allowNull: true },  // Référence transaction FineoPay
  paymentDate: { type: DataTypes.DATE, allowNull: true },          // Date du paiement
  paymentProcessing: { type: DataTypes.BOOLEAN, defaultValue: false }, // Flag anti-doublon
  // 🆕 Champs split payment
  paymentType: { type: DataTypes.STRING, defaultValue: 'full' }, // 'full' ou 'split'
  paymentStep: { type: DataTypes.INTEGER, defaultValue: 1 },      // 1 = premier paiement, 2 = second
  syncRef: { type: DataTypes.STRING, allowNull: true }            // Référence de synchronisation FineoPay
}, {
  sequelize,
  modelName: 'Order',
  tableName: 'orders',
  timestamps: true,
  paranoid: true, // Active l'archivage (soft delete)
  underscored: true // Convertit camelCase vers snake_case
});

module.exports = Order;
