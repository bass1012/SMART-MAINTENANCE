import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/services/service_api_service.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/snackbar_helper.dart';
import '../../utils/test_keys.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/repair_service.dart';
import '../../models/installation_service.dart';
import 'diagnostic_payment_screen.dart';

class NewInterventionScreen extends StatefulWidget {
  final String? preSelectedType;
  final int? preSelectedOfferId;
  final int? preSelectedEquipmentCount;

  const NewInterventionScreen({
    super.key,
    this.preSelectedType,
    this.preSelectedOfferId,
    this.preSelectedEquipmentCount,
  });

  @override
  State<NewInterventionScreen> createState() => _NewInterventionScreenState();
}

class _NewInterventionScreenState extends State<NewInterventionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ServiceApiService _serviceApiService = ServiceApiService();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImages = 5;

  // Contrôleurs de formulaire
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _equipmentCountController = TextEditingController(text: '1');

  String _selectedPriority = 'normal';
  String? _selectedType;
  String? _selectedClimatiseurType;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;

  // Offres de maintenance
  List<Map<String, dynamic>> _maintenanceOffers = [];
  String? _selectedMaintenanceOffer;
  bool _isLoadingOffers = false;

  // Souscriptions actives et quota
  List<Map<String, dynamic>> _activeSubscriptions = [];
  int? _maxEquipmentAllowed; // Quota max disponible pour l'offre sélectionnée

  // Services de réparation
  List<RepairService> _repairServices = [];
  int? _selectedRepairServiceId;
  bool _isLoadingRepairServices = false;

  // Services d'installation
  List<InstallationService> _installationServices = [];
  int? _selectedInstallationServiceId;
  bool _isLoadingInstallationServices = false;

  // Frais de diagnostic (chargé depuis l'API)
  int _diagnosticFee = 4000; // Valeur par défaut

  @override
  void initState() {
    super.initState();
    // Charger les frais de diagnostic depuis l'API
    _loadDiagnosticFee();
    // Pré-remplir le nombre d'équipements si fourni
    if (widget.preSelectedEquipmentCount != null) {
      _equipmentCountController.text =
          widget.preSelectedEquipmentCount.toString();
    }
    // Si un type est pré-sélectionné, l'initialiser et charger les données correspondantes
    if (widget.preSelectedType != null) {
      _selectedType = widget.preSelectedType;
      // Charger les données appropriées selon le type
      if (_selectedType == 'Maintenance') {
        _loadMaintenanceOffersWithPreselection();
      } else if (_selectedType == 'repair') {
        _loadRepairServices();
      } else if (_selectedType == 'installation') {
        _loadInstallationServices();
      }
    }
  }

  Future<void> _loadDiagnosticFee() async {
    try {
      final response = await _apiService.getDiagnosticConfig();
      if (response['success'] == true && response['data'] != null) {
        final fee = response['data']['default_fee'];
        if (fee != null && mounted) {
          setState(() {
            _diagnosticFee = fee is int ? fee : (fee as num).toInt();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement frais diagnostic: $e');
      // Utiliser la valeur par défaut en cas d'erreur
    }
  }

  Future<void> _loadMaintenanceOffersWithPreselection() async {
    await _loadMaintenanceOffers();
    // Si un offre est pré-sélectionnée, la sélectionner après le chargement
    if (widget.preSelectedOfferId != null && _maintenanceOffers.isNotEmpty) {
      final offerIdStr = widget.preSelectedOfferId.toString();
      final offerExists =
          _maintenanceOffers.any((o) => o['id'].toString() == offerIdStr);
      if (offerExists) {
        setState(() {
          _selectedMaintenanceOffer = offerIdStr;
        });
        _updateQuotaForSelectedOffer(offerIdStr);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _equipmentCountController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceOffers() async {
    setState(() => _isLoadingOffers = true);
    try {
      final offers = await _apiService.getMaintenanceOffers();
      // Charger aussi les souscriptions actives
      final subscriptions = await _apiService.getSubscriptions();
      setState(() {
        _maintenanceOffers = offers
            .map((offer) => {
                  'id': offer.id,
                  'title': offer.title,
                  'price': offer.price,
                  'description': offer.description,
                })
            .toList();
        // Filtrer les souscriptions actives avec payment_status = paid
        _activeSubscriptions = (subscriptions as List)
            .where(
                (s) => s['status'] == 'active' && s['payment_status'] == 'paid')
            .map<Map<String, dynamic>>((s) => s as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors du chargement des offres: $e');
      }
    } finally {
      setState(() => _isLoadingOffers = false);
    }
  }

  void _updateQuotaForSelectedOffer(String? offerId) {
    if (offerId == null) {
      setState(() => _maxEquipmentAllowed = null);
      return;
    }

    // Chercher une souscription active pour cette offre
    Map<String, dynamic>? subscription;
    try {
      subscription = _activeSubscriptions.firstWhere(
        (s) => s['maintenance_offer_id'].toString() == offerId,
      );
    } catch (_) {
      subscription = null;
    }

    if (subscription != null) {
      final equipmentCount = subscription['equipment_count'] as int? ?? 1;
      final equipmentUsed = subscription['equipment_used'] as int? ?? 0;
      final remaining = equipmentCount - equipmentUsed;
      setState(() {
        _maxEquipmentAllowed = remaining > 0 ? remaining : null;
        // Note: on ne limite plus automatiquement - l'utilisateur peut dépasser et payer la différence
      });
    } else {
      setState(() => _maxEquipmentAllowed = null);
    }
  }

  Future<void> _loadRepairServices() async {
    setState(() => _isLoadingRepairServices = true);
    try {
      final services = await _serviceApiService.getActiveRepairServices();
      setState(() {
        _repairServices = services;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context,
            'Erreur lors du chargement des services de réparation: $e');
      }
    } finally {
      setState(() => _isLoadingRepairServices = false);
    }
  }

  Future<void> _loadInstallationServices() async {
    setState(() => _isLoadingInstallationServices = true);
    try {
      final services = await _serviceApiService.getActiveInstallationServices();
      setState(() {
        _installationServices = services;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context,
            'Erreur lors du chargement des services d\'installation: $e');
      }
    } finally {
      setState(() => _isLoadingInstallationServices = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Vérifier si c'est une réparation/dépannage ou installation (tous les jours autorisés)
    final bool isRepair =
        _selectedType == 'repair' || _selectedType == 'Réparation';
    final bool isInstallation = _selectedType == 'installation';
    final bool allDaysAllowed = isRepair || isInstallation;

    // Calculer la date initiale (demain ou lundi si dimanche pour maintenance/diagnostic)
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    // Si la date initiale est un dimanche et ce n'est pas réparation/installation, avancer au lundi
    if (!allDaysAllowed && initialDate.weekday == DateTime.sunday) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      fieldLabelText: 'Date',
      selectableDayPredicate: (date) {
        // Réparation et Installation: tous les jours autorisés
        if (allDaysAllowed) return true;
        // Autres types (maintenance, diagnostic): Lundi-Samedi uniquement
        if (date.weekday == DateTime.sunday) return false;
        return true;
      },
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final DateTime? selectedDate = _preferredDate;
    final bool isRepair =
        _selectedType == 'repair' || _selectedType == 'Réparation';
    final bool isInstallation = _selectedType == 'installation';

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Sélectionner l\'heure',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      hourLabelText: 'Heure',
      minuteLabelText: 'Minute',
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('fr', 'FR'),
          child: child,
        );
      },
    );

    if (picked != null) {
      if (selectedDate == null) {
        // Si pas de date sélectionnée, on accepte l'heure quand même
        setState(() {
          _preferredTime = picked;
        });
        return;
      }

      final int weekday = selectedDate.weekday;
      final int hour = picked.hour;
      final int minute = picked.minute;
      bool isValid = false;
      String errorMessage = '';

      if (isRepair) {
        // Réparation: tous les jours, jusqu'à 21h00
        if (hour >= 8 && (hour < 21 || (hour == 21 && minute == 0))) {
          isValid = true;
        } else {
          errorMessage = 'Les réparations sont disponibles de 8h00 à 21h00.';
        }
      } else if (isInstallation) {
        // Installation: tous les jours et week-ends jusqu'à 17h
        if (hour >= 8 && (hour < 17 || (hour == 17 && minute == 0))) {
          isValid = true;
        } else {
          errorMessage = 'Les installations sont disponibles de 8h00 à 17h00.';
        }
      } else {
        // Maintenance, Diagnostic
        if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
          // Lundi-vendredi : 8h00-17h30
          if ((hour >= 8 && hour < 17) || (hour == 17 && minute <= 30)) {
            isValid = true;
          } else {
            errorMessage = 'Horaires du lundi au vendredi: 8h00-17h30.';
          }
        } else if (weekday == DateTime.saturday) {
          // Samedi : 9h00-12h00
          if ((hour >= 9 && hour < 12) || (hour == 12 && minute == 0)) {
            isValid = true;
          } else {
            errorMessage = 'Horaires du samedi: 9h00-12h00.';
          }
        } else {
          errorMessage = 'Jour non disponible pour ce type d\'intervention.';
        }
      }

      if (isValid) {
        setState(() {
          _preferredTime = picked;
        });
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, errorMessage);
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context,
            'Les services de localisation sont désactivés',
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackBarHelper.showWarning(
              context,
              'Permission de localisation refusée',
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context,
            'Permission de localisation refusée définitivement. Activez-la dans les paramètres.',
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convertir les coordonnées en adresse
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        if (mounted) {
          setState(() {
            _addressController.text = address;
          });
          SnackBarHelper.showSuccess(
            context,
            'Localisation récupérée avec succès',
            emoji: '📍',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la récupération de la localisation: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      SnackBarHelper.showWarning(
        context,
        'Maximum $_maxImages photos autorisées',
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la prise de photo: $e',
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      SnackBarHelper.showWarning(
        context,
        'Maximum $_maxImages photos autorisées',
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la sélection de l\'image: $e',
        );
      }
    }
  }

  Future<void> _submitIntervention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_preferredDate == null) {
      SnackBarHelper.showWarning(
        context,
        'Veuillez sélectionner une date',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Récupérer l'ID du client depuis le token/profil
      final userData = await _apiService.getUserData();

      // Extraire l'ID en essayant différentes structures possibles
      final customerId = userData?['id'] ??
          userData?['user']?['id'] ??
          userData?['data']?['user']?['id'];

      print('🔍 [NewIntervention] UserData keys: ${userData?.keys.toList()}');
      print('🔍 [NewIntervention] CustomerId extrait: $customerId');

      if (customerId == null) {
        throw Exception('Impossible de récupérer l\'ID utilisateur');
      }

      // Combiner date et heure pour scheduled_date
      DateTime scheduledDateTime = _preferredDate!;
      if (_preferredTime != null) {
        scheduledDateTime = DateTime(
          _preferredDate!.year,
          _preferredDate!.month,
          _preferredDate!.day,
          _preferredTime!.hour,
          _preferredTime!.minute,
        );
      }

      // Préparer les données de la demande selon le format attendu par l'API
      // Générer un titre par défaut si le champ n'est pas affiché (Maintenance/Installation/Réparation)
      String title = _titleController.text.trim();
      if (title.isEmpty) {
        if (_selectedType == 'Maintenance') {
          title = 'Demande de maintenance';
        } else if (_selectedType == 'installation' &&
            _selectedInstallationServiceId != null) {
          // Utiliser le titre du service d'installation sélectionné
          final selectedService = _installationServices.firstWhere(
            (s) => s.id == _selectedInstallationServiceId,
          );
          title =
              'Installation: ${selectedService.title} - ${selectedService.model}';
        } else if (_selectedType == 'repair' &&
            _selectedRepairServiceId != null) {
          // Utiliser le titre du service de réparation sélectionné
          final selectedService = _repairServices.firstWhere(
            (s) => s.id == _selectedRepairServiceId,
          );
          title =
              'Dépannage: ${selectedService.title} - ${selectedService.model}';
        } else {
          title = 'Intervention ${_selectedType ?? ""}';
        }
      }

      final interventionData = {
        'title': title,
        'description': _descriptionController.text.trim(),
        'customer_id': customerId,
        'scheduled_date': scheduledDateTime.toIso8601String(),
        'priority': 'normal', // Priorité par défaut
        'status': 'pending',
        'address': _addressController.text.trim(),
        'intervention_type': _selectedType,
        'equipment_count': int.tryParse(_equipmentCountController.text) ?? 1,
      };

      // Ajouter l'offre de maintenance si le type est maintenance/Maintenance
      if (_selectedType == 'Maintenance' && _selectedMaintenanceOffer != null) {
        interventionData['maintenance_offer_id'] =
            int.parse(_selectedMaintenanceOffer!);
      }

      // Ajouter le service d'installation si le type est installation
      if (_selectedType == 'installation' &&
          _selectedInstallationServiceId != null) {
        interventionData['installation_service_id'] =
            _selectedInstallationServiceId;
      }

      // Ajouter le service de réparation si le type est repair
      if (_selectedType == 'repair' && _selectedRepairServiceId != null) {
        interventionData['repair_service_id'] = _selectedRepairServiceId;
      }

      // Appel API avec images (OPTION 1 - Multipart/Form-Data)
      Map<String, dynamic> createdIntervention;
      if (_selectedImages.isNotEmpty) {
        createdIntervention = await _apiService.createInterventionWithImages(
          data: interventionData,
          images: _selectedImages,
        );
      } else {
        // Sans images, utiliser la méthode classique
        createdIntervention =
            await _apiService.createIntervention(interventionData);
      }

      // Alternative: OPTION 2 - Base64 (décommenter pour utiliser)
      // await _apiService.createInterventionWithImagesBase64(
      //   data: interventionData,
      //   images: _selectedImages.isNotEmpty ? _selectedImages : null,
      // );

      if (mounted) {
        // Message personnalisé selon le type d'intervention
        String successMessage;
        if (_selectedType == 'installation') {
          successMessage =
              'Demande d\'installation créée. Après le diagnostic, vous recevrez un devis détaillé.';
        } else if (_selectedType == 'repair') {
          successMessage =
              'Demande de dépannage créée. Après le diagnostic, vous recevrez un devis détaillé.';
        } else {
          successMessage = 'Demande d\'intervention créée avec succès';
        }

        SnackBarHelper.showSuccess(
          context,
          successMessage,
          emoji: '🎉',
        );

        // Si c'est un diagnostic ou réparation avec frais, rediriger vers le paiement
        final interventionId = createdIntervention['data']?['intervention']
                ?['id'] ??
            createdIntervention['data']?['id'];

        // Récupérer le diagnostic_fee depuis la réponse (le backend calcule si paiement nécessaire)
        final createdInterventionData = createdIntervention['data']
                ?['intervention'] ??
            createdIntervention['data'];
        final diagnosticFeeFromServer = double.tryParse(
                createdInterventionData?['diagnostic_fee']?.toString() ??
                    '0') ??
            0;
        final isFreeDiagnosis =
            createdInterventionData?['is_free_diagnosis'] ?? true;

        if (!isFreeDiagnosis &&
            diagnosticFeeFromServer > 0 &&
            interventionId != null) {
          // Attendre un peu pour que l'utilisateur voie le message de succès
          await Future.delayed(const Duration(milliseconds: 800));

          // Utiliser le montant calculé par le backend
          double paymentAmount = diagnosticFeeFromServer;

          if (mounted) {
            // Naviguer vers l'écran de paiement
            final paymentResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiagnosticPaymentScreen(
                  interventionId: interventionId is int
                      ? interventionId
                      : int.parse(interventionId.toString()),
                  diagnosticFee: paymentAmount,
                ),
              ),
            );

            // Retourner avec le résultat du paiement
            if (mounted) {
              Navigator.pop(context, paymentResult ?? true);
            }
          }
        } else {
          // Pour les interventions gratuites (maintenance avec souscription active), retourner normalement
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nouvelle Intervention',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/call_center.png'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête informatif
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0a543d).withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.build_circle_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Décrivez votre besoin et nous vous mettrons en contact avec un technicien',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Type d'intervention
                Text(
                  'Type d\'intervention',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey(TestKeys.interventionTypeDropdown),
                    value: _selectedType,
                    decoration: InputDecoration(
                      hintText: 'Sélectionnez un type d\'intervention',
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0a543d), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.category_outlined,
                            color: Colors.white, size: 20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Maintenance',
                        child:
                            Text('Maintenance', style: GoogleFonts.poppins()),
                      ),
                      DropdownMenuItem(
                        value: 'repair',
                        child: Text('Dépannage (Diagnostic préalable)',
                            style: GoogleFonts.poppins()),
                      ),
                      DropdownMenuItem(
                        value: 'installation',
                        child: Text('Installation (Diagnostic préalable)',
                            style: GoogleFonts.poppins()),
                      ),
                      DropdownMenuItem(
                        value: 'diagnostic',
                        child: Text('Diagnostic', style: GoogleFonts.poppins()),
                      )
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un type d\'intervention';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _selectedMaintenanceOffer = null;
                        _selectedRepairServiceId = null;
                        _selectedInstallationServiceId = null;
                        _selectedClimatiseurType = null;
                        if (value == 'Maintenance') {
                          _loadMaintenanceOffers();
                        }
                        if (value == 'repair') {
                          _loadRepairServices();
                        }
                        if (value == 'installation') {
                          _loadInstallationServices();
                        }
                      });
                    },
                  ),
                ),

                // Message d'avertissement pour les réparations
                if (_selectedType == 'repair') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Des frais de diagnostic s\'appliquent. Un devis vous sera envoyé après le diagnostic.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Message d'avertissement pour les installations
                if (_selectedType == 'installation') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.build_outlined,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Des frais de diagnostic s\'appliquent. Un devis vous sera envoyé après le diagnostic.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Message d'avertissement pour les diagnostics
                if (_selectedType == 'diagnostic') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warning_outlined,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Frais de diagnostic: ${NumberFormat('#,###', 'fr_FR').format(_diagnosticFee)} FCFA. Un devis vous sera envoyé après le diagnostic.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Offres de maintenance (visible seulement si type = Maintenance)
                if (_selectedType == 'Maintenance') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Offre de maintenance',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0a543d),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingOffers
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: ButtonLoadingIndicator(
                                color: Color(0xFF0a543d),
                                size: 8.0,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedMaintenanceOffer,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Sélectionnez une offre de maintenance',
                              hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF0a543d), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0a543d),
                                      Color(0xFF0d6b4d)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_offer_outlined,
                                    color: Colors.white, size: 20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            items: _maintenanceOffers.map((offer) {
                              final title = offer['title'] ?? '';
                              final price = offer['price'] ?? 0;
                              return DropdownMenuItem<String>(
                                value: offer['id'].toString(),
                                child: Text(
                                  '$title - ${price.toStringAsFixed(0)} FCFA',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (_selectedType == 'Maintenance' &&
                                  (value == null || value.isEmpty)) {
                                return 'Veuillez sélectionner une offre de maintenance';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() => _selectedMaintenanceOffer = value);
                              _updateQuotaForSelectedOffer(value);
                            },
                          ),
                  ),
                  // Affichage du prix total calculé
                  if (_selectedMaintenanceOffer != null) ...[
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      Map<String, dynamic>? offer;
                      try {
                        offer = _maintenanceOffers.firstWhere(
                          (o) =>
                              o['id'].toString() == _selectedMaintenanceOffer,
                        );
                      } catch (_) {
                        offer = null;
                      }
                      final unitPrice =
                          (offer?['price'] as num?)?.toDouble() ?? 0;
                      final equipCount =
                          int.tryParse(_equipmentCountController.text) ?? 1;

                      // Calculer la répartition
                      final quotaRemaining = _maxEquipmentAllowed ?? 0;
                      final equipmentCovered = quotaRemaining > 0
                          ? (equipCount <= quotaRemaining
                              ? equipCount
                              : quotaRemaining)
                          : 0;
                      final equipmentToPay = equipCount - equipmentCovered;
                      final costToPay = unitPrice * equipmentToPay;

                      // Vérifier s'il y a une souscription active
                      final hasActiveSubscription =
                          _maxEquipmentAllowed != null &&
                              _maxEquipmentAllowed! > 0;
                      final isFullyCovered =
                          hasActiveSubscription && equipmentToPay == 0;
                      final isPartiallyCovered =
                          hasActiveSubscription && equipmentToPay > 0;

                      Color bgColor;
                      Color borderColor;
                      Color textColor;
                      IconData icon;
                      String message;

                      if (isFullyCovered) {
                        bgColor = Colors.green.withOpacity(0.1);
                        borderColor = Colors.green.withOpacity(0.3);
                        textColor = Colors.green[700]!;
                        icon = Icons.check_circle;
                        message =
                            'Couvert par votre souscription ($equipCount équipement(s) sur $quotaRemaining disponible(s))';
                      } else if (isPartiallyCovered) {
                        bgColor = Colors.orange.withOpacity(0.1);
                        borderColor = Colors.orange.withOpacity(0.3);
                        textColor = Colors.orange[700]!;
                        icon = Icons.info;
                        message =
                            '$equipmentCovered couvert(s) + $equipmentToPay à payer: ${costToPay.toStringAsFixed(0)} FCFA';
                      } else {
                        bgColor = Colors.blue.withOpacity(0.1);
                        borderColor = Colors.blue.withOpacity(0.3);
                        textColor = Colors.blue[700]!;
                        icon = Icons.payment;
                        message =
                            'Total: ${(unitPrice * equipCount).toStringAsFixed(0)} FCFA ($equipCount × ${unitPrice.toStringAsFixed(0)} FCFA)';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: textColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                message,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  // Nombre d'équipements (pour maintenance)
                  const SizedBox(height: 16),
                  Text(
                    'Nombre d\'équipements',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      key: const ValueKey(
                          TestKeys.interventionEquipmentCountField),
                      controller: _equipmentCountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                        ),
                        hintText: '1',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 14),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.format_list_numbered,
                              color: Colors.white, size: 20),
                        ),
                        helperText: _maxEquipmentAllowed != null
                            ? '$_maxEquipmentAllowed gratuit(s), au-delà sera facturé'
                            : 'Nombre d\'équipements concernés',
                        helperStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _maxEquipmentAllowed != null
                              ? Colors.green
                              : null,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer le nombre d\'équipements';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1) {
                          return 'Veuillez entrer un nombre valide (minimum 1)';
                        }
                        // Note: pas de blocage si dépasse le quota - les équipements supplémentaires seront facturés
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],

                // Sélection du service d'installation (pour type installation)
                if (_selectedType == 'installation') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Service d\'installation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoadingInstallationServices
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0a543d),
                              ),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: _selectedInstallationServiceId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF0a543d), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                              hintText: 'Sélectionner un service',
                              hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 14),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0a543d),
                                      Color(0xFF0d6b4d)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.ac_unit_outlined,
                                    color: Colors.white, size: 20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            dropdownColor: Colors.white,
                            items: _installationServices.map((service) {
                              return DropdownMenuItem<int>(
                                value: service.id,
                                child: Text(
                                  '${service.title} - ${service.model}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (_selectedType == 'installation' &&
                                  value == null) {
                                return 'Veuillez sélectionner un service d\'installation';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(
                                  () => _selectedInstallationServiceId = value);
                            },
                          ),
                  ),
                  // Afficher la disponibilité du service sélectionné
                  if (_selectedInstallationServiceId != null) ...[
                    Builder(builder: (context) {
                      final selectedService = _installationServices.firstWhere(
                        (s) => s.id == _selectedInstallationServiceId,
                        orElse: () => _installationServices.first,
                      );
                      if (selectedService.availabilityInfo != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedService.availabilityInfo!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                  const SizedBox(height: 16),
                ],

                // Sélection du service de dépannage (pour type repair)
                if (_selectedType == 'repair') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Service de dépannage',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoadingRepairServices
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0a543d),
                              ),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: _selectedRepairServiceId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF0a543d), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                              hintText: 'Sélectionner un service',
                              hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 14),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0a543d),
                                      Color(0xFF0d6b4d)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.build_outlined,
                                    color: Colors.white, size: 20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            dropdownColor: Colors.white,
                            items: _repairServices.map((service) {
                              return DropdownMenuItem<int>(
                                value: service.id,
                                child: Text(
                                  '${service.title} - ${service.model}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (_selectedType == 'repair' && value == null) {
                                return 'Veuillez sélectionner un service de dépannage';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() => _selectedRepairServiceId = value);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Titre (caché pour Maintenance, Installation et Réparation)
                if (_selectedType != 'Maintenance' &&
                    _selectedType != 'installation' &&
                    _selectedType != 'repair') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Titre de la demande',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      key: const ValueKey(TestKeys.interventionTitleField),
                      controller: _titleController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                        ),
                        hintText: 'Ex: Panne de chaudière',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 14),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.title_outlined,
                              color: Colors.white, size: 20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (_selectedType != 'Maintenance' &&
                            _selectedType != 'installation' &&
                            _selectedType != 'repair' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Espacement si le titre est caché
                if (_selectedType == 'Maintenance' ||
                    _selectedType == 'installation' ||
                    _selectedType == 'repair')
                  const SizedBox(height: 16),

                // Description avec label et placeholder personnalisés selon le type
                Text(
                  _selectedType == 'installation'
                      ? 'Emplacement de l\'installation'
                      : _selectedType == 'Maintenance'
                          ? 'Emplacement et description du problème'
                          : 'Emplacement et description du problème',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    key: const ValueKey(TestKeys.interventionDescriptionField),
                    controller: _descriptionController,
                    maxLines: 5,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0a543d), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      hintText: _selectedType == 'Maintenance'
                          ? 'Ex: Piece de la maison concernée'
                          : _selectedType == 'repair'
                              ? 'Parlez-nous du problème et de la pièce de la maison concernée'
                              : _selectedType == 'installation'
                                  ? 'Dites-nous la pièce de la maison concernée'
                                  : _selectedType == 'diagnostic'
                                      ? 'Parlez-nous du problème et de la pièce de la maison concernée'
                                      : 'Ex: La chaudière est au sous-sol. Elle ne démarre plus depuis ce matin...',
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                      alignLabelWithHint: true,
                      helperText: _selectedType == 'installation'
                          ? 'Précisez la pièce où sera installé l\'équipement'
                          : _selectedType == 'Maintenance'
                              ? 'Précisez la pièce où se trouve l\'équipement'
                              : 'Précisez l\'emplacement de l\'appareil et le problème',
                      helperStyle: GoogleFonts.poppins(fontSize: 12),
                      helperMaxLines: 2,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Adresse
                Text(
                  'Adresse d\'intervention',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    key: const ValueKey(TestKeys.interventionAddressField),
                    controller: _addressController,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0a543d), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      hintText: 'Ex: 15 Rue de la Paix, Cocody, Abidjan',
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                      helperText: 'Adresse complète avec quartier et ville',
                      helperStyle: GoogleFonts.poppins(fontSize: 12),
                      alignLabelWithHint: true,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer une adresse';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _isLoadingLocation ? 0.5 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0a543d).withOpacity(0.1),
                          const Color(0xFF0d6b4d).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed:
                          _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF0a543d)),
                            )
                          : const Icon(Icons.my_location,
                              color: Color(0xFF0a543d), size: 20),
                      label: Text(
                        _isLoadingLocation
                            ? 'Localisation en cours...'
                            : 'Utiliser ma position actuelle si vous êtes sur place',
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Photos (optionnelles)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Photos (optionnelles)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (_selectedImages.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0a543d).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_selectedImages.length}/$_maxImages',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Grille d'images
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
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
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Boutons d'ajout
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectedImages.length < _maxImages
                                    ? _pickImageFromCamera
                                    : null,
                                icon: const Icon(Icons.camera_alt, size: 20),
                                label: const Text('Photo',
                                    style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0a543d),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectedImages.length < _maxImages
                                    ? _pickImageFromGallery
                                    : null,
                                icon: const Icon(Icons.photo_library, size: 20),
                                label: const Text('Galerie',
                                    style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0a543d),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jusqu\'à $_maxImages photos pour aider le technicien',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date préférée
                Text(
                  'Date souhaitée',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today_outlined,
                              color: Colors.white, size: 20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      child: Text(
                        _preferredDate != null
                            ? DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                                .format(_preferredDate!)
                            : 'Sélectionner une date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _preferredDate != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Heure préférée (optionnel)
                Text(
                  'Heure souhaitée (optionnel)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.access_time_outlined,
                              color: Colors.white, size: 20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      child: Text(
                        _preferredTime != null
                            ? '${_preferredTime!.hour.toString().padLeft(2, '0')}:${_preferredTime!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner une heure',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _preferredTime != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton de soumission
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0a543d),
                        Color(0xFF0d6b4d),
                        Color(0xFF0f7d59)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0a543d).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    key: const ValueKey(TestKeys.interventionSubmitButton),
                    onPressed: _isLoading ? null : _submitIntervention,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading
                        ? SizedBox(
                            width: 45,
                            child: ButtonLoadingIndicator(
                              color: Colors.white,
                              size: 6.0,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 24),
                    label: Text(
                      _isLoading ? 'Envoi en cours...' : 'Envoyer ma demande',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
