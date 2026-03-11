import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_cache_service.dart';
import '../../providers/sync_provider.dart';

class DiagnosticReportScreen extends StatefulWidget {
  final int interventionId;
  final Map<String, dynamic> intervention;

  const DiagnosticReportScreen({
    Key? key,
    required this.interventionId,
    required this.intervention,
  }) : super(key: key);

  @override
  State<DiagnosticReportScreen> createState() => _DiagnosticReportScreenState();
}

class _DiagnosticReportScreenState extends State<DiagnosticReportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form controllers
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // Parts list
  List<Map<String, dynamic>> _partsList = [];

  // Selected values
  String _selectedUrgency = 'medium';
  final List<String> _urgencyLevels = ['low', 'medium', 'high', 'critical'];

  @override
  void dispose() {
    _problemController.dispose();
    _solutionController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPart() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController();

        return AlertDialog(
          title: const Text('Ajouter une pièce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la pièce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  setState(() {
                    _partsList.add({
                      'name': nameController.text,
                      'quantity': int.parse(quantityController.text),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removePart(int index) {
    setState(() {
      _partsList.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final connectivityService = ConnectivityService();
    final cacheService = LocalCacheService();

    final diagnosticData = {
      'intervention_id': widget.interventionId,
      'problem_description': _problemController.text,
      'recommended_solution': _solutionController.text,
      'parts_needed': _partsList,
      'labor_cost': 0,
      'estimated_total': 0,
      'urgency_level': _selectedUrgency,
      'estimated_duration': _durationController.text,
      'photos': [],
      'notes': _notesController.text,
    };

    try {
      // Vérifier la connectivité
      if (!connectivityService.isConnected) {
        // Mode hors ligne - mettre en queue
        print('📴 Mode hors ligne - Mise en queue du rapport diagnostic');
        await cacheService.addToSyncQueue(
          'diagnostic_report_upload',
          widget.interventionId,
          diagnosticData,
        );

        // Notifier le SyncProvider
        if (mounted) {
          context.read<SyncProvider>().addToQueue(
                'diagnostic_report_upload',
                widget.interventionId,
                diagnosticData,
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Rapport sauvegardé hors ligne. Sera synchronisé au retour du réseau.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // Mode en ligne - soumettre directement
      final apiService = ApiService();
      final response = await apiService.post(
        '/diagnostic-reports',
        diagnosticData,
      );

      if (response['message'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // En cas d'erreur réseau, mettre en queue
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        print('📴 Erreur réseau - Mise en queue du rapport diagnostic');
        await cacheService.addToSyncQueue(
          'diagnostic_report_upload',
          widget.interventionId,
          diagnosticData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Erreur réseau. Rapport sauvegardé et sera synchronisé automatiquement.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intervention info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervention #${widget.interventionId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.intervention['title'] ?? 'Sans titre',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.intervention['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Problem description
            const Text(
              'Description du problème *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _problemController,
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème constaté...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Recommended solution
            const Text(
              'Solution recommandée *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _solutionController,
              decoration: const InputDecoration(
                hintText: 'Quelle solution proposez-vous ?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Parts needed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pièces nécessaires',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_partsList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aucune pièce ajoutée. Cliquez sur "Ajouter" pour ajouter des pièces.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._partsList.asMap().entries.map((entry) {
                final index = entry.key;
                final part = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(part['name']),
                    subtitle: Text('Quantité: ${part['quantity']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePart(index),
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 20),

            // Urgency level
            const Text(
              'Niveau d\'urgence *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUrgency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _urgencyLevels.map((level) {
                IconData icon;
                Color color;
                String label;
                switch (level) {
                  case 'low':
                    icon = Icons.arrow_downward;
                    color = Colors.green;
                    label = 'Faible';
                    break;
                  case 'medium':
                    icon = Icons.remove;
                    color = Colors.orange;
                    label = 'Moyen';
                    break;
                  case 'high':
                    icon = Icons.arrow_upward;
                    color = Colors.deepOrange;
                    label = 'Élevé';
                    break;
                  case 'critical':
                    icon = Icons.warning;
                    color = Colors.red;
                    label = 'Critique';
                    break;
                  default:
                    icon = Icons.help;
                    color = Colors.grey;
                    label = level;
                }
                return DropdownMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedUrgency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Estimated duration
            const Text(
              'Durée estimée *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                hintText: 'Ex: 2-3 heures',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Notes
            const Text(
              'Notes additionnelles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Informations supplémentaires...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Soumettre le rapport',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
