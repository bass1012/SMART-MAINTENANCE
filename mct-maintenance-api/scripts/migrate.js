const fs = require('fs');
const path = require('path');
const { sequelize } = require('../src/config/database');

async function runMigrations() {
  try {
    console.log('🔄 Démarrage des migrations...');
    
    // Connecter à la base de données
    await sequelize.authenticate();
    console.log('✅ Connexion à la base de données établie.');
    
    // Obtenir la liste des fichiers de migration
    const migrationsDir = path.join(__dirname, '../migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.js'))
      .sort(); // Trier par nom de fichier (ordre chronologique)
    
    console.log(`📁 ${migrationFiles.length} fichiers de migration trouvés.`);
    
    // Créer la table de suivi des migrations si elle n'existe pas
    const [results] = await sequelize.query(`
      CREATE TABLE IF NOT EXISTS migration_history (
        filename VARCHAR(255) PRIMARY KEY,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Obtenir la liste des migrations déjà exécutées
    const [executedMigrations] = await sequelize.query(
      'SELECT filename FROM migration_history'
    );
    const executedSet = new Set(executedMigrations.map(row => row.filename));
    
    // Exécuter les migrations non encore appliquées
    for (const file of migrationFiles) {
      if (executedSet.has(file)) {
        console.log(`⏭️  Migration ${file} déjà exécutée, passage à la suivante.`);
        continue;
      }
      
      console.log(`🔄 Exécution de la migration: ${file}`);
      
      try {
        const migration = require(path.join(migrationsDir, file));
        await migration.up(sequelize.getQueryInterface(), sequelize.constructor);
        
        // Marquer la migration comme exécutée
        await sequelize.query(
          'INSERT INTO migration_history (filename) VALUES (?)',
          { replacements: [file] }
        );
        
        console.log(`✅ Migration ${file} exécutée avec succès.`);
      } catch (error) {
        console.error(`❌ Erreur lors de l'exécution de la migration ${file}:`, error);
        throw error;
      }
    }
    
    console.log('🎉 Toutes les migrations ont été exécutées avec succès!');
    
  } catch (error) {
    console.error('❌ Erreur lors des migrations:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  runMigrations();
}

module.exports = runMigrations;