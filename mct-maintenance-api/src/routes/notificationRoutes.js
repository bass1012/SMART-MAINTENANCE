const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { body, query, param } = require('express-validator');
const notificationController = require('../controllers/notificationController');
const broadcastController = require('../controllers/broadcastController');

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: Récupérer toutes les notifications de l'utilisateur
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [info, warning, error, success]
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [unread, read, archived]
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Liste des notifications
 */
router.get('/', authenticate, notificationController.getMyNotifications);

/**
 * @swagger
 * /api/notifications/unread-count:
 *   get:
 *     summary: Récupérer le nombre de notifications non lues
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Nombre de notifications non lues
 */
router.get('/unread-count', authenticate, notificationController.getUnreadCount);

/**
 * @swagger
 * /api/notifications/{id}:
 *   get:
 *     summary: Récupérer une notification par ID
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Détails de la notification
 */
// Route supprimée - getNotificationById n'existe pas dans le nouveau contrôleur

/**
 * @swagger
 * /api/notifications/{id}/mark-read:
 *   post:
 *     summary: Marquer une notification comme lue
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification marquée comme lue
 */
router.patch('/:id/read', authenticate, notificationController.markAsRead);

/**
 * @swagger
 * /api/notifications/{id}/mark-unread:
 *   patch:
 *     summary: Marquer une notification comme non lue
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification marquée comme non lue
 */
router.patch('/:id/unread', authenticate, notificationController.markAsUnread);

/**
 * @swagger
 * /api/notifications/mark-all-read:
 *   post:
 *     summary: Marquer toutes les notifications comme lues
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Toutes les notifications marquées comme lues
 */
router.post('/mark-all-read', authenticate, notificationController.markAllAsRead);

/**
 * @swagger
 * /api/notifications/delete-all:
 *   delete:
 *     summary: Supprimer toutes les notifications de l'utilisateur
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Toutes les notifications supprimées
 */
router.delete('/delete-all', authenticate, notificationController.deleteAllNotifications);

/**
 * @swagger
 * /api/notifications/{id}:
 *   delete:
 *     summary: Supprimer une notification
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification supprimée
 */
router.delete('/:id', authenticate, notificationController.deleteNotification);

// ============================================
// 📢 ROUTES BROADCAST (Admin uniquement)
// ============================================

/**
 * POST /api/notifications/broadcast/send
 * Envoyer une notification à plusieurs utilisateurs
 */
router.post(
  '/broadcast/send',
  authenticate,
  authorize('admin'),
  broadcastController.sendBroadcastNotification
);

/**
 * GET /api/notifications/broadcast/stats
 * Obtenir les statistiques d'utilisateurs pour le broadcast
 */
router.get(
  '/broadcast/stats',
  authenticate,
  authorize('admin'),
  broadcastController.getBroadcastStats
);

/**
 * GET /api/notifications/broadcast/users
 * Obtenir la liste des utilisateurs pour sélection
 */
router.get(
  '/broadcast/users',
  authenticate,
  authorize('admin'),
  broadcastController.getUsers
);

module.exports = router;
