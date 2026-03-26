import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/screens/customer/complaints_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/interventions_list_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/invoices_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/profile_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/settings_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/notifications_screen.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/services/fcm_service.dart';
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/utils/responsive_helper.dart';
import '../../utils/snackbar_helper.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({super.key});

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  UserModel? _user;
  int _unreadNotifications = 0;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Écouter les clics de notification en temps réel
    _notificationSubscription = FCMService().onNotificationTap.listen((data) {
      print('🔔 [ManagerMainScreen] Notification tap reçue via stream');
      if (mounted) {
        final navigationService = NotificationNavigationService();
        navigationService.navigateFromNotification(context, data);
      }
    });
    // Retarder le chargement pour éviter les conflits de layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
        _loadUnreadNotifications();
        _checkPendingNotifications();
      }
    });
  }

  @override
  void dispose() {
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
      print('📬 [Manager] Notification en attente détectée, navigation...');
      final navigationService = NotificationNavigationService();
      navigationService.navigateFromNotification(context, notificationData);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final profileResponse = await _apiService.getProfile();

      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(profileResponse['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur lors du chargement: $e');
      }
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response = await _apiService.getUnreadNotificationsCount();
      if (response['success'] && mounted) {
        setState(() {
          _unreadNotifications = response['data']?['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Erreur chargement notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
            ),
          ),
        ),
        title: Text(
          'Manager',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: _buildNotificationButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildProfileButton(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête moderne avec gradient bleu
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1565C0),
                            Color(0xFF1976D2),
                            Color(0xFF1E88E5),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // Carte de bienvenue
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.manage_accounts,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bonjour, ${_user?.firstName ?? 'Manager'} 👋',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Espace Manager',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section fonctionnalités
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Gestion',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grille de fonctionnalités
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveHelper.getHorizontalPadding(context)
                                .clamp(16, 32),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            ResponsiveHelper.buildServiceGridDelegate(context),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return _buildFeatureCard(
                                context,
                                icon: Icons.engineering,
                                title: 'Interventions',
                                color: const Color(0xFF1565C0),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const InterventionsListScreen(),
                                    ),
                                  );
                                },
                              );
                            case 1:
                              return _buildFeatureCard(
                                context,
                                icon: Icons.report_problem_outlined,
                                title: 'Réclamations',
                                color: const Color(0xFFE53935),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ComplaintsScreen(),
                                    ),
                                  );
                                },
                              );
                            case 2:
                              return _buildFeatureCard(
                                context,
                                icon: Icons.receipt_long_outlined,
                                title: 'Factures',
                                color: const Color(0xFF43A047),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const InvoicesScreen(),
                                    ),
                                  );
                                },
                              );
                            case 3:
                              return _buildFeatureCard(
                                context,
                                icon: Icons.bar_chart,
                                title: 'Statistiques',
                                color: const Color(0xFF7B1FA2),
                                onTap: () {
                                  SnackBarHelper.showInfo(
                                    context,
                                    'Statistiques - Bientôt disponible',
                                  );
                                },
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section Actions rapides
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Actions rapides',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildQuickAction(
                              icon: Icons.person_outline,
                              title: 'Mon profil',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                            ),
                            _buildQuickAction(
                              icon: Icons.settings_outlined,
                              title: 'Paramètres',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                            ),
                            _buildQuickAction(
                              icon: Icons.logout,
                              title: 'Déconnexion',
                              color: Colors.red,
                              onTap: () async {
                                await _apiService.logout();
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF1565C0)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color ?? const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      },
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (_unreadNotifications > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _unreadNotifications > 99
                      ? '99+'
                      : _unreadNotifications.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withOpacity(0.2),
        backgroundImage: _user?.profileImage != null
            ? NetworkImage(_user!.profileImage!)
            : null,
        child: _user?.profileImage == null
            ? Text(
                (_user?.firstName?.isNotEmpty == true
                        ? _user!.firstName![0]
                        : 'M')
                    .toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }
}
