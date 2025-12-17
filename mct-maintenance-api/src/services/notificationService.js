const Notification = require('../models/Notification');
const { User } = require('../models');
const { Op } = require('sequelize');
const fcmService = require('./fcmService');

class NotificationService {
  constructor() {
    this.io = null;
    this.connectedUsers = new Map(); // userId -> socketId
  }

  // Initialiser Socket.IO
  initialize(io) {
    this.io = io;
    console.log('✅ Service de notifications initialisé');

    // Gérer les connexions Socket.IO
    io.on('connection', (socket) => {
      console.log(`🔌 Client connecté: ${socket.id}`);

      // Authentifier l'utilisateur
      socket.on('authenticate', (userId) => {
        if (userId) {
          this.connectedUsers.set(userId, socket.id);
          socket.userId = userId;
          console.log(`✅ Utilisateur ${userId} authentifié sur socket ${socket.id}`);
          
          // Rejoindre une room spécifique à l'utilisateur
          socket.join(`user:${userId}`);
          
          // Rejoindre une room pour son rôle
          User.findByPk(userId).then(user => {
            if (user) {
              socket.join(`role:${user.role}`);
              console.log(`✅ Utilisateur ${userId} a rejoint la room role:${user.role}`);
            }
          });
        }
      });

      // Marquer une notification comme lue
      socket.on('mark_read', async (notificationId) => {
        try {
          await this.markAsRead(notificationId);
          socket.emit('notification_read', { notificationId });
        } catch (error) {
          console.error('❌ Erreur mark_read:', error);
        }
      });

      // Marquer toutes les notifications comme lues
      socket.on('mark_all_read', async (userId) => {
        try {
          await this.markAllAsRead(userId);
          socket.emit('all_notifications_read');
        } catch (error) {
          console.error('❌ Erreur mark_all_read:', error);
        }
      });

      // Déconnexion
      socket.on('disconnect', () => {
        if (socket.userId) {
          this.connectedUsers.delete(socket.userId);
          console.log(`🔌 Utilisateur ${socket.userId} déconnecté`);
        }
      });
    });
  }

  // Créer et envoyer une notification
  async create({
    userId,
    type,
    title,
    message,
    data = null,
    priority = 'medium',
    actionUrl = null
  }) {
    try {
      // Créer la notification en base de données
      const notification = await Notification.create({
        user_id: userId,
        type,
        title,
        message,
        data,
        priority,
        action_url: actionUrl,
        is_read: false
      });

      console.log(`📬 Notification créée [ID: ${notification.id}] pour user ${userId}: ${title}`);

      // Envoyer en temps réel via Socket.IO
      let socketSent = false;
      if (this.io) {
        const room = `user:${userId}`;
        const socketsInRoom = await this.io.in(room).fetchSockets();
        
        console.log(`🔌 [Notif ${notification.id}] Tentative d'envoi Socket.IO à la room "${room}"`);
        console.log(`👤 [Notif ${notification.id}] ${socketsInRoom.length} client(s) connecté(s) dans cette room`);
        
        this.io.to(room).emit('new_notification', {
          id: notification.id,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          data: notification.data,
          priority: notification.priority,
          action_url: notification.action_url,
          created_at: notification.created_at,
          updated_at: notification.updated_at,
          is_read: notification.is_read,
          user_id: notification.user_id
        });
        
        if (socketsInRoom.length > 0) {
          console.log(`🔔 [Notif ${notification.id}] Notification envoyée en temps réel à ${socketsInRoom.length} client(s) de user ${userId}`);
          socketSent = true;
        } else {
          console.log(`⚠️  [Notif ${notification.id}] Aucun client connecté pour user ${userId}, notification stockée uniquement en DB`);
        }
      } else {
        console.log(`⚠️  [Notif ${notification.id}] Socket.IO non initialisé`);
      }

      // Envoyer notification push via FCM SEULEMENT si l'utilisateur n'est pas connecté via Socket.IO
      if (!socketSent) {
        try {
          const user = await User.findByPk(userId, { attributes: ['fcm_token'] });
          if (user && user.fcm_token) {
            console.log(`📱 [Notif ${notification.id}] Utilisateur ${userId} non connecté, envoi FCM...`);
            await fcmService.sendToDevice(
              user.fcm_token,
              { title, body: message },
              {
                type,
                priority,
                actionUrl: actionUrl || '',
                notificationId: notification.id.toString(),
                ...data
              }
            );
            console.log(`✅ [Notif ${notification.id}] FCM envoyé avec succès pour user ${userId}`);
          } else {
            console.log(`⚠️  [Notif ${notification.id}] Pas de FCM token pour user ${userId}`);
          }
        } catch (fcmError) {
          console.error(`⚠️  [Notif ${notification.id}] Erreur envoi FCM (ignorée):`, fcmError.message);
          // Ne pas bloquer si FCM échoue
        }
      } else {
        console.log(`✓ [Notif ${notification.id}] Utilisateur ${userId} connecté, pas d'envoi FCM (éviter doublon)`);
      }

      return notification;
    } catch (error) {
      console.error('❌ Erreur création notification:', error);
      throw error;
    }
  }

