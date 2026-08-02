const {
  canReadQuote,
  canReadOrder,
  canReadUserOwnedResource
} = require('../../../src/policies/resourceOwnershipPolicy');

describe('resourceOwnershipPolicy', () => {
  test('autorise uniquement le profil propriétaire du devis', async () => {
    const models = {
      CustomerProfile: {
        findOne: jest.fn().mockResolvedValue({ id: 17 })
      },
      Intervention: { findOne: jest.fn() }
    };

    await expect(canReadQuote({
      quote: { customerId: 17 },
      user: { id: 4, role: 'customer' },
      models
    })).resolves.toBe(true);
    await expect(canReadQuote({
      quote: { customerId: 18 },
      user: { id: 4, role: 'customer' },
      models
    })).resolves.toBe(false);
  });

  test('autorise le technicien seulement si le devis dépend de son intervention', async () => {
    const models = {
      CustomerProfile: { findOne: jest.fn() },
      Intervention: { findOne: jest.fn().mockResolvedValueOnce({ id: 8 }).mockResolvedValueOnce(null) }
    };
    const input = {
      quote: { intervention_id: 8 },
      user: { id: 12, role: 'technician' },
      models
    };

    await expect(canReadQuote(input)).resolves.toBe(true);
    await expect(canReadQuote(input)).resolves.toBe(false);
    expect(models.Intervention.findOne).toHaveBeenCalledWith({
      where: { id: 8, technician_id: 12 },
      attributes: ['id']
    });
  });

  test('compare les contrats et souscriptions uniquement à leur User.id propriétaire', () => {
    expect(canReadUserOwnedResource({
      resource: { customer_id: 7 },
      user: { id: 7, role: 'customer' }
    })).toBe(true);
    expect(canReadUserOwnedResource({
      resource: { customer_id: 8 },
      user: { id: 7, role: 'customer' }
    })).toBe(false);
    expect(canReadUserOwnedResource({
      resource: { customer_id: 8 },
      user: { id: 1, role: 'manager' }
    })).toBe(true);
  });

  test('résout le propriétaire d’une commande via CustomerProfile.id', async () => {
    const models = {
      CustomerProfile: { findOne: jest.fn().mockResolvedValue({ id: 17 }) }
    };
    await expect(canReadOrder({
      order: { customerId: 17 },
      user: { id: 7, role: 'customer' },
      models
    })).resolves.toBe(true);
    await expect(canReadOrder({
      order: { customerId: 18 },
      user: { id: 7, role: 'customer' },
      models
    })).resolves.toBe(false);
  });
});
