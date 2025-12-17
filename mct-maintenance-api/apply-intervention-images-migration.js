#!/usr/bin/env node

/**
 * Script d'application de la migration intervention_images
 * Usage: node apply-intervention-images-migration.js
 */

const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const migrationPath = path.join(__dirname, 'migrations', 'create_intervention_images.sql');

console.log('🔄 Application de la migration intervention_images...\n');

// Vérifier que la base de données existe
if (!fs.existsSync(dbPath)) {
  console.error('❌ Erreur: database.sqlite introuvable');
  process.exit(1);
}

// Vérifier que le fichier de migration existe
if (!fs.existsSync(migrationPath)) {
  console.error('❌ Erreur: Fichier de migration introuvable');
  process.exit(1);
}

// Lire le fichier de migration
const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

// Ouvrir la connexion
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Erreur de connexion à la base de données:', err);
    process.exit(1);
  }
  console.log('✅ Connexion à la base de données réussie');
});

// Vérifier si la table existe déjà
db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='intervention_images'", (err, row) => {
  if (err) {
    console.error('❌ Erreur lors de la vérification:', err);
    db.close();
    process.exit(1);
  }

  if (row) {
    console.log('⚠️  La table intervention_images existe déjà');
    console.log('ℹ️  Aucune action nécessaire\n');
    
    // Afficher le nombre d'images existantes
    db.get("SELECT COUNT(*) as count FROM intervention_images", (err, result) => {
      if (!err) {
        console.log(`📊 Nombre d'images actuelles: ${result.count}`);
      }
      db.close();
    });
  } else {
    console.log('📝 Création de la table intervention_images...\n');
    
    // Exécuter la migration
    db.exec(migrationSQL, (err) => {
      if (err) {
        console.error('❌ Erreur lors de l\'exécution de la migration:', err);
        db.close();
        process.exit(1);
      }
      
      console.log('✅ Migration appliquée avec succès !');
      console.log('✅ Table intervention_images créée');
      console.log('✅ Index créé sur intervention_id\n');
      
      // Vérifier la structure de la table
      db.all("PRAGMA table_info(intervention_images)", (err, columns) => {
        if (!err && columns) {
          console.log('📋 Structure de la table:');
          columns.forEach(col => {
            console.log(`   - ${col.name} (${col.type})`);
          });
          console.log('');
        }
        
        console.log('🎉 Migration terminée avec succès !');
        console.log('');
        console.log('📌 Prochaines étapes:');
        console.log('   1. Installer multer: npm install multer');
        console.log('   2. Redémarrer le serveur: npm run dev');
        console.log('   3. Tester l\'upload depuis l\'application mobile');
        
        db.close();
      });
    });
  }
});
