jest.mock('../../../src/models', () => {
  const model = {};
  return {
    MaintenanceSchedule: model,
    User: model,
    Intervention: { findOne: jest.fn(), findByPk: jest.fn() },
    CustomerProfile: { findOne: jest.fn() },
    Equipment: model,
    InterventionImage: model,
    MaintenanceOffer: model,
    RepairService: model,
    InstallationService: model,
    Subscription: model,
    DiagnosticReport: model,
    Quote: model,
    SystemConfig: model,
    Order: model,
    TechnicianProfile: model
  };
});

jest.mock('../../../src/config/database', () => ({
  sequelize: {}
}));

jest.mock('../../../src/config/multer', () => ({
  array: jest.fn(() => (req, res, next) => next())
}));

jest.mock('../../../src/services/notificationHelpers', () => ({}));
jest.mock('../../../src/services/notificationService', () => ({}));
jest.mock('../../../src/services/emailService', () => ({ sendEmail: jest.fn() }));
jest.mock('../../../src/services/emailHelper', () => ({}));
jest.mock('../../../src/services/schedulingService', () => ({}));
jest.mock('../../../src/services/contractSchedulingService', () => ({}));

const { Intervention, CustomerProfile } = require('../../../src/models');
const {
  getInterventionById,
  updateIntervention
} = require('../../../src/controllers/intervention/interventionController');

const createResponse = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
};

describe('getInterventionById authorization scope', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('retourne 404 à un client lorsque la ressource est hors de son périmètre', async () => {
    CustomerProfile.findOne.mockResolvedValue({ id: 27 });
    Intervention.findOne.mockResolvedValue(null);
    const req = {
      params: { id: '42' },
      user: { id: 11, role: 'customer' }
    };
    const res = createResponse();

    await getInterventionById(req, res);

    const query = Intervention.findOne.mock.calls[0][0];
    expect(query.where.id).toBe('42');
    expect(query.where.customer_id).toBe(27);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Intervention non trouvée'
    });
  });

  test('limite la requête d’un technicien à son identifiant', async () => {
    Intervention.findOne.mockResolvedValue(null);
    const req = {
      params: { id: '42' },
      user: { id: 9, role: 'technician' }
    };
    const res = createResponse();

    await getInterventionById(req, res);

    expect(Intervention.findOne.mock.calls[0][0].where).toEqual({
      id: '42',
      technician_id: 9
    });
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('autorise un manager à charger une intervention', async () => {
    const interventionData = { id: 42, diagnosticReports: [] };
    Intervention.findOne.mockResolvedValue({
      images: [],
      toJSON: () => ({ ...interventionData })
    });
    const req = {
      params: { id: '42' },
      user: { id: 2, role: 'manager' }
    };
    const res = createResponse();

    await getInterventionById(req, res);

    expect(Intervention.findOne.mock.calls[0][0].where).toEqual({ id: '42' });
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: {
        ...interventionData,
        intervention_images: [],
        report_images: []
      }
    });
  });

  test('refuse un rôle hors périmètre avant toute lecture en base', async () => {
    const req = {
      params: { id: '42' },
      user: { id: 3, role: 'depannage' }
    };
    const res = createResponse();

    await getInterventionById(req, res);

    expect(Intervention.findOne).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('updateIntervention customer identity', () => {
  beforeEach(() => jest.clearAllMocks());

  test('retire les deux variantes de customer_id du payload générique', async () => {
    const current = {
      status: 'pending',
      update: jest.fn().mockResolvedValue(undefined)
    };
    Intervention.findByPk
      .mockResolvedValueOnce(current)
      .mockResolvedValueOnce({ id: 42, customer: null });
    const req = {
      params: { id: '42' },
      body: {
        customer_id: 99,
        customerId: 100,
        title: 'Titre légitime',
        priority: 'high'
      }
    };
    const res = createResponse();

    await updateIntervention(req, res);

    expect(current.update).toHaveBeenCalledWith({
      title: 'Titre légitime',
      priority: 'high'
    });
    expect(res.status).toHaveBeenCalledWith(200);
  });
});
