const { sequelize } = require('../src/config/database');
const { QueryTypes } = require('sequelize');

async function up() {
  try {
    console.log('🔧 Vérification de la colonne second_contact dans la table quotes...');

    // Vérifier si la colonne existe déjà
    const columns = await sequelize.query(
      "PRAGMA table_info(quotes);",
      { type: QueryTypes.SELECT }
    );

    const secondContactExists = columns.some(col => col.name === 'second_contact');

    if (secondContactExists) {
      console.log('✅ La colonne second_contact existe déjà');
      return;
    }

    console.log('➕ Ajout de la colonne second_contact...');

    await sequelize.query(`
      ALTER TABLE quotes
      ADD COLUMN second_contact VARCHAR(255);
    `);

    console.log('✅ Colonne second_contact ajoutée avec succès à la table quotes');

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    throw error;
  }
}

async function down() {
  try {
    console.log('🔧 Suppression de la colonne second_contact...');

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
