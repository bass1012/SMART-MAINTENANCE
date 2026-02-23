/**
 * Migration: Ajouter colonnes géolocalisation à table users
 * Date: 5 Janvier 2026
 * 
 * Ajoute:
 * - latitude (DECIMAL)
 * - longitude (DECIMAL)
 * - last_location_update (DATETIME)
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../database.sqlite');

async function up() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath);

    db.serialize(() => {
      // 1. Ajouter colonne latitude
      db.run(`
        ALTER TABLE users 
        ADD COLUMN latitude DECIMAL(10, 8) DEFAULT NULL
      `, (err) => {
        if (err && !err.message.includes('duplicate column')) {
          console.error('❌ Erreur ajout latitude:', err.message);
          reject(err);
          return;
        }
        console.log('✅ Colonne latitude ajoutée');
      });

      // 2. Ajouter colonne longitude
      db.run(`
        ALTER TABLE users 
        ADD COLUMN longitude DECIMAL(11, 8) DEFAULT NULL
      `, (err) => {
        if (err && !err.message.includes('duplicate column')) {
          console.error('❌ Erreur ajout longitude:', err.message);
          reject(err);
          return;
        }
        console.log('✅ Colonne longitude ajoutée');
      });

      // 3. Ajouter colonne last_location_update
      db.run(`
        ALTER TABLE users 
        ADD COLUMN last_location_update DATETIME DEFAULT NULL
      `, (err) => {
        if (err && !err.message.includes('duplicate column')) {
          console.error('❌ Erreur ajout last_location_update:', err.message);
          reject(err);
          return;
        }
        console.log('✅ Colonne last_location_update ajoutée');
      });

      // 4. Peupler avec données test (coordonnées Abidjan et environs)
      db.run(`
        UPDATE users 
        SET 
          latitude = CASE
            WHEN id = 15 THEN 5.3599  -- Plateau (centre Abidjan)
            WHEN id = 6 THEN 5.3484   -- Cocody
            WHEN id = 19 THEN 5.3355  -- Marcory
            ELSE 5.3599 + (RANDOM() % 100 - 50) / 1000.0  -- Variation ±50km
          END,
          longitude = CASE
            WHEN id = 15 THEN -4.0083  -- Plateau
            WHEN id = 6 THEN -3.9866   -- Cocody
            WHEN id = 19 THEN -4.0160  -- Marcory
            ELSE -4.0083 + (RANDOM() % 100 - 50) / 1000.0  -- Variation ±50km
          END,
          last_location_update = datetime('now')
        WHERE role IN ('technician', 'admin')
      `, (err) => {
        if (err) {
          console.error('❌ Erreur peuplement données:', err.message);
          reject(err);
          return;
        }
        console.log('✅ Données géolocalisation peuplées pour techniciens/admins');
      });

      db.close((err) => {
        if (err) {
          console.error('❌ Erreur fermeture DB:', err.message);
          reject(err);
        } else {
          console.log('✅ Migration géolocalisation terminée');
          resolve();
        }
      });
    });
  });
}

async function down() {
  // SQLite ne supporte pas DROP COLUMN directement
  // Il faut recréer la table sans ces colonnes
  console.log('⚠️  Rollback non implémenté pour SQLite');
  console.log('   Les colonnes latitude, longitude, last_location_update resteront');
}

// Exécution si lancé directement
if (require.main === module) {
  console.log('🚀 Démarrage migration géolocalisation...\n');
  
  up()
    .then(() => {
      console.log('\n✅ Migration réussie !');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration échouée:', error);
      process.exit(1);
    });
}

module.exports = { up, down };
