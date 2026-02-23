import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class TechnicianNotificationsScreen extends StatefulWidget {
  const TechnicianNotificationsScreen({super.key});

  @override
  State<TechnicianNotificationsScreen> createState() =>
      _TechnicianNotificationsScreenState();
}

class _TechnicianNotificationsScreenState
    extends State<TechnicianNotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getNotifications();

      if (response['success']) {
        setState(() {
          _notifications =
              List<Map<String, dynamic>>.from(response['data'] ?? []);
          _unreadCount =
              _notifications.where((n) => !(n['is_read'] ?? false)).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors du chargement des notifications');
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      // Mise à jour optimiste de l'interface
      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _unreadCount =
              _notifications.where((n) => !(n['is_read'] ?? false)).length;
        }
      });

      // Appel API
      await _apiService.markNotificationAsRead(notificationId);
    } catch (e) {
      // En cas d'erreur, recharger pour avoir l'état correct
      await _loadNotifications();
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la mise à jour');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Mise à jour optimiste de l'interface
      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
        _unreadCount = 0;
      });

      // Appel API
      await _apiService.markAllNotificationsAsRead();

      if (mounted) {
        SnackBarHelper.showSuccess(
            context, 'Toutes les notifications marquées comme lues',
            emoji: '✓');
      }
    } catch (e) {
      // En cas d'erreur, recharger pour avoir l'état correct
      await _loadNotifications();
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la mise à jour');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    print('📱 Clic sur notification: ${notification['type']}');

    // Extraire les données additionnelles du champ 'data'
    Map<String, dynamic>? additionalData;
    if (notification['data'] != null) {
      print('   Données brutes: ${notification['data']}');
      if (notification['data'] is String) {
        try {
          additionalData = jsonDecode(notification['data']);
        } catch (e) {
          print('   Erreur parsing JSON: $e');
        }
      } else if (notification['data'] is Map) {
        additionalData = Map<String, dynamic>.from(notification['data']);
      }
      print('   Données extraites: $additionalData');
    }

    // Construire les données de navigation
    final notificationData = {
      'type': notification['type'],
      'role': 'technician', // Forcer le rôle technicien
      // Essayer d'abord dans 'data', puis directement dans notification
      'interventionId': additionalData?['interventionId'] ??
          additionalData?['intervention_id'] ??
          notification['intervention_id'],
      'quoteId': additionalData?['quoteId'] ??
          additionalData?['quote_id'] ??
          notification['quote_id'],
      'orderId': additionalData?['orderId'] ??
          additionalData?['order_id'] ??
          notification['order_id'],
      'complaintId': additionalData?['complaintId'] ??
          additionalData?['complaint_id'] ??
          notification['complaint_id'],
      'subscriptionId': additionalData?['subscriptionId'] ??
          additionalData?['subscription_id'] ??
          notification['subscription_id'],
    };

    print('   Données finales pour navigation: $notificationData');

    // Fermer l'écran de notifications avant de naviguer
    Navigator.pop(context);

    // Attendre la fin de l'animation de fermeture
    await Future.delayed(const Duration(milliseconds: 300));

    // Utiliser le service de navigation
    if (mounted) {
      final navigationService = NotificationNavigationService();
      navigationService.navigateFromNotification(context, notificationData);
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      // Supprimer localement en attendant l'implémentation backend
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        _unreadCount =
            _notifications.where((n) => !(n['is_read'] ?? false)).length;
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Notification supprimée',
            emoji: '🗑️');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la suppression');
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'Vider les notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Vider tout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      // Appel API pour supprimer toutes les notifications côté serveur
      final response = await _apiService.deleteAllNotifications();
      if (response['success']) {
        // Recharger la liste depuis le backend
        await _loadNotifications();
        if (mounted) {
          SnackBarHelper.showSuccess(
              context, 'Toutes les notifications ont été supprimées',
              emoji: '🗑️');
        }
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Erreur lors de la suppression');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la suppression');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0a543d),
                Color(0xFF0d6b4d),
              ],
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: Text(
                'Tout lire',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Vider toutes les notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune notification',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas de nouvelles notifications',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] ?? false;
    final String type = notification['type'] ?? 'info';
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? '';
    final DateTime? createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : null;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : const Color(0xFF0a543d).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? Colors.grey[200]!
                  : const Color(0xFF0a543d).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getNotificationColors(type),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0a543d),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getNotificationColors(String type) {
    switch (type) {
      case 'intervention':
        return [const Color(0xFF0a543d), const Color(0xFF0f7d59)];
      case 'appointment':
        return [Colors.blue.shade600, Colors.blue.shade400];
      case 'payment':
        return [Colors.green.shade600, Colors.green.shade400];
      case 'warning':
        return [Colors.orange.shade600, Colors.orange.shade400];
      case 'urgent':
        return [Colors.red.shade600, Colors.red.shade400];
      default:
        return [Colors.grey.shade600, Colors.grey.shade400];
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'intervention':
        return Icons.build_circle;
      case 'appointment':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'warning':
        return Icons.warning_amber;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
