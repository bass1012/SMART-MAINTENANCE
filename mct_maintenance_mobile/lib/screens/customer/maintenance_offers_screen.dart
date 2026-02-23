import 'package:flutter/material.dart';
import '../../models/maintenance_offer_model.dart';
import '../../models/installation_service.dart';
import '../../models/repair_service.dart';
import '../../services/api_service.dart';
import '../../services/service_api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import 'subscription_payment_screen.dart';
import '../../utils/snackbar_helper.dart';
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
  final ApiService _apiService = ApiService();
  final ServiceApiService _serviceApiService = ServiceApiService();
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

  @override
  void initState() {
    super.initState();
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
      final offers = await _apiService.getMaintenanceOffers();
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
    print('🔄 Début du chargement des souscriptions...');
    setState(() {
      _isLoadingSubscriptions = true;
      _errorSubscriptions = null;
    });

    try {
      print('📞 Appel API getSubscriptions()...');
      final subscriptions = await _apiService.getSubscriptions();
      print('✅ Souscriptions reçues: ${subscriptions.length}');
      print('📦 Données: $subscriptions');

      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoadingSubscriptions = false;
        });
        print('✅ État mis à jour avec succès');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement des souscriptions: $e');
      print('📍 Stack trace: $stackTrace');

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
      final services = await _serviceApiService.getActiveInstallationServices();
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
      final services = await _serviceApiService.getActiveRepairServices();
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
        .where(
            (s) => s['payment_status'] == 'pending' && s['status'] == 'active')
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
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Glissez pour naviguer entre les sections',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
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
                            color: const Color(0xFF0a543d).withOpacity(0.3),
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
                              Text('Entretien'),
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
                              Text('Réparation'),
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
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _interventionNestedTabController,
            labelColor: const Color(0xFF0a543d),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0a543d),
            tabs: const [
              Tab(text: 'Nos Offres'),
              Tab(text: 'Mes Souscriptions'),
            ],
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

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _buildOfferCard(offer);
        },
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorSubscriptions != null) {
      // Vérifier si c'est une erreur d'authentification
      final isAuthError = _errorSubscriptions!.contains('Session expirée') ||
          _errorSubscriptions!.contains('AUTH_ERROR') ||
          _errorSubscriptions!.contains('Invalid token');

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuthError ? Icons.lock_clock : Icons.error_outline,
              size: 64,
              color: isAuthError ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isAuthError
                    ? 'Votre session a expiré'
                    : 'Erreur: $_errorSubscriptions',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isAuthError
                  ? () async {
                      await _apiService.logout();
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

  Widget _buildOfferCard(MaintenanceOffer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'OFFRE ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${offer.duration} mois',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (offer.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      offer.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ce forfait comprend:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...offer.features.map((feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'pour ${offer.duration} mois',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showSubscriptionDialog(offer);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Souscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(MaintenanceOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de souscrire à l\'offre:',
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
              '${offer.price.toStringAsFixed(0)} FCFA pour ${offer.duration} mois',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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
              // Capturer le contexte avant l'opération async
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Fermer le dialogue de confirmation
              navigator.pop();

              // Afficher un loader
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Créer la souscription
                await _apiService.createSubscription(offer.id);

                // Fermer le loader
                navigator.pop();

                // Afficher le succès
                if (mounted) {
                  _showSuccessDialog(offer);
                }
              } catch (e) {
                // Fermer le loader
                navigator.pop();

                // Afficher l'erreur
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

  void _showSuccessDialog(MaintenanceOffer offer) {
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
              'Votre souscription à "${offer.title}" est en attente de confirmation de paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
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
            const SizedBox(height: 4),
            Text(
              'Modèle: ${service.model}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${service.price.toStringAsFixed(0)} FCFA',
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
                await _apiService.createServiceSubscription(
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
        title: const Text('Souscription confirmée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Souscription réussie',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez souscrit au service "${service.title}" avec succès.',
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
            const SizedBox(height: 4),
            Text(
              'Type: ${service.model}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.price == 0
                  ? 'Gratuit'
                  : '${service.price.toStringAsFixed(0)} FCFA',
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
                await _apiService.createServiceSubscription(
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
        title: const Text('Souscription confirmée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Souscription réussie',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez souscrit au service "${service.title}" avec succès.',
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subscriptions_outlined,
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
              'Vous n\'avez pas encore de souscription active. Consultez les offres disponibles !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            child: const Text('VOIR LES OFFRES'),
          ),
        ],
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

    Color statusColor = Colors.green;
    String statusText = 'Active';
    IconData statusIcon = Icons.check_circle;

    if (status == 'expired') {
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
                    offer?['title'] ?? 'Offre',
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
                    color: statusColor.withOpacity(0.1),
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
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
                                subscriptionName:
                                    offer?['title'] ?? 'Souscription',
                                amount: price.toDouble(),
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
      await _apiService.cancelSubscription(subscriptionId);

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

    if (status == 'expired') {
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
                    color: statusColor.withOpacity(0.1),
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
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

    if (status == 'expired') {
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
                    service?['name'] ?? 'Service de réparation',
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
                    color: statusColor.withOpacity(0.1),
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
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
                                    'Souscription Réparation',
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
                color: const Color(0xFF0a543d).withOpacity(0.1),
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
                      builder: (context) => const NewInterventionScreen(),
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
                    color: const Color(0xFF0a543d).withOpacity(0.1),
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
                      const SizedBox(height: 4),
                      Text(
                        service.model,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
                    '${service.price.toStringAsFixed(0)} F',
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
                color: Colors.orange.withOpacity(0.1),
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
                    'Toutes les réparations/dépannages de splits sont soumis à élaboration d\'un devis à la suite d\'un diagnostic* et la réparation se fera une fois le devis validé par le client.',
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
                      builder: (context) => const NewInterventionScreen(),
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
            'Aucun service de réparation disponible pour le moment.',
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
                    color: Colors.orange.withOpacity(0.1),
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
                      const SizedBox(height: 4),
                      Text(
                        service.model,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
                    service.price == 0
                        ? 'Gratuit'
                        : '${service.price.toStringAsFixed(0)} F',
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
                'Vous n\'avez pas encore de souscription pour la réparation.',
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
            color: const Color(0xFF0a543d).withOpacity(0.1),
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
