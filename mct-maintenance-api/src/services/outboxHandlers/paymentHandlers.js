const {
  Order,
  Quote,
  Intervention,
  DiagnosticReport,
  CustomerProfile,
  User,
  Subscription,
  TechnicianProfile
} = require('../../models');
const notificationService = require('../notificationService');
const schedulingService = require('../schedulingService');
const contractSchedulingService = require('../contractSchedulingService');
const { notifyQuoteAccepted } = require('../notificationHelpers');
const { registerOutboxHandler } = require('../outboxService');

const handleShopPaymentConfirmed = async (
  { orderId, reference, amount },
  event,
  { models = { Order, CustomerProfile }, notifications = notificationService } = {}
) => {
  const order = await models.Order.findByPk(orderId);
  if (!order) throw new Error(`Commande boutique #${orderId} introuvable`);

  const customerProfile = await models.CustomerProfile.findByPk(order.customerId);
  if (!customerProfile?.user_id) {
    throw new Error(`Client de la commande boutique #${orderId} introuvable`);
  }

  const baseKey = event.idempotencyKey || `fineopay:${reference}:shop-notifications`;
  await notifications.create({
    userId: customerProfile.user_id,
    type: 'payment_confirmed',
    title: '✅ Paiement confirmé',
    message: `Votre paiement de ${amount} FCFA pour la commande #${orderId} a été confirmé.`,
    data: { orderId, order_id: orderId, amount, reference },
    priority: 'high',
    idempotencyKey: `${baseKey}:customer`
  });

  const customerName = customerProfile.first_name
    ? `${customerProfile.first_name} ${customerProfile.last_name || ''}`.trim()
    : 'Un client';
  await notifications.notifyAdmins({
    type: 'payment_received',
    title: '💰 Paiement reçu (boutique)',
    message: `Paiement de ${amount} FCFA reçu de ${customerName} (commande boutique #${orderId})`,
    data: {
      orderId,
      order_id: orderId,
      amount: Number(amount),
      paymentType: 'shop',
      reference,
      customerId: customerProfile.id
    },
    priority: 'medium',
    actionUrl: `/commandes/${orderId}`,
    idempotencyKey: `${baseKey}:admins`
  });

};

const handleDiagnosticPaymentConfirmed = async (
  { interventionId, reference, amount, paymentStep },
  event,
  {
    models = { Intervention, CustomerProfile, User },
    notifications = notificationService,
    scheduler = schedulingService
  } = {}
) => {
  const intervention = await models.Intervention.findByPk(interventionId, {
    include: [{
      model: models.CustomerProfile,
      as: 'customer',
      include: [{ model: models.User, as: 'user' }]
    }]
  });
  const customer = intervention?.customer?.user;
  if (!intervention || !customer?.id) {
    throw new Error(`Intervention diagnostic #${interventionId} ou client introuvable`);
  }

  const baseKey = event.idempotencyKey || `fineopay:${reference}:diagnostic-effects`;
  let technicianId = intervention.technician_id;
  let technicianName = 'MCT';
  if (Number(paymentStep) === 1 && !intervention.technician_id) {
    try {
      const assignment = await scheduler.autoAssignIntervention(interventionId, {
        sendNotifications: false
      });
      technicianId = assignment?.assigned_technician?.id || null;
      technicianName = assignment?.assigned_technician?.name || technicianName;
    } catch (error) {
      if (!String(error.message).includes('Aucun technicien disponible')) throw error;
    }
  }
  if (Number(paymentStep) === 1 && technicianId) {
    if (technicianName === 'MCT' && models.User.findByPk) {
      const technician = await models.User.findByPk(technicianId, {
        attributes: ['id', 'first_name', 'last_name']
      });
      technicianName = `${technician?.first_name || ''} ${technician?.last_name || ''}`.trim() || technicianName;
    }
    await notifications.create({
      userId: technicianId,
      type: 'intervention_assigned',
      title: '🔧 Nouvelle intervention assignée (Auto)',
      message: `Une intervention vous a été assignée automatiquement à ${intervention.address || 'l’adresse du client'}.`,
      data: { intervention_id: interventionId, role: 'technician' },
      priority: 'high',
      actionUrl: `/interventions/${interventionId}`,
      idempotencyKey: `${baseKey}:assignment-technician`
    });
    await notifications.create({
      userId: customer.id,
      type: 'technician_assigned',
      title: '✅ Technicien assigné',
      message: `Bonne nouvelle ! Le technicien ${technicianName} a été assigné à votre demande d’intervention.`,
      data: { intervention_id: interventionId, technician_id: technicianId, role: 'client' },
      priority: 'high',
      actionUrl: `/interventions/${interventionId}`,
      idempotencyKey: `${baseKey}:assignment-customer`
    });
  } else if (Number(paymentStep) === 1 && !technicianId) {
    await notifications.create({
      userId: customer.id,
      type: 'technician_search',
      title: '🔍 Recherche d\'équipe',
      message: 'Votre paiement est confirmé ! Nous recherchons actuellement l’équipe la plus proche.',
      data: { intervention_id: interventionId, role: 'client' },
      priority: 'high',
      idempotencyKey: `${baseKey}:technician-search`
    });
  }

  const numericAmount = Number(amount || 0);
  const isBalance = Number(paymentStep) === 2;
  const isFree = numericAmount === 0;
  const clientTitle = isFree
    ? '✅ Demande d\'intervention confirmée'
    : isBalance ? '✅ Solde confirmé' : '✅ Paiement d\'intervention confirmé';
  const clientMessage = isFree
    ? `Votre demande d'intervention #${interventionId} a été enregistrée avec succès.`
    : isBalance
      ? `Votre paiement final de ${numericAmount} FCFA pour l'intervention #${interventionId} a été confirmé.`
      : `Votre paiement de ${numericAmount} FCFA pour l'intervention #${interventionId} a été confirmé.`;
  await notifications.create({
    userId: customer.id,
    type: 'diagnostic_payment_confirmed',
    title: clientTitle,
    message: clientMessage,
    data: { intervention_id: interventionId, amount: numericAmount, reference, payment_step: paymentStep },
    priority: 'high',
    idempotencyKey: `${baseKey}:customer-confirmation`
  });

  const customerName = `${intervention.customer.first_name || ''} ${intervention.customer.last_name || ''}`.trim() || 'client';
  const adminTitle = isFree
    ? '📋 Nouvelle demande d\'intervention'
    : isBalance ? '💰 Solde d\'intervention reçu' : '💰 Paiement d\'intervention reçu';
  await notifications.notifyAdmins({
    type: 'diagnostic_payment_received',
    title: adminTitle,
    message: isFree
      ? `Nouvelle demande d'intervention #${interventionId} reçue de ${customerName} (Gratuit).`
      : `${isBalance ? 'Solde' : 'Paiement'} de ${numericAmount} FCFA reçu de ${customerName} (intervention #${interventionId}).`,
    data: {
      interventionId,
      amount: numericAmount,
      reference,
      paymentStep,
      customerId: intervention.customer.id
    },
    priority: 'medium',
    actionUrl: `/interventions/${interventionId}`,
    idempotencyKey: `${baseKey}:admins`
  });
};

