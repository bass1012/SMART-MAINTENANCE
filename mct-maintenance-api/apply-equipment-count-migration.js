#!/usr/bin/env node

/**
 * Script d'application de la migration equipment_count
 * Usage: node apply-equipment-count-migration.js
 */

const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const migrationPath = path.join(__dirname, 'migrations', 'add_equipment_count_to_interventions.sql');

console.log('🔄 Application de la migration equipment_count...\n');

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

// Vérifier si la colonne existe déjà
db.get("PRAGMA table_info(interventions)", (err, row) => {
  if (err) {
    console.error('❌ Erreur lors de la vérification de la table:', err);
    db.close();
    process.exit(1);
  }
});

db.all("PRAGMA table_info(interventions)", (err, rows) => {
  if (err) {
    console.error('❌ Erreur:', err);
    db.close();
    process.exit(1);
  }

  const columnExists = rows.some(row => row.name === 'equipment_count');

  if (columnExists) {
    console.log('ℹ️  La colonne equipment_count existe déjà');
    console.log('✅ Migration déjà appliquée\n');
    
    // Afficher quelques interventions pour vérification
    db.all("SELECT id, title, equipment_count FROM interventions LIMIT 5", (err, rows) => {
      if (!err && rows.length > 0) {
        console.log('📊 Exemple d\'interventions:');
        rows.forEach(row => {
          console.log(`   ID ${row.id}: ${row.title} - ${row.equipment_count || 1} équipement(s)`);
        });
      }
      db.close();
    });
    return;
  }

  console.log('📝 Application de la migration...');

  // Séparer les commandes SQL
  const commands = migrationSQL
    .split(';')
    .map(cmd => cmd.trim())
    .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));

  // Exécuter les commandes en série
  let completed = 0;
  
  const executeCommand = (index) => {
    if (index >= commands.length) {
      console.log(`✅ ${completed} commande(s) exécutée(s) avec succès\n`);
      
      // Vérifier le résultat
      db.all("SELECT id, title, equipment_count FROM interventions LIMIT 5", (err, rows) => {
        if (!err && rows.length > 0) {
          console.log('📊 Interventions mises à jour:');
          rows.forEach(row => {
            console.log(`   ID ${row.id}: ${row.title} - ${row.equipment_count || 1} équipement(s)`);
          });
        }
        
        console.log('\n✅ Migration appliquée avec succès!');
        console.log('🎉 Le champ equipment_count est maintenant disponible\n');
        db.close();
      });
      return;
    }

    const command = commands[index];
    
    db.run(command, (err) => {
      if (err) {
        console.error(`❌ Erreur lors de l'exécution de la commande ${index + 1}:`, err);
        db.close();
        process.exit(1);
      }
      
      completed++;
      executeCommand(index + 1);
    });
  };

  executeCommand(0);
});

// Gérer les erreurs
db.on('error', (err) => {
  console.error('❌ Erreur de base de données:', err);
  process.exit(1);
});
