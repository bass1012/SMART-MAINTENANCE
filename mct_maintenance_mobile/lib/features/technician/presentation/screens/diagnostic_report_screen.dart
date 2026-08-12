import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:mct_maintenance_mobile/services/connectivity_service.dart';
import 'package:mct_maintenance_mobile/services/local_cache_service.dart';
import 'package:mct_maintenance_mobile/providers/sync_provider.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';

class DiagnosticReportScreen extends StatefulWidget {
  final int interventionId;
  final Map<String, dynamic> intervention;

  const DiagnosticReportScreen({
    super.key,
    required this.interventionId,
    required this.intervention,
  });

  @override
  State<DiagnosticReportScreen> createState() => _DiagnosticReportScreenState();
}

class _DiagnosticReportScreenState extends State<DiagnosticReportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Multi-équipements
  final List<Map<String, dynamic>> _equipments = [];

  // Controllers globaux
  final _problemController = TextEditingController();
  final _materialsNeededController = TextEditingController();
  final _solutionController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // Pièces nécessaires (liste détaillée optionnelle)
  final List<Map<String, dynamic>> _partsList = [];

  // Urgence
  String _selectedUrgency = 'medium';
  final List<String> _urgencyLevels = ['low', 'medium', 'high', 'critical'];

  final List<String> _equipmentTypes = [
    'Allège',
    'Armoire',
    'Cassette',
    'Gainable',
    'Mural',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingDiagnosticReport();
    if (_equipments.isEmpty) {
      _addEquipment();
    }
  }

  void _loadExistingDiagnosticReport() {
    Map<String, dynamic> diag = {};

    if (widget.intervention['diagnostic_report'] != null) {
      final r = widget.intervention['diagnostic_report'];
      if (r is Map) diag = Map<String, dynamic>.from(r);
      if (r is String) {
        try {
          diag = json.decode(r);
        } catch (_) {}
      }
    } else if (widget.intervention['diagnosticReports'] is List &&
        (widget.intervention['diagnosticReports'] as List).isNotEmpty) {
      final first = (widget.intervention['diagnosticReports'] as List)[0];
      if (first is Map) diag = Map<String, dynamic>.from(first);
    } else if (widget.intervention['report_data'] != null) {
      final r = widget.intervention['report_data'];
      if (r is Map) diag = Map<String, dynamic>.from(r);
      if (r is String) {
        try {
          diag = json.decode(r);
        } catch (_) {}
      }
    } else {
      diag = widget.intervention;
    }

    if (diag.isEmpty) return;

    final problem = diag['problem_description'] ?? diag['work_description'] ?? diag['description'];
    if (problem != null) _problemController.text = problem.toString();

    final materials = diag['materials_needed'];
    if (materials != null) _materialsNeededController.text = materials.toString();

    final solution = diag['recommended_solution'];
    if (solution != null) _solutionController.text = solution.toString();

    final duration = diag['estimated_duration'] ?? diag['duration'];
    if (duration != null) _durationController.text = duration.toString();

    final notes = diag['notes'] ?? diag['observations'];
    if (notes != null) _notesController.text = notes.toString();

    final urgency = diag['urgency_level'];
    if (urgency != null && _urgencyLevels.contains(urgency.toString())) {
      _selectedUrgency = urgency.toString();
    }

    // Pièces
    final partsData = diag['parts_needed'] ?? diag['spare_parts'] ?? diag['materials_used'];
    if (partsData != null) {
      List parsedParts = [];
      if (partsData is String) {
        try {
          parsedParts = json.decode(partsData);
        } catch (_) {}
      } else if (partsData is List) {
        parsedParts = partsData;
      }
      _partsList.clear();
      for (var item in parsedParts) {
        if (item is Map) {
          _partsList.add(Map<String, dynamic>.from(item));
        } else if (item != null && item.toString().isNotEmpty) {
          _partsList.add({'name': item.toString(), 'quantity': 1});
        }
      }
    }

    // Équipements
    final eqData = diag['equipments'];
    List parsedEq = [];
    if (eqData is String) {
      try {
        parsedEq = json.decode(eqData);
      } catch (_) {}
    } else if (eqData is List) {
      parsedEq = eqData;
    }

    if (parsedEq.isNotEmpty) {
      _equipments.clear();
      for (var item in parsedEq) {
        if (item is Map) {
          _addEquipment(initialData: Map<String, dynamic>.from(item));
        }
      }
    } else if (diag['pression'] != null || diag['intensite'] != null || diag['equipment_brand'] != null) {
      _equipments.clear();
      _addEquipment(initialData: diag);
    }
  }

  void _addEquipment({Map<String, dynamic>? initialData}) {
    final newIndex = _equipments.length + 1;
    final rawType = (initialData?['type'] ?? initialData?['equipment_type'])?.toString() ?? 'Mural';
    String matchedType = 'Mural';
    for (var t in _equipmentTypes) {
      if (t.toLowerCase() == rawType.toLowerCase()) {
        matchedType = t;
        break;
      }
    }

    final name = (initialData?['name'] ?? initialData?['equipment_name'])?.toString() ?? '';
    final brand = (initialData?['brand'] ?? initialData?['equipment_brand'])?.toString() ?? '';
    final location = initialData?['location']?.toString() ?? '';
    final state = (initialData?['state'] ?? initialData?['equipment_state'])?.toString() ?? '';
    final tested = initialData?['tested'] != null
        ? (initialData!['tested'] == true || initialData['tested'] == 'Oui' || initialData['tested'] == 1)
        : true;

    final bIntensite = (initialData?['before_intensite'] ?? initialData?['intensite'])?.toString() ?? '';
    final bTension = (initialData?['before_tension'] ?? initialData?['tension'])?.toString() ?? '';
    final bFreon = (initialData?['before_freon'] ?? initialData?['freon'] ?? initialData?['type_freon'])?.toString() ?? '';
    final bPression = (initialData?['before_pression'] ?? initialData?['pression'])?.toString() ?? '';
    final bPuissance = (initialData?['before_puissance'] ?? initialData?['puissance'])?.toString() ?? '';

    setState(() {
      _equipments.add({
        'index': newIndex,
        'type': matchedType,
        'tested': tested,
        'controllers': {
          'name': TextEditingController(text: name),
          'brand': TextEditingController(text: brand),
          'location': TextEditingController(text: location),
          'state': TextEditingController(text: state),
          'before_intensite': TextEditingController(text: bIntensite),
          'before_tension': TextEditingController(text: bTension),
          'before_freon': TextEditingController(text: bFreon),
          'before_pression': TextEditingController(text: bPression),
          'before_puissance': TextEditingController(text: bPuissance),
        },
      });
    });
  }

  void _removeEquipment(int index) {
    if (_equipments.length <= 1) return;
    setState(() {
      final removed = _equipments.removeAt(index);
      final Map<String, TextEditingController> ctrlMap = removed['controllers'];
      for (var controller in ctrlMap.values) {
        controller.dispose();
      }
      for (int i = 0; i < _equipments.length; i++) {
        _equipments[i]['index'] = i + 1;
      }
    });
  }

  void _addPart() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Ajouter une pièce', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _buildRoundedInputDecoration(
                  labelText: 'Nom de la pièce',
                  hintText: 'Ex: Filtre, Condensateur',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: _buildRoundedInputDecoration(
                  labelText: 'Quantité',
                  hintText: 'Ex: 1',
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
                      'name': nameController.text.trim(),
                      'quantity': int.tryParse(quantityController.text.trim()) ?? 1,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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

  InputDecoration _buildRoundedInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0a543d), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      SnackBarHelper.showWarning(context, 'Veuillez remplir les champs obligatoires.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final connectivityService = ConnectivityService();
    final cacheService = LocalCacheService();

    // Enrichir le tableau d'équipements
    final enrichedEquipments = _equipments.map((eq) {
      final Map<String, TextEditingController> ctrl = eq['controllers'];
      final brand = ctrl['brand']?.text.trim() ?? '';
      final location = ctrl['location']?.text.trim() ?? '';
      final state = ctrl['state']?.text.trim() ?? '';
      final bIntensite = ctrl['before_intensite']?.text.trim() ?? '';
      final bTension = ctrl['before_tension']?.text.trim() ?? '';
      final bFreon = ctrl['before_freon']?.text.trim() ?? '';
      final bPression = ctrl['before_pression']?.text.trim() ?? '';
      final bPuissance = ctrl['before_puissance']?.text.trim() ?? '';
      final name = ctrl['name']?.text.trim() ?? '';

      return {
        'index': eq['index'],
        'type': eq['type'] ?? 'Mural',
        'brand': brand,
        'location': location,
        'state': state,
        'tested': eq['tested'] ?? true,
        'before_intensite': bIntensite,
        'before_tension': bTension,
        'before_freon': bFreon,
        'before_pression': bPression,
        'before_puissance': bPuissance,
        'name': name,
        'pression': bPression,
        'puissance': bPuissance,
        'intensite': bIntensite,
        'tension': bTension,
        'freon': bFreon,
      };
    }).toList();

    final firstEquipment = enrichedEquipments.isNotEmpty ? enrichedEquipments[0] : {};

    final diagnosticData = {
      'intervention_id': widget.interventionId,
      'equipments': enrichedEquipments,
      'equipment_count': enrichedEquipments.length,
      'equipment_state': firstEquipment['state'] ?? '',
      'equipment_type': firstEquipment['type'] ?? '',
      'equipment_brand': firstEquipment['brand'] ?? '',
      'pression': firstEquipment['before_pression'] ?? '',
      'puissance': firstEquipment['before_puissance'] ?? '',
      'intensite': firstEquipment['before_intensite'] ?? '',
      'tension': firstEquipment['before_tension'] ?? '',
      'freon': firstEquipment['before_freon'] ?? '',
      'problem_description': _problemController.text.trim(),
      'materials_needed': _materialsNeededController.text.trim(),
      'recommended_solution': _solutionController.text.trim().isNotEmpty
          ? _solutionController.text.trim()
          : _problemController.text.trim(),
      'parts_needed': _partsList,
      'labor_cost': 0,
      'estimated_total': 0,
      'urgency_level': _selectedUrgency,
      'estimated_duration': _durationController.text.trim(),
      'photos': [],
      'notes': _notesController.text.trim(),
    };

    try {
      if (!connectivityService.isConnected) {
        if (kDebugMode) debugPrint('📴 Mode hors ligne - Queue rapport diagnostic');
        await cacheService.addToSyncQueue(
          'diagnostic_report_upload',
          widget.interventionId,
          diagnosticData,
        );

        if (mounted) {
          context.read<SyncProvider>().addToQueue(
                'diagnostic_report_upload',
                widget.interventionId,
                diagnosticData,
              );
          SnackBarHelper.showInfo(
            context,
            'Rapport sauvegardé hors ligne. Sera synchronisé au retour du réseau.',
          );
          Navigator.pop(context, true);
        }
        return;
      }

      final interventionRepository = context.read<InterventionRepository>();
      final response = await interventionRepository.submitDiagnosticReport(
        diagnosticData,
      );

      if (mounted) {
        if (response['success'] == true || response['message'] != null) {
          SnackBarHelper.showSuccess(
            context,
            response['message'] ?? 'Rapport de diagnostic soumis avec succès !',
          );
          Navigator.pop(context, true);
        } else {
          SnackBarHelper.showError(
            context,
            response['message'] ?? 'Erreur lors de la soumission du rapport',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        await cacheService.addToSyncQueue(
          'diagnostic_report_upload',
          widget.interventionId,
          diagnosticData,
        );

        if (mounted) {
          SnackBarHelper.showInfo(
            context,
            'Erreur réseau. Rapport sauvegardé et sera synchronisé automatiquement.',
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Erreur: $e');
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
    final interventionTitle = widget.intervention['title'] ?? 'Diagnostic';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Rapport de Diagnostic',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête d'intervention
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
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
                            color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment, color: Color(0xFF0a543d), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Intervention #${widget.interventionId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0a543d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      interventionTitle,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (widget.intervention['address'] != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.intervention['address'],
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1 À 5 : ÉQUIPEMENTS & DONNÉES TECHNIQUES
            _buildSectionHeader('Équipements & Constantes Avant Intervention', Icons.build_rounded, const Color(0xFF0a543d)),
            const SizedBox(height: 14),

            for (int i = 0; i < _equipments.length; i++) ...[
              _buildEquipmentCard(_equipments[i], i),
              const SizedBox(height: 16),
            ],

            OutlinedButton.icon(
              onPressed: _addEquipment,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Ajouter un autre équipement',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0a543d),
                side: const BorderSide(color: Color(0xFF0a543d), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),

            // POINT 6 : DÉCRIRE LA PANNE
            _buildSectionHeader('6/ Décrire la panne (Constat)', Icons.report_problem_rounded, Colors.orange.shade900),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _problemController,
                  decoration: _buildRoundedInputDecoration(
                    labelText: 'Constat de la panne *',
                    hintText: 'Décrivez les symptômes et la panne constatée par vos soins...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez décrire la panne constatée';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // POINT 7 : MATÉRIELS NÉCESSAIRES
            _buildSectionHeader('7/ Matériels nécessaires (Dépannage / Installation)', Icons.build_circle_rounded, Colors.blue.shade900),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _materialsNeededController,
                      decoration: _buildRoundedInputDecoration(
                        labelText: 'Besoins en matériel & pièces',
                        hintText: 'Lister les pièces, outillages ou matériels nécessaires pour effectuer les travaux...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Pièces détachées précises (Optionnel)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _addPart,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter une pièce'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0a543d),
                          ),
                        ),
                      ],
                    ),
                    if (_partsList.isNotEmpty)
                      Column(
                        children: [
                          for (int idx = 0; idx < _partsList.length; idx++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_partsList[idx]['name']} (x${_partsList[idx]['quantity']})',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removePart(idx),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // INFORMATIONS DE PLANIFICATION & DUREE
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: _buildRoundedInputDecoration(
                              labelText: 'Durée estimée',
                              hintText: 'Ex: 2 heures',
                              prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUrgency,
                            decoration: _buildRoundedInputDecoration(
                              labelText: 'Urgence',
                            ),
                            items: _urgencyLevels.map((level) {
                              String label;
                              Color col;
                              switch (level) {
                                case 'low':
                                  label = 'Faible';
                                  col = Colors.green;
                                  break;
                                case 'high':
                                  label = 'Élevé';
                                  col = Colors.deepOrange;
                                  break;
                                case 'critical':
                                  label = 'Critique';
                                  col = Colors.red;
                                  break;
                                default:
                                  label = 'Moyen';
                                  col = Colors.orange;
                              }
                              return DropdownMenuItem(
                                value: level,
                                child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUrgency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      decoration: _buildRoundedInputDecoration(
                        labelText: 'Remarques / Observations',
                        hintText: 'Précisions supplémentaires pour le Back-office...',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // BOUTON DE SOUMISSION
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a543d),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 22),
                label: Text(
                  _isSubmitting ? 'Envoi en cours...' : 'Valider & Soumettre le Diagnostic',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> eq, int index) {
    final Map<String, TextEditingController> ctrl = eq['controllers'];
    final stateCtrl = ctrl['state']!;
    final locationCtrl = ctrl['location']!;
    final brandCtrl = ctrl['brand']!;
    final bIntensiteCtrl = ctrl['before_intensite']!;
    final bTensionCtrl = ctrl['before_tension']!;
    final bFreonCtrl = ctrl['before_freon']!;
    final bPressionCtrl = ctrl['before_pression']!;
    final bPuissanceCtrl = ctrl['before_puissance']!;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Équipement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF0a543d),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Équipement ${index + 1}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_equipments.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeEquipment(index),
                  ),
              ],
            ),
            const Divider(height: 24),

            // 1/ TYPE ET MARQUE DE L'ÉQUIPEMENT
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _equipmentTypes.contains(eq['type']) ? eq['type'] : 'Mural',
                    decoration: _buildRoundedInputDecoration(
                      labelText: '1/ Type d\'équipement *',
                    ),
                    items: _equipmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => eq['type'] = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: brandCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: 'Marque *',
                      hintText: 'Ex: LK, Carrier',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Marque requise' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2/ EMPLACEMENT & 3/ ÉTAT DE L'ÉQUIPEMENT
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: locationCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: '2/ Emplacement',
                      hintText: 'Ex: Salon, Chambre 1',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: stateCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: '3/ État équipement',
                      hintText: 'Ex: Neuf, Usagé, Vétuste',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4/ TEST ÉQUIPEMENT (OUI / NON)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '4/ Test équipement :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Oui'),
                        selected: eq['tested'] == true,
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: eq['tested'] == true ? Colors.green.shade900 : Colors.black,
                          fontWeight: eq['tested'] == true ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (sel) {
                          if (sel) setState(() => eq['tested'] = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Non'),
                        selected: eq['tested'] == false,
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: eq['tested'] == false ? Colors.red.shade900 : Colors.black,
                          fontWeight: eq['tested'] == false ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (sel) {
                          if (sel) setState(() => eq['tested'] = false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5/ DONNÉES TECHNIQUES (CONSTANTES AVANT INTERVENTION)
            Text(
              '5/ Données techniques (Constantes avant intervention)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: const Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: bIntensiteCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: 'Intensité (A)',
                      prefixIcon: const Icon(Icons.electrical_services_outlined, size: 18),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: bTensionCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: 'Tension (V)',
                      prefixIcon: const Icon(Icons.bolt_outlined, size: 18),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: bFreonCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: 'Fréon',
                      hintText: 'Ex: R410A, R32',
                      prefixIcon: const Icon(Icons.cloud_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: bPressionCtrl,
                    decoration: _buildRoundedInputDecoration(
                      labelText: 'Pression (bar)',
                      prefixIcon: const Icon(Icons.compress_outlined, size: 18),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: bPuissanceCtrl,
              decoration: _buildRoundedInputDecoration(
                labelText: 'Puissance (CV / kW)',
                prefixIcon: const Icon(Icons.power_outlined, size: 18),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