const handleSubscriptionPaymentConfirmed = async (
  { subscriptionId, reference, amount, paymentStep },
  event,
  {
    models = { Subscription, User },
    notifications = notificationService,
    contractScheduler = contractSchedulingService
  } = {}
) => {
  const subscription = await models.Subscription.findByPk(subscriptionId, {
    include: [{ model: models.User, as: 'customer' }]
  });
  if (!subscription) throw new Error(`Souscription #${subscriptionId} introuvable`);

  const customerId = subscription.customer?.id || subscription.customer_id;
  if (!customerId) throw new Error(`Client de la souscription #${subscriptionId} introuvable`);

  const baseKey = event.idempotencyKey || `fineopay:${reference}:subscription-effects`;
  if (Number(paymentStep) === 1 && subscription.contract_type === 'scheduled') {
    await contractScheduler.activateContractAfterPayment(subscriptionId, reference);
  }

  if (Number(paymentStep) === 2) {
    await notifications.create({
      userId: customerId,
      type: 'payment_received',
      title: '🎉 Contrat complété !',
      message: `Votre paiement final de ${amount} FCFA a été confirmé. Merci pour votre confiance !`,
      data: { subscription_id: subscriptionId, amount: Number(amount), reference, payment_phase: 2 },
      priority: 'high',
      actionUrl: '/contrats',
      idempotencyKey: `${baseKey}:customer-final`
    });
  } else if (subscription.contract_type !== 'scheduled') {
    await notifications.create({
      userId: customerId,
      type: 'payment_confirmed',
      title: '✅ Souscription activée',
      message: `Votre paiement de ${amount} FCFA a été confirmé. Votre souscription est maintenant active !`,
      data: { subscription_id: subscriptionId, amount: Number(amount), reference },
      priority: 'high',
      idempotencyKey: `${baseKey}:customer-confirmation`
    });
  }

  const customerName = subscription.customer
    ? `${subscription.customer.first_name || ''} ${subscription.customer.last_name || ''}`.trim() || 'Un client'
    : 'Un client';
  await notifications.notifyAdmins({
    type: 'payment_received',
    title: Number(paymentStep) === 2 ? '💰 Paiement final contrat reçu' : '💰 Paiement abonnement reçu',
    message: Number(paymentStep) === 2
      ? `Second paiement de ${amount} FCFA reçu de ${customerName} - Contrat terminé`
      : `Paiement de ${amount} FCFA reçu de ${customerName} (abonnement)`,
    data: { subscriptionId, amount: Number(amount), paymentType: 'subscription', reference, paymentStep },
    priority: 'medium',
    actionUrl: '/dashboard',
    idempotencyKey: `${baseKey}:admins`
  });
};

