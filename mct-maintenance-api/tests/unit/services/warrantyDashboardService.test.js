jest.mock('../../../src/models', () => ({
  Equipment: { findAll: jest.fn() },
  Intervention: { findAll: jest.fn() },
  Complaint: { findAll: jest.fn() },
  Subscription: { findAll: jest.fn() }
}));

const { Equipment, Intervention, Complaint, Subscription } = require('../../../src/models');
const { buildWarrantyDashboard } = require('../../../src/services/warrantyDashboardService');

describe('warrantyDashboardService', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    Equipment.findAll.mockResolvedValue([]);
    Intervention.findAll.mockResolvedValue([]);
    Complaint.findAll.mockResolvedValue([]);
    Subscription.findAll.mockResolvedValue([]);
  });

  it('doit retourner un dashboard vide si aucun équipement ni réclamation', async () => {
    const result = await buildWarrantyDashboard(1);

    expect(result.summary.total_equipments).toBe(0);
    expect(result.summary.warranties_active).toBe(0);
    expect(result.summary.open_complaints).toBe(0);
    expect(result.equipments).toEqual([]);
    expect(result.open_complaints).toEqual([]);
  });

  it('doit correctement catégoriser les statuts de garantie (active, expirée, expire bientôt)', async () => {
    const now = new Date();
    const futureDate = new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const soonDate = new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const pastDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    Equipment.findAll.mockResolvedValue([
      { id: 1, name: 'Climatiseur A', type: 'AC', brand: 'LG', warranty_expiry: futureDate, status: 'active' },
      { id: 2, name: 'Chauffe-eau B', type: 'Heater', brand: 'Ariston', warranty_expiry: soonDate, status: 'active' },
      { id: 3, name: 'Pompe C', type: 'Pump', brand: 'Pedrollo', warranty_expiry: pastDate, status: 'active' },
      { id: 4, name: 'Groupe D', type: 'Generator', brand: 'SDMO', warranty_expiry: null, status: 'active' }
    ]);

    const result = await buildWarrantyDashboard(1);

    expect(result.summary.total_equipments).toBe(4);
    expect(result.summary.warranties_active).toBe(1);
    expect(result.summary.warranties_expiring_soon).toBe(1);
    expect(result.summary.warranties_expired).toBe(1);

    expect(result.equipments[0].warranty_status).toBe('active');
    expect(result.equipments[1].warranty_status).toBe('expiring_soon');
    expect(result.equipments[2].warranty_status).toBe('expired');
    expect(result.equipments[3].warranty_status).toBe('unknown');
  });

  it('doit inclure les réclamations ouvertes et souscriptions actives', async () => {
    Complaint.findAll.mockResolvedValue([
      { id: 10, subject: 'Panne récurrente', status: 'pending', created_at: new Date() }
    ]);
    Subscription.findAll.mockResolvedValue([
      { id: 100, end_date: new Date(Date.now() + 15 * 86400000) }
    ]);

    const result = await buildWarrantyDashboard(1);

    expect(result.summary.open_complaints).toBe(1);
    expect(result.summary.active_subscriptions).toBe(1);
    expect(result.open_complaints[0].subject).toBe('Panne récurrente');
    expect(result.active_subscriptions[0].days_remaining).toBeGreaterThan(0);
  });
});
