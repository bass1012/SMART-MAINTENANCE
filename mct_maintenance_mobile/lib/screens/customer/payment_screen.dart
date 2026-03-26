import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/loading_indicator.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final double amount;
  final int paymentStep; // 1 = premier paiement 50%, 2 = second paiement 50%

  const PaymentScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    this.paymentStep = 1,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  late final PaymentService _paymentService;
  bool _isProcessing = false;
  bool _isWaitingForPayment = false;
  Timer? _pollingTimer;
  int? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(_apiService);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        _isWaitingForPayment &&
        _currentOrderId != null) {
      print(
          '📱 Application revenue au premier plan - Vérification du paiement...');
      _checkPaymentStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_tech_2.png'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé de la facture
                _buildInvoiceSummary(),
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
                            'Payer ${_formatCurrency(widget.amount)}',
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
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Card(
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
                  'Facture',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 21, 21, 21),
                  ),
                ),
                Text(
                  widget.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Afficher info 50% si c'est un paiement split
            if (widget.paymentStep == 1) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premier paiement (50%) - Le reste sera dû après les travaux',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.paymentStep == 2) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement final (50%) - Travaux terminés',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.paymentStep > 0
                      ? 'Montant à payer (50%)'
                      : 'Montant à payer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(widget.amount),
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
            const SizedBox(height: 12),
            // Logos Cartes Bancaires
            Row(
              children: [
                const SizedBox(width: 4),
                Image.asset('assets/images/logo_visa.png',
                    height: 35,
                    width: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 12),
                Image.asset('assets/images/MasterCard_Logo.png',
                    height: 35,
                    width: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 12),
                Image.asset('assets/images/logo_cb.jpg',
                    height: 35,
                    width: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
                Icons.credit_card, 'Carte bancaire', 'Visa, Mastercard'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      // Convertir invoiceId en int (c'est en fait un orderId)
      final orderId = int.parse(widget.invoiceId);
      _currentOrderId = orderId;

      print(
          '💳 Initialisation paiement FineoPay pour commande #$orderId (étape ${widget.paymentStep})');

      // Initialiser le paiement FineoPay
      final paymentData = await _paymentService.initializeOrderPayment(
        orderId,
        widget.amount,
        widget.invoiceNumber,
        paymentStep: widget.paymentStep,
      );
      final paymentUrl = paymentData['paymentUrl'] as String;

      print('✅ URL de paiement reçue: $paymentUrl');

      setState(() {
        _isWaitingForPayment = true;
        _isProcessing = false;
      });

      // Ouvrir le paiement dans un WebView intégré
      if (mounted) {
        final paymentResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              title: 'Paiement commande #${widget.invoiceNumber}',
              orderId: orderId,
            ),
          ),
        );

        // Gérer le résultat du paiement
        if (paymentResult == true) {
          // Paiement réussi - vérifier le statut
          _startPolling();
          await _checkPaymentStatus();
        } else {
          // Paiement annulé ou échoué
          _stopPolling();
          if (mounted) {
            setState(() {
              _isWaitingForPayment = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isWaitingForPayment = false;
        _currentOrderId = null;
      });

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

  void _startPolling() {
    print('🔄 Démarrage du polling pour vérifier le paiement...');

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isWaitingForPayment || _currentOrderId == null) {
        timer.cancel();
        return;
      }
      _checkPaymentStatus();
    });
  }

  void _stopPolling() {
    print('⏹️ Arrêt du polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    setState(() {
      _isWaitingForPayment = false;
      _currentOrderId = null;
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null) return;

    try {
      print(
          '🔍 Vérification ACTIVE du statut de paiement pour commande #$_currentOrderId');

      // Utiliser le nouvel endpoint qui vérifie directement auprès de FineoPay
      final response =
          await _apiService.get('/fineopay/verify-payment/$_currentOrderId');

      if (response['success'] == true) {
        final order = response['data'];
        final paymentStatus = order['paymentStatus']; // Noter: camelCase

        print('📊 Statut du paiement: $paymentStatus');

        if (paymentStatus == 'paid') {
          // Paiement réussi !
          _stopPolling();

          if (mounted) {
            // Afficher un message de succès
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                title: const Text('Paiement réussi !'),
                content: const Text(
                  'Votre paiement a été confirmé avec succès.\n\n'
                  'Vous pouvez suivre l\'évolution de votre commande dans vos commandes.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      // Fermer le dialog et retourner à l'écran précédent
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(true); // Retourner avec résultat
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a543d),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else if (paymentStatus == 'failed') {
          // Paiement échoué
          _stopPolling();

          if (mounted) {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                icon: const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 64,
                ),
                title: const Text('Paiement échoué'),
                content: const Text(
                  'Le paiement n\'a pas pu être traité.\n\n'
                  'Veuillez réessayer.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Fermer le dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Erreur vérification statut: $e');
    }
  }

  void _showCashPaymentInfo() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.store,
          color: Color(0xFF0a543d),
          size: 64,
        ),
        title: const Text('Paiement en espèces'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vous pouvez effectuer le paiement en espèces dans l\'une de nos agences :',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Adresses
              const Text(
                '📍 Nos adresses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddressCard('Siège', 'Marcory Zone 4\nRue du canal'),
              const SizedBox(height: 8),
              _buildAddressCard('Showroom', 'Vallon'),
              const SizedBox(height: 8),
              _buildAddressCard('Showroom', 'Faya'),

              const SizedBox(height: 16),
              const Divider(),
              _buildCashInfoRow(
                  '🕐 Horaires', 'Lun-Ven: 8h-17h30\nSam: 9h-13h'),
              const Divider(),
              _buildCashInfoRow('📋 Référence', widget.invoiceNumber),
              const Divider(),
              _buildCashInfoRow('💰 Montant', _formatCurrency(widget.amount)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Veuillez mentionner la référence lors du paiement.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Fermer le dialog
              Navigator.pop(parentContext); // Retourner à l'écran précédent
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                  content: Text(
                      'N\'oubliez pas de mentionner la référence de votre commande'),
                  backgroundColor: Color(0xFF0a543d),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String label, String address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0a543d).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0a543d),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
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
