'use strict';

const { RefundRequest, Intervention, Order, Payment, CustomerProfile, User } = require('../models');
const { sequelize } = require('../config/database');

class RefundError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.name = 'RefundError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

/**
 * Crée une demande de remboursement formelle
 */
const createRefundRequest = async ({
  user,
  interventionId,
  orderId,
  paymentId,
  amount,
  reason
}) => {
  if (!user) {
    throw new RefundError(401, 'AUTH_REQUIRED', 'Authentification requise');
  }

  if (!reason || String(reason).trim().length === 0) {
    throw new RefundError(400, 'REASON_REQUIRED', 'Un motif de remboursement est requis');
  }

  let customerId = null;
  if (user.role === 'customer') {
    const profile = await CustomerProfile.findOne({ where: { user_id: user.id } });
    if (!profile) {
      throw new RefundError(400, 'CUSTOMER_PROFILE_NOT_FOUND', 'Profil client introuvable');
    }
    customerId = profile.id;
  }

  let targetAmount = amount;

  if (interventionId) {
    const intervention = await Intervention.findByPk(interventionId);
    if (!intervention) {
      throw new RefundError(404, 'INTERVENTION_NOT_FOUND', 'Intervention introuvable');
    }
    if (user.role === 'customer' && Number(intervention.customer_id) !== Number(customerId)) {
      throw new RefundError(403, 'ACCESS_DENIED', 'Vous n’êtes pas le propriétaire de cette intervention');
    }
    if (!targetAmount) {
      targetAmount = Number(intervention.final_price || intervention.estimated_price || 0);
    }
  } else if (orderId) {
    const order = await Order.findByPk(orderId);
    if (!order) {
      throw new RefundError(404, 'ORDER_NOT_FOUND', 'Commande introuvable');
    }
    if (user.role === 'customer' && Number(order.customerId) !== Number(customerId) && Number(order.userId) !== Number(user.id)) {
      throw new RefundError(403, 'ACCESS_DENIED', 'Vous n’êtes pas le propriétaire de cette commande');
    }
    if (!targetAmount) {
      targetAmount = Number(order.totalAmount || 0);
    }
  }

  if (!targetAmount || targetAmount <= 0) {
    throw new RefundError(400, 'INVALID_AMOUNT', 'Le montant du remboursement doit être supérieur à 0');
  }

  const existingRequest = await RefundRequest.findOne({
    where: {
      user_id: user.id,
      ...(interventionId ? { intervention_id: interventionId } : {}),
      ...(orderId ? { order_id: orderId } : {}),
      status: ['requested', 'approved']
    }
  });

  if (existingRequest) {
    throw new RefundError(409, 'REFUND_ALREADY_REQUESTED', 'Une demande de remboursement est déjà en cours pour cette ressource');
  }

  const refundRequest = await RefundRequest.create({
    user_id: user.id,
    customer_id: customerId,
    intervention_id: interventionId || null,
    order_id: orderId || null,
    payment_id: paymentId || null,
    amount: targetAmount,
    reason: String(reason).trim(),
    status: 'requested'
  });

  return refundRequest;
};

/**
 * Traitement idempotent d'une demande de remboursement par un Admin/Manager
 */
const processRefundRequest = async ({
  requestId,
  action,
  amount,
  adminNote,
  idempotencyKey
}) => {
  if (!['approve', 'process', 'reject'].includes(action)) {
    throw new RefundError(400, 'INVALID_ACTION', 'Action invalide. Valeurs autorisées: approve, process, reject');
  }

  if (idempotencyKey) {
    const existing = await RefundRequest.findOne({ where: { idempotency_key: idempotencyKey } });
    if (existing && existing.id !== Number(requestId)) {
      return existing;
    }
  }

  const transaction = await sequelize.transaction();

  try {
    const isPostgres = sequelize.getDialect() === 'postgres';
    const refundRequest = await RefundRequest.findByPk(requestId, {
      transaction,
      ...(isPostgres ? { lock: true } : {})
    });
    if (!refundRequest) {
      await transaction.rollback();
      throw new RefundError(404, 'REFUND_REQUEST_NOT_FOUND', 'Demande de remboursement introuvable');
    }

    if (refundRequest.status === 'processed' || refundRequest.status === 'rejected') {
      await transaction.rollback();
      return refundRequest; // Idempotent: renvoie l'état déjà finalisé
    }

    if (action === 'reject') {
      await refundRequest.update({
        status: 'rejected',
        admin_note: adminNote || refundRequest.admin_note,
        idempotency_key: idempotencyKey || refundRequest.idempotency_key,
        rejected_at: new Date()
      }, { transaction });

      await transaction.commit();
      return refundRequest;
    }

    if (action === 'approve') {
      await refundRequest.update({
        status: 'approved',
        admin_note: adminNote || refundRequest.admin_note,
        idempotency_key: idempotencyKey || refundRequest.idempotency_key
      }, { transaction });

      await transaction.commit();
      return refundRequest;
    }

    if (action === 'process') {
      const finalAmount = amount || refundRequest.amount;

      // Marquer le paiement comme remboursé si associé
      if (refundRequest.payment_id) {
        const payment = await Payment.findByPk(refundRequest.payment_id, { transaction });
        if (payment) {
          await payment.update({
            status: 'refunded',
            refundedAt: new Date(),
            refundAmount: finalAmount,
            refundReason: refundRequest.reason
          }, { transaction });
        }
      }

      if (refundRequest.order_id) {
        const order = await Order.findByPk(refundRequest.order_id, { transaction });
        if (order) {
          await order.update({ paymentStatus: 'refunded' }, { transaction });
        }
      }

      await refundRequest.update({
        status: 'processed',
        amount: finalAmount,
        admin_note: adminNote || refundRequest.admin_note,
        idempotency_key: idempotencyKey || refundRequest.idempotency_key,
        processed_at: new Date()
      }, { transaction });

      await transaction.commit();
      return refundRequest;
    }
  } catch (error) {
    if (!transaction.finished) {
      await transaction.rollback();
    }
    throw error;
  }
};

module.exports = {
  RefundError,
  createRefundRequest,
  processRefundRequest
};
