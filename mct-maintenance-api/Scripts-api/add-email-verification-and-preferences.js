const { sequelize } = require('../src/config/database');

/**
 * Migration: Ajout des champs de vérification email et table de préférences de notifications
 */
async function migrate() {
  try {
    console.log('🚀 Début de la migration...');
    
    // 1. Ajouter les colonnes de vérification email à la table users
    console.log('📝 Ajout des colonnes de vérification email...');
    
    // SQLite ne supporte pas IF NOT EXISTS pour ALTER TABLE, on doit vérifier manuellement
    try {
      await sequelize.query(`
        ALTER TABLE users ADD COLUMN email_verification_token TEXT
      `);
      console.log('✅ Colonne email_verification_token ajoutée');
    } catch (error) {
      if (error.message.includes('duplicate column name')) {
        console.log('ℹ️  Colonne email_verification_token existe déjà');
      } else {
        throw error;
      }
    }
    
    try {
      await sequelize.query(`
        ALTER TABLE users ADD COLUMN email_verification_expires DATETIME
      `);
      console.log('✅ Colonne email_verification_expires ajoutée');
    } catch (error) {
      if (error.message.includes('duplicate column name')) {
        console.log('ℹ️  Colonne email_verification_expires existe déjà');
      } else {
        throw error;
      }
    }
    
    console.log('✅ Colonnes ajoutées à la table users');
    
    // 2. Créer la table notification_preferences
    console.log('📝 Création de la table notification_preferences...');
    
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS notification_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        
        -- Préférences générales
        email_enabled INTEGER NOT NULL DEFAULT 1,
        push_enabled INTEGER NOT NULL DEFAULT 1,
        sms_enabled INTEGER NOT NULL DEFAULT 0,
        
        -- Notifications interventions
        intervention_request_email INTEGER DEFAULT 1,
        intervention_request_push INTEGER DEFAULT 1,
        intervention_assigned_email INTEGER DEFAULT 1,
        intervention_assigned_push INTEGER DEFAULT 1,
        intervention_completed_email INTEGER DEFAULT 1,
        intervention_completed_push INTEGER DEFAULT 1,
        
        -- Notifications commandes
        order_created_email INTEGER DEFAULT 1,
        order_created_push INTEGER DEFAULT 1,
        order_status_update_email INTEGER DEFAULT 1,
        order_status_update_push INTEGER DEFAULT 1,
        
        -- Notifications devis
        quote_created_email INTEGER DEFAULT 1,
        quote_created_push INTEGER DEFAULT 1,
        quote_updated_email INTEGER DEFAULT 1,
        quote_updated_push INTEGER DEFAULT 1,
        
        -- Notifications réclamations
        complaint_created_email INTEGER DEFAULT 1,
        complaint_created_push INTEGER DEFAULT 1,
        complaint_response_email INTEGER DEFAULT 1,
        complaint_response_push INTEGER DEFAULT 1,
        
        -- Notifications contrats
        contract_expiring_email INTEGER DEFAULT 1,
        contract_expiring_push INTEGER DEFAULT 1,
        
        -- Notifications marketing
        promotion_email INTEGER DEFAULT 0,
        promotion_push INTEGER DEFAULT 0,
        maintenance_tip_email INTEGER DEFAULT 0,
        maintenance_tip_push INTEGER DEFAULT 0,
        
        -- Notifications générales
        general_email INTEGER DEFAULT 1,
        general_push INTEGER DEFAULT 1,
        
        -- Heures de silence
        quiet_hours_enabled INTEGER DEFAULT 0,
        quiet_hours_start TEXT NULL,
        quiet_hours_end TEXT NULL,
        
        -- Digest
        daily_digest_enabled INTEGER DEFAULT 0,
        weekly_digest_enabled INTEGER DEFAULT 0,
        
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    console.log('✅ Table notification_preferences créée');
    
    // 3. Créer des préférences par défaut pour tous les utilisateurs existants
    console.log('📝 Création des préférences par défaut pour les utilisateurs existants...');
    
    await sequelize.query(`
      INSERT OR IGNORE INTO notification_preferences (user_id)
      SELECT id FROM users
    `);
    
    console.log('✅ Préférences créées pour tous les utilisateurs');
    
    // 4. Mettre à jour les variables d'environnement nécessaires
    console.log('');
    console.log('⚠️  IMPORTANT: Ajoutez ces variables dans votre fichier .env :');
    console.log('');
    console.log('# Configuration SMTP pour emails');
    console.log('SMTP_HOST=smtp.gmail.com');
    console.log('SMTP_PORT=587');
    console.log('SMTP_SECURE=false');
    console.log('SMTP_USER=votre-email@gmail.com');
    console.log('SMTP_PASS=votre-mot-de-passe-application');
    console.log('SMTP_FROM=noreply@mct-maintenance.com');
    console.log('SMTP_FROM_NAME=MCT Maintenance');
    console.log('');
    console.log('# URL frontend pour liens de vérification');
    console.log('FRONTEND_URL=http://localhost:3001');
    console.log('');
    
    console.log('✅ Migration terminée avec succès!');
    
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Exécuter la migration
migrate()
  .then(() => {
    console.log('✅ Migration complétée');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Erreur:', error);
    process.exit(1);
  });
