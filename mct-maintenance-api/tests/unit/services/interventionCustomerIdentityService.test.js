jest.mock('../../../src/models', () => ({
  CustomerProfile: { findOne: jest.fn(), findByPk: jest.fn() }
}));

const { CustomerProfile } = require('../../../src/models');
const {
  resolveInterventionCustomerProfile
} = require('../../../src/services/interventionCustomerIdentityService');

describe('interventionCustomerIdentityService', () => {
  beforeEach(() => jest.clearAllMocks());

  test('ignore un identifiant fourni par le client et résout son propre profil', async () => {
    CustomerProfile.findOne.mockResolvedValue({ id: 27, user_id: 11 });

    await expect(resolveInterventionCustomerProfile({
      user: { id: 11, role: 'customer' },
      requestedCustomerId: 99
    })).resolves.toEqual({ id: 27, user_id: 11 });

    expect(CustomerProfile.findOne).toHaveBeenCalledWith({
      where: { user_id: 11 },
      transaction: undefined
    });
    expect(CustomerProfile.findByPk).not.toHaveBeenCalled();
  });

  test('exige explicitement un CustomerProfile.id pour un rôle interne', async () => {
    CustomerProfile.findByPk.mockResolvedValue({ id: 27, user_id: 11 });

    await resolveInterventionCustomerProfile({
      user: { id: 1, role: 'admin' },
      requestedCustomerId: 27
    });

    expect(CustomerProfile.findByPk).toHaveBeenCalledWith(27, {
      transaction: undefined
    });
    expect(CustomerProfile.findOne).not.toHaveBeenCalled();
  });

  test('refuse un technicien et un profil inexistant', async () => {
    await expect(resolveInterventionCustomerProfile({
      user: { id: 9, role: 'technician' },
      requestedCustomerId: 27
    })).rejects.toEqual(expect.objectContaining({ statusCode: 403 }));

    CustomerProfile.findByPk.mockResolvedValue(null);
    await expect(resolveInterventionCustomerProfile({
      user: { id: 1, role: 'manager' },
      requestedCustomerId: 999
    })).rejects.toEqual(expect.objectContaining({
      statusCode: 400,
      code: 'CUSTOMER_PROFILE_NOT_FOUND'
    }));
  });
});
