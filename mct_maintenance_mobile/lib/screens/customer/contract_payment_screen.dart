import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../utils/snackbar_helper.dart';
import 'payment_webview_screen.dart';

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
  });

  @override
  State<ContractPaymentScreen> createState() => _ContractPaymentScreenState();
}

class _ContractPaymentScreenState extends State<ContractPaymentScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  late final PaymentService _paymentService;
  bool _isProcessing = false;
  bool _isWaitingForPayment = false;
  Timer? _pollingTimer;

  // Calcul du montant pour 50% (premier ou deuxième paiement)
  double get _firstPaymentAmount => (widget.amount / 2).ceilToDouble();
  double get _secondPaymentAmount => (widget.amount / 2).floorToDouble();

  // Détermine la phase de paiement actuelle
  int get _currentPaymentPhase {
    if (widget.paymentPhase != null) return widget.paymentPhase!;
    // Par défaut, si premier paiement pas fait, c'est phase 1
    if (widget.firstPaymentStatus == null ||
        widget.firstPaymentStatus == 'pending') {
      return 1;
    }
    // Si premier paiement fait mais pas le deuxième, c'est phase 2
    if (widget.firstPaymentStatus == 'paid' &&
        (widget.secondPaymentStatus == null ||
            widget.secondPaymentStatus == 'pending')) {
      return 2;
    }
    return 1;
  }

  // Montant à payer pour la phase actuelle
  double get _amountToPay {
    return _currentPaymentPhase == 1
        ? _firstPaymentAmount
        : _secondPaymentAmount;
  }

  // Titre du paiement actuel
  String get _paymentTitle {
    return _currentPaymentPhase == 1
        ? '1er paiement (50%)'
        : '2ème paiement (50%)';
  }

  // Description du paiement
  String get _paymentDescription {
    return _currentPaymentPhase == 1
        ? 'À la validation du contrat'
        : 'Après la 3ème visite';
  }

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

    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      print(
          '📱 Application revenue au premier plan - Vérification du paiement...');
      _checkPaymentStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement du contrat'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_tech_2.png'),
                fit: BoxFit.cover,
                opacity: 0.2,
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

                  // Information sur les modes de paiement
                  _buildPaymentInfo(),
                  const SizedBox(height: 32),

                  // Bouton paiement FineoPay
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

                  const SizedBox(height: 12),

                  // Bouton paiement en espèces
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _showCashPaymentInfo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0a543d),
                        side: const BorderSide(
                            color: Color(0xFF0a543d), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.money),
                      label: const Text(
                        'Payer en espèces',
                        style: TextStyle(
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
          // Loading overlay
          if (_isWaitingForPayment)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF0a543d),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vérification du paiement en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Veuillez patienter',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractSummary() {
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
                  'Contrat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Text(
                  widget.reference,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_month,
                    size: 20, color: Color(0xFF0a543d)),
                const SizedBox(width: 8),
                Text(
                  _formatContractType(widget.contractType),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.ac_unit, size: 20, color: Color(0xFF0a543d)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.equipment.isNotEmpty
                        ? '${widget.equipment}${widget.model != null && widget.model!.isNotEmpty ? ' - ${widget.model}' : ''}'
                        : 'Climatiseur${widget.model != null && widget.model!.isNotEmpty ? ' - ${widget.model}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_repeat,
                    size: 20, color: Color(0xFF0a543d)),
                const SizedBox(width: 8),
                const Text(
                  '4 visites par an (1 tous les 3 mois)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Montant total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _formatCurrency(widget.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Split payment breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0a543d).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // 1er paiement
                  _buildPaymentRow(
                    '1er paiement (50%)',
                    _firstPaymentAmount,
                    'À la validation',
                    widget.firstPaymentStatus == 'paid'
                        ? Icons.check_circle
                        : (_currentPaymentPhase == 1
                            ? Icons.arrow_forward_ios
                            : Icons.schedule),
                    widget.firstPaymentStatus == 'paid'
                        ? Colors.green
                        : (_currentPaymentPhase == 1
                            ? Colors.orange
                            : Colors.grey),
                    isSelected: _currentPaymentPhase == 1,
                  ),
                  const SizedBox(height: 8),
                  // 2ème paiement
                  _buildPaymentRow(
                    '2ème paiement (50%)',
                    _secondPaymentAmount,
                    'Après 3ème visite',
                    widget.secondPaymentStatus == 'paid'
                        ? Icons.check_circle
                        : (_currentPaymentPhase == 2
                            ? Icons.arrow_forward_ios
                            : Icons.schedule),
                    widget.secondPaymentStatus == 'paid'
                        ? Colors.green
                        : (_currentPaymentPhase == 2
                            ? Colors.orange
                            : Colors.grey),
                    isSelected: _currentPaymentPhase == 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Montant à payer maintenant
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 7, 5, 1),
                        ),
                      ),
                      Text(
                        _paymentDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 15, 14, 14),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(_amountToPay),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
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

  Widget _buildPaymentInfo() {
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
                const Expanded(
                  child: Text(
                    'Paiement sécurisé avec FineoPay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    String title,
    double amount,
    String description,
    IconData icon,
    Color color, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.black54,
            ),
          ),
        ],
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
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre contrat sera activé dès réception du paiement. La première intervention sera planifiée automatiquement.',
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

  void _showCashPaymentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.money, color: Color(0xFF0a543d), size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(_paymentTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildCashInfoRow('📋 Référence', widget.reference),
                    const Divider(),
                    _buildCashInfoRow(
                        '💰 Total contrat', _formatCurrency(widget.amount)),
                    const Divider(),
                    _buildCashInfoRow(
                        '💳 $_paymentTitle', _formatCurrency(_amountToPay)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              _buildCashInfoRow(
                  '🕐 Horaires', 'Lun-Ven: 8h-17h30\nSam: 9h-13h'),
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
                        'Veuillez mentionner la référence ${widget.reference} lors du paiement.',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    _confirmPayment();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
            ),
            icon: _isProcessing
                ? const SizedBox.shrink()
                : const Icon(Icons.check_circle),
            label: _isProcessing
                ? const SizedBox(
                    height: 20,
                    child:
                        ButtonLoadingIndicator(color: Colors.white, size: 6.0),
                  )
                : const Text('J\'ai payé'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      print(
          '💳 Initialisation paiement FineoPay pour contrat #${widget.subscriptionId} - Phase $_currentPaymentPhase');

      // Initialiser le paiement FineoPay avec le montant 50%
      final paymentData = await _paymentService.initializeSubscriptionPayment(
        widget.subscriptionId,
        _amountToPay, // Utiliser le montant 50% au lieu du montant total
        widget.reference,
        paymentPhase: _currentPaymentPhase, // Indiquer la phase de paiement
      );
      final paymentUrl = paymentData['paymentUrl'] as String;

      print(
          '✅ URL de paiement reçue: $paymentUrl (Montant: $_amountToPay FCFA)');

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
              title: 'Paiement contrat ${widget.reference}',
              orderId: widget.subscriptionId, // Utiliser subscriptionId
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
      if (!_isWaitingForPayment) {
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
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      print(
          '🔍 Vérification statut paiement pour contrat #${widget.subscriptionId} (Phase: $_currentPaymentPhase)');

      // Vérifier le statut via le backend
      final response = await _apiService.get(
          '/fineopay/verify-subscription-payment/${widget.subscriptionId}');

      if (response['success'] == true) {
        // Le backend retourne payment_status (underscore) ou first_payment_status pour 50/50
        final paymentStatus = response['data']?['payment_status'] ??
            response['data']?['paymentStatus'];
        final subscriptionStatus = response['data']?['status'];
        final firstPaymentStatus = response['data']?['first_payment_status'];
        final secondPaymentStatus = response['data']?['second_payment_status'];

        print(
            '📊 Statut: $subscriptionStatus, 1er paiement: $firstPaymentStatus, 2ème paiement: $secondPaymentStatus');

        // Vérifier selon la phase de paiement
        if (_currentPaymentPhase == 2) {
          // SECOND PAIEMENT (50%) - Dernière visite
          if (secondPaymentStatus == 'paid' ||
              subscriptionStatus == 'completed') {
            // Second paiement réussi !
            _stopPolling();

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(child: Text('🎉 Contrat complété !')),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Votre paiement final (50%) a été confirmé !',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toutes les visites de maintenance ont été effectuées et le contrat est maintenant complété.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.celebration,
                                color: Colors.green, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Merci pour votre confiance ! À bientôt pour un nouveau contrat.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le dialogue
                        Navigator.pop(context); // Quitter l'écran de paiement
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        } else {
          // PREMIER PAIEMENT (50%) - À la validation
          if (paymentStatus == 'paid' || firstPaymentStatus == 'paid') {
            // Paiement réussi !
            _stopPolling();

            // Afficher le message de succès
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(child: Text('Premier paiement réussi !')),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Votre premier paiement (50%) a été confirmé.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Votre contrat est maintenant actif et la première intervention a été planifiée.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Le deuxième paiement (50%) sera demandé après la 3ème visite.',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le dialogue
                        Navigator.pop(context); // Quitter l'écran de paiement
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erreur vérification statut: $e');
    }
  }

  Future<void> _confirmPayment() async {
    // Afficher un dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0a543d)),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Text('Vérification du paiement en cours...'),
            ),
          ],
        ),
      ),
    );

    try {
      final response =
          await _apiService.confirmContractPayment(widget.subscriptionId);

      if (mounted) {
        // Fermer le dialogue de chargement
        Navigator.pop(context);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('Paiement confirmé !')),
              ],
            ),
            content: Text(response['message'] ??
                'Votre contrat est maintenant actif. La première intervention a été planifiée.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer le dialogue
                  Navigator.pop(context); // Retourner à l'écran précédent
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fermer le dialogue de chargement
        Navigator.pop(context);
        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    }
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

  String _formatContractType(String type) {
    switch (type) {
      case 'scheduled':
      case 'scheduled_maintenance':
        return 'Maintenance programmée';
      case 'on_demand':
        return 'Maintenance à la demande';
      default:
        return 'Contrat de maintenance';
    }
  }
}
