const { sequelize } = require('../src/config/database');

async function addRatingColumns() {
  try {
    console.log('🔄 Ajout des colonnes rating et review à la table interventions...');

    // Vérifier si les colonnes existent déjà
    const [results] = await sequelize.query(`
      PRAGMA table_info(interventions);
    `);

    const columns = results.map(col => col.name);
    const hasRating = columns.includes('rating');
    const hasReview = columns.includes('review');

    if (hasRating && hasReview) {
      console.log('✅ Les colonnes rating et review existent déjà');
      return;
    }

    // Ajouter la colonne rating si elle n'existe pas
    if (!hasRating) {
      await sequelize.query(`
        ALTER TABLE interventions 
        ADD COLUMN rating INTEGER CHECK(rating >= 1 AND rating <= 5);
      `);
      console.log('✅ Colonne rating ajoutée');
    }

    // Ajouter la colonne review si elle n'existe pas
    if (!hasReview) {
      await sequelize.query(`
        ALTER TABLE interventions 
        ADD COLUMN review TEXT;
      `);
      console.log('✅ Colonne review ajoutée');
    }

    console.log('✅ Migration terminée avec succès');
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    throw error;
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  addRatingColumns()
    .then(() => {
      console.log('Migration terminée');
      process.exit(0);
    })
    .catch(error => {
      console.error('Erreur:', error);
      process.exit(1);
    });
}

module.exports = addRatingColumns;
