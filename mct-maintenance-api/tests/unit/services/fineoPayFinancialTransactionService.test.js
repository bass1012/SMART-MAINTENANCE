const {
  recordShopPayment,
  recordDiagnosticPayment,
  recordSubscriptionPayment,
  recordQuoteOrderPayment
} = require('../../../src/services/payment/fineoPayFinancialTransactionService');

const createDatabase = () => ({
  transaction: jest.fn(async (callback) => callback({ LOCK: { UPDATE: 'UPDATE' } }))
});

const createModels = () => ({
  Order: { findByPk: jest.fn() },
  Quote: { findByPk: jest.fn() },
  Subscription: { findByPk: jest.fn() },
  Intervention: { findByPk: jest.fn() },
  CustomerProfile: {},
  User: {},
  Payment: { findOne: jest.fn().mockResolvedValue(null), create: jest.fn() },
  PaymentLog: { create: jest.fn() },
  OutboxEvent: { create: jest.fn() }
});

describe('fineoPayFinancialTransactionService', () => {
  test('enregistre atomiquement un paiement boutique sous verrou', async () => {
    const database = createDatabase();
    const models = createModels();
    const order = {
      id: 42,
      totalAmount: 10000,
      paymentStatus: 'pending',
      fineopayCheckoutId: 'checkout-42',
      update: jest.fn()
    };
    models.Order.findByPk.mockResolvedValue(order);
    models.Payment.create.mockResolvedValue({ id: 1 });

    const result = await recordShopPayment({
      orderId: 42,
      reference: 'TRX-SHOP',
      amount: 10000,
      database,
      models
    });

    expect(models.Order.findByPk).toHaveBeenCalledWith(42, expect.objectContaining({
      transaction: expect.any(Object),
      lock: 'UPDATE'
    }));
    expect(models.Payment.create).toHaveBeenCalledWith(expect.objectContaining({
      orderId: 42,
      purpose: 'shop',
      status: 'succeeded'
    }), { transaction: expect.any(Object) });
    expect(order.update).toHaveBeenCalledWith(expect.objectContaining({
      paymentStatus: 'paid'
    }), { transaction: expect.any(Object) });
    expect(models.PaymentLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ eventType: 'payment_confirmed' }),
      { transaction: expect.any(Object) }
    );
    expect(models.OutboxEvent.create).toHaveBeenCalledWith(expect.objectContaining({
      topic: 'payment.shop.confirmed',
      idempotencyKey: 'fineopay:TRX-SHOP:shop-notifications',
      payload: { orderId: 42, reference: 'TRX-SHOP', amount: 10000 }
    }), { transaction: expect.any(Object) });
    expect(result.duplicate).toBe(false);
  });

  test('refuse le montant boutique différent de la valeur en base', async () => {
    const models = createModels();
    models.Order.findByPk.mockResolvedValue({ id: 42, totalAmount: 10000 });

    await expect(recordShopPayment({
      orderId: 42,
      reference: 'TRX-SHOP',
      amount: 1,
      database: createDatabase(),
      models
    })).rejects.toEqual(expect.objectContaining({
      code: 'EXPECTED_AMOUNT_MISMATCH',
      statusCode: 409
    }));
    expect(models.Payment.create).not.toHaveBeenCalled();
    expect(models.OutboxEvent.create).not.toHaveBeenCalled();
  });

  test('enregistre le solde diagnostic et toutes ses écritures dans la transaction', async () => {
    const models = createModels();
    const intervention = {
      id: 8,
      diagnostic_paid: true,
      second_payment_status: 'pending',
      second_payment_amount: 7500,
      update: jest.fn()
    };
    models.Intervention.findByPk.mockResolvedValue(intervention);
    models.Payment.create.mockResolvedValue({ id: 2 });

    const result = await recordDiagnosticPayment({
      interventionId: 8,
      reference: 'TRX-DIAG-2',
      amount: 7500,
      sourceIp: '127.0.0.1',
      database: createDatabase(),
      models
    });

    expect(result.paymentStep).toBe(2);
    expect(intervention.update).toHaveBeenCalledWith({
      second_payment_status: 'paid',
      second_payment_date: expect.any(Date)
    }, { transaction: expect.any(Object) });
    expect(models.Payment.create).toHaveBeenCalledWith(expect.objectContaining({
      interventionId: 8,
      paymentStep: 2
    }), { transaction: expect.any(Object) });
    expect(models.OutboxEvent.create).toHaveBeenCalledWith(expect.objectContaining({
      topic: 'payment.diagnostic.confirmed',
      idempotencyKey: 'fineopay:TRX-DIAG-2:diagnostic-effects',
      payload: {
        interventionId: 8,
        reference: 'TRX-DIAG-2',
        amount: 7500,
        paymentStep: 2
      }
    }), { transaction: expect.any(Object) });
  });

  test('enregistre le deuxième paiement abonnement et propage toute erreur du journal', async () => {
    const models = createModels();
    const subscription = {
      id: 5,
      first_payment_status: 'paid',
      second_payment_status: 'pending',
      second_payment_amount: 5000,
      update: jest.fn()
    };
    models.Subscription.findByPk.mockResolvedValue(subscription);
    models.Payment.create.mockResolvedValue({ id: 3 });
    models.PaymentLog.create.mockRejectedValue(new Error('journal indisponible'));

    await expect(recordSubscriptionPayment({
      subscriptionId: 5,
      reference: 'TRX-SUB-2',
      amount: 5000,
      database: createDatabase(),
      models
    })).rejects.toThrow('journal indisponible');

    expect(subscription.update).toHaveBeenCalledWith(expect.objectContaining({
      second_payment_status: 'paid',
      status: 'completed'
    }), { transaction: expect.any(Object) });
  });

  test('reconnaît un paiement identique existant sans remuter la cible', async () => {
    const models = createModels();
    const order = {
      id: 42,
      totalAmount: 10000,
      paymentStatus: 'paid',
      update: jest.fn()
    };
    models.Order.findByPk.mockResolvedValue(order);
    models.Payment.findOne.mockResolvedValue({
      orderId: 42,
      subscriptionId: null,
      interventionId: null,
      purpose: 'shop',
      paymentStep: 0,
      amount: 10000
    });

    const result = await recordShopPayment({
      orderId: 42,
      reference: 'TRX-SHOP',
      amount: 10000,
      database: createDatabase(),
      models
    });

    expect(result.duplicate).toBe(true);
    expect(order.update).not.toHaveBeenCalled();
    expect(models.Payment.create).not.toHaveBeenCalled();
  });

  test('verrouille Order, Quote puis Intervention et confirme un acompte devis', async () => {
    const models = createModels();
    const order = {
      id: 12, quoteId: 7, totalAmount: 5001, paymentType: 'split',
      paymentStep: 1, paymentStatus: 'pending', update: jest.fn()
    };
    const quote = {
      id: 7, intervention_id: 4, reference: 'DEV-7', execute_now: false,
      total: 10001, first_payment_amount: 5001, second_payment_amount: 5000,
      first_payment_status: 'pending', second_payment_status: 'pending', update: jest.fn()
    };
    const intervention = { id: 4, notes: '', update: jest.fn() };
    models.Order.findByPk.mockResolvedValue(order);
    models.Quote.findByPk.mockResolvedValue(quote);
    models.Intervention.findByPk.mockResolvedValue(intervention);
    models.Payment.create.mockResolvedValue({ id: 10 });

    const result = await recordQuoteOrderPayment({
      orderId: 12,
      reference: 'TRX-QUOTE-1',
      amount: '5001.00',
      database: createDatabase(),
      models
    });

    expect(models.Order.findByPk.mock.invocationCallOrder[0])
      .toBeLessThan(models.Quote.findByPk.mock.invocationCallOrder[0]);
    expect(models.Quote.findByPk.mock.invocationCallOrder[0])
      .toBeLessThan(models.Intervention.findByPk.mock.invocationCallOrder[0]);
    expect(models.Payment.create).toHaveBeenCalledWith(expect.objectContaining({
      orderId: 12, purpose: 'quote', paymentStep: 1, amount: '5001.00'
    }), { transaction: expect.any(Object) });
    expect(quote.update).toHaveBeenCalledWith(expect.objectContaining({
      first_payment_status: 'paid', payment_status: 'partial'
    }), { transaction: expect.any(Object) });
    expect(intervention.update).toHaveBeenCalledWith(expect.objectContaining({
      status: 'execution_confirmed'
    }), { transaction: expect.any(Object) });
    expect(result).toEqual(expect.objectContaining({
      paymentStep: 1, executionActivated: true, duplicate: false
    }));
  });

  test('le solde devis ne régresse pas le statut de l’intervention', async () => {
    const models = createModels();
    const order = {
      id: 12, quoteId: 7, totalAmount: 5000, paymentType: 'split',
      paymentStep: 2, paymentStatus: 'paid', update: jest.fn()
    };
    const quote = {
      id: 7, intervention_id: 4, total: 10001, execute_now: true,
      first_payment_amount: 5001, second_payment_amount: 5000,
      first_payment_status: 'paid', second_payment_status: 'pending', update: jest.fn()
    };
    const intervention = { id: 4, status: 'completed', update: jest.fn() };
    models.Order.findByPk.mockResolvedValue(order);
    models.Quote.findByPk.mockResolvedValue(quote);
    models.Intervention.findByPk.mockResolvedValue(intervention);
    models.Payment.create.mockResolvedValue({ id: 11 });

    const result = await recordQuoteOrderPayment({
      orderId: 12, reference: 'TRX-QUOTE-2', amount: 5000,
      database: createDatabase(), models
    });

    expect(result.executionActivated).toBe(false);
    expect(intervention.update).not.toHaveBeenCalled();
    expect(quote.update).toHaveBeenCalledWith(expect.objectContaining({
      second_payment_status: 'paid', payment_status: 'paid'
    }), { transaction: expect.any(Object) });
  });

  test('refuse un montant de devis falsifié après verrouillage', async () => {
    const models = createModels();
    models.Order.findByPk.mockResolvedValue({
      id: 12, quoteId: 7, totalAmount: 10000, paymentType: 'full', paymentStep: 0
    });
    models.Quote.findByPk.mockResolvedValue({
      id: 7, total: 10000, payment_status: 'pending', intervention_id: null
    });

    await expect(recordQuoteOrderPayment({
      orderId: 12, reference: 'TRX-QUOTE', amount: 1,
      database: createDatabase(), models
    })).rejects.toEqual(expect.objectContaining({ code: 'EXPECTED_AMOUNT_MISMATCH' }));
    expect(models.Payment.create).not.toHaveBeenCalled();
  });
});
