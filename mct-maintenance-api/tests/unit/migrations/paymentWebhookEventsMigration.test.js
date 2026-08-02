const { Sequelize, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_create_payment_webhook_events');

describe('migration payment_webhook_events', () => {
  let database;

  beforeEach(async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    await migration.up(database.getQueryInterface(), Sequelize);
  });

  afterEach(async () => {
    await database.close();
  });

  test('crée le registre et interdit deux fois la même référence fournisseur', async () => {
    const insert = (syncRef) => database.query(`
      INSERT INTO payment_webhook_events (
        provider,
        provider_reference,
        sync_ref,
        payload_hash,
        status,
        attempt_count,
        processing_started_at,
        created_at,
        updated_at
      ) VALUES (
        'fineopay',
        'TRX-123',
        :syncRef,
        :payloadHash,
        'processing',
        1,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
    `, {
      replacements: { syncRef, payloadHash: 'a'.repeat(64) },
      type: QueryTypes.INSERT
    });

    await insert('ORDER_42');
    await expect(insert('ORDER_99')).rejects.toThrow();

    const rows = await database.query(
      'SELECT provider_reference, sync_ref FROM payment_webhook_events',
      { type: QueryTypes.SELECT }
    );
    expect(rows).toEqual([{ provider_reference: 'TRX-123', sync_ref: 'ORDER_42' }]);
  });
});
