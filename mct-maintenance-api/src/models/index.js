const MaintenanceSchedule = require('./MaintenanceSchedule');
const EmailVerificationCode = require('./EmailVerificationCode');
const DiagnosticReport = require('./DiagnosticReport');
const SystemConfig = require('./SystemConfig');
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
const InstallationService = require('./InstallationService');
const RepairService = require('./RepairService');
const Subscription = require('./Subscription');
const Notification = require('./Notification');
const InterventionImage = require('./InterventionImage');
const ChatMessage = require('./ChatMessage');
const PasswordResetCode = require('./PasswordResetCode');
const Split = require('./Split');
const PaymentLog = require('./PaymentLog');

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
Intervention.belongsTo(CustomerProfile, { foreignKey: 'customer_id', as: 'customer' });
Intervention.belongsTo(User, { foreignKey: 'technician_id', as: 'technician' });
Intervention.belongsTo(MaintenanceOffer, { foreignKey: 'maintenance_offer_id', as: 'maintenance_offer' });
Intervention.belongsTo(RepairService, { foreignKey: 'repair_service_id', as: 'repair_service' });
Intervention.belongsTo(InstallationService, { foreignKey: 'installation_service_id', as: 'installation_service' });
CustomerProfile.hasMany(Intervention, { foreignKey: 'customer_id', as: 'interventions' });
User.hasMany(Intervention, { foreignKey: 'technician_id', as: 'technicianInterventions' });
MaintenanceOffer.hasMany(Intervention, { foreignKey: 'maintenance_offer_id', as: 'interventions' });
RepairService.hasMany(Intervention, { foreignKey: 'repair_service_id', as: 'interventions' });
InstallationService.hasMany(Intervention, { foreignKey: 'installation_service_id', as: 'interventions' });

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
Order.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });
Order.belongsTo(Quote, { foreignKey: 'quoteId', as: 'quote' });
Quote.hasOne(Order, { foreignKey: 'quoteId', as: 'order' });
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
  InstallationService,
  RepairService,
  Subscription,
  InterventionImage,
  Payment,
  ChatMessage,
  PasswordResetCode,
  Split,
  DiagnosticReport,
  PaymentLog,
  SystemConfig,
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
InstallationService.hasMany(Subscription, { foreignKey: 'installation_service_id', as: 'subscriptions' });
Subscription.belongsTo(InstallationService, { foreignKey: 'installation_service_id', as: 'installationService' });
RepairService.hasMany(Subscription, { foreignKey: 'repair_service_id', as: 'subscriptions' });
Subscription.belongsTo(RepairService, { foreignKey: 'repair_service_id', as: 'repairService' });

// Define associations for Split (Traçabilité par équipement)
User.hasMany(Split, { foreignKey: 'customer_id', as: 'splits' });
Split.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });

// Un split peut avoir plusieurs souscriptions (historique) mais une seule active
Split.hasMany(Subscription, { foreignKey: 'split_id', as: 'subscriptions' });
Subscription.belongsTo(Split, { foreignKey: 'split_id', as: 'split' });

// Un split peut avoir plusieurs interventions (historique)
Split.hasMany(Intervention, { foreignKey: 'split_id', as: 'interventions' });
Intervention.belongsTo(Split, { foreignKey: 'split_id', as: 'split' });

// Define associations for Notification
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Define associations for ChatMessage
User.hasMany(ChatMessage, { foreignKey: 'sender_id', as: 'sentMessages' });
ChatMessage.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });

// Define associations for PasswordResetCode
User.hasMany(PasswordResetCode, { foreignKey: 'user_id', as: 'passwordResetCodes' });
PasswordResetCode.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Define associations for DiagnosticReport
Intervention.hasMany(DiagnosticReport, { foreignKey: 'intervention_id', as: 'diagnosticReports' });
DiagnosticReport.belongsTo(Intervention, { foreignKey: 'intervention_id', as: 'intervention' });
User.hasMany(DiagnosticReport, { foreignKey: 'technician_id', as: 'submittedReports' });
DiagnosticReport.belongsTo(User, { foreignKey: 'technician_id', as: 'technician' });
User.hasMany(DiagnosticReport, { foreignKey: 'reviewed_by', as: 'reviewedReports' });
DiagnosticReport.belongsTo(User, { foreignKey: 'reviewed_by', as: 'reviewer' });
DiagnosticReport.hasMany(Quote, { foreignKey: 'diagnostic_report_id', as: 'quotes' });

// Extend Quote associations for diagnostic workflow
Quote.belongsTo(DiagnosticReport, { foreignKey: 'diagnostic_report_id', as: 'diagnosticReport' });
Quote.belongsTo(Intervention, { foreignKey: 'intervention_id', as: 'intervention' });
Intervention.hasMany(Quote, { foreignKey: 'intervention_id', as: 'quotes' });

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
  InstallationService,
  RepairService,
  Subscription,
  Notification,
  InterventionImage,
  Payment,
  ChatMessage,
  EmailVerificationCode,
  Split
};
