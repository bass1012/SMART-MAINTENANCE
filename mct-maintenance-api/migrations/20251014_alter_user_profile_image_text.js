module.exports = {
  up: async (queryInterface, Sequelize) => {
    // SQLite ne supporte pas ALTER COLUMN, donc on doit recréer la colonne
    // On va renommer l'ancienne colonne, en créer une nouvelle, copier les données, puis supprimer l'ancienne
    try {
      await queryInterface.describeTable('users');
    } catch (err) {
      console.warn('Skipping alter users.profile_image: table not found.');
      return;
    }
    await queryInterface.sequelize.transaction(async (transaction) => {
      await queryInterface.renameColumn('users', 'profile_image', 'profile_image_old', { transaction });
      await queryInterface.addColumn('users', 'profile_image', {
        type: Sequelize.TEXT,
        allowNull: true
      }, { transaction });
      await queryInterface.sequelize.query(
        'UPDATE users SET profile_image = profile_image_old',
        { transaction }
      );
      await queryInterface.removeColumn('users', 'profile_image_old', { transaction });
    });
  },
  down: async (queryInterface, Sequelize) => {
    // Pour revenir en arrière, repasser à VARCHAR(255)
    try {
      await queryInterface.describeTable('users');
    } catch (err) {
      console.warn('Skipping rollback alter users.profile_image: table not found.');
      return;
    }
    await queryInterface.sequelize.transaction(async (transaction) => {
      await queryInterface.renameColumn('users', 'profile_image', 'profile_image_old', { transaction });
      await queryInterface.addColumn('users', 'profile_image', {
        type: Sequelize.STRING(255),
        allowNull: true
      }, { transaction });
      await queryInterface.sequelize.query(
        'UPDATE users SET profile_image = profile_image_old',
        { transaction }
      );
      await queryInterface.removeColumn('users', 'profile_image_old', { transaction });
    });
  }
};