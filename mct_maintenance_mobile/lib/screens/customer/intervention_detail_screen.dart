import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import 'diagnostic_payment_screen.dart';
import 'payment_screen.dart';
import 'contract_payment_screen.dart';

class InterventionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;

  const InterventionDetailScreen({
    super.key,
    required this.intervention,
  });

  @override
  State<InterventionDetailScreen> createState() =>
      _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _intervention;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _intervention = widget.intervention;

    // Rafraîchir immédiatement à l'ouverture pour avoir les dernières données
    Future.delayed(Duration.zero, () {
      print(
          '🔄 Rafraîchissement initial de l\'intervention #${_intervention['id']}');
      _refreshIntervention();
      // Popup d'évaluation désactivé - l'utilisateur peut évaluer via le bouton
    });

    // Rafraîchir automatiquement toutes les 30 secondes si l'intervention n'est pas terminée
    final status = _intervention['status'] ?? 'pending';
    print(
        '📊 Statut actuel: $status - Timer auto-refresh: ${status != 'completed' && status != 'cancelled' ? 'ACTIVÉ' : 'DÉSACTIVÉ'}');

    if (status != 'completed' && status != 'cancelled') {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        print(
            '⏰ Timer déclenché - Rafraîchissement auto de l\'intervention #${_intervention['id']}');
        _refreshIntervention();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshIntervention() async {
    // Ne pas afficher le loader lors du rafraîchissement automatique
    final isAutoRefresh = !_isLoading;
    if (!isAutoRefresh) {
      setState(() => _isLoading = true);
    }

    try {
      print('📡 Appel API getInterventionById(${_intervention['id']})...');
      final response =
          await _apiService.getInterventionById(_intervention['id']);

      final newStatus = response['data']['status'];
      final oldStatus = _intervention['status'];

      print('✅ Réponse API reçue:');
      print('   - Ancien statut: $oldStatus');
      print('   - Nouveau statut: $newStatus');

      if (oldStatus != newStatus) {
        print('🔄 CHANGEMENT DE STATUT DÉTECTÉ: $oldStatus → $newStatus');
      }

      if (mounted) {
        setState(() {
          _intervention = response['data'];
          _isLoading = false;
        });

        // Si le statut a changé, annuler le timer car un nouveau sera créé avec le nouveau statut
        if (oldStatus != newStatus &&
            (newStatus == 'completed' || newStatus == 'cancelled')) {
          print('⏹️ Arrêt du timer auto-refresh (intervention terminée)');
          _refreshTimer?.cancel();
          _refreshTimer = null;
        }
      }
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (!isAutoRefresh) {
          SnackBarHelper.showError(context, 'Erreur: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _intervention['status'] ?? 'pending';
    final priority = _intervention['priority'] ?? 'medium';
    final scheduledDate = _intervention['scheduled_date'] != null
        ? DateTime.parse(_intervention['scheduled_date'])
        : null;
    final completedDate = _intervention['completed_date'] != null
        ? DateTime.parse(_intervention['completed_date'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Intervention'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshIntervention,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/Maintenancier_SMART_Maintenance_two.png'),
                  fit: BoxFit.cover,
                  opacity: 0.4,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _refreshIntervention,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et priorité
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _intervention['title'] ?? 'Sans titre',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityBadge(priority),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Suivi des étapes
                      _buildProgressTracker(status),
                      const SizedBox(height: 24),

                      // Informations principales
                      _buildInfoCard(),
                      const SizedBox(height: 16),

                      // Description
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),

                      // Images
                      if (_intervention['images'] != null &&
                          (_intervention['images'] as List).isNotEmpty)
                        _buildImagesCard(),

                      if (_intervention['images'] != null &&
                          (_intervention['images'] as List).isNotEmpty)
                        const SizedBox(height: 16),

                      // Technicien
                      if (_intervention['technician'] != null)
                        _buildTechnicianCard(),

                      // Offre d'entretien
                      if (_intervention['maintenance_offer'] != null) ...[
                        const SizedBox(height: 16),
                        _buildMaintenanceOfferCard(),
                      ],

                      const SizedBox(height: 16),

                      // Dates
                      _buildDatesCard(scheduledDate, completedDate),

                      // Section paiement si non payé
                      if (_needsPayment()) ...[
                        const SizedBox(height: 16),
                        _buildPaymentSection(),
                      ],

                      // Bouton d'annulation si l'intervention peut être annulée
                      if (_canCancel(status)) ...[
                        const SizedBox(height: 16),
                        _buildCancelButton(),
                      ],

                      // Section confirmation du rapport si rapport soumis et non confirmé
                      if (status == 'completed' && _hasReportToConfirm()) ...[
                        const SizedBox(height: 16),
                        _buildConfirmationSection(),
                      ],

                      // Section notation du technicien si intervention terminée et confirmée
                      if (status == 'completed' && _isConfirmedByCustomer())
                        const SizedBox(height: 16),
                      if (status == 'completed' && _isConfirmedByCustomer())
                        _buildRatingSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  bool _canCancel(String status) {
    // Le client peut annuler si l'intervention est en attente ou assignée
    // mais pas encore acceptée, en cours ou terminée
    return status == 'pending' || status == 'assigned';
  }

  bool _needsPayment() {
    // Check if this intervention requires payment
    final diagnosticPaid = _intervention['diagnostic_paid'] ?? false;
    final diagnosticFee =
        double.tryParse(_intervention['diagnostic_fee']?.toString() ?? '0') ??
            0;
    final isFree = _intervention['is_free_diagnosis'] ?? true;

    // Needs payment if not free, has a fee, and not yet paid
    return !isFree && diagnosticFee > 0 && !diagnosticPaid;
  }

  // Vérifie si le rapport est soumis mais pas encore confirmé par le client
  bool _hasReportToConfirm() {
    final reportSubmittedAt = _intervention['report_submitted_at'];
    final customerConfirmed = _intervention['customer_confirmed'] ?? false;
    return reportSubmittedAt != null && customerConfirmed != true;
  }

  // Vérifie si le client a confirmé l'intervention
  bool _isConfirmedByCustomer() {
    final reportSubmittedAt = _intervention['report_submitted_at'];
    final customerConfirmed = _intervention['customer_confirmed'] ?? false;
    // On peut noter si: pas de rapport (ancien système) OU rapport confirmé
    return reportSubmittedAt == null || customerConfirmed == true;
  }

  Widget _buildConfirmationSection() {
    final reportData = _intervention['report_data'];
    Map<String, dynamic>? parsedReport;
    if (reportData != null && reportData is String) {
      try {
        parsedReport = Map<String, dynamic>.from(reportData.isNotEmpty
            ? (reportData.startsWith('{') ? _parseJson(reportData) : {})
            : {});
      } catch (e) {
        parsedReport = null;
      }
    } else if (reportData is Map) {
      parsedReport = Map<String, dynamic>.from(reportData);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fact_check,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Confirmation du rapport',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
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
                      const Expanded(
                        child: Text(
                          'Le technicien a soumis son rapport',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez confirmer que l\'intervention a été correctement réalisée, ou contestez si vous avez des remarques.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (parsedReport != null && parsedReport.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildReportSummary(parsedReport),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showRejectionDialog,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Contester'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmIntervention,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a543d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      if (jsonString.isEmpty) return {};
      final decoded = jsonDecode(jsonString);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {};
    }
  }

  Widget _buildReportSummary(Map<String, dynamic> report) {
    final workDone = report['travaux_effectues'] ?? report['description'] ?? '';
    final observations = report['observations'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé du rapport',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (workDone.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.build, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workDone,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    observations,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmIntervention() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'intervention'),
        content: const Text(
          'Confirmez-vous que le technicien a correctement réalisé l\'intervention ?\n\n'
          'Vous pourrez ensuite évaluer le service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
            ),
            child:
                const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.confirmInterventionCompletion(
          _intervention['id'],
          true,
        );

        print('🔍 Réponse confirmation: $response');
        print('🔍 response[data]: ${response['data']}');
        print('🔍 payment_required: ${response['data']?['payment_required']}');
        print('🔍 payment_info: ${response['data']?['payment_info']}');
        print(
            '🔍 contract_payment_info: ${response['data']?['contract_payment_info']}');

        // Vérifier si un second paiement de CONTRAT est requis (50% restant - dernière visite)
        if (response['data'] != null &&
            response['data']['payment_required'] == true &&
            response['data']['contract_payment_info'] != null) {
          final contractPaymentInfo = response['data']['contract_payment_info'];
          print('💰 Second paiement CONTRAT requis: $contractPaymentInfo');
          if (mounted) {
            // Afficher une boîte de dialogue pour le paiement final du contrat
            final shouldPay = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.payment_rounded,
                    color: Color(0xFF0a543d), size: 48),
                title: const Text('Paiement final du contrat'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toutes les visites de maintenance ont été effectuées. Veuillez procéder au paiement final du contrat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a543d).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${(contractPaymentInfo['amount'] as num).toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0a543d),
                            ),
                          ),
                          const Text(
                            'Solde final (50%)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Plus tard'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a543d),
                    ),
                    child: const Text('Payer maintenant',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

            if (shouldPay == true && mounted) {
              // Rediriger vers l'écran de paiement de contrat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContractPaymentScreen(
                    subscriptionId: contractPaymentInfo['subscription_id'],
                    reference: contractPaymentInfo['reference'] ?? 'N/A',
                    amount: (contractPaymentInfo['total'] as num).toDouble(),
                    contractType: 'Contrat de maintenance',
                    equipment: contractPaymentInfo['equipment_description'] ??
                        'Maintenance annuelle',
                    model: contractPaymentInfo['equipment_model'],
                    paymentPhase: 2, // Second paiement
                    firstPaymentStatus: 'paid',
                    secondPaymentStatus: 'pending',
                  ),
                ),
              ).then((_) => _refreshIntervention());
              return; // On sort ici car on a redirigé vers le paiement
            }
          }
        }

        // Vérifier si un second paiement de DEVIS est requis (50% restant)
        if (response['data'] != null &&
            response['data']['payment_required'] == true) {
          final paymentInfo = response['data']['payment_info'];
          print('💰 Second paiement requis: $paymentInfo');
          if (paymentInfo != null && mounted) {
            // Afficher une boîte de dialogue pour le paiement du solde
            final shouldPay = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.payment,
                    color: Color(0xFF0a543d), size: 48),
                title: const Text('Paiement du solde'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'L\'intervention est confirmée. Veuillez procéder au paiement du solde restant.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a543d).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${(paymentInfo['amount'] as num).toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0a543d),
                            ),
                          ),
                          const Text(
                            '50% restant',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Plus tard'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a543d),
                    ),
                    child: const Text('Payer maintenant',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

            if (shouldPay == true && mounted) {
              // Rediriger vers l'écran de paiement
              final orderId = paymentInfo['order_id'];
              if (orderId == null) {
                SnackBarHelper.showError(
                    context, 'Erreur: Commande non trouvée');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    invoiceId: orderId.toString(),
                    invoiceNumber: paymentInfo['quote_reference'] ?? 'N/A',
                    amount: (paymentInfo['amount'] as num).toDouble(),
                    paymentStep: 2,
                  ),
                ),
              ).then((_) => _refreshIntervention());
              return; // On sort ici car on a redirigé vers le paiement
            }
          }
        }

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Merci pour votre confirmation !',
          );
          await _refreshIntervention();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Erreur: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showRejectionDialog() async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contester l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veuillez expliquer pourquoi vous contestez la fin de cette intervention :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Ex: Le problème n\'est pas résolu, le technicien n\'est pas venu...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              } else {
                SnackBarHelper.showWarning(
                  context,
                  'Veuillez indiquer la raison',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _apiService.confirmInterventionCompletion(
          _intervention['id'],
          false,
          rejectionReason: result,
        );
        if (mounted) {
          SnackBarHelper.showInfo(
            context,
            'Votre contestation a été enregistrée. Un administrateur vous contactera.',
          );
          await _refreshIntervention();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Erreur: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPaymentSection() {
    final diagnosticFee =
        double.tryParse(_intervention['diagnostic_fee']?.toString() ?? '0') ??
            0;
    final interventionType = _intervention['intervention_type'] ?? '';

    String paymentLabel;
    switch (interventionType) {
      case 'repair':
        paymentLabel = 'Paiement dépannage';
        break;
      case 'installation':
        paymentLabel = 'Paiement installation';
        break;
      default:
        paymentLabel = 'Paiement diagnostic';
    }

    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  paymentLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Montant à payer: ${diagnosticFee.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez effectuer le paiement pour confirmer votre demande.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiagnosticPaymentScreen(
                        interventionId: _intervention['id'],
                        diagnosticFee: diagnosticFee,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _refreshIntervention();
                  }
                },
                icon: const Icon(Icons.credit_card),
                label: const Text('Payer maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous pouvez annuler cette demande si vous n\'en avez plus besoin.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showCancelConfirmation,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Annuler cette intervention'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 32,
          ),
        ),
        title: const Text('Annuler l\'intervention ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette demande d\'intervention ? Cette action est irréversible.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non, garder'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelIntervention();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelIntervention() async {
    setState(() => _isLoading = true);

    try {
      await _apiService.cancelIntervention(_intervention['id']);

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Intervention annulée avec succès',
          emoji: '✓',
        );
        // Rafraîchir les données
        await _refreshIntervention();
        // Retourner à la liste avec indication de mise à jour
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Widget _buildProgressTracker(String status) {
    final steps = [
      {
        'key': 'pending',
        'label': 'Demande créée',
        'icon': Icons.assignment,
        'desc': 'En attente d\'assignation'
      },
      {
        'key': 'assigned',
        'label': 'Technicien assigné',
        'icon': Icons.person_add,
        'desc': 'Un technicien a été désigné'
      },
      {
        'key': 'accepted',
        'label': 'Acceptée',
        'icon': Icons.check_circle_outline,
        'desc': 'Le technicien a accepté'
      },
      {
        'key': 'on_the_way',
        'label': 'En route',
        'icon': Icons.directions_car,
        'desc': 'Le technicien est en route'
      },
      {
        'key': 'arrived',
        'label': 'Sur place',
        'icon': Icons.location_on,
        'desc': 'Le technicien est arrivé'
      },
      {
        'key': 'in_progress',
        'label': 'En cours',
        'icon': Icons.engineering,
        'desc': 'Intervention en cours'
      },
      {
        'key': 'completed',
        'label': 'Terminée',
        'icon': Icons.check_circle,
        'desc': 'Intervention terminée'
      },
    ];

    int currentStep = 0;
    if (status == 'assigned') currentStep = 1;
    if (status == 'accepted') currentStep = 2;
    if (status == 'on_the_way') currentStep = 3;
    if (status == 'arrived') currentStep = 4;
    if (status == 'in_progress') currentStep = 5;
    if (status == 'completed') currentStep = 6;
    if (status == 'cancelled') currentStep = -1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suivi de l\'intervention',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (status == 'cancelled')
              _buildCancelledState()
            else
              Column(
                children: List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isCompleted = index < currentStep;
                  final isCurrent = index == currentStep;
                  final isLast = index == steps.length - 1;

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Icône
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCompleted || isCurrent
                                  ? const Color(0xFF0a543d)
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCompleted || isCurrent
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrent
                                        ? const Color(0xFF0a543d)
                                        : Colors.grey.shade500,
                                    fontWeight: isCurrent
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Check
                          if (isCompleted)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF0a543d),
                              size: 24,
                            ),
                        ],
                      ),

                      // Ligne de connexion
                      if (!isLast)
                        Container(
                          margin: const EdgeInsets.only(
                              left: 25, top: 8, bottom: 8),
                          width: 2,
                          height: 30,
                          color: isCompleted
                              ? const Color(0xFF0a543d)
                              : Colors.grey.shade300,
                        ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intervention annulée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette intervention a été annulée',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_intervention['intervention_type'] != null)
              _buildInfoRow(
                Icons.category,
                'Type',
                _getTypeLabel(_intervention['intervention_type']),
              ),
            if (_intervention['intervention_type'] != null &&
                _intervention['intervention_type']
                    .toString()
                    .toLowerCase()
                    .contains('installation') &&
                _intervention['climatiseur_type'] != null)
              _buildInfoRow(
                Icons.ac_unit,
                'Modèle',
                _intervention['climatiseur_type'],
              ),
            _buildInfoRow(
              Icons.format_list_numbered,
              'Nombre d\'équipements',
              '${_intervention['equipment_count'] ?? 1}',
            ),
            if (_intervention['address'] != null)
              _buildInfoRow(
                Icons.location_on,
                'Adresse',
                _intervention['address'],
              ),
            _buildInfoRow(
              Icons.info_outline,
              'Statut',
              _getStatusLabel(_intervention['status'] ?? 'pending'),
              color: _getStatusColor(_intervention['status'] ?? 'pending'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            Text(
              _intervention['description'] ?? 'Aucune description',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard() {
    final technician = _intervention['technician'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technicien assigné',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0a543d),
                  child: Text(
                    '${technician['first_name']?[0] ?? ''}${technician['last_name']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${technician['first_name']} ${technician['last_name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (technician['phone'] != null &&
                          technician['phone'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              technician['phone'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (technician['phone'] != null &&
                    technician['phone'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFF0a543d)),
                    onPressed: () async {
                      final Uri phoneUri =
                          Uri(scheme: 'tel', path: technician['phone']);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceOfferCard() {
    final offer = _intervention['maintenance_offer'];
    if (offer == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0a543d).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Color(0xFF0a543d),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Offre d\'entretien',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                offer['title'] ?? 'Offre',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0a543d),
                ),
              ),
              if (offer['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  offer['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${offer['price']?.toString() ?? '0'} F CFA',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatesCard(DateTime? scheduledDate, DateTime? completedDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (scheduledDate != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Date prévue',
                '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} à ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
              ),
            if (completedDate != null)
              _buildInfoRow(
                Icons.check_circle_outline,
                'Date de fin',
                '${completedDate.day}/${completedDate.month}/${completedDate.year} à ${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'low':
        color = Colors.blue;
        label = 'Basse';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Moyenne';
        break;
      case 'high':
        color = Colors.red;
        label = 'Haute';
        break;
      case 'critical':
        color = Colors.purple;
        label = 'Critique';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImagesCard() {
    final images = _intervention['images'] as List;
    final baseUrl = 'http://10.0.2.2:3000'; // Émulateur Android

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: Color(0xFF0a543d)),
                const SizedBox(width: 8),
                Text(
                  'Photos (${images.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final imageUrl = '$baseUrl${image['image_url']}';

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        // Afficher l'image en grand
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error,
                                          size: 50, color: Colors.red),
                                    );
                                  },
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Erreur',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'accepted':
        return Colors.green.shade700;
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
        return Colors.teal;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente d\'assignation';
      case 'assigned':
        return 'Technicien assigné';
      case 'accepted':
        return 'Acceptée par le technicien';
      case 'on_the_way':
        return 'Technicien en route';
      case 'arrived':
        return 'Technicien sur place';
      case 'in_progress':
        return 'En cours d\'intervention';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'maintenance':
        return 'Maintenance';
      case 'repair':
        return 'Dépannage';
      case 'installation':
        return 'Installation';
      default:
        return type;
    }
  }

  Widget _buildRatingSection() {
    final hasRating = _intervention['rating'] != null;
    final rating = _intervention['rating'] ?? 0;
    final review = _intervention['review'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Évaluation du service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasRating) ...[
              // Afficher la note existante
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        );
                      }),
                    ),
                    if (review.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        review,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Merci pour votre évaluation !',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else ...[
              // Formulaire pour ajouter une note
              Text(
                'Comment évalueriez-vous le service du technicien ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0a543d).withOpacity(0.1),
                      const Color(0xFF0f7d59).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0a543d).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Color(0xFF0a543d),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Votre avis compte !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aidez-nous à améliorer notre service',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Évaluer le technicien'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Vérifier et afficher le popup d'évaluation si nécessaire
  void _checkAndShowRatingDialog() {
    final status = _intervention['status'];
    final hasRating = _intervention['rating'] != null;

    // Afficher le popup seulement si l'intervention est terminée et pas encore évaluée
    if (status == 'completed' && !hasRating && mounted) {
      // Attendre un peu pour que l'écran soit bien chargé
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          print('⭐ Affichage automatique du popup d\'évaluation');
          _showRatingDialog();
        }
      });
    }
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header avec gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Évaluer le service',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Votre avis nous aide à améliorer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Note globale',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    index < selectedRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                          if (selectedRating > 0) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _getRatingText(selectedRating),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0a543d),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            'Commentaire (optionnel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reviewController,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText: 'Partagez votre expérience...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0a543d),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer avec boutons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0a543d).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: selectedRating > 0
                                  ? () => _submitRating(
                                        dialogContext,
                                        selectedRating,
                                        reviewController.text,
                                      )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Envoyer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Correct';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return '';
    }
  }

  Future<void> _submitRating(
      BuildContext dialogContext, int rating, String review) async {
    // Sauvegarder si un rating existait AVANT la soumission
    final hadRatingBefore = _intervention['rating'] != null;

    try {
      // Fermer le clavier
      FocusScope.of(dialogContext).unfocus();

      // Afficher un loader
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0a543d)),
        ),
      );

      await _apiService.rateIntervention(
        _intervention['id'],
        rating,
        review.trim(),
      );

      // Fermer le loader
      if (mounted) Navigator.of(dialogContext).pop();

      // Fermer le dialog de notation
      if (mounted) Navigator.of(dialogContext).pop();

      // Rafraîchir les données
      await _refreshIntervention();

      // Afficher un message de succès
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Merci pour votre évaluation !',
          emoji: '⭐',
        );
      }
    } catch (e) {
      // Fermer le loader
      if (mounted) Navigator.of(dialogContext).pop();

      // Vérifier si le message d'erreur indique que c'est déjà évalué
      final errorMessage = e.toString().toLowerCase();
      final isAlreadyRated = errorMessage.contains('déjà été évaluée') ||
          errorMessage.contains('already rated');

      if (isAlreadyRated || hadRatingBefore) {
        // Rafraîchir les données pour afficher l'évaluation existante
        await _refreshIntervention();

        // Fermer le dialog de notation
        if (mounted) Navigator.of(dialogContext).pop();

        if (mounted) {
          SnackBarHelper.showWarning(
            context,
            'Cette intervention a déjà été évaluée',
          );
        }
      } else {
        // Erreur normale - afficher l'erreur
        if (mounted) {
          SnackBarHelper.showError(
            dialogContext,
            'Erreur: $e',
          );
        }
      }
    }
  }
}
