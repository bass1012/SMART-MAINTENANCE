const {
  sequelize,
  Order,
  Quote,
  Subscription,
  Intervention,
  CustomerProfile,
  User,
  Payment,
  PaymentLog,
  OutboxEvent
} = require('../../models');
const { enqueueOutboxEvent } = require('../outboxService');

class FineoPayFinancialTransactionError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.name = 'FineoPayFinancialTransactionError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

const minorAmount = (value) => {
  const number = Number(value);
  return Number.isFinite(number) ? Math.round(number * 100) : null;
};

const assertExpectedAmount = (received, expected) => {
  if (
    minorAmount(received) === null
    || minorAmount(expected) === null
    || minorAmount(received) !== minorAmount(expected)
  ) {
    throw new FineoPayFinancialTransactionError(
      409,
      'EXPECTED_AMOUNT_MISMATCH',
      'Le montant FineoPay ne correspond pas au montant attendu en base'
    );
  }
};

const findExistingPayment = async ({
  paymentModel,
  reference,
  transaction
}) => paymentModel.findOne({
  where: { provider: 'fineopay', paymentId: reference },
  transaction,
  lock: transaction.LOCK.UPDATE
});

const assertSameExistingPayment = (payment, expected) => {
  if (!payment) return false;
  const sameTarget = (
    Number(payment.orderId || 0) === Number(expected.orderId || 0)
    && Number(payment.subscriptionId || 0) === Number(expected.subscriptionId || 0)
    && Number(payment.interventionId || 0) === Number(expected.interventionId || 0)
  );
  if (
    !sameTarget
    || payment.purpose !== expected.purpose
    || Number(payment.paymentStep) !== Number(expected.paymentStep)
    || minorAmount(payment.amount) !== minorAmount(expected.amount)
  ) {
    throw new FineoPayFinancialTransactionError(
      409,
      'PAYMENT_REFERENCE_CONFLICT',
      'La référence FineoPay est déjà liée à un autre paiement'
    );
  }
  return true;
};

const createLedgerPayment = ({
  paymentModel,
  values,
  reference,
  amount,
  syncRef,
  checkoutId,
  transaction,
  now
}) => paymentModel.create({
  ...values,
  amount,
  currency: 'XOF',
  provider: 'fineopay',
  paymentId: reference,
  status: 'succeeded',
  syncRef,
  gatewayCheckoutId: checkoutId || null,
  verifiedAt: now,
  paidAt: now,
  metadata: { fineopay_reference: reference }
}, { transaction });

const recordShopPayment = async ({
  orderId,
  reference,
  amount,
  database = sequelize,
  models = { Order, Payment, PaymentLog, OutboxEvent },
  enqueueEvent = enqueueOutboxEvent,
  now = new Date()
}) => database.transaction(async (transaction) => {
  const order = await models.Order.findByPk(orderId, {
    transaction,
    lock: transaction.LOCK.UPDATE
  });
  if (!order) {
    throw new FineoPayFinancialTransactionError(404, 'ORDER_NOT_FOUND', 'Commande boutique introuvable');
  }

  assertExpectedAmount(amount, order.totalAmount);
  const paymentValues = {
    orderId: order.id,
    paymentStep: 0,
    purpose: 'shop',
    amount
  };
  const existing = await findExistingPayment({
    paymentModel: models.Payment,
    reference,
    transaction
  });
  if (assertSameExistingPayment(existing, paymentValues)) {
    return { order, duplicate: true, payment: existing };
  }
  if (order.paymentStatus === 'paid') {
    throw new FineoPayFinancialTransactionError(
      409,
      'ORDER_ALREADY_PAID',
      'Cette commande est déjà payée avec une autre transaction'
    );
  }

  const payment = await createLedgerPayment({
    paymentModel: models.Payment,
    values: paymentValues,
    reference,
    amount,
    syncRef: `SHOP_ORDER_${orderId}`,
    checkoutId: order.fineopayCheckoutId,
    transaction,
    now
  });
  await order.update({
    paymentStatus: 'paid',
    paymentMethod: 'fineopay',
    paymentDate: now
  }, { transaction });
  await models.PaymentLog.create({
    orderId: order.id,
    eventType: 'payment_confirmed',
    provider: 'fineopay',
    fineopayReference: reference,
    amount,
    paymentStatus: 'paid',
    success: true,
    metadata: { type: 'shop' }
  }, { transaction });
  await enqueueEvent({
    topic: 'payment.shop.confirmed',
    aggregateType: 'order',
    aggregateId: order.id,
    idempotencyKey: `fineopay:${reference}:shop-notifications`,
    payload: { orderId: order.id, reference, amount: Number(amount) },
    transaction,
    model: models.OutboxEvent
  });

  return { order, duplicate: false, payment };
});

