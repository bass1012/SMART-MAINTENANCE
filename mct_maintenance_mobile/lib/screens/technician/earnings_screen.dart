import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';

class TechnicianEarningsScreen extends StatefulWidget {
  const TechnicianEarningsScreen({super.key});

  @override
  State<TechnicianEarningsScreen> createState() =>
      _TechnicianEarningsScreenState();
}

class _TechnicianEarningsScreenState extends State<TechnicianEarningsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // month, week, year

  // Données fictives
  final Map<String, double> _earnings = {
    'month': 385000,
    'week': 95000,
    'year': 1250000,
  };

  final List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);

    // Simuler un chargement
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _transactions.addAll([
          {
            'date': '2025-10-26',
            'title': 'Réparation climatisation',
            'customer': 'Jean Dupont',
            'amount': 45000,
            'status': 'paid',
          },
          {
            'date': '2025-10-25',
            'title': 'Installation pompe',
            'customer': 'Marie Kouassi',
            'amount': 65000,
            'status': 'paid',
          },
          {
            'date': '2025-10-24',
            'title': 'Maintenance préventive',
            'customer': 'Société ABC',
            'amount': 85000,
            'status': 'pending',
          },
          {
            'date': '2025-10-23',
            'title': 'Dépannage électrique',
            'customer': 'Paul Bamba',
            'amount': 35000,
            'status': 'paid',
          },
          {
            'date': '2025-10-22',
            'title': 'Vérification système alarme',
            'customer': 'Restaurant Le Palmier',
            'amount': 55000,
            'status': 'paid',
          },
        ]);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Revenus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildEarningsSummary(),
                  const SizedBox(height: 24),
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  _buildTransactionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsSummary() {
    final currentEarnings = _earnings[_selectedPeriod] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    SnackBarHelper.showInfo(
                        context, 'Télécharger le rapport - À implémenter');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Revenus totaux',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${currentEarnings.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPeriodLabel(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodChip('week', 'Semaine', Icons.calendar_today),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodChip('month', 'Mois', Icons.calendar_month),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodChip('year', 'Année', Icons.calendar_view_month),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String period, String label, IconData icon) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = period);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                SnackBarHelper.showInfo(context, 'Voir tout - À implémenter');
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._transactions
            .map((transaction) => _buildTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isPaid = transaction['status'] == 'paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPaid
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          transaction['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(transaction['customer']),
            const SizedBox(height: 2),
            Text(
              transaction['date'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction['amount']} FCFA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPaid ? 'Payé' : 'En attente',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPaid ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois-ci';
      case 'year':
        return 'Cette année';
      default:
        return '';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Toutes'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(
                    context, 'Afficher toutes les transactions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Payées'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(
                    context, 'Afficher transactions payées');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: const Text('En attente'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(
                    context, 'Afficher transactions en attente');
              },
            ),
          ],
        ),
      ),
    );
  }
}
