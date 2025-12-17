import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final int subscriptionId;
  final String subscriptionName;
  final double amount;

  const SubscriptionPaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final ApiService _apiService = ApiService();
  String _selectedPaymentMethod = 'orange_money';
  bool _isProcessing = false;

  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _getProvider() {
    switch (_selectedPaymentMethod) {
      case 'orange_money':
        return 'orange_money';
      case 'mtn_money':
        return 'mtn_money';
      case 'moov_money':
        return 'moov_money';
      case 'wave':
        return 'wave';
      case 'card':
        return 'stripe';
      case 'cash':
        return 'cash';
      default:
        return 'orange_money';
    }
  }

  Future<void> _processPayment() async {
    // Validation du formulaire seulement pour les méthodes qui nécessitent des champs
    if (_selectedPaymentMethod != 'cash' && _selectedPaymentMethod != 'card') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final paymentData = {
        'subscriptionId': widget.subscriptionId,
        'provider': _getProvider(),
        if (_selectedPaymentMethod == 'orange_money' ||
            _selectedPaymentMethod == 'mtn_money' ||
            _selectedPaymentMethod == 'moov_money' ||
            _selectedPaymentMethod == 'wave')
          'phoneNumber': _phoneController.text,
      };

      await _apiService.processSubscriptionPayment(paymentData);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon:
                const Icon(Icons.check_circle, color: Colors.orange, size: 64),
            title: const Text('Paiement initié'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre souscription à "${widget.subscriptionName}" est en attente de confirmation de paiement.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Montant: ${_formatCurrency(widget.amount)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 64),
            title: const Text('Erreur de paiement'),
            content: Text(
              'Une erreur est survenue lors du traitement de votre paiement.\n\n$e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement de souscription'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubscriptionSummary(),
              const SizedBox(height: 24),
              const Text('Méthode de paiement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPaymentMethods(),
              const SizedBox(height: 24),
              if (_selectedPaymentMethod == 'orange_money' ||
                  _selectedPaymentMethod == 'mtn_money' ||
                  _selectedPaymentMethod == 'moov_money')
                _buildMobileMoneyForm(),
              if (_selectedPaymentMethod == 'wave') _buildWaveForm(),
              if (_selectedPaymentMethod == 'card') _buildCardForm(),
              if (_selectedPaymentMethod == 'cash') _buildCashInfo(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text('Payer ${_formatCurrency(widget.amount)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSummary() {
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
                const Text('Souscription',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                Expanded(
                  child: Text(widget.subscriptionName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant à payer',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_formatCurrency(widget.amount),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0a543d))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        // Orange Money
        _buildMobileMoneyMethodTile(
          'orange_money',
          'Orange Money',
          'assets/images/orange_money.png', // Placeholder pour le logo
          'Paiement via Orange Money',
        ),
        const SizedBox(height: 12),
        // MTN Mobile Money (MoMo)
        _buildMobileMoneyMethodTile(
          'mtn_money',
          'MTN Mobile Money',
          'assets/images/mtn_money.png', // Placeholder pour le logo
          'Paiement via MTN MoMo',
        ),
        const SizedBox(height: 12),
        // Moov Money
        _buildMobileMoneyMethodTile(
          'moov_money',
          'Moov Money',
          'assets/images/moov_money.png', // Format PNG
          'Paiement via Moov Money',
        ),
        const SizedBox(height: 12),
        // Wave avec logo
        _buildMobileMoneyMethodTile(
          'wave',
          'Wave',
          'assets/images/wave.png',
          'Paiement mobile Wave',
        ),
        const SizedBox(height: 12),
        // Carte bancaire
        _buildPaymentMethodTile(
            'card', 'Carte bancaire', Icons.credit_card, 'Visa, Mastercard'),
        const SizedBox(height: 12),
        // Espèces
        _buildPaymentMethodTile(
            'cash', 'Espèces', Icons.money, 'Paiement en espèces'),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
      String value, String title, IconData icon, String subtitle) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  isSelected ? const Color(0xFF0a543d) : Colors.grey.shade300,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF0a543d).withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF0a543d) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0a543d) : null)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0a543d)),
          ],
        ),
      ),
    );
  }

  // Widget spécifique pour les opérateurs Mobile Money avec logo
  Widget _buildMobileMoneyMethodTile(
      String value, String title, String logoPath, String subtitle) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  isSelected ? const Color(0xFF0a543d) : Colors.grey.shade300,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF0a543d).withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            // Zone pour le logo de l'opérateur
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                logoPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.phone_android,
                    color: isSelected
                        ? const Color(0xFF0a543d)
                        : Colors.grey.shade600,
                    size: 30,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0a543d) : null)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0a543d)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations Mobile Money',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: 'Ex: 0707070707',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Veuillez entrer votre numéro';
            if (value.length < 10) return 'Numéro invalide';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Vous recevrez une notification sur votre téléphone pour confirmer le paiement.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.blue.shade900))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations Wave',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Numéro Wave',
            hintText: 'Ex: 0707070707',
            prefixIcon: const Icon(Icons.water_drop),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Veuillez entrer votre numéro Wave';
            if (value.length < 10) return 'Numéro invalide';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations de carte',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Numéro de carte',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Veuillez entrer le numéro de carte'
              : null,
        ),
      ],
    );
  }

  Widget _buildCashInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Paiement en espèces',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vous avez choisi de payer en espèces. Veuillez vous présenter à l\'un de nos bureaux pour effectuer le paiement.',
            style: TextStyle(fontSize: 14, color: Colors.green.shade900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCashInstruction('1',
                    'Confirmez votre souscription en cliquant sur "Confirmer le paiement"'),
                const SizedBox(height: 6),
                _buildCashInstruction('2',
                    'Rendez-vous à l\'un de nos bureaux avec le montant en espèces'),
                const SizedBox(height: 6),
                _buildCashInstruction('3',
                    'Présentez votre référence de souscription à notre agent'),
                const SizedBox(height: 6),
                _buildCashInstruction('4', 'Récupérez votre reçu de paiement'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInstruction(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0a543d),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }
}
