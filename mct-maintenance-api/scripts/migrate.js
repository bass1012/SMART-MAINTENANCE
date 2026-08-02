const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const { sequelize } = require('../src/config/database');

const migrationsDirectory = path.join(__dirname, '../migrations');

const discoverMigrations = () => fs.readdirSync(migrationsDirectory)
  .filter((filename) => filename.endsWith('.js'))
  .sort();

const loadMigration = (filename) => {
  const migration = require(path.join(migrationsDirectory, filename));
  if (!migration || typeof migration.up !== 'function' || typeof migration.down !== 'function') {
    throw new TypeError(`Migration invalide ${filename}: les fonctions up et down sont obligatoires`);
  }
  return migration;
};

const ensureHistoryTable = async (database) => {
  await database.query(`
    CREATE TABLE IF NOT EXISTS migration_history (
      filename VARCHAR(255) PRIMARY KEY,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
};

const getExecutedMigrations = async (database) => {
  const [rows] = await database.query('SELECT filename FROM migration_history');
  return new Set(rows.map((row) => row.filename));
};

async function runMigrations({ database = sequelize, statusOnly = false, closeConnection = true } = {}) {
  try {
    await database.authenticate();
    await ensureHistoryTable(database);

    const migrationFiles = discoverMigrations();
    const executedMigrations = await getExecutedMigrations(database);
    const pendingMigrations = migrationFiles.filter((filename) => !executedMigrations.has(filename));

    console.log(`📁 ${migrationFiles.length} migrations JS versionnées, ${pendingMigrations.length} en attente.`);
    if (statusOnly) {
      for (const filename of pendingMigrations) console.log(`⏳ ${filename}`);
      return { total: migrationFiles.length, pending: pendingMigrations };
    }

    for (const filename of pendingMigrations) {
      console.log(`🔄 Exécution de la migration: ${filename}`);
      const migration = loadMigration(filename);
      await migration.up(database.getQueryInterface(), Sequelize);
      await database.query(
        'INSERT INTO migration_history (filename) VALUES (?)',
        { replacements: [filename] }
      );
      console.log(`✅ Migration ${filename} exécutée.`);
    }

    return { total: migrationFiles.length, executed: pendingMigrations.length };
  } finally {
    if (closeConnection) await database.close();
  }
}

if (require.main === module) {
  runMigrations({ statusOnly: process.argv.includes('--status') })
    .catch((error) => {
      console.error(`❌ Erreur lors des migrations: ${error.message}`);
      process.exitCode = 1;
    });
}

module.exports = runMigrations;
module.exports.discoverMigrations = discoverMigrations;
module.exports.loadMigration = loadMigration;
