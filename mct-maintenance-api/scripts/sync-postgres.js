#!/usr/bin/env node
/**
 * Script pour créer toutes les tables PostgreSQL dans le bon ordre
 * Usage: node scripts/sync-postgres.js
 */

require('dotenv').config();

const { sequelize } = require('../src/config/database');

async function syncTables() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('        SYNCHRONISATION PostgreSQL');
  console.log('═══════════════════════════════════════════════════════════');
  
  try {
    console.log('\n🔌 Test de connexion...');
    await sequelize.authenticate();
    console.log('   ✅ Connecté à PostgreSQL');
    
    // Nettoyer le schéma public
    console.log('\n🗑️  Nettoyage du schéma...');
    await sequelize.query('DROP SCHEMA IF EXISTS public CASCADE');
    await sequelize.query('CREATE SCHEMA public');
    await sequelize.query('GRANT ALL ON SCHEMA public TO postgres');
    await sequelize.query('GRANT ALL ON SCHEMA public TO public');
    console.log('   ✅ Schéma recréé');
    
    // Importer les modèles APRÈS le nettoyage
    console.log('\n📦 Importation des modèles...');
    
    // Ordre de synchronisation - tables de base d'abord
    const { DataTypes } = require('sequelize');
    
    // 1. Tables sans dépendances
    const User = require('../src/models/User');
    const MaintenanceOffer = require('../src/models/MaintenanceOffer');
    const RepairService = require('../src/models/RepairService');
    const InstallationService = require('../src/models/InstallationService');
    const Category = require('../src/models/Category');
    const Brand = require('../src/models/Brand');
    const SystemConfig = require('../src/models/SystemConfig');
    const Promotion = require('../src/models/Promotion');
    
    console.log('   📋 Création des tables de base...');
    await User.sync({ force: true });
    await MaintenanceOffer.sync({ force: true });
    await RepairService.sync({ force: true });
    await InstallationService.sync({ force: true });
    await Category.sync({ force: true });
    await Brand.sync({ force: true });
    await SystemConfig.sync({ force: true });
    await Promotion.sync({ force: true });
    console.log('   ✅ Tables de base créées');
    
    // 2. Tables dépendant de User
    const CustomerProfile = require('../src/models/CustomerProfile');
    const TechnicianProfile = require('../src/models/TechnicianProfile');
    const Equipment = require('../src/models/Equipment');
    const Notification = require('../src/models/Notification');
    const Contract = require('../src/models/Contract');
    const Split = require('../src/models/Split');
    const PasswordResetCode = require('../src/models/PasswordResetCode');
    const EmailVerificationCode = require('../src/models/EmailVerificationCode');
    const MaintenanceSchedule = require('../src/models/MaintenanceSchedule');
    
    console.log('   📋 Création des tables dépendant de User...');
    await CustomerProfile.sync({ force: true });
    await TechnicianProfile.sync({ force: true });
    await Equipment.sync({ force: true });
    await Notification.sync({ force: true });
    await Contract.sync({ force: true });
    await Split.sync({ force: true });
    await PasswordResetCode.sync({ force: true });
    await EmailVerificationCode.sync({ force: true });
    await MaintenanceSchedule.sync({ force: true });
    console.log('   ✅ Tables User-dépendantes créées');
    
    // 3. Tables dépendant de CustomerProfile
    const Subscription = require('../src/models/Subscription');
    const Intervention = require('../src/models/Intervention');
    const Quote = require('../src/models/Quote');
    const Order = require('../src/models/Order');
    const Complaint = require('../src/models/Complaint');
    const ChatMessage = require('../src/models/ChatMessage');
    const Product = require('../src/models/Product');
    
    console.log('   📋 Création des tables CustomerProfile-dépendantes...');
    await Product.sync({ force: true });
    await Subscription.sync({ force: true });
    await Intervention.sync({ force: true });
    await Quote.sync({ force: true });
    await Order.sync({ force: true });
    await Complaint.sync({ force: true });
    await ChatMessage.sync({ force: true });
    console.log('   ✅ Tables CustomerProfile-dépendantes créées');
    
    // 4. Tables de niveau 3
    const InterventionImage = require('../src/models/InterventionImage');
    const DiagnosticReport = require('../src/models/DiagnosticReport');
    const QuoteItem = require('../src/models/QuoteItem');
    const OrderItem = require('../src/models/OrderItem');
    const ComplaintNote = require('../src/models/ComplaintNote');
    const PaymentLog = require('../src/models/PaymentLog');
    const Payment = require('../src/models/Payment')(sequelize, DataTypes);
    
    console.log('   📋 Création des tables de niveau 3...');
    await InterventionImage.sync({ force: true });
    await DiagnosticReport.sync({ force: true });
    await QuoteItem.sync({ force: true });
    await OrderItem.sync({ force: true });
    await ComplaintNote.sync({ force: true });
    await PaymentLog.sync({ force: true });
    await Payment.sync({ force: true });
    console.log('   ✅ Tables de niveau 3 créées');
    
    // Lister les tables créées
    const [tables] = await sequelize.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      ORDER BY tablename
    `);
    
    console.log(`\n📋 ${tables.length} table(s) créée(s):`);
    tables.forEach(t => console.log(`   - ${t.tablename}`));
    
    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('✅ Synchronisation terminée!');
    console.log('   Vous pouvez maintenant lancer: npm run migrate:postgres');
    console.log('═══════════════════════════════════════════════════════════');
    
  } catch (error) {
    console.error('\n❌ Erreur lors de la synchronisation:', error.message);
    console.error(error.stack);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

syncTables();
