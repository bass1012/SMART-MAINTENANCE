const { Op } = require('sequelize');
const { sequelize, OutboxEvent } = require('../models');

const DEFAULT_MAX_ATTEMPTS = 8;
const DEFAULT_LEASE_MS = 5 * 60 * 1000;
const DEFAULT_BATCH_SIZE = 20;

const handlers = new Map();

const registerOutboxHandler = (topic, handler) => {
  if (!topic || typeof handler !== 'function') {
    throw new TypeError('Topic et handler outbox valides requis');
  }
  handlers.set(topic, handler);
};

const enqueueOutboxEvent = ({
  topic,
  aggregateType,
  aggregateId,
  idempotencyKey,
  payload,
  transaction,
  availableAt = new Date(),
  model = OutboxEvent
}) => model.create({
  topic,
  aggregateType,
  aggregateId: String(aggregateId),
  idempotencyKey,
  payload,
  status: 'pending',
  attempts: 0,
  availableAt
}, { transaction });

const claimOutboxBatch = async ({
  now = new Date(),
  leaseMs = DEFAULT_LEASE_MS,
  limit = DEFAULT_BATCH_SIZE,
  database = sequelize,
  model = OutboxEvent
} = {}) => database.transaction(async (transaction) => {
  const leaseExpiredAt = new Date(now.getTime() - leaseMs);
  const dialect = database.getDialect();
  const events = await model.findAll({
    where: {
      [Op.or]: [
        { status: 'pending', availableAt: { [Op.lte]: now } },
        { status: 'processing', lockedAt: { [Op.lte]: leaseExpiredAt } }
      ]
    },
    order: [['id', 'ASC']],
    limit,
    transaction,
    lock: transaction.LOCK.UPDATE,
    ...(dialect === 'postgres' ? { skipLocked: true } : {})
  });

  for (const event of events) {
    await event.update({
      status: 'processing',
      attempts: Number(event.attempts || 0) + 1,
      lockedAt: now
    }, { transaction });
  }
  return events;
});

const retryDelayMs = (attempts) => Math.min(
  60 * 60 * 1000,
  1000 * (2 ** Math.max(0, attempts - 1))
);

const processOutboxEvent = async ({
  event,
  handler = handlers.get(event.topic),
  now = new Date(),
  maxAttempts = DEFAULT_MAX_ATTEMPTS
}) => {
  try {
    if (!handler) throw new Error(`Aucun handler outbox enregistré pour ${event.topic}`);
    await handler(event.payload, event);
    await event.update({
      status: 'completed',
      processedAt: now,
      lockedAt: null,
      lastError: null
    });
    return { completed: true, dead: false };
  } catch (error) {
    const attempts = Number(event.attempts || 0);
    const dead = attempts >= maxAttempts;
    await event.update({
      status: dead ? 'dead' : 'pending',
      availableAt: new Date(now.getTime() + retryDelayMs(attempts)),
      lockedAt: null,
      lastError: String(error?.message || error).slice(0, 2000)
    });
    return { completed: false, dead, error };
  }
};

const dispatchOutboxBatch = async (options = {}) => {
  const events = await claimOutboxBatch(options);
  const results = [];
  for (const event of events) {
    results.push(await processOutboxEvent({ event }));
  }
  return results;
};

module.exports = {
  DEFAULT_MAX_ATTEMPTS,
  DEFAULT_LEASE_MS,
  enqueueOutboxEvent,
  registerOutboxHandler,
  claimOutboxBatch,
  processOutboxEvent,
  dispatchOutboxBatch,
  retryDelayMs
};
