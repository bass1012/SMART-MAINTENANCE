import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/models/dashboard_stats_model.dart';
import 'package:mct_maintenance_mobile/screens/customer/complaints_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/maintenance_offers_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/maintenance_reports_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/quotes_contracts_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/interventions_list_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/shop_screen.dart';
import '../../utils/snackbar_helper.dart';
import 'package:mct_maintenance_mobile/screens/customer/invoices_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/support_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/history_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/profile_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/settings_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/notifications_screen.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import '../../utils/test_keys.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  UserModel? _user;
  DashboardStats? _stats;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUnreadNotifications();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Charger le profil et les statistiques en parallèle
      final results = await Future.wait([
        _apiService.getProfile(),
        _apiService.getDashboardStats(),
      ]);

      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(results[0]['data']);
          _stats = DashboardStats.fromJson(results[1]['data']);
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
      // Silently fail pour ne pas bloquer l'interface
      print('Erreur chargement notifications: $e');
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
        title: Text(
          'Tableau de Bord',
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête moderne avec gradient
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0a543d),
                          Color(0xFF0d6b4d),
                          Color(0xFF0f7d59),
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
                            // Carte de bienvenue glassmorphism
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.waving_hand,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bonjour,',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          _user?.firstName ?? 'Client',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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

                  // Section des statistiques
                  if (_stats != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Mes Statistiques',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0a543d),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.build_circle_outlined,
                              title: 'Interventions',
                              value: '${_stats!.totalInterventions}',
                              subtitle:
                                  '${_stats!.pendingInterventions} en cours',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.description_outlined,
                              title: 'Devis',
                              value: '${_stats!.totalQuotes}',
                              subtitle: '${_stats!.pendingQuotes} en attente',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              title: 'Commandes',
                              value: '${_stats!.totalOrders}',
                              subtitle: 'Total',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.attach_money,
                              title: 'Dépenses',
                              value: '${_stats!.totalSpent.toStringAsFixed(0)}',
                              subtitle: 'FCFA',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Grille des fonctionnalités
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Services',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0a543d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      children: [
                        // Première ligne de cartes
                        _buildFeatureCard(
                          context,
                          icon: Icons.engineering,
                          title: 'Interventions',
                          color: const Color(0xFF0a543d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InterventionsListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          icon: Icons.description_outlined,
                          title: 'Devis et Contrat',
                          color: const Color(0xFF0d6b4d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const QuotesContractsScreen(),
                              ),
                            );
                          },
                        ),
                        // Deuxième ligne de cartes
                        _buildFeatureCard(
                          context,
                          icon: Icons.assignment_outlined,
                          title: 'Rapport maintenance',
                          color: const Color(0xFF0a543d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MaintenanceReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          icon: Icons.report_problem_outlined,
                          title: 'Réclamation',
                          color: const Color(0xFF0d6b4d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ComplaintsScreen(),
                              ),
                            );
                          },
                        ),
                        // Troisième ligne de cartes
                        _buildFeatureCard(
                          context,
                          icon: Icons.engineering_outlined,
                          title: 'Offre entretien',
                          color: const Color(0xFF0a543d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MaintenanceOffersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          icon: Icons.shopping_cart_outlined,
                          title: 'Boutique',
                          color: const Color(0xFF0d6b4d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ShopScreen(),
                              ),
                            );
                          },
                        ),
                        // Quatrième ligne de cartes
                        _buildFeatureCard(
                          context,
                          icon: Icons.history,
                          title: 'Historique',
                          color: const Color(0xFF0a543d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(
                                  initialTabIndex:
                                      0, // Ouvrir sur le premier onglet (Interventions)
                                ),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          icon: Icons.receipt_long_outlined,
                          title: 'Factures',
                          color: const Color(0xFF0d6b4d),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InvoicesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section des actions rapides
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Actions Rapides',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0a543d),
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
                            color: const Color(0xFF0a543d).withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildQuickAction(
                            icon: Icons.receipt_long_outlined,
                            title: 'Voir mes factures',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InvoicesScreen(),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          _buildQuickAction(
                            icon: Icons.chat_bubble_outline,
                            title: 'Contacter le support',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SupportScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.3,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0a543d).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0a543d).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Row(
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
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bouton de notifications moderne dans l'AppBar
  Widget _buildNotificationButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                // Recharger le compteur après retour
                _loadUnreadNotifications();
              },
            ),
          ),
          if (_unreadNotifications > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: _unreadNotifications > 99 ? 9 : 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Bouton de profil moderne dans l'AppBar
  Widget _buildProfileButton() {
    final hasAvatar =
        _user?.profileImage != null && _user!.profileImage!.isNotEmpty;
    final avatarUrl = hasAvatar
        ? (_user!.profileImage!.startsWith('http')
            ? _user!.profileImage!
            : '${_apiService.baseUrl}/uploads/avatars/${_user!.profileImage}')
        : null;

    return GestureDetector(
      onTap: _showModernMenu,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasAvatar
              ? null
              : const LinearGradient(
                  colors: [Colors.white24, Colors.white12],
                ),
          border: Border.all(color: Colors.white30, width: 2),
          image: hasAvatar && avatarUrl != null
              ? DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasAvatar
            ? null
            : Center(
                child: Text(
                  _user != null &&
                          _user!.firstName != null &&
                          _user!.firstName!.isNotEmpty
                      ? _user!.firstName![0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  // Menu moderne en bottom sheet
  void _showModernMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 24),
            // En-tête avec profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _user?.profileImage != null &&
                              _user!.profileImage!.isNotEmpty
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0a543d).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: _user?.profileImage != null &&
                              _user!.profileImage!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                _user!.profileImage!.startsWith('http')
                                    ? _user!.profileImage!
                                    : '${_apiService.baseUrl}/uploads/avatars/${_user!.profileImage}',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _user?.profileImage != null &&
                            _user!.profileImage!.isNotEmpty
                        ? null
                        : Center(
                            child: Text(
                              _user != null &&
                                      _user!.firstName != null &&
                                      _user!.firstName!.isNotEmpty
                                  ? '${_user!.firstName![0]}${_user!.lastName != null && _user!.lastName!.isNotEmpty ? _user!.lastName![0] : ''}'
                                      .toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user != null
                              ? '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'
                                  .trim()
                              : 'Utilisateur',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0a543d),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            // Menu items
            _buildModernMenuItem(
              icon: Icons.person_outline,
              title: 'Mon Profil',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            _buildModernMenuItem(
              icon: Icons.history_outlined,
              title: 'Historique',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );
              },
            ),
            _buildModernMenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Factures',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InvoicesScreen()),
                );
              },
            ),
            _buildModernMenuItem(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SupportScreen()),
                );
              },
            ),
            _buildModernMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(height: 1),
            _buildModernMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              color: Colors.red,
              onTap: () async {
                // Capturer le BuildContext avant toute opération async
                final navigator = Navigator.of(context);

                // Fermer le bottom sheet
                navigator.pop();

                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Déconnexion',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text('Annuler', style: GoogleFonts.poppins()),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            Text('Déconnexion', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  try {
                    await _apiService.logout();
                  } catch (e) {
                    // Ignorer les erreurs de déconnexion
                  }

                  // Utiliser le navigator capturé au lieu du context
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF0a543d)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color ?? const Color(0xFF0a543d),
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
    );
  }
}

// Utilisation du modèle UserModel depuis le fichier user_model.dart
