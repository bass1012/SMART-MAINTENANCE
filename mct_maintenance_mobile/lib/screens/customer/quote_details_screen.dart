import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/button_loading_indicator.dart';
import 'quote_payment_screen.dart';

class QuoteDetailsScreen extends StatefulWidget {
  final int quoteId;

  const QuoteDetailsScreen({
    Key? key,
    required this.quoteId,
  }) : super(key: key);

  @override
  State<QuoteDetailsScreen> createState() => _QuoteDetailsScreenState();
}

class _QuoteDetailsScreenState extends State<QuoteDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _quote;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuoteDetails();
  }

  Future<void> _loadQuoteDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _apiService.get('/quotes/${widget.quoteId}/details');
      setState(() {
        _quote = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      await _processAcceptQuote(executeNow: true);
    } else {
      await _showScheduleDialog();
    }
  }

  Future<void> _showScheduleDialog() async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

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
                  'Choisissez la date et l\'heure :',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
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
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

    await _processAcceptQuote(scheduledDate: scheduledDateTime);
  }

  Future<void> _processAcceptQuote({
    DateTime? scheduledDate,
    bool executeNow = false,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final body = <String, dynamic>{
        'execute_now': executeNow,
      };
      if (scheduledDate != null) {
        body['scheduled_date'] = scheduledDate.toIso8601String();
      }

      final response = await _apiService.post(
        '/quotes/${widget.quoteId}/accept',
        body,
      );

      if (response['payment_required'] == true) {
        // Rediriger vers l'écran de paiement
        if (mounted) {
          final paid = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => QuotePaymentScreen(
                quoteId: widget.quoteId,
                amount: response['amount'],
                quote: response['quote'],
              ),
            ),
          );

          if (paid == true) {
            // Paiement réussi, retourner à l'écran précédent
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            // Recharger les détails du devis
            _loadQuoteDetails();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Devis accepté'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectQuote() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez indiquer le motif du refus :'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Ex: Le prix est trop élevé...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif du refus est obligatoire'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _apiService.post(
        '/quotes/${widget.quoteId}/reject',
        {
          'rejection_reason': reasonController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Devis rejeté'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return 'Envoyé';
      case 'accepted':
        return 'Accepté';
      case 'rejected':
        return 'Rejeté';
      case 'expired':
        return 'Expiré';
      case 'draft':
        return 'Brouillon';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Devis'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuoteDetails,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _quote == null
                  ? const Center(child: Text('Devis non trouvé'))
                  : RefreshIndicator(
                      onRefresh: _loadQuoteDetails,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header card
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _quote!['reference'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          _getStatusLabel(_quote!['status']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            _getStatusColor(_quote!['status']),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    'Date d\'émission',
                                    _quote!['issueDate'] ?? 'N/A',
                                  ),
                                  _buildInfoRow(
                                    'Date d\'expiration',
                                    _quote!['expiryDate'] ?? 'N/A',
                                  ),
                                  if (_quote!['intervention'] != null)
                                    _buildInfoRow(
                                      'Intervention',
                                      '#${_quote!['intervention']['id']}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Line items
                          if (_quote!['line_items'] != null &&
                              (_quote!['line_items'] as List).isNotEmpty) ...[
                            const Text(
                              'Détails du devis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    (_quote!['line_items'] as List).length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final item =
                                      (_quote!['line_items'] as List)[index];
                                  return ListTile(
                                    title: Text(item['description'] ?? ''),
                                    subtitle: Text(
                                      'Qté: ${item['quantity']} × ${(item['unit_price'] ?? 0).toStringAsFixed(0)} FCFA',
                                    ),
                                    trailing: Text(
                                      '${(item['total'] ?? 0).toStringAsFixed(0)} FCFA',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Pricing summary
                          Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildPriceRow(
                                    'Sous-total',
                                    _quote!['subtotal'] ?? 0,
                                  ),
                                  if ((_quote!['taxAmount'] ?? 0) > 0)
                                    _buildPriceRow(
                                      'TVA',
                                      _quote!['taxAmount'] ?? 0,
                                    ),
                                  if ((_quote!['discountAmount'] ?? 0) > 0)
                                    _buildPriceRow(
                                      'Remise',
                                      -(_quote!['discountAmount'] ?? 0),
                                      color: Colors.green,
                                    ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${(_quote!['total'] ?? 0).toStringAsFixed(0)} FCFA',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          if (_quote!['notes'] != null &&
                              _quote!['notes'].toString().isNotEmpty) ...[
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(_quote!['notes']),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Terms and conditions
                          if (_quote!['termsAndConditions'] != null &&
                              _quote!['termsAndConditions']
                                  .toString()
                                  .isNotEmpty) ...[
                            const Text(
                              'Conditions générales',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _quote!['termsAndConditions'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Payment status
                          if (_quote!['payment_status'] != null) ...[
                            Card(
                              color: _quote!['payment_status'] == 'paid'
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _quote!['payment_status'] == 'paid'
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: _quote!['payment_status'] == 'paid'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _quote!['payment_status'] == 'paid'
                                          ? 'Paiement effectué'
                                          : 'En attente de paiement',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Action buttons (only if status is 'sent')
                          if (_quote!['status'] == 'sent') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isProcessing ? null : _rejectQuote,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: _isProcessing
                                          ? const ButtonLoadingIndicator()
                                          : const Text('Refuser'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isProcessing ? null : _acceptQuote,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: _isProcessing
                                          ? const ButtonLoadingIndicator()
                                          : const Text('Accepter et Payer'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Rejected reason
                          if (_quote!['status'] == 'rejected' &&
                              _quote!['rejection_reason'] != null) ...[
                            Card(
                              color: Colors.red[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Motif du refus',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(_quote!['rejection_reason']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
