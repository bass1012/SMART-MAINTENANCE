#!/usr/bin/env node
/**
 * Script de migration SQLite → PostgreSQL
 * 
 * Usage:
 *   1. Configurer DATABASE_URL dans .env avec l'URL PostgreSQL
 *   2. npm run migrate:postgres
 * 
 * Ce script:
 *   - Lit toutes les données de la base SQLite locale
 *   - Crée les tables dans PostgreSQL
 *   - Migre toutes les données
 */

const { Sequelize } = require('sequelize');
const path = require('path');
require('dotenv').config();

// Vérifier la présence de DATABASE_URL
if (!process.env.DATABASE_URL) {
  console.error('❌ DATABASE_URL non défini dans .env');
  console.error('   Exemple: DATABASE_URL=postgres://user:password@host:5432/database');
  process.exit(1);
}

// Connexion SQLite (source)
const sqliteDB = new Sequelize({
  dialect: 'sqlite',
  storage: path.join(__dirname, '../database.sqlite'),
  logging: false
});

// Connexion PostgreSQL (destination)
const postgresDB = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  logging: false,
  dialectOptions: {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  }
});

// Liste des tables à migrer (dans l'ordre pour respecter les foreign keys)
const TABLES_ORDER = [
  'users',
  'customer_profiles',
  'maintenance_offers',
  'repair_services',
  'installation_services',
  'products',
  'maintenance_contracts',
  'scheduled_contracts',
  'interventions',
  'intervention_images',
  'intervention_equipments',
  'quotes',
  'quote_items',
  'orders',
  'order_items',
  'diagnostic_reports',
  'complaints',
  'notifications',
  'ratings',
  'technician_availabilities',
  'technician_schedules',
  'technician_locations',
  'technician_specializations',
  'app_settings',
  'payment_transactions',
  'report_templates'
];

