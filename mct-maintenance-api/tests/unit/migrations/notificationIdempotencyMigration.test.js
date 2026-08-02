const { Sequelize, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_add_notification_idempotency');

describe('migration notifications idempotentes', () => {
  let database;

  beforeEach(async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    const queryInterface = database.getQueryInterface();
    await queryInterface.createTable('notifications', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      user_id: { type: Sequelize.INTEGER, allowNull: false },
      type: { type: Sequelize.STRING, allowNull: false },
      title: { type: Sequelize.STRING, allowNull: false },
      message: { type: Sequelize.TEXT, allowNull: false }
    });
    await migration.up(queryInterface, Sequelize);
  });

  afterEach(async () => database.close());

  test('autorise les anciennes lignes sans clé et interdit une clé dupliquée', async () => {
    const insert = (key) => database.query(`
      INSERT INTO notifications (user_id, type, title, message, dedupe_key)
      VALUES (1, 'general', 'Titre', 'Message', :key)
    `, { replacements: { key }, type: QueryTypes.INSERT });

    await insert(null);
    await insert(null);
    await insert('fineopay:TRX-1:customer-confirmation');
    await expect(insert('fineopay:TRX-1:customer-confirmation')).rejects.toThrow();
    await database.query(`
      INSERT INTO notifications (user_id, type, title, message, dedupe_key)
      VALUES (2, 'general', 'Titre', 'Message', 'fineopay:TRX-1:customer-confirmation')
    `, { type: QueryTypes.INSERT });
  });
});
