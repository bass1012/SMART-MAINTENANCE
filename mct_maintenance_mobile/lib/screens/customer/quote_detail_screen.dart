import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quote_contract_model.dart';
import '../../services/api_service.dart';
import 'payment_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  final QuoteContract quote;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  late QuoteContract _quote;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
  }

  Future<void> _acceptQuote() async {
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
      // Exécution immédiate
      await _processAcceptQuote(executeNow: true);
    } else {
      // Planification
      await _showScheduleDialog();
    }
  }

  Future<void> _showScheduleDialog() async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final secondContactController = TextEditingController();

    // Dialog pour sélectionner la date et l'heure de l'intervention
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

                // Champ pour le second contact
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

                // Sélection de la date
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

                // Sélection de l'heure
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

    // Combiner date et heure
    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final secondContact = secondContactController.text.trim();
    await _processAcceptQuote(
      scheduledDate: scheduledDateTime,
      secondContact: secondContact.isNotEmpty ? secondContact : null,
    );
  }

  Future<void> _processAcceptQuote({
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
  }) async {
    setState(() => _isLoading = true);

    try {
      await _apiService.acceptQuote(
        _quote.id,
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

          Navigator.pop(context, true);
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

          final quoteIdInt = int.tryParse(_quote.id);
          print('🔍 DEBUG Recherche commande pour quoteId: $quoteIdInt');

          // Trouver la commande la plus récente liée à ce devis
          final recentOrder = orders.firstWhere(
            (order) {
              final orderQuoteId = order['quoteId'];
              print('🔍 DEBUG Order ${order['id']}: quoteId=$orderQuoteId');
              return orderQuoteId == quoteIdInt ||
                  orderQuoteId.toString() == _quote.id;
            },
            orElse: () => <String, dynamic>{},
          );

          print('🔍 DEBUG Commande trouvée: $recentOrder');

          if (recentOrder.isNotEmpty && recentOrder['id'] != null) {
            print(
                '✅ Navigation vers paiement pour commande ${recentOrder['id']}');
            // Naviguer directement vers l'écran de paiement
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  invoiceId: recentOrder['id'].toString(),
                  invoiceNumber: recentOrder['reference'] ?? 'N/A',
                  amount: (recentOrder['totalAmount'] ?? 0).toDouble(),
                ),
              ),
            );
          } else {
            print('⚠️  Aucune commande trouvée, retour normal');
            // Si pas de commande trouvée, retourner normalement
            Navigator.pop(context, true);
          }
        } catch (e) {
          print('⚠️  Erreur récupération commande: $e');
          // En cas d'erreur, retourner normalement
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _rejectQuote() async {
    String rejectionReason = '';

    // Dialog pour demander la raison du refus
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pourquoi refusez-vous ce devis ?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
              onChanged: (value) => rejectionReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final reason = rejectionReason.trim().isEmpty
          ? 'Refusé par le client'
          : rejectionReason.trim();
      final updatedQuote = await _apiService.rejectQuote(_quote.id, reason);

      print(
          '🔄 Devis mis à jour - Statut: ${updatedQuote.status}, Raison: ${updatedQuote.rejectionReason}');

      if (mounted) {
        setState(() {
          _quote = updatedQuote;
          _isLoading = false;
        });
        SnackBarHelper.showWarning(context, 'Devis refusé');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _payNow() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer la commande associée au devis
      final ordersResponse = await _apiService.get('/orders');
      final orders =
          (ordersResponse['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final quoteIdInt = int.tryParse(_quote.id);

      // Trouver la commande liée à ce devis
      final order = orders.firstWhere(
        (order) {
          final orderQuoteId = order['quoteId'];
          return orderQuoteId == quoteIdInt ||
              orderQuoteId.toString() == _quote.id;
        },
        orElse: () => <String, dynamic>{},
      );

      if (order.isNotEmpty && order['id'] != null) {
        // Naviguer vers l'écran de paiement
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                invoiceId: order['id'].toString(),
                invoiceNumber: order['reference'] ?? 'N/A',
                amount: (order['totalAmount'] ?? _quote.amount).toDouble(),
              ),
            ),
          ).then((_) {
            // Recharger le devis après paiement
            _refreshQuote();
          });
        }
      } else {
        // Pas de commande trouvée, créer une session de paiement directe
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.showError(
            context,
            'Commande non trouvée. Veuillez contacter le support.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _refreshQuote() async {
    try {
      final updatedQuote = await _apiService.getQuoteDetails(_quote.id);
      if (mounted) {
        setState(() {
          _quote = updatedQuote;
        });
      }
    } catch (e) {
      print('⚠️ Erreur rafraîchissement devis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(_quote.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Devis'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec référence et statut
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _quote.reference,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
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
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    _formatStatus(_quote.status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _quote.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations du devis
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Date d\'émission',
                              dateFormat.format(_quote.createdAt),
                            ),
                            const SizedBox(height: 12),
                            if (_quote.validUntil != null)
                              _buildInfoRow(
                                Icons.event_available,
                                'Valable jusqu\'au',
                                dateFormat.format(_quote.validUntil!),
                              ),
                            if (_quote.validUntil != null &&
                                _quote.scheduledDate != null)
                              const SizedBox(height: 12),
                            // Afficher la date planifiée si le devis est accepté
                            if (_quote.scheduledDate != null)
                              _buildInfoRow(
                                Icons.schedule,
                                'Intervention prévue le',
                                '${dateFormat.format(_quote.scheduledDate!)} à ${DateFormat('HH:mm').format(_quote.scheduledDate!)}',
                              ),
                            if (_quote.scheduledDate != null &&
                                _quote.secondContact != null)
                              const SizedBox(height: 12),
                            // Afficher le second contact si fourni
                            if (_quote.secondContact != null &&
                                _quote.secondContact!.isNotEmpty)
                              _buildInfoRow(
                                Icons.phone,
                                'Second contact',
                                _quote.secondContact!,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    if (_quote.description.isNotEmpty)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _quote.description,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Articles/Produits
                    if (_quote.items.isNotEmpty)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Articles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(_quote.items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                                return Column(
                                  children: [
                                    if (index > 0) const Divider(height: 24),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Badge personnalisé si article custom
                                        if (item.isCustom)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: Colors.orange),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        if (item.isCustom)
                                          const SizedBox(width: 8),

                                        // Nom du produit
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} FCFA',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (item.discount > 0) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Remise: ${item.discount}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Total de la ligne
                                        Text(
                                          '${item.total.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0a543d),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }).toList()),
                            ],
                          ),
                        ),
                      ),
                    if (_quote.items.isNotEmpty) const SizedBox(height: 16),

                    // Montant
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Montant Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_quote.amount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'action
                    if (_quote.status == 'pending' || _quote.status == 'sent')
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _acceptQuote,
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'Accepter le devis',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _rejectQuote,
                              icon: const Icon(Icons.cancel),
                              label: const Text(
                                'Refuser le devis',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Message pour devis accepté/refusé
                    if (_quote.status == 'accepted')
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Vous avez accepté ce devis',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Afficher le statut du paiement
                                if (_quote.paymentStatus != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        _quote.paymentStatus == 'paid'
                                            ? Icons.payment
                                            : _quote.paymentStatus == 'deferred'
                                                ? Icons.schedule
                                                : Icons.hourglass_empty,
                                        color: _quote.paymentStatus == 'paid'
                                            ? Colors.green.shade700
                                            : _quote.paymentStatus == 'deferred'
                                                ? Colors.blue.shade700
                                                : Colors.orange.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _quote.paymentStatus == 'paid'
                                            ? 'Paiement effectué'
                                            : _quote.paymentStatus == 'deferred'
                                                ? 'Paiement reporté'
                                                : 'Paiement en attente',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _quote.paymentStatus == 'paid'
                                              ? Colors.green.shade700
                                              : _quote.paymentStatus ==
                                                      'deferred'
                                                  ? Colors.blue.shade700
                                                  : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Bouton "Payer maintenant" pour paiement différé
                          if (_quote.paymentStatus == 'deferred') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _payNow,
                                icon: const Icon(Icons.payment),
                                label: const Text(
                                  'Payer maintenant',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0a543d),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                    if (_quote.status == 'rejected')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Vous avez refusé ce devis',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_quote.rejectionReason != null &&
                                _quote.rejectionReason!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Raison du refus:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _quote.rejectionReason!,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blueGrey;
      case 'sent':
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
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
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Accepté';
      case 'rejected':
        return 'Refusé';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }
}
