jest.mock('axios', () => ({
  post: jest.fn(),
  get: jest.fn()
}));

jest.mock('../../../src/models', () => ({
  Quote: {},
  Order: {},
  Intervention: {},
  DiagnosticReport: {},
  User: {},
  TechnicianProfile: {},
  CustomerProfile: {},
  PaymentLog: { create: jest.fn() },
  Subscription: {},
  Payment: {}
}));

jest.mock('../../../src/services/payment/orderPaymentInitiationService', () => {
  class PaymentInitiationError extends Error {
    constructor(statusCode, message) {
      super(message);
      this.statusCode = statusCode;
    }
  }

  return {
    resolveOrderPaymentInitiation: jest.fn(),
    PaymentInitiationError
  };
});

jest.mock('../../../src/services/payment/paymentWebhookIdempotencyService', () => ({
  claimPaymentWebhook: jest.fn(),
  markPaymentWebhookCompleted: jest.fn(),
  markPaymentWebhookFailed: jest.fn()
}));

jest.mock('../../../src/services/payment/fineoPayFinancialTransactionService', () => ({
  recordShopPayment: jest.fn(),
  recordDiagnosticPayment: jest.fn(),
  recordSubscriptionPayment: jest.fn(),
  recordQuoteOrderPayment: jest.fn()
}));

jest.mock('../../../src/services/notificationService', () => ({
  create: jest.fn(),
  notifyAdmins: jest.fn()
}));

const axios = require('axios');
const { PaymentLog, Payment, Subscription } = require('../../../src/models');
const {
  resolveOrderPaymentInitiation,
  PaymentInitiationError
} = require('../../../src/services/payment/orderPaymentInitiationService');
const {
  claimPaymentWebhook,
  markPaymentWebhookCompleted,
  markPaymentWebhookFailed
} = require('../../../src/services/payment/paymentWebhookIdempotencyService');
const {
  recordSubscriptionPayment,
  recordQuoteOrderPayment
} = require('../../../src/services/payment/fineoPayFinancialTransactionService');
const {
  createPaymentLink,
  handleCallback
} = require('../../../src/controllers/payment/fineoPayController');

const createResponse = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
};

describe('createPaymentLink', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('ignore le montant client et utilise exclusivement le contexte canonique', async () => {
    const order = { update: jest.fn() };
    resolveOrderPaymentInitiation.mockResolvedValue({
      order,
      amount: 10000,
      paymentStep: 0,
      title: 'Commande CMD-42 - Paiement intégral',
      description: 'Paiement intégral pour la commande CMD-42'
    });
    axios.post.mockResolvedValue({
      data: {
        success: true,
        data: {
          checkoutLink: 'https://pay.test/BIZ/chk_123/checkout'
        }
      }
    });
    const req = {
      user: { id: 11, role: 'customer' },
      body: { orderId: 42, amount: 1, title: 'Montant falsifié' },
      ip: '127.0.0.1',
      get: jest.fn(() => 'jest')
    };
    const res = createResponse();

    await createPaymentLink(req, res);

    expect(resolveOrderPaymentInitiation).toHaveBeenCalledWith({
      orderId: 42,
      user: req.user
    });
    expect(axios.post.mock.calls[0][1]).toEqual(expect.objectContaining({
      amount: 10000,
      syncRef: 'ORDER_42'
    }));
    expect(order.update).toHaveBeenCalledWith(expect.objectContaining({
      paymentStep: 0,
      fineopayCheckoutId: 'chk_123'
    }));
    expect(PaymentLog.create).toHaveBeenCalledWith(expect.objectContaining({
      amount: 10000,
      paymentStatus: 'pending'
    }));
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ amount: 10000 })
    }));
  });

  test('n’appelle jamais FineoPay lorsque la commande est refusée', async () => {
    resolveOrderPaymentInitiation.mockRejectedValue(
      new PaymentInitiationError(404, 'Commande non trouvée')
    );
    const req = {
      user: { id: 11, role: 'customer' },
      body: { orderId: 99, amount: 1, title: 'Tiers' },
      ip: '127.0.0.1',
      get: jest.fn(() => 'jest')
    };
    const res = createResponse();

    await createPaymentLink(req, res);

    expect(axios.post).not.toHaveBeenCalled();
    expect(PaymentLog.create).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(404);
  });
});

