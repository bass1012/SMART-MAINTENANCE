const { Sequelize, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_create_outbox_events');

describe('migration outbox_events', () => {
  let database;

  beforeEach(async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    await migration.up(database.getQueryInterface(), Sequelize);
  });

  afterEach(async () => database.close());

  test('interdit deux effets avec la même clé d’idempotence', async () => {
    const insert = () => database.query(`
      INSERT INTO outbox_events (
        topic, aggregate_type, aggregate_id, idempotency_key, payload,
        status, attempts, available_at, created_at, updated_at
      ) VALUES (
        'payment.quote.confirmed', 'order', '42', 'fineopay:TRX-1:effects', '{}',
        'pending', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )
    `, { type: QueryTypes.INSERT });

    await insert();
    await expect(insert()).rejects.toThrow();
  });
});
