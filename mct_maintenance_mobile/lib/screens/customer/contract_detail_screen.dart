import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import 'contract_payment_screen.dart';

class ContractDetailScreen extends StatefulWidget {
  final Contract contract;

  const ContractDetailScreen({
    super.key,
    required this.contract,
  });

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isRequestingRenewal = false;
  bool _isRefreshing = false;
  late Contract _contract;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
  }

  /// Actualiser les données du contrat
  Future<void> _refreshContract() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final updatedContract = await _apiService.getContractById(_contract.id);
      if (mounted && updatedContract != null) {
        setState(() {
          _contract = updatedContract;
          _isRefreshing = false;
        });
        SnackBarHelper.showSuccess(context, 'Contrat actualisé');
      } else {
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        SnackBarHelper.showError(context, 'Erreur lors de l\'actualisation');
      }
    }
  }

  /// Ouvrir l'écran de paiement
  void _openPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractPaymentScreen(
          subscriptionId: _contract.subscriptionId ?? _contract.id,
          reference: _contract.reference,
          amount: _contract.amount,
          contractType: _contract.type,
          equipment: _contract.equipmentDescription ?? 'Équipement',
          model: _contract.equipmentModel,
          firstPaymentStatus: _contract.firstPaymentStatus,
          secondPaymentStatus: _contract.secondPaymentStatus,
        ),
      ),
    );
  }

  Future<void> _requestRenewal() async {
    setState(() => _isRequestingRenewal = true);

    try {
      final response =
          await _apiService.requestContractRenewal(widget.contract.id);

      if (mounted) {
        setState(() => _isRequestingRenewal = false);

        // Afficher un dialogue de succès
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Demande envoyée'),
              ],
            ),
            content: Text(response['message'] ??
                'Votre demande de renouvellement a été envoyée avec succès.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer le dialogue
                  Navigator.pop(context); // Retourner à la liste
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingRenewal = false);

        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  void _shareContract() {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final contract = widget.contract;

    // Formater le statut en français
    String status = _formatStatus(contract.status);

    // Formater le type en français
    String type = _formatType(contract.type);

    // Formater la fréquence de paiement
    String frequency = _formatPaymentFrequency(contract.paymentFrequency);

    // Créer le message de partage
    final String shareText = '''
📄 CONTRAT DE MAINTENANCE - SMART MAINTENANCE

Référence: ${contract.reference}
${contract.title.isNotEmpty ? 'Titre: ${contract.title}\n' : ''}
Type: $type
Statut: $status

📅 Période:
Du: ${dateFormat.format(contract.startDate)}
Au: ${dateFormat.format(contract.endDate)}

💰 Montant: ${contract.amount.toStringAsFixed(0)} FCFA
Fréquence: $frequency

${contract.description.isNotEmpty ? '\n📝 Description:\n${contract.description}\n' : ''}
${contract.termsAndConditions?.isNotEmpty == true ? '\n📋 Termes et Conditions:\n${contract.termsAndConditions}\n' : ''}
${contract.notes?.isNotEmpty == true ? '\n📌 Notes:\n${contract.notes}\n' : ''}
---
Smart Maintenance - Service de qualité
    '''
        .trim();

    Share.share(
      shareText,
      subject: 'Contrat ${contract.reference} - Smart Maintenance',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final statusColor = _getStatusColor(_contract.status);
    final isActive = _contract.status == 'active';
    final daysRemaining = _contract.endDate.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Contrat'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshContract,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareContract,
            tooltip: 'Partager le contrat',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContract,
        color: const Color(0xFF0a543d),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.15,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _contract.reference,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _contract.title.isNotEmpty
                            ? _contract.title
                            : 'Contrat de ${_formatType(_contract.type)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getTypeIcon(_contract.type),
                                    size: 16, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  _formatType(_contract.type),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatStatus(_contract.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Alerte si expiration proche
                if (isActive && daysRemaining <= 30 && daysRemaining > 0)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Votre contrat expire dans $daysRemaining jour${daysRemaining > 1 ? "s" : ""}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Montant avec split payment
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0a543d), Color(0xFF0e6b4d)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0a543d).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Montant total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Montant Total',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_contract.amount.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatPaymentFrequency(
                                  _contract.paymentFrequency),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      // Split payment breakdown
                      Row(
                        children: [
                          // 1er paiement - 50%
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '1er paiement',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_contract.amount / 2).ceil().toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'À la validation',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 2ème paiement - 50%
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.event_available,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '2ème paiement',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_contract.amount / 2).floor().toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Après 3ème visite',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Modalités de paiement - 50/50
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Modalités de paiement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentStep(
                        step: '1',
                        title: 'Premier paiement (50%)',
                        description: 'À la validation du contrat',
                        amount: (_contract.amount / 2).ceil().toDouble(),
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentStep(
                        step: '2',
                        title: 'Deuxième paiement (50%)',
                        description: 'Après la 3ème visite de maintenance',
                        amount: (_contract.amount / 2).floor().toDouble(),
                        icon: Icons.event_available,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                color: Colors.blue.shade600, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Votre contrat inclut 4 visites de maintenance par an',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Période du contrat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Période du contrat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateCard(
                              icon: Icons.play_circle_outline,
                              label: 'Date de début',
                              date: dateFormat.format(_contract.startDate),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateCard(
                              icon: Icons.event,
                              label: 'Date de fin',
                              date: dateFormat.format(_contract.endDate),
                              color: isActive && daysRemaining <= 30
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                if (_contract.description.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _contract.description,
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Termes et conditions
                if (widget.contract.termsAndConditions?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Termes et Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            widget.contract.termsAndConditions!,
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Notes
                if (widget.contract.notes?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note_outlined,
                                  color: Colors.amber[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.contract.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                // Bouton de paiement si en attente de paiement
                if (_contract.status == 'pending_payment')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Alerte paiement en attente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.payment,
                                  color: Colors.orange, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Paiement en attente',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Montant: ${_contract.amount.toStringAsFixed(0)} FCFA',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openPaymentScreen(),
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Payer maintenant'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              SnackBarHelper.showInfo(context,
                                  'Contactez-nous au +225 XX XX XX XX XX');
                            },
                            icon: const Icon(Icons.support_agent),
                            label: const Text('Contacter le support'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF0a543d)),
                              foregroundColor: const Color(0xFF0a543d),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bouton de second paiement pour contrats actifs
                if (_contract.status == 'active' ||
                    _contract.status == 'awaiting_second_payment')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Alerte second paiement requis
                        Builder(
                          builder: (context) {
                            final visitsCompleted =
                                _contract.visitsCompleted ?? 0;
                            final visitsTotal = _contract.visitsTotal ?? 4;
                            final allVisitsDone =
                                visitsCompleted >= visitsTotal;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: allVisitsDone
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: allVisitsDone
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        allVisitsDone
                                            ? Icons.celebration
                                            : Icons.hourglass_empty,
                                        color: allVisitsDone
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              allVisitsDone
                                                  ? 'Maintenance terminée !'
                                                  : 'Maintenance en cours',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: allVisitsDone
                                                    ? Colors.blue
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              allVisitsDone
                                                  ? 'Toutes les $visitsTotal visites ont été effectuées.'
                                                  : '$visitsCompleted/$visitsTotal visites effectuées. Le paiement final sera disponible après la 3ème visite.',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: allVisitsDone
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          color: allVisitsDone
                                              ? Colors.orange
                                              : Colors.grey,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Paiement final: ${(_contract.secondPaymentAmount ?? (_contract.amount / 2)).toStringAsFixed(0)} FCFA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: allVisitsDone
                                                  ? Colors.orange
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final visitsCompleted =
                                _contract.visitsCompleted ?? 0;
                            final visitsTotal = _contract.visitsTotal ?? 4;
                            final canPay = visitsCompleted >=
                                    (visitsTotal - 1) ||
                                _contract.status == 'awaiting_second_payment';

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    canPay ? () => _openPaymentScreen() : null,
                                icon: const Icon(Icons.credit_card),
                                label: const Text('Payer le solde (50%)'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor:
                                      canPay ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                // Actions pour contrats complétés (après second paiement)
                if (_contract.status == 'completed')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        // Vérifier si toutes les visites sont terminées
                        final visitsTotal = _contract.visitsTotal ?? 0;
                        final visitsCompleted = _contract.visitsCompleted ?? 0;
                        final allVisitsCompleted =
                            visitsTotal > 0 && visitsCompleted >= visitsTotal;
                        final canRequestRenewal =
                            allVisitsCompleted && !_isRequestingRenewal;

                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    canRequestRenewal ? _requestRenewal : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Demander un renouvellement'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: canRequestRenewal
                                      ? const Color(0xFF0a543d)
                                      : Colors.grey.shade400,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            // Message explicatif si bouton désactivé
                            if (!allVisitsCompleted && visitsTotal > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Le renouvellement sera disponible après la dernière intervention ($visitsCompleted/$visitsTotal effectuées)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Contacter le support
                                  SnackBarHelper.showInfo(context,
                                      'Contactez-nous au +225 XX XX XX XX XX');
                                },
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Contacter le support'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(
                                      color: Color(0xFF0a543d)),
                                  foregroundColor: const Color(0xFF0a543d),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep({
    required String step,
    required String title,
    required String description,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blueGrey;
      case 'pending':
        return Colors.orange;
      case 'pending_payment':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'awaiting_second_payment':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'used':
        return Colors.purple;
      case 'expired':
        return Colors.red;
      case 'terminated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending':
        return 'En attente';
      case 'pending_payment':
        return 'Paiement en attente';
      case 'active':
        return 'Actif';
      case 'awaiting_second_payment':
        return 'Paiement final requis';
      case 'completed':
        return 'Terminé';
      case 'expired':
        return 'Expiré';
      case 'terminated':
        return 'Résilié';
      case 'used':
        return 'Consommé';
      default:
        return status;
    }
  }

  String _formatType(String type) {
    switch (type) {
      case 'maintenance':
        return 'Maintenance';
      case 'scheduled_maintenance':
        return 'Maintenance programmée';
      case 'support':
        return 'Support';
      case 'warranty':
        return 'Garantie';
      case 'service':
        return 'Service';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build_circle;
      case 'scheduled_maintenance':
        return Icons.calendar_month;
      case 'support':
        return Icons.support_agent;
      case 'warranty':
        return Icons.verified_user;
      case 'service':
        return Icons.room_service;
      default:
        return Icons.assignment;
    }
  }

  String _formatPaymentFrequency(String frequency) {
    switch (frequency) {
      case 'monthly':
        return 'Mensuel';
      case 'quarterly':
        return 'Trimestriel';
      case 'yearly':
        return 'Annuel';
      case 'one_time':
        return 'Unique';
      default:
        return frequency;
    }
  }
}
