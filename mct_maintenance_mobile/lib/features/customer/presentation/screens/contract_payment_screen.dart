import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/contract_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/services/payment_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:mct_maintenance_mobile/services/deep_link_service.dart';

class ContractPaymentScreen extends StatefulWidget {
  final int subscriptionId;
  final String reference;
  final double amount;
  final String contractType;
  final String equipment;
  final String? model;
  final String? firstPaymentStatus;
  final String? secondPaymentStatus;
  final int? paymentPhase; // 1 = premier paiement, 2 = deuxième paiement
  final double? firstPaymentAmount;
  final double? secondPaymentAmount;
  final int? visitsTotal;
  final int? visitIntervalMonths;

  const ContractPaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.reference,
    required this.amount,
    required this.contractType,
    required this.equipment,
    this.model,
    this.firstPaymentStatus,
    this.secondPaymentStatus,
    this.paymentPhase,
    this.firstPaymentAmount,
    this.secondPaymentAmount,
    this.visitsTotal,
    this.visitIntervalMonths,
  });

  @override
  State<ContractPaymentScreen> createState() => _ContractPaymentScreenState();
}

class _ContractPaymentScreenState extends State<ContractPaymentScreen>
    with WidgetsBindingObserver {
  late final ContractRepository _contractRepository;
  late final PaymentService _paymentService;
  bool _isProcessing = false;

  // 'half' = payer 50%, 'full' = payer 100%
  String _selectedPaymentOption = 'half';

  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPolls = 60; // 5 minutes max (60 × 5s)
  String? _lastPaymentReference; // référence reçue via deep link

  // Phase effective de paiement (déduite du statut)
  int get _currentPaymentPhase {
    if (widget.paymentPhase != null) {
      return widget.paymentPhase!;
    }
    if (widget.firstPaymentStatus == 'paid' &&
        widget.secondPaymentStatus == 'paid') {
      return 0;
    }
    if (widget.firstPaymentStatus == null ||
        widget.firstPaymentStatus == 'pending') {
      return 1;
    }
    if (widget.firstPaymentStatus == 'paid' &&
        (widget.secondPaymentStatus == null ||
            widget.secondPaymentStatus == 'pending')) {
      return 2;
    }
    return 1;
  }

  double get _firstPaymentAmount =>
      widget.firstPaymentAmount ?? (widget.amount / 2).ceilToDouble();
  double get _secondPaymentAmount =>
      widget.secondPaymentAmount ?? (widget.amount / 2).floorToDouble();

  /// Montant à payer selon l'option sélectionnée
  double get _amountToPay {
    if (_currentPaymentPhase == 2) return _secondPaymentAmount;
    return _selectedPaymentOption == 'full'
        ? widget.amount
        : _firstPaymentAmount;
  }

  /// Phase effective à envoyer à l'API
  int get _effectivePhase {
    if (_currentPaymentPhase == 2) return 2;
    return _selectedPaymentOption == 'full' ? 0 : 1; // 0 = paiement complet
  }

  @override
  void initState() {
    super.initState();
    _contractRepository = context.read<ContractRepository>();
    _paymentService = context.read<PaymentService>();
    WidgetsBinding.instance.addObserver(this);
    DeepLinkService().paymentStream.listen(_onPaymentCallback);
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
    if (state == AppLifecycleState.resumed) {
      _checkPaymentStatus();
    }
  }

  void _onPaymentCallback(Map<String, String> data) {
    if (!mounted) {
      return;
    }
    final reference = data['reference'] ?? '';
    final syncRef = data['syncRef'] ?? '';
    final expectedSyncRef = 'SUBSCRIPTION_${widget.subscriptionId}';
    if (reference.isEmpty && syncRef.isEmpty) {
      return;
    }
    if (syncRef != expectedSyncRef &&
        !reference.contains('${widget.subscriptionId}')) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '💳 Deep link paiement reçu pour contrat #${widget.subscriptionId}: $data');
    }
    // Stocker la référence et vérifier immédiatement
    if (reference.isNotEmpty) {
      _lastPaymentReference = reference;
    }
    _checkPaymentStatus();
  }

  // ===================== PAIEMENT =====================

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 🎁 Gestion des paiements de contrat à 0 FCFA
      if (_amountToPay <= 0) {
        if (kDebugMode) {
          debugPrint(
              '🎁 Montant contrat = 0 FCFA pour souscription #${widget.subscriptionId} : Validation directe.');
        }
        final confirmation = await _contractRepository
            .verifySubscriptionPayment(widget.subscriptionId);
        final data = confirmation['data'];
        final isConfirmed = confirmation['success'] == true &&
            data is Map &&
            _isPaymentSuccess(data);
        if (!isConfirmed) {
          throw Exception(
              'Le serveur n\'a pas confirmé l\'activation gratuite du contrat.');
        }
        if (mounted) _showPaymentSuccess();
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💳 Initialisation paiement FineoPay pour contrat #${widget.subscriptionId} '
            '- ${_selectedPaymentOption == "full" ? "100%" : "50%"} '
            '- Montant: $_amountToPay FCFA');
      }

      final paymentData = await _paymentService.initializeSubscriptionPayment(
        widget.subscriptionId,
        _amountToPay,
        widget.reference,
        paymentPhase: _effectivePhase,
        redirectUrl: 'smartmaintenance://payment-callback',
        autoRedirect: false,
      );

      final paymentUrl =
          (paymentData['paymentUrl'] ?? paymentData['checkoutUrl']) as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Aucun lien de paiement reçu du serveur.');
      }

      if (kDebugMode) debugPrint('🔗 URL paiement: $paymentUrl');

      final Uri uri = Uri.parse(paymentUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (mounted) _startPaymentPolling();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ===================== POLLING =====================

  void _startPaymentPolling() {
    if (_pollingTimer != null) return;
    _pollCount = 0;

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

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _pollCount++;
      if (kDebugMode) {
        debugPrint(
            '🔍 Polling contrat #${widget.subscriptionId} ($_pollCount/$_maxPolls)');
      }

      if (_pollCount >= _maxPolls) {
        _stopPolling();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showTimeoutDialog();
        return;
      }

      await _checkPaymentStatus();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkPaymentManually(BuildContext dialogContext) async {
    try {
      final response = await _contractRepository.verifySubscriptionPayment(
          widget.subscriptionId,
          reference: _lastPaymentReference);
      final data = response['data'] ?? {};
      final isPaid = _isPaymentSuccess(data);

      if (isPaid) {
        _stopPolling();
        // Fermer le dialog de polling de façon sécurisée
        if (dialogContext.mounted) {
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

  Future<void> _checkPaymentStatus() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔍 Vérification statut paiement pour contrat #${widget.subscriptionId}');
      }

      final response = await _contractRepository.verifySubscriptionPayment(
          widget.subscriptionId,
          reference: _lastPaymentReference);

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final isPaid = _isPaymentSuccess(data);

        if (kDebugMode) {
          debugPrint('📊 payment_status: ${data["payment_status"]}, '
              'first_payment_status: ${data["first_payment_status"]}, '
              'second_payment_status: ${data["second_payment_status"]}, '
              'isPaid: $isPaid');
        }

        if (isPaid) {
          _stopPolling();
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // fermer le dialog de polling
          }
          _showPaymentSuccess();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur vérification statut: $e');
    }
  }

  /// Détermine si le paiement est un succès selon la phase en cours.
  bool _isPaymentSuccess(Map<dynamic, dynamic> data) {
    final paymentStatus =
        (data['payment_status'] ?? data['paymentStatus'])?.toString();
    final subscriptionStatus = data['status']?.toString();
    final firstPaymentStatus =
        (data['first_payment_status'] ?? data['firstPaymentStatus'])
            ?.toString();
    final secondPaymentStatus =
        (data['second_payment_status'] ?? data['secondPaymentStatus'])
            ?.toString();

    if (_currentPaymentPhase == 2) {
      // Solde (2ème paiement)
      return secondPaymentStatus == 'paid' || subscriptionStatus == 'completed';
    }

    // Premier paiement OU paiement 100% :
    //   - 'paid'    → paiement 100% ou contrat entièrement soldé
    //   - 'partial' → premier versement 50% confirmé
    //   - firstPaymentStatus == 'paid' → idem
    //   - status 'active' ou 'completed' → contrat activé
    return paymentStatus == 'paid' ||
        paymentStatus == 'partial' || // ← FIX: premier versement 50% validé
        firstPaymentStatus == 'paid' ||
        subscriptionStatus == 'active' ||
        subscriptionStatus == 'completed';
  }

  // ===================== DIALOGS =====================

  void _showPaymentSuccess() {
    if (!mounted) return;

    final isFullPayment = _selectedPaymentOption == 'full';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: Text(isFullPayment
            ? '🎉 Contrat activé !'
            : 'Premier paiement réussi !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFullPayment
                  ? 'Votre paiement intégral a été confirmé. Votre contrat de maintenance est maintenant actif.'
                  : 'Votre premier versement (50%) a été confirmé. Votre contrat est actif.',
              textAlign: TextAlign.center,
            ),
            if (!isFullPayment) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le deuxième versement (50%) sera demandé après la ${widget.visitsTotal != null ? "${widget.visitsTotal! ~/ 2 + 1}ème" : "3ème"} visite.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _closeScreenAfterDialog();
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

  Future<void> _closeScreenAfterDialog() async {
    await Future.microtask(() {});
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final allPaid = _currentPaymentPhase == 0;

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
              // Résumé du contrat
              _buildContractSummary(),
              const SizedBox(height: 24),

              // Sélecteur d'option de paiement (uniquement pour phase 1)
              if (_currentPaymentPhase == 1) ...[
                _buildPaymentOptionSelector(),
                const SizedBox(height: 16),
              ],

              // Information FineoPay
              _buildFineoPayInfo(),
              const SizedBox(height: 32),

              // Message si tout est payé
              if (allPaid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tous les paiements ont été effectués pour ce contrat.',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Bouton de paiement principal
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
                            'Payer ${_formatCurrency(_amountToPay)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _buildContractSummary() {
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
                    '${widget.equipment}${widget.model != null && widget.model!.isNotEmpty ? ' - ${widget.model}' : ''}',
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
            if (widget.visitsTotal != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_repeat,
                      size: 16, color: Color(0xFF047857)),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.visitsTotal} visites'
                    '${widget.visitIntervalMonths != null ? ' · tous les ${widget.visitIntervalMonths} mois' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _formatCurrency(widget.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Montant à payer maintenant
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF97316), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPaymentPhase == 2
                              ? '2ème paiement (50%)'
                              : (_selectedPaymentOption == 'full'
                                  ? 'Paiement intégral (100%)'
                                  : '1er paiement (50%)'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentPaymentPhase == 2
                              ? 'Solde restant'
                              : (_selectedPaymentOption == 'full'
                                  ? 'À la validation du contrat'
                                  : 'À la validation, solde après visites'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(_amountToPay),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez votre option de paiement :',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Option 50%
        _buildOptionTile(
          value: 'half',
          title: '50% maintenant',
          subtitle:
              '${_formatCurrency(_firstPaymentAmount)} à la validation — solde ${_formatCurrency(_secondPaymentAmount)} après les visites',
          icon: Icons.payment,
        ),
        const SizedBox(height: 10),
        // Option 100%
        _buildOptionTile(
          value: 'full',
          title: 'Paiement intégral (100%)',
          subtitle: '${_formatCurrency(widget.amount)} en une seule fois',
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.orange : Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.orange.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.orange : Colors.grey,
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
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paiement sécurisé avec FineoPay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Modes de paiement disponibles :',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
            Row(
              children: [
                Icon(Icons.credit_card, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Carte bancaire',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Visa, Mastercard',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
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
          Icon(Icons.security, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paiement 100% sécurisé. Vous serez redirigé vers la page FineoPay pour choisir votre mode de paiement.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
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
