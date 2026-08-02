const { Sequelize, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_expand_notification_types');

describe('migration types de notification extensibles', () => {
  let database;

  afterEach(async () => {
    if (database) await database.close();
    database = null;
  });

  test('accepte sous SQLite un type utilisé par les parcours FineoPay', async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    const queryInterface = database.getQueryInterface();
    await queryInterface.createTable('notifications', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      type: {
        type: Sequelize.ENUM('general', 'payment_received'),
        allowNull: false
      }
    });

    await migration.up(queryInterface, Sequelize);
    await database.query(
      'INSERT INTO notifications (type) VALUES (:type)',
      { replacements: { type: 'technician_search' }, type: QueryTypes.INSERT }
    );
    const [row] = await database.query(
      'SELECT type FROM notifications LIMIT 1',
      { type: QueryTypes.SELECT }
    );
    expect(row.type).toBe('technician_search');
  });

  test('convertit explicitement l’ENUM PostgreSQL puis supprime son type devenu inutile', async () => {
    const query = jest.fn().mockResolvedValue(undefined);
    const transaction = { id: 'tx' };
    const sequelize = {
      getDialect: jest.fn(() => 'postgres'),
      transaction: jest.fn(async (callback) => callback(transaction)),
      query
    };

    await migration.up({ sequelize }, Sequelize);

    expect(query).toHaveBeenNthCalledWith(
      1,
      expect.stringContaining('TYPE VARCHAR(64) USING "type"::text'),
      { transaction }
    );
    expect(query).toHaveBeenNthCalledWith(
      2,
      expect.stringContaining('DROP TYPE IF EXISTS'),
      { transaction }
    );
  });
});
