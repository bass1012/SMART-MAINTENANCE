import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'subscription_payment_screen.dart';
import 'contract_payment_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late final SubscriptionRepository _subscriptionRepository;
  bool _isLoading = true;
  List<Map<String, dynamic>> _subscriptions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscriptionRepository = context.read<SubscriptionRepository>();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final subscriptions = await _subscriptionRepository.getSubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Souscriptions'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : _subscriptions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadSubscriptions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = _subscriptions[index];
                          return _buildSubscriptionCard(subscription);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
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
              'Vous n\'avez pas encore de souscription active.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
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

    Color statusColor = Colors.green;
    String statusText = 'Active';

    if (status == 'expired') {
      statusColor = Colors.orange;
      statusText = 'Expirée';
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Annulée';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${price.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid'
                        ? Colors.green.withValues(alpha: 0.2)
                        : paymentStatus == 'partial'
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentStatus == 'paid'
                        ? 'Payé'
                        : paymentStatus == 'partial'
                            ? 'Acompte Payé (50%)'
                            : 'En attente',
                    style: TextStyle(
                      color: paymentStatus == 'paid'
                          ? Colors.green
                          : paymentStatus == 'partial'
                              ? Colors.blue.shade700
                              : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (status == 'active' && paymentStatus == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Les souscriptions maintenance (offer != null) utilisent le paiement 50/50
                      final bool isMaintenance = offer != null;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isMaintenance
                              ? ContractPaymentScreen(
                                  subscriptionId: subscription['id'],
                                  reference: subscription['reference'] ?? 'CTR-${subscription['id']}',
                                  amount: price.toDouble(),
                                  contractType: subscription['contract_type'] ?? 'on_demand',
                                  equipment: subscription['equipment_description'] ?? offer!['title'] ?? 'Équipement',
                                  model: subscription['equipment_model'],
                                  firstPaymentStatus: subscription['first_payment_status'],
                                  secondPaymentStatus: subscription['second_payment_status'],
                                )
                              : SubscriptionPaymentScreen(
                                  subscriptionId: subscription['id'],
                                  subscriptionName: offer?['title'] ?? 'Souscription',
                                  amount: price.toDouble(),
                                ),
                        ),
                      );

                      // Recharger si le paiement a réussi
                      if (result == true) {
                        _loadSubscriptions();
                      }
                    },
                    child: const Text('PAYER MAINTENANT'),
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
}
