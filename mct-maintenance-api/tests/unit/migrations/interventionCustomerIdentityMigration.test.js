const { Sequelize, QueryTypes } = require('sequelize');
const migration = require('../../../migrations/20260801_unify_intervention_customer_identity');

describe('migration identité client des interventions', () => {
  let database;

  afterEach(async () => {
    if (database) await database.close();
    database = null;
  });

  test('refuse une collision User/Profile sans contrainte fournissant la source de vérité', () => {
    const plan = migration.buildBackfillPlan({
      interventionCustomerIds: [79],
      profiles: [
        { id: 79, user_id: 84 },
        { id: 74, user_id: 79 }
      ],
      users: [{ id: 79 }, { id: 84 }],
      referencedTable: null
    });

    expect(plan.updates).toEqual([]);
    expect(plan.errors).toEqual([{
      customerId: 79,
      reason: 'AMBIGUOUS_USER_PROFILE_COLLISION'
    }]);
  });

  test('conserve une collision numérique lorsque la FK canonique prouve un CustomerProfile.id', () => {
    const plan = migration.buildBackfillPlan({
      interventionCustomerIds: [79],
      profiles: [
        { id: 79, user_id: 84 },
        { id: 74, user_id: 79 }
      ],
      users: [{ id: 79 }, { id: 84 }],
      referencedTable: 'customer_profiles'
    });

    expect(plan).toEqual({ updates: [], errors: [] });
  });

  test('backfille une collision numérique lorsque la FK legacy prouve un User.id', () => {
    const plan = migration.buildBackfillPlan({
      interventionCustomerIds: [79],
      profiles: [
        { id: 79, user_id: 84 },
        { id: 74, user_id: 79 }
      ],
      users: [{ id: 79 }, { id: 84 }],
      referencedTable: 'users'
    });

    expect(plan).toEqual({
      updates: [{ from: 79, to: 74 }],
      errors: []
    });
  });

  test('backfille une correspondance User.id certaine puis crée la FK canonique', async () => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    const queryInterface = database.getQueryInterface();
    await queryInterface.createTable('users', {
      id: { type: Sequelize.INTEGER, primaryKey: true }
    });
    await queryInterface.createTable('customer_profiles', {
      id: { type: Sequelize.INTEGER, primaryKey: true },
      user_id: { type: Sequelize.INTEGER, allowNull: false, unique: true }
    });
    await queryInterface.createTable('interventions', {
      id: { type: Sequelize.INTEGER, primaryKey: true },
      customer_id: { type: Sequelize.INTEGER, allowNull: false }
    });
    await database.query('INSERT INTO users (id) VALUES (100)');
    await database.query('INSERT INTO customer_profiles (id, user_id) VALUES (5, 100)');
    await database.query('INSERT INTO interventions (id, customer_id) VALUES (1, 100)');

    await migration.up(queryInterface, Sequelize);

    const [row] = await database.query(
      'SELECT customer_id FROM interventions WHERE id = 1',
      { type: QueryTypes.SELECT }
    );
    expect(row.customer_id).toBe(5);
    const references = await queryInterface.getForeignKeyReferencesForTable('interventions');
    expect(references).toEqual(expect.arrayContaining([
      expect.objectContaining({
        columnName: 'customer_id',
        referencedTableName: 'customer_profiles'
      })
    ]));
  });
});
