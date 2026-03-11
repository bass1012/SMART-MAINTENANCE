import 'dart:convert';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      if (!mounted) return;
      setState(() => _isLoading = true);
      final response = await _apiService.getNotifications();

      if (!mounted) return;

      if (response['success']) {
        setState(() {
          _notifications =
              List<Map<String, dynamic>>.from(response['data'] ?? []);
          _unreadCount =
              _notifications.where((n) => !(n['is_read'] ?? false)).length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackBarHelper.showError(
          context, 'Erreur lors du chargement des notifications');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      if (!mounted) return;
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
      if (mounted) {
        await _loadNotifications();
        SnackBarHelper.showError(context, 'Erreur lors de la mise à jour');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      if (!mounted) return;
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
      if (mounted) {
        await _loadNotifications();
        SnackBarHelper.showError(context, 'Erreur lors de la mise à jour');
      }
    }
  }

  /// Gérer le clic sur une notification
  void _handleNotificationTap(Map<String, dynamic> notification) {
    print('📱 Clic sur notification: ${notification['type']}');

    // Extraire les données additionnelles du champ 'data' (JSON ou Map)
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

    // Créer l'objet de données pour la navigation
    final Map<String, dynamic> notificationData = {
      'type': notification['type'],
      'role': notification['role'] ??
          'customer', // Par défaut customer pour cet écran
      // Essayer d'abord dans 'data', puis directement dans notification (pour compatibilité)
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
      'contractId': additionalData?['contractId'] ??
          additionalData?['contract_id'] ??
          notification['contract_id'],
      'paymentLink': additionalData?['paymentLink'] ??
          additionalData?['payment_link'] ??
          notification['payment_link'],
    };

    print('   Données finales pour navigation: $notificationData');

    // Obtenir le NavigatorState AVANT de fermer l'écran
    final navigator = Navigator.of(context);

    // Utiliser le service de navigation avec pushReplacement pour éviter le context invalide
    final navigationService = NotificationNavigationService();
    navigationService.navigateFromNotificationWithReplace(
        navigator, notificationData);
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.delete_sweep, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Vider tout',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    try {
      await _apiService.deleteAllNotifications();
      await _loadNotifications();
      if (mounted) {
        SnackBarHelper.showSuccess(
            context, 'Toutes les notifications supprimées',
            emoji: '🗑️');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la suppression des notifications');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0a543d),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tout marquer lu',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'delete_all') {
                  _showDeleteAllConfirmation();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Vider tout',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_tech_2.png'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: const Color(0xFF0a543d),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de notifications',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'info';
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color(0xFF0a543d)
                .withOpacity(0.45), // Vert AppBar moins transparent
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? Colors.grey.shade200
              : const Color(0xFF0a543d).withOpacity(
                  0.70), // Vert AppBar plus marqué et moins transparent
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Marquer comme lu si non lu
          if (!isRead) {
            _markAsRead(notification['id']);
          }

          // Naviguer vers le contenu de la notification
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getNotificationColors(type),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getNotificationColors(type)[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isRead ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0a543d),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isRead ? Colors.black54 : Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isRead ? Colors.grey.shade500 : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isRead ? Colors.grey.shade500 : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'intervention':
        return Icons.build_circle_outlined;
      case 'quote':
        return Icons.description_outlined;
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'complaint':
        return Icons.report_problem_outlined;
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_paid':
      case 'diagnostic_payment_confirmed':
        return Icons.check_circle_outline;
      case 'payment_pending':
      case 'second_payment_required':
        return Icons.schedule_outlined;
      case 'payment_failed':
      case 'diagnostic_payment_failed':
        return Icons.error_outline;
      case 'payment_refunded':
        return Icons.money_off_outlined;
      case 'success':
      case 'intervention_confirmed':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
      case 'intervention_rejected':
      case 'intervention_dispute':
        return Icons.error_outline;
      case 'report_submitted':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  List<Color> _getNotificationColors(String type) {
    switch (type) {
      case 'intervention':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      case 'quote':
        return [const Color(0xFF0a543d), const Color(0xFF0d6b4d)];
      case 'invoice':
        return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
      case 'complaint':
        return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_paid':
      case 'diagnostic_payment_confirmed':
      case 'intervention_confirmed':
        return [const Color(0xFF4CAF50), const Color(0xFF388E3C)]; // Vert
      case 'payment_pending':
      case 'report_submitted':
      case 'second_payment_required':
        return [const Color(0xFFFF9800), const Color(0xFFF57C00)]; // Orange
      case 'payment_failed':
      case 'diagnostic_payment_failed':
      case 'intervention_rejected':
      case 'intervention_dispute':
        return [const Color(0xFFF44336), const Color(0xFFD32F2F)]; // Rouge
      case 'payment_refunded':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)]; // Bleu
      case 'success':
        return [const Color(0xFF4CAF50), const Color(0xFF388E3C)];
      case 'warning':
        return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
      case 'error':
        return [const Color(0xFFF44336), const Color(0xFFD32F2F)];
      default:
        return [const Color(0xFF0a543d), const Color(0xFF0d6b4d)];
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
