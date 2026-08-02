const { Sequelize, DataTypes } = require('sequelize');
const definePayment = require('../../../src/models/Payment');

describe('Payment model', () => {
  let database;
  let Payment;

  beforeEach(() => {
    database = new Sequelize('sqlite::memory:', { logging: false });
    Payment = definePayment(database, DataTypes);
  });

  afterEach(async () => {
    await database.close();
  });

  test('accepte FineoPay, le statut canonique et le rattachement intervention', async () => {
    const payment = Payment.build({
      interventionId: 42,
      amount: 10000,
      provider: 'fineopay',
      paymentId: 'TRX-123',
      status: 'succeeded',
      paymentStep: 1,
      purpose: 'diagnostic',
      syncRef: 'DIAGNOSTIC_42',
      verifiedAt: new Date()
    });

    await expect(payment.validate()).resolves.toBeDefined();
    expect(payment.interventionId).toBe(42);
  });

  test('refuse un fournisseur inconnu', async () => {
    const payment = Payment.build({
      amount: 10000,
      provider: 'provider_falsifie',
      status: 'succeeded'
    });

    await expect(payment.validate()).rejects.toThrow();
  });
});
