import '../../utils/snackbar_helper.dart';
import 'package:flutter/foundation.dart';
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
    String paymentOption = 'split'; // 'split' = 50%+50%, 'full' = 100%

    // Premier dialog: choisir entre exécution immédiate ou planification + mode de paiement
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final halfAmount = (_quote.amount / 2).ceil();
          final totalAmount = _quote.amount.toInt();

          return AlertDialog(
            title: const Text('Accepter le devis'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Mode de paiement
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF0a543d).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payment,
                                color: const Color(0xFF0a543d), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Mode de paiement',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0a543d),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Option 50%
                        InkWell(
                          onTap: () =>
                              setDialogState(() => paymentOption = 'split'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: paymentOption == 'split'
                                  ? const Color(0xFF0a543d).withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'split',
                                  groupValue: paymentOption,
                                  onChanged: (v) =>
                                      setDialogState(() => paymentOption = v!),
                                  activeColor: const Color(0xFF0a543d),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payer 50% maintenant',
                                        style: TextStyle(
                                          fontWeight: paymentOption == 'split'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        '$halfAmount FCFA maintenant + $halfAmount FCFA après la 3ᵉ intervention',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Option 100%
                        InkWell(
                          onTap: () =>
                              setDialogState(() => paymentOption = 'full'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: paymentOption == 'full'
                                  ? const Color(0xFF0a543d).withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'full',
                                  groupValue: paymentOption,
                                  onChanged: (v) =>
                                      setDialogState(() => paymentOption = v!),
                                  activeColor: const Color(0xFF0a543d),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payer la totalité',
                                        style: TextStyle(
                                          fontWeight: paymentOption == 'full'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        '$totalAmount FCFA en une seule fois',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
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

                  const SizedBox(height: 20),

                  const Text(
                    'Comment souhaitez-vous procéder ?',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, 'immediate_$paymentOption'),
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
                      onPressed: () =>
                          Navigator.pop(context, 'schedule_$paymentOption'),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );

    if (choice == null) return;

    // Parser le choix (format: "action_paymentOption")
    final parts = choice.split('_');
    final action = parts[0];
    final selectedPaymentOption = parts.length > 1 ? parts[1] : 'split';

    if (action == 'immediate') {
      // Exécution immédiate
      await _processAcceptQuote(
          executeNow: true, paymentOption: selectedPaymentOption);
    } else {
      // Planification
      await _showScheduleDialog(paymentOption: selectedPaymentOption);
    }
  }

  Future<void> _showScheduleDialog({String paymentOption = 'split'}) async {
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
      paymentOption: paymentOption,
    );
  }

  Future<void> _processAcceptQuote({
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
    String paymentOption = 'split',
  }) async {
    setState(() => _isLoading = true);

    try {
      // Récupérer la réponse avec les infos de paiement
      final acceptResponse = await _apiService.acceptQuote(
        _quote.id,
        scheduledDate: scheduledDate,
        executeNow: executeNow,
        secondContact: secondContact,
        paymentOption: paymentOption,
      );

      // Extraire le montant du premier paiement (50%)
      double? firstPaymentAmount;
      if (acceptResponse['first_payment'] != null) {
        firstPaymentAmount =
            (acceptResponse['first_payment']['amount'] as num?)?.toDouble();
      }
      print('💰 Premier paiement (50%): $firstPaymentAmount FCFA');

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

        // Utiliser order_id retourné directement par acceptQuote (pas de race condition)
        Map<String, dynamic> recentOrder = {};
        final directOrderId = acceptResponse['order_id'];
        final directOrderRef = acceptResponse['order_reference'] as String?;

        if (directOrderId != null) {
          recentOrder = {
            'id': directOrderId,
            'reference': directOrderRef,
            'totalAmount': (acceptResponse['first_payment']
                as Map<String, dynamic>?)?['amount'],
          };
        } else {
          // Fallback: GET /orders si order_id absent de la réponse
          try {
            final ordersResponse = await _apiService.get('/orders');
            final orders = (ordersResponse['data'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final quoteIdInt = int.tryParse(_quote.id);
            recentOrder = orders.firstWhere(
              (order) {
                final orderQuoteId = order['quoteId'];
                return orderQuoteId == quoteIdInt ||
                    orderQuoteId.toString() == _quote.id;
              },
              orElse: () => <String, dynamic>{},
            );
          } catch (e) {
            if (kDebugMode)
              debugPrint('⚠️ Erreur récupération commande fallback: $e');
          }
        }

        if (recentOrder.isNotEmpty && recentOrder['id'] != null) {
          // Calculer le montant selon le mode de paiement choisi
          double amountToPay;
          int paymentStep = 1;

          if (paymentOption == 'full') {
            // Paiement intégral (100%)
            amountToPay = _quote.amount;
            paymentStep = 0; // 0 = paiement complet
            print(
                '💰 Paiement intégral: ${amountToPay.toStringAsFixed(0)} FCFA (100%)');
          } else if (firstPaymentAmount != null && firstPaymentAmount > 0) {
            amountToPay = firstPaymentAmount;
            paymentStep = 1;
            print(
                '💰 Paiement split (API): ${amountToPay.toStringAsFixed(0)} FCFA (50% - étape 1)');
          } else if (_quote.paymentType == 'split' &&
              _quote.firstPaymentAmount != null) {
            amountToPay = _quote.firstPaymentAmount!;
            paymentStep = 1;
            print(
                '💰 Paiement split (quote): ${amountToPay.toStringAsFixed(0)} FCFA (50% - étape 1)');
          } else {
            // Fallback: utiliser le montant de la commande directement
            // Note: totalAmount de la commande est DÉJÀ le montant 50% pour split payment
            final orderAmount = recentOrder['totalAmount'];
            if (orderAmount != null && orderAmount > 0) {
              amountToPay = (orderAmount as num).toDouble();
              print(
                  '💰 Paiement (order totalAmount): ${amountToPay.toStringAsFixed(0)} FCFA');
            } else {
              // Si pas de totalAmount, calculer 50% du total du devis
              amountToPay = (_quote.amount / 2).ceilToDouble();
              print(
                  '💰 Paiement (quote 50%): ${amountToPay.toStringAsFixed(0)} FCFA');
            }
            paymentStep = 1;
          }

          // Naviguer directement vers l'écran de paiement
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                invoiceId: recentOrder['id'].toString(),
                invoiceNumber: recentOrder['reference'] ?? 'N/A',
                amount: amountToPay,
                paymentStep: paymentStep,
              ),
            ),
          );
        } else {
          // Aucune commande trouvée (order_id absent et fallback GET /orders vide)
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
        // Déterminer le montant et l'étape de paiement (50%)
        double paymentAmount;
        int paymentStep = 1;

        if (_quote.paymentType == 'split' &&
            _quote.firstPaymentAmount != null) {
          if (_quote.firstPaymentStatus == 'paid') {
            // Premier paiement déjà fait, payer le second
            paymentAmount =
                _quote.secondPaymentAmount ?? _quote.firstPaymentAmount!;
            paymentStep = 2;
          } else {
            // Premier paiement à effectuer (50%)
            paymentAmount = _quote.firstPaymentAmount!;
            paymentStep = 1;
          }
        } else {
          // Paiement intégral (ancien système)
          paymentAmount = (order['totalAmount'] ?? _quote.amount).toDouble();
        }

        // Naviguer vers l'écran de paiement
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                invoiceId: order['id'].toString(),
                invoiceNumber: order['reference'] ?? 'N/A',
                amount: paymentAmount,
                paymentStep: paymentStep,
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
                            // Badge de statut en haut à droite
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Devis',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
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
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Référence sur sa propre ligne
                            SelectableText(
                              _quote.reference,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0a543d),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _quote.title,
                              style: const TextStyle(
                                fontSize: 16,
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

                    const SizedBox(height: 24),

                    // Explication des options de paiement pour les devis en attente
                    if (_quote.status == 'pending' || _quote.status == 'sent')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.blue.shade400, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Options de paiement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Option 1 - 50%
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.looks_one,
                                      color: Colors.blue.shade600, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payer 50% maintenant',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${(_quote.amount / 2).ceil()} FCFA à l\'acceptation + ${(_quote.amount / 2).ceil()} FCFA après la 3ᵉ intervention',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Option 2 - 100%
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.looks_two,
                                      color: Colors.green.shade600, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payer la totalité',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${_quote.amount.toInt()} FCFA en une seule fois',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Vous pourrez choisir votre option lors de l\'acceptation du devis.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

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
                                label: Text(
                                  _quote.paymentType == 'split' &&
                                          _quote.firstPaymentAmount != null
                                      ? (_quote.firstPaymentStatus == 'paid'
                                          ? 'Payer ${_quote.secondPaymentAmount?.toStringAsFixed(0) ?? _quote.firstPaymentAmount!.toStringAsFixed(0)} FCFA (50%)'
                                          : 'Payer ${_quote.firstPaymentAmount!.toStringAsFixed(0)} FCFA (50%)')
                                      : 'Payer maintenant',
                                  style: const TextStyle(fontSize: 16),
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

  Widget _buildPaymentRow(String label, double amount, String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Payé';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
