import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/models/dashboard_stats_model.dart';
import 'package:mct_maintenance_mobile/screens/customer/complaints_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/maintenance_offers_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/maintenance_reports_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/quotes_contracts_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/interventions_list_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/intervention_detail_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/equipments_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/shop_screen.dart';
import '../admin/suggest_technicians_screen.dart';
import '../../utils/snackbar_helper.dart';
import 'package:mct_maintenance_mobile/screens/customer/invoices_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/support_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/faq_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/cgu_cgv_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/history_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/warranty_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/profile_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/settings_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/notifications_screen.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/services/fcm_service.dart';
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';

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
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Écouter les clics de notification en temps réel
    _notificationSubscription = FCMService().onNotificationTap.listen((data) {
      print('🔔 [CustomerMainScreen] Notification tap reçue via stream');
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
        _checkUnratedInterventions();
        _checkPendingDiagnosticPayments();
        _checkPendingConfirmationReports();
      }
    });
  }

  /// Vérifier s'il y a des rapports en attente de confirmation
  Future<void> _checkPendingConfirmationReports() async {
    print(
        '📋 [CustomerMainScreen] Vérification rapports en attente de confirmation...');
    // Attendre pour ne pas surcharger au démarrage (après les autres checks)
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    try {
      final pendingReports = await _apiService.getPendingConfirmationReports();

      print('✅ ${pendingReports.length} rapport(s) en attente de confirmation');

      if (pendingReports.isNotEmpty && mounted) {
        _showPendingConfirmationDialog(pendingReports.first);
      }
    } catch (e) {
      print('❌ Erreur vérification rapports: $e');
    }
  }

  /// Afficher le dialogue de confirmation du rapport
  void _showPendingConfirmationDialog(Map<String, dynamic> intervention) {
    final title = intervention['title'] ?? 'Intervention';
    final technicianName = intervention['technician'] != null
        ? '${intervention['technician']['first_name']} ${intervention['technician']['last_name']}'
        : 'Technicien';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade700,
            size: 48,
          ),
        ),
        title: const Text(
          'Travaux terminés',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Le technicien '),
                    TextSpan(
                      text: technicianName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' a terminé l\'intervention '),
                    TextSpan(
                      text: '"$title"',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' et a soumis son rapport.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Veuillez confirmer que les travaux ont bien été réalisés et procéder au solde de l\'intervention.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Important : Le solde doit être réglé avant la dernière intervention de maintenance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Naviguer vers le détail de l'intervention
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterventionDetailScreen(
                    intervention: intervention,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Voir et solder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Vérifier s'il y a des paiements de diagnostic en attente
  Future<void> _checkPendingDiagnosticPayments() async {
    print(
        '💳 [CustomerMainScreen] Vérification paiements diagnostic en attente...');
    // Attendre un peu pour ne pas surcharger au démarrage
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    try {
      final pendingPayments = await _apiService.getPendingDiagnosticPayments();

      print('✅ ${pendingPayments.length} paiement(s) en attente');

      if (pendingPayments.isNotEmpty && mounted) {
        _showPendingPaymentNotification(pendingPayments);
      }
    } catch (e) {
      print('❌ Erreur vérification paiements: $e');
    }
  }

  /// Afficher une notification pour les paiements en attente
  void _showPendingPaymentNotification(
      List<Map<String, dynamic>> pendingPayments) {
    final count = pendingPayments.length;
    final firstPayment = pendingPayments.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 48,
          ),
        ),
        title: Text(
          count == 1 ? 'Paiement en attente' : '$count paiements en attente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count == 1
                  ? 'Vous avez une demande d\'intervention en attente de paiement du diagnostic.'
                  : 'Vous avez $count demandes d\'intervention en attente de paiement du diagnostic.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Intervention #${firstPayment['id']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Naviguer vers la liste des interventions
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InterventionsListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir les interventions'),
          ),
        ],
      ),
    );
  }

  /// Vérifier s'il y a des interventions non notées
  Future<void> _checkUnratedInterventions() async {
    print(
        '🔍 [CustomerMainScreen] Démarrage vérification interventions non notées...');
    // Attendre que l'écran soit complètement chargé
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) {
      print('⚠️ Widget non monté, annulation vérification');
      return;
    }

    try {
      // Récupérer les interventions ignorées (Plus tard)
      final prefs = await SharedPreferences.getInstance();
      final ignoredIds =
          prefs.getStringList('ignored_rating_interventions') ?? [];
      print('📋 Interventions ignorées: $ignoredIds');

      print('📞 Appel API getUnratedInterventions...');
      final unratedInterventions = await _apiService.getUnratedInterventions();

      print(
          '✅ Réponse reçue: ${unratedInterventions.length} intervention(s) non notée(s)');
      print('📋 Détails: $unratedInterventions');

      // Filtrer les interventions ignorées
      final filteredInterventions = unratedInterventions.where((intervention) {
        final id = intervention['id'].toString();
        return !ignoredIds.contains(id);
      }).toList();

      print(
          '📋 Après filtrage: ${filteredInterventions.length} intervention(s) à noter');

      if (filteredInterventions.isNotEmpty && mounted) {
        print(
            '🎯 Affichage popup pour intervention #${filteredInterventions.first['id']}');
        // Afficher le popup pour la première intervention non notée
        _showRatingDialog(filteredInterventions.first);
      } else {
        print('ℹ️ Aucune intervention à noter ou widget non monté');
      }
    } catch (e) {
      print(
          '❌ Erreur lors de la vérification des interventions non notées: $e');
      print('📊 Stack trace: ${StackTrace.current}');
    }
  }

  /// Vérifier s'il y a une notification en attente de traitement
  Future<void> _checkPendingNotifications() async {
    // Attendre que le widget soit monté
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final fcmService = FCMService();
    final notificationData = fcmService.getAndClearPendingNotification();

    if (notificationData != null) {
      print('📬 Notification en attente détectée, navigation...');
      final navigationService = NotificationNavigationService();
      navigationService.navigateFromNotification(context, notificationData);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Charger d'abord le profil
      final profileResponse = await _apiService.getProfile();

      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(profileResponse['data']);
          print('👤 User chargé: role=${_user?.role}');
        });
      }

      // Ensuite charger les stats (peut échouer pour les admins)
      try {
        final statsResponse = await _apiService.getDashboardStats();
        if (mounted) {
          setState(() {
            _stats = DashboardStats.fromJson(statsResponse['data']);
          });
        }
      } catch (statsError) {
        print('⚠️  Erreur stats (normal pour admin): $statsError');
      }

      // Recharger aussi les notifications
      await _loadUnreadNotifications();

      if (mounted) {
        setState(() {
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
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupportScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF0a543d),
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
        ),
      ),
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
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                      'assets/images/Maintenancier_SMART_Maintenance.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0a543d).withOpacity(0.30),
                      const Color(0xFF0d6b4d).withOpacity(0.30),
                      const Color(0xFF0f7d59).withOpacity(0.30),
                      Colors.white.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.3, 0.5, 0.8],
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête moderne avec effet glassmorphism
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
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
                                      color: Colors.white.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(14),
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
                                                  color: Colors.white
                                                      .withOpacity(0.9),
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

                        // Bannière défilante - Horaires service client
                        _buildScrollingBanner(),

                        const SizedBox(height: 24),

                        // Grille des fonctionnalités
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Services',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
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
                                icon: Icons.engineering_outlined,
                                title: 'Nos Offres',
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
                                icon: Icons.engineering,
                                title: 'Planifier une Intervention',
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
                              // Deuxième ligne de cartes
                              _buildFeatureCard(
                                context,
                                icon: Icons.report_problem_outlined,
                                title: 'Réclamation',
                                color: const Color(0xFF0d6b4d),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ComplaintsScreen(),
                                    ),
                                  );
                                },
                              ),
                              // Troisième ligne de cartes
                              _buildFeatureCard(
                                context,
                                icon: Icons.devices_other,
                                title: 'Mes équipements',
                                color: const Color(0xFF0a543d),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EquipmentsScreen(),
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
                                icon: Icons.verified_user,
                                title: 'Garantie',
                                color: const Color(0xFF0d6b4d),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WarrantyScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section des statistiques (déplacée ici)
                        if (_stats != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Mes Statistiques',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                                    subtitle:
                                        '${_stats!.pendingQuotes} en attente',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section des actions rapides
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Actions Rapides',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0a543d).withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                        builder: (context) =>
                                            const InvoicesScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                _buildQuickAction(
                                  icon: Icons.help_outline,
                                  title: 'FAQ',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FAQScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                _buildQuickAction(
                                  icon: Icons.description_outlined,
                                  title:
                                      'Conditions Générales d\'Utilisation et de Vente',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CGUCGVScreen(),
                                      ),
                                    );
                                  },
                                ),
                                // Bouton test suggestions pour admins uniquement
                                if (_user?.role == 'admin') ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  _buildQuickAction(
                                    icon: Icons.person_search,
                                    title: '🧪 Test Suggestions Techniciens',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SuggestTechniciansScreen(
                                            interventionId: 122,
                                            interventionTitle:
                                                'Intervention test - Non assignée',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildScrollingBanner() {
    // Vérifier l'heure actuelle
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Afficher la bannière en dehors des heures de service (8h-18h en semaine)
    // Donc afficher si: avant 8h OU après 17h30 OU weekend
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isBeforeOpening = currentHour < 8;
    final isAfterClosing =
        currentHour > 18 || (currentHour == 18 && currentMinute >= 30);

    // Afficher la bannière seulement en dehors des heures de service
    final shouldShowBanner = isWeekend || isBeforeOpening || isAfterClosing;

    if (!shouldShowBanner) {
      return const SizedBox
          .shrink(); // Ne rien afficher pendant les heures de service
    }

    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.amber.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _ScrollingText(
          text:
              '   📞 Service Client disponible de 8h à 18h du lundi au vendredi   •   Samedi de 09h à 12h   •   ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade800,
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
            Colors.white.withOpacity(0.95),
            color.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
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
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Colors.white,
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
              icon: Icons.assignment_outlined,
              title: 'Rapport maintenance',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MaintenanceReportsScreen()),
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

  /// Afficher le dialogue de notation pour une intervention
  void _showRatingDialog(Map<String, dynamic> intervention) {
    int rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFF0a543d).withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                Text(
                  'Notez l\'intervention',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0a543d),
                  ),
                ),
                const SizedBox(height: 8),

                // Sous-titre avec info intervention
                Text(
                  'Intervention #${intervention['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (intervention['title'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    intervention['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Étoiles de notation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color:
                              index < rating ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Champ commentaire
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Partagez votre expérience (optionnel)',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0a543d),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          // Sauvegarder l'intervention comme ignorée
                          final prefs = await SharedPreferences.getInstance();
                          final ignoredIds = prefs.getStringList(
                                  'ignored_rating_interventions') ??
                              [];
                          final interventionId = intervention['id'].toString();
                          if (!ignoredIds.contains(interventionId)) {
                            ignoredIds.add(interventionId);
                            await prefs.setStringList(
                                'ignored_rating_interventions', ignoredIds);
                            print(
                                '📌 Intervention #$interventionId ajoutée aux ignorées');
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Plus tard',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: rating == 0
                            ? null
                            : () async {
                                try {
                                  await _apiService.rateIntervention(
                                    intervention['id'],
                                    rating,
                                    reviewController.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    SnackBarHelper.showSuccess(
                                      context,
                                      'Merci pour votre évaluation !',
                                      emoji: '⭐',
                                    );
                                    // Vérifier s'il y a d'autres interventions non notées
                                    _checkUnratedInterventions();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    SnackBarHelper.showError(
                                      context,
                                      'Erreur: $e',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0a543d),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Envoyer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget pour le texte défilant animé
class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({
    required this.text,
    required this.style,
  });

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 840),
    )..addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = maxScroll * _animationController.value;
          _scrollController.jumpTo(currentScroll);
        }
      });

    // Démarrer l'animation en boucle
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 100,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }
}
