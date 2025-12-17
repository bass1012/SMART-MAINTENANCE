const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const CustomerProfile = require('../models/CustomerProfile');
const fcmService = require('./fcmService');

class ChatService {
  constructor(io) {
    this.io = io;
    this.connectedUsers = new Map(); // userId -> socketId
    this.setupSocketHandlers();
  }

  setupSocketHandlers() {
    // Garder une référence à io pour l'utiliser dans les callbacks
    const io = this.io;
    
    this.io.on('connection', (socket) => {
      // Authentification utilisateur
      socket.on('chat:authenticate', async (data) => {
        try {
          const userId = typeof data === 'object' ? data.userId : data;
          const token = typeof data === 'object' ? data.token : null;
          
          if (!userId) {
            console.error('❌ [Chat] Auth échouée - userId manquant');
            socket.emit('chat:error', { error: 'userId requis' });
            return;
          }

          // Récupérer les informations utilisateur depuis la DB
          const user = await User.findByPk(userId, {
            include: [{
              model: CustomerProfile,
              as: 'customerProfile',
              attributes: ['first_name', 'last_name']
            }]
          });

          // Déterminer le nom à afficher
          let userName = 'Utilisateur';
          let userRole = 'customer'; // Par défaut
          
          if (user) {
            userRole = user.role || 'customer';
            
            if (user.customerProfile && user.customerProfile.first_name) {
              userName = `${user.customerProfile.first_name} ${user.customerProfile.last_name || ''}`.trim();
            } else if (user.first_name) {
              userName = `${user.first_name} ${user.last_name || ''}`.trim();
            } else if (user.email) {
              userName = user.email.split('@')[0];
            }
          }

          this.connectedUsers.set(userId, socket.id);
          socket.userId = userId;
          socket.userName = userName;
          socket.userRole = userRole;
          
          // Joindre une room personnelle
          socket.join(`user:${userId}`);
          
          // Si c'est un admin, joindre aussi la room des admins
          if (userRole === 'admin') {
            socket.join('role:admin');
          }
          
          // Confirmer l'authentification
          socket.emit('chat:authenticated', { 
            success: true,
            message: 'Authentification réussie',
            userId: userId,
            userName: userName,
            userRole: userRole
          });
          
          // Notifier que l'utilisateur est en ligne
          socket.broadcast.emit('chat:user_online', { userId, userName, userRole });
        } catch (error) {
          console.error('❌ [Chat] Erreur lors de l\'authentification:', error);
          socket.emit('chat:error', { error: 'Erreur d\'authentification' });
        }
      });

      // Envoi d'un message
      socket.on('chat:send_message', async (data) => {
        try {
          const { message, sender_role, attachment_url, attachment_type, recipient_id } = data;
          
          // Utiliser le userId stocké dans le socket lors de l'authentification
          const sender_id = socket.userId;

          if (!sender_id) {
            console.error('❌ [Chat] sender_id manquant - non authentifié');
            socket.emit('chat:error', { error: 'Utilisateur non authentifié' });
            return;
          }

          if (!message || message.trim() === '') {
            socket.emit('chat:error', { error: 'Message vide' });
            return;
          }

          // Sauvegarder le message dans la base de données
          const newMessage = await ChatMessage.create({
            sender_id,
            sender_role: sender_role || 'customer',
            recipient_id: recipient_id || null, // ID du destinataire (pour les messages admin → client)
            message: message.trim(),
            attachment_url,
            attachment_type,
            is_read: false
          });

          // Charger le message avec les relations
          const messageWithSender = await ChatMessage.findByPk(newMessage.id, {
            include: [
              {
                model: User,
                as: 'sender',
                attributes: ['id', 'first_name', 'last_name', 'email', 'role'],
                include: [
                  {
                    model: CustomerProfile,
                    as: 'customerProfile',
                    attributes: ['id', 'first_name', 'last_name']
                  }
                ]
              }
            ]
          });

          // LOGIQUE DE ROUTAGE DES MESSAGES
          // Si c'est un client qui écrit → envoyer seulement aux admins
          // Si c'est un admin qui écrit → envoyer seulement au client concerné (recipient_id)
          
          if (sender_role === 'admin') {
            // L'admin envoie un message → envoyer au client spécifique
            if (recipient_id) {
              io.to(`user:${recipient_id}`).emit('chat:new_message', messageWithSender);
              
              // 📱 NOTIFICATION PUSH au client
              await this.sendNotificationToUser(recipient_id, {
                title: 'Nouveau message',
                body: message.trim().substring(0, 100), // Limite à 100 caractères
              }, {
                type: 'chat',
                sender_id: String(sender_id),
                sender_role: 'admin',
                message_id: String(newMessage.id)
              });
            } else {
              // Pas de recipient_id → comportement par défaut (broadcast à tous les clients non-admin)
              socket.broadcast.emit('chat:new_message', messageWithSender);
            }
          } else {
            // Un client envoie un message → envoyer à TOUS les admins
            io.to('role:admin').emit('chat:new_message', messageWithSender);
            
            // 📱 NOTIFICATION PUSH aux admins
            await this.sendNotificationToAdmins(sender_id, {
              title: `Nouveau message de ${socket.userName || 'un client'}`,
              body: message.trim().substring(0, 100),
            }, {
              type: 'chat',
              sender_id: String(sender_id),
              sender_role: sender_role || 'customer',
              message_id: String(newMessage.id)
            });
          }

          // Confirmer l'envoi à l'expéditeur avec le message complet
          // L'expéditeur utilisera ce message pour l'afficher localement
          socket.emit('chat:message_sent', { success: true, message: messageWithSender });

        } catch (error) {
          console.error('💬 [Chat] Erreur envoi message:', error);
          socket.emit('chat:error', { error: 'Erreur lors de l\'envoi du message' });
        }
      });

      // Notification de "en train de taper..."
      socket.on('chat:typing', (data) => {
        // Utiliser les données du socket (stockées lors de l'authentification)
        const userId = socket.userId;
        const userName = socket.userName || 'Utilisateur';
        const userRole = socket.userRole;
        const recipientId = data?.recipient_id;
        
        // Envoyer uniquement au destinataire
        if (userRole === 'customer' || userRole === 'technician') {
          // Client → Tous les admins
          io.to('role:admin').emit('chat:user_typing', { userId, userName, userRole });
        } else if (userRole === 'admin' && recipientId) {
          // Admin → Client spécifique
          io.to(`user:${recipientId}`).emit('chat:user_typing', { userId, userName, userRole });
        }
      });

      // Notification d'"arrêt de taper"
      socket.on('chat:stop_typing', (data) => {
        const userId = socket.userId;
        const userRole = socket.userRole;
        const recipientId = data?.recipient_id;
        
        // Envoyer uniquement au destinataire
        if (userRole === 'customer' || userRole === 'technician') {
          // Client → Tous les admins
          io.to('role:admin').emit('chat:user_stop_typing', { userId, userRole });
        } else if (userRole === 'admin' && recipientId) {
          // Admin → Client spécifique
          io.to(`user:${recipientId}`).emit('chat:user_stop_typing', { userId, userRole });
        }
      });

      // Marquer les messages comme lus
      // Marquer les messages comme lus
      socket.on('chat:mark_read', async (data) => {
        try {
          const messageIds = data?.messageIds || data; // Support des deux formats
          
          console.log('📖 [Chat] Requête mark_read reçue:', { data, messageIds });
          
          if (!messageIds || (Array.isArray(messageIds) && messageIds.length === 0)) {
            console.log('⚠️ [Chat] Aucun message à marquer');
            return;
          }

          const result = await ChatMessage.update(
            { is_read: true },
            {
              where: {
                id: Array.isArray(messageIds) ? messageIds : [messageIds],
                is_read: false
              }
            }
          );

          console.log(`✅ [Chat] ${result[0]} message(s) mis à jour en DB (sur ${Array.isArray(messageIds) ? messageIds.length : 1} demandés)`);

          // Notifier les autres utilisateurs
          this.io.emit('chat:messages_read', { messageIds });
          console.log('📢 [Chat] Événement chat:messages_read émis');
        } catch (error) {
          console.error('❌ [Chat] Erreur marquage lus:', error);
        }
      });

      // Déconnexion
      socket.on('disconnect', () => {
        if (socket.userId) {
          this.connectedUsers.delete(socket.userId);
          socket.broadcast.emit('chat:user_offline', { userId: socket.userId });
        }
      });
    });
  }

