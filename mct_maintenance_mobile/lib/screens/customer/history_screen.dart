import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const HistoryScreen({
    super.key,
    this.initialTabIndex = 0, // 0=Interventions, 1=Commandes, 2=Devis
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;

  List<HistoryItem> _interventions = [];
  List<HistoryItem> _orders = [];
  List<HistoryItem> _quotes = [];
  List<Map<String, dynamic>> _ordersRawData =
      []; // Données brutes des commandes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex, // Définir l'onglet initial
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      // Charger les vraies données depuis l'API
      final interventionsResponse = await _apiService.getInterventions();
      final ordersResponse = await _apiService.getOrders();
      final quotesResponse = await _apiService.getQuotes();

      if (mounted) {
        setState(() {
          _interventions = _parseInterventions(interventionsResponse);
          _ordersRawData =
              List<Map<String, dynamic>>.from(ordersResponse['data'] ?? []);
          _orders = _parseOrders(ordersResponse);
          _quotes = _parseQuotes(quotesResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur de chargement de l\'historique: $e');
      if (mounted) {
        setState(() {
          // En cas d'erreur, utiliser les données de démo
          _interventions = _getDemoInterventions();
          _orders = _getDemoOrders();
          _quotes = _getDemoQuotes();
          _isLoading = false;
        });
        SnackBarHelper.showError(context, 'Erreur de chargement: $e');
      }
    }
  }

  List<HistoryItem> _parseInterventions(Map<String, dynamic> response) {
    try {
      final List<dynamic> interventionsData = response['data'] ?? [];

      return interventionsData.map((interventionJson) {
        return HistoryItem(
          id: interventionJson['id'].toString(),
          title: _getInterventionTitle(interventionJson),
          date: DateTime.parse(interventionJson['scheduledDate'] ??
              interventionJson['createdAt'] ??
              DateTime.now().toIso8601String()),
          status:
              _mapInterventionStatus(interventionJson['status'] ?? 'pending'),
          type: 'intervention',
          description: interventionJson['description'] ??
              interventionJson['address'] ??
              'Intervention de maintenance',
          amount: interventionJson['cost'] != null
              ? double.tryParse(interventionJson['cost'].toString())
              : null,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors du parsing des interventions: $e');
      return [];
    }
  }

  String _getInterventionTitle(Map<String, dynamic> interventionJson) {
    final type = interventionJson['type'] ?? 'maintenance';
    final equipment = interventionJson['equipment'];

    if (equipment != null && equipment['name'] != null) {
      return '${_formatInterventionType(type)} - ${equipment['name']}';
    }

    return _formatInterventionType(type);
  }

  String _formatInterventionType(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return 'Maintenance';
      case 'repair':
        return 'Réparation';
      case 'installation':
        return 'Installation';
      case 'diagnostic':
        return 'Diagnostic';
      default:
        return type;
    }
  }

  String _mapInterventionStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'completed':
        return 'completed';
      case 'in_progress':
      case 'in-progress':
      case 'assigned':
        return 'pending';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  List<HistoryItem> _parseQuotes(Map<String, dynamic> response) {
    try {
      final List<dynamic> quotesData = response['data'] ?? [];

      return quotesData.map((quoteJson) {
        double amount = 0.0;
        if (quoteJson['total'] != null) {
          amount = double.tryParse(quoteJson['total'].toString()) ?? 0.0;
        } else if (quoteJson['amount'] != null) {
          amount = double.tryParse(quoteJson['amount'].toString()) ?? 0.0;
        }

        return HistoryItem(
          id: quoteJson['id'].toString(),
          title: quoteJson['reference'] ?? 'Devis #${quoteJson['id']}',
          date: DateTime.parse(quoteJson['issueDate'] ??
              quoteJson['createdAt'] ??
              DateTime.now().toIso8601String()),
          status: _mapQuoteStatus(quoteJson['status'] ?? 'pending'),
          type: 'quote',
          description:
              quoteJson['title'] ?? quoteJson['description'] ?? 'Devis',
          amount: amount,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors du parsing des devis: $e');
      return [];
    }
  }

  String _mapQuoteStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'accepted':
        return 'completed';
      case 'rejected':
        return 'cancelled';
      case 'sent':
      case 'pending':
      case 'draft':
        return 'pending';
      default:
        return 'pending';
    }
  }

  List<HistoryItem> _parseOrders(Map<String, dynamic> response) {
    try {
      final List<dynamic> ordersData = response['data'] ?? [];

      return ordersData.map((orderJson) {
        // Parser le montant avec plusieurs tentatives
        double amount = 0.0;
        if (orderJson['totalAmount'] != null) {
          amount = double.tryParse(orderJson['totalAmount'].toString()) ?? 0.0;
        } else if (orderJson['montant_total'] != null) {
          amount =
              double.tryParse(orderJson['montant_total'].toString()) ?? 0.0;
        } else if (orderJson['total'] != null) {
          amount = double.tryParse(orderJson['total'].toString()) ?? 0.0;
        } else if (orderJson['amount'] != null) {
          amount = double.tryParse(orderJson['amount'].toString()) ?? 0.0;
        }

        return HistoryItem(
          id: orderJson['id'].toString(),
          title: 'Commande #${orderJson['id']}',
          date: DateTime.parse(orderJson['created_at'] ??
              orderJson['createdAt'] ??
              DateTime.now().toIso8601String()),
          status: _mapOrderStatus(orderJson['status'] ?? 'pending'),
          type: 'order',
          description: orderJson['notes'] ??
              orderJson['shippingAddress'] ??
              'Commande #${orderJson['id']}',
          amount: amount,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors du parsing des commandes: $e');
      return [];
    }
  }

  String _mapOrderStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'completed':
      case 'delivered':
      case 'paid':
      case 'paye':
      case 'livre':
        return 'completed';
      case 'processing':
      case 'en_cours':
        return 'processing';
      case 'cancelled':
      case 'canceled':
      case 'annule':
        return 'cancelled';
      case 'pending':
      default:
        return 'pending';
    }
  }

  List<HistoryItem> _getDemoInterventions() {
    return [
      HistoryItem(
        id: '1',
        title: 'Maintenance préventive chaudière',
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'completed',
        type: 'intervention',
        description: 'Entretien annuel de la chaudière Viessmann',
      ),
      HistoryItem(
        id: '2',
        title: 'Réparation pompe à chaleur',
        date: DateTime.now().subtract(const Duration(days: 15)),
        status: 'completed',
        type: 'intervention',
        description: 'Remplacement du compresseur',
      ),
      HistoryItem(
        id: '3',
        title: 'Installation thermostat',
        date: DateTime.now().subtract(const Duration(days: 30)),
        status: 'completed',
        type: 'intervention',
        description: 'Installation d\'un thermostat connecté Nest',
      ),
    ];
  }

  List<HistoryItem> _getDemoOrders() {
    return [
      HistoryItem(
        id: '1',
        title: 'Commande #CMD-2025-001',
        date: DateTime.now().subtract(const Duration(days: 10)),
        status: 'delivered',
        type: 'order',
        description: 'Thermostat Nest + Installation',
        amount: 349.00,
      ),
      HistoryItem(
        id: '2',
        title: 'Commande #CMD-2024-089',
        date: DateTime.now().subtract(const Duration(days: 45)),
        status: 'delivered',
        type: 'order',
        description: 'Filtre pour chaudière',
        amount: 45.00,
      ),
    ];
  }

  List<HistoryItem> _getDemoQuotes() {
    return [
      HistoryItem(
        id: '1',
        title: 'Devis #DEV-2025-001',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'pending',
        type: 'quote',
        description: 'Installation pompe à chaleur',
        amount: 8500.00,
      ),
      HistoryItem(
        id: '2',
        title: 'Devis #DEV-2024-078',
        date: DateTime.now().subtract(const Duration(days: 60)),
        status: 'accepted',
        type: 'quote',
        description: 'Remplacement chaudière',
        amount: 3200.00,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHistory,
              tooltip: 'Actualiser',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Column(
              children: [
                // Titre subtil au-dessus des onglets
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Interventions'),
                      Tab(text: 'Commandes'),
                      Tab(text: 'Devis'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryList(_interventions),
                    _buildHistoryList(_orders),
                    _buildHistoryList(_quotes),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> items) {
    if (items.isEmpty) {
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
              Icon(Icons.history,
                  size: 64, color: const Color(0xFF0a543d).withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'Aucun historique',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (item.type == 'order') {
            _navigateToOrderDetail(item);
          } else {
            _showItemDetails(item);
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(item.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (item.amount != null)
                    Text(
                      '${item.amount!.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
      case 'delivered':
      case 'accepted':
        color = Colors.green;
        label = status == 'completed'
            ? 'Terminé'
            : status == 'delivered'
                ? 'Livré'
                : 'Accepté';
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.blue;
        label = 'En cours';
        icon = Icons.hourglass_empty;
        break;
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red;
        label = status == 'cancelled' ? 'Annulé' : 'Rejeté';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _navigateToOrderDetail(HistoryItem item) {
    // Trouver les données brutes de la commande
    final orderData = _ordersRawData.firstWhere(
      (order) => order['id'].toString() == item.id,
      orElse: () => {},
    );

    if (orderData.isEmpty) {
      SnackBarHelper.showError(
          context, 'Impossible de charger les détails de la commande');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: orderData),
      ),
    );
  }

  void _showItemDetails(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Type', _getTypeLabel(item.type)),
            _buildDetailRow('Date', _formatDate(item.date)),
            _buildDetailRow('Description', item.description),
            if (item.amount != null)
              _buildDetailRow(
                  'Montant', '${item.amount!.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SnackBarHelper.showInfo(
                      context, 'Voir les détails - À implémenter');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Voir les détails complets'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'intervention':
        return 'Intervention';
      case 'order':
        return 'Commande';
      case 'quote':
        return 'Devis';
      default:
        return type;
    }
  }
}

// Modèle d'élément d'historique
class HistoryItem {
  final String id;
  final String title;
  final DateTime date;
  final String status;
  final String type;
  final String description;
  final double? amount;

  HistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.type,
    required this.description,
    this.amount,
  });
}
