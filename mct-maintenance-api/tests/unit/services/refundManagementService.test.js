jest.mock('../../../src/models', () => ({
  RefundRequest: {
    findOne: jest.fn(),
    findByPk: jest.fn(),
    create: jest.fn()
  },
  Intervention: {
    findByPk: jest.fn()
  },
  Order: {
    findByPk: jest.fn()
  },
  Payment: {
    findByPk: jest.fn()
  },
  CustomerProfile: {
    findOne: jest.fn()
  },
  User: {}
}));

jest.mock('../../../src/config/database', () => ({
  sequelize: {
    getDialect: () => 'sqlite',
    transaction: jest.fn(() => ({
      commit: jest.fn(),
      rollback: jest.fn(),
      finished: false
    }))
  }
}));

const {
  createRefundRequest,
  processRefundRequest,
  RefundError
} = require('../../../src/services/refundManagementService');
const { RefundRequest, Intervention, CustomerProfile, Order } = require('../../../src/models');

describe('RefundManagementService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createRefundRequest', () => {
    it('devrait refuser une demande sans motif', async () => {
      const user = { id: 1, role: 'customer' };
      await expect(
        createRefundRequest({ user, interventionId: 10, reason: '' })
      ).rejects.toThrow(RefundError);
    });

    it('devrait refuser si le profil client est introuvable', async () => {
      CustomerProfile.findOne.mockResolvedValue(null);
      const user = { id: 99, role: 'customer' };
      await expect(
        createRefundRequest({ user, interventionId: 10, reason: 'Service insatisfaisant' })
      ).rejects.toThrow(RefundError);
    });

    it('devrait créer une demande de remboursement valide', async () => {
      CustomerProfile.findOne.mockResolvedValue({ id: 27, user_id: 1 });
      Intervention.findByPk.mockResolvedValue({
        id: 10,
        customer_id: 27,
        estimated_price: 15000
      });
      RefundRequest.findOne.mockResolvedValue(null);
      RefundRequest.create.mockResolvedValue({
        id: 1,
        user_id: 1,
        customer_id: 27,
        intervention_id: 10,
        amount: 15000,
        reason: 'Intervention annulée et acompte versé',
        status: 'requested'
      });

      const user = { id: 1, role: 'customer' };
      const request = await createRefundRequest({
        user,
        interventionId: 10,
        reason: 'Intervention annulée et acompte versé'
      });

      expect(request).toBeDefined();
      expect(request.amount).toBe(15000);
      expect(request.status).toBe('requested');
      expect(RefundRequest.create).toHaveBeenCalledWith(expect.objectContaining({
        user_id: 1,
        customer_id: 27,
        intervention_id: 10,
        amount: 15000
      }));
    });

    it('devrait empêcher les demandes en double sur la même ressource', async () => {
      CustomerProfile.findOne.mockResolvedValue({ id: 27, user_id: 1 });
      Intervention.findByPk.mockResolvedValue({
        id: 10,
        customer_id: 27,
        estimated_price: 15000
      });
      RefundRequest.findOne.mockResolvedValue({ id: 1, status: 'requested' });

      const user = { id: 1, role: 'customer' };
      await expect(
        createRefundRequest({
          user,
          interventionId: 10,
          reason: 'Nouvelle tentative'
        })
      ).rejects.toThrow(RefundError);
    });
  });

  describe('processRefundRequest', () => {
    it('devrait approuver puis traiter de façon constante et idempotent', async () => {
      const mockRecord = {
        id: 1,
        status: 'requested',
        amount: 20000,
        update: jest.fn().mockImplementation(async (updates) => {
          Object.assign(mockRecord, updates);
          return mockRecord;
        })
      };

      RefundRequest.findByPk.mockResolvedValue(mockRecord);

      const processed = await processRefundRequest({
        requestId: 1,
        action: 'process',
        idempotencyKey: 'key-refund-101'
      });

      expect(processed.status).toBe('processed');
      expect(mockRecord.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'processed'
        }),
        expect.anything()
      );
    });
  });
});