const handleQuotePaymentConfirmed = async (
  { orderId, quoteId, interventionId, reference, amount, paymentStep, executionActivated },
  event,
  {
    models = { Order, Quote, Intervention, DiagnosticReport, CustomerProfile, User, TechnicianProfile },
    notifications = notificationService,
    scheduler = schedulingService,
    notifyQuote = notifyQuoteAccepted
  } = {}
) => {
  const order = await models.Order.findByPk(orderId, {
    include: [{
      model: models.Quote,
      as: 'quote',
      include: [
        { model: models.DiagnosticReport, as: 'diagnosticReport', required: false },
        { model: models.Intervention, as: 'intervention', include: [{ model: models.CustomerProfile, as: 'customer', include: [{ model: models.User, as: 'user' }] }] }
      ]
    }]
  });
  const quote = order?.quote;
  const intervention = quote?.intervention;
  const customer = intervention?.customer;
  if (!order || !quote || !intervention || !customer?.user_id) {
    throw new Error(`Contexte du devis payé #${quoteId || orderId} introuvable`);
  }

  const baseKey = event.idempotencyKey || `fineopay:${reference}:quote-effects`;
  if (executionActivated) {
    await notifyQuote(quote, customer, { idempotencyKey: `${baseKey}:quote-accepted` });
  }

  if (executionActivated) {
    let technicianId = intervention.technician_id;
    if (!technicianId) {
      const assignment = await scheduler.autoAssignIntervention(interventionId || intervention.id, { sendNotifications: false });
      technicianId = assignment?.assigned_technician?.id || null;
    }
    if (technicianId) {
      await notifications.create({
        userId: technicianId,
        type: 'quote_execution_confirmed',
        title: quote.execute_now ? '✅ Paiement confirmé - Exécution immédiate' : '📅 Exécution planifiée confirmée',
        message: quote.execute_now
          ? `Le client a payé le devis ${quote.reference}. Vous pouvez procéder à l’intervention immédiatement.`
          : `Le client a payé le devis ${quote.reference}. Préparez-vous pour l’intervention planifiée.`,
        data: { quote_id: quote.id, intervention_id: intervention.id, execute_now: quote.execute_now, role: 'technician' },
        priority: 'high',
        actionUrl: `/interventions/${intervention.id}`,
        idempotencyKey: `${baseKey}:technician`
      });
    } else {
      await notifications.create({
        userId: customer.user_id,
        type: 'technician_search',
        title: '🔍 Recherche d\'équipe',
        message: 'Votre paiement est confirmé ! Nous recherchons actuellement l’équipe la plus proche.',
        data: { intervention_id: intervention.id, role: 'client' },
        priority: 'high',
        idempotencyKey: `${baseKey}:technician-search`
      });
    }
  }

  await notifications.create({
    userId: customer.user_id,
    type: 'payment_success',
    title: '💳 Paiement confirmé',
    message: `Votre paiement de ${amount} FCFA pour la commande ${order.reference} a été traité avec succès.`,
    data: { order_id: orderId, amount: Number(amount), reference, payment_method: 'fineopay', payment_step: paymentStep },
    priority: 'high',
    actionUrl: `/commandes/${orderId}`,
    idempotencyKey: `${baseKey}:customer-confirmation`
  });
  await notifications.notifyAdmins({
    type: 'quote_paid',
    title: '✅ Devis payé - Exécution autorisée',
    message: `Le devis ${quote.reference} pour l’intervention #${intervention.id} a été payé par le client.`,
    data: { quote_id: quote.id, intervention_id: intervention.id, order_id: orderId, reference },
    priority: 'high',
    actionUrl: `/interventions/${intervention.id}`,
    idempotencyKey: `${baseKey}:admins`
  });
};

const registerPaymentOutboxHandlers = () => {
  registerOutboxHandler('payment.shop.confirmed', handleShopPaymentConfirmed);
  registerOutboxHandler('payment.diagnostic.confirmed', handleDiagnosticPaymentConfirmed);
  registerOutboxHandler('payment.subscription.confirmed', handleSubscriptionPaymentConfirmed);
  registerOutboxHandler('payment.quote.confirmed', handleQuotePaymentConfirmed);
};

module.exports = {
  handleShopPaymentConfirmed,
  handleDiagnosticPaymentConfirmed,
  handleSubscriptionPaymentConfirmed,
  handleQuotePaymentConfirmed,
  registerPaymentOutboxHandlers
};
