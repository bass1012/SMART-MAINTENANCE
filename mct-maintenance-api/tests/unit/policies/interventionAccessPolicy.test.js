jest.mock('../../../src/models', () => ({
  CustomerProfile: {
    findOne: jest.fn()
  }
}));

const { CustomerProfile } = require('../../../src/models');
const {
  buildInterventionReadWhere,
  InterventionAccessDeniedError
} = require('../../../src/policies/interventionAccessPolicy');

describe('buildInterventionReadWhere', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test.each(['admin', 'manager'])('autorise le rôle interne %s', async (role) => {
    await expect(buildInterventionReadWhere({
      interventionId: '42',
      user: { id: 7, role }
    })).resolves.toEqual({ id: '42' });

    expect(CustomerProfile.findOne).not.toHaveBeenCalled();
  });

  test('limite un technicien à ses interventions assignées', async () => {
    await expect(buildInterventionReadWhere({
      interventionId: '42',
      user: { id: 9, role: 'technician' }
    })).resolves.toEqual({
      id: '42',
      technician_id: 9
    });
  });

  test('limite le client à son seul CustomerProfile.id', async () => {
    CustomerProfile.findOne.mockResolvedValue({ id: 27 });

    const where = await buildInterventionReadWhere({
      interventionId: '42',
      user: { id: 11, role: 'customer' }
    });

    expect(CustomerProfile.findOne).toHaveBeenCalledWith({
      where: { user_id: 11 },
      attributes: ['id']
    });
    expect(where).toEqual({ id: '42', customer_id: 27 });
  });

  test('utilise un périmètre impossible si le profil client est absent', async () => {
    CustomerProfile.findOne.mockResolvedValue(null);

    const where = await buildInterventionReadWhere({
      interventionId: '42',
      user: { id: 11, role: 'customer' }
    });

    expect(where.customer_id).toBe(-1);
  });

  test.each([
    null,
    { id: 3, role: 'depannage' },
    { id: 3, role: 'unknown' }
  ])('refuse un utilisateur hors périmètre %#', async (user) => {
    await expect(buildInterventionReadWhere({
      interventionId: '42',
      user
    })).rejects.toBeInstanceOf(InterventionAccessDeniedError);
  });
});