const recordDiagnosticPayment = async ({
  interventionId,
  reference,
  amount,
  sourceIp,
  database = sequelize,
  models = { Intervention, CustomerProfile, User, Payment, PaymentLog, OutboxEvent },
  enqueueEvent = enqueueOutboxEvent,
  now = new Date()
}) => database.transaction(async (transaction) => {
  const intervention = await models.Intervention.findByPk(interventionId, {
    include: [{
      model: models.CustomerProfile,
      as: 'customer',
      include: [{ model: models.User, as: 'user' }]
    }],
    transaction,
    lock: transaction.LOCK.UPDATE
  });
  if (!intervention) {
    throw new FineoPayFinancialTransactionError(404, 'INTERVENTION_NOT_FOUND', 'Intervention introuvable');
  }

  const paymentStep = intervention.diagnostic_paid !== true ? 1 : 2;
  const expectedAmount = paymentStep === 1
    ? intervention.diagnostic_fee
    : intervention.second_payment_amount;
  assertExpectedAmount(amount, expectedAmount);

  const paymentValues = {
    interventionId: intervention.id,
    paymentStep,
    purpose: 'diagnostic',
    amount
  };
  const existing = await findExistingPayment({
    paymentModel: models.Payment,
    reference,
    transaction
  });
  if (assertSameExistingPayment(existing, paymentValues)) {
    return { intervention, paymentStep, duplicate: true, payment: existing };
  }
  if (paymentStep === 2 && intervention.second_payment_status !== 'pending') {
    throw new FineoPayFinancialTransactionError(
      409,
      'INTERVENTION_ALREADY_PAID',
      'Cette intervention est déjà intégralement payée'
    );
  }

  const payment = await createLedgerPayment({
    paymentModel: models.Payment,
    values: paymentValues,
    reference,
    amount,
    syncRef: `DIAGNOSTIC_${interventionId}`,
    transaction,
    now
  });
  const update = paymentStep === 1
    ? { diagnostic_paid: true, diagnostic_payment_date: now }
    : { second_payment_status: 'paid', second_payment_date: now };
  await intervention.update(update, { transaction });
  await models.PaymentLog.create({
    eventType: 'diagnostic_payment_confirmed',
    provider: 'fineopay',
    fineopayReference: reference,
    amount,
    paymentStatus: 'paid',
    sourceIp,
    success: true,
    metadata: { interventionId, type: 'diagnostic', paymentStep }
  }, { transaction });
  await enqueueEvent({
    topic: 'payment.diagnostic.confirmed',
    aggregateType: 'intervention',
    aggregateId: intervention.id,
    idempotencyKey: `fineopay:${reference}:diagnostic-effects`,
    payload: {
      interventionId: intervention.id,
      reference,
      amount: Number(amount),
      paymentStep
    },
    transaction,
    model: models.OutboxEvent
  });

  return { intervention, paymentStep, duplicate: false, payment };
});

