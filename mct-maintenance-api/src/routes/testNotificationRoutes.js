const express = require('express');
const router = express.Router();
const { User } = require('../models');
const fcmService = require('../services/fcmService');

/**
 * POST /api/test/notification/:userId
 * Envoyer une notification de test à un utilisateur spécifique
 */
router.post('/notification/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`\n🧪 TEST NOTIFICATION pour user ${userId}`);
    
    // Récupérer l'utilisateur
    const user = await User.findByPk(userId, {
      attributes: ['id', 'first_name', 'last_name', 'fcm_token']
    });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    if (!user.fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'Utilisateur n\'a pas de token FCM'
      });
    }
    
    console.log(`   User: ${user.first_name} ${user.last_name}`);
    console.log(`   Token: ${user.fcm_token.substring(0, 30)}...`);
    
    // Envoyer la notification de test
    const result = await fcmService.sendToDevice(
      user.fcm_token,
      {
        title: '🧪 Test iOS Notification',
        body: `Bonjour ${user.first_name}, si vous voyez ceci, les notifications fonctionnent !`
      },
      {
        type: 'test',
        userId: userId.toString(),
        timestamp: Date.now().toString()
      }
    );
    
    if (result) {
      console.log(`✅ Notification de test envoyée avec succès`);
      console.log(`   Message ID: ${result}`);
      
      res.json({
        success: true,
        message: 'Notification de test envoyée',
        data: {
          messageId: result,
          user: {
            id: user.id,
            name: `${user.first_name} ${user.last_name}`,
            hasToken: true
          }
        }
      });
    } else {
      console.log(`⚠️  Notification non envoyée (pas de résultat)`);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de la notification'
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur test notification:', error);
    res.status(500).json({
      success: false,
      message: error.message,
      error: error.code || 'UNKNOWN_ERROR'
    });
  }
});

/**
 * GET /api/test/notification/check/:userId
 * Vérifier le token FCM d'un utilisateur
 */
router.get('/notification/check/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const user = await User.findByPk(userId, {
      attributes: ['id', 'first_name', 'last_name', 'fcm_token', 'role']
    });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    res.json({
      success: true,
      data: {
        userId: user.id,
        name: `${user.first_name} ${user.last_name}`,
        role: user.role,
        hasToken: !!user.fcm_token,
        tokenPreview: user.fcm_token ? `${user.fcm_token.substring(0, 30)}...` : null
      }
    });
    
  } catch (error) {
    console.error('Erreur check token:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
