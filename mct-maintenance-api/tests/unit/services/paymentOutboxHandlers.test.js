jest.mock('../../../src/services/notificationService', () => ({
  create: jest.fn(),
  notifyAdmins: jest.fn()
}));

const {
  handleShopPaymentConfirmed,
  handleDiagnosticPaymentConfirmed,
  handleSubscriptionPaymentConfirmed,
  handleQuotePaymentConfirmed
} = require('../../../src/services/outboxHandlers/paymentHandlers');

describe('handlers outbox paiement', () => {
  test('notifie client et admins avec des clés de déduplication stables', async () => {
    const notifications = { create: jest.fn(), notifyAdmins: jest.fn() };
    const models = {
      Order: { findByPk: jest.fn().mockResolvedValue({ id: 42, customerId: 9 }) },
      CustomerProfile: {
        findByPk: jest.fn().mockResolvedValue({
          id: 9, user_id: 7, first_name: 'Awa', last_name: 'Koné'
        })
      }
    };

    await handleShopPaymentConfirmed(
      { orderId: 42, reference: 'TRX-SHOP', amount: 10000 },
      { idempotencyKey: 'fineopay:TRX-SHOP:shop-notifications' },
      { models, notifications }
    );

    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      userId: 7,
      idempotencyKey: 'fineopay:TRX-SHOP:shop-notifications:customer'
    }));
    expect(notifications.notifyAdmins).toHaveBeenCalledWith(expect.objectContaining({
      idempotencyKey: 'fineopay:TRX-SHOP:shop-notifications:admins'
    }));
  });

  test('échoue avant tout envoi si le destinataire métier est incohérent', async () => {
    const notifications = { create: jest.fn(), notifyAdmins: jest.fn() };
    const models = {
      Order: { findByPk: jest.fn().mockResolvedValue({ id: 42, customerId: 9 }) },
      CustomerProfile: { findByPk: jest.fn().mockResolvedValue(null) }
    };

    await expect(handleShopPaymentConfirmed(
      { orderId: 42, reference: 'TRX-SHOP', amount: 10000 },
      { idempotencyKey: 'fineopay:TRX-SHOP:shop-notifications' },
      { models, notifications }
    )).rejects.toThrow('Client de la commande');
    expect(notifications.create).not.toHaveBeenCalled();
    expect(notifications.notifyAdmins).not.toHaveBeenCalled();
  });

  test('assigne uniquement au premier paiement diagnostic puis notifie avec déduplication', async () => {
    const notifications = {
      create: jest.fn().mockResolvedValue({ id: 1 }),
      notifyAdmins: jest.fn().mockResolvedValue([])
    };
    const scheduler = {
      autoAssignIntervention: jest.fn().mockResolvedValue({
        assigned_technician: { id: 12, name: 'Moussa Traoré' }
      })
    };
    const intervention = {
      id: 8,
      technician_id: null,
      customer: {
        id: 9,
        first_name: 'Awa',
        last_name: 'Koné',
        user: { id: 7 }
      }
    };
    const models = {
      Intervention: { findByPk: jest.fn().mockResolvedValue(intervention) },
      CustomerProfile: {},
      User: {}
    };

    await handleDiagnosticPaymentConfirmed(
      { interventionId: 8, reference: 'TRX-DIAG', amount: 5000, paymentStep: 1 },
      { idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects' },
      { models, notifications, scheduler }
    );

    expect(scheduler.autoAssignIntervention).toHaveBeenCalledWith(8, {
      sendNotifications: false
    });
    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      userId: 12,
      type: 'intervention_assigned',
      idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects:assignment-technician'
    }));
    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      userId: 7,
      type: 'diagnostic_payment_confirmed',
      idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects:customer-confirmation'
    }));
    expect(notifications.notifyAdmins).toHaveBeenCalledWith(expect.objectContaining({
      idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects:admins'
    }));
  });

  test('une panne d’assignation informe la recherche sans transformer le paiement en échec', async () => {
    const notifications = {
      create: jest.fn().mockResolvedValue({ id: 1 }),
      notifyAdmins: jest.fn().mockResolvedValue([])
    };
    const scheduler = {
      autoAssignIntervention: jest.fn().mockRejectedValue(new Error('Aucun technicien disponible trouvé'))
    };
    const models = {
      Intervention: {
        findByPk: jest.fn().mockResolvedValue({
          id: 8,
          technician_id: null,
          customer: { id: 9, first_name: 'Awa', last_name: 'Koné', user: { id: 7 } }
        })
      },
      CustomerProfile: {},
      User: {}
    };

    await handleDiagnosticPaymentConfirmed(
      { interventionId: 8, reference: 'TRX-DIAG', amount: 5000, paymentStep: 1 },
      { idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects' },
      { models, notifications, scheduler }
    );

    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      type: 'technician_search',
      idempotencyKey: 'fineopay:TRX-DIAG:diagnostic-effects:technician-search'
    }));
    expect(notifications.create).not.toHaveBeenCalledWith(expect.objectContaining({
      type: 'diagnostic_payment_failed'
    }));
  });

  test('le paiement du solde diagnostic ne relance pas l’assignation', async () => {
    const notifications = { create: jest.fn(), notifyAdmins: jest.fn() };
    const scheduler = { autoAssignIntervention: jest.fn() };
    const models = {
      Intervention: {
        findByPk: jest.fn().mockResolvedValue({
          id: 8,
          technician_id: 12,
          customer: { id: 9, first_name: 'Awa', last_name: 'Koné', user: { id: 7 } }
        })
      },
      CustomerProfile: {},
      User: {}
    };

    await handleDiagnosticPaymentConfirmed(
      { interventionId: 8, reference: 'TRX-DIAG-2', amount: 5000, paymentStep: 2 },
      { idempotencyKey: 'fineopay:TRX-DIAG-2:diagnostic-effects' },
      { models, notifications, scheduler }
    );

    expect(scheduler.autoAssignIntervention).not.toHaveBeenCalled();
    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      title: '✅ Solde confirmé',
      data: expect.objectContaining({ payment_step: 2 })
    }));
  });

  test('active un contrat programmé et notifie via des clés idempotentes', async () => {
    const notifications = { create: jest.fn(), notifyAdmins: jest.fn() };
    const contractScheduler = { activateContractAfterPayment: jest.fn() };
    const models = {
      Subscription: {
        findByPk: jest.fn().mockResolvedValue({
          id: 5,
          customer_id: 7,
          contract_type: 'scheduled',
          customer: { id: 7, first_name: 'Awa', last_name: 'Koné' }
        })
      },
      User: {}
    };

    await handleSubscriptionPaymentConfirmed(
      { subscriptionId: 5, reference: 'TRX-SUB', amount: 5000, paymentStep: 1 },
      { idempotencyKey: 'fineopay:TRX-SUB:subscription-effects' },
      { models, notifications, contractScheduler }
    );

    expect(contractScheduler.activateContractAfterPayment).toHaveBeenCalledWith(5, 'TRX-SUB');
    expect(notifications.notifyAdmins).toHaveBeenCalledWith(expect.objectContaining({
      idempotencyKey: 'fineopay:TRX-SUB:subscription-effects:admins'
    }));
  });

  test('produit les effets devis par l’outbox sans notification en double', async () => {
    const notifications = { create: jest.fn(), notifyAdmins: jest.fn() };
    const scheduler = {
      autoAssignIntervention: jest.fn().mockResolvedValue({
        assigned_technician: { id: 12 }
      })
    };
    const notifyQuote = jest.fn();
    const intervention = {
      id: 4,
      technician_id: null,
      customer: { id: 9, user_id: 7 }
    };
    const quote = {
      id: 7,
      reference: 'DEV-7',
      execute_now: true,
      intervention
    };
    const models = {
      Order: {
        findByPk: jest.fn().mockResolvedValue({ id: 12, reference: 'CMD-12', quote })
      },
      Quote: {},
      Intervention: {},
      DiagnosticReport: {},
      CustomerProfile: {},
      User: {},
      TechnicianProfile: {}
    };

    await handleQuotePaymentConfirmed(
      {
        orderId: 12,
        quoteId: 7,
        interventionId: 4,
        reference: 'TRX-QUOTE',
        amount: 10000,
        paymentStep: 0,
        executionActivated: true
      },
      { idempotencyKey: 'fineopay:TRX-QUOTE:quote-effects' },
      { models, notifications, scheduler, notifyQuote }
    );

    expect(notifyQuote).toHaveBeenCalledWith(quote, intervention.customer, {
      idempotencyKey: 'fineopay:TRX-QUOTE:quote-effects:quote-accepted'
    });
    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      userId: 12,
      idempotencyKey: 'fineopay:TRX-QUOTE:quote-effects:technician'
    }));
    expect(notifications.notifyAdmins).toHaveBeenCalledWith(expect.objectContaining({
      idempotencyKey: 'fineopay:TRX-QUOTE:quote-effects:admins'
    }));
  });
});
