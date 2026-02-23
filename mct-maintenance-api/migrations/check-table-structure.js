/**
 * Vérifier la structure de la table users
 */

'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('📊 Vérification de la structure de la table users...\n');

    try {
      const tableDesc = await queryInterface.describeTable('users');
      
      console.log('Colonnes de la table users:');
      const columns = Object.entries(tableDesc).map(([name, info]) => ({
        name,
        type: info.type,
        nullable: info.allowNull ? 'YES' : 'NO',
        default: info.defaultValue || 'NULL',
        pk: info.primaryKey ? 'YES' : 'NO'
      }));
      console.table(columns);

      // Vérifier spécifiquement le champ email
      const emailCol = tableDesc.email;
      if (emailCol) {
        console.log('\n📧 Colonne email:');
        console.log('   Type:', emailCol.type);
        console.log('   Nullable:', emailCol.allowNull ? '✅ OUI' : '❌ NON');
        console.log('   Default:', emailCol.defaultValue || 'NULL');

        if (emailCol.allowNull) {
          console.log('\n✅ Email peut être NULL.');
        } else {
          console.log('\n⚠️  Email ne peut pas être NULL.');
        }
      }
    } catch (error) {
      console.error('❌ Erreur:', error);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('ℹ️  Pas de rollback pour une migration de vérification');
  }
};
