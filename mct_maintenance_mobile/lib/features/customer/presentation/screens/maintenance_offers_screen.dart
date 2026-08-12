import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/models/maintenance_offer_model.dart';
import 'package:mct_maintenance_mobile/models/installation_service.dart';
import 'package:mct_maintenance_mobile/models/repair_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/service_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';
import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/widgets/common/support_fab_wrapper.dart';
import 'subscription_payment_screen.dart';
import 'contract_payment_screen.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';
import 'new_intervention_screen.dart';

class MaintenanceOffersScreen extends StatefulWidget {
  final int initialTabIndex;

  const MaintenanceOffersScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<MaintenanceOffersScreen> createState() =>
      _MaintenanceOffersScreenState();
}

class _MaintenanceOffersScreenState extends State<MaintenanceOffersScreen>
    with TickerProviderStateMixin {
  late final ServiceRepository _serviceRepository;
  late final SubscriptionRepository _subscriptionRepository;
  late final AuthRepository _authRepository;
  late TabController _tabController;
  late TabController _interventionNestedTabController;
  bool _isLoadingOffers = true;
  bool _isLoadingSubscriptions = true;
  bool _isLoadingInstallation = true;
  bool _isLoadingRepair = true;
  List<MaintenanceOffer> _offers = [];
  List<Map<String, dynamic>> _subscriptions = [];
  List<InstallationService> _installationServices = [];
  List<RepairService> _repairServices = [];
  String? _errorOffers;
  String? _errorSubscriptions;
  String? _errorInstallation;
  String? _errorRepair;

  // Variables d'état pour la Solution 3 : UI Mobile Dynamique (Toggle & Accordéon)
  String _selectedModeFilter = 'demand'; // 'demand', 'subscription'
  String _selectedCategoryFilter =
      'mural'; // 'mural', 'cassette', 'allege_armoire', 'gainable'
  final Set<int> _expandedOfferIds = {};
  bool _isCommonCoreExpanded = false;

  @override
  void initState() {
    super.initState();
    _serviceRepository = context.read<ServiceRepository>();
    _subscriptionRepository = context.read<SubscriptionRepository>();
    _authRepository = context.read<AuthRepository>();
    _loadAllData();
    _tabController = TabController(
      length: 3, // 3 onglets: Intervention, Installation, Réparation
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _interventionNestedTabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Rebuild pour mettre à jour les badges
    });
    // Charger toutes les données au démarrage
    _loadOffers();
    _loadSubscriptions();
    _loadInstallationServices();
    _loadRepairServices();
  }

  void _loadAllData() {
    _loadOffers();
    _loadSubscriptions();
    _loadInstallationServices();
    _loadRepairServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _interventionNestedTabController.dispose();
    super.dispose();
  }

  // Getters pour filtrer les souscriptions par type
  List<Map<String, dynamic>> get _interventionSubscriptions {
    return _subscriptions
        .where((sub) => sub['maintenance_offer_id'] != null)
        .toList();
  }

  List<Map<String, dynamic>> get _installationSubscriptions {
    return _subscriptions
        .where((sub) => sub['installation_service_id'] != null)
        .toList();
  }

  List<Map<String, dynamic>> get _repairSubscriptions {
    return _subscriptions
        .where((sub) => sub['repair_service_id'] != null)
        .toList();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _serviceRepository.getMaintenanceOffers();
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorOffers = e.toString();
          _isLoadingOffers = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptions() async {
    if (kDebugMode) debugPrint('🔄 Début du chargement des souscriptions...');
    setState(() {
      _isLoadingSubscriptions = true;
      _errorSubscriptions = null;
    });

    try {
      if (kDebugMode) debugPrint('📞 Appel API getSubscriptions()...');
      final subscriptions = await _subscriptionRepository.getSubscriptions();
      if (kDebugMode)
        debugPrint('✅ Souscriptions reçues: ${subscriptions.length}');
      if (kDebugMode) debugPrint('📦 Données: $subscriptions');

      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoadingSubscriptions = false;
        });
        if (kDebugMode) debugPrint('✅ État mis à jour avec succès');
      }
    } catch (e, stackTrace) {
      if (kDebugMode)
        debugPrint('❌ Erreur lors du chargement des souscriptions: $e');
      if (kDebugMode) debugPrint('📍 Stack trace: $stackTrace');

      if (mounted) {
        // Détecter les erreurs d'authentification
        if (e.toString().contains('AUTH_ERROR') ||
            e.toString().contains('Invalid token') ||
            e.toString().contains('Token invalide')) {
          setState(() {
            _errorSubscriptions = 'Session expirée. Veuillez vous reconnecter.';
            _isLoadingSubscriptions = false;
          });

          // Afficher un message et proposer de se reconnecter
          SnackBarHelper.showWarning(
            context,
            'Votre session a expiré',
            duration: const Duration(seconds: 10),
          );

          // Redirection vers login
          if (mounted) {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } else {
          setState(() {
            _errorSubscriptions = e.toString();
            _isLoadingSubscriptions = false;
          });
        }
      }
    }
  }

  Future<void> _loadInstallationServices() async {
    setState(() {
      _isLoadingInstallation = true;
      _errorInstallation = null;
    });

    try {
      final services = await _serviceRepository.getActiveInstallationServices();
      if (mounted) {
        setState(() {
          _installationServices = services;
          _isLoadingInstallation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorInstallation = e.toString();
          _isLoadingInstallation = false;
        });
      }
    }
  }

  Future<void> _loadRepairServices() async {
    setState(() {
      _isLoadingRepair = true;
      _errorRepair = null;
    });

    try {
      final services = await _serviceRepository.getActiveRepairServices();
      if (mounted) {
        setState(() {
          _repairServices = services;
          _isLoadingRepair = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorRepair = e.toString();
          _isLoadingRepair = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compter les souscriptions d'intervention en attente de paiement uniquement
    final pendingCount = _interventionSubscriptions
        .where((s) =>
            s['payment_status'] == 'pending' &&
            (s['status'] == 'active' || s['status'] == 'pending_payment'))
        .length;

    // Compter les souscriptions d'installation en attente de paiement
    final pendingInstallationCount = _installationSubscriptions
        .where(
            (s) => s['payment_status'] == 'pending' && s['status'] == 'active')
        .length;

    // Compter les souscriptions de réparation en attente de paiement
    final pendingRepairCount = _repairSubscriptions
        .where(
            (s) => s['payment_status'] == 'pending' && s['status'] == 'active')
        .length;

    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nos Services'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadOffers();
                _loadSubscriptions();
                _loadInstallationServices();
                _loadRepairServices();
              },
              tooltip: 'Actualiser',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: Column(
              children: [
                // Message de swipe subtil au-dessus des onglets
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swipe_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Glissez pour naviguer entre les sections',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      padding: EdgeInsets.zero,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0a543d).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF0a543d),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.engineering_outlined, size: 16),
                              SizedBox(width: 4),
                              Text('Maintenance'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.build_outlined, size: 16),
                              SizedBox(width: 4),
                              Text('Installation'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.handyman_outlined, size: 16),
                              SizedBox(width: 4),
                              Text('Dépannage'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInterventionTab(), // Offres + Souscriptions maintenance
              _buildInstallationTab(), // Offres + Souscriptions installation
              _buildRepairTab(), // Offres + Souscriptions réparation
            ],
          ),
        ),
      ),
    );
  }

  // ========== ONGLET INTERVENTION (Offres + Souscriptions) ==========
  Widget _buildInterventionTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _interventionNestedTabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF0a543d),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0a543d),
                    Color(0xFF0d6b4d),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0a543d).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              tabs: [
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nos Offres',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Mes Souscriptions',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _interventionNestedTabController,
            children: [
              _buildOffersTab(),
              _buildSubscriptionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  List<MaintenanceOffer> get _filteredOffers {
    return _offers.where((offer) {
      if (_selectedModeFilter == 'demand') {
        if (offer.isAnnual) return false;
      } else if (_selectedModeFilter == 'subscription') {
        if (!offer.isAnnual) return false;
      }

      if (_selectedCategoryFilter != 'all') {
        final category = offer.equipmentCategory;
        if (_selectedCategoryFilter == 'allege_armoire') {
          if (category != 'allege' &&
              category != 'armoire' &&
              category != 'allege_armoire') {
            return false;
          }
        } else if (category != 'all' && category != _selectedCategoryFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildOffersTab() {
    if (_isLoadingOffers) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorOffers != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorOffers'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOffers,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return _buildEmptyOffersState();
    }

    final filteredList = _filteredOffers;

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Sélecteur Dynamique de Mode (Toggle Switch: À la demande / Abonnement)
          _buildModeToggleSwitch(),
          const SizedBox(height: 12),

          // 2. Barre de Puces par Typologie d'Équipement
          _buildCategoryFilterChips(),
          const SizedBox(height: 14),

          // 3. Liste des Offres sous forme d'Accordéons Pliables
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune offre ne correspond aux filtres sélectionnés',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedModeFilter = 'demand';
                        _selectedCategoryFilter = 'mural';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Réinitialiser les filtres'),
                  ),
                ],
              ),
            )
          else
            ...filteredList.map((offer) => _buildAccordionOfferCard(offer)),

          const SizedBox(height: 20),

          // 4. Bandeau Socle Commun Inclus en Fin de Page
          _buildCommonCoreBanner(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorSubscriptions != null) {
      // Vérifier si c'est une erreur d'authentification ou de timeout
      final isAuthError = _errorSubscriptions!.contains('Session expirée') ||
          _errorSubscriptions!.contains('AUTH_ERROR') ||
          _errorSubscriptions!.contains('Invalid token');
      final isTimeoutError = _errorSubscriptions!.contains('TimeoutException') ||
          _errorSubscriptions!.contains('SocketException') ||
          _errorSubscriptions!.contains('Future not completed') ||
          _errorSubscriptions!.contains('ClientException');

      final displayErrorMessage = isAuthError
          ? 'Votre session a expiré'
          : isTimeoutError
              ? 'Délai d\'attente dépassé. Veuillez vérifier votre connexion internet.'
              : 'Erreur: $_errorSubscriptions';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuthError
                  ? Icons.lock_clock
                  : (isTimeoutError ? Icons.wifi_off_rounded : Icons.error_outline),
              size: 64,
              color: isAuthError ? Colors.orange : (isTimeoutError ? Colors.amber.shade700 : Colors.red),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                displayErrorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isAuthError
                  ? () async {
                      await _authRepository.logout();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  : _loadSubscriptions,
              icon: Icon(isAuthError ? Icons.login : Icons.refresh),
              label: Text(isAuthError ? 'SE RECONNECTER' : 'Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuthError ? Colors.orange : null,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Filtrer les souscriptions d'intervention uniquement
    final interventionSubs = _interventionSubscriptions;

    if (interventionSubs.isEmpty) {
      return _buildEmptySubscriptionsState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: interventionSubs.length,
        itemBuilder: (context, index) {
          final subscription = interventionSubs[index];
          return _buildSubscriptionCard(subscription);
        },
      ),
    );
  }

  Widget _buildEmptyOffersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune offre d\'entretien disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Aucune offre d\'entretien n\'est actuellement disponible. Veuillez réessayer ultérieurement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonCoreBanner() {
    return Card(
      elevation: 1,
      color: const Color(0xFFF0F7F4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFB2DFDB), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isCommonCoreExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isCommonCoreExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0a543d).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Color(0xFF0a543d),
              size: 22,
            ),
          ),
          title: const Text(
            'Socle inclus dans toutes nos offres — Prestation SMART Maintenance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0a543d),
            ),
          ),
          subtitle: const Text(
            'Ce qui est TOUJOURS inclus dans chacune de nos interventions',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          children: [
            const Divider(height: 14, color: Color(0xFFB2DFDB)),
            _buildCoreGuaranteeItem(
              icon: Icons.clean_hands_outlined,
              title: 'Nettoyage sous pression à la vapeur (Anti-bactérien)',
              subtitle:
                  'Élimination complète des bactéries, germes et poussières en profondeur.',
            ),
            _buildCoreGuaranteeItem(
              icon: Icons.build_circle_outlined,
              title: 'Démontage & Lavage complet des composants',
              subtitle:
                  'Panneaux de protection, filtres à air, condenseur, évaporateur et bac à eau.',
            ),
            _buildCoreGuaranteeItem(
              icon: Icons.checklist_rtl_rounded,
              title: 'Vérifications techniques & fonctionnelles',
              subtitle:
                  'Contrôle des parties tournantes (pompes, ventilateurs) et de la tuyauterie.',
            ),
            _buildCoreGuaranteeItem(
              icon: Icons.directions_car_outlined,
              title: 'Déplacement techniciens qualifiés sur Abidjan',
              subtitle:
                  'Inclus dans le tarif de base sur toute la zone métropolitaine d’Abidjan.',
            ),
            _buildCoreGuaranteeItem(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Rapport d\'intervention détaillé',
              subtitle:
                  'Délivré systématiquement après chaque passage avec nos conseils d’utilisation.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreGuaranteeItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0a543d)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToggleOption(
            key: 'demand',
            label: 'À la demande',
            icon: Icons.flash_on_rounded,
          ),
          _buildToggleOption(
            key: 'subscription',
            label: 'Abonnement annuel',
            icon: Icons.event_repeat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedModeFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedModeFilter = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0a543d) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0a543d).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    final categories = [
      {'key': 'mural', 'label': '🟢 Muraux'},
      {'key': 'cassette', 'label': '🔵 Cassettes'},
      {'key': 'allege_armoire', 'label': '🟠 Allèges / Armoires'},
      {'key': 'gainable', 'label': '🔴 Gainables'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategoryFilter == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF0a543d),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0a543d),
              backgroundColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF0a543d) : Colors.grey.shade300,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryFilter = cat['key']!;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccordionOfferCard(MaintenanceOffer offer) {
    final isExpanded = _expandedOfferIds.contains(offer.id);
    final isSubscription = offer.isAnnual;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: offer.isActive
              ? const Color(0xFF0a543d).withValues(alpha: 0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de carte avec Tag / Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSubscription
                  ? Colors.amber.shade700.withValues(alpha: 0.12)
                  : const Color(0xFF0a543d).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSubscription
                          ? Icons.event_repeat_rounded
                          : Icons.flash_on_rounded,
                      size: 16,
                      color: isSubscription
                          ? Colors.amber.shade900
                          : const Color(0xFF0a543d),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSubscription
                          ? 'ABONNEMENT PROGRAMMÉ'
                          : 'INTERVENTION À LA DEMANDE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSubscription
                            ? Colors.amber.shade900
                            : const Color(0xFF0a543d),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (offer.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Disponible',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et Description
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (offer.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Tarif & Note
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${offer.price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                    if (offer.priceNote != null &&
                        offer.priceNote!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offer.priceNote!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (offer.originalPrice != null &&
                    offer.originalPrice! > offer.price) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Prix avant remise : ${offer.originalPrice!.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                if (offer.isAnnual ||
                    offer.includesFreon ||
                    offer.refrigerant != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (offer.discountPercent != null &&
                          offer.discountPercent! > 0)
                        _buildOfferDetailChip(
                          Icons.discount_outlined,
                          '-${offer.discountPercent!.toStringAsFixed(0)} %',
                        ),
                      if (offer.cadenceLabel?.isNotEmpty == true)
                        _buildOfferDetailChip(
                          Icons.event_repeat_outlined,
                          offer.cadenceLabel!,
                        )
                      else if (offer.visitsPerYear != null)
                        _buildOfferDetailChip(
                          Icons.event_repeat_outlined,
                          '${offer.visitsPerYear} visites / an',
                        )
                      else if (offer.visitIntervalMonths != null)
                        _buildOfferDetailChip(
                          Icons.event_repeat_outlined,
                          'Tous les ${offer.visitIntervalMonths} mois',
                        ),
                      if (offer.refrigerant?.isNotEmpty == true)
                        _buildOfferDetailChip(
                          Icons.ac_unit_outlined,
                          'Fréon ${offer.refrigerant}',
                        )
                      else if (offer.includesFreon)
                        _buildOfferDetailChip(
                          Icons.ac_unit_outlined,
                          'Fréon inclus',
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Bouton Accordéon : Déplier / Replier les prestations et options
                if (offer.features.isNotEmpty || offer.paidOptions.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedOfferIds.remove(offer.id);
                        } else {
                          _expandedOfferIds.add(offer.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isExpanded
                                ? 'Masquer le détail de l\'offre'
                                : 'Voir le détail & options (${offer.features.length + offer.paidOptions.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0a543d),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: const Color(0xFF0a543d),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contenu déroulant de l'accordéon
                  if (isExpanded) ...[
                    if (offer.features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: offer.features
                              .map((feature) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Color(0xFF0a543d),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    // Section des Options Payantes
                    if (offer.paidOptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 15, color: Colors.amber.shade900),
                                const SizedBox(width: 6),
                                Text(
                                  'Options payantes (non incluses) :',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...offer.paidOptions.map((opt) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded,
                                          size: 15,
                                          color: Colors.amber.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      if (opt.price != null ||
                                          opt.note != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            opt.price != null
                                                ? '${opt.price!.toInt()} FCFA'
                                                : (opt.note ?? 'Sur devis'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],

                const SizedBox(height: 14),

                // Bouton d'action principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSubscriptionDialog(offer),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded,
                        size: 18),
                    label: Text(
                      offer.isAnnual
                          ? 'Souscrire à l\'abonnement annuel'
                          : 'Demander cette intervention',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a543d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0a543d)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0a543d),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnualSubscriptionDialog(MaintenanceOffer offer) {
    int equipmentCount = 1;
    DateTime firstInterventionDate =
        DateTime.now().add(const Duration(days: 1));

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Abonnement annuel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${offer.price.toStringAsFixed(0)} FCFA${offer.priceNote?.isNotEmpty == true ? ' ${offer.priceNote}' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF0a543d),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (offer.discountPercent != null &&
                    offer.discountPercent! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Remise annoncée : -${offer.discountPercent!.toStringAsFixed(0)} %',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Le montant final et l\'échéancier seront confirmés par le serveur.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nombre d\'équipements couverts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: equipmentCount > 1
                          ? () => setDialogState(() => equipmentCount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$equipmentCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: equipmentCount < 10
                          ? () => setDialogState(() => equipmentCount++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Première intervention',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: dialogContext,
                      initialDate: firstInterventionDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (selectedDate != null) {
                      setDialogState(
                        () => firstInterventionDate = selectedDate,
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_formatDate(firstInterventionDate)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _createAnnualSubscription(
                  offer: offer,
                  equipmentCount: equipmentCount,
                  firstInterventionDate: firstInterventionDate,
                );
              },
              child: const Text('CONFIRMER'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAnnualSubscription({
    required MaintenanceOffer offer,
    required int equipmentCount,
    required DateTime firstInterventionDate,
  }) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      // Route dédiée aux offres annuelles : crée un contrat `scheduled` avec
      // visites planifiées, remise annuelle appliquée et conditions figées.
      final response =
          await _subscriptionRepository.createAnnualSubscription(
        maintenanceOfferId: offer.id,
        equipmentCount: equipmentCount,
        firstInterventionDate: firstInterventionDate,
      );
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Souscription refusée');
      }

      final payload = _asStringMap(response['data']) ?? response;
      final subscription = _asStringMap(payload['subscription']) ?? payload;
      final pricing = _asStringMap(payload['pricing']) ?? const {};
      final subscriptionId = _asInt(subscription['id'] ?? payload['id']);
      final firstPaymentAmount = _asDouble(
        payload['first_payment_amount'] ??
            subscription['first_payment_amount'] ??
            pricing['first_payment_amount'],
      );
      final secondPaymentAmount = _asDouble(
        payload['second_payment_amount'] ??
            subscription['second_payment_amount'] ??
            pricing['second_payment_amount'],
      );
      final totalAmount = _asDouble(
            subscription['price'] ??
                subscription['final_price'] ??
                payload['price'] ??
                payload['total_amount'] ??
                pricing['final_price'],
          ) ??
          ((firstPaymentAmount ?? 0) + (secondPaymentAmount ?? 0));
      final paymentStatus =
          (subscription['payment_status'] ?? payload['payment_status'])
              ?.toString();

      if (mounted && isLoadingDialogVisible && rootNavigator.canPop()) {
        rootNavigator.pop();
        isLoadingDialogVisible = false;
      }
      await _loadSubscriptions();
      if (!mounted) return;

      final requiresPayment = subscriptionId != null &&
          paymentStatus != 'paid' &&
          (firstPaymentAmount ?? 0) > 0;
      if (requiresPayment) {
        final paymentResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractPaymentScreen(
              subscriptionId: subscriptionId,
              reference: (subscription['reference'] ?? 'CTR-$subscriptionId')
                  .toString(),
              amount: totalAmount,
              contractType: 'scheduled',
              equipment: offer.title,
              firstPaymentStatus:
                  subscription['first_payment_status']?.toString(),
              secondPaymentStatus:
                  subscription['second_payment_status']?.toString(),
              firstPaymentAmount: firstPaymentAmount,
              secondPaymentAmount: secondPaymentAmount,
              visitsTotal: offer.visitsPerYear,
              visitIntervalMonths: offer.visitIntervalMonths,
            ),
          ),
        );
        if (paymentResult == true) await _loadSubscriptions();
      } else {
        SnackBarHelper.showSuccess(
          context,
          'Votre abonnement annuel a bien été créé.',
        );
      }
      if (mounted) _interventionNestedTabController.animateTo(1);
    } catch (error) {
      if (mounted && isLoadingDialogVisible && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Impossible de créer l\'abonnement : $error',
        );
      }
    }
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _showSubscriptionDialog(MaintenanceOffer offer) {
    int equipmentCount = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Demander une intervention'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous avez sélectionné l\'offre:',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${offer.price.toStringAsFixed(0)} FCFA / équipement',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Sélection du nombre d'équipements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre d\'équipements',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: equipmentCount > 1
                                ? () {
                                    setDialogState(() {
                                      equipmentCount--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color:
                                equipmentCount > 1 ? Colors.blue : Colors.grey,
                            iconSize: 32,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              '$equipmentCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: equipmentCount < 10
                                ? () {
                                    setDialogState(() {
                                      equipmentCount++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color:
                                equipmentCount < 10 ? Colors.blue : Colors.grey,
                            iconSize: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Total: ${(offer.price * equipmentCount).toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0a543d),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Message d'information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vous allez être redirigé vers le formulaire d\'intervention avec cette offre pré-sélectionnée.',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
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
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: () {
                // Fermer le dialogue
                Navigator.pop(context);

                // Naviguer vers la page de création d'intervention avec les paramètres pré-remplis
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewInterventionScreen(
                      preSelectedType: 'Maintenance',
                      preSelectedOfferId: offer.id,
                      preSelectedEquipmentCount: equipmentCount,
                    ),
                  ),
                );
              },
              child: const Text('CONTINUER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(MaintenanceOffer offer,
      {double discount = 0, double? finalPrice, int equipmentCount = 1}) {
    final displayPrice = finalPrice ?? (offer.price * equipmentCount);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement initié'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pending_outlined,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'En attente de confirmation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre souscription à "${offer.title}" pour $equipmentCount équipement(s) est en attente de confirmation de paiement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (discount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.discount, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Réduction: -${discount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Montant à payer: ${displayPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('RETOUR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aller sur l'onglet des souscriptions dans la section Intervention
              _interventionNestedTabController.animateTo(1);
              _loadSubscriptions();
            },
            child: const Text('VOIR MES SOUSCRIPTIONS'),
          ),
        ],
      ),
    );
  }

  void _showInstallationSubscriptionDialog(InstallationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de souscrire au service:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              service.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (service.model != null && service.model!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Modèle: ${service.model}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 4),
            if (service.price != null)
              Text(
                '${service.price!.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0a543d),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'En confirmant, vous acceptez les conditions générales de vente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await _subscriptionRepository.createServiceSubscription(
                  serviceId: service.id,
                  serviceType: 'installation',
                );

                navigator.pop();

                if (mounted) {
                  _showInstallationSuccessDialog(service);
                }
              } catch (e) {
                navigator.pop();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  void _showInstallationSuccessDialog(InstallationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement initié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pending_outlined,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'En attente de confirmation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre souscription au service "${service.title}" est en attente de confirmation de paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRepairSubscriptionDialog(RepairService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de souscrire au service:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              service.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (service.model != null && service.model!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Type: ${service.model}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 4),
            if (service.price != null)
              Text(
                service.price == 0
                    ? 'Gratuit'
                    : '${service.price!.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'En confirmant, vous acceptez les conditions générales de vente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await _subscriptionRepository.createServiceSubscription(
                  serviceId: service.id,
                  serviceType: 'repair',
                );

                navigator.pop();

                if (mounted) {
                  _showRepairSuccessDialog(service);
                }
              } catch (e) {
                navigator.pop();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  void _showRepairSuccessDialog(RepairService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement initié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pending_outlined,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'En attente de confirmation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre souscription au service "${service.title}" est en attente de confirmation de paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubscriptionsState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  size: 48,
                  color: Color(0xFF0a543d),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucune souscription',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vous n\'avez pas encore de souscription active. Consultez nos offres disponibles pour vous abonner !',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _interventionNestedTabController.animateTo(0);
                  },
                  icon: const Icon(Icons.explore_rounded,
                      size: 18, color: Colors.white),
                  label: Text(
                    'VOIR LES OFFRES',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final offer = subscription['offer'] as Map<String, dynamic>?;
    final status = subscription['status'] as String;
    final paymentStatus = subscription['payment_status'] as String;
    final startDate = DateTime.parse(subscription['start_date']);
    final endDate = DateTime.parse(subscription['end_date']);
    final price = subscription['price'] as num;
    final id = subscription['id'] as int;
    final equipmentCount = subscription['equipment_count'] as int? ?? 1;
    final equipmentUsed = subscription['equipment_used'] as int? ?? 0;
    final equipmentRemaining = equipmentCount - equipmentUsed;
    final usedAt = subscription['used_at'] != null
        ? DateTime.parse(subscription['used_at'])
        : null;
    final interventionId = subscription['intervention_id'] as int?;
    final firstPaymentAmount = _asDouble(subscription['first_payment_amount']);
    final secondPaymentAmount =
        _asDouble(subscription['second_payment_amount']);
    final visitsTotal = _asInt(subscription['visits_total']);
    final visitIntervalMonths = _asInt(subscription['visit_interval_months']);

    Color statusColor = Colors.green;
    String statusText = 'Active';
    IconData statusIcon = Icons.check_circle;

    if (status == 'pending_payment' &&
        paymentStatus != 'paid' &&
        paymentStatus != 'partial') {
      statusColor = Colors.orange;
      statusText = 'Paiement requis';
      statusIcon = Icons.schedule;
    } else if (status == 'used' || equipmentRemaining <= 0) {
      statusColor = Colors.blue;
      statusText = 'Utilisée';
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'expired') {
      statusColor = Colors.orange;
      statusText = 'Expirée';
      statusIcon = Icons.warning;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Annulée';
      statusIcon = Icons.cancel;
    }


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer?['title'] ?? 'Offre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$equipmentUsed/$equipmentCount utilisé${equipmentUsed > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (status == 'active' && equipmentRemaining > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$equipmentRemaining restant${equipmentRemaining > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: price == 0
                        ? Colors.blue.withValues(alpha: 0.1)
                        : (paymentStatus == 'paid'
                            ? Colors.green.withValues(alpha: 0.1)
                            : paymentStatus == 'partial'
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        price == 0
                            ? Icons.card_giftcard
                            : (paymentStatus == 'paid'
                                ? Icons.check_circle
                                : paymentStatus == 'partial'
                                    ? Icons.check_circle_outline
                                    : Icons.schedule),
                        size: 16,
                        color: price == 0
                            ? Colors.blue.shade700
                            : (paymentStatus == 'paid'
                                ? Colors.green
                                : paymentStatus == 'partial'
                                    ? Colors.blue.shade700
                                    : Colors.orange),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        price == 0
                            ? 'Gratuit'
                            : (paymentStatus == 'paid'
                                ? 'Payé'
                                : paymentStatus == 'partial'
                                    ? 'Acompte Payé (50%)'
                                    : 'En attente'),
                        style: TextStyle(
                          color: price == 0
                              ? Colors.blue.shade700
                              : (paymentStatus == 'paid'
                                  ? Colors.green
                                  : paymentStatus == 'partial'
                                      ? Colors.blue.shade700
                                      : Colors.orange),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((status == 'active' || status == 'pending_payment') &&
                paymentStatus == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteSubscription(id),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'SUPPRIMER',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractPaymentScreen(
                                subscriptionId: id,
                                reference:
                                    subscription['reference'] ?? 'CTR-$id',
                                amount: price.toDouble(),
                                contractType: 'scheduled',
                                equipment:
                                    subscription['equipment_description'] ??
                                        'Équipement',
                                model: subscription['equipment_model'],
                                firstPaymentStatus:
                                    subscription['first_payment_status'],
                                secondPaymentStatus:
                                    subscription['second_payment_status'],
                                firstPaymentAmount: firstPaymentAmount,
                                secondPaymentAmount: secondPaymentAmount,
                                visitsTotal: visitsTotal,
                                visitIntervalMonths: visitIntervalMonths,
                              ),
                            ),
                          );

                          // Recharger les souscriptions si le paiement a réussi
                          if (result == true) {
                            _loadSubscriptions();
                          }
                        },
                        icon: const Icon(Icons.credit_card, size: 18),
                        label: const Text('PAYER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Bouton pour utiliser la souscription active et payée (ou acompte payé)
            if (status == 'active' &&
                (paymentStatus == 'paid' || paymentStatus == 'partial'))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: equipmentRemaining > 0
                      ? ElevatedButton.icon(
                          onPressed: () {
                            // Naviguer vers la création d'intervention avec l'offre pré-sélectionnée
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewInterventionScreen(
                                  preSelectedType: 'Maintenance',
                                  preSelectedOfferId: offer?['id'] as int?,
                                  preSelectedSubscriptionId: id,
                                  preSelectedEquipmentCount:
                                      (subscription['equipment_count'] as num?)
                                          ?.toInt(),
                                ),
                              ),
                            ).then((_) {

                              // Recharger les souscriptions après retour
                              _loadSubscriptions();
                            });
                          },
                          icon: const Icon(Icons.build, size: 18),
                          label: const Text('UTILISER MAINTENANT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0a543d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('QUOTA ÉPUISÉ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                          ),
                        ),
                ),
              ),

            // Afficher les infos d'utilisation pour les souscriptions utilisées
            if (status == 'used' && usedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Souscription utilisée',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Le ${_formatDate(usedAt)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            if (interventionId != null)
                              Text(
                                'Intervention #$interventionId',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _deleteSubscription(int subscriptionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette souscription non payée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _subscriptionRepository.cancelSubscription(subscriptionId);

      if (mounted) {
        SnackBarHelper.showSuccess(
            context, 'Souscription supprimée avec succès',
            emoji: '🗑️');

        // Recharger les souscriptions
        _loadSubscriptions();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Widget _buildInstallationSubscriptionCard(Map<String, dynamic> subscription) {
    final service =
        subscription['installationService'] as Map<String, dynamic>?;
    final status = subscription['status'] as String;
    final paymentStatus = subscription['payment_status'] as String;
    final startDate = DateTime.parse(subscription['start_date']);
    final endDate = DateTime.parse(subscription['end_date']);
    final price = subscription['price'] as num;
    final id = subscription['id'] as int;

    Color statusColor = Colors.green;
    String statusText = 'Active';
    IconData statusIcon = Icons.check_circle;

    if (status == 'used') {
      statusColor = Colors.blue;
      statusText = 'Utilisée';
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'expired') {
      statusColor = Colors.orange;
      statusText = 'Expirée';
      statusIcon = Icons.warning;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Annulée';
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service?['name'] ?? 'Service d\'installation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        paymentStatus == 'paid'
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 16,
                        color: paymentStatus == 'paid'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatus == 'paid' ? 'Payé' : 'En attente',
                        style: TextStyle(
                          color: paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'active' && paymentStatus == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteSubscription(id),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'SUPPRIMER',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPaymentScreen(
                                subscriptionId: id,
                                subscriptionName: service?['name'] ??
                                    'Souscription Installation',
                                amount: price.toDouble(),
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadSubscriptions();
                          }
                        },
                        icon: const Icon(Icons.credit_card, size: 18),
                        label: const Text('PAYER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildRepairSubscriptionCard(Map<String, dynamic> subscription) {
    final service = subscription['repairService'] as Map<String, dynamic>?;
    final status = subscription['status'] as String;
    final paymentStatus = subscription['payment_status'] as String;
    final startDate = DateTime.parse(subscription['start_date']);
    final endDate = DateTime.parse(subscription['end_date']);
    final price = subscription['price'] as num;
    final id = subscription['id'] as int;

    Color statusColor = Colors.green;
    String statusText = 'Active';
    IconData statusIcon = Icons.check_circle;

    if (status == 'used') {
      statusColor = Colors.blue;
      statusText = 'Utilisée';
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'expired') {
      statusColor = Colors.orange;
      statusText = 'Expirée';
      statusIcon = Icons.warning;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Annulée';
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service?['name'] ?? 'Service de dépannage',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        paymentStatus == 'paid'
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 16,
                        color: paymentStatus == 'paid'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatus == 'paid' ? 'Payé' : 'En attente',
                        style: TextStyle(
                          color: paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'active' && paymentStatus == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteSubscription(id),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'SUPPRIMER',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPaymentScreen(
                                subscriptionId: id,
                                subscriptionName: service?['name'] ??
                                    'Souscription Dépannage',
                                amount: price.toDouble(),
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadSubscriptions();
                          }
                        },
                        icon: const Icon(Icons.credit_card, size: 18),
                        label: const Text('PAYER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
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

  // ========== ONGLET INSTALLATION ==========
  Widget _buildInstallationTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle,
                size: 64,
                color: Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 32),

            // Message informatif
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'Toutes les installations de splits sont soumises \u00e0 \u00e9laboration d\'un devis \u00e0 la suite d\'un diagnostic* et l\'installation se fera une fois le devis valid\u00e9 par le client.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '*4 000 FCFA le co\u00fbt du diagnostic',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton Commander un Diagnostic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewInterventionScreen(
                        preSelectedType: 'installation',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_outlined, size: 24),
                label: const Text(
                  'Commander un Diagnostic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a543d),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationServicesTab() {
    if (_isLoadingInstallation) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorInstallation != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorInstallation'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInstallationServices,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_installationServices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Aucun service d\'installation disponible pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _installationServices.length,
      itemBuilder: (context, index) {
        final service = _installationServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    color: Color(0xFF0a543d),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0a543d),
                        ),
                      ),
                      if (service.model != null &&
                          service.model!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.model!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (service.availabilityInfo != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.availabilityInfo!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.price != null
                        ? '${service.price!.toStringAsFixed(0)} F'
                        : '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstallationSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorSubscriptions != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorSubscriptions'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSubscriptions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Filtrer les souscriptions d'installation
    final installationSubs = _installationSubscriptions;

    if (installationSubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune souscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Vous n\'avez pas encore de souscription pour l\'installation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: installationSubs.length,
        itemBuilder: (context, index) {
          final subscription = installationSubs[index];
          return _buildInstallationSubscriptionCard(subscription);
        },
      ),
    );
  }

  // ========== ONGLET RÉPARATION (Offres uniquement) ==========
  Widget _buildRepairTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handyman,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),

            // Message informatif
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tous les dépannages de splits sont soumis à élaboration d\'un devis à la suite d\'un diagnostic* et le dépannage se fera une fois le devis validé par le client.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '*4 000 FCFA le coût du diagnostic',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton Commander un Diagnostic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewInterventionScreen(
                        preSelectedType: 'repair',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_outlined, size: 24),
                label: const Text(
                  'Commander un Diagnostic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairServicesTab() {
    if (_isLoadingRepair) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorRepair != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorRepair'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRepairServices,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_repairServices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Aucun service de dépannage disponible pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _repairServices.length,
      itemBuilder: (context, index) {
        final service = _repairServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.orange, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.handyman,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      if (service.model != null &&
                          service.model!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.model!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.price == null
                        ? '-'
                        : (service.price == 0
                            ? 'Gratuit'
                            : '${service.price!.toStringAsFixed(0)} F'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorSubscriptions != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorSubscriptions'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSubscriptions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Filtrer les souscriptions de réparation
    final repairSubs = _repairSubscriptions;

    if (repairSubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune souscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Vous n\'avez pas encore de souscription pour le dépannage.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: repairSubs.length,
        itemBuilder: (context, index) {
          final subscription = repairSubs[index];
          return _buildRepairSubscriptionCard(subscription);
        },
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0a543d).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0a543d),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
