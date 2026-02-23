const express = require('express');
const router = express.Router();
const diagnosticReportController = require('../controllers/diagnosticReportController');
const quoteWorkflowController = require('../controllers/quoteWorkflowController');
const { authenticate } = require('../middleware/auth');

// ========== DIAGNOSTIC REPORTS ==========

/**
 * Technicien soumet un rapport de diagnostic
 * POST /api/diagnostic-reports
 * Body: { intervention_id, problem_description, recommended_solution, parts_needed, labor_cost, estimated_total, urgency_level, estimated_duration, photos, notes }
 */
router.post('/', authenticate, diagnosticReportController.submitReport);

/**
 * Lister les rapports de diagnostic (avec filtres)
 * GET /api/diagnostic-reports?status=submitted&technician_id=5&page=1&limit=20
 */
router.get('/', authenticate, diagnosticReportController.listReports);

/**
 * Obtenir un rapport de diagnostic par ID
 * GET /api/diagnostic-reports/:id
 */
router.get('/:id', authenticate, diagnosticReportController.getReportById);

/**
 * Admin met à jour le statut d'un rapport
 * PATCH /api/diagnostic-reports/:id/status
 * Body: { status: 'reviewed' | 'quote_sent' | 'approved' | 'rejected', notes }
 */
router.patch('/:id/status', authenticate, diagnosticReportController.updateReportStatus);

// ========== QUOTE WORKFLOW ==========

/**
 * Admin crée un devis à partir d'un rapport de diagnostic
 * POST /api/quotes/from-report
 * Body: { diagnostic_report_id, line_items, subtotal, taxAmount, discountAmount, total, notes, termsAndConditions, expiryDays }
 */
router.post('/quotes/from-report', authenticate, quoteWorkflowController.createQuoteFromReport);

/**
 * Obtenir les détails d'un devis
 * GET /api/quotes/:id/details
 */
router.get('/quotes/:id/details', authenticate, quoteWorkflowController.getQuoteDetails);

/**
 * Client accepte un devis
 * POST /api/quotes/:id/accept
 */
router.post('/quotes/:id/accept', authenticate, quoteWorkflowController.acceptQuote);

/**
 * Client rejette un devis
 * POST /api/quotes/:id/reject
 * Body: { rejection_reason: string }
 */
router.post('/quotes/:id/reject', authenticate, quoteWorkflowController.rejectQuote);

module.exports = router;
