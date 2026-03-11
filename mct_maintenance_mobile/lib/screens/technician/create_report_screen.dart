import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mct_maintenance_mobile/screens/technician/report_summary_screen.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class CreateReportScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;

  const CreateReportScreen({
    super.key,
    required this.intervention,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;

  // === LISTE DES ÉQUIPEMENTS ===
  List<Map<String, dynamic>> _equipments = [];

  // === SECTION DÉTAIL INTERVENTION ===
  DateTime? _interventionDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _interventionNatureController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  // === SECTION PIÈCES DE RECHANGE ===
  List<Map<String, dynamic>> _spareParts = [];

  // Photos
  List<XFile> _photos = [];

  // États possibles de l'équipement
  final List<String> _equipmentStates = [
    'Bon état',
    'Vétuste',
    'Hors service',
    'Neuf',
  ];

  @override
  void initState() {
    super.initState();
    _interventionDate = DateTime.now();
    _initializeEquipments();
    _loadCurrentUser();
    _loadExistingReportData();
  }

  void _initializeEquipments() {
    // Déterminer le nombre d'équipements depuis l'intervention
    final equipmentCount = widget.intervention['equipment_count'] ?? 1;
    print('📦 Initialisation de $equipmentCount équipement(s)');

    for (int i = 0; i < equipmentCount; i++) {
      _equipments.add(_createEmptyEquipment(i + 1));
    }
  }

  Map<String, dynamic> _createEmptyEquipment(int index) {
    return {
      'index': index,
      'state': null,
      'type': '',
      'brand': '',
      'pression': '',
      'puissance': '',
      'intensite': '',
      'tension': '',
    };
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _apiService.loadUserData();
    if (mounted) {
      setState(() {
        _currentUser = userData;
      });
    }
  }

  void _loadExistingReportData() {
    // Charger les données existantes du rapport si présentes
    if (widget.intervention['report_data'] != null) {
      try {
        final reportData = widget.intervention['report_data'];
        print('🔍 Type de report_data: ${reportData.runtimeType}');

        Map<String, dynamic> data = {};

        if (reportData is String && reportData.isNotEmpty) {
          data = json.decode(reportData);
        } else if (reportData is Map) {
          data = Map<String, dynamic>.from(reportData);
        }

        if (data.isNotEmpty) {
          // Charger les équipements si présents
          if (data['equipments'] != null && data['equipments'] is List) {
            _equipments = List<Map<String, dynamic>>.from(
              (data['equipments'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
            print('✅ ${_equipments.length} équipement(s) chargé(s)');
          } else {
            // Ancienne structure mono-équipement - migrer
            if (_equipments.isNotEmpty) {
              _equipments[0] = {
                'index': 1,
                'state': data['equipment_state'],
                'type': data['equipment_type'] ?? '',
                'brand': data['equipment_brand'] ?? '',
                'pression': data['pression']?.toString() ?? '',
                'puissance': data['puissance']?.toString() ?? '',
                'intensite': data['intensite']?.toString() ?? '',
                'tension': data['tension']?.toString() ?? '',
              };
            }
          }

          // Section Détail intervention
          _interventionNatureController.text =
              data['intervention_nature'] ?? data['work_description'] ?? '';
          _observationsController.text = data['observations'] ?? '';

          // Heures début/fin
          if (data['start_time'] != null) {
            final parts = data['start_time'].toString().split(':');
            if (parts.length >= 2) {
              _startTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 0,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }
          if (data['end_time'] != null) {
            final parts = data['end_time'].toString().split(':');
            if (parts.length >= 2) {
              _endTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 0,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }

          // Charger les pièces de rechange
          if (data['spare_parts'] != null || data['materials_used'] != null) {
            final partsData = data['spare_parts'] ?? data['materials_used'];
            if (partsData is List) {
              _spareParts = List<Map<String, dynamic>>.from(
                partsData.map((item) {
                  if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  }
                  return {'name': item.toString(), 'quantity': 1};
                }),
              );
              print('✅ ${_spareParts.length} pièces de rechange chargées');
            }
          }

          setState(() {});
        }
      } catch (e, stackTrace) {
        print('❌ Erreur lors du chargement des données du rapport: $e');
        print('❌ Stack trace: $stackTrace');
      }
    }
  }

  @override
  void dispose() {
    _interventionNatureController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  String _getTechnicianName() {
    // D'abord essayer depuis l'intervention
    final technician = widget.intervention['technician'];
    if (technician != null && technician is Map) {
      final firstName = technician['first_name'] ?? '';
      final lastName = technician['last_name'] ?? '';
      final name = '$firstName $lastName'.trim();
      if (name.isNotEmpty) return name;
    }

    // Sinon utiliser les données de l'utilisateur connecté (le technicien)
    if (_currentUser != null) {
      final firstName = _currentUser!['first_name'] ?? '';
      final lastName = _currentUser!['last_name'] ?? '';
      final name = '$firstName $lastName'.trim();
      if (name.isNotEmpty) return name;
    }

    return 'N/A';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _interventionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _interventionDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  int _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    return endMinutes - startMinutes;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la sélection des photos: \$e');
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la prise de photo: \$e');
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _addSparePart() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController(text: '1');

        return AlertDialog(
          title: const Text('Ajouter une pièce de rechange'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la pièce',
                  hintText: 'Ex: Compresseur, Filtre, Condensateur...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _spareParts.add({
                      'name': nameController.text,
                      'quantity': int.tryParse(quantityController.text) ?? 1,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeSparePart(int index) {
    setState(() {
      _spareParts.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_interventionNatureController.text.trim().isEmpty) {
      SnackBarHelper.showWarning(
          context, 'Veuillez décrire la nature de l\'intervention');
      return;
    }

    // Préparer les chemins des photos
    List<String> photoPaths = _photos.map((photo) => photo.path).toList();

    // Calculer la durée
    final duration = _calculateDuration();

    // Formater les heures
    String? startTimeStr;
    String? endTimeStr;
    if (_startTime != null) {
      startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, "0")}:${_startTime!.minute.toString().padLeft(2, "0")}';
    }
    if (_endTime != null) {
      endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, "0")}:${_endTime!.minute.toString().padLeft(2, "0")}';
    }

    // Compatibilité: garder les données du premier équipement en racine
    final firstEquipment = _equipments.isNotEmpty ? _equipments[0] : {};

    final reportData = {
      'intervention_id': widget.intervention['id'],
      // Liste des équipements (nouvelle structure)
      'equipments': _equipments,
      'equipment_count': _equipments.length,
      // Compatibilité avec l'ancienne structure (premier équipement)
      'equipment_state': firstEquipment['state'] ?? '',
      'equipment_type': firstEquipment['type'] ?? '',
      'equipment_brand': firstEquipment['brand'] ?? '',
      'pression': firstEquipment['pression'] ?? '',
      'puissance': firstEquipment['puissance'] ?? '',
      'intensite': firstEquipment['intensite'] ?? '',
      'tension': firstEquipment['tension'] ?? '',
      // Détail intervention
      'technician_name': _getTechnicianName(),
      'intervention_date': _interventionDate?.toIso8601String(),
      'start_time': startTimeStr,
      'end_time': endTimeStr,
      'duration': duration,
      'intervention_nature': _interventionNatureController.text.trim(),
      'work_description':
          _interventionNatureController.text.trim(), // Pour compatibilité
      'observations': _observationsController.text.trim(),
      // Pièces de rechange
      'spare_parts': _spareParts,
      'materials_used': _spareParts, // Pour compatibilité
      // Photos
      'photos': photoPaths,
    };

    // Naviguer vers l'écran de récapitulatif
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportSummaryScreen(
            intervention: widget.intervention,
            reportData: reportData,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0a543d)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0a543d),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une carte d'équipement
  Widget _buildEquipmentCard(int index) {
    final equipment = _equipments[index];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0a543d),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                equipment['brand']?.isNotEmpty == true
                    ? '${equipment['brand']} - ${equipment['type']}'
                    : 'Équipement ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (_equipments.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeEquipment(index),
                tooltip: 'Supprimer',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // État de l'équipement
                const Text(
                  'État',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: equipment['state'],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Sélectionner l\'état',
                  ),
                  items: _equipmentStates.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _equipments[index]['state'] = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Type et Marque
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['type'],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: Climatiseur mural',
                            ),
                            onChanged: (value) {
                              _equipments[index]['type'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Marque',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['brand'],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: LK, Carrier',
                            ),
                            onChanged: (value) {
                              _equipments[index]['brand'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mesures techniques
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pression',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['pression'],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: 12.5',
                              suffixText: 'bar',
                            ),
                            onChanged: (value) {
                              _equipments[index]['pression'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Puissance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['puissance'],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: 2.5',
                              suffixText: 'CV',
                            ),
                            onChanged: (value) {
                              _equipments[index]['puissance'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Intensité',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['intensite'],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: 5.2',
                              suffixText: 'A',
                            ),
                            onChanged: (value) {
                              _equipments[index]['intensite'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tension',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: equipment['tension'],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: 220',
                              suffixText: 'V',
                            ),
                            onChanged: (value) {
                              _equipments[index]['tension'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addEquipment() {
    setState(() {
      _equipments.add(_createEmptyEquipment(_equipments.length + 1));
    });
  }

  void _removeEquipment(int index) {
    if (_equipments.length > 1) {
      setState(() {
        _equipments.removeAt(index);
        // Renuméroter
        for (int i = 0; i < _equipments.length; i++) {
          _equipments[i]['index'] = i + 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport d\'Intervention'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================================
                      // SECTION 1: ÉQUIPEMENTS
                      // ============================================
                      _buildSectionTitle('Équipements (${_equipments.length})',
                          Icons.build_circle),
                      const SizedBox(height: 16),

                      // Liste des équipements
                      ...List.generate(_equipments.length,
                          (index) => _buildEquipmentCard(index)),

                      // Bouton ajouter équipement
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _addEquipment,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un équipement'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0a543d),
                            side: const BorderSide(color: Color(0xFF0a543d)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ============================================
                      // SECTION 2: DÉTAIL DE L'INTERVENTION
                      // ============================================
                      _buildSectionTitle(
                          'Détail de l\'Intervention', Icons.assignment),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Intervenant (lecture seule)
                              const Text(
                                'Intervenant (Technicien)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Color(0xFF0a543d)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getTechnicianName(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Date
                              const Text(
                                'Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF0a543d)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _interventionDate != null
                                            ? dateFormat
                                                .format(_interventionDate!)
                                            : 'Sélectionner une date',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Début et Fin sur la même ligne
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Début',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: _selectStartTime,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[400]!),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    color: Color(0xFF0a543d),
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _startTime != null
                                                      ? '${_startTime!.hour.toString().padLeft(2, "0")}:${_startTime!.minute.toString().padLeft(2, "0")}'
                                                      : 'HH:MM',
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fin',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: _selectEndTime,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[400]!),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    color: Color(0xFF0a543d),
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _endTime != null
                                                      ? '${_endTime!.hour.toString().padLeft(2, "0")}:${_endTime!.minute.toString().padLeft(2, "0")}'
                                                      : 'HH:MM',
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_startTime != null && _endTime != null) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Durée: \${_calculateDuration()} min',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Nature de l'intervention
                              const Text(
                                'Nature de l\'intervention *',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _interventionNatureController,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Décrivez en détail le travail effectué...',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ce champ est obligatoire';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Observation
                              const Text(
                                'Observation',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _observationsController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Observations, recommandations pour le client...',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ============================================
                      // SECTION 3: PRODUIT ET PIÈCES DE RECHANGE
                      // ============================================
                      _buildSectionTitle(
                          'Produit et Pièces de Rechange', Icons.inventory),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pièces de rechange',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addSparePart,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0a543d),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_spareParts.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[50],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Aucune pièce de rechange ajoutée',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _spareParts.length,
                                  itemBuilder: (context, index) {
                                    final part = _spareParts[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.settings,
                                          color: Color(0xFF0a543d),
                                        ),
                                        title: Text(part['name']),
                                        subtitle: Text(
                                          'Quantité: ${part["quantity"]}',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _removeSparePart(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ============================================
                      // SECTION 4: PHOTOS
                      // ============================================
                      _buildSectionTitle('Photos', Icons.camera_alt),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon:
                                        const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Prendre photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.photo_library,
                                        size: 18),
                                    label: const Text('Galerie'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0a543d),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_photos.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[50],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Aucune photo ajoutée',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _photos.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            File(_photos[index].path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removePhoto(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton soumettre
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitReport,
                          icon: const Icon(Icons.send, size: 24),
                          label: const Text(
                            'Soumettre le rapport',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0a543d),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
