const { sequelize } = require('./src/config/database');

async function fixNotificationType() {
  try {
    console.log('🔄 Mise à jour du modèle de notifications...\n');

    // 1. Créer la nouvelle table
    console.log('1️⃣ Création de la nouvelle table...');
    await sequelize.query(`
      CREATE TABLE notifications_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN (
          'intervention_request',
          'intervention_assigned',
          'technician_assigned',
          'intervention_completed',
          'intervention_updated',
          'complaint_created',
          'complaint_response',
          'complaint_status_update',
          'subscription_created',
          'subscription_expiring',
          'order_created',
          'order_status_update',
          'quote_created',
          'quote_accepted',
          'quote_rejected',
          'quote_updated',
          'contract_created',
          'contract_expiring',
          'payment_received',
          'report_submitted',
          'general'
        )),
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        data TEXT,
        is_read INTEGER DEFAULT 0,
        read_at DATETIME,
        priority TEXT DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high')),
        action_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Table créée\n');

    // 2. Copier les données
    console.log('2️⃣ Copie des données existantes...');
    await sequelize.query(`
      INSERT INTO notifications_new 
      SELECT * FROM notifications
    `);
    console.log('✅ Données copiées\n');

    // 3. Supprimer l'ancienne table
    console.log('3️⃣ Suppression de l\'ancienne table...');
    await sequelize.query('DROP TABLE notifications');
    console.log('✅ Ancienne table supprimée\n');

    // 4. Renommer la nouvelle table
    console.log('4️⃣ Renommage de la nouvelle table...');
    await sequelize.query('ALTER TABLE notifications_new RENAME TO notifications');
    console.log('✅ Table renommée\n');

    // 5. Recréer les index
    console.log('5️⃣ Création des index...');
    await sequelize.query('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
    await sequelize.query('CREATE INDEX idx_notifications_type ON notifications(type)');
    await sequelize.query('CREATE INDEX idx_notifications_is_read ON notifications(is_read)');
    await sequelize.query('CREATE INDEX idx_notifications_created_at ON notifications(created_at)');
    console.log('✅ Index créés\n');

    // Vérification
    const [results] = await sequelize.query(`
      SELECT type, COUNT(*) as count 
      FROM notifications 
      GROUP BY type
    `);
    
    console.log('📈 Types de notifications dans la base:');
    results.forEach(row => {
      console.log(`   - ${row.type}: ${row.count} notification(s)`);
    });

    await sequelize.close();
    console.log('\n🎉 Migration terminée avec succès !');
    console.log('✅ Le type "technician_assigned" est maintenant disponible\n');
    console.log('➡️  Redémarrez le backend avec: npm start');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

fixNotificationType();