  // Créer des notifications pour plusieurs utilisateurs
  async createBulk(userIds, notificationData) {
    try {
      const notifications = await Promise.all(
        userIds.map(userId => this.create({ ...notificationData, userId }))
      );
      return notifications;
    } catch (error) {
      console.error('❌ Erreur création notifications bulk:', error);
      throw error;
    }
  }

  // Créer une notification pour tous les admins
  async notifyAdmins(notificationData) {
    try {
      console.log('👥 Recherche des admins actifs...');
      const admins = await User.findAll({
        where: { role: 'admin', status: 'active' }
      });
      
      console.log(`👥 ${admins.length} admin(s) trouvé(s):`, admins.map(a => ({ id: a.id, email: a.email })));
      
      if (admins.length === 0) {
        console.warn('⚠️  Aucun admin actif trouvé, notifications non envoyées');
        return [];
      }
      
      const adminIds = admins.map(admin => admin.id);
      console.log('📬 Envoi de notifications à', adminIds.length, 'admin(s)');
      const result = await this.createBulk(adminIds, notificationData);
      console.log('✅ Notifications créées pour les admins');
      return result;
    } catch (error) {
      console.error('❌ Erreur notification admins:', error);
      throw error;
    }
  }

  // Créer une notification pour tous les techniciens
  async notifyTechnicians(notificationData) {
    try {
      const technicians = await User.findAll({
        where: { role: 'technician', status: 'active' }
      });
      
      const technicianIds = technicians.map(tech => tech.id);
      return await this.createBulk(technicianIds, notificationData);
    } catch (error) {
      console.error('❌ Erreur notification techniciens:', error);
      throw error;
    }
  }

  // Récupérer les notifications d'un utilisateur
  async getUserNotifications(userId, { limit = 50, offset = 0, unreadOnly = false } = {}) {
    try {
      const where = { user_id: userId };
      if (unreadOnly) {
        where.is_read = false;
      }

      const result = await Notification.findAndCountAll({
        where,
        order: [['created_at', 'DESC']],
        limit,
        offset
      });

      // Transformer les données pour s'assurer du format snake_case
      const transformedRows = result.rows.map(notification => {
        const data = notification.toJSON();
        return {
          id: data.id,
          user_id: data.user_id,
          type: data.type,
          title: data.title,
          message: data.message,
          data: data.data,
          is_read: data.is_read,
          read_at: data.read_at,
          priority: data.priority,
          action_url: data.action_url,
          created_at: data.createdAt || data.created_at,
          updated_at: data.updatedAt || data.updated_at
        };
      });

      return {
        rows: transformedRows,
        count: result.count
      };
    } catch (error) {
      console.error('❌ Erreur récupération notifications:', error);
      throw error;
    }
  }

  // Compter les notifications non lues
  async getUnreadCount(userId) {
    try {
      const count = await Notification.count({
        where: {
          user_id: userId,
          is_read: false
        }
      });
      return count;
    } catch (error) {
      console.error('❌ Erreur comptage notifications:', error);
      throw error;
    }
  }

  // Marquer une notification comme lue
  async markAsRead(notificationId) {
    try {
      const notification = await Notification.findByPk(notificationId);
      if (notification && !notification.is_read) {
        await notification.update({
          is_read: true,
          read_at: new Date()
        });
        console.log(`✅ Notification ${notificationId} marquée comme lue`);
      }
      return notification;
    } catch (error) {
      console.error('❌ Erreur marquage notification:', error);
      throw error;
    }
  }

  // Marquer une notification comme non lue
  async markAsUnread(notificationId) {
    try {
      const notification = await Notification.findByPk(notificationId);
      if (notification && notification.is_read) {
        await notification.update({
          is_read: false,
          read_at: null
        });
        console.log(`✅ Notification ${notificationId} marquée comme non lue`);
      }
      return notification;
    } catch (error) {
      console.error('❌ Erreur marquage notification:', error);
      throw error;
    }
  }

  // Marquer toutes les notifications d'un utilisateur comme lues
  async markAllAsRead(userId) {
    try {
      const result = await Notification.update(
        {
          is_read: true,
          read_at: new Date()
        },
        {
          where: {
            user_id: userId,
            is_read: false
          }
        }
      );
      console.log(`✅ ${result[0]} notifications marquées comme lues pour user ${userId}`);
      return result[0];
    } catch (error) {
      console.error('❌ Erreur marquage toutes notifications:', error);
      throw error;
    }
  }

  // Supprimer les anciennes notifications
  async cleanOldNotifications(daysOld = 30) {
    try {
      const date = new Date();
      date.setDate(date.getDate() - daysOld);

      const result = await Notification.destroy({
        where: {
          created_at: {
            [Op.lt]: date
          },
          is_read: true
        }
      });

      console.log(`🗑️ ${result} anciennes notifications supprimées`);
      return result;
    } catch (error) {
      console.error('❌ Erreur nettoyage notifications:', error);
      throw error;
    }
  }
}

// Export singleton
const notificationService = new NotificationService();
module.exports = notificationService;
