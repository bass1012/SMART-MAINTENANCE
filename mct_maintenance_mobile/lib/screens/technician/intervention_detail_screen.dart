import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/screens/technician/create_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/diagnostic_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/view_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/view_diagnostic_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/split_scan_screen.dart';
import 'package:mct_maintenance_mobile/models/split.dart';
import '../../utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = false;
  late Map<String, dynamic> _intervention;

  // Split scanné pour cette intervention
  SplitScanResult? _scannedSplit;
  bool _splitRequired = true; // Le scan est obligatoire par défaut

  // Étapes du workflow - version complète (sera filtrée selon le type)
  final List<Map<String, dynamic>> _allWorkflowSteps = [
    {'status': 'assigned', 'label': 'Assignée', 'icon': Icons.assignment},
    {'status': 'accepted', 'label': 'Acceptée', 'icon': Icons.check_circle},
    {'status': 'on_the_way', 'label': 'En route', 'icon': Icons.directions_car},
    {'status': 'arrived', 'label': 'Arrivé', 'icon': Icons.location_on},
    {'status': 'in_progress', 'label': 'En cours', 'icon': Icons.build},
    {'status': 'completed', 'label': 'Terminée', 'icon': Icons.done_all},
    {
      'status': 'diagnostic_submitted',
      'label': 'Diagnostic soumis',
      'icon': Icons.assignment_turned_in
    },
    {
      'status': 'execution_confirmed',
      'label': 'Exécution confirmée',
      'icon': Icons.verified
    },
  ];

  // Retourne les étapes du workflow filtrées selon le type d'intervention
  List<Map<String, dynamic>> get _workflowSteps {
    final interventionType =
        _intervention['intervention_type']?.toString().toLowerCase() ?? '';
    final status = _intervention['status']?.toString().toLowerCase() ?? '';

    // Les interventions de type diagnostic ont l'étape "Diagnostic soumis"
    final isDiagnostic = interventionType.contains('diagnostic') ||
        interventionType.contains('depannage') ||
        interventionType.contains('dépannage') ||
        interventionType.contains('reparation') ||
        interventionType.contains('réparation') ||
        interventionType.contains('urgence');

    // Exécution (après acceptation du devis) - workflow simplifié
    final isExecution = interventionType.contains('execution') &&
        (status == 'execution_confirmed' ||
            status == 'in_progress' ||
            status == 'completed');

    if (isExecution) {
      // Workflow exécution: technicien doit cliquer "Exécuter" puis "Terminer"
      return [
        {
          'status': 'execution_confirmed',
          'label': 'Exécution confirmée',
          'icon': Icons.verified
        },
        {'status': 'in_progress', 'label': 'En cours', 'icon': Icons.build},
        {'status': 'completed', 'label': 'Terminée', 'icon': Icons.done_all},
      ];
    } else if (isDiagnostic) {
      // Workflow diagnostic complet
      return _allWorkflowSteps
          .where((step) => step['status'] != 'execution_confirmed')
          .toList();
    } else {
      // Workflow standard sans diagnostic ni exécution
      return _allWorkflowSteps
          .where((step) =>
              step['status'] != 'diagnostic_submitted' &&
              step['status'] != 'execution_confirmed')
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _intervention = Map.from(widget.intervention);
    print('📍 initState - Intervention ${_intervention['id']} chargée');
    print('   🔍 DEBUG - customer: ${_intervention['customer']}');
    print('   🔍 DEBUG - date: ${_intervention['date']}');
    print('   🔍 DEBUG - time: ${_intervention['time']}');
    print('   🔍 DEBUG - type: ${_intervention['type']}');
    print(
        '   🔍 DEBUG - climatiseur_type: ${_intervention['climatiseur_type']}');
    print('   🔍 DEBUG - Keys disponibles: ${_intervention.keys.toList()}');
    // Recharger depuis le cache pour avoir le statut le plus récent
    _loadInterventionFromCache();
  }

  @override
  void didUpdateWidget(InterventionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // NE PAS mettre à jour depuis widget.intervention si on a déjà des données fraîches
    // Le parent peut avoir des données en cache plus anciennes
    print(
        '⚠️ didUpdateWidget appelé - IGNORÉ pour préserver les données fraîches');
  }

  int _getCurrentStepIndex() {
    if (_intervention == null) return 0;

    final status = _intervention['status'];
    if (status == null) return 0;

    final index = _workflowSteps.indexWhere((step) => step['status'] == status);
    return index >= 0 ? index : 0;
  }

  Future<void> _performAction(String action) async {
    setState(() => _isLoading = true);

    try {
      final interventionId = _intervention['id'];
      Map<String, dynamic> response;

      switch (action) {
        case 'accept':
          response = await _apiService.acceptIntervention(interventionId);
          break;
        case 'on_the_way':
          response = await _apiService.markInterventionOnTheWay(interventionId);
          break;
        case 'arrived':
          response = await _apiService.markInterventionArrived(interventionId);
          break;
        case 'start':
        case 'in_progress':
          response = await _apiService.startIntervention(interventionId);
          break;
        case 'complete':
          response = await _apiService.completeIntervention(interventionId);
          break;
        default:
          throw Exception('Action inconnue');
      }

      if (mounted) {
        // Mettre à jour l'intervention localement
        setState(() {
          // Mapper l'action vers le statut correspondant
          switch (action) {
            case 'accept':
              _intervention['status'] = 'accepted';
              break;
            case 'on_the_way':
              _intervention['status'] = 'on_the_way';
              break;
            case 'arrived':
              _intervention['status'] = 'arrived';
              break;
            case 'start':
            case 'in_progress':
              _intervention['status'] = 'in_progress';
              break;
            case 'complete':
              _intervention['status'] = 'completed';
              break;
          }
          // Surcharger avec le statut API si disponible
          if (response['data'] != null && response['data']['status'] != null) {
            _intervention['status'] = response['data']['status'];
          }
          _isLoading = false;
        });

        SnackBarHelper.showSuccess(
            context, response['message'] ?? 'Action effectuée avec succès',
            emoji: '✓');

        // Si l'intervention est terminée, proposer de créer un rapport
        if (_intervention['status'] == 'completed') {
          // Afficher un dialogue pour proposer de créer le rapport
          final createReport = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Intervention terminée'),
              content: const Text(
                'L\'intervention est maintenant terminée. Voulez-vous créer le rapport maintenant ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Plus tard'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Créer le rapport'),
                ),
              ],
            ),
          );

          if (createReport == true && mounted) {
            // Aller à l'écran de création de rapport
            await _goToReport();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _goToReport() async {
    // Déterminer le type d'intervention
    final interventionType = _intervention['intervention_type'] ?? '';

    Widget reportScreen;
    if (interventionType == 'diagnostic') {
      // Utiliser le nouveau écran de diagnostic
      reportScreen = DiagnosticReportScreen(
        interventionId: _intervention['id'],
        intervention: _intervention,
      );
    } else {
      // Utiliser l'ancien écran pour maintenance et autres types
      reportScreen = CreateReportScreen(
        intervention: _intervention,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => reportScreen),
    );

    // Si le rapport a été soumis avec succès, recharger l'intervention
    if (result == true && mounted) {
      // Forcer un rechargement complet depuis l'API pour obtenir le rapport soumis
      print('🔄 Rapport soumis, rechargement complet de l\'intervention...');
      setState(() => _isLoading = true);

      try {
        // Recharger depuis l'API (pas depuis le cache)
        final response =
            await _apiService.getInterventionById(_intervention['id']);

        if (response['success'] && response['data'] != null) {
          final updatedIntervention = response['data'];
          print('✅ Intervention rechargée:');
          print('   - status: ${updatedIntervention['status']}');
          print(
              '   - report_submitted_at: ${updatedIntervention['report_submitted_at']}');

          setState(() {
            _intervention = updatedIntervention;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('❌ Erreur rechargement: $e');
        setState(() => _isLoading = false);
        // Fallback sur le cache
        await _loadInterventionFromCache();
      }
    }
  }

  /// Ouvre l'écran de scan QR pour identifier le split
  Future<void> _scanSplitQR() async {
    // Récupérer le customer_id si disponible (peut être String ou int)
    // Note: customer peut être une String (nom) ou un objet {id, name, ...}
    int? customerId;
    final customerData = _intervention['customer'];
    if (customerData != null && customerData is Map) {
      final rawId = customerData['id'] ?? customerData['user_id'];
      if (rawId != null) {
        customerId = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
    }
    // Essayer aussi avec customer_id directement sur l'intervention
    if (customerId == null && _intervention['customer_id'] != null) {
      final rawId = _intervention['customer_id'];
      customerId = rawId is int ? rawId : int.tryParse(rawId.toString());
    }

    // Récupérer l'intervention_id (peut être String ou int)
    final rawInterventionId = _intervention['id'];
    final int interventionId = rawInterventionId is int
        ? rawInterventionId
        : int.parse(rawInterventionId.toString());

    final result = await Navigator.push<SplitScanResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SplitScanScreen(
          interventionId: interventionId,
          customerId: customerId,
          onSplitScanned: (scanResult) {
            print('✅ Split scanné: ${scanResult.split.splitCode}');
          },
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _scannedSplit = result;
        // Mettre à jour l'intervention avec le split_id
        _intervention['split_id'] = result.split.id;
      });

      SnackBarHelper.showSuccess(
        context,
        'Split identifié: ${result.split.displayName}',
        emoji: '✅',
      );
    }
  }

  /// Widget affichant les informations du split scanné
  Widget _buildScannedSplitInfo() {
    if (_scannedSplit == null) return const SizedBox.shrink();

    final split = _scannedSplit!.split;
    final offer = _scannedSplit!.activeOffer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Split identifié',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const Spacer(),
              // Bouton pour rescanner
              TextButton.icon(
                onPressed: _scanSplitQR,
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Changer'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Infos du split
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.ac_unit, color: Color(0xFF0a543d)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      split.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${split.location ?? "Non défini"} • ${split.formattedPower}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      split.splitCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Offre active
          if (offer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Offre: ${offer.title}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber,
                      size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Aucune offre active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadInterventionFromCache() async {
    // Recharger depuis le cache pour avoir le statut le plus récent
    try {
      print(
          '🔄 Rechargement intervention depuis cache ID: ${_intervention['id']}');

      final response = await _apiService.getTechnicianInterventions();

      if (mounted && response['data'] != null) {
        final interventions = (response['data'] as List)
            .where((i) => i != null) // Filtrer les items null
            .toList();
        print(
            '📋 ${interventions.length} interventions récupérées (fromCache: ${response['fromCache'] ?? false})');

        final updatedIntervention = interventions.firstWhere(
          (i) => i['id'] == _intervention['id'],
          orElse: () {
            print(
                '⚠️ Intervention ${_intervention['id']} non trouvée dans la liste');
            return _intervention;
          },
        );

        print('✅ Intervention mise à jour depuis cache:');
        print('   - status: ${updatedIntervention['status']}');
        print(
            '   - report_submitted_at: ${updatedIntervention['report_submitted_at']}');
        print(
            '   - report_data: ${updatedIntervention['report_data'] != null ? "Présent" : "Absent"}');

        if (mounted) {
          setState(() {
            _intervention = updatedIntervention;
          });
          print(
              '✅ setState appelé, intervention mise à jour avec statut: ${_intervention['status']}');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du rechargement depuis cache: $e');
    }
  }

  Future<void> _loadInterventionDetails() async {
    // Alias pour compatibilité
    await _loadInterventionFromCache();
  }

  Future<void> _viewReport() async {
    // Vérifier le type d'intervention pour utiliser le bon écran
    final interventionType = _intervention['intervention_type'] ?? '';

    if (interventionType == 'diagnostic') {
      // Pour les diagnostics, utiliser ViewDiagnosticReportScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewDiagnosticReportScreen(
            intervention: _intervention,
          ),
        ),
      );
    } else {
      // Pour les interventions standard, utiliser ViewReportScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewReportScreen(
            intervention: _intervention,
          ),
        ),
      );
    }
  }

  Widget _buildStepper() {
    final currentStep = _getCurrentStepIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_workflowSteps.length, (index) {
            final step = _workflowSteps[index];
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return _buildStepItem(
              step['label'],
              step['icon'],
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: index == _workflowSteps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    String label,
    IconData icon, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final Color color = isCompleted
        ? const Color(0xFF0a543d)
        : isCurrent
            ? Colors.orange
            : Colors.grey[300]!;

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted || isCurrent ? Colors.white : color,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted || isCurrent ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_intervention == null) {
      return const SizedBox.shrink();
    }

    final status = _intervention['status'];
    if (status == null) {
      return const SizedBox.shrink();
    }

    // Détermine si on peut afficher le bouton d'itinéraire
    final canShowMapButton = [
      'accepted',
      'on_the_way',
      'arrived',
      'in_progress',
      'execution_confirmed'
    ].contains(status);

    // Bouton principal selon le statut
    Widget? mainButton;

    switch (status) {
      case 'assigned':
      case 'pending':
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('accept'),
          icon: const Icon(Icons.check_circle),
          label: const Text('Accepter l\'intervention'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0a543d),
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      case 'execution_confirmed':
        // Exécution confirmée: technicien doit démarrer l'exécution
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('in_progress'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Exécuter la tâche'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0a543d),
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      case 'accepted':
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('on_the_way'),
          icon: const Icon(Icons.directions_car),
          label: const Text('Je suis en route'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      case 'on_the_way':
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('arrived'),
          icon: const Icon(Icons.location_on),
          label: const Text('Je suis arrivé'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      case 'arrived':
        // COMMENTÉ TEMPORAIREMENT POUR LES TESTS - Scanner QR désactivé
        // TODO: Réactiver le scan QR plus tard
        /*
        // Si le split n'a pas encore été scanné, afficher le bouton de scan
        if (_scannedSplit == null && _intervention['split_id'] == null) {
          mainButton = Column(
            children: [
              // Message d'avertissement
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Veuillez scanner le QR code du split avant de démarrer l\'intervention',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton de scan
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _scanSplitQR,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner le Split'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          );
        } else {
        */
        // Split déjà scanné, afficher les infos et le bouton démarrer
        mainButton = Column(
          children: [
            // Afficher les infos du split scanné
            if (_scannedSplit != null) _buildScannedSplitInfo(),
            if (_scannedSplit != null) const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _performAction('start'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer l\'intervention'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        );
        // } // Fin du bloc commenté
        break;

      case 'in_progress':
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('complete'),
          icon: const Icon(Icons.done),
          label: const Text('Terminer l\'intervention'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      case 'completed':
        // Vérifier si un rapport a déjà été soumis
        final hasReport = _intervention['report_submitted_at'] != null;

        if (hasReport) {
          // Si rapport déjà soumis, afficher bouton "Voir le rapport"
          mainButton = ElevatedButton.icon(
            onPressed: _isLoading ? null : _viewReport,
            icon: const Icon(Icons.visibility),
            label: const Text('Voir le rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
            ),
          );
        } else {
          // Sinon, afficher bouton "Créer le rapport"
          mainButton = ElevatedButton.icon(
            onPressed: _isLoading ? null : _goToReport,
            icon: const Icon(Icons.description),
            label: const Text('Créer le rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
              minimumSize: const Size(double.infinity, 50),
            ),
          );
        }
        break;

      case 'diagnostic_submitted':
        // Rapport de diagnostic soumis - afficher bouton "Voir le rapport"
        mainButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : _viewReport,
          icon: const Icon(Icons.visibility),
          label: const Text('Voir le rapport de diagnostic'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
          ),
        );
        break;

      default:
        break;
    }

    // Si pas de bouton principal, retourner widget vide
    if (mainButton == null) {
      return const SizedBox.shrink();
    }

    // Si on ne peut pas afficher le bouton d'itinéraire, retourner juste le bouton principal
    if (!canShowMapButton) {
      return mainButton;
    }

    // Sinon, afficher le bouton principal ET le bouton d'itinéraire
    return Column(
      children: [
        mainButton,
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.map),
          label: const Text('Voir l\'itinéraire'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0a543d),
            side: const BorderSide(color: Color(0xFF0a543d), width: 2),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticMap() {
    final address = _intervention['address'];
    if (address == null || address.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: _openMap, // Cliquer sur la carte ouvre Google Maps
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0a543d),
                const Color(0xFF0a543d).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern de fond pour simuler une carte
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: MapPatternPainter(),
                  ),
                ),
              ),
              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icône de localisation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF0a543d),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Adresse et bouton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Lieu d\'intervention',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Icône de navigation
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Color(0xFF0a543d),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _intervention['title'] ?? 'Intervention',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Carte statique de localisation
            if (_intervention['address'] != null &&
                _intervention['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStaticMap(),
            ],
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Client',
              _intervention['customer'] is Map
                  ? '${_intervention['customer']['first_name'] ?? ''} ${_intervention['customer']['last_name'] ?? ''}'
                      .trim()
                  : (_intervention['customer']?.toString() ?? 'Non spécifié'),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              _intervention['address'] ?? 'Non spécifiée',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              '${_intervention['date']} à ${_intervention['time']}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.category,
              'Type',
              _intervention['type'] ?? 'Service',
            ),
            if (_intervention['type'] != null &&
                _intervention['type']
                    .toString()
                    .toLowerCase()
                    .contains('installation') &&
                _intervention['climatiseur_type'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.ac_unit,
                'Modèle',
                _intervention['climatiseur_type'],
              ),
            ],
            if (_intervention['description'] != null &&
                _intervention['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _intervention['description'],
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ouvre l'application de carte (Google Maps ou Apple Maps) avec l'itinéraire
  Future<void> _openMap() async {
    final address = _intervention['address'];

    if (address == null || address.toString().isEmpty) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Adresse non disponible');
      }
      return;
    }

    try {
      // Encode l'adresse pour l'URL
      final encodedAddress = Uri.encodeComponent(address);

      Uri mapUrl;

      if (Platform.isAndroid) {
        // Sur Android, utiliser le schéma geo: qui ouvre l'app de carte par défaut
        // ou l'URL Google Maps simplifiée avec search au lieu de dir
        mapUrl = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      } else {
        // Sur iOS, utiliser l'URL Apple Maps
        mapUrl = Uri.parse('https://maps.apple.com/?q=$encodedAddress');
      }

      print('🗺️ Ouverture de la carte avec URL: $mapUrl');

      // Essayer de lancer l'URL
      final canLaunch = await canLaunchUrl(mapUrl);
      print('🗺️ canLaunchUrl result: $canLaunch');

      if (canLaunch) {
        final launched = await launchUrl(
          mapUrl,
          mode: LaunchMode.externalApplication,
        );
        print('🗺️ launchUrl result: $launched');

        if (!launched && mounted) {
          SnackBarHelper.showError(
            context,
            'Impossible d\'ouvrir l\'application de carte',
          );
        }
      } else {
        // Tentative avec le schéma geo: comme fallback sur Android
        if (Platform.isAndroid) {
          final geoUrl = Uri.parse('geo:0,0?q=$encodedAddress');
          print('🗺️ Tentative avec geo: $geoUrl');

          if (await canLaunchUrl(geoUrl)) {
            await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            SnackBarHelper.showError(
              context,
              'Impossible d\'ouvrir l\'application de carte',
            );
          }
        } else if (mounted) {
          SnackBarHelper.showError(
            context,
            'Impossible d\'ouvrir l\'application de carte',
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de la carte: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de l\'ouverture de l\'itinéraire',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'intervention'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  _buildStepper(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildActionButton(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// Painter pour créer un pattern de carte en arrière-plan
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Dessiner une grille pour simuler une carte
    const spacing = 30.0;

    // Lignes verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Ajouter quelques "routes" diagonales pour plus de réalisme
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
