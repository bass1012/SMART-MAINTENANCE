import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mct_maintenance_mobile/config/environment.dart' show AppConfig;
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/report_summary_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mct_maintenance_mobile/widgets/common/authenticated_network_image.dart';

class CreateReportScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;
  final bool isInitialStep;

  const CreateReportScreen({
    super.key,
    required this.intervention,
    this.isInitialStep = false,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final AuthRepository _authRepository;
  late Map<String, dynamic> _intervention;

  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  // === LISTE DES ÉQUIPEMENTS ===
  final List<Map<String, dynamic>> _equipments = [];

  // === PHOTOS AVANT INTERVENTION ===
  final List<XFile> _photosBefore = [];

  // === PHOTOS APRÈS INTERVENTION ===
  final List<XFile> _photosAfter = [];

  // === TRAVAUX EFFECTUÉS (checkboxes obligatoires) ===
  final Map<String, bool> _tasksDone = {
    'filtres_air': false,
    'batterie_evaporateur': false,
    'bacs_condensat': false,
    'turbine': false,
    'condenseur': false,
    'carrosserie_evaporateur': false,
    'tuyauterie_evacuation': false,
    'parties_electriques': false,
  };

  static const Map<String, String> _taskLabels = {
    'filtres_air': 'Nettoyage des filtres à air',
    'batterie_evaporateur': 'Nettoyage de la batterie évaporateur',
    'bacs_condensat': 'Nettoyage des bacs à condensat',
    'turbine': 'Nettoyage de la turbine',
    'condenseur': 'Nettoyage du condenseur',
    'carrosserie_evaporateur': 'Nettoyage de la carrosserie évaporateur',
    'tuyauterie_evacuation':
        'Soufflement à forte pression de la tuyauterie d\'évacuation des condensats',
    'parties_electriques': 'Nettoyage des parties électriques',
  };

  // === TYPES D'ÉQUIPEMENT ===
  static const List<String> _equipmentTypes = [
    'Allège',
    'Armoire',
    'Cassette',
    'Gainable',
    'Mural',
    'Autre',
  ];

  // === SECTION DÉTAIL INTERVENTION ===
  DateTime? _interventionDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _interventionNatureController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  // === SECTION PIÈCES DE RECHANGE ===
  List<Map<String, dynamic>> _spareParts = [];

  @override
  void initState() {
    super.initState();
    _authRepository = context.read<AuthRepository>();
    _intervention = Map<String, dynamic>.from(widget.intervention);
    _interventionDate = DateTime.now();
    _loadCurrentUser();
    _loadTimesFromPrefs();
    _initializeReport();
  }

  Future<void> _initializeReport() async {
    if (!widget.isInitialStep) {
      try {
        final repository = context.read<InterventionRepository>();
        final response =
            await repository.getInterventionById(_intervention['id']);
        if (response['success'] == true && response['data'] is Map) {
          _intervention = Map<String, dynamic>.from(response['data'] as Map);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Impossible de rafraîchir le constat initial, utilisation du cache: $e');
        }
      }
    }

    _loadExistingReportData();
    if (_equipments.isEmpty) {
      _initializeEquipments();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = _intervention['id'];
    final now = DateTime.now();

    if (mounted) {
      setState(() {
        // 1. Charger l'heure de début (depuis started_at API ou SharedPreferences)
        if (_startTime == null) {
          String? startedAtStr = _intervention['started_at'] ??
              prefs.getString('intervention_${id}_started_at');
          startedAtStr ??= _intervention['created_at'];

          if (startedAtStr != null) {
            try {
              final startedAt = DateTime.parse(startedAtStr).toLocal();
              _startTime = TimeOfDay(hour: startedAt.hour, minute: startedAt.minute);
            } catch (_) {}
          }
        }

        // 2. Charger l'heure de fin (depuis completed_at ou l'heure actuelle MAINTENANT)
        if (_endTime == null) {
          String? completedAtStr = _intervention['completed_at'] ??
              prefs.getString('intervention_${id}_completed_at');
          if (completedAtStr != null) {
            try {
              final completedAt = DateTime.parse(completedAtStr).toLocal();
              _endTime = TimeOfDay(hour: completedAt.hour, minute: completedAt.minute);
            } catch (_) {
              _endTime = TimeOfDay.now();
            }
          } else {
            _endTime = TimeOfDay.now();
          }
        }

        // 3. Si _startTime est toujours nul (aucun début enregistré), déduire 30 minutes par rapport à _endTime
        if (_startTime == null && _endTime != null) {
          final endDt = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
          final startDt = endDt.subtract(const Duration(minutes: 30));
          _startTime = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
          prefs.setString('intervention_${id}_started_at', startDt.toIso8601String());
        }
      });
    }
  }

  void _initializeEquipments() {
    final equipmentCount = _intervention['equipment_count'] ?? 1;
    if (kDebugMode) {
      debugPrint(
          '📦 Initialisation par défaut de $equipmentCount équipement(s)');
    }
    _equipments.clear();
    for (int i = 0; i < equipmentCount; i++) {
      _equipments.add(_createEquipmentMap(i + 1));
    }
  }

  Map<String, dynamic> _createEquipmentMap(int index,
      {Map<String, dynamic>? initialData}) {
    final rawType =
        (initialData?['type'] ?? initialData?['equipment_type'])?.toString() ??
            'Mural';
    String matchedType = 'Mural';
    for (var t in _equipmentTypes) {
      if (t.toLowerCase() == rawType.toLowerCase()) {
        matchedType = t;
        break;
      }
    }

    final brand = (initialData?['brand'] ?? initialData?['equipment_brand'])
            ?.toString() ??
        '';
    final location = initialData?['location']?.toString() ?? '';
    final state = (initialData?['state'] ?? initialData?['equipment_state'])
            ?.toString() ??
        '';
    final beforeIntensite =
        (initialData?['before_intensite'] ?? initialData?['intensite'])
                ?.toString() ??
            '';
    final beforeTension =
        (initialData?['before_tension'] ?? initialData?['tension'])
                ?.toString() ??
            '';
    final beforeFreon =
        (initialData?['before_freon'] ?? initialData?['freon'] ?? initialData?['type_freon'])?.toString() ??
            '';
    final beforePression =
        (initialData?['before_pression'] ?? initialData?['pression'])
                ?.toString() ??
            '';
    final beforePuissance =
        (initialData?['before_puissance'] ?? initialData?['puissance'])
                ?.toString() ??
            '';
    final afterIntensite = initialData?['after_intensite']?.toString() ?? '';
    final afterTension = initialData?['after_tension']?.toString() ?? '';
    final afterFreon = initialData?['after_freon']?.toString() ?? '';
    final afterPression = initialData?['after_pression']?.toString() ?? '';
    final afterPuissance = initialData?['after_puissance']?.toString() ?? '';
    final name =
        (initialData?['name'] ?? initialData?['equipment_name'])?.toString() ??
            '';
    final tested = initialData?['tested'] != null
        ? (initialData!['tested'] == true || initialData['tested'] == 'Oui' || initialData['tested'] == 1)
        : true;

    final Map<String, TextEditingController> controllers = {
      'brand': TextEditingController(text: brand),
      'location': TextEditingController(text: location),
      'state': TextEditingController(text: state),
      'before_intensite': TextEditingController(text: beforeIntensite),
      'before_tension': TextEditingController(text: beforeTension),
      'before_freon': TextEditingController(text: beforeFreon),
      'before_pression': TextEditingController(text: beforePression),
      'before_puissance': TextEditingController(text: beforePuissance),
      'after_intensite': TextEditingController(text: afterIntensite),
      'after_tension': TextEditingController(text: afterTension),
      'after_freon': TextEditingController(text: afterFreon),
      'after_pression': TextEditingController(text: afterPression),
      'after_puissance': TextEditingController(text: afterPuissance),
      'name': TextEditingController(text: name),
    };

    return {
      'index': index,
      'type': matchedType,
      'tested': tested,
      'controllers': controllers,
    };
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _authRepository.getUserData();
    if (mounted) {
      setState(() {
        _currentUser = userData;
      });
    }
  }

  void _loadExistingReportData() {
    try {
      final reportData = _intervention['report_data'];
      Map<String, dynamic> data = {};

      if (reportData is String && reportData.isNotEmpty) {
        try {
          data = json.decode(reportData);
        } catch (_) {}
      } else if (reportData is Map) {
        data = Map<String, dynamic>.from(reportData);
      }

      if (data.isEmpty && _intervention.isNotEmpty) {
        data = _intervention;
      }

      if (data.isEmpty) return;

      final isDiagnosticData = data['report_type'] == 'diagnostic' ||
          (data['problem_description'] != null &&
              data['work_description'] == null &&
              data['intervention_nature'] == null);

      // 📸 1. Charger les photos AVANT
      _photosBefore.clear();
      final photosBeforeList = data['photos_before'] ?? data['photos'];
      if (photosBeforeList is List) {
        for (var item in photosBeforeList) {
          if (item != null && item.toString().isNotEmpty) {
            _photosBefore.add(XFile(item.toString()));
          }
        }
      }

      // 📸 2. Charger les photos APRÈS
      _photosAfter.clear();
      final photosAfterList = data['photos_after'];
      if (photosAfterList is List) {
        for (var item in photosAfterList) {
          if (item != null && item.toString().isNotEmpty) {
            _photosAfter.add(XFile(item.toString()));
          }
        }
      }

      // 📦 3. Charger les ÉQUIPEMENTS avec leurs contrôleurs
      if (data['equipments'] != null &&
          data['equipments'] is List &&
          (data['equipments'] as List).isNotEmpty) {
        _equipments.clear();
        final list = data['equipments'] as List;
        for (int i = 0; i < list.length; i++) {
          final item = Map<String, dynamic>.from(list[i]);
          _equipments.add(_createEquipmentMap(i + 1, initialData: item));
        }
        if (kDebugMode) {
          debugPrint(
              '✅ ${_equipments.length} équipement(s) chargé(s) depuis report_data');
        }
      } else {
        // Fallback mono-équipement
        _equipments.clear();
        _equipments.add(_createEquipmentMap(1, initialData: data));
      }

      // 🛠️ 4. Charger TRAVAUX EFFECTUÉS
      if (data['tasks_done'] != null && data['tasks_done'] is Map) {
        final tasks = Map<String, dynamic>.from(data['tasks_done']);
        tasks.forEach((key, value) {
          if (key == 'volets_air') {
            _tasksDone['condenseur'] = value == true;
          } else if (_tasksDone.containsKey(key)) {
            _tasksDone[key] = value == true;
          }
        });
      }

      // 📝 5. Textes intervention
      if (!isDiagnosticData) {
        _interventionNatureController.text =
            data['intervention_nature'] ?? data['work_description'] ?? '';
        _observationsController.text = data['observations'] ?? '';
      }

      // ⏰ 6. Heures
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

      // 🔩 7. Pièces de rechange
      final partsData = data['spare_parts'] ?? data['materials_used'];
      if (partsData is List) {
        _spareParts = List<Map<String, dynamic>>.from(
          partsData.map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return {'name': item.toString(), 'quantity': 1};
          }),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Erreur chargement rapport: $e\n$stackTrace');
      }
    }
  }

  @override
  void dispose() {
    _interventionNatureController.dispose();
    _observationsController.dispose();
    for (var eq in _equipments) {
      if (eq['controllers'] != null && eq['controllers'] is Map) {
        final ctrls = eq['controllers'] as Map<String, TextEditingController>;
        for (var c in ctrls.values) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  String _getTechnicianName() {
    final technician = _intervention['technician'];
    if (technician != null && technician is Map) {
      final name =
          '${technician['first_name'] ?? ''} ${technician['last_name'] ?? ''}'
              .trim();
      if (name.isNotEmpty) return name;
    }
    if (_currentUser != null) {
      final name =
          '${_currentUser!['first_name'] ?? ''} ${_currentUser!['last_name'] ?? ''}'
              .trim();
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
    if (picked != null) setState(() => _interventionDate = picked);
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime != null) {
          final startMins = picked.hour * 60 + picked.minute;
          final endMins = _endTime!.hour * 60 + _endTime!.minute;
          if (endMins < startMins) {
            _endTime = picked;
          }
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (_startTime != null) {
        final startMins = _startTime!.hour * 60 + _startTime!.minute;
        final endMins = picked.hour * 60 + picked.minute;
        if (endMins < startMins) {
          if (mounted) {
            SnackBarHelper.showWarning(
              context,
              'L\'heure de fin ne peut pas être antérieure à l\'heure de début.',
            );
          }
          return;
        }
      }
      setState(() => _endTime = picked);
    }
  }

  int _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    int diff = endMinutes - startMinutes;
    if (diff < 0) {
      diff += 1440; // Gère le passage de minuit (ex: 23:45 à 00:30)
    }
    return diff;
  }

  Future<void> _takePhotoFor(List<XFile> list) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) setState(() => list.add(photo));
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Erreur photo: $e');
    }
  }

  Future<void> _pickPhotosFor(List<XFile> list) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) setState(() => list.addAll(images));
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Erreur galerie: $e');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (video != null) {
        final file = File(video.path);
        final sizeInBytes = await file.length();
        if (sizeInBytes > 30 * 1024 * 1024) {
          if (mounted) {
            SnackBarHelper.showWarning(
                context, 'La vidéo dépasse la limite de 30 Mo');
          }
          return;
        }
        setState(() => _photosAfter.add(video));
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Erreur vidéo: $e');
    }
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
                decoration: const InputDecoration(labelText: 'Quantité'),
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
                  backgroundColor: const Color(0xFF0a543d)),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeSparePart(int index) =>
      setState(() => _spareParts.removeAt(index));

  void _addEquipment() => setState(
      () => _equipments.add(_createEquipmentMap(_equipments.length + 1)));

  void _removeEquipment(int index) {
    if (_equipments.length > 1) {
      setState(() {
        final removed = _equipments.removeAt(index);
        if (removed['controllers'] != null && removed['controllers'] is Map) {
          final ctrls =
              removed['controllers'] as Map<String, TextEditingController>;
          for (var c in ctrls.values) {
            c.dispose();
          }
        }
        for (int i = 0; i < _equipments.length; i++) {
          _equipments[i]['index'] = i + 1;
        }
      });
    }
  }

  bool _validateInitialPhase() {
    if (_photosBefore.isEmpty) {
      SnackBarHelper.showWarning(
          context, 'Ajoutez au moins une photo avant intervention');
      return false;
    }

    for (int i = 0; i < _equipments.length; i++) {
      final equipment = _equipments[i];
      final controllers =
          equipment['controllers'] as Map<String, TextEditingController>;
      final requiredControllers = <String>[
        'brand',
        'location',
        'state',
        'before_intensite',
        'before_tension',
        'before_freon',
        'before_pression',
        'before_puissance',
      ];

      if ((equipment['type']?.toString().trim().isEmpty ?? true) ||
          equipment['tested'] == null ||
          requiredControllers
              .any((key) => controllers[key]?.text.trim().isEmpty ?? true)) {
        SnackBarHelper.showWarning(context,
            'Complétez toutes les informations avant intervention pour l’équipement ${i + 1}');
        return false;
      }
    }
    return true;
  }

  bool _validateFinalPhase() {
    if (_tasksDone.values.every((done) => !done)) {
      SnackBarHelper.showWarning(context, 'Cochez au moins un travail effectué');
      return false;
    }
    if (_photosAfter.isEmpty) {
      SnackBarHelper.showWarning(
          context, 'Ajoutez au moins une photo après intervention');
      return false;
    }

    for (int i = 0; i < _equipments.length; i++) {
      final controllers =
          _equipments[i]['controllers'] as Map<String, TextEditingController>;
      final requiredControllers = <String>[
        'after_intensite',
        'after_tension',
        'after_freon',
        'after_pression',
        'after_puissance',
      ];
      if (requiredControllers
          .any((key) => controllers[key]?.text.trim().isEmpty ?? true)) {
        SnackBarHelper.showWarning(context,
            'Complétez toutes les données techniques après intervention pour l’équipement ${i + 1}');
        return false;
      }
    }
    return true;
  }

  // === SOUMISSION (Étape 1 = Démarrage / Étape 2 = Rapport Final) ===
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.isInitialStep && !_validateInitialPhase()) return;
    if (!widget.isInitialStep && !_validateFinalPhase()) return;

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
      final aIntensite = ctrl['after_intensite']?.text.trim() ?? '';
      final aTension = ctrl['after_tension']?.text.trim() ?? '';
      final aFreon = ctrl['after_freon']?.text.trim() ?? '';
      final aPression = ctrl['after_pression']?.text.trim() ?? '';
      final aPuissance = ctrl['after_puissance']?.text.trim() ?? '';
      final name = ctrl['name']?.text.trim() ?? '';

      return {
        'index': eq['index'],
        'type': eq['type'] ?? '',
        'brand': brand,
        'location': location,
        'state': state,
        'tested': eq['tested'],
        'before_intensite': bIntensite,
        'before_tension': bTension,
        'before_freon': bFreon,
        'before_pression': bPression,
        'before_puissance': bPuissance,
        'after_intensite': aIntensite,
        'after_tension': aTension,
        'after_freon': aFreon,
        'after_pression': aPression,
        'after_puissance': aPuissance,
        'name': name,
        'pression': bPression,
        'puissance': bPuissance,
        'intensite': bIntensite,
        'tension': bTension,
        'freon': bFreon,
      };
    }).toList();

    final firstEquipment =
        enrichedEquipments.isNotEmpty ? enrichedEquipments[0] : {};

    // ──────────────────────────────────────────────
    // ÉTAPE 1 : CONSTAT INITIAL (AU DÉMARRAGE)
    // ──────────────────────────────────────────────
    if (widget.isInitialStep) {
      setState(() => _isLoading = true);

      final initialReportData = {
        'intervention_id': _intervention['id'],
        'report_type': 'maintenance',
        'initial_completed': true,
        'equipments': enrichedEquipments,
        'equipment_count': _equipments.length,
        'equipment_state': firstEquipment['state'] ?? '',
        'equipment_name': firstEquipment['name'] ?? '',
        'equipment_type': firstEquipment['type'] ?? '',
        'equipment_brand': firstEquipment['brand'] ?? '',
        'pression': firstEquipment['pression'] ?? '',
        'puissance': firstEquipment['puissance'] ?? '',
        'intensite': firstEquipment['intensite'] ?? '',
        'tension': firstEquipment['tension'] ?? '',
        'freon': firstEquipment['freon'] ?? '',
        'photos_before': _photosBefore.map((p) => p.path).toList(),
        'photos': _photosBefore.map((p) => p.path).toList(),
      };

      try {
        final repo = context.read<InterventionRepository>();
        final response = await repo.startIntervention(
          _intervention['id'],
          reportData: initialReportData,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          if (response['success'] == true) {
            SnackBarHelper.showSuccess(
                context, 'Constat initial validé et intervention démarrée !');
            Navigator.pop(context, true);
          } else {
            SnackBarHelper.showError(
                context, response['message'] ?? 'Erreur lors du démarrage');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.showError(
              context, 'Erreur lors de la validation : $e');
        }
      }
      return;
    }

    // ──────────────────────────────────────────────
    // ÉTAPE 2 : RAPPORT DE FIN D'INTERVENTION
    // ──────────────────────────────────────────────
    final duration = _calculateDuration();

    String? startTimeStr;
    String? endTimeStr;
    if (_startTime != null) {
      startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
    }
    if (_endTime != null) {
      endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
    }

    final reportData = {
      'intervention_id': _intervention['id'],
      'report_type': 'maintenance',
      'equipments': enrichedEquipments,
      'equipment_count': _equipments.length,
      'equipment_state': firstEquipment['state'] ?? '',
      'equipment_name': firstEquipment['name'] ?? '',
      'equipment_type': firstEquipment['type'] ?? '',
      'equipment_brand': firstEquipment['brand'] ?? '',
      'pression': firstEquipment['pression'] ?? '',
      'puissance': firstEquipment['puissance'] ?? '',
      'intensite': firstEquipment['intensite'] ?? '',
      'tension': firstEquipment['tension'] ?? '',
      'freon': firstEquipment['freon'] ?? '',
      'tasks_done': _tasksDone,
      'photos_before': _photosBefore.map((p) => p.path).toList(),
      'photos_after': _photosAfter.map((p) => p.path).toList(),
      'technician_name': _getTechnicianName(),
      'intervention_date': _interventionDate?.toIso8601String(),
      'start_time': startTimeStr,
      'end_time': endTimeStr,
      'duration': duration,
      'intervention_nature': _interventionNatureController.text.trim().isNotEmpty
          ? _interventionNatureController.text.trim()
          : 'Entretien / Maintenance',
      'work_description': _interventionNatureController.text.trim().isNotEmpty
          ? _interventionNatureController.text.trim()
          : 'Entretien / Maintenance',
      'observations': _observationsController.text.trim(),
      'spare_parts': _spareParts,
      'materials_used': _spareParts,
      'photos': [
        ..._photosBefore.map((p) => p.path),
        ..._photosAfter.map((p) => p.path),
      ],
    };

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportSummaryScreen(
            intervention: _intervention,
            reportData: reportData,
          ),
        ),
      );
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  // ===========================
  // WIDGETS HELPERS
  // ===========================

  Widget _buildPhaseHeader(String title, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0a543d)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTechField(
    String label,
    String key,
    Map<String, dynamic> equipment, {
    String? suffix,
  }) {
    final Map<String, TextEditingController> ctrl = equipment['controllers'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl[key],
          readOnly: !widget.isInitialStep && key.startsWith('before_'),
          keyboardType: key.contains('freon')
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: '-', suffixText: suffix),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(List<XFile> photos, {bool readOnly = false}) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
        ),
        child: const Center(
          child: Text('Aucune photo ajoutée',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final rawPath = photos[index].path;
        final pathLower = rawPath.toLowerCase();
        final isVideo = pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.avi');
        final isNetwork = rawPath.startsWith('http://') ||
            rawPath.startsWith('https://') ||
            rawPath.startsWith('/uploads/');

        Widget imageWidget;
        if (isVideo) {
          imageWidget = Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 36, color: Colors.grey.shade600),
                const SizedBox(height: 4),
                Text('Vidéo',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          );
        } else if (isNetwork) {
          final fullUrl = rawPath.startsWith('/uploads/')
              ? '${AppConfig.baseUrl}$rawPath'
              : rawPath;
          imageWidget = AuthenticatedNetworkImage(
            fullUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        } else {
          imageWidget = Image.file(
            File(rawPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
            if (!readOnly)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => photos.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoButtons(List<XFile> list, {bool showVideo = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _takePhotoFor(list),
          icon: const Icon(Icons.camera_alt, size: 18),
          label: const Text('Caméra'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickPhotosFor(list),
          icon: const Icon(Icons.photo_library, size: 18),
          label: const Text('Galerie'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d)),
        ),
        if (showVideo)
          ElevatedButton.icon(
            onPressed: _takeVideo,
            icon: const Icon(Icons.videocam, size: 18),
            label: const Text('Vidéo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          ),
      ],
    );
  }

  Widget _buildTestChip(
      int equipmentIndex, bool value, String label, Color color,
      {bool enabled = true}) {
    final isSelected = _equipments[equipmentIndex]['tested'] == value;
    return GestureDetector(
      onTap: enabled
          ? () => setState(() => _equipments[equipmentIndex]['tested'] = value)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(int index, {bool showAfterSection = true}) {
    final equipment = _equipments[index];
    final Map<String, TextEditingController> ctrl = equipment['controllers'];
    final brandText = ctrl['brand']?.text ?? '';
    final label = brandText.isNotEmpty
        ? '$brandText${equipment['type']?.isNotEmpty == true ? ' - ${equipment['type']}' : ''}'
        : 'Équipement ${index + 1}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            if (widget.isInitialStep && _equipments.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeEquipment(index),
                tooltip: 'Supprimer',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────
                // PHASE AVANT pour cet équipement
                // ─────────────────────────────────────
                _buildPhaseHeader(
                  'AVANT INTERVENTION — Équipement ${index + 1}',
                  Colors.orange.shade800,
                  Icons.assignment_outlined,
                ),
                const SizedBox(height: 16),

                // Point 2 : Type + Marque
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Type',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _equipmentTypes.contains(equipment['type'])
                                    ? equipment['type']
                                    : null,
                            decoration:
                                const InputDecoration(hintText: 'Sélectionner'),
                            items: _equipmentTypes
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: widget.isInitialStep
                                ? (value) => setState(
                                    () => equipment['type'] = value ?? '')
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Marque',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: ctrl['brand'],
                            readOnly: !widget.isInitialStep,
                            decoration: const InputDecoration(
                                hintText: 'Ex: LK, Carrier, Samsung'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Point 3 : Emplacement
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emplacement',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['location'],
                      readOnly: !widget.isInitialStep,
                      decoration: const InputDecoration(
                          hintText:
                              'Ex: Salon, Chambre, Bureau, Salle de réunion...'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Point 4 : État (champ texte libre)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('État de l\'équipement',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['state'],
                      readOnly: !widget.isInitialStep,
                      decoration: const InputDecoration(
                          hintText:
                              'Ex: Neuf, Usagé, Vétuste, Hors service...'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Point 5 : Test équipement (Oui / Non)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test équipement',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTestChip(index, true, 'Oui', Colors.green,
                            enabled: widget.isInitialStep),
                        const SizedBox(width: 12),
                        _buildTestChip(index, false, 'Non', Colors.red.shade600,
                            enabled: widget.isInitialStep),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Point 6 : Données techniques AVANT
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Données techniques — AVANT intervention',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildTechField(
                            'Intensité', 'before_intensite', equipment,
                            suffix: 'A')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTechField(
                            'Tension', 'before_tension', equipment,
                            suffix: 'V')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildTechField(
                            'Pression', 'before_pression', equipment,
                            suffix: 'bar')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTechField(
                            'Puissance', 'before_puissance', equipment,
                            suffix: 'CV')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildTechField(
                            'Fréon', 'before_freon', equipment)),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                if (showAfterSection) ...[
                  const SizedBox(height: 24),
                  // ─────────────────────────────────────
                  // PHASE APRÈS pour cet équipement
                  // ─────────────────────────────────────
                  _buildPhaseHeader(
                    'APRÈS INTERVENTION — Équipement ${index + 1}',
                    const Color(0xFF0a543d),
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Données techniques — APRÈS intervention',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTechField(
                              'Intensité', 'after_intensite', equipment,
                              suffix: 'A')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTechField(
                              'Tension', 'after_tension', equipment,
                              suffix: 'V')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTechField(
                              'Pression', 'after_pression', equipment,
                              suffix: 'bar')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTechField(
                              'Puissance', 'after_puissance', equipment,
                              suffix: 'CV')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTechField(
                              'Fréon', 'after_freon', equipment)),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // BUILD
  // ===========================

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final isInitial = widget.isInitialStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(isInitial
            ? 'Constat Initial (Démarrage)'
            : 'Rapport de Fin d\'Intervention'),
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
                      // ════════════════════════════════════════
                      // ÉTAPE 1 : PHASE AVANT INTERVENTION
                      // ════════════════════════════════════════
                      _buildPhaseHeader(
                        'AVANT INTERVENTION — Constat Initial',
                        Colors.orange.shade800,
                        Icons.assignment_outlined,
                      ),
                      const SizedBox(height: 20),

                      // ── Point 1 : Photos AVANT ──
                      _buildSectionTitle(
                          '1. Photos de l\'équipement avant intervention',
                          Icons.camera_alt),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (isInitial) _buildPhotoButtons(_photosBefore),
                              const SizedBox(height: 12),
                              _buildPhotoGrid(_photosBefore,
                                  readOnly: !isInitial),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Points 2-6 : Équipements ──
                      _buildSectionTitle(
                        'Équipements (${_equipments.length})',
                        Icons.build_circle,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                          _equipments.length,
                          (index) => _buildEquipmentCard(index,
                              showAfterSection: !isInitial)),

                      if (isInitial)
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
                      const SizedBox(height: 32),

                      // ════════════════════════════════════════
                      // ÉTAPE 2 : PHASE APRÈS INTERVENTION
                      // (Masqué en Étape Initial)
                      // ════════════════════════════════════════
                      if (!isInitial) ...[
                        _buildPhaseHeader(
                          'APRÈS INTERVENTION',
                          const Color(0xFF0a543d),
                          Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 20),

                        // ── Point 7 : Travaux effectués ──
                        _buildSectionTitle(
                          '7. Travaux effectués',
                          Icons.checklist,
                          trailing: TextButton.icon(
                            onPressed: () {
                              final allChecked = _tasksDone.values.every((v) => v);
                              setState(() {
                                _tasksDone.updateAll((key, value) => !allChecked);
                              });
                            },
                            icon: Icon(
                              _tasksDone.values.every((v) => v)
                                  ? Icons.deselect
                                  : Icons.select_all,
                              size: 18,
                              color: const Color(0xFF0a543d),
                            ),
                            label: Text(
                              _tasksDone.values.every((v) => v)
                                  ? 'Tout décocher'
                                  : 'Tout cocher',
                              style: const TextStyle(
                                color: Color(0xFF0a543d),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            child: Column(
                              children: _taskLabels.entries.map((entry) {
                                return CheckboxListTile(
                                  value: _tasksDone[entry.key] ?? false,
                                  onChanged: (val) => setState(() =>
                                      _tasksDone[entry.key] = val ?? false),
                                  title: Text(entry.value,
                                      style: const TextStyle(fontSize: 14)),
                                  activeColor: const Color(0xFF0a543d),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  dense: true,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Point 8 : Photos APRÈS ──
                        _buildSectionTitle(
                            '8. Photos de l\'équipement après intervention',
                            Icons.camera_enhance),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildPhotoButtons(_photosAfter,
                                    showVideo: true),
                                const SizedBox(height: 12),
                                _buildPhotoGrid(_photosAfter),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ════════════════════════════════════════
                        // SECTION DÉTAIL DE L'INTERVENTION
                        // ════════════════════════════════════════
                        _buildSectionTitle(
                            'Détail de l\'Intervention', Icons.assignment),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Intervenant (Technicien)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
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
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Date',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Début',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14)),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: _selectStartTime,
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.access_time,
                                                      color: Color(0xFF0a543d),
                                                      size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _startTime != null
                                                        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                                        : 'HHhMM',
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
                                          const Text('Fin',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14)),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: _selectEndTime,
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.access_time,
                                                      color: Color(0xFF0a543d),
                                                      size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _endTime != null
                                                        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                                                        : 'HHhMM',
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
                                      'Durée: ${_calculateDuration()} min',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ════════════════════════════════════════
                        // SECTION PIÈCES DE RECHANGE
                        // ════════════════════════════════════════
                        _buildSectionTitle(
                            'Produit et Pièces de Rechange', Icons.inventory),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Pièces de rechange',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14)),
                                    ElevatedButton.icon(
                                      onPressed: _addSparePart,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Ajouter'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0a543d),
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
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.grey[50],
                                    ),
                                    child: const Center(
                                      child: Text(
                                          'Aucune pièce de rechange ajoutée',
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _spareParts.length,
                                    itemBuilder: (context, index) {
                                      final part = _spareParts[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: const Icon(Icons.settings,
                                              color: Color(0xFF0a543d)),
                                          title: Text(part['name']),
                                          subtitle: Text(
                                              'Quantité: ${part['quantity']}'),
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
                        const SizedBox(height: 32),
                      ],

                      // ════════════════════════════════════════
                      // BOUTON VALIDER / SOUMETTRE
                      // ════════════════════════════════════════
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitReport,
                          icon: Icon(
                            isInitial ? Icons.play_arrow : Icons.send,
                            size: 24,
                          ),
                          label: Text(
                            isInitial
                                ? 'Valider & Démarrer l\'intervention'
                                : 'Soumettre le rapport',
                            style: const TextStyle(fontSize: 18),
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
