import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/screens/technician/create_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/view_report_screen.dart';
import '../../utils/snackbar_helper.dart';

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

  // Étapes du workflow
  final List<Map<String, dynamic>> _workflowSteps = [
    {'status': 'assigned', 'label': 'Assignée', 'icon': Icons.assignment},
    {'status': 'accepted', 'label': 'Acceptée', 'icon': Icons.check_circle},
    {'status': 'on_the_way', 'label': 'En route', 'icon': Icons.directions_car},
    {'status': 'arrived', 'label': 'Arrivé', 'icon': Icons.location_on},
    {'status': 'in_progress', 'label': 'En cours', 'icon': Icons.build},
    {'status': 'completed', 'label': 'Terminée', 'icon': Icons.done_all},
  ];

  @override
  void initState() {
    super.initState();
    _intervention = Map.from(widget.intervention);
    print('📍 initState - Intervention ${_intervention['id']} chargée');
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
    final status = _intervention['status'];
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
          _intervention['status'] = response['data']['status'];
          _isLoading = false;
        });

        SnackBarHelper.showSuccess(
            context, response['message'] ?? 'Action effectuée avec succès',
            emoji: '✓');

        // Si l'intervention est terminée, proposer de créer un rapport
        if (_intervention['status'] == 'completed') {
          // Retourner true pour indiquer que l'intervention a été modifiée
          Navigator.pop(context, true);
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReportScreen(
          intervention: _intervention,
        ),
      ),
    );

    // Si le rapport a été soumis avec succès, recharger l'intervention
    if (result == true && mounted) {
      await _loadInterventionDetails();
    }
  }

  Future<void> _loadInterventionDetails() async {
    // Recharger les détails de l'intervention depuis l'API
    // pour mettre à jour report_submitted_at
    try {
      print('🔄 Rechargement intervention ID: ${_intervention['id']}');

      final response = await _apiService.getTechnicianInterventions();

      if (mounted && response['data'] != null) {
        final interventions = response['data'] as List;
        print('📋 ${interventions.length} interventions récupérées');

        final updatedIntervention = interventions.firstWhere(
          (i) => i['id'] == _intervention['id'],
          orElse: () {
            print(
                '⚠️ Intervention ${_intervention['id']} non trouvée dans la liste');
            return _intervention;
          },
        );

        print('✅ Intervention mise à jour:');
        print(
            '   - report_submitted_at: ${updatedIntervention['report_submitted_at']}');
        print(
            '   - report_data: ${updatedIntervention['report_data'] != null ? "Présent" : "Absent"}');

        if (mounted) {
          setState(() {
            _intervention = updatedIntervention;
          });
          print('✅ setState appelé, intervention mise à jour');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du rechargement: $e');
    }
  }

  Future<void> _viewReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewReportScreen(
          intervention: _intervention,
        ),
      ),
    );
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
    final status = _intervention['status'];

    switch (status) {
      case 'assigned':
      case 'pending':
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('accept'),
          icon: const Icon(Icons.check_circle),
          label: const Text('Accepter l\'intervention'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0a543d),
            minimumSize: const Size(double.infinity, 50),
          ),
        );

      case 'accepted':
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('on_the_way'),
          icon: const Icon(Icons.directions_car),
          label: const Text('Je suis en route'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
          ),
        );

      case 'on_the_way':
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('arrived'),
          icon: const Icon(Icons.location_on),
          label: const Text('Je suis arrivé'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
        );

      case 'arrived':
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('start'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Démarrer l\'intervention'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0a543d),
            minimumSize: const Size(double.infinity, 50),
          ),
        );

      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performAction('complete'),
          icon: const Icon(Icons.done),
          label: const Text('Terminer l\'intervention'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
          ),
        );

      case 'completed':
        // Vérifier si un rapport a déjà été soumis
        print(
            '🔍 Vérification rapport pour intervention ${_intervention['id']}');
        print(
            '   - report_submitted_at: ${_intervention['report_submitted_at']}');
        print('   - report_data: ${_intervention['report_data']}');

        final hasReport = _intervention['report_submitted_at'] != null;
        print('   - hasReport: $hasReport');

        if (hasReport) {
          // Si rapport déjà soumis, afficher bouton "Voir le rapport"
          return ElevatedButton.icon(
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
          return ElevatedButton.icon(
            onPressed: _isLoading ? null : _goToReport,
            icon: const Icon(Icons.description),
            label: const Text('Créer le rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
              minimumSize: const Size(double.infinity, 50),
            ),
          );
        }

      default:
        return const SizedBox.shrink();
    }
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
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Client',
              _intervention['customer'] ?? 'Non spécifié',
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
