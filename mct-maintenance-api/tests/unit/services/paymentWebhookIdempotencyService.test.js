const {
  buildPayloadHash,
  claimPaymentWebhook,
  markPaymentWebhookCompleted,
  markPaymentWebhookFailed
} = require('../../../src/services/payment/paymentWebhookIdempotencyService');

const input = {
  provider: 'fineopay',
  reference: 'TRX-123',
  syncRef: 'ORDER_42',
  status: 'success',
  amount: 10000
};

const uniqueError = () => Object.assign(new Error('duplicate'), {
  name: 'SequelizeUniqueConstraintError'
});

const createDatabase = () => ({
  transaction: jest.fn(async (callback) => callback({
    LOCK: { UPDATE: 'UPDATE' }
  }))
});

describe('paymentWebhookIdempotencyService', () => {
  test('réserve un nouvel événement avec une empreinte financière stable', async () => {
    const event = { id: 1 };
    const model = {
      create: jest.fn().mockResolvedValue(event)
    };

    const result = await claimPaymentWebhook({ ...input, model });

    expect(result).toEqual({ acquired: true, reason: 'created', event });
    expect(model.create).toHaveBeenCalledWith(expect.objectContaining({
      provider: 'fineopay',
      providerReference: 'TRX-123',
      syncRef: 'ORDER_42',
      payloadHash: buildPayloadHash(input),
      status: 'processing',
      attemptCount: 1
    }));
  });

  test.each([
    ['completed', 'completed'],
    ['processing', 'processing']
  ])('bloque un rejeu %s avec le même payload', async (status, reason) => {
    const event = {
      ...input,
      providerReference: input.reference,
      payloadHash: buildPayloadHash(input),
      status,
      processingStartedAt: new Date('2026-08-01T10:00:00Z'),
      attemptCount: 1,
      update: jest.fn()
    };
    const model = {
      create: jest.fn().mockRejectedValue(uniqueError()),
      findOne: jest.fn().mockResolvedValue(event)
    };

    const result = await claimPaymentWebhook({
      ...input,
      model,
      database: createDatabase(),
      now: new Date('2026-08-01T10:01:00Z')
    });

    expect(result).toEqual({ acquired: false, reason, event });
    expect(event.update).not.toHaveBeenCalled();
  });

  test('refuse une même référence rejouée avec un payload différent', async () => {
    const event = {
      syncRef: 'ORDER_42',
      payloadHash: 'different',
      status: 'completed'
    };
    const model = {
      create: jest.fn().mockRejectedValue(uniqueError()),
      findOne: jest.fn().mockResolvedValue(event)
    };

    const result = await claimPaymentWebhook({
      ...input,
      model,
      database: createDatabase()
    });

    expect(result.reason).toBe('payload_mismatch');
    expect(result.acquired).toBe(false);
  });

  test.each([
    ['failed', new Date('2026-08-01T10:01:00Z')],
    ['processing', new Date('2026-08-01T09:50:00Z')]
  ])('reprend un événement %s réessayable', async (status, processingStartedAt) => {
    const event = {
      syncRef: input.syncRef,
      payloadHash: buildPayloadHash(input),
      status,
      processingStartedAt,
      attemptCount: 2,
      update: jest.fn().mockResolvedValue(undefined)
    };
    const model = {
      create: jest.fn().mockRejectedValue(uniqueError()),
      findOne: jest.fn().mockResolvedValue(event)
    };
    const now = new Date('2026-08-01T10:02:00Z');

    const result = await claimPaymentWebhook({
      ...input,
      model,
      database: createDatabase(),
      now,
      leaseMs: 5 * 60 * 1000
    });

    expect(result).toEqual({ acquired: true, reason: 'resumed', event });
    expect(event.update).toHaveBeenCalledWith(expect.objectContaining({
      status: 'processing',
      attemptCount: 3,
      processingStartedAt: now,
      lastError: null
    }), expect.objectContaining({ transaction: expect.any(Object) }));
  });

  test('finalise ou échoue explicitement un traitement réservé', async () => {
    const event = { update: jest.fn().mockResolvedValue(undefined) };
    const completedAt = new Date('2026-08-01T10:05:00Z');

    await markPaymentWebhookCompleted(event, completedAt);
    await markPaymentWebhookFailed(event, new Error('mutation impossible'));

    expect(event.update).toHaveBeenNthCalledWith(1, {
      status: 'completed',
      processedAt: completedAt,
      lastError: null
    });
    expect(event.update).toHaveBeenNthCalledWith(2, {
      status: 'failed',
      lastError: 'mutation impossible'
    });
  });
});
