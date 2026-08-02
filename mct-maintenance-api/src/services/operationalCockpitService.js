const { Op } = require('sequelize');
const {
  Intervention,
  Order,
  Quote,
  CustomerProfile,
  TechnicianProfile,
  Subscription,
  RefundRequest
} = require('../models');

/**
 * Calcule le cockpit des exceptions opérationnelles actives.
 * Retourne les alertes regroupées par catégorie métier.
 */
async function buildOperationalAlerts() {
  const now = new Date();
  const threeDaysAgo = new Date(now - 3 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
  const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

  const [
    failedPayments,
    unassignedInterventions,
    lateInterventions,
    expiredQuotes,
    nearExpiryContracts,
    pendingRefunds,
    pendingDiagnosticPayments
  ] = await Promise.all([
    // 1. Commandes avec paiement échoué ou bloqué depuis > 3 jours
    Order.findAll({
      where: {
        payment_status: { [Op.in]: ['failed', 'pending'] },
        created_at: { [Op.lt]: threeDaysAgo }
      },
      include: [{ association: 'customer', required: false }],
      order: [['created_at', 'ASC']],
      limit: 50
    }),

    // 2. Interventions sans technicien assigné depuis > 24h
    Intervention.findAll({
      where: {
        status: 'pending',
        technician_id: null,
        created_at: { [Op.lt]: new Date(now - 24 * 60 * 60 * 1000) }
      },
      include: [{ association: 'customer', required: false }],
      order: [['created_at', 'ASC']],
      limit: 50
    }),

    // 3. Interventions en retard (scheduled_date dépassée, pas encore terminée)
    Intervention.findAll({
      where: {
        status: { [Op.in]: ['assigned', 'in_progress'] },
        scheduled_date: { [Op.lt]: now }
      },
      include: [
        { association: 'customer', required: false },
        { association: 'technician', required: false }
      ],
      order: [['scheduled_date', 'ASC']],
      limit: 50
    }),

    // 4. Devis expirés (créés depuis > 7 jours) en attente d'acceptation
    Quote.findAll({
      where: {
        status: 'pending',
        created_at: { [Op.lt]: sevenDaysAgo }
      },
      include: [{ association: 'intervention', required: false }],
      order: [['created_at', 'ASC']],
      limit: 50
    }),

    // 5. Souscriptions actives arrivant à échéance dans 30 jours
    Subscription.findAll({
      where: {
        status: 'active',
        end_date: { [Op.between]: [now, thirtyDaysFromNow] }
      },
      order: [['end_date', 'ASC']],
      limit: 50
    }),

    // 6. Demandes de remboursement en attente de traitement
    RefundRequest.findAll({
      where: { status: 'requested' },
      order: [['created_at', 'ASC']],
      limit: 50
    }),

    // 7. Interventions bloquées en attente de paiement du diagnostic
    Intervention.findAll({
      where: {
        status: 'pending_payment',
        diagnostic_paid: false,
        created_at: { [Op.lt]: threeDaysAgo }
      },
      include: [{ association: 'customer', required: false }],
      order: [['created_at', 'ASC']],
      limit: 50
    })
  ]);

  return {
    summary: {
      total_alerts:
        failedPayments.length +
        unassignedInterventions.length +
        lateInterventions.length +
        expiredQuotes.length +
        nearExpiryContracts.length +
        pendingRefunds.length +
        pendingDiagnosticPayments.length,
      generated_at: now.toISOString()
    },
    alerts: {
      failed_payments: {
        count: failedPayments.length,
        label: 'Paiements échoués ou bloqués (> 3 jours)',
        severity: failedPayments.length > 0 ? 'critical' : 'ok',
        items: failedPayments.map(o => ({
          id: o.id,
          reference: o.reference,
          amount: o.total_amount,
          payment_status: o.payment_status,
          created_at: o.created_at
        }))
      },
      unassigned_interventions: {
        count: unassignedInterventions.length,
        label: 'Interventions sans technicien (> 24h)',
        severity: unassignedInterventions.length > 0 ? 'critical' : 'ok',
        items: unassignedInterventions.map(i => ({
          id: i.id,
          title: i.title,
          priority: i.priority,
          scheduled_date: i.scheduled_date,
          created_at: i.created_at
        }))
      },
      late_interventions: {
        count: lateInterventions.length,
        label: 'Interventions en retard par rapport à la date prévue',
        severity: lateInterventions.length > 0 ? 'warning' : 'ok',
        items: lateInterventions.map(i => ({
          id: i.id,
          title: i.title,
          status: i.status,
          scheduled_date: i.scheduled_date,
          minutes_late: Math.floor((now - new Date(i.scheduled_date)) / 60000)
        }))
      },
      expired_quotes: {
        count: expiredQuotes.length,
        label: 'Devis en attente depuis > 7 jours',
        severity: expiredQuotes.length > 0 ? 'warning' : 'ok',
        items: expiredQuotes.map(q => ({
          id: q.id,
          amount: q.total_amount,
          intervention_id: q.intervention_id,
          created_at: q.created_at,
          days_old: Math.floor((now - new Date(q.created_at)) / (1000 * 60 * 60 * 24))
        }))
      },
      near_expiry_contracts: {
        count: nearExpiryContracts.length,
        label: 'Souscriptions arrivant à échéance dans 30 jours',
        severity: nearExpiryContracts.length > 0 ? 'info' : 'ok',
        items: nearExpiryContracts.map(s => ({
          id: s.id,
          customer_id: s.customer_id,
          end_date: s.end_date,
          days_remaining: Math.floor((new Date(s.end_date) - now) / (1000 * 60 * 60 * 24))
        }))
      },
      pending_refunds: {
        count: pendingRefunds.length,
        label: 'Demandes de remboursement en attente de traitement',
        severity: pendingRefunds.length > 0 ? 'warning' : 'ok',
        items: pendingRefunds.map(r => ({
          id: r.id,
          amount: r.amount,
          reason: r.reason,
          created_at: r.created_at
        }))
      },
      pending_diagnostic_payments: {
        count: pendingDiagnosticPayments.length,
        label: 'Interventions bloquées en attente du paiement diagnostic (> 3 jours)',
        severity: pendingDiagnosticPayments.length > 0 ? 'warning' : 'ok',
        items: pendingDiagnosticPayments.map(i => ({
          id: i.id,
          title: i.title,
          diagnostic_fee: i.diagnostic_fee,
          created_at: i.created_at
        }))
      }
    }
  };
}

module.exports = { buildOperationalAlerts };
