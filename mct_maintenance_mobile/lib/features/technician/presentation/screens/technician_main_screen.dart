import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:mct_maintenance_mobile/features/common/domain/repositories/notification_repository.dart';
import 'package:mct_maintenance_mobile/services/fcm_service.dart';
import 'package:mct_maintenance_mobile/services/chat_service.dart';
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/models/technician_stats_model.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/utils/avatar_helper.dart';
import 'package:mct_maintenance_mobile/utils/responsive_helper.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/interventions_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/calendar_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/reports_screen.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/reviews_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/technician_settings_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/availability_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/technician_notifications_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mct_maintenance_mobile/widgets/common/offline_indicator.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  UserModel? _user;
  TechnicianStats? _stats;
  String _availabilityStatus = 'offline';
  int _unreadNotifications = 0;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSocketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Écouter les clics de notification en temps réel
    _notificationSubscription = FCMService().onNotificationTap.listen((data) {
      if (kDebugMode)
        debugPrint(
            '🔔 [TechnicianMainScreen] Notification tap reçue via stream');
      if (mounted) {
        final navigationService = NotificationNavigationService();
        navigationService.navigateFromNotification(context, data);
      }
    });

    // Écouter les événements Socket.io de changement de statut de disponibilité
    _statusSocketSubscription =
        ChatService().onTechnicianStatusChanged.listen((data) {
      if (kDebugMode)
        debugPrint('⚡ [TechnicianMainScreen] Changement statut Socket: $data');
      if (mounted) {
        final targetId = data['user_id']?.toString();
        final myId = _user?.id.toString();
        if (targetId != null && myId != null && targetId == myId) {
          final newStatus = data['availability_status']?.toString();
          if (newStatus != null) {
            setState(() {
              _availabilityStatus = newStatus;
            });
          }
        } else {
          _loadDashboardData();
        }
      }
    });

    // Retarder le chargement pour éviter les conflits de layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
        _loadNotificationsCount();
        _checkPendingNotifications();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (kDebugMode)
        debugPrint('🔄 [TechnicianMainScreen] App reprise -> Rechargement');
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSocketSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Vérifier s'il y a une notification en attente de traitement
  Future<void> _checkPendingNotifications() async {
    // Attendre que le widget soit monté
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final fcmService = FCMService();
    final notificationData = fcmService.getAndClearPendingNotification();

    if (notificationData != null) {
      if (kDebugMode)
        debugPrint(
            '📬 [Technician] Notification en attente détectée, navigation...');
      final navigationService = NotificationNavigationService();
      navigationService.navigateFromNotification(context, notificationData);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final authRepository = context.read<AuthRepository>();
      final interventionRepository = context.read<InterventionRepository>();

      // Récupérer le profil et les stats en parallèle
      final results = await Future.wait<dynamic>([
        authRepository.getProfile(),
        interventionRepository.getTechnicianStats(),
      ]);

      final profileData = results[0];
      final statsData = results[1];

      if (mounted) {
        String status = 'offline';
        if (profileData['data'] != null) {
          final p = profileData['data'];
          if (p['profile'] != null && p['profile']['availability_status'] != null) {
            status = p['profile']['availability_status'].toString();
          } else if (p['technicianProfile'] != null && p['technicianProfile']['availability_status'] != null) {
            status = p['technicianProfile']['availability_status'].toString();
          } else if (p['availability_status'] != null) {
            status = p['availability_status'].toString();
          }
        }

        setState(() {
          _user = UserModel.fromJson(profileData['data']);
          _availabilityStatus = status;

          // Utiliser les stats du backend ou données fictives si non disponibles
          final data = statsData['data'] ?? {};
          _stats = TechnicianStats(
            totalInterventions: data['total_interventions'] ?? 0,
            pendingInterventions: data['pending_interventions'] ?? 0,
            completedInterventions: data['completed_interventions'] ?? 0,
            inProgressInterventions: data['in_progress_interventions'] ?? 0,
            totalRevenue: (data['total_revenue'] ?? 0).toDouble(),
            monthlyRevenue: (data['monthly_revenue'] ?? 0).toDouble(),
            averageRating: (data['average_rating'] ?? 0).toDouble(),
            totalReviews: data['total_reviews'] ?? 0,
            upcomingAppointments: data['upcoming_appointments'] ?? 0,
          );
          _isLoading = false;
        });

        // 🔌 Connecter le socket ChatService avec l'ID utilisateur
        if (_user != null) {
          if (kDebugMode) debugPrint('🔌 [TechnicianMainScreen] Connexion Socket.IO pour user ${_user!.id}');
          ChatService().connect();
        }
      }

      // Recharger le compteur de notifications
      await _loadNotificationsCount();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        try {
          SnackBarHelper.showError(context, 'Erreur de connexion. Veuillez réessayer.');
        } catch (_) {}
      }
    }
  }

  Future<void> _loadNotificationsCount() async {
    try {
      final notificationRepository = context.read<NotificationRepository>();
      final response = await notificationRepository.getNotifications();
      if (response['success'] && mounted) {
        final notifications =
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        final unreadCount =
            notifications.where((n) => !(n['is_read'] ?? false)).length;
        if (kDebugMode)
          debugPrint('🔔 Notifications non lues: $unreadCount'); // Debug
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Erreur chargement notifications: $e'); // Debug
      // Ignorer les erreurs silencieusement
    }
  }

  void _showAvatarMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // En-tête avec avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        const Color(0xFF0a543d).withValues(alpha: 0.1),
                    foregroundImage: AvatarHelper.hasAvatar(_user?.profileImage)
                        ? AvatarHelper.buildImageProvider(_user!.profileImage)
                        : null,
                    onForegroundImageError: AvatarHelper.hasAvatar(_user?.profileImage)
                        ? (_, __) {}
                        : null,
                    child: Text(
                      (_user?.firstName?.isNotEmpty == true
                              ? _user!.firstName![0]
                              : 'T')
                          .toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0a543d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                  .trim()
                                  .isNotEmpty
                              ? '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                  .trim()
                              : 'Technicien',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _user?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey[200]),
            // Menu items
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Mon Profil',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/technician/profile');
              },
            ),
            _buildMenuItem(
              icon: Icons.schedule_outlined,
              title: 'Disponibilités',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianAvailabilityScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianSettingsScreen(),
                  ),
                );
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              color: Colors.red,
              onTap: () async {
                // IMPORTANT : Lire le AuthRepository AVANT de pop le contexte
                final authRepository = context.read<AuthRepository>();
                // Capturer le Navigator avant toute opération async
                final navigator = Navigator.of(context);

                // Fermer le bottom sheet
                navigator.pop();

                final shouldLogout = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.zero,
                    content: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0a543d),
                            Color(0xFF0d6b4d),
                            Color(0xFF0f7d59)
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Déconnexion',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Êtes-vous sûr de vouloir vous déconnecter ?',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.5),
                                      ),
                                    ),
                                    child: Text(
                                      'Annuler',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5252),
                                          Color(0xFFE53935)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.red.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Déconnexion',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (shouldLogout == true) {
                  try {
                    await FCMService().clearOnLogout();
                    await authRepository.logout();
                  } catch (e) {
                    // Ignorer les erreurs de déconnexion
                  }

                  // Utiliser le navigator capturé
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF0a543d)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color ?? const Color(0xFF0a543d),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
            ),
          ),
        ),
        title: Text(
          'Tableau de Bord Tech',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Cloche de notification avec badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const TechnicianNotificationsScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                  // Recharger le nombre de notifications après retour
                  if (mounted) {
                    await _loadNotificationsCount();
                  }
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotifications > 99
                          ? '99+'
                          : _unreadNotifications.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Avatar avec menu
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: _showAvatarMenu,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    foregroundImage: AvatarHelper.hasAvatar(_user?.profileImage)
                        ? AvatarHelper.buildImageProvider(_user!.profileImage)
                        : null,
                    onForegroundImageError: AvatarHelper.hasAvatar(_user?.profileImage)
                        ? (_, __) {}
                        : null,
                    child: Text(
                      (_user?.firstName?.isNotEmpty == true
                              ? _user!.firstName![0]
                              : 'T')
                          .toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0a543d),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _availabilityStatus == 'available'
                            ? const Color(0xFF4CAF50)
                            : _availabilityStatus == 'busy'
                                ? const Color(0xFFFF9800)
                                : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Stack(
              children: [
                // Image de fond
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Image.asset(
                      'assets/images/background_tech_2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Contenu principal
                Column(
                  children: [
                    // Indicateur de mode offline
                    const OfflineIndicator(),
                    // Contenu principal
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadDashboardData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête de bienvenue
                              _buildWelcomeCard(),
                              const SizedBox(height: 24),

                              // Statistiques
                              if (_stats != null) ...[
                                Text(
                                  'Mes Statistiques',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildStatsGrid(),
                                const SizedBox(height: 24),
                              ],

                              // Services
                              Text(
                                'Mes Services',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildServicesGrid(),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Map<String, dynamic> _getStatusColors() {
    switch (_availabilityStatus) {
      case 'available':
        return {
          'color': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
          'lightTint': const Color(0xFFF1F8E9),
          'label': 'En ligne (Disponible)',
          'shortLabel': 'Disponible',
        };
      case 'busy':
        return {
          'color': const Color(0xFFE65100),
          'bgColor': const Color(0xFFFFF3E0),
          'lightTint': const Color(0xFFFFF8E1),
          'label': 'Occupé (En intervention)',
          'shortLabel': 'Occupé',
        };
      case 'offline':
      default:
        return {
          'color': const Color(0xFF616161),
          'bgColor': const Color(0xFFF5F5F5),
          'lightTint': const Color(0xFFFAFAFA),
          'label': 'Hors ligne',
          'shortLabel': 'Hors ligne',
        };
    }
  }

  Widget _buildAvailabilityBadge() {
    final statusInfo = _getStatusColors();
    final Color color = statusInfo['color'];
    final Color bgColor = statusInfo['bgColor'];
    final String label = statusInfo['label'];

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TechnicianAvailabilityScreen(),
          ),
        );
        _loadDashboardData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.swap_horiz_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final statusInfo = _getStatusColors();
    final Color statusColor = statusInfo['color'];
    final Color lightTint = statusInfo['lightTint'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightTint,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.65),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Décoration d'arrière-plan pastel
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // Icône avec dégradé et bordure aux couleurs de l'état
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Salutation et Badge de statut
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour ${_user?.firstName ?? 'Technicien'} !',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0a543d),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAvailabilityBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.build_circle_outlined,
                title: 'Interventions',
                value: '${_stats!.totalInterventions}',
                subtitle: '${_stats!.pendingInterventions} en attente',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                title: 'Complétées',
                value: '${_stats!.completedInterventions}',
                subtitle: 'Ce mois',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_outline,
                title: 'Évaluation',
                value: _stats!.averageRating.toStringAsFixed(1),
                subtitle: '${_stats!.totalReviews} avis',
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: ResponsiveHelper.buildServiceGridDelegate(context),
      itemCount: 4,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildServiceCard(
              icon: Icons.assignment_outlined,
              title: 'Mes Interventions',
              color: const Color(0xFF0a543d),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianInterventionsScreen(),
                  ),
                );
              },
            );
          case 1:
            return _buildServiceCard(
              icon: Icons.calendar_today_outlined,
              title: 'Mon Calendrier',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianCalendarScreen(),
                  ),
                );
              },
            );
          case 2:
            return _buildServiceCard(
              icon: Icons.description_outlined,
              title: 'Rapports',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianReportsScreen(),
                  ),
                );
              },
            );
          case 3:
            return _buildServiceCard(
              icon: Icons.star_outline,
              title: 'Évaluations',
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechnicianReviewsScreen(),
                  ),
                );
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
