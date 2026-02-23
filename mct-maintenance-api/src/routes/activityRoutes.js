const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

// Toutes les routes nécessitent une authentification
router.use(authenticate);

/**
 * GET /api/activities/recent
 * Récupère les activités récentes du système
 */
router.get('/recent', async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    const { Notification } = require('../models');
    
    // Pour l'instant, on retourne les notifications récentes comme activités
    const activities = await Notification.findAll({
      where: { user_id: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      attributes: ['id', 'type', 'title', 'message', 'createdAt', 'is_read']
    });

    const formattedActivities = activities.map(activity => ({
      id: activity.id,
      type: activity.type,
      title: activity.title,
      message: activity.message,
      timestamp: activity.createdAt,
      read: activity.is_read
    }));

    res.json({
      success: true,
      data: formattedActivities
    });
  } catch (error) {
    console.error('❌ Error fetching recent activities:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des activités récentes',
      error: error.message
    });
  }
});

module.exports = router;
