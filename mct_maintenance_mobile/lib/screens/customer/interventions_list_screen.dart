import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import '../../widgets/common/responsive_background.dart';
import 'intervention_detail_screen.dart';
import 'new_intervention_screen.dart';
import 'diagnostic_payment_screen.dart';
import 'subscription_payment_screen.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/test_keys.dart';

class InterventionsListScreen extends StatefulWidget {
  const InterventionsListScreen({super.key});

  @override
  State<InterventionsListScreen> createState() =>
      _InterventionsListScreenState();
}

class _InterventionsListScreenState extends State<InterventionsListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _interventions = [];
  List<Map<String, dynamic>> _pendingDiagnosticPayments = [];
  List<Map<String, dynamic>> _pendingSubscriptionPayments = [];
  String _filterStatus = 'all';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Rafraîchir automatiquement toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadInterventions(),
      _loadPendingDiagnosticPayments(),
      _loadPendingSubscriptionPayments(),
    ]);
  }

  Future<void> _loadPendingDiagnosticPayments() async {
    try {
      final pending = await _apiService.getPendingDiagnosticPayments();
      if (mounted) {
        setState(() {
          _pendingDiagnosticPayments = pending;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement paiements diagnostic en attente: $e');
    }
  }

  Future<void> _loadPendingSubscriptionPayments() async {
    try {
      final pending = await _apiService.getPendingSubscriptionPayments();
      if (mounted) {
        setState(() {
          _pendingSubscriptionPayments = pending;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement paiements souscription en attente: $e');
    }
  }

  Future<void> _loadInterventions() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _apiService.getUserData();

      // Extraire l'ID en essayant différentes structures possibles
      final customerId = userData?['id'] ??
          userData?['user']?['id'] ??
          userData?['data']?['user']?['id'];

      print('🔍 [Interventions] UserData keys: ${userData?.keys.toList()}');
      print('🔍 [Interventions] CustomerId extrait: $customerId');

      if (customerId == null) {
        throw Exception('Impossible de récupérer l\'ID utilisateur');
      }

      final response =
          await _apiService.getInterventions(customerId: customerId);

      if (mounted) {
        setState(() {
          _interventions = List<Map<String, dynamic>>.from(
              response['data']?['interventions'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredInterventions {
    if (_filterStatus == 'all') {
      return _interventions;
    }
    return _interventions.where((i) => i['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      alignLeft: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interventions'),
          backgroundColor: const Color(0xFF0a543d),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey(TestKeys.newInterventionFAB),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewInterventionScreen(),
              ),
            );

            if (result == true) {
              _loadData();
            }
          },
          backgroundColor: const Color(0xFF0a543d),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nouvelle Intervention',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SimpleResponsiveBackground(
          imagePath: 'assets/images/Maintenancier_SMART_Maintenance_two.png',
          opacity: 0.4,
          child: Column(
            children: [
              // Banner pour paiements diagnostic en attente
              if (_pendingDiagnosticPayments.isNotEmpty)
                _buildPendingPaymentsBanner(),

              // Banner pour paiements souscription en attente
              if (_pendingSubscriptionPayments.isNotEmpty)
                _buildPendingSubscriptionPaymentsBanner(),

              // Filtres
              _buildFilters(),

              // Liste des interventions
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInterventions.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              key: const ValueKey(TestKeys.interventionsList),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredInterventions.length,
                              itemBuilder: (context, index) {
                                final intervention =
                                    _filteredInterventions[index];
                                return _buildInterventionCard(intervention);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsBanner() {
    final count = _pendingDiagnosticPayments.length;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showPendingPaymentsDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1
                            ? '1 paiement en attente'
                            : '$count paiements en attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Finalisez vos demandes d\'intervention',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPendingPaymentsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiements en attente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Complétez le paiement pour activer vos demandes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Liste des paiements en attente
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingDiagnosticPayments.length,
                itemBuilder: (context, index) {
                  final intervention = _pendingDiagnosticPayments[index];
                  return _buildPendingPaymentCard(intervention);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentCard(Map<String, dynamic> intervention) {
    final id = intervention['id'];
    final title = intervention['title'] ?? 'Intervention #$id';
    final type = intervention['intervention_type'] ?? 'diagnostic';
    // Handle both String and num types for diagnostic_fee
    final rawFee = intervention['diagnostic_fee'];
    final diagnosticFee = rawFee is String
        ? double.tryParse(rawFee) ?? 4000.0
        : (rawFee as num?)?.toDouble() ?? 4000.0;
    final createdAt = intervention['created_at'] != null
        ? DateTime.parse(intervention['created_at'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type == 'repair' ? 'Dépannage' : 'Diagnostic',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#$id',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  '${diagnosticFee.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelConfirmation(intervention),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToPayment(intervention),
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: const Text('Payer maintenant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(Map<String, dynamic> intervention) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 32,
          ),
        ),
        title: const Text('Annuler l\'intervention ?'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler l\'intervention #${intervention['id']} ? Cette action est irréversible.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelIntervention(intervention);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelIntervention(Map<String, dynamic> intervention) async {
    try {
      final id = intervention['id'] is int
          ? intervention['id']
          : int.parse(intervention['id'].toString());

      await _apiService.cancelIntervention(id);

      if (mounted) {
        Navigator.pop(context); // Fermer le bottom sheet
        SnackBarHelper.showSuccess(
          context,
          'Intervention annulée',
          emoji: '✓',
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _navigateToPayment(Map<String, dynamic> intervention) async {
    Navigator.pop(context); // Fermer le bottom sheet

    final id = intervention['id'] is int
        ? intervention['id']
        : int.parse(intervention['id'].toString());
    final diagnosticFee = (intervention['diagnostic_fee'] ?? 4000).toDouble();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosticPaymentScreen(
          interventionId: id,
          diagnosticFee: diagnosticFee,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  // ==================== PAIEMENTS SOUSCRIPTION EN ATTENTE ====================

  Widget _buildPendingSubscriptionPaymentsBanner() {
    final count = _pendingSubscriptionPayments.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0a543d), Color(0xFF168d5f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showPendingSubscriptionPaymentsDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1
                            ? '1 offre d\'entretien en attente'
                            : '$count offres d\'entretien en attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Cliquez pour procéder au paiement',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPendingSubscriptionPaymentsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.card_membership,
                      color: Color(0xFF0a543d),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offres d\'entretien',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Paiements en attente',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Liste des paiements en attente
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingSubscriptionPayments.length,
                itemBuilder: (context, index) {
                  final subscription = _pendingSubscriptionPayments[index];
                  return _buildPendingSubscriptionCard(subscription);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSubscriptionCard(Map<String, dynamic> subscription) {
    final id = subscription['id'];
    final offer = subscription['offer'] as Map<String, dynamic>?;
    final title = offer?['title'] ?? 'Offre d\'entretien #$id';
    final description = offer?['description'] ?? '';
    final price = (subscription['price'] ?? offer?['price'] ?? 0).toDouble();
    final createdAt = subscription['created_at'] != null
        ? DateTime.parse(subscription['created_at'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF0a543d),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Entretien',
                    style: TextStyle(
                      color: Color(0xFF0a543d),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#$id',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money,
                    size: 14, color: Color(0xFF0a543d)),
                const SizedBox(width: 4),
                Text(
                  '${price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Color(0xFF0a543d),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSubscriptionPayment(subscription),
                icon: const Icon(Icons.credit_card, size: 18),
                label: const Text('Payer maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToSubscriptionPayment(
      Map<String, dynamic> subscription) async {
    Navigator.pop(context); // Fermer le bottom sheet

    final subscriptionId = subscription['id'] is int
        ? subscription['id']
        : int.parse(subscription['id'].toString());

    final offer = subscription['offer'] as Map<String, dynamic>?;
    final subscriptionName = offer?['title'] ?? 'Offre d\'entretien';
    final amount = (subscription['price'] ?? offer?['price'] ?? 0).toDouble();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPaymentScreen(
          subscriptionId: subscriptionId,
          subscriptionName: subscriptionName,
          amount: amount,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('En attente', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Assignée', 'assigned'),
            const SizedBox(width: 8),
            _buildFilterChip('Acceptée', 'accepted'),
            const SizedBox(width: 8),
            _buildFilterChip('En route', 'on_the_way'),
            const SizedBox(width: 8),
            _buildFilterChip('En cours', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Terminée', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: const Color(0xFF0a543d).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0a543d),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0a543d) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
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
            Icon(
              Icons.engineering_outlined,
              size: 80,
              color: const Color(0xFF0a543d).withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune intervention',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'all'
                  ? 'Vous n\'avez pas encore de demande d\'intervention'
                  : 'Aucune intervention avec ce statut',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    final status = intervention['status'] ?? 'pending';
    final priority = intervention['priority'] ?? 'medium';
    final scheduledDate = intervention['scheduled_date'] != null
        ? DateTime.parse(intervention['scheduled_date'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterventionDetailScreen(
                intervention: intervention,
              ),
            ),
          );

          if (result == true) {
            _loadInterventions();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et priorité
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention['title'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(priority),
                ],
              ),
              const SizedBox(height: 12),

              // Statut
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 20,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              if (intervention['description'] != null)
                Text(
                  intervention['description'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Informations supplémentaires
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    scheduledDate != null
                        ? '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}'
                        : 'Date non définie',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.format_list_numbered,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${intervention['equipment_count'] ?? 1} équip.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (intervention['address'] != null)
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        intervention['address'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Technicien assigné
              if (intervention['technician'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Technicien: ${intervention['technician']['first_name']} ${intervention['technician']['last_name']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],

              // Offre d'entretien
              if (intervention['maintenance_offer'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF0a543d).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer,
                          size: 16, color: Color(0xFF0a543d)),
                      const SizedBox(width: 4),
                      Text(
                        'Offre: ${intervention['maintenance_offer']['title']}',
                        style: const TextStyle(
                          color: Color(0xFF0a543d),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Service de réparation
              if (intervention['repair_service'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_outlined,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Dépannage: ${intervention['repair_service']['title']} - ${intervention['repair_service']['model']}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Service d'installation
              if (intervention['installation_service'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ac_unit_outlined,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Installation: ${intervention['installation_service']['title']} - ${intervention['installation_service']['model']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Indicateur paiement en attente
              if (_needsPayment(intervention)) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Paiement en attente',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _needsPayment(Map<String, dynamic> intervention) {
    // Check if this intervention requires payment
    final diagnosticPaid = intervention['diagnostic_paid'] ?? false;
    final diagnosticFee =
        double.tryParse(intervention['diagnostic_fee']?.toString() ?? '0') ?? 0;
    final isFree = intervention['is_free_diagnosis'] ?? true;

    // Needs payment if not free, has a fee, and not yet paid
    return !isFree && diagnosticFee > 0 && !diagnosticPaid;
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'low':
        color = Colors.blue;
        label = 'Basse';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Moyenne';
        break;
      case 'high':
        color = Colors.red;
        label = 'Haute';
        break;
      case 'critical':
        color = Colors.purple;
        label = 'Critique';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.assignment;
      case 'assigned':
        return Icons.person_add;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'on_the_way':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'accepted':
        return Colors.green.shade700;
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
        return Colors.teal;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente d\'assignation';
      case 'assigned':
        return 'Technicien assigné';
      case 'accepted':
        return 'Acceptée par le technicien';
      case 'on_the_way':
        return 'Technicien en route';
      case 'arrived':
        return 'Technicien sur place';
      case 'in_progress':
        return 'Intervention en cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
