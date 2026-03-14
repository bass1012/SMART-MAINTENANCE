import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quote_contract_model.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import 'quote_detail_screen.dart';
import 'contract_detail_screen.dart';
import '../../utils/snackbar_helper.dart';
import 'payment_screen.dart';

class QuotesContractsScreen extends StatefulWidget {
  const QuotesContractsScreen({super.key});

  @override
  State<QuotesContractsScreen> createState() => _QuotesContractsScreenState();
}

class _QuotesContractsScreenState extends State<QuotesContractsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoadingQuotes = true;
  bool _isLoadingContracts = true;
  List<QuoteContract> _quotes = [];
  List<Contract> _contracts = [];
  String? _errorQuotes;
  String? _errorContracts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuotes();
    _loadContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    try {
      final quotes = await _apiService.getCustomerQuotes();
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoadingQuotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorQuotes = e.toString();
          _isLoadingQuotes = false;
        });
      }
    }
  }

  Future<void> _loadContracts() async {
    try {
      final contracts = await _apiService.getCustomerContracts();
      if (mounted) {
        setState(() {
          _contracts = contracts;
          _isLoadingContracts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorContracts = e.toString();
          _isLoadingContracts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Devis et Contrats'),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text('Devis (${_quotes.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text('Contrats (${_contracts.length})'),
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
              // Onglet Devis
              _buildQuotesTab(),
              // Onglet Contrats
              _buildContractsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesTab() {
    if (_isLoadingQuotes) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorQuotes != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorQuotes'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuotes,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_quotes.isEmpty) {
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
              Icon(Icons.description_outlined,
                  size: 64, color: const Color(0xFF0a543d).withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'Aucun devis trouvé',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quotes.length,
        itemBuilder: (context, index) {
          final quote = _quotes[index];
          return _buildQuoteCard(quote);
        },
      ),
    );
  }

  Widget _buildContractsTab() {
    if (_isLoadingContracts) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorContracts != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorContracts'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContracts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_contracts.isEmpty) {
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
              Icon(Icons.assignment_outlined,
                  size: 64, color: const Color(0xFF0a543d).withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'Aucun contrat trouvé',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContracts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contracts.length,
        itemBuilder: (context, index) {
          final contract = _contracts[index];
          return _buildContractCard(contract);
        },
      ),
    );
  }

  Widget _buildQuoteCard(QuoteContract quote) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(quote.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(quote: quote),
            ),
          );

          if (result == true) {
            _loadQuotes(); // Recharger la liste si le devis a été modifié
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quote.reference,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatStatus(quote.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              // Badge de statut de paiement pour les devis acceptés
              if (quote.status == 'accepted' &&
                  quote.paymentStatus != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: quote.paymentStatus == 'paid'
                            ? Colors.green.withOpacity(0.2)
                            : quote.paymentStatus == 'deferred'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            quote.paymentStatus == 'paid'
                                ? Icons.check_circle
                                : quote.paymentStatus == 'deferred'
                                    ? Icons.schedule
                                    : Icons.hourglass_empty,
                            size: 14,
                            color: quote.paymentStatus == 'paid'
                                ? Colors.green.shade700
                                : quote.paymentStatus == 'deferred'
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quote.paymentStatus == 'paid'
                                ? 'Payé'
                                : quote.paymentStatus == 'deferred'
                                    ? 'Paiement reporté'
                                    : 'Paiement en attente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: quote.paymentStatus == 'paid'
                                  ? Colors.green.shade700
                                  : quote.paymentStatus == 'deferred'
                                      ? Colors.blue.shade700
                                      : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                quote.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quote.amount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  if (quote.validUntil != null)
                    Text(
                      'Valable jusqu\'au ${dateFormat.format(quote.validUntil!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (quote.status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Refuser le devis
                          },
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _acceptQuote(quote.id);
                          },
                          child: const Text('Accepter'),
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
  }

  Future<void> _acceptQuote(String quoteId) async {
    // Premier dialog: choisir entre exécution immédiate ou planification
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comment souhaitez-vous procéder ?',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'immediate'),
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text('Exécuter immédiatement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a543d),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le technicien est sur place',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'schedule'),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Planifier pour plus tard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0a543d),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0a543d)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisir une date et heure',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'immediate') {
      await _processAcceptQuote(quoteId, executeNow: true);
    } else {
      await _showScheduleDialog(quoteId);
    }
  }

  Future<void> _showScheduleDialog(String quoteId) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final secondContactController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Planifier l\'intervention'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veuillez remplir les informations suivantes :',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: secondContactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Second contact',
                    hintText: 'Optionnel',
                    prefixIcon: const Icon(Icons.phone, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: selectedDate == null
                        ? 'Sélectionner'
                        : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  enabled: selectedDate != null,
                  onTap: selectedDate == null
                      ? null
                      : () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                  decoration: InputDecoration(
                    labelText: 'Heure',
                    hintText: selectedTime == null
                        ? 'Sélectionner'
                        : selectedTime!.format(context),
                    prefixIcon: Icon(Icons.access_time,
                        size: 20,
                        color: selectedDate == null ? Colors.grey : null),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedDate != null && selectedTime != null
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedDate == null || selectedTime == null)
      return;

    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final secondContact = secondContactController.text.trim();
    await _processAcceptQuote(
      quoteId,
      scheduledDate: scheduledDateTime,
      secondContact: secondContact.isNotEmpty ? secondContact : null,
    );
  }

  Future<void> _processAcceptQuote(
    String quoteId, {
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
  }) async {
    try {
      await _apiService.acceptQuote(
        quoteId,
        scheduledDate: scheduledDate,
        executeNow: executeNow,
        secondContact: secondContact,
      );
      if (mounted) {
        // Si c'est une intervention planifiée pour plus tard
        if (!executeNow && scheduledDate != null) {
          // Afficher confirmation avec date planifiée, pas de redirection paiement
          final formattedDate =
              '${scheduledDate.day.toString().padLeft(2, '0')}/${scheduledDate.month.toString().padLeft(2, '0')}/${scheduledDate.year}';
          final formattedTime =
              '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text('Devis accepté'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Votre intervention est planifiée pour :',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF0a543d)),
                        const SizedBox(width: 8),
                        Text(
                          '$formattedDate à $formattedTime',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0a543d),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Le paiement sera effectué le jour de l\'intervention.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          _loadQuotes();
          return;
        }

        // Exécution immédiate → rediriger vers paiement
        SnackBarHelper.showSuccess(context, 'Devis accepté avec succès',
            emoji: '✓');

        // 🛒 Récupérer la liste des commandes pour trouver celle qui vient d'être créée
        try {
          final ordersResponse = await _apiService.get('/orders');
          print('🔍 DEBUG Orders response: $ordersResponse');

          final orders =
              (ordersResponse['data'] as List?)?.cast<Map<String, dynamic>>() ??
                  [];
          print('🔍 DEBUG Nombre de commandes: ${orders.length}');

          if (orders.isNotEmpty) {
            print('🔍 DEBUG Première commande: ${orders.first}');
          }

          final quoteIdInt = int.tryParse(quoteId);
          print('🔍 DEBUG Recherche commande pour quoteId: $quoteIdInt');

          // Trouver la commande la plus récente liée à ce devis
          final recentOrder = orders.firstWhere(
            (order) {
              final orderQuoteId = order['quoteId'];
              print('🔍 DEBUG Order ${order['id']}: quoteId=$orderQuoteId');
              return orderQuoteId == quoteIdInt ||
                  orderQuoteId.toString() == quoteId;
            },
            orElse: () => <String, dynamic>{},
          );

          print('🔍 DEBUG Commande trouvée: $recentOrder');

          if (recentOrder.isNotEmpty && recentOrder['id'] != null) {
            print(
                '✅ Navigation vers paiement pour commande ${recentOrder['id']}');
            // Naviguer directement vers l'écran de paiement
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  invoiceId: recentOrder['id'].toString(),
                  invoiceNumber: recentOrder['reference'] ?? 'N/A',
                  amount: (recentOrder['totalAmount'] ?? 0).toDouble(),
                ),
              ),
            ).then((_) => _loadQuotes()); // Rafraîchir après retour du paiement
          } else {
            print('⚠️  Aucune commande trouvée, rafraîchissement normal');
            // Si pas de commande trouvée, rafraîchir normalement
            _loadQuotes();
          }
        } catch (e) {
          print('⚠️  Erreur récupération commande: $e');
          // En cas d'erreur, rafraîchir normalement
          _loadQuotes();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blueGrey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'sent':
        return 'Envoyé';
      case 'accepted':
        return 'Accepté';
      case 'rejected':
        return 'Refusé';
      case 'expired':
        return 'Expiré';
      case 'pending':
        return 'En attente';
      case 'pending_payment':
        return 'Paiement en attente';
      case 'active':
        return 'Actif';
      case 'awaiting_second_payment':
        return 'Paiement final requis';
      case 'completed':
        return 'Terminé';
      case 'used':
        return 'Consommé';
      case 'terminated':
        return 'Résilié';
      default:
        return status;
    }
  }

  Widget _buildContractCard(Contract contract) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getContractStatusColor(contract.status);
    final isActive = contract.status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailScreen(contract: contract),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getContractTypeIcon(contract.type),
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contract.reference,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contract.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatStatus(contract.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Début',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(contract.startDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Fin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(contract.endDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isActive &&
                                    contract.endDate.isBefore(DateTime.now()
                                        .add(const Duration(days: 30)))
                                ? Colors.orange
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                        '${contract.amount.toStringAsFixed(0)} FCFA',
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatPaymentFrequency(contract.paymentFrequency),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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

  Color _getContractStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blueGrey;
      case 'pending':
        return Colors.orange;
      case 'pending_payment':
        return Colors.deepOrange;
      case 'active':
        return Colors.green;
      case 'awaiting_second_payment':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'used':
        return Colors.purple;
      case 'expired':
        return Colors.red;
      case 'terminated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getContractTypeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build_circle;
      case 'scheduled_maintenance':
        return Icons.calendar_month;
      case 'support':
        return Icons.support_agent;
      case 'warranty':
        return Icons.verified_user;
      case 'service':
        return Icons.room_service;
      default:
        return Icons.assignment;
    }
  }

  String _formatPaymentFrequency(String frequency) {
    switch (frequency) {
      case 'monthly':
        return 'Mensuel';
      case 'quarterly':
        return 'Trimestriel';
      case 'yearly':
        return 'Annuel';
      case 'one_time':
        return 'Unique';
      default:
        return frequency;
    }
  }
}
