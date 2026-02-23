const { sequelize } = require('../src/config/database');
const { QueryTypes } = require('sequelize');

async function addPaymentStatusToOrders() {
  try {
    console.log('🔄 Migration: Ajout du champ payment_status à la table orders...');

    // Vérifier si la colonne existe déjà
    const columns = await sequelize.query(
      `PRAGMA table_info(orders)`,
      { type: QueryTypes.SELECT }
    );

    const hasPaymentStatus = Array.isArray(columns) && columns.some(col => col.name === 'payment_status');

    if (hasPaymentStatus) {
      console.log('✅ La colonne payment_status existe déjà');
      return;
    }

    // Ajouter la colonne payment_status
    await sequelize.query(`
      ALTER TABLE orders 
      ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending';
    `);

    // Mettre à jour les commandes existantes avec status='completed' en 'paid'
    await sequelize.query(`
      UPDATE orders 
      SET payment_status = 'paid' 
      WHERE status = 'completed';
    `);

    console.log('✅ Migration terminée avec succès');
    console.log('   Colonne payment_status ajoutée à la table orders');
    console.log('   Commandes "completed" marquées comme "paid"');
  } catch (error) {
    console.error('❌ Erreur migration:', error);
    throw error;
  }
}

// Exécuter la migration
if (require.main === module) {
  addPaymentStatusToOrders()
    .then(() => {
      console.log('✅ Migration complète');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Échec migration:', error);
      process.exit(1);
    });
}

module.exports = addPaymentStatusToOrders;
