const { Order, Intervention, CustomerProfile, User } = require('../../models');
const notificationService = require('../notificationService');
const schedulingService = require('../schedulingService');
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

const registerPaymentOutboxHandlers = () => {
  registerOutboxHandler('payment.shop.confirmed', handleShopPaymentConfirmed);
  registerOutboxHandler('payment.diagnostic.confirmed', handleDiagnosticPaymentConfirmed);
};

module.exports = {
  handleShopPaymentConfirmed,
  handleDiagnosticPaymentConfirmed,
  registerPaymentOutboxHandlers
};
