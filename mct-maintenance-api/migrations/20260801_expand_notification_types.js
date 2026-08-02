'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const dialect = queryInterface.sequelize.getDialect();
    if (dialect === 'postgres') {
      await queryInterface.sequelize.transaction(async (transaction) => {
        await queryInterface.sequelize.query(
          'ALTER TABLE "notifications" ALTER COLUMN "type" TYPE VARCHAR(64) USING "type"::text',
          { transaction }
        );
        await queryInterface.sequelize.query(
          'DROP TYPE IF EXISTS "enum_notifications_type"',
          { transaction }
        );
      });
      return;
    }

    await queryInterface.changeColumn('notifications', 'type', {
      type: Sequelize.STRING(64),
      allowNull: false
    });
  },

  async down() {
    throw new Error(
      'Migration non réversible automatiquement : vérifier les types existants avant de recréer un ENUM'
    );
  }
};
