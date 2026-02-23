const express = require('express');
const router = express.Router();
const { cleanupExpiredCodes, getCodesStats } = require('../utils/cleanupExpiredCodes');
const cronService = require('../services/cronService');
const { authenticate, authorize } = require('../middleware/auth');

/**
 * GET /api/maintenance/cleanup/stats
 * Obtenir les statistiques des codes
 * Accessible uniquement aux admins
 */
router.get('/stats', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const stats = await getCodesStats();
    
    if (!stats) {
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des statistiques'
      });
    }

    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('❌ [Cleanup API] Erreur stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * POST /api/maintenance/cleanup/run
 * Déclencher le nettoyage manuellement
 * Accessible uniquement aux admins
 */
router.post('/run', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const result = await cleanupExpiredCodes();
    
    res.json({
      success: result.success,
      message: result.success 
        ? `Nettoyage effectué: ${result.totalDeleted} code(s) supprimé(s)`
        : 'Erreur lors du nettoyage',
      details: {
        emailCodesDeleted: result.emailCodesDeleted,
        resetCodesDeleted: result.resetCodesDeleted,
        totalDeleted: result.totalDeleted
      }
    });
  } catch (error) {
    console.error('❌ [Cleanup API] Erreur nettoyage:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * GET /api/maintenance/cron/status
 * Obtenir le statut des jobs cron
 * Accessible uniquement aux admins
 */
router.get('/cron/status', authenticate, authorize(['admin']), (req, res) => {
  try {
    const jobs = cronService.getJobsStatus();
    
    res.json({
      success: true,
      jobs,
      totalJobs: jobs.length
    });
  } catch (error) {
    console.error('❌ [Cron API] Erreur statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

module.exports = router;
