const MaintenanceSchedule = require('./MaintenanceSchedule');
// Import all models
const User = require('./User');
const CustomerProfile = require('./CustomerProfile');
const TechnicianProfile = require('./TechnicianProfile');
const Equipment = require('./Equipment');
const Intervention = require('./Intervention');
const Contract = require('./Contract');
const Product = require('./Product');
const Category = require('./Category');
const Brand = require('./Brand');
const Quote = require('./Quote');
const QuoteItem = require('./QuoteItem');
const Order = require('./Order');
const OrderItem = require('./OrderItem');
const Complaint = require('./Complaint');
const ComplaintNote = require('./ComplaintNote');
const MaintenanceOffer = require('./MaintenanceOffer');
const Subscription = require('./Subscription');
const Notification = require('./Notification');
const InterventionImage = require('./InterventionImage');
const ChatMessage = require('./ChatMessage');
const PasswordResetCode = require('./PasswordResetCode');

// Association CustomerProfile -> User
const fs = require('fs');
const path = require('path');
const { sequelize } = require('../config/database');
const { DataTypes } = require('sequelize');

// Initialize Payment model (factory pattern)
const Payment = require('./Payment')(sequelize, DataTypes);

// Define associations
User.hasOne(CustomerProfile, { foreignKey: 'user_id', as: 'customerProfile' });
User.hasOne(TechnicianProfile, { foreignKey: 'user_id', as: 'technicianProfile' });
TechnicianProfile.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
CustomerProfile.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
// ...existing code...
User.hasMany(Equipment, { foreignKey: 'customer_id', as: 'equipments' });

Equipment.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });

// Associations pour MaintenanceSchedule (planification)
MaintenanceSchedule.belongsTo(Equipment, { foreignKey: 'equipment_id', as: 'equipment' });
MaintenanceSchedule.belongsTo(User, { foreignKey: 'technician_id', as: 'technician' });

// Associations interventions
Intervention.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });
Intervention.belongsTo(User, { foreignKey: 'technician_id', as: 'technician' });
User.hasMany(Intervention, { foreignKey: 'customer_id', as: 'customerInterventions' });
User.hasMany(Intervention, { foreignKey: 'technician_id', as: 'technicianInterventions' });

// Associations images interventions
Intervention.hasMany(InterventionImage, { foreignKey: 'intervention_id', as: 'images' });
InterventionImage.belongsTo(Intervention, { foreignKey: 'intervention_id', as: 'intervention' });

// Associations contracts
Contract.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });
User.hasMany(Contract, { foreignKey: 'customer_id', as: 'contracts' });

// Associations devis
Quote.hasMany(QuoteItem, { foreignKey: 'quoteId', as: 'items', onDelete: 'CASCADE' });
QuoteItem.belongsTo(Quote, { foreignKey: 'quoteId', as: 'quote' });

// Associations commandes
Order.belongsTo(User, { foreignKey: 'customerId', as: 'customer' });
Order.hasMany(OrderItem, { foreignKey: 'orderId', as: 'items', onDelete: 'CASCADE' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });
OrderItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

// Associations produits - catégories - marques
Product.belongsTo(Category, { foreignKey: 'categorie_id', as: 'categorie' });
Product.belongsTo(Brand, { foreignKey: 'marque_id', as: 'marque' });
Category.hasMany(Product, { foreignKey: 'categorie_id', as: 'products' });
Brand.hasMany(Product, { foreignKey: 'marque_id', as: 'products' });

// Note: Les associations de Complaint sont déjà définies dans Complaint.js

// Export all models
const models = {
  User,
  CustomerProfile,
  TechnicianProfile,
  MaintenanceSchedule,
  Equipment,
  Intervention,
  Contract,
  Product,
  Category,
  Brand,
  Quote,
  QuoteItem,
  Order,
  OrderItem,
  Complaint,
  ComplaintNote,
  MaintenanceOffer,
  Subscription,
  InterventionImage,
  Payment,
  ChatMessage,
  PasswordResetCode,
  sequelize
};

// Define associations for ComplaintNote
Complaint.hasMany(ComplaintNote, { foreignKey: 'complaintId', as: 'notes' });
ComplaintNote.belongsTo(Complaint, { foreignKey: 'complaintId', as: 'complaint' });
ComplaintNote.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// Define associations for Subscription
User.hasMany(Subscription, { foreignKey: 'customer_id', as: 'subscriptions' });
Subscription.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });
MaintenanceOffer.hasMany(Subscription, { foreignKey: 'maintenance_offer_id', as: 'subscriptions' });
Subscription.belongsTo(MaintenanceOffer, { foreignKey: 'maintenance_offer_id', as: 'offer' });

// Define associations for Notification
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Define associations for ChatMessage
User.hasMany(ChatMessage, { foreignKey: 'sender_id', as: 'sentMessages' });
ChatMessage.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });

// Define associations for PasswordResetCode
User.hasMany(PasswordResetCode, { foreignKey: 'user_id', as: 'passwordResetCodes' });
PasswordResetCode.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Define associations for Payment
if (Payment.associate) {
  Payment.associate({ Order, Subscription });
}
Order.hasMany(Payment, { foreignKey: 'orderId', as: 'payments' });
Subscription.hasMany(Payment, { foreignKey: 'subscriptionId', as: 'payments' });

// Export the sequelize instance for transactions
module.exports = {
  ...models,
  CustomerProfile,
  ComplaintNote,
  MaintenanceOffer,
  Subscription,
  Notification,
  InterventionImage,
  Payment,
  ChatMessage
};
