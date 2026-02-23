const { sequelize } = require('../src/config/database');
const { QueryTypes } = require('sequelize');

async function addTrackingUrlToOrders() {
  try {
    console.log('🔄 Migration: Ajout du champ tracking_url à la table orders...');

    // Vérifier si la colonne existe déjà
    const columns = await sequelize.query(
      `PRAGMA table_info(orders)`,
      { type: QueryTypes.SELECT }
    );

    const hasTrackingUrl = Array.isArray(columns) && columns.some(col => col.name === 'tracking_url');

    if (hasTrackingUrl) {
      console.log('✅ La colonne tracking_url existe déjà');
      return;
    }

    // Ajouter la colonne tracking_url
    await sequelize.query(`
      ALTER TABLE orders 
      ADD COLUMN tracking_url VARCHAR(500);
    `);

    console.log('✅ Migration terminée avec succès');
    console.log('   Colonne tracking_url ajoutée à la table orders');
  } catch (error) {
    console.error('❌ Erreur migration:', error);
    throw error;
  }
}

// Exécuter la migration
if (require.main === module) {
  addTrackingUrlToOrders()
    .then(() => {
      console.log('✅ Migration complète');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Échec migration:', error);
      process.exit(1);
    });
}

module.exports = addTrackingUrlToOrders;
