const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const CustomerProfile = require('../models/CustomerProfile');
const { authenticate } = require('../middleware/auth');

// Récupérer l'historique des messages pour un utilisateur
router.get('/history', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    // Si c'est un admin, récupérer tous les messages
    // Si c'est un client, récupérer UNIQUEMENT :
    //   - Ses propres messages (sender_id = userId)
    //   - Les messages des admins destinés à LUI (sender_role = 'admin' AND recipient_id = userId)
    const whereClause = req.user.role === 'admin' || req.user.role === 'technician'
      ? {} // Admin voit tous les messages
      : {
          [Op.or]: [
            { sender_id: userId },                              // Messages envoyés par le client
            { sender_role: 'admin', recipient_id: userId }      // Messages des admins POUR ce client
          ]
        };

    const messages = await ChatMessage.findAll({
      where: whereClause,
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
      ],
      order: [['created_at', 'ASC']], // Ordre chronologique : anciens messages en haut, nouveaux en bas
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      success: true,
      data: messages,
      total: messages.length
    });
  } catch (error) {
    console.error('Erreur récupération historique chat:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de l\'historique'
    });
  }
});

// Envoyer un message (via API REST - backup si Socket.IO ne fonctionne pas)
router.post('/send', authenticate, async (req, res) => {
  try {
    const { message, attachment_url, attachment_type } = req.body;

    if (!message || message.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'Le message ne peut pas être vide'
      });
    }

    const newMessage = await ChatMessage.create({
      sender_id: req.user.id,
      sender_role: req.user.role,
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

    // Émettre le message via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.emit('new_chat_message', messageWithSender);
    }

    res.status(201).json({
      success: true,
      data: messageWithSender
    });
  } catch (error) {
    console.error('Erreur envoi message:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'envoi du message'
    });
  }
});

// Marquer les messages comme lus
router.put('/mark-read', authenticate, async (req, res) => {
  try {
    const { message_ids } = req.body;

    if (!message_ids || !Array.isArray(message_ids)) {
      return res.status(400).json({
        success: false,
        error: 'IDs de messages invalides'
      });
    }

    await ChatMessage.update(
      { is_read: true },
      {
        where: {
          id: message_ids,
          is_read: false
        }
      }
    );

    res.json({
      success: true,
      message: 'Messages marqués comme lus'
    });
  } catch (error) {
    console.error('Erreur marquage messages lus:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du marquage des messages'
    });
  }
});

// Récupérer la liste des conversations (pour les admins)
router.get('/conversations', authenticate, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        error: 'Accès réservé aux administrateurs'
      });
    }

    const { Sequelize } = require('sequelize');
    
    // Récupérer tous les clients qui ont envoyé au moins un message
    const conversations = await ChatMessage.findAll({
      attributes: [
        'sender_id',
        [Sequelize.fn('MAX', Sequelize.col('ChatMessage.created_at')), 'last_message_date'],
        [Sequelize.fn('COUNT', Sequelize.literal("CASE WHEN is_read = false AND sender_role = 'customer' THEN 1 END")), 'unread_count']
      ],
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
      ],
      where: {
        sender_role: 'customer'
      },
      group: ['sender_id', 'sender.id', 'sender->customerProfile.id'],
      order: [[Sequelize.literal('last_message_date'), 'DESC']]
    });

    console.log('📊 [Chat] Conversations récupérées:', conversations.map(c => ({
      sender_id: c.sender_id,
      unread_count: c.get('unread_count')
    })));

    res.json({
      success: true,
      data: conversations
    });
  } catch (error) {
    console.error('Erreur récupération conversations:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des conversations'
    });
  }
});

