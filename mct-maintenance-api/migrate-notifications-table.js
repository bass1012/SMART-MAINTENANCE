const { sequelize } = require('./src/config/database');
const Notification = require('./src/models/Notification');

async function migrateNotificationsTable() {
  console.log('🔄 Migration de la table notifications...');

  try {
    // 1. Créer une table temporaire avec les données existantes
    console.log('📦 Sauvegarde des notifications existantes...');
    await sequelize.query(`
      CREATE TABLE notifications_backup AS SELECT * FROM notifications;
    `);
    console.log('✅ Sauvegarde créée');

    // 2. Supprimer l'ancienne table
    console.log('🗑️  Suppression de l\'ancienne table...');
    await sequelize.query('DROP TABLE notifications;');
    console.log('✅ Ancienne table supprimée');

    // 3. Recréer la table avec la nouvelle structure
    console.log('🔨 Création de la nouvelle table...');
    await Notification.sync({ force: true });
    console.log('✅ Nouvelle table créée avec les nouveaux types');

    // 4. Restaurer les données
    console.log('📥 Restauration des notifications...');
    await sequelize.query(`
      INSERT INTO notifications 
      SELECT * FROM notifications_backup 
      WHERE type IN (
        'intervention_request',
        'intervention_assigned',
        'technician_assigned',
        'intervention_completed',
        'complaint_created',
        'complaint_response',
        'complaint_status_change',
        'subscription_created',
        'subscription_expiring',
        'order_created',
        'order_status_update',
        'quote_created',
        'quote_sent',
        'quote_updated',
        'quote_accepted',
        'quote_rejected',
        'contract_created',
        'contract_expiring',
        'contract_renewal_request',
        'payment_received',
        'report_submitted',
        'general',
        'maintenance_offer_created',
        'maintenance_offer_activated',
        'promotion',
        'maintenance_tip',
        'maintenance_reminder',
        'announcement',
        'alert'
      );
    `);
    console.log('✅ Données restaurées');

    // 5. Supprimer la table de backup
    console.log('🧹 Nettoyage...');
    await sequelize.query('DROP TABLE notifications_backup;');
    console.log('✅ Nettoyage terminé');

    console.log('✨ Migration réussie !');
    console.log('📊 Les nouveaux types de notifications disponibles:');
    console.log('   - promotion');
    console.log('   - maintenance_tip');
    console.log('   - maintenance_reminder');
    console.log('   - announcement');
    console.log('   - alert');
    console.log('   - maintenance_offer_created');
    console.log('   - maintenance_offer_activated');

  } catch (error) {
    console.error('❌ Erreur migration:', error);
    
    // Tentative de rollback
    try {
      console.log('🔄 Tentative de rollback...');
      await sequelize.query('DROP TABLE IF EXISTS notifications;');
      await sequelize.query('ALTER TABLE notifications_backup RENAME TO notifications;');
      console.log('✅ Rollback effectué');
    } catch (rollbackError) {
      console.error('❌ Erreur rollback:', rollbackError);
    }
  } finally {
    await sequelize.close();
  }
}

migrateNotificationsTable();