const recordSubscriptionPayment = async ({
  subscriptionId,
  reference,
  amount,
  sourceIp,
  database = sequelize,
  models = { Subscription, User, Payment, PaymentLog, OutboxEvent },
  enqueueEvent = enqueueOutboxEvent,
  now = new Date()
}) => database.transaction(async (transaction) => {
  const subscription = await models.Subscription.findByPk(subscriptionId, {
    include: [{ model: models.User, as: 'customer' }],
    transaction,
    lock: transaction.LOCK.UPDATE
  });
  if (!subscription) {
    throw new FineoPayFinancialTransactionError(404, 'SUBSCRIPTION_NOT_FOUND', 'Souscription introuvable');
  }

  const paymentStep = subscription.first_payment_status === 'paid' ? 2 : 1;
  const expectedAmount = paymentStep === 2
    ? subscription.second_payment_amount
    : (subscription.first_payment_amount || subscription.price);
  assertExpectedAmount(amount, expectedAmount);

  const paymentValues = {
    subscriptionId: subscription.id,
    paymentStep,
    purpose: 'subscription',
    amount
  };
  const existing = await findExistingPayment({
    paymentModel: models.Payment,
    reference,
    transaction
  });
  if (assertSameExistingPayment(existing, paymentValues)) {
    return { subscription, paymentStep, duplicate: true, payment: existing };
  }
  if (paymentStep === 2 && subscription.second_payment_status === 'paid') {
    throw new FineoPayFinancialTransactionError(
      409,
      'SUBSCRIPTION_ALREADY_PAID',
      'Cette souscription est déjà intégralement payée'
    );
  }

  const payment = await createLedgerPayment({
    paymentModel: models.Payment,
    values: paymentValues,
    reference,
    amount,
    syncRef: `SUBSCRIPTION_${subscriptionId}`,
    checkoutId: subscription.checkout_link_id,
    transaction,
    now
  });
  const update = paymentStep === 2
    ? {
      second_payment_status: 'paid',
      payment_status: 'paid',
      status: 'completed'
    }
    : {
      first_payment_status: 'paid',
      payment_status: Number(subscription.second_payment_amount || 0) > 0 ? 'partial' : 'paid',
      ...(subscription.contract_type === 'scheduled' ? {} : { status: 'active' })
    };
  await subscription.update(update, { transaction });
  await models.PaymentLog.create({
    eventType: paymentStep === 2 ? 'subscription_second_payment' : 'payment_confirmed',
    provider: 'fineopay',
    fineopayReference: reference,
    amount,
    paymentStatus: 'paid',
    sourceIp,
    success: true,
    metadata: { subscriptionId, type: 'subscription', payment_phase: paymentStep }
  }, { transaction });
  await enqueueEvent({
    topic: 'payment.subscription.confirmed',
    aggregateType: 'subscription',
    aggregateId: subscription.id,
    idempotencyKey: `fineopay:${reference}:subscription-effects`,
    payload: {
      subscriptionId: subscription.id,
      reference,
      amount: Number(amount),
      paymentStep
    },
    transaction,
    model: models.OutboxEvent
  });

  return { subscription, paymentStep, duplicate: false, payment };
});

