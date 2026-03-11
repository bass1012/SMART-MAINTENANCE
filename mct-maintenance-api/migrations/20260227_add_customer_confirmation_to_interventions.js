/**
 * Migration pour ajouter les champs de confirmation client aux interventions
 * Le client doit confirmer que le technicien a bien terminé l'intervention après réception du rapport
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('🔄 Ajout des champs de confirmation client aux interventions...');
    
    // Vérifier si les colonnes existent déjà
    const tableInfo = await queryInterface.describeTable('interventions');
    
    if (!tableInfo.customer_confirmed) {
      await queryInterface.addColumn('interventions', 'customer_confirmed', {
        type: Sequelize.BOOLEAN,
        allowNull: true,
        defaultValue: false
      });
      console.log('✅ Colonne customer_confirmed ajoutée');
    } else {
      console.log('⏭️ Colonne customer_confirmed existe déjà');
    }
    
    if (!tableInfo.customer_confirmed_at) {
      await queryInterface.addColumn('interventions', 'customer_confirmed_at', {
        type: Sequelize.DATE,
        allowNull: true
      });
      console.log('✅ Colonne customer_confirmed_at ajoutée');
    } else {
      console.log('⏭️ Colonne customer_confirmed_at existe déjà');
    }
    
    if (!tableInfo.customer_rejection_reason) {
      await queryInterface.addColumn('interventions', 'customer_rejection_reason', {
        type: Sequelize.TEXT,
        allowNull: true
      });
      console.log('✅ Colonne customer_rejection_reason ajoutée');
    } else {
      console.log('⏭️ Colonne customer_rejection_reason existe déjà');
    }
    
    console.log('✅ Migration terminée avec succès');
  },

  async down(queryInterface, Sequelize) {
    console.log('🔄 Suppression des champs de confirmation client...');
    
    const tableInfo = await queryInterface.describeTable('interventions');
    
    if (tableInfo.customer_confirmed) {
      await queryInterface.removeColumn('interventions', 'customer_confirmed');
    }
    if (tableInfo.customer_confirmed_at) {
      await queryInterface.removeColumn('interventions', 'customer_confirmed_at');
    }
    if (tableInfo.customer_rejection_reason) {
      await queryInterface.removeColumn('interventions', 'customer_rejection_reason');
    }
    
    console.log('✅ Rollback terminé');
  }
};
