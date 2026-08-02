const { Sequelize, DataTypes, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_harden_payments_ledger');

const createLegacySchema = async (database) => {
  const queryInterface = database.getQueryInterface();
  await queryInterface.createTable('interventions', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true }
  });
  await queryInterface.createTable('payments', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    order_id: { type: DataTypes.INTEGER, allowNull: true },
    amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    provider: { type: DataTypes.STRING(32), allowNull: false },
    payment_id: { type: DataTypes.STRING(255), allowNull: true },
    status: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'pending' }
  });
  await queryInterface.createTable('payment_logs', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    event_type: { type: DataTypes.STRING(64), allowNull: false }
  });
};

describe('migration de durcissement du registre payments', () => {
  let database;

  beforeEach(async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    await createLegacySchema(database);
  });

  afterEach(async () => {
    await database.close();
  });

  test('ajoute les champs FineoPay et impose l’unicité fournisseur/référence', async () => {
    await migration.up(database.getQueryInterface(), Sequelize);

    const columns = await database.getQueryInterface().describeTable('payments');
    expect(columns).toEqual(expect.objectContaining({
      intervention_id: expect.any(Object),
      payment_step: expect.any(Object),
      purpose: expect.any(Object),
      sync_ref: expect.any(Object),
      gateway_checkout_id: expect.any(Object),
      verified_at: expect.any(Object)
    }));

    const insert = () => database.query(`
      INSERT INTO payments (
        intervention_id,
        amount,
        provider,
        payment_id,
        status,
        payment_step,
        purpose,
        sync_ref
      ) VALUES (NULL, 10000, 'fineopay', 'TRX-123', 'succeeded', 1, 'diagnostic', 'DIAGNOSTIC_42')
    `, { type: QueryTypes.INSERT });

    await insert();
    await expect(insert()).rejects.toThrow();
  });

  test('interrompt la migration sans supprimer les doublons historiques', async () => {
    await database.query(`
      INSERT INTO payments (amount, provider, payment_id, status)
      VALUES
        (10000, 'fineopay', 'TRX-DUP', 'completed'),
        (10000, 'fineopay', 'TRX-DUP', 'completed')
    `);

    await expect(
      migration.up(database.getQueryInterface(), Sequelize)
    ).rejects.toThrow('Rapprochement manuel requis');

    const rows = await database.query(
      "SELECT COUNT(*) AS count FROM payments WHERE payment_id = 'TRX-DUP'",
      { type: QueryTypes.SELECT }
    );
    expect(Number(rows[0].count)).toBe(2);
  });

  test('retire et restaure le default avant la conversion PostgreSQL du statut', async () => {
    const queries = [];
    const queryInterface = {
      describeTable: jest.fn()
        .mockResolvedValueOnce({ provider: {}, status: {} })
        .mockResolvedValueOnce({ event_type: {} }),
      sequelize: {
        getDialect: jest.fn(() => 'postgres'),
        query: jest.fn(async (sql) => {
          queries.push(sql.trim());
          return sql.includes('HAVING COUNT(*) > 1') ? [[], undefined] : [[], undefined];
        })
      },
      addColumn: jest.fn().mockResolvedValue(undefined),
      showIndex: jest.fn().mockResolvedValue([{ name: 'payments_provider_payment_id_uq' }])
    };

    await migration.up(queryInterface, Sequelize);

    const dropDefault = queries.findIndex((sql) => sql.includes('status" DROP DEFAULT'));
    const changeType = queries.findIndex((sql) => sql.includes('status" TYPE VARCHAR'));
    const setDefault = queries.findIndex((sql) => sql.includes("status\" SET DEFAULT 'pending'"));
    expect(dropDefault).toBeGreaterThan(-1);
    expect(changeType).toBeGreaterThan(dropDefault);
    expect(setDefault).toBeGreaterThan(changeType);
  });
});