const recordQuoteOrderPayment = async ({
  orderId,
  reference,
  amount,
  sourceIp,
  clientAccountNumber,
  database = sequelize,
  models = { Order, Quote, Intervention, Payment, PaymentLog, OutboxEvent },
  enqueueEvent = enqueueOutboxEvent,
  now = new Date()
}) => database.transaction(async (transaction) => {
  const order = await models.Order.findByPk(orderId, {
    transaction,
    lock: transaction.LOCK.UPDATE
  });
  if (!order) {
    throw new FineoPayFinancialTransactionError(404, 'ORDER_NOT_FOUND', 'Commande de devis introuvable');
  }

  const quoteId = order.quoteId || order.quote_id;
  const quote = quoteId ? await models.Quote.findByPk(quoteId, {
    transaction,
    lock: transaction.LOCK.UPDATE
  }) : null;
  if (!quote) {
    throw new FineoPayFinancialTransactionError(404, 'QUOTE_NOT_FOUND', 'Devis associé introuvable');
  }

  const interventionId = quote.intervention_id || quote.interventionId;
  const intervention = interventionId
    ? await models.Intervention.findByPk(interventionId, {
      transaction,
      lock: transaction.LOCK.UPDATE
    })
    : null;
  const isSplitPayment = (order.paymentType || order.payment_type || 'full') === 'split';
  const paymentStep = isSplitPayment
    ? Number(order.paymentStep ?? order.payment_step ?? 1)
    : 0;
  if ((isSplitPayment && ![1, 2].includes(paymentStep)) || (!isSplitPayment && paymentStep !== 0)) {
    throw new FineoPayFinancialTransactionError(409, 'INVALID_PAYMENT_STEP', 'Étape de paiement incohérente');
  }

  const quoteTotal = Number.isFinite(Number(quote.total)) ? Number(quote.total) : null;
  const orderAmount = Number.isFinite(Number(order.totalAmount)) ? Number(order.totalAmount) : null;
  const firstAmount = quote.first_payment_amount != null
    ? Number(quote.first_payment_amount)
    : quoteTotal != null
      ? Math.ceil(quoteTotal / 2)
      : orderAmount;
  const expectedAmount = !isSplitPayment
    ? (quoteTotal ?? orderAmount)
    : paymentStep === 2
      ? quote.second_payment_amount != null
        ? Number(quote.second_payment_amount)
        : quoteTotal != null && firstAmount != null
          ? quoteTotal - firstAmount
          : null
      : firstAmount;
  assertExpectedAmount(amount, expectedAmount);

  const paymentValues = {
    orderId: order.id,
    paymentStep,
    purpose: 'quote',
    amount
  };
  const existing = await findExistingPayment({
    paymentModel: models.Payment,
    reference,
    transaction
  });
  if (assertSameExistingPayment(existing, paymentValues)) {
    return {
      order,
      quote,
      intervention,
      paymentStep,
      isSplitPayment,
      executionActivated: false,
      duplicate: true,
      payment: existing
    };
  }
  if (
    (!isSplitPayment && quote.payment_status === 'paid')
    || (isSplitPayment && paymentStep === 1 && quote.first_payment_status === 'paid')
    || (isSplitPayment && paymentStep === 2 && quote.second_payment_status === 'paid')
  ) {
    throw new FineoPayFinancialTransactionError(
      409,
      'QUOTE_STEP_ALREADY_PAID',
      'Cette étape du devis est déjà payée avec une autre transaction'
    );
  }

  const payment = await createLedgerPayment({
    paymentModel: models.Payment,
    values: paymentValues,
    reference,
    amount,
    syncRef: `ORDER_${orderId}`,
    checkoutId: order.fineopayCheckoutId,
    transaction,
    now
  });
  await order.update({
    status: quote.execute_now ? 'processing' : 'scheduled',
    paymentStatus: 'paid',
    paymentMethod: 'fineopay',
    paymentDate: now,
    fineopayReference: reference,
    paymentStep
  }, { transaction });

  const quoteUpdate = isSplitPayment
    ? paymentStep === 1
      ? {
        first_payment_status: 'paid',
        first_payment_date: now,
        first_payment_transaction_id: reference,
        payment_status: 'partial'
      }
      : {
        second_payment_status: 'paid',
        second_payment_date: now,
        second_payment_transaction_id: reference,
        payment_status: 'paid',
        paid_at: now
      }
    : {
      payment_status: 'paid',
      payment_type: 'full',
      payment_transaction_id: reference,
      paid_at: now,
      payment_method: 'fineopay'
    };
  await quote.update(quoteUpdate, { transaction });

  const executionActivated = paymentStep === 0 || paymentStep === 1;
  if (intervention && executionActivated) {
    const mode = quote.execute_now ? '⚡ PAIEMENT CONFIRMÉ' : '📅 PAIEMENT REÇU';
    await intervention.update({
      status: 'execution_confirmed',
      ...(quote.execute_now ? {} : { intervention_type: 'execution' }),
      notes: `${intervention.notes || ''}\n\n[${now.toISOString()}] ${mode} (webhook) - Devis ${quote.reference}`
    }, { transaction });
  }

  await models.PaymentLog.create({
    orderId: order.id,
    eventType: 'payment_confirmed',
    provider: 'fineopay',
    fineopayReference: reference,
    checkoutLinkId: order.fineopayCheckoutId,
    amount,
    paymentStatus: 'paid',
    sourceIp,
    success: true,
    metadata: { source: 'webhook', clientAccountNumber, paymentStep }
  }, { transaction });
  await enqueueEvent({
    topic: 'payment.quote.confirmed',
    aggregateType: 'order',
    aggregateId: order.id,
    idempotencyKey: `fineopay:${reference}:quote-effects`,
    payload: {
      orderId: order.id,
      quoteId: quote.id,
      interventionId: intervention?.id || null,
      reference,
      amount: Number(amount),
      paymentStep,
      executionActivated
    },
    transaction,
    model: models.OutboxEvent
  });

  return {
    order,
    quote,
    intervention,
    paymentStep,
    isSplitPayment,
    executionActivated,
    duplicate: false,
    payment
  };
});

module.exports = {
  FineoPayFinancialTransactionError,
  assertExpectedAmount,
  recordShopPayment,
  recordDiagnosticPayment,
  recordSubscriptionPayment,
  recordQuoteOrderPayment
};
