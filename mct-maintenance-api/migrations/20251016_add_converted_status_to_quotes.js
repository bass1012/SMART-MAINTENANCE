'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Modifier le type ENUM pour ajouter 'converted'
    await queryInterface.sequelize.query(`
      ALTER TABLE quotes 
      MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'draft';
    `);
    
    console.log('✅ Colonne status de quotes modifiée avec succès');
  },

  async down(queryInterface, Sequelize) {
    // Revenir à l'ancienne définition
    await queryInterface.sequelize.query(`
      ALTER TABLE quotes 
      MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'draft';
    `);
  }
};
