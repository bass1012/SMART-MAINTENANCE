const runMigrations = require('../../../scripts/migrate');

describe('moteur de migrations unique', () => {
  test('le mode status ne modifie pas le schéma métier', async () => {
    const database = {
      authenticate: jest.fn(),
      close: jest.fn(),
      query: jest.fn()
        .mockResolvedValueOnce([[], undefined])
        .mockResolvedValueOnce([[], undefined]),
      getQueryInterface: jest.fn()
    };

    const result = await runMigrations({
      database,
      statusOnly: true,
      closeConnection: false
    });

    expect(result.total).toBeGreaterThan(0);
    expect(result.pending).toHaveLength(result.total);
    expect(database.query).toHaveBeenCalledTimes(2);
    expect(database.query).not.toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO migration_history'),
      expect.anything()
    );
    expect(database.close).not.toHaveBeenCalled();
  });

  test('refuse un module qui ne respecte pas le contrat up/down', () => {
    expect(() => runMigrations.loadMigration('check-table-structure.js')).not.toThrow();
    expect(() => runMigrations.loadMigration('README.md')).toThrow();
  });
});
