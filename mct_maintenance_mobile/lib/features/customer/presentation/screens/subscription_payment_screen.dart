import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/payment_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/services/deep_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final int subscriptionId;
  final String subscriptionName;
  final double amount;
  final int? offerId;
  final String? paymentOption; // 'split' (50%) ou 'full' (100%)

  const SubscriptionPaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
    this.offerId,
    this.paymentOption,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  late final PaymentRepository _paymentRepository;
  bool _isProcessing = false;
  bool _isReferralEligible = false;
  String? _lastPaymentReference; // référence reçue via deep link

  double get _effectiveAmount =>
      _isReferralEligible ? widget.amount * 0.5 : widget.amount;

  int _pollCount = 0;
  static const int _maxPolls = 60; // 5 minutes max (60 x 5s)
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _paymentRepository = context.read<PaymentRepository>();
    // Écouter le deep link pour capturer la référence FineoPay dès que disponible
    DeepLinkService().paymentStream.listen(_onDeepLink);
    _checkReferralDiscount();
  }

  Future<void> _checkReferralDiscount() async {
    try {
      final subRepo = context.read<SubscriptionRepository>();
      final rewardData = await subRepo.getReferralReward();
      if (mounted &&
          rewardData['success'] == true &&
          rewardData['eligible'] == true) {
        setState(() {
          _isReferralEligible = true;
        });
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('⚠️ Erreur vérification réduction parrainage: $e');
    }
  }

  void _onDeepLink(Map<String, String> data) {
    if (!mounted) {
      return;
    }
    final syncRef = data['syncRef'] ?? '';
    final expectedSyncRef = 'SUBSCRIPTION_${widget.subscriptionId}';
    if (syncRef != expectedSyncRef) {
      return;
    }
    final ref = data['reference'] ?? '';
    if (ref.isEmpty) {
      return;
    }
    if (kDebugMode) debugPrint('🔗 Deep link capturé: reference=$ref');
    _lastPaymentReference = ref;
    // Vérification immédiate dès réception du deep link
    _checkWithReference(ref);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startPaymentPolling() {
    if (_pollTimer != null) return; // déjà en cours
    setState(() {
      _pollCount = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFFEA580C),
                  strokeWidth: 3,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFEA580C),
                size: 24,
              ),
            ],
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
      if (kDebugMode) {
        debugPrint(
            '🔍 Polling souscription #${widget.subscriptionId} ($_pollCount/$_maxPolls)');
      }

      if (_pollCount >= _maxPolls) {
        _stopPolling();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showTimeoutDialog();
        return;
      }

      try {
        final response = await _paymentRepository.verifySubscriptionPayment(
          widget.subscriptionId,
          reference: _lastPaymentReference,
        );
        final data = response['data'] ?? {};
        final paymentStatus =
            data['payment_status'] ?? data['paymentStatus'] ?? data['status'];
        final firstPaymentStatus =
            data['first_payment_status'] ?? data['firstPaymentStatus'];
        final secondPaymentStatus =
            data['second_payment_status'] ?? data['secondPaymentStatus'];

        bool isPaid = false;
        if (firstPaymentStatus == 'paid' && secondPaymentStatus != 'paid') {
          // Solde (2ème paiement)
          isPaid = secondPaymentStatus == 'paid' || paymentStatus == 'paid';
        } else {
          // Premier paiement
          isPaid = paymentStatus == 'paid' ||
              paymentStatus == 'partial' ||
              firstPaymentStatus == 'paid' ||
              data['status'] == 'active' ||
              data['status'] == 'completed';
        }

        if (kDebugMode)
          debugPrint(
              '📊 Statut: $paymentStatus, 1er: $firstPaymentStatus, 2ème: $secondPaymentStatus, isPaid: $isPaid');

        if (isPaid) {
          _stopPolling();
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          _showPaymentSuccess();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Erreur polling: $e');
      }
    });
  }

  Future<void> _checkPaymentManually(BuildContext dialogContext) async {
    try {
      final response = await _paymentRepository.verifySubscriptionPayment(
        widget.subscriptionId,
        reference: _lastPaymentReference,
      );
      final data = response['data'] ?? {};
      final paymentStatus =
          data['payment_status'] ?? data['paymentStatus'] ?? data['status'];
      final firstPaymentStatus =
          data['first_payment_status'] ?? data['firstPaymentStatus'];
      final secondPaymentStatus =
          data['second_payment_status'] ?? data['secondPaymentStatus'];

      bool isPaid = false;
      if (firstPaymentStatus == 'paid' && secondPaymentStatus != 'paid') {
        // Solde (2ème paiement)
        isPaid = secondPaymentStatus == 'paid' || paymentStatus == 'paid';
      } else {
        // Premier paiement
        isPaid = paymentStatus == 'paid' ||
            paymentStatus == 'partial' ||
            firstPaymentStatus == 'paid' ||
            data['status'] == 'active' ||
            data['status'] == 'completed';
      }

      if (isPaid) {
        _stopPolling();
        if (mounted && Navigator.of(dialogContext).canPop()) {
          Navigator.pop(dialogContext);
        }
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

  /// Vérification immédiate avec une référence connue (depuis deep link).
  Future<void> _checkWithReference(String reference) async {
    try {
      final response = await _paymentRepository.verifySubscriptionPayment(
        widget.subscriptionId,
        reference: reference,
      );
      final data = response['data'] ?? {};
      final paymentStatus =
          data['payment_status'] ?? data['paymentStatus'] ?? data['status'];
      final firstPaymentStatus =
          data['first_payment_status'] ?? data['firstPaymentStatus'];
      final isPaid = paymentStatus == 'paid' ||
          paymentStatus == 'partial' ||
          firstPaymentStatus == 'paid' ||
          data['status'] == 'active' ||
          data['status'] == 'completed';

      if (kDebugMode)
        debugPrint(
            '⚡ Vérification directe: $paymentStatus / $firstPaymentStatus → isPaid=$isPaid');

      if (isPaid && mounted) {
        _stopPolling();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showPaymentSuccess();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur vérification directe: $e');
    }
  }

  void _showPaymentSuccess() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 40,
          ),
        ),
        title: const Text(
          'Paiement confirmé !',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Votre souscription "${widget.subscriptionName}" a été activée avec succès !\n\n'
          'Votre première demande de maintenance a été programmée, vous serez notifié le jour de l\'intervention.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(this.context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Résumé de la souscription
                          _buildSubscriptionSummary(),
                          const SizedBox(height: 16),

                          // Information sur FineoPay
                          _buildFineoPayInfo(),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          // Bouton de paiement
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                      'Payer ${_formatCurrency(_effectiveAmount)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Note de sécurité
                          _buildSecurityNote(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSummary() {
    final isSplit = widget.paymentOption == 'split';

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    widget.subscriptionName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            if (_isReferralEligible) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFFD97706), size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Réduction Parrainage (-50%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'Bravo ! Vos parrainages vous offrent 50% de réduction sur cette 3ème demande d\'intervention.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.paymentOption != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFF97316), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSplit
                                ? 'Acompte (50% à la commande)'
                                : 'Paiement intégral (100%)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSplit
                                ? 'Le solde (50%) sera demandé après les travaux'
                                : 'Règlement de la totalité en une seule fois',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSplit ? '50%' : '100%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSplit ? 'Montant à payer (50%)' : 'Montant à payer',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isReferralEligible) ...[
                      Text(
                        _formatCurrency(widget.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    Text(
                      _formatCurrency(_effectiveAmount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isReferralEligible
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFEA580C),
                      ),
                    ),
                  ],
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
      // 🎁 Gestion des souscriptions à 0 FCFA (Offres incluses, gratuités ou réductions à 100%)
      if (_effectiveAmount <= 0) {
        if (kDebugMode) {
          debugPrint(
              '🎁 Montant = 0 FCFA pour souscription #${widget.subscriptionId} : Validation directe sans passerelle.');
        }
        final confirmation = await _paymentRepository
            .verifySubscriptionPayment(widget.subscriptionId);
        final data = confirmation['data'];
        final isConfirmed = confirmation['success'] == true &&
            data is Map &&
            (data['payment_status'] == 'paid' ||
                data['first_payment_status'] == 'paid') &&
            (data['status'] == 'active' || data['status'] == 'completed');
        if (!isConfirmed) {
          throw Exception(
              'Le serveur n\'a pas confirmé l\'activation gratuite de la souscription.');
        }
        if (mounted) _showPaymentSuccess();
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💳 Initialisation paiement FineoPay pour souscription #${widget.subscriptionId}');
      }

      final response = await _paymentRepository.initializeSubscriptionPayment(
        subscriptionId: widget.subscriptionId,
        amount: _effectiveAmount,
        reference: 'SUB-${widget.subscriptionId}',
        redirectUrl: 'smartmaintenance://payment-callback',
        autoRedirect: false,
      );

      if (mounted) {
        // Le repository retourne déjà decoded['data'] — lire directement la clé FineoPay
        final paymentUrl =
            (response['paymentUrl'] ?? response['checkoutUrl']) as String?;

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                '🔗 Ouverture du paiement dans le navigateur externe: $paymentUrl');
          }

          // Ouvrir le paiement dans le navigateur externe
          final Uri uri = Uri.parse(paymentUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Lancer directement le polling pour vérifier le statut du paiement
          if (mounted) {
            _startPaymentPolling();
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
