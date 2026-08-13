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

      // Sécurité : Auto-rejoindre les rooms depuis l'utilisateur authentifié par le middleware socketAuth
      const authenticatedUser = socket.data?.user;
      const authenticatedUserId = socket.data?.userId || (authenticatedUser ? authenticatedUser.id : null);
      const authenticatedUserRole = socket.data?.userRole || (authenticatedUser ? authenticatedUser.role : null);

      if (authenticatedUserId) {
        this.connectedUsers.set(authenticatedUserId, socket.id);
        socket.userId = authenticatedUserId;
        socket.join(`user:${authenticatedUserId}`);
        if (authenticatedUserRole) {
          socket.join(`role:${authenticatedUserRole}`);
        }
        console.log(`✅ Utilisateur #${authenticatedUserId} (${authenticatedUserRole}) authentifié et connecté sur socket ${socket.id}`);
      }

      // Événement d'authentification rétro-compatible
      socket.on('authenticate', async (userId) => {
        // Ignorer l'usurpation si l'utilisateur est déjà authentifié par JWT
        const effectiveUserId = authenticatedUserId || userId;
        if (effectiveUserId) {
          this.connectedUsers.set(effectiveUserId, socket.id);
          socket.userId = effectiveUserId;
          socket.join(`user:${effectiveUserId}`);
          
          if (!authenticatedUserRole) {
            const u = await User.findByPk(effectiveUserId);
            if (u) {
              socket.join(`role:${u.role}`);
            }
          }
        }
      });

      // Marquer une notification comme lue (vérification de propriété)
      socket.on('mark_read', async (notificationId) => {
        try {
          const userId = socket.userId || socket.data?.userId;
          if (!userId) return;

          const notification = await Notification.findByPk(notificationId);
          if (!notification) return;

          // Seul le destinataire ou un administrateur/manager peut marquer comme lue
          const isOwner = Number(notification.user_id) === Number(userId);
          const isAdminOrManager = ['admin', 'manager'].includes(socket.data?.userRole || socket.data?.user?.role);

          if (isOwner || isAdminOrManager) {
            await this.markAsRead(notificationId);
            socket.emit('notification_read', { notificationId });
          } else {
            console.warn(`⚠️ Tentative non autorisée de mark_read sur notification #${notificationId} par user #${userId}`);
          }
        } catch (error) {
          console.error('❌ Erreur mark_read:', error);
        }
      });

      // Marquer toutes les notifications comme lues (pour l'utilisateur connecté uniquement)
      socket.on('mark_all_read', async (requestedUserId) => {
        try {
          const effectiveUserId = socket.userId || socket.data?.userId || requestedUserId;
          if (!effectiveUserId) return;

          await this.markAllAsRead(effectiveUserId);
          socket.emit('all_notifications_read');
        } catch (error) {
          console.error('❌ Erreur mark_all_read:', error);
        }
      });

      // Déconnexion
      socket.on('disconnect', () => {
        const userId = socket.userId || socket.data?.userId;
        if (userId) {
          this.connectedUsers.delete(userId);
          console.log(`🔌 Utilisateur ${userId} déconnecté`);
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
    actionUrl = null,
    idempotencyKey = null
  }) {
    try {
      if (
        idempotencyKey !== null
        && (typeof idempotencyKey !== 'string' || !idempotencyKey.trim())
      ) {
        throw new TypeError('La clé d’idempotence de notification doit être une chaîne non vide');
      }
      if (idempotencyKey && idempotencyKey.length > 191) {
        throw new TypeError('La clé d’idempotence de notification dépasse 191 caractères');
      }

      // Créer la notification en base de données
      const values = {
        user_id: userId,
        type,
        title,
        message,
        data,
        priority,
        action_url: actionUrl,
        dedupe_key: idempotencyKey,
        is_read: false
      };
      let notification;
      let created = true;
      if (idempotencyKey) {
        [notification, created] = await Notification.findOrCreate({
          where: { user_id: userId, dedupe_key: idempotencyKey },
          defaults: values
        });
      } else {
        notification = await Notification.create(values);
      }

      if (!created) {
        console.log(`↩️ Notification déjà traitée [ID: ${notification.id}] pour user ${userId}`);
        return notification;
      }

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
          created_at: notification.created_at || notification.createdAt || new Date().toISOString(),
          createdAt: notification.createdAt || notification.created_at || new Date().toISOString(),
          updated_at: notification.updated_at || notification.updatedAt || new Date().toISOString(),
          is_read: notification.is_read ?? false,
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

      // TOUJOURS envoyer notification push via FCM (même si Socket.IO est connecté)
      // Car l'app mobile peut ne pas écouter Socket.IO pour les notifications
      if (true) {
        try {
          const user = await User.findByPk(userId, { attributes: ['fcm_token', 'role'] });
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
                target_user_id: userId.toString(),
                target_role: user.role || '',
                ...data
              }
            );
            console.log(`✅ [Notif ${notification.id}] FCM envoyé avec succès pour user ${userId}`);
          } else {
            console.log(`⚠️  [Notif ${notification.id}] Pas de FCM token pour user ${userId}`);
          }
        } catch (fcmError) {
          console.error(`⚠️  [Notif ${notification.id}] Erreur envoi FCM (ignorée):`, fcmError.message); // nosemgrep: unsafe-formatstring
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

  // Créer une notification pour tous les admins et managers
  async notifyAdmins(notificationData) {
    try {
      console.log('👥 Recherche des admins et managers actifs...');
      const admins = await User.findAll({
        where: { 
          role: { [Op.in]: ['admin', 'manager'] }, 
          status: 'active' 
        }
      });
      
      console.log(`👥 ${admins.length} admin(s)/manager(s) trouvé(s):`, admins.map(a => ({ id: a.id, email: a.email, role: a.role }))); // nosemgrep: unsafe-formatstring
      
      if (admins.length === 0) {
        console.warn('⚠️  Aucun admin/manager actif trouvé, notifications non envoyées');
        return [];
      }
      
      const adminIds = admins.map(admin => admin.id);
      console.log('📬 Envoi de notifications à', adminIds.length, 'admin(s)/manager(s)');
      const result = await this.createBulk(adminIds, notificationData);
      console.log('✅ Notifications créées pour les admins et managers');
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
