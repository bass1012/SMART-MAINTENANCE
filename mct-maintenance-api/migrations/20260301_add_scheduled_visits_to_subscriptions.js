/**
 * Migration: Ajouter les champs de planification des visites aux souscriptions
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    console.log('🔄 Migration: Ajout des champs de planification des visites...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    // Ajouter visits_total
    if (!tableInfo.visits_total) {
      await queryInterface.addColumn('subscriptions', 'visits_total', {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 1
      });
      console.log('✅ Colonne visits_total ajoutée');
    } else {
      console.log('⏭️ Colonne visits_total existe déjà');
    }
    
    // Ajouter visits_completed
    if (!tableInfo.visits_completed) {
      await queryInterface.addColumn('subscriptions', 'visits_completed', {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0
      });
      console.log('✅ Colonne visits_completed ajoutée');
    } else {
      console.log('⏭️ Colonne visits_completed existe déjà');
    }
    
    // Ajouter visit_interval_months
    if (!tableInfo.visit_interval_months) {
      await queryInterface.addColumn('subscriptions', 'visit_interval_months', {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 3
      });
      console.log('✅ Colonne visit_interval_months ajoutée');
    } else {
      console.log('⏭️ Colonne visit_interval_months existe déjà');
    }
    
    // Ajouter next_visit_date
    if (!tableInfo.next_visit_date) {
      await queryInterface.addColumn('subscriptions', 'next_visit_date', {
        type: Sequelize.DATE,
        allowNull: true
      });
      console.log('✅ Colonne next_visit_date ajoutée');
    } else {
      console.log('⏭️ Colonne next_visit_date existe déjà');
    }
    
    // Ajouter first_intervention_date
    if (!tableInfo.first_intervention_date) {
      await queryInterface.addColumn('subscriptions', 'first_intervention_date', {
        type: Sequelize.DATE,
        allowNull: true
      });
      console.log('✅ Colonne first_intervention_date ajoutée');
    } else {
      console.log('⏭️ Colonne first_intervention_date existe déjà');
    }
    
    // Ajouter contract_type
    if (!tableInfo.contract_type) {
      await queryInterface.addColumn('subscriptions', 'contract_type', {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'on_demand'
      });
      console.log('✅ Colonne contract_type ajoutée');
    } else {
      console.log('⏭️ Colonne contract_type existe déjà');
    }
    
    console.log('✅ Migration terminée avec succès!');
  },

  async down(queryInterface, Sequelize) {
    console.log('🔄 Rollback: Suppression des champs de planification...');
    
    const tableInfo = await queryInterface.describeTable('subscriptions');
    
    const columnsToRemove = ['visits_total', 'visits_completed', 'visit_interval_months', 
                             'next_visit_date', 'first_intervention_date', 'contract_type'];
    
    for (const col of columnsToRemove) {
      if (tableInfo[col]) {
        await queryInterface.removeColumn('subscriptions', col);
        console.log(`✅ Colonne ${col} supprimée`);
      }
    }
    
    console.log('✅ Rollback terminé');
  }
};
