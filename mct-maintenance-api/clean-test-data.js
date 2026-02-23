const { 
  Intervention, 
  Order, 
  Payment, 
  Notification, 
  Complaint,
  InterventionImage,
  OrderItem,
  Quote,
  QuoteItem,
  Contract,
  MaintenanceSchedule,
  sequelize
} = require('./src/models');
const fs = require('fs');
const path = require('path');

/**
 * Script de nettoyage de la base de données pour les tests
 * Supprime toutes les données de test en gardant les utilisateurs de base
 */
async function cleanTestData() {
  try {
    console.log('🧹 Démarrage du nettoyage de la base de données...\n');

    // 1. Supprimer les images d'interventions
    console.log('📸 Suppression des images d\'interventions...');
    const deletedImages = await InterventionImage.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedImages} image(s) supprimée(s)`);

    // 2. Supprimer les interventions
    console.log('🔧 Suppression des interventions...');
    const deletedInterventions = await Intervention.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedInterventions} intervention(s) supprimée(s)`);

    // 3. Supprimer les items de commande
    console.log('📦 Suppression des items de commande...');
    const deletedOrderItems = await OrderItem.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedOrderItems} item(s) supprimé(s)`);

    // 4. Supprimer les paiements
    console.log('💰 Suppression des paiements...');
    const deletedPayments = await Payment.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedPayments} paiement(s) supprimé(s)`);

    // 5. Supprimer les commandes
    console.log('🛒 Suppression des commandes...');
    const deletedOrders = await Order.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedOrders} commande(s) supprimée(s)`);

    // 6. Supprimer les items de devis
    console.log('📋 Suppression des items de devis...');
    const deletedQuoteItems = await QuoteItem.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedQuoteItems} item(s) de devis supprimé(s)`);

    // 7. Supprimer les devis
    console.log('📄 Suppression des devis...');
    const deletedQuotes = await Quote.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedQuotes} devis supprimé(s)`);

    // 8. Supprimer les réclamations
    console.log('📢 Suppression des réclamations...');
    const deletedComplaints = await Complaint.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedComplaints} réclamation(s) supprimée(s)`);

    // 9. Supprimer les notifications
    console.log('🔔 Suppression des notifications...');
    const deletedNotifications = await Notification.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedNotifications} notification(s) supprimée(s)`);

    // 10. Supprimer les planifications de maintenance
    console.log('📅 Suppression des planifications...');
    const deletedSchedules = await MaintenanceSchedule.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedSchedules} planification(s) supprimée(s)`);

    // 11. Supprimer les contrats
    console.log('📝 Suppression des contrats...');
    const deletedContracts = await Contract.destroy({ where: {}, force: true });
    console.log(`   ✅ ${deletedContracts} contrat(s) supprimé(s)`);

    // 12. Nettoyer les fichiers uploadés (optionnel - commenté pour sécurité)
    console.log('\n📁 Nettoyage des fichiers uploadés...');
    const uploadsDir = path.join(__dirname, 'uploads', 'interventions');
    if (fs.existsSync(uploadsDir)) {
      const files = fs.readdirSync(uploadsDir);
      let deletedFiles = 0;
      files.forEach(file => {
        if (file !== '.gitkeep') {
          fs.unlinkSync(path.join(uploadsDir, file));
          deletedFiles++;
        }
      });
      console.log(`   ✅ ${deletedFiles} fichier(s) supprimé(s)`);
    }

    // 13. Réinitialiser les auto-increment (SQLite)
    console.log('\n🔄 Réinitialisation des séquences...');
    await sequelize.query("DELETE FROM sqlite_sequence WHERE name IN ('interventions', 'orders', 'payments', 'notifications', 'complaints', 'order_items', 'quotes', 'quote_items', 'intervention_images', 'maintenance_schedules', 'contracts')");
    console.log('   ✅ Séquences réinitialisées');

    console.log('\n✨ Nettoyage terminé avec succès!');
    console.log('\n📊 Résumé:');
    console.log(`   - ${deletedInterventions} interventions`);
    console.log(`   - ${deletedOrders} commandes`);
    console.log(`   - ${deletedPayments} paiements`);
    console.log(`   - ${deletedQuotes} devis`);
    console.log(`   - ${deletedComplaints} réclamations`);
    console.log(`   - ${deletedNotifications} notifications`);
    console.log(`   - ${deletedContracts} contrats`);
    console.log(`   - ${deletedSchedules} planifications`);
    console.log('\n⚠️  Les utilisateurs, produits et équipements sont conservés\n');

    process.exit(0);
    
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
    console.error(error.stack);
    process.exit(1);
  }
}

// Demander confirmation avant d'exécuter
console.log('⚠️  ATTENTION: Ce script va supprimer toutes les données de test!');
console.log('   - Interventions');
console.log('   - Commandes et paiements');
console.log('   - Devis');
console.log('   - Réclamations');
console.log('   - Notifications');
console.log('   - Contrats');
console.log('\n✅ Les utilisateurs, produits et équipements seront conservés\n');

// Vérifier si --force est passé en argument
if (process.argv.includes('--force')) {
  cleanTestData();
} else {
  console.log('Pour confirmer, relancez avec: node clean-test-data.js --force\n');
  process.exit(0);
}