async function getTableColumns(db, tableName, dialect) {
  try {
    if (dialect === 'sqlite') {
      const [columns] = await db.query(`PRAGMA table_info("${tableName}")`);
      return columns.map(c => c.name);
    } else {
      const [columns] = await db.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = '${tableName}'
      `);
      return columns.map(c => c.column_name);
    }
  } catch (e) {
    return [];
  }
}

async function tableExists(db, tableName, dialect) {
  try {
    if (dialect === 'sqlite') {
      const [result] = await db.query(`
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='${tableName}'
      `);
      return result.length > 0;
    } else {
      const [result] = await db.query(`
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' AND tablename = '${tableName}'
      `);
      return result.length > 0;
    }
  } catch (e) {
    return false;
  }
}

async function migrateTable(tableName) {
  console.log(`\n📦 Migration de la table: ${tableName}`);
  
  // Vérifier si la table existe dans SQLite
  const sqliteExists = await tableExists(sqliteDB, tableName, 'sqlite');
  if (!sqliteExists) {
    console.log(`   ⏭️  Table ${tableName} n'existe pas dans SQLite, ignorée`);
    return { table: tableName, count: 0, skipped: true };
  }
  
  // Récupérer les données de SQLite
  const [rows] = await sqliteDB.query(`SELECT * FROM "${tableName}"`);
  console.log(`   📊 ${rows.length} enregistrement(s) trouvé(s)`);
  
  if (rows.length === 0) {
    return { table: tableName, count: 0, skipped: false };
  }
  
  // Vérifier si la table existe dans PostgreSQL
  const pgExists = await tableExists(postgresDB, tableName, 'postgres');
  if (!pgExists) {
    console.log(`   ⚠️  Table ${tableName} n'existe pas dans PostgreSQL`);
    console.log(`   💡 Exécutez d'abord: NODE_ENV=production npm start (pour créer les tables)`);
    return { table: tableName, count: 0, error: 'Table not found in PostgreSQL' };
  }
  
  // Récupérer les colonnes PostgreSQL (pour éviter les erreurs de colonnes manquantes)
  const pgColumns = await getTableColumns(postgresDB, tableName, 'postgres');
  
  // Insérer les données dans PostgreSQL
  let successCount = 0;
  let errorCount = 0;
  
  for (const row of rows) {
    try {
      // Filtrer les colonnes qui existent dans PostgreSQL
      const filteredRow = {};
      for (const [key, value] of Object.entries(row)) {
        if (pgColumns.includes(key)) {
          // Gérer les valeurs JSON stockées en string
          if (typeof value === 'string' && (value.startsWith('{') || value.startsWith('['))) {
            try {
              filteredRow[key] = JSON.parse(value);
            } catch {
              filteredRow[key] = value;
            }
          } else {
            filteredRow[key] = value;
          }
        }
      }
      
      const columns = Object.keys(filteredRow);
      const values = Object.values(filteredRow);
      const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
      
      await postgresDB.query(
        `INSERT INTO "${tableName}" (${columns.map(c => `"${c}"`).join(', ')}) 
         VALUES (${placeholders})
         ON CONFLICT (id) DO NOTHING`,
        { bind: values }
      );
      successCount++;
    } catch (e) {
      errorCount++;
      if (errorCount <= 3) {
        console.log(`   ❌ Erreur ligne ${row.id}: ${e.message}`);
      }
    }
  }
  
  console.log(`   ✅ ${successCount} migré(s), ${errorCount} erreur(s)`);
  return { table: tableName, count: successCount, errors: errorCount };
}

async function resetSequences() {
  console.log('\n🔄 Réinitialisation des séquences PostgreSQL...');
  
  for (const tableName of TABLES_ORDER) {
    try {
      const pgExists = await tableExists(postgresDB, tableName, 'postgres');
      if (!pgExists) continue;
      
      // Réinitialiser la séquence à la valeur max de l'id
      await postgresDB.query(`
        SELECT setval(
          pg_get_serial_sequence('"${tableName}"', 'id'),
          COALESCE((SELECT MAX(id) FROM "${tableName}"), 1)
        )
      `);
    } catch (e) {
      // Ignorer les erreurs (table sans séquence)
    }
  }
  
  console.log('   ✅ Séquences réinitialisées');
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('        MIGRATION SQLite → PostgreSQL');
  console.log('═══════════════════════════════════════════════════════════');
  
  try {
    // Test des connexions
    console.log('\n🔌 Test des connexions...');
    await sqliteDB.authenticate();
    console.log('   ✅ SQLite connecté');
    
    await postgresDB.authenticate();
    console.log('   ✅ PostgreSQL connecté');
    
    // Migration des tables
    console.log('\n📋 Début de la migration...');
    const results = [];
    
    for (const table of TABLES_ORDER) {
      const result = await migrateTable(table);
      results.push(result);
    }
    
    // Réinitialiser les séquences
    await resetSequences();
    
    // Résumé
    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('                    RÉSUMÉ');
    console.log('═══════════════════════════════════════════════════════════');
    
    let totalMigrated = 0;
    let totalErrors = 0;
    
    for (const r of results) {
      if (!r.skipped && !r.error) {
        console.log(`   ${r.table}: ${r.count} enregistrement(s)`);
        totalMigrated += r.count;
        totalErrors += r.errors || 0;
      }
    }
    
    console.log('───────────────────────────────────────────────────────────');
    console.log(`   TOTAL: ${totalMigrated} enregistrement(s) migrés, ${totalErrors} erreur(s)`);
    console.log('═══════════════════════════════════════════════════════════');
    
    if (totalErrors === 0) {
      console.log('\n✅ Migration terminée avec succès!');
    } else {
      console.log('\n⚠️  Migration terminée avec des erreurs.');
    }
    
  } catch (error) {
    console.error('\n❌ Erreur fatale:', error.message);
    process.exit(1);
  } finally {
    await sqliteDB.close();
    await postgresDB.close();
  }
}

main();
