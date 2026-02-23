import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/models/technician_stats_model.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/utils/avatar_helper.dart';
import 'package:mct_maintenance_mobile/screens/technician/interventions_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/calendar_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/reports_screen.dart';
import '../../utils/snackbar_helper.dart';
import 'package:mct_maintenance_mobile/screens/technician/reviews_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/technician_settings_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/availability_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/technician_notifications_screen.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/widgets/common/offline_indicator.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  UserModel? _user;
  TechnicianStats? _stats;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    // Retarder le chargement pour éviter les conflits de layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
        _loadNotificationsCount();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      // Récupérer le profil et les stats en parallèle
      final results = await Future.wait([
        _apiService.getProfile(),
        _apiService.getTechnicianStats(),
      ]);

      final profileData = results[0];
      final statsData = results[1];

      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(profileData['data']);

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
      }

      // Recharger le compteur de notifications
      await _loadNotificationsCount();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur lors du chargement: $e');
      }
    }
  }

  Future<void> _loadNotificationsCount() async {
    try {
      final response = await _apiService.getNotifications();
      if (response['success'] && mounted) {
        final notifications =
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        final unreadCount =
            notifications.where((n) => !(n['is_read'] ?? false)).length;
        print('🔔 Notifications non lues: $unreadCount'); // Debug
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement notifications: $e'); // Debug
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
                    backgroundColor: const Color(0xFF0a543d).withOpacity(0.1),
                    backgroundImage: AvatarHelper.hasAvatar(_user?.profileImage)
                        ? NetworkImage(
                            AvatarHelper.buildAvatarUrl(_user!.profileImage))
                        : null,
                    child: _user?.profileImage == null ||
                            _user!.profileImage!.isEmpty
                        ? Text(
                            (_user?.firstName?.isNotEmpty == true
                                    ? _user!.firstName![0]
                                    : 'T')
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0a543d),
                            ),
                          )
                        : null,
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
                              color: Colors.white.withOpacity(0.2),
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
                                color: Colors.white.withOpacity(0.9),
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
                                          color: Colors.red.withOpacity(0.3),
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
                    await _apiService.logout();
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
          color: (color ?? const Color(0xFF0a543d)).withOpacity(0.1),
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
                    MaterialPageRoute(
                      builder: (context) =>
                          const TechnicianNotificationsScreen(),
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
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: _showAvatarMenu,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: AvatarHelper.hasAvatar(_user?.profileImage)
                    ? NetworkImage(
                        AvatarHelper.buildAvatarUrl(_user!.profileImage))
                    : null,
                child:
                    _user?.profileImage == null || _user!.profileImage!.isEmpty
                        ? Text(
                            (_user?.firstName?.isNotEmpty == true
                                    ? _user!.firstName![0]
                                    : 'T')
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0a543d),
                            ),
                          )
                        : null,
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

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0a543d),
                    Color(0xFF0d6b4d),
                    Color(0xFF0f7d59)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.engineering,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_user?.firstName ?? 'Technicien'} !',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0a543d),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prêt pour une nouvelle journée de travail !',
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
            color: Colors.black.withOpacity(0.05),
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
                      color.withOpacity(0.8),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildServiceCard(
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
        ),
        _buildServiceCard(
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
        ),
        _buildServiceCard(
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
        ),
        _buildServiceCard(
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
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
                        color.withOpacity(0.8),
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
