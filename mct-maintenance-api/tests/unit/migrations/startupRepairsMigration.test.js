const { Sequelize, DataTypes, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260802_move_startup_repairs_to_versioned_migration');

describe('migration des anciennes réparations de démarrage', () => {
  let database;

  beforeEach(async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    const queryInterface = database.getQueryInterface();
    await queryInterface.createTable('subscriptions', {
      id: { type: DataTypes.INTEGER, primaryKey: true },
      price: { type: DataTypes.DECIMAL(10, 2) },
      payment_status: { type: DataTypes.STRING },
      first_payment_status: { type: DataTypes.STRING },
      second_payment_status: { type: DataTypes.STRING },
      status: { type: DataTypes.STRING }
    });
    await queryInterface.createTable('interventions', {
      id: { type: DataTypes.INTEGER, primaryKey: true },
      diagnostic_fee: { type: DataTypes.DECIMAL(10, 2) },
      diagnostic_paid: { type: DataTypes.BOOLEAN },
      is_free_diagnosis: { type: DataTypes.BOOLEAN },
      status: { type: DataTypes.STRING },
      customer_confirmed: { type: DataTypes.BOOLEAN }
    });
    await queryInterface.createTable('diagnostic_reports', {
      id: { type: DataTypes.INTEGER, primaryKey: true }
    });
  });

  afterEach(async () => {
    await database.close();
  });

  test('ajoute le schéma manquant et applique les corrections une seule fois', async () => {
    await database.query(`
      INSERT INTO subscriptions
        (id, price, payment_status, first_payment_status, second_payment_status, status)
      VALUES (1, 0, 'pending', 'pending', 'pending', 'pending_payment')
    `);
    await database.query(`
      INSERT INTO interventions
        (id, diagnostic_fee, diagnostic_paid, is_free_diagnosis, status, customer_confirmed)
      VALUES (1, 0, 0, 0, 'pending', 0)
    `);

    await migration.up(database.getQueryInterface(), Sequelize);
    await migration.up(database.getQueryInterface(), Sequelize);

    const interventionColumns = await database.getQueryInterface().describeTable('interventions');
    const reportColumns = await database.getQueryInterface().describeTable('diagnostic_reports');
    expect(interventionColumns).toEqual(expect.objectContaining({
      payment_option: expect.any(Object),
      total_price: expect.any(Object),
      second_payment_amount: expect.any(Object),
      second_payment_status: expect.any(Object)
    }));
    expect(reportColumns).toEqual(expect.objectContaining({
      equipments: expect.any(Object),
      materials_needed: expect.any(Object)
    }));

    const [subscription] = await database.query(
      'SELECT * FROM subscriptions WHERE id = 1',
      { type: QueryTypes.SELECT }
    );
    const [intervention] = await database.query(
      'SELECT * FROM interventions WHERE id = 1',
      { type: QueryTypes.SELECT }
    );
    expect(subscription).toEqual(expect.objectContaining({
      payment_status: 'paid',
      first_payment_status: 'paid',
      second_payment_status: 'paid',
      status: 'active'
    }));
    expect(intervention.diagnostic_paid).toBe(1);
    expect(intervention.is_free_diagnosis).toBe(1);
  });
});
