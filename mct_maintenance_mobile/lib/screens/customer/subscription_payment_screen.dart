import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import 'payment_webview_screen.dart';
import 'new_intervention_screen.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final int subscriptionId;
  final String subscriptionName;
  final double amount;
  final int? offerId;

  const SubscriptionPaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
    this.offerId,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  bool _isPolling = false;
  int _pollCount = 0;
  static const int _maxPolls = 60; // 5 minutes max (60 x 5s)
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (mounted) setState(() => _isPolling = false);
  }

  void _startPaymentPolling() {
    if (_pollTimer != null) return; // déjà en cours
    setState(() {
      _isPolling = true;
      _pollCount = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 4,
          ),
        ),
        title: const Text('Vérification en cours...'),
        content: const Text(
          'Complétez le paiement sur FineoPay.\n\n'
          'L\'application vérifie automatiquement votre paiement.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopPolling();
              Navigator.pop(dialogContext);
              Navigator.pop(context, false);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _checkPaymentManually(dialogContext),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Vérifier maintenant'),
          ),
        ],
      ),
    );

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _pollCount++;
      if (kDebugMode)
        debugPrint(
            '🔍 Polling souscription #${widget.subscriptionId} ($_pollCount/$_maxPolls)');

      if (_pollCount >= _maxPolls) {
        _stopPolling();
        if (mounted && Navigator.of(context).canPop())
          Navigator.of(context).pop();
        _showTimeoutDialog();
        return;
      }

      try {
        final response = await _apiService.get(
          '/fineopay/verify-subscription-payment/${widget.subscriptionId}',
        );
        final paymentStatus = response['data']?['payment_status'];
        if (kDebugMode) debugPrint('📊 Statut: $paymentStatus');

        if (paymentStatus == 'paid') {
          _stopPolling();
          if (mounted && Navigator.of(context).canPop())
            Navigator.of(context).pop();
          _showPaymentSuccess();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Erreur polling: $e');
      }
    });
  }

  Future<void> _checkPaymentManually(BuildContext dialogContext) async {
    try {
      final response = await _apiService.get(
        '/fineopay/verify-subscription-payment/${widget.subscriptionId}',
      );
      final paymentStatus = response['data']?['payment_status'];

      if (paymentStatus == 'paid') {
        _stopPolling();
        if (mounted && Navigator.of(dialogContext).canPop())
          Navigator.pop(dialogContext);
        _showPaymentSuccess();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Paiement pas encore reçu. Réessayez dans quelques instants.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Vérifier le statut du paiement après le WebView
  Future<void> _checkPaymentStatus() async {
    if (!mounted) return;

    // Attendre un court délai pour laisser le webhook FineoPay se traiter
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await _apiService.get(
        '/fineopay/verify-subscription-payment/${widget.subscriptionId}',
      );

      final paymentStatus = response['data']?['payment_status'];
      if (kDebugMode)
        debugPrint('📊 Vérification statut paiement: $paymentStatus');

      if (paymentStatus == 'paid') {
        _showPaymentSuccess();
      } else {
        // Paiement pas encore confirmé - démarrer le polling
        if (mounted) {
          _startPaymentPolling();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur vérification paiement: $e');
      // En cas d'erreur, démarrer le polling quand même
      if (mounted) {
        _startPaymentPolling();
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
        content: Text(
          'Votre souscription "${widget.subscriptionName}" a été activée avec succès !\n\n'
          'Vous pouvez maintenant créer votre première demande de maintenance.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, true);
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Fermer l'écran de paiement et rediriger vers la création d'intervention
              Navigator.pushReplacement(
                this.context,
                MaterialPageRoute(
                  builder: (context) => NewInterventionScreen(
                    preSelectedType: 'Maintenance',
                    preSelectedOfferId: widget.offerId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Créer une maintenance'),
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
        icon: const Icon(Icons.timer_off, color: Colors.orange, size: 64),
        title: const Text('Vérification terminée'),
        content: const Text(
          'Le paiement n\'a pas été détecté.\n\n'
          'Si vous avez payé, il sera traité automatiquement sous peu.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, false);
            },
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkPaymentManually(this.context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Vérifier encore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Souscription'),
        backgroundColor: const Color(0xFFEEBD1B),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_tech_2.png'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la souscription
              _buildSubscriptionSummary(),
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
    );
  }

  Widget _buildSubscriptionSummary() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Souscription',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 17, 15, 15),
                  ),
                ),
                Flexible(
                  child: Text(
                    widget.subscriptionName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
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
                  _formatCurrency(widget.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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
                const Icon(
                  Icons.payment,
                  color: Colors.orange,
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
            // Logos Mobile Money
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
      if (kDebugMode)
        debugPrint(
            '💳 Initialisation paiement FineoPay pour souscription #${widget.subscriptionId}');

      // Envoyer les données avec le provider FineoPay
      final paymentData = {
        'subscriptionId': widget.subscriptionId,
        'amount': widget.amount,
        'provider': 'fineopay', // Utiliser FineoPay
      };

      final response =
          await _apiService.processSubscriptionPayment(paymentData);

      if (mounted) {
        // Vérifier si on a un lien de paiement FineoPay
        final checkoutUrl = response['data']?['checkoutUrl'];

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          if (kDebugMode)
            debugPrint('🔗 Ouverture du paiement WebView: $checkoutUrl');

          // Ouvrir le paiement dans un WebView intégré
          final paymentResult = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                paymentUrl: checkoutUrl,
                title: 'Paiement ${widget.subscriptionName}',
                subscriptionId: widget.subscriptionId,
              ),
            ),
          );

          // Gérer le résultat du paiement - toujours vérifier via polling
          // car le webhook FineoPay peut n'être pas encore traité
          if (mounted) {
            if (paymentResult == true) {
              // WebView a détecté le succès - vérifier directement
              await _checkPaymentStatus();
            } else {
              // Paiement peut-être complété - démarrer le polling pour vérifier
              _startPaymentPolling();
            }
          }
        } else {
          throw Exception(
              'Aucun lien de paiement reçu du serveur. Veuillez réessayer.');
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

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }
}
