/**
 * Migration: Ajout du champ created_by pour tracer qui a créé les comptes admin/manager
 */

const { sequelize } = require('../src/config/database');
const { QueryTypes } = require('sequelize');

async function up() {
  console.log('🚀 Migration: Ajout de created_by à la table users...');
  
  try {
    // Vérifier si la colonne existe déjà
    const columns = await sequelize.query(
      "PRAGMA table_info(users)",
      { type: QueryTypes.SELECT }
    );
    
    const hasCreatedBy = columns.some(col => col.name === 'created_by');
    
    if (hasCreatedBy) {
      console.log('✅ La colonne created_by existe déjà');
      return;
    }
    
    // Ajouter la colonne created_by
    await sequelize.query(`
      ALTER TABLE users 
      ADD COLUMN created_by INTEGER NULL
    `);
    
    console.log('✅ Colonne created_by ajoutée avec succès');
    
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error.message);
    throw error;
  }
}

async function down() {
  console.log('🔙 Rollback: Suppression de created_by...');
  
  try {
    // SQLite ne supporte pas DROP COLUMN directement
    // Il faudrait recréer la table sans cette colonne
    console.log('⚠️ SQLite ne supporte pas DROP COLUMN - migration manuelle nécessaire');
  } catch (error) {
    console.error('❌ Erreur lors du rollback:', error.message);
    throw error;
  }
}

// Exécution directe
if (require.main === module) {
  up()
    .then(() => {
      console.log('✅ Migration terminée');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration échouée:', error);
      process.exit(1);
    });
}

module.exports = { up, down };
