const { DataTypes } = require('sequelize');

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('📝 Adding installation_service_id and repair_service_id to subscriptions table...');
    
    // Vérifier si les colonnes existent déjà
    const tableDesc = await queryInterface.describeTable('subscriptions');
    
    // Ne pas modifier maintenance_offer_id car SQLite ne supporte pas bien changeColumn avec FK
    // Le modèle Sequelize le gère comme nullable au niveau application
    console.log('ℹ️ maintenance_offer_id will be handled as nullable at the application level');
    
    // Ajouter installation_service_id (sans FK pour SQLite)
    if (!tableDesc.installation_service_id) {
      await queryInterface.addColumn('subscriptions', 'installation_service_id', {
        type: DataTypes.INTEGER,
        allowNull: true
      });
      console.log('✅ installation_service_id column added');
    } else {
      console.log('⚠️ installation_service_id already exists');
    }
    
    // Ajouter repair_service_id (sans FK pour SQLite)
    if (!tableDesc.repair_service_id) {
      await queryInterface.addColumn('subscriptions', 'repair_service_id', {
        type: DataTypes.INTEGER,
        allowNull: true
      });
      console.log('✅ repair_service_id column added');
    } else {
      console.log('⚠️ repair_service_id already exists');
    }
    
    console.log('✅ Migration completed successfully!');
    console.log('ℹ️ Note: Foreign key constraints are managed at the application level for SQLite compatibility');
  },

  down: async (queryInterface, Sequelize) => {
    console.log('📝 Reverting changes to subscriptions table...');
    
    const tableDesc = await queryInterface.describeTable('subscriptions');
    
    // Supprimer repair_service_id
    if (tableDesc.repair_service_id) {
      await queryInterface.removeColumn('subscriptions', 'repair_service_id');
      console.log('✅ repair_service_id column removed');
    }
    
    // Supprimer installation_service_id
    if (tableDesc.installation_service_id) {
      await queryInterface.removeColumn('subscriptions', 'installation_service_id');
      console.log('✅ installation_service_id column removed');
    }
    
    console.log('✅ Rollback completed successfully!');
  }
};
