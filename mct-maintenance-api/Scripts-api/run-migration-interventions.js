// Script pour exécuter la migration d'ajout des colonnes address et intervention_type

const { sequelize } = require('../src/config/database');
const migration = require('../migrations/20251022_add_address_and_type_to_interventions');

async function runMigration() {
  try {
    console.log('🔄 Connexion à la base de données...');
    await sequelize.authenticate();
    console.log('✅ Connecté à la base de données');

    console.log('🔄 Exécution de la migration...');
    await migration.up(sequelize.getQueryInterface(), sequelize.Sequelize);
    console.log('✅ Migration exécutée avec succès');

    console.log('✅ Colonnes address et intervention_type ajoutées à la table interventions');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  }
}

runMigration();