  // Envoyer un message à un utilisateur spécifique
  sendToUser(userId, event, data) {
    const socketId = this.connectedUsers.get(userId);
    if (socketId) {
      this.io.to(socketId).emit(event, data);
      return true;
    }
    return false;
  }

  // Diffuser un message à tous les utilisateurs
  broadcast(event, data) {
    this.io.emit(event, data);
  }

  /**
   * Envoyer une notification push à un utilisateur spécifique
   * @param {number} userId - ID de l'utilisateur
   * @param {object} notification - {title, body}
   * @param {object} data - Données supplémentaires
   */
  async sendNotificationToUser(userId, notification, data = {}) {
    try {
      const user = await User.findByPk(userId, {
        attributes: ['id', 'fcm_token']
      });

      if (user && user.fcm_token) {
        await fcmService.sendToDevice(user.fcm_token, notification, data);
        console.log(`📱 [Chat] Notification envoyée à l'utilisateur ${userId}`);
      } else {
        console.log(`⚠️  [Chat] Pas de FCM token pour l'utilisateur ${userId}`);
      }
    } catch (error) {
      console.error(`❌ [Chat] Erreur envoi notification à l'utilisateur ${userId}:`, error.message);
    }
  }

  /**
   * Envoyer une notification push à tous les admins
   * @param {number} senderId - ID de l'expéditeur (pour l'exclure si admin)
   * @param {object} notification - {title, body}
   * @param {object} data - Données supplémentaires
   */
  async sendNotificationToAdmins(senderId, notification, data = {}) {
    try {
      const admins = await User.findAll({
        where: {
          role: 'admin'
        },
        attributes: ['id', 'fcm_token']
      });

      const tokens = admins
        .filter(admin => admin.id !== senderId && admin.fcm_token) // Exclure l'expéditeur
        .map(admin => admin.fcm_token);

      if (tokens.length > 0) {
        await fcmService.sendToMultipleDevices(tokens, notification, data);
        console.log(`📱 [Chat] Notification envoyée à ${tokens.length} admin(s)`);
      } else {
        console.log('⚠️  [Chat] Aucun admin avec FCM token trouvé');
      }
    } catch (error) {
      console.error('❌ [Chat] Erreur envoi notification aux admins:', error.message);
    }
  }
}

module.exports = ChatService;
