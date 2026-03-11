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
  rejection_reason: { type: DataTypes.TEXT, field: 'rejection_reason' },
  scheduled_date: { type: DataTypes.DATE, allowNull: true, field: 'scheduled_date' },
  second_contact: { type: DataTypes.STRING, allowNull: true, field: 'second_contact' },
  execute_now: { type: DataTypes.BOOLEAN, allowNull: true, defaultValue: false, field: 'execute_now' },
  // New fields for diagnostic workflow
  intervention_id: { type: DataTypes.INTEGER, allowNull: true, field: 'intervention_id' },
  diagnostic_report_id: { type: DataTypes.INTEGER, allowNull: true, field: 'diagnostic_report_id' },
  line_items: { type: DataTypes.TEXT, allowNull: true, field: 'line_items', 
    get() {
      const rawValue = this.getDataValue('line_items');
      return rawValue ? JSON.parse(rawValue) : null;
    },
    set(value) {
      this.setDataValue('line_items', value ? JSON.stringify(value) : null);
    }
  },
  sent_at: { type: DataTypes.DATE, allowNull: true, field: 'sent_at' },
  viewed_at: { type: DataTypes.DATE, allowNull: true, field: 'viewed_at' },
  responded_at: { type: DataTypes.DATE, allowNull: true, field: 'responded_at' },
  payment_status: { type: DataTypes.STRING, defaultValue: 'pending', field: 'payment_status' },
  paid_at: { type: DataTypes.DATE, allowNull: true, field: 'paid_at' },
  payment_method: { type: DataTypes.STRING, allowNull: true, field: 'payment_method' },
  payment_transaction_id: { type: DataTypes.STRING, allowNull: true, field: 'payment_transaction_id' },
  // Paiement en deux étapes (50% à l'acceptation, 50% à la fin)
  payment_type: { type: DataTypes.STRING, defaultValue: 'split', field: 'payment_type' }, // 'full' ou 'split'
  first_payment_amount: { type: DataTypes.FLOAT, allowNull: true, field: 'first_payment_amount' },
  first_payment_status: { type: DataTypes.STRING, defaultValue: 'pending', field: 'first_payment_status' }, // 'pending', 'paid'
  first_payment_date: { type: DataTypes.DATE, allowNull: true, field: 'first_payment_date' },
  first_payment_transaction_id: { type: DataTypes.STRING, allowNull: true, field: 'first_payment_transaction_id' },
  second_payment_amount: { type: DataTypes.FLOAT, allowNull: true, field: 'second_payment_amount' },
  second_payment_status: { type: DataTypes.STRING, defaultValue: 'pending', field: 'second_payment_status' }, // 'pending', 'paid'
  second_payment_date: { type: DataTypes.DATE, allowNull: true, field: 'second_payment_date' },
  second_payment_transaction_id: { type: DataTypes.STRING, allowNull: true, field: 'second_payment_transaction_id' }
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
