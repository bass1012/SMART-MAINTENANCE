import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/loading_indicator.dart';
import 'payment_webview_screen.dart';

class DiagnosticPaymentScreen extends StatefulWidget {
  final int interventionId;
  final double diagnosticFee;

  const DiagnosticPaymentScreen({
    super.key,
    required this.interventionId,
    required this.diagnosticFee,
  });

  @override
  State<DiagnosticPaymentScreen> createState() =>
      _DiagnosticPaymentScreenState();
}

class _DiagnosticPaymentScreenState extends State<DiagnosticPaymentScreen> {
  final ApiService _apiService = ApiService();
  late final PaymentService _paymentService;
  bool _isProcessing = false;
  bool _isPolling = false;
  int _pollCount = 0;
  final int _maxPolls = 24; // 24 * 5 sec = 2 minutes

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(_apiService);
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information sur le diagnostic
            _buildDiagnosticInfo(),
            const SizedBox(height: 24),

            // Information importante
            _buildImportantNote(),
            const SizedBox(height: 24),

            // Information sur FineoPay
            _buildFineoPayInfo(),
            const SizedBox(height: 32),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.credit_card),
                label: _isProcessing
                    ? SizedBox(
                        height: 20,
                        child: ButtonLoadingIndicator(
                          color: Colors.white,
                          size: 6.0,
                        ),
                      )
                    : Text(
                        'Payer ${_formatCurrency(widget.diagnosticFee)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Note de sécurité
            _buildSecurityNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfo() {
    return Card(
      elevation: 2,
      color: const Color(0xFF0a543d).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Intervention',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '#${widget.interventionId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Frais de diagnostic',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant à payer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(widget.diagnosticFee),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0a543d),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frais de diagnostic obligatoires',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les frais de diagnostic sont obligatoires pour tous les clients. Le technicien pourra intervenir après confirmation du paiement.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFineoPayInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: const Color(0xFF0a543d),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Paiement sécurisé avec FineoPay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Modes de paiement disponibles :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Logos Mobile Money et Portefeuilles
            Row(
              children: [
                const SizedBox(width: 4),
                Image.asset('assets/images/orange_money.png',
                    height: 40,
                    width: 40,
                    errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 12),
                Image.asset('assets/images/mtn_money.png',
                    height: 40,
                    width: 40,
                    errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 12),
                Image.asset('assets/images/moov_money.png',
                    height: 40,
                    width: 40,
                    errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 12),
                Image.asset('assets/images/wave.png',
                    height: 40,
                    width: 40,
                    errorBuilder: (c, e, s) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '• Cartes bancaires (Visa, Mastercard)\n'
              '• Portefeuilles électroniques (Wave)\n'
              '• Mobile Money (Orange, MTN, Moov)',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paiement 100% sécurisé. Vous serez redirigé vers la page FineoPay pour choisir votre mode de paiement.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      print(
          '💳 Initialisation paiement diagnostic pour intervention #${widget.interventionId}');

      // Initialiser le paiement FineoPay
      final paymentData = await _paymentService
          .initializeDiagnosticPayment(widget.interventionId);
      final paymentUrl = paymentData['payment_url'] as String;

      print('✅ URL de paiement reçue: $paymentUrl');

      // Ouvrir le paiement dans un WebView intégré
      if (mounted) {
        final paymentResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              title: 'Paiement diagnostic #${widget.interventionId}',
            ),
          ),
        );

        if (paymentResult == true) {
          // Paiement réussi - vérifier le statut
          _showPaymentVerificationDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            title: const Text('Erreur de paiement'),
            content: Text(
              'Une erreur est survenue lors de l\'initialisation du paiement.\n\n$e',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentVerificationDialog() {
    _isPolling = true;
    _pollCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Démarrer le polling
          if (_isPolling && _pollCount == 0) {
            _pollPaymentStatus(dialogContext, setDialogState);
          }

          return AlertDialog(
            icon: const Icon(
              Icons.hourglass_top,
              color: Colors.orange,
              size: 64,
            ),
            title: const Text('Vérification en cours...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nous vérifions automatiquement votre paiement.\n\n'
                  'Complétez le paiement sur FineoPay, la confirmation sera automatique.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _pollCount / _maxPolls,
                  backgroundColor: Colors.grey.shade300,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérification ${_pollCount}/$_maxPolls',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _isPolling = false;
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, false);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _checkPaymentManually(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Vérifier maintenant'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pollPaymentStatus(
      BuildContext dialogContext, StateSetter setDialogState) async {
    while (_isPolling && _pollCount < _maxPolls && mounted) {
      await Future.delayed(const Duration(seconds: 5));

      if (!_isPolling || !mounted) break;

      _pollCount++;
      setDialogState(() {});
      print(
          '🔍 Polling paiement diagnostic #${widget.interventionId} (${_pollCount}/$_maxPolls)');

      try {
        final response = await _apiService.get(
          '/fineopay/verify-diagnostic-payment/${widget.interventionId}',
        );

        final diagnosticPaid = response['data']?['diagnostic_paid'] == true;
        print('📊 Statut diagnostic_paid: $diagnosticPaid');

        if (diagnosticPaid) {
          _isPolling = false;
          if (mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.pop(dialogContext);
          }
          _showPaymentSuccess();
          return;
        }
      } catch (e) {
        print('❌ Erreur polling: $e');
      }
    }

    // Temps écoulé
    if (_pollCount >= _maxPolls && mounted) {
      _isPolling = false;
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.pop(dialogContext);
      }
      _showTimeoutDialog();
    }
  }

  Future<void> _checkPaymentManually(BuildContext dialogContext) async {
    try {
      final response = await _apiService.get(
        '/fineopay/verify-diagnostic-payment/${widget.interventionId}',
      );

      final diagnosticPaid = response['data']?['diagnostic_paid'] == true;

      if (diagnosticPaid) {
        _isPolling = false;
        if (mounted && Navigator.of(dialogContext).canPop()) {
          Navigator.pop(dialogContext);
        }
        _showPaymentSuccess();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Paiement pas encore reçu. Réessayez dans quelques instants.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentSuccess() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Paiement confirmé !'),
        content: const Text(
          'Le diagnostic de votre intervention a été payé avec succès !\n\n'
          'Un technicien sera assigné sous peu.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, true); // Retourner avec succès
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.access_time, color: Colors.orange, size: 64),
        title: const Text('Vérification expirée'),
        content: const Text(
          'Le délai de vérification automatique est écoulé.\n\n'
          'Si vous avez effectué le paiement, il sera traité automatiquement '
          'et vous recevrez une notification.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }
}
