const notificationService = require('../services/notificationService');
const { User } = require('../models');
const { Op } = require('sequelize');

/**
 * Envoyer une notification broadcast
 * Permet aux admins d'envoyer des notifications à plusieurs utilisateurs
 */
const sendBroadcastNotification = async (req, res) => {
  try {
    const {
      recipients, // { type: 'all' | 'customers' | 'technicians' | 'specific', userIds?: [] }
      notification // { type, title, message, priority, actionUrl }
    } = req.body;

    // Validation
    if (!recipients || !notification) {
      return res.status(400).json({
        success: false,
        message: 'Données manquantes: recipients et notification requis'
      });
    }

    if (!notification.title || !notification.message) {
      return res.status(400).json({
        success: false,
        message: 'Le titre et le message sont obligatoires'
      });
    }

    // Déterminer les utilisateurs destinataires
    let targetUsers = [];
    let whereClause = { status: 'active' };

    switch (recipients.type) {
      case 'all':
        // Tous les utilisateurs actifs
        console.log('📢 Broadcast: Tous les utilisateurs');
        whereClause.role = { [Op.in]: ['customer', 'technician'] };
        break;

      case 'customers':
        // Tous les clients
        console.log('📢 Broadcast: Tous les clients');
        whereClause.role = 'customer';
        break;

      case 'technicians':
        // Tous les techniciens
        console.log('📢 Broadcast: Tous les techniciens');
        whereClause.role = 'technician';
        break;

      case 'specific':
        // Utilisateurs spécifiques
        if (!recipients.userIds || !Array.isArray(recipients.userIds) || recipients.userIds.length === 0) {
          return res.status(400).json({
            success: false,
            message: 'userIds requis pour le type "specific"'
          });
        }
        console.log('📢 Broadcast: Utilisateurs spécifiques:', recipients.userIds);
        whereClause.id = { [Op.in]: recipients.userIds };
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Type de destinataire invalide'
        });
    }

    // Récupérer les utilisateurs
    targetUsers = await User.findAll({
      where: whereClause,
      attributes: ['id', 'email', 'role']
    });

    if (targetUsers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Aucun utilisateur trouvé correspondant aux critères'
      });
    }

    console.log(`📨 Envoi de notification à ${targetUsers.length} utilisateur(s)`);

    // Envoyer la notification à tous les utilisateurs
    const userIds = targetUsers.map(u => u.id);
    
    // Dédupliquer les IDs au cas où
    const uniqueUserIds = [...new Set(userIds)];
    if (uniqueUserIds.length !== userIds.length) {
      console.warn(`⚠️  Doublons détectés: ${userIds.length} -> ${uniqueUserIds.length} utilisateurs uniques`);
    }
    
    console.log(`📋 Liste des utilisateurs cibles: ${uniqueUserIds.join(', ')}`);
    
    const notificationData = {
      type: notification.type || 'general',
      title: notification.title,
      message: notification.message,
      priority: notification.priority || 'medium',
      actionUrl: notification.actionUrl || null,
      data: notification.data || null
    };

    const results = await notificationService.createBulk(uniqueUserIds, notificationData);

    console.log(`✅ ${results.length} notification(s) créée(s)`);

    res.json({
      success: true,
      message: `Notification envoyée à ${results.length} utilisateur(s)`,
      data: {
        sent_count: results.length,
        recipients: targetUsers.map(u => ({
          id: u.id,
          email: u.email,
          role: u.role
        }))
      }
    });

  } catch (error) {
    console.error('❌ Erreur envoi broadcast:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification',
      error: error.message
    });
  }
};

/**
 * Récupérer les statistiques d'envoi
 */
const getBroadcastStats = async (req, res) => {
  try {
    const totalUsers = await User.count({
      where: {
        status: 'active',
        role: { [Op.in]: ['customer', 'technician'] }
      }
    });

    const totalCustomers = await User.count({
      where: { status: 'active', role: 'customer' }
    });

    const totalTechnicians = await User.count({
      where: { status: 'active', role: 'technician' }
    });

    res.json({
      success: true,
      data: {
        total_users: totalUsers,
        total_customers: totalCustomers,
        total_technicians: totalTechnicians
      }
    });

  } catch (error) {
    console.error('❌ Erreur stats broadcast:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
};

/**
 * Récupérer la liste des utilisateurs (pour sélection)
 */
const getUsers = async (req, res) => {
  try {
    const { role, search } = req.query;

    let whereClause = {
      status: 'active',
      role: { [Op.in]: ['customer', 'technician'] }
    };

    if (role) {
      whereClause.role = role;
    }

    if (search) {
      whereClause[Op.or] = [
        { email: { [Op.like]: `%${search}%` } },
        { first_name: { [Op.like]: `%${search}%` } },
        { last_name: { [Op.like]: `%${search}%` } }
      ];
    }

    const users = await User.findAll({
      where: whereClause,
      attributes: ['id', 'email', 'first_name', 'last_name', 'role'],
      limit: 100,
      order: [['email', 'ASC']]
    });

    res.json({
      success: true,
      data: users
    });

  } catch (error) {
    console.error('❌ Erreur récupération utilisateurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des utilisateurs'
    });
  }
};

module.exports = {
  sendBroadcastNotification,
  getBroadcastStats,
  getUsers
};