describe('handleCallback', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    claimPaymentWebhook.mockResolvedValue({
      acquired: true,
      reason: 'created',
      event: { id: 1 }
    });
    markPaymentWebhookCompleted.mockResolvedValue(undefined);
    markPaymentWebhookFailed.mockResolvedValue(undefined);
    recordSubscriptionPayment.mockReset();
    recordQuoteOrderPayment.mockReset();
  });

  const createCallbackRequest = (body) => ({
    body,
    rawBody: Buffer.from(JSON.stringify(body)),
    headers: {},
    ip: '127.0.0.1',
    get: jest.fn(() => 'jest')
  });

  test('refuse le callback quand la transaction ne peut pas être vérifiée', async () => {
    axios.get.mockRejectedValue(new Error('FineoPay indisponible'));
    const body = {
      reference: 'TRX-123',
      syncRef: 'ORDER_42',
      status: 'success',
      amount: 10000
    };
    const req = createCallbackRequest(body);
    const res = createResponse();

    await handleCallback(req, res);

    expect(axios.get).toHaveBeenCalledWith(
      expect.stringContaining('/transactions/TRX-123'),
      expect.objectContaining({ timeout: 10000 })
    );
    expect(res.status).toHaveBeenCalledWith(503);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: false,
      code: 'PROVIDER_UNAVAILABLE',
      retryable: true
    }));
    expect(PaymentLog.create).toHaveBeenCalledWith(expect.objectContaining({
      success: false,
      errorMessage: expect.stringContaining('PROVIDER_UNAVAILABLE')
    }));
  });

  test('acquitte un rejeu déjà terminé sans relancer le traitement métier', async () => {
    const body = {
      reference: 'TRX-123',
      syncRef: 'ORDER_42',
      status: 'success',
      amount: 10000
    };
    axios.get.mockResolvedValue({ data: { success: true, data: body } });
    claimPaymentWebhook.mockResolvedValue({
      acquired: false,
      reason: 'completed',
      event: { id: 1 }
    });
    const res = createResponse();

    await handleCallback(createCallbackRequest(body), res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      duplicate: true
    }));
    expect(markPaymentWebhookCompleted).not.toHaveBeenCalled();
    expect(markPaymentWebhookFailed).not.toHaveBeenCalled();
  });

  test('acquitte seulement après avoir finalisé un échec de paiement authentifié', async () => {
    const body = {
      reference: 'TRX-FAILED',
      syncRef: 'UNKNOWN_42',
      status: 'failed',
      amount: 10000
    };
    axios.get.mockResolvedValue({ data: { success: true, data: body } });
    const res = createResponse();

    await handleCallback(createCallbackRequest(body), res);

    expect(markPaymentWebhookCompleted).toHaveBeenCalledWith({ id: 1 });
    expect(markPaymentWebhookCompleted.mock.invocationCallOrder[0])
      .toBeLessThan(res.status.mock.invocationCallOrder[0]);
    expect(res.status).toHaveBeenCalledWith(200);
    expect(markPaymentWebhookFailed).not.toHaveBeenCalled();
  });

  test('termine le premier paiement d’abonnement avant de finaliser le webhook', async () => {
    const body = {
      reference: 'TRX-SUB-1',
      syncRef: 'SUBSCRIPTION_42',
      status: 'success',
      amount: 5000
    };
    const subscription = {
      id: 42,
      customer_id: 7,
      customer: { first_name: 'Awa', last_name: 'Koné' },
      contract_type: 'standard',
      payment_status: 'pending',
      first_payment_status: 'pending',
      second_payment_status: 'pending',
      checkout_link_id: 'checkout-42',
      update: jest.fn().mockResolvedValue(undefined)
    };
    Subscription.findByPk = jest.fn().mockResolvedValue(subscription);
    Payment.create = jest.fn().mockResolvedValue({ id: 99 });
    recordSubscriptionPayment.mockResolvedValue({
      subscription,
      paymentStep: 1,
      duplicate: false,
      payment: { id: 99 }
    });
    axios.get.mockResolvedValue({ data: { success: true, data: body } });
    const res = createResponse();

    await handleCallback(createCallbackRequest(body), res);

    expect(recordSubscriptionPayment).toHaveBeenCalledWith({
      subscriptionId: 42,
      reference: 'TRX-SUB-1',
      amount: 5000,
      sourceIp: '127.0.0.1'
    });
    expect(markPaymentWebhookCompleted).toHaveBeenCalledWith({ id: 1 });
    expect(res.status).toHaveBeenCalledWith(200);
  });

  test('n’acquitte pas avant la fin du traitement métier et rend l’échec réessayable', async () => {
    const body = {
      reference: 'TRX-123',
      syncRef: 'ORDER_42',
      status: 'success',
      amount: 10000
    };
    axios.get.mockResolvedValue({ data: { success: true, data: body } });
    recordQuoteOrderPayment.mockRejectedValue(new Error('transaction devis impossible'));
    const res = createResponse();

    await handleCallback(createCallbackRequest(body), res);

    expect(markPaymentWebhookFailed).toHaveBeenCalledWith(
      { id: 1 },
      expect.objectContaining({ message: 'transaction devis impossible' })
    );
    expect(markPaymentWebhookCompleted).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      code: 'WEBHOOK_PROCESSING_FAILED',
      retryable: true
    }));
  });
});
