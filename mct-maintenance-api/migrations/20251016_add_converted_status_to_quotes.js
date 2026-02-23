'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // SQLite ne supporte pas MODIFY COLUMN
    // Les valeurs ENUM sont gérées au niveau de l'application
    // Aucune modification de schéma nécessaire pour ajouter une valeur ENUM en SQLite
    console.log('✅ Status "converted" disponible pour quotes (géré par l\'application)');
  },

  async down(queryInterface, Sequelize) {
    // Pas de rollback nécessaire
    console.log('✅ Migration rollback (aucune action nécessaire pour SQLite)');
  }
};
