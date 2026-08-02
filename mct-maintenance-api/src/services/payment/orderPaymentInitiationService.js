const { Order, Quote, CustomerProfile } = require('../../models');

const INTERNAL_ROLES = new Set(['admin', 'manager']);

class PaymentInitiationError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = 'PaymentInitiationError';
    this.statusCode = statusCode;
  }
}

const numericValue = (value) => {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const resolveCustomerAccess = async (user, order) => {
  if (INTERNAL_ROLES.has(user?.role)) return;

  if (user?.role !== 'customer') {
    throw new PaymentInitiationError(403, 'Accès refusé à ce paiement');
  }

  const customerProfile = await CustomerProfile.findOne({
    where: { user_id: user.id },
    attributes: ['id']
  });
  const allowedCustomerIds = new Set([String(user.id)]);

  if (customerProfile?.id !== undefined && customerProfile?.id !== null) {
    allowedCustomerIds.add(String(customerProfile.id));
  }

  if (!allowedCustomerIds.has(String(order.customerId))) {
    // Réponse volontairement identique à une commande absente pour éviter
    // de révéler l'existence d'une commande appartenant à un autre client.
    throw new PaymentInitiationError(404, 'Commande non trouvée');
  }
};

const ensurePositiveAmount = (amount) => {
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new PaymentInitiationError(409, 'Montant de paiement invalide en base');
  }
  return amount;
};

const resolveSplitPayment = (order, quote) => {
  if (!quote) {
    throw new PaymentInitiationError(
      409,
      'Le devis associé est requis pour un paiement en plusieurs étapes'
    );
  }

  const firstStatus = quote.first_payment_status || 'pending';
  const secondStatus = quote.second_payment_status || 'pending';

  if (quote.payment_status === 'paid' || secondStatus === 'paid') {
    throw new PaymentInitiationError(409, 'Ce devis est déjà entièrement payé');
  }

  const quoteTotal = numericValue(quote.total);
  const firstAmount = numericValue(quote.first_payment_amount)
    ?? numericValue(order.totalAmount)
    ?? (quoteTotal !== null ? Math.ceil(quoteTotal / 2) : null);

  if (firstStatus !== 'paid') {
    if (order.status !== 'pending') {
      throw new PaymentInitiationError(409, 'Cette commande ne peut pas recevoir un nouvel acompte');
    }
    if (order.paymentStatus === 'paid') {
      throw new PaymentInitiationError(
        409,
        'État de paiement incohérent : acompte commande payé mais devis non payé'
      );
    }

    return {
      paymentStep: 1,
      amount: ensurePositiveAmount(firstAmount)
    };
  }

  const secondAmount = numericValue(quote.second_payment_amount)
    ?? (quoteTotal !== null && firstAmount !== null ? quoteTotal - firstAmount : null);

  return {
    paymentStep: 2,
    amount: ensurePositiveAmount(secondAmount)
  };
};

const resolveFullPayment = (order, quote) => {
  if (order.paymentStatus === 'paid' || quote?.payment_status === 'paid') {
    throw new PaymentInitiationError(409, 'Cette commande est déjà payée');
  }

  if (!['pending', 'failed'].includes(order.paymentStatus || 'pending')) {
    throw new PaymentInitiationError(409, 'Cette commande ne peut pas être payée dans son état actuel');
  }
  if (order.status !== 'pending') {
    throw new PaymentInitiationError(409, 'Cette commande est déjà en cours de traitement');
  }

  const amount = numericValue(quote?.total) ?? numericValue(order.totalAmount);
  return {
    paymentStep: 0,
    amount: ensurePositiveAmount(amount)
  };
};

const resolveOrderPaymentInitiation = async ({ orderId, user }) => {
  const normalizedOrderId = Number(orderId);
  if (!Number.isInteger(normalizedOrderId) || normalizedOrderId <= 0) {
    throw new PaymentInitiationError(400, 'orderId doit être un entier positif');
  }

  const order = await Order.findByPk(normalizedOrderId, {
    include: [{ model: Quote, as: 'quote', required: false }]
  });

  if (!order) {
    throw new PaymentInitiationError(404, 'Commande non trouvée');
  }

  await resolveCustomerAccess(user, order);

  if (order.status === 'cancelled' || order.status === 'completed') {
    throw new PaymentInitiationError(409, 'Cette commande ne peut plus être payée');
  }
  if (order.paymentStatus === 'refunded') {
    throw new PaymentInitiationError(409, 'Cette commande a été remboursée');
  }

  const quote = order.quote || null;
  const paymentType = order.paymentType || order.payment_type || 'full';
  const payment = paymentType === 'split'
    ? resolveSplitPayment(order, quote)
    : resolveFullPayment(order, quote);
  const reference = order.reference || `#${order.id}`;
  const paymentLabel = payment.paymentStep === 1
    ? 'Premier paiement (50%)'
    : payment.paymentStep === 2
      ? 'Solde final (50%)'
      : 'Paiement intégral';

  return {
    order,
    amount: payment.amount,
    paymentStep: payment.paymentStep,
    title: `Commande ${reference} - ${paymentLabel}`,
    description: `${paymentLabel} pour la commande ${reference}`
  };
};

module.exports = {
  resolveOrderPaymentInitiation,
  PaymentInitiationError
};
