import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class QuotePaymentScreen extends StatefulWidget {
  final int quoteId;
  final double amount;
  final Map<String, dynamic> quote;

  const QuotePaymentScreen({
    Key? key,
    required this.quoteId,
    required this.amount,
    required this.quote,
  }) : super(key: key);

  @override
  State<QuotePaymentScreen> createState() => _QuotePaymentScreenState();
}

class _QuotePaymentScreenState extends State<QuotePaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  String? _error;
  String? _paymentUrl;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final response = await _apiService.post(
        '/payments/fineopay/initialize-quote',
        {'quoteId': widget.quoteId},
      );

      if (response['success'] == true && response['payment_url'] != null) {
        setState(() {
          _paymentUrl = response['payment_url'];
          _isProcessing = false;
        });
      } else {
        setState(() {
          _error = response['message'] ??
              'Erreur lors de l\'initialisation du paiement';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_paymentUrl == null) return;

    try {
      final uri = Uri.parse(_paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Attendre que l'utilisateur revienne et afficher un dialogue
        if (mounted) {
          await _showPaymentCompletionDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien de paiement'),
              backgroundColor: Colors.red,
            ),
          );
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
    }
  }

  Future<void> _showPaymentCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Paiement en cours'),
        content: const Text(
          'Avez-vous terminé le paiement ?\n\n'
          'Si le paiement a été effectué avec succès, cliquez sur "Terminé". '
          'Sinon, vous pouvez réessayer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context, false); // Retour à l'écran précédent
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context, true); // Retour avec succès
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminé'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement du Devis'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quote information card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du devis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Référence',
                      widget.quote['reference'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Intervention',
                      '#${widget.quote['intervention_id'] ?? 'N/A'}',
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Montant à payer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${widget.amount.toStringAsFixed(0)} FCFA',
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
            const SizedBox(height: 24),

            // Payment method card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Méthodes de paiement disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodItem(
                        'Orange Money', Icons.phone_android),
                    _buildPaymentMethodItem('MTN Money', Icons.phone_iphone),
                    _buildPaymentMethodItem('Moov Money', Icons.smartphone),
                    _buildPaymentMethodItem('Wave', Icons.waves),
                    _buildPaymentMethodItem(
                        'Carte bancaire', Icons.credit_card),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Information notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Après validation, vous serez redirigé vers la page de paiement sécurisée FineoPay.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            if (_isProcessing)
              const SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_paymentUrl != null)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.credit_card, size: 24),
                  label: const Text(
                    'Procéder au paiement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _initializePayment,
                  child: const Text('Réessayer'),
                ),
              ),

            const SizedBox(height: 8),

            // Cancel button
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
            ),
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

  Widget _buildPaymentMethodItem(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
}
