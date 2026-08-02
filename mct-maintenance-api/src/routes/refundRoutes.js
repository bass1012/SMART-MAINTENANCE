'use strict';

const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { RefundRequest, CustomerProfile } = require('../models');
const { createRefundRequest, processRefundRequest, RefundError } = require('../services/refundManagementService');

// Créer une demande de remboursement (Client ou Admin/Manager)
router.post('/request', authenticate, async (req, res, next) => {
  try {
    const { interventionId, orderId, paymentId, amount, reason } = req.body;
    const refundRequest = await createRefundRequest({
      user: req.user,
      interventionId,
      orderId,
      paymentId,
      amount,
      reason
    });

    res.status(201).json({
      success: true,
      message: 'Demande de remboursement enregistrée avec succès',
      data: refundRequest
    });
  } catch (error) {
    if (error instanceof RefundError) {
      return res.status(error.statusCode).json({
        success: false,
        code: error.code,
        message: error.message
      });
    }
    next(error);
  }
});

// Consulter ses propres demandes de remboursement (Client)
router.get('/my-requests', authenticate, async (req, res, next) => {
  try {
    const where = { user_id: req.user.id };
    const requests = await RefundRequest.findAll({
      where,
      order: [['created_at', 'DESC']]
    });

    res.status(200).json({
      success: true,
      count: requests.length,
      data: requests
    });
  } catch (error) {
    next(error);
  }
});

// Liste globale des remboursements (Admin / Manager)
router.get('/admin/all', authenticate, authorize('admin', 'manager'), async (req, res, next) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) {
      where.status = status;
    }

    const requests = await RefundRequest.findAll({
      where,
      order: [['created_at', 'DESC']]
    });

    res.status(200).json({
      success: true,
      count: requests.length,
      data: requests
    });
  } catch (error) {
    next(error);
  }
});

// Traiter/Valider/Refuser un remboursement (Admin / Manager)
router.post('/admin/:id/process', authenticate, authorize('admin', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { action, amount, adminNote, idempotencyKey } = req.body;

    const result = await processRefundRequest({
      requestId: id,
      action,
      amount,
      adminNote,
      idempotencyKey
    });

    res.status(200).json({
      success: true,
      message: `Demande de remboursement mise à jour (action: ${action})`,
      data: result
    });
  } catch (error) {
    if (error instanceof RefundError) {
      return res.status(error.statusCode).json({
        success: false,
        code: error.code,
        message: error.message
      });
    }
    next(error);
  }
});

module.exports = router;
