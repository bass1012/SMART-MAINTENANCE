jest.mock('../../../src/models', () => ({
  Intervention: { findAll: jest.fn() },
  Order: { findAll: jest.fn() },
  Quote: { findAll: jest.fn() },
  CustomerProfile: { findAll: jest.fn() },
  TechnicianProfile: { findAll: jest.fn() },
  Subscription: { findAll: jest.fn() },
  RefundRequest: { findAll: jest.fn() }
}));

const { Intervention, Order, Quote, Subscription, RefundRequest } = require('../../../src/models');
const { buildOperationalAlerts } = require('../../../src/services/operationalCockpitService');

describe('operationalCockpitService', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    Order.findAll.mockResolvedValue([]);
    Intervention.findAll.mockResolvedValue([]);
    Quote.findAll.mockResolvedValue([]);
    Subscription.findAll.mockResolvedValue([]);
    RefundRequest.findAll.mockResolvedValue([]);
  });

  it('doit retourner un cockpit vide sans alertes', async () => {
    const result = await buildOperationalAlerts();

    expect(result.summary.total_alerts).toBe(0);
    expect(result.alerts.failed_payments.severity).toBe('ok');
    expect(result.alerts.unassigned_interventions.severity).toBe('ok');
    expect(result.alerts.late_interventions.severity).toBe('ok');
    expect(result.alerts.expired_quotes.severity).toBe('ok');
    expect(result.alerts.near_expiry_contracts.severity).toBe('ok');
    expect(result.alerts.pending_refunds.severity).toBe('ok');
    expect(result.alerts.pending_diagnostic_payments.severity).toBe('ok');
  });

  it('doit signaler des paiements échoués comme critiques', async () => {
    Order.findAll.mockResolvedValueOnce([
      { id: 1, reference: 'CMD-1', total_amount: 50000, payment_status: 'failed', created_at: new Date() }
    ]);

    const result = await buildOperationalAlerts();

    expect(result.summary.total_alerts).toBe(1);
    expect(result.alerts.failed_payments.count).toBe(1);
    expect(result.alerts.failed_payments.severity).toBe('critical');
    expect(result.alerts.failed_payments.items[0].reference).toBe('CMD-1');
  });

  it('doit signaler les interventions non assignées comme critiques', async () => {
    Order.findAll.mockResolvedValue([]);
    // First Intervention.findAll call = unassigned
    Intervention.findAll
      .mockResolvedValueOnce([
        { id: 10, title: 'Fuite clim', priority: 'high', scheduled_date: new Date(), created_at: new Date() }
      ])
      .mockResolvedValue([]);

    const result = await buildOperationalAlerts();

    expect(result.alerts.unassigned_interventions.count).toBe(1);
    expect(result.alerts.unassigned_interventions.severity).toBe('critical');
  });

  it('doit comptabiliser les remboursements en attente', async () => {
    RefundRequest.findAll.mockResolvedValue([
      { id: 5, amount: 15000, reason: 'Intervention annulée', created_at: new Date() }
    ]);

    const result = await buildOperationalAlerts();

    expect(result.alerts.pending_refunds.count).toBe(1);
    expect(result.alerts.pending_refunds.severity).toBe('warning');
    expect(result.summary.total_alerts).toBe(1);
  });
});
