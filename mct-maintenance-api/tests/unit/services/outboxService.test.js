const {
  enqueueOutboxEvent,
  claimOutboxBatch,
  processOutboxEvent,
  retryDelayMs
} = require('../../../src/services/outboxService');

describe('outboxService', () => {
  test('inscrit l’événement dans la transaction appelante', async () => {
    const transaction = { id: 'tx-1' };
    const model = { create: jest.fn().mockResolvedValue({ id: 1 }) };

    await enqueueOutboxEvent({
      topic: 'payment.quote.confirmed',
      aggregateType: 'order',
      aggregateId: 42,
      idempotencyKey: 'fineopay:TRX-1:quote-effects',
      payload: { orderId: 42 },
      transaction,
      model
    });

    expect(model.create).toHaveBeenCalledWith(expect.objectContaining({
      aggregateId: '42',
      status: 'pending',
      attempts: 0
    }), { transaction });
  });

  test('réserve sous verrou les événements disponibles et les baux expirés', async () => {
    const now = new Date('2026-08-01T12:00:00Z');
    const event = { attempts: 1, update: jest.fn() };
    const model = { findAll: jest.fn().mockResolvedValue([event]) };
    const transaction = { LOCK: { UPDATE: 'UPDATE' } };
    const database = {
      getDialect: jest.fn(() => 'postgres'),
      transaction: jest.fn(async (callback) => callback(transaction))
    };

    const events = await claimOutboxBatch({ now, database, model });

    expect(events).toEqual([event]);
    expect(model.findAll).toHaveBeenCalledWith(expect.objectContaining({
      transaction,
      lock: 'UPDATE',
      skipLocked: true,
      limit: 20
    }));
    expect(event.update).toHaveBeenCalledWith({
      status: 'processing',
      attempts: 2,
      lockedAt: now
    }, { transaction });
  });

  test('termine un effet exécuté avec succès', async () => {
    const event = {
      topic: 'payment.test',
      payload: { id: 1 },
      attempts: 1,
      update: jest.fn()
    };
    const handler = jest.fn().mockResolvedValue(undefined);
    const now = new Date('2026-08-01T12:00:00Z');

    const result = await processOutboxEvent({ event, handler, now });

    expect(handler).toHaveBeenCalledWith(event.payload, event);
    expect(event.update).toHaveBeenCalledWith({
      status: 'completed',
      processedAt: now,
      lockedAt: null,
      lastError: null
    });
    expect(result.completed).toBe(true);
  });

  test('programme un retry exponentiel puis passe en dead-letter', async () => {
    const now = new Date('2026-08-01T12:00:00Z');
    const handler = jest.fn().mockRejectedValue(new Error('push indisponible'));
    const retryEvent = {
      topic: 'payment.test', payload: {}, attempts: 3, update: jest.fn()
    };

    const retry = await processOutboxEvent({
      event: retryEvent, handler, now, maxAttempts: 4
    });
    expect(retry.dead).toBe(false);
    expect(retryEvent.update).toHaveBeenCalledWith(expect.objectContaining({
      status: 'pending',
      availableAt: new Date(now.getTime() + retryDelayMs(3)),
      lastError: 'push indisponible'
    }));

    const deadEvent = {
      topic: 'payment.test', payload: {}, attempts: 4, update: jest.fn()
    };
    const dead = await processOutboxEvent({
      event: deadEvent, handler, now, maxAttempts: 4
    });
    expect(dead.dead).toBe(true);
    expect(deadEvent.update).toHaveBeenCalledWith(expect.objectContaining({ status: 'dead' }));
  });

  test('un topic sans handler redevient pending au lieu de rester verrouillé', async () => {
    const event = {
      topic: 'unknown', payload: {}, attempts: 1, update: jest.fn()
    };

    const result = await processOutboxEvent({ event, handler: undefined });

    expect(result.completed).toBe(false);
    expect(event.update).toHaveBeenCalledWith(expect.objectContaining({
      status: 'pending',
      lockedAt: null,
      lastError: expect.stringContaining('Aucun handler')
    }));
  });
});
