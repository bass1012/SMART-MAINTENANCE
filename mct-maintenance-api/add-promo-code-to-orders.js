const { sequelize } = require('./src/config/database');
const Order = require('./src/models/Order');

async function addPromoCodeColumns() {
  try {
    console.log('🔧 Ajout des colonnes promo_code à la table orders...');
    
    const queryInterface = sequelize.getQueryInterface();
    
    // Vérifier si les colonnes existent déjà
    const tableDescription = await queryInterface.describeTable('orders');
    
    if (!tableDescription.promo_code) {
      await queryInterface.addColumn('orders', 'promo_code', {
        type: sequelize.Sequelize.STRING,
        allowNull: true,
        after: 'tracking_url'
      });
      console.log('✅ Colonne promo_code ajoutée');
    } else {
      console.log('ℹ️  Colonne promo_code existe déjà');
    }
    
    if (!tableDescription.promo_discount) {
      await queryInterface.addColumn('orders', 'promo_discount', {
        type: sequelize.Sequelize.FLOAT,
        defaultValue: 0,
        allowNull: true,
        after: 'promo_code'
      });
      console.log('✅ Colonne promo_discount ajoutée');
    } else {
      console.log('ℹ️  Colonne promo_discount existe déjà');
    }
    
    if (!tableDescription.promo_id) {
      await queryInterface.addColumn('orders', 'promo_id', {
        type: sequelize.Sequelize.INTEGER,
        allowNull: true,
        after: 'promo_discount'
      });
      console.log('✅ Colonne promo_id ajoutée');
    } else {
      console.log('ℹ️  Colonne promo_id existe déjà');
    }
    
    console.log('✅ Migration des colonnes promo_code terminée avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  }
}

addPromoCodeColumns();