// Récupérer l'historique d'une conversation avec un client spécifique
router.get('/conversation/:userId', authenticate, async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 100, offset = 0 } = req.query;

    // Vérifier les permissions
    if (req.user.role !== 'admin' && req.user.role !== 'technician' && req.user.id !== parseInt(userId)) {
      return res.status(403).json({
        success: false,
        error: 'Accès non autorisé'
      });
    }

    // Récupérer la conversation entre l'admin et ce client spécifique
    // - Messages envoyés PAR le client (sender_id = userId)
    // - Messages envoyés par les admins À ce client (sender_role = 'admin' AND recipient_id = userId)
    const messages = await ChatMessage.findAll({
      where: {
        [Op.or]: [
          { sender_id: parseInt(userId) },                         // Messages du client
          { sender_role: 'admin', recipient_id: parseInt(userId) } // Messages des admins POUR ce client
        ]
      },
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
      ],
      order: [['created_at', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // Si c'est un admin/tech qui charge, marquer les messages du client comme lus automatiquement
    if (req.user.role === 'admin' || req.user.role === 'technician') {
      const unreadClientMessages = messages
        .filter(msg => !msg.is_read && msg.sender_role === 'customer')
        .map(msg => msg.id);

      if (unreadClientMessages.length > 0) {
        await ChatMessage.update(
          { is_read: true },
          { where: { id: unreadClientMessages } }
        );

        console.log(`✅ [Chat] ${unreadClientMessages.length} message(s) du client ${userId} automatiquement marqués comme lus`);

        // Notifier via Socket.IO
        const io = require('../services/socketService').getIO();
        if (io) {
          io.emit('chat:messages_read', { messageIds: unreadClientMessages });
        }
        
        // Mettre à jour les messages dans la réponse
        messages.forEach(msg => {
          if (unreadClientMessages.includes(msg.id)) {
            msg.is_read = true;
          }
        });
      }
    }

    res.json({
      success: true,
      data: messages
    });
  } catch (error) {
    console.error('Erreur récupération conversation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de la conversation'
    });
  }
});

// Compter les messages non lus
router.get('/unread-count', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Admin voit tous les messages non lus des clients
    // Client voit ses messages non lus
    const whereClause = req.user.role === 'admin' || req.user.role === 'technician'
      ? { is_read: false, sender_role: 'customer' }
      : { is_read: false, sender_id: { [require('sequelize').Op.ne]: userId } };

    const count = await ChatMessage.count({
      where: whereClause
    });

    res.json({
      success: true,
      count
    });
  } catch (error) {
    console.error('Erreur comptage messages non lus:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du comptage'
    });
  }
});

// Supprimer l'historique de chat pour l'utilisateur connecté
router.delete('/history', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;

    // Supprimer tous les messages de l'utilisateur
    // - Messages envoyés par l'utilisateur (sender_id = userId)
    // - Messages reçus par l'utilisateur (recipient_id = userId)
    const deletedCount = await ChatMessage.destroy({
      where: {
        [Op.or]: [
          { sender_id: userId },
          { recipient_id: userId }
        ]
      }
    });

    console.log(`🗑️ [Chat] ${deletedCount} message(s) supprimé(s) pour l'utilisateur ${userId}`);

    res.json({
      success: true,
      message: 'Historique de chat supprimé avec succès',
      deletedCount
    });
  } catch (error) {
    console.error('Erreur suppression historique chat:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression de l\'historique'
    });
  }
});

// Supprimer une conversation spécifique (admin uniquement)
router.delete('/conversation/:userId', authenticate, async (req, res) => {
  try {
    // Vérifier que l'utilisateur est admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Accès refusé. Seuls les admins peuvent supprimer des conversations.'
      });
    }

    const targetUserId = parseInt(req.params.userId);

    // Supprimer tous les messages liés à cet utilisateur
    const deletedCount = await ChatMessage.destroy({
      where: {
        [Op.or]: [
          { sender_id: targetUserId },
          { recipient_id: targetUserId }
        ]
      }
    });

    console.log(`🗑️ [Chat] Admin ${req.user.id} a supprimé ${deletedCount} message(s) de l'utilisateur ${targetUserId}`);

    res.json({
      success: true,
      message: 'Conversation supprimée avec succès',
      deletedCount
    });
  } catch (error) {
    console.error('Erreur suppression conversation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression de la conversation'
    });
  }
});

module.exports = router;
