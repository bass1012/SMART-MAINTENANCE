const crypto = require('crypto');
const { UniqueConstraintError } = require('sequelize');
const { PaymentWebhookEvent, sequelize } = require('../../models');

const DEFAULT_LEASE_MS = 5 * 60 * 1000;

const buildPayloadHash = ({ reference, syncRef, status, amount }) => crypto
  .createHash('sha256')
  .update(`${reference}|${syncRef}|${status}|${Number(amount).toFixed(2)}`)
  .digest('hex');

const isUniqueConstraintError = (error) => (
  error instanceof UniqueConstraintError
  || error?.name === 'SequelizeUniqueConstraintError'
);

const claimExistingEvent = async ({
  model,
  database,
  provider,
  reference,
  syncRef,
  payloadHash,
  now,
  leaseMs
}) => database.transaction(async (transaction) => {
  const event = await model.findOne({
    where: { provider, providerReference: reference },
    transaction,
    lock: transaction.LOCK.UPDATE
  });

  if (!event) {
    throw new Error('Événement webhook introuvable après conflit d’unicité');
  }

  if (event.syncRef !== syncRef || event.payloadHash !== payloadHash) {
    return { acquired: false, reason: 'payload_mismatch', event };
  }
  if (event.status === 'completed') {
    return { acquired: false, reason: 'completed', event };
  }

  const startedAt = new Date(event.processingStartedAt).getTime();
  const leaseExpired = !Number.isFinite(startedAt)
    || now.getTime() - startedAt >= leaseMs;

  if (event.status === 'processing' && !leaseExpired) {
    return { acquired: false, reason: 'processing', event };
  }

  await event.update({
    status: 'processing',
    attemptCount: Number(event.attemptCount || 0) + 1,
    processingStartedAt: now,
    processedAt: null,
    lastError: null
  }, { transaction });

  return { acquired: true, reason: 'resumed', event };
});

const claimPaymentWebhook = async ({
  provider,
  reference,
  syncRef,
  status,
  amount,
  leaseMs = DEFAULT_LEASE_MS,
  now = new Date(),
  model = PaymentWebhookEvent,
  database = sequelize
}) => {
  const payloadHash = buildPayloadHash({ reference, syncRef, status, amount });

  try {
    const event = await model.create({
      provider,
      providerReference: reference,
      syncRef,
      payloadHash,
      status: 'processing',
      attemptCount: 1,
      processingStartedAt: now
    });
    return { acquired: true, reason: 'created', event };
  } catch (error) {
    if (!isUniqueConstraintError(error)) throw error;
  }

  return claimExistingEvent({
    model,
    database,
    provider,
    reference,
    syncRef,
    payloadHash,
    now,
    leaseMs
  });
};

const markPaymentWebhookCompleted = async (event, now = new Date()) => event.update({
  status: 'completed',
  processedAt: now,
  lastError: null
});

const markPaymentWebhookFailed = async (event, error) => event.update({
  status: 'failed',
  lastError: String(error?.message || error).slice(0, 2000)
});

module.exports = {
  DEFAULT_LEASE_MS,
  buildPayloadHash,
  claimPaymentWebhook,
  markPaymentWebhookCompleted,
  markPaymentWebhookFailed
};
