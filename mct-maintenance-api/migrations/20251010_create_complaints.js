const { sequelize } = require('../src/config/database');
const Complaint = require('../src/models/Complaint');

async function up() {
  console.log('Création de la table complaints...');
  
  try {
    // Synchroniser le modèle avec la base de données
    await Complaint.sync({ force: false });
    
    console.log('Table complaints créée avec succès');
  } catch (error) {
    console.error('Erreur lors de la création de la table complaints:', error);
    throw error;
  }
}

async function down() {
  console.log('Suppression de la table complaints...');
  try {
    await Complaint.drop();
    console.log('Table complaints supprimée');
  } catch (error) {
    console.error('Erreur lors de la suppression de la table complaints:', error);
    throw error;
  }
}

// Exécuter la migration si le script est appelé directement
if (require.main === module) {
  (async () => {
    try {
      await up();
      console.log('Migration complaints exécutée avec succès');
    } catch (error) {
      console.error('Erreur lors de la migration complaints:', error);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  })();
}

module.exports = { up, down };