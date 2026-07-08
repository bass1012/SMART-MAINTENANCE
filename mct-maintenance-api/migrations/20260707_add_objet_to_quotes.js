'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    try {
      // Check if column already exists to prevent errors during migration re-runs
      const tableInfo = await queryInterface.describeTable('quotes');
      if (!tableInfo.objet) {
        await queryInterface.addColumn('quotes', 'objet', {
          type: Sequelize.STRING,
          allowNull: true,
          defaultValue: 'Devis d\'entretien de climatisation'
        });
        console.log('✅ Colonne objet ajoutée à la table quotes');
      } else {
        console.log('✅ La colonne objet existe déjà dans la table quotes');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la migration add_objet_to_quotes:', error);
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    try {
      await queryInterface.removeColumn('quotes', 'objet');
      console.log('🔙 Colonne objet supprimée de la table quotes');
    } catch (error) {
      console.error('❌ Erreur lors du rollback add_objet_to_quotes:', error);
      throw error;
    }
  }
};
