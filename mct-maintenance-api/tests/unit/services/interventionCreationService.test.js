jest.mock('../../../src/models', () => ({
  Subscription: {
    findOne: jest.fn()
  },
  SystemConfig: {
    findOne: jest.fn()
  }
}));

const { Subscription, SystemConfig } = require('../../../src/models');
const InterventionCreationService = require('../../../src/services/interventionCreationService');

describe('InterventionCreationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('devrait marquer un diagnostic payant comme pending_payment', async () => {
    SystemConfig.findOne.mockResolvedValue({ value: '10000' });

    const result = await InterventionCreationService.calculateDiagnosticFeeAndStatus({
      interventionData: { intervention_type: 'diagnostic' },
      customerUserId: 1,
      actualCustomerId: 2
    });

    expect(result.isFreeDiagnosis).toBe(false);
    expect(result.diagnosticFee).toBe(10000);
    expect(result.initialStatus).toBe('pending_payment');
    expect(result.diagnosticPaid).toBe(false);
  });

  it('devrait couvrir un entretien par souscription active si équipement disponible', async () => {
    Subscription.findOne.mockResolvedValue({
      equipment_count: 5,
      equipment_used: 1
    });

    const result = await InterventionCreationService.calculateDiagnosticFeeAndStatus({
      interventionData: { intervention_type: 'entretien', maintenance_offer_id: 3, equipment_count: 2 },
      customerUserId: 1,
      actualCustomerId: 2
    });

    expect(result.hasActiveSubscription).toBe(true);
    expect(result.equipmentCoveredBySubscription).toBe(2);
    expect(result.equipmentToPay).toBe(0);
    expect(result.isFreeDiagnosis).toBe(true);
    expect(result.initialStatus).toBe('pending');
    expect(result.diagnosticPaid).toBe(true);
  });
});
