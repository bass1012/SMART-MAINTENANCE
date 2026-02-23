const { sequelize } = require('../src/config/database');
const { QueryTypes } = require('sequelize');

async function up() {
  try {
    console.log('🔧 Vérification de la colonne scheduled_date dans la table quotes...');

    // Vérifier si la colonne existe déjà
    const columns = await sequelize.query(
      "PRAGMA table_info(quotes);",
      { type: QueryTypes.SELECT }
    );

    const scheduledDateExists = columns.some(col => col.name === 'scheduled_date');

    if (scheduledDateExists) {
      console.log('✅ La colonne scheduled_date existe déjà');
      return;
    }

    console.log('➕ Ajout de la colonne scheduled_date...');

    await sequelize.query(`
      ALTER TABLE quotes
      ADD COLUMN scheduled_date DATETIME;
    `);

    console.log('✅ Colonne scheduled_date ajoutée avec succès à la table quotes');

    // Créer un index pour améliorer les performances de recherche
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS idx_quotes_scheduled_date 
      ON quotes(scheduled_date);
    `);

    console.log('✅ Index créé sur scheduled_date');

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    throw error;
  }
}

async function down() {
  try {
    console.log('🔧 Suppression de la colonne scheduled_date...');

    // SQLite ne supporte pas DROP COLUMN directement
    // Il faut recréer la table sans la colonne
    console.log('⚠️  SQLite ne supporte pas DROP COLUMN - migration down non implémentée');
    console.log('💡 Pour rollback, restaurez une sauvegarde de la base de données');

  } catch (error) {
    console.error('❌ Erreur lors du rollback:', error);
    throw error;
  }
}

module.exports = { up, down };

// Exécution si appelé directement
if (require.main === module) {
  up()
    .then(() => {
      console.log('✅ Migration terminée');
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ Migration échouée:', err);
      process.exit(1);
    });
}
