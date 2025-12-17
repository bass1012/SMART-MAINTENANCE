import 'package:flutter/material.dart';
import '../../models/maintenance_offer_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import 'subscription_payment_screen.dart';
import '../../utils/snackbar_helper.dart';

class MaintenanceOffersScreen extends StatefulWidget {
  const MaintenanceOffersScreen({super.key});

  @override
  State<MaintenanceOffersScreen> createState() =>
      _MaintenanceOffersScreenState();
}

class _MaintenanceOffersScreenState extends State<MaintenanceOffersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoadingOffers = true;
  bool _isLoadingSubscriptions = true;
  List<MaintenanceOffer> _offers = [];
  List<Map<String, dynamic>> _subscriptions = [];
  String? _errorOffers;
  String? _errorSubscriptions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Rebuild pour mettre à jour les badges
      if (_tabController.index == 1 && !_isLoadingSubscriptions) {
        _loadSubscriptions();
      }
    });
    _loadOffers();
    // Charger les souscriptions au démarrage aussi
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Compter les souscriptions en attente de paiement
    final pendingCount = _subscriptions
        .where(
            (s) => s['payment_status'] == 'pending' && s['status'] == 'active')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offres d\'Entretien'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadOffers();
              _loadSubscriptions();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Message de swipe subtil au-dessus des onglets
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.engineering_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text('Offres (${_offers.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.subscriptions_outlined, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Souscriptions (${_subscriptions.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pendingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersTab(),
          _buildSubscriptionsTab(),
        ],
      ),
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

    if (_subscriptions.isEmpty) {
      return _buildEmptySubscriptionsState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
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
              // Aller sur l'onglet des souscriptions
              _tabController.animateTo(1);
              _loadSubscriptions();
            },
            child: const Text('VOIR MES SOUSCRIPTIONS'),
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
                      child: ElevatedButton(
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
                        child: const Text('PAYER'),
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
}
