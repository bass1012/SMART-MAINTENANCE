jest.mock('../../../src/models', () => ({
  Order: { findByPk: jest.fn() },
  Quote: {},
  CustomerProfile: { findOne: jest.fn() }
}));

const { Order, CustomerProfile } = require('../../../src/models');
const {
  resolveOrderPaymentInitiation,
  PaymentInitiationError
} = require('../../../src/services/payment/orderPaymentInitiationService');

const buildOrder = (overrides = {}) => ({
  id: 42,
  customerId: 27,
  reference: 'CMD-42',
  totalAmount: 10000,
  status: 'pending',
  paymentStatus: 'pending',
  paymentType: 'full',
  quote: null,
  ...overrides
});

describe('resolveOrderPaymentInitiation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('utilise le montant en base pour un paiement intégral propriétaire', async () => {
    Order.findByPk.mockResolvedValue(buildOrder());
    CustomerProfile.findOne.mockResolvedValue({ id: 27 });

    await expect(resolveOrderPaymentInitiation({
      orderId: '42',
      user: { id: 11, role: 'customer' }
    })).resolves.toEqual(expect.objectContaining({
      amount: 10000,
      paymentStep: 0,
      title: 'Commande CMD-42 - Paiement intégral'
    }));
  });

  test('accepte temporairement une commande historique liée au User.id', async () => {
    Order.findByPk.mockResolvedValue(buildOrder({ customerId: 11 }));
    CustomerProfile.findOne.mockResolvedValue({ id: 27 });

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 11, role: 'customer' }
    })).resolves.toEqual(expect.objectContaining({ amount: 10000 }));
  });

  test('masque une commande appartenant à un autre client', async () => {
    Order.findByPk.mockResolvedValue(buildOrder({ customerId: 99 }));
    CustomerProfile.findOne.mockResolvedValue({ id: 27 });

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 11, role: 'customer' }
    })).rejects.toMatchObject({
      statusCode: 404,
      message: 'Commande non trouvée'
    });
  });

  test.each(['admin', 'manager'])('autorise le rôle interne %s', async (role) => {
    Order.findByPk.mockResolvedValue(buildOrder({ customerId: 99 }));

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 2, role }
    })).resolves.toEqual(expect.objectContaining({ amount: 10000 }));

    expect(CustomerProfile.findOne).not.toHaveBeenCalled();
  });

  test('refuse un technicien', async () => {
    Order.findByPk.mockResolvedValue(buildOrder());

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 9, role: 'technician' }
    })).rejects.toBeInstanceOf(PaymentInitiationError);
  });

  test('dérive le premier acompte depuis le devis', async () => {
    Order.findByPk.mockResolvedValue(buildOrder({
      paymentType: 'split',
      totalAmount: 5001,
      quote: {
        total: 10001,
        payment_status: 'pending',
        first_payment_amount: 5001,
        first_payment_status: 'pending',
        second_payment_amount: 5000,
        second_payment_status: 'pending'
      }
    }));

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 2, role: 'admin' }
    })).resolves.toEqual(expect.objectContaining({
      amount: 5001,
      paymentStep: 1
    }));
  });

  test('dérive le second paiement même si la commande est déjà marquée paid', async () => {
    Order.findByPk.mockResolvedValue(buildOrder({
      paymentType: 'split',
      paymentStatus: 'paid',
      totalAmount: 5001,
      quote: {
        total: 10001,
        payment_status: 'partial',
        first_payment_amount: 5001,
        first_payment_status: 'paid',
        second_payment_amount: 5000,
        second_payment_status: 'pending'
      }
    }));

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 2, role: 'manager' }
    })).resolves.toEqual(expect.objectContaining({
      amount: 5000,
      paymentStep: 2
    }));
  });

  test.each([
    { status: 'cancelled' },
    { status: 'processing' },
    { paymentStatus: 'refunded' },
    { paymentStatus: 'paid' }
  ])('refuse une commande non payable %#', async (override) => {
    Order.findByPk.mockResolvedValue(buildOrder(override));

    await expect(resolveOrderPaymentInitiation({
      orderId: 42,
      user: { id: 2, role: 'admin' }
    })).rejects.toMatchObject({ statusCode: 409 });
  });
});
