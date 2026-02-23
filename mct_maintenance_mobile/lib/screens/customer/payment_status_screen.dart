import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class PaymentStatusScreen extends StatefulWidget {
  final int orderId;
  final String orderReference;

  const PaymentStatusScreen({
    super.key,
    required this.orderId,
    required this.orderReference,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  int _checkCount = 0;
  final int _maxChecks = 20; // Vérifier pendant 1 minute max (20 x 3s)
  String _paymentStatus = 'pending';
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _startChecking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startChecking() {
    // Vérifier immédiatement
    _checkPaymentStatus();

    // Puis vérifier toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_checkCount >= _maxChecks || _paymentStatus == 'paid') {
        timer.cancel();
        setState(() => _isChecking = false);
      } else {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      _checkCount++;
      print(
          '🔍 Vérification ACTIVE statut paiement (${_checkCount}/$_maxChecks)...');

      final response = await _apiService.get(
        '/fineopay/verify-payment/${widget.orderId}',
      );

      if (response['success'] == true) {
        final status = response['data']['paymentStatus'];
        print('💳 Statut: $status');

        setState(() {
          _paymentStatus = status;
        });

        if (status == 'paid') {
          _timer?.cancel();
          setState(() => _isChecking = false);

          if (mounted) {
            SnackBarHelper.showSuccess(
              context,
              'Paiement confirmé !',
              emoji: '✅',
            );

            // Rediriger vers la liste des commandes après 2 secondes
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ Erreur vérification statut: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du paiement'),
        leading: _paymentStatus == 'paid'
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIcon(),
                const SizedBox(height: 32),
                Text(
                  _getStatusTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusMessage(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildActionButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_paymentStatus == 'paid') {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
      );
    } else if (_isChecking) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(strokeWidth: 6),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.hourglass_empty,
          color: Colors.orange,
          size: 60,
        ),
      );
    }
  }

  String _getStatusTitle() {
    if (_paymentStatus == 'paid') {
      return 'Paiement confirmé !';
    } else if (_isChecking) {
      return 'Vérification en cours...';
    } else {
      return 'Paiement en attente';
    }
  }

  String _getStatusMessage() {
    if (_paymentStatus == 'paid') {
      return 'Votre paiement a été traité avec succès.\nCommande ${widget.orderReference}';
    } else if (_isChecking) {
      return 'Nous vérifions votre paiement auprès de FineoPay.\nVeuillez patienter...';
    } else {
      return 'Le paiement n\'a pas encore été confirmé.\nVous pouvez fermer cet écran et vous recevrez une notification dès que le paiement sera validé.';
    }
  }

  Widget _buildActionButton(BuildContext context) {
    if (_paymentStatus == 'paid') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.home),
        label: const Text('Retour à l\'accueil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    } else if (!_isChecking) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isChecking = true;
                _checkCount = 0;
              });
              _startChecking();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Vérifier à nouveau'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annuler'),
      );
    }
  }
}
