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
  const NewInterventionScreen({super.key});

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

  // Offres d'entretien
  List<Map<String, dynamic>> _maintenanceOffers = [];
  String? _selectedMaintenanceOffer;
  bool _isLoadingOffers = false;

  // Services de réparation
  List<RepairService> _repairServices = [];
  int? _selectedRepairServiceId;
  bool _isLoadingRepairServices = false;

  // Services d'installation
  List<InstallationService> _installationServices = [];
  int? _selectedInstallationServiceId;
  bool _isLoadingInstallationServices = false;

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
      setState(() {
        _maintenanceOffers = offers
            .map((offer) => {
                  'id': offer.id,
                  'title': offer.title,
                  'price': offer.price,
                  'description': offer.description,
                })
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      fieldLabelText: 'Date',
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
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
      setState(() {
        _preferredTime = picked;
      });
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
      // Générer un titre par défaut si le champ n'est pas affiché (Entretien/Installation/Réparation)
      String title = _titleController.text.trim();
      if (title.isEmpty) {
        if (_selectedType == 'Entretien') {
          title = 'Demande d\'entretien';
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
              'Réparation: ${selectedService.title} - ${selectedService.model}';
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

      // Ajouter l'offre d'entretien si le type est maintenance/Entretien
      if (_selectedType == 'Entretien' && _selectedMaintenanceOffer != null) {
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
        SnackBarHelper.showSuccess(
          context,
          'Demande d\'intervention créée avec succès',
          emoji: '🎉',
        );

        // Si c'est un diagnostic, réparation, installation ou entretien sans souscription, rediriger vers le paiement
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
          // Pour les interventions gratuites (entretien avec souscription active), retourner normalement
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
      body: SingleChildScrollView(
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
                      borderSide:
                          const BorderSide(color: Color(0xFF0a543d), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
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
                      value: 'Entretien',
                      child: Text('Entretien', style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'repair',
                      child: Text('Réparation (Diagnostic préalable)',
                          style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'installation',
                      child: Text('Installation', style: GoogleFonts.poppins()),
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
                      if (value == 'Entretien') {
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
                          'Un devis vous sera envoyé avant le début de l\'intervention',
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
                          'Un devis vous sera envoyé après le diagnostic',
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

              // Offres d'entretien (visible seulement si type = Entretien)
              if (_selectedType == 'Entretien') ...[
                const SizedBox(height: 16),
                Text(
                  'Offre d\'entretien',
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
                          decoration: InputDecoration(
                            hintText: 'Sélectionnez une offre d\'entretien',
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
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
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
                            return DropdownMenuItem<String>(
                              value: offer['id'].toString(),
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (value) {
                            if (_selectedType == 'Entretien' &&
                                (value == null || value.isEmpty)) {
                              return 'Veuillez sélectionner une offre d\'entretien';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => _selectedMaintenanceOffer = value);
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
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
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
                          isExpanded: true,
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
                const SizedBox(height: 16),
              ],

              // Sélection du service de réparation (pour type repair)
              if (_selectedType == 'repair') ...[
                const SizedBox(height: 16),
                Text(
                  'Service de réparation',
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
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
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
                          isExpanded: true,
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
                              return 'Veuillez sélectionner un service de réparation';
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

              // Titre (caché pour Entretien, Installation et Réparation)
              if (_selectedType != 'Entretien' &&
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
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
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
                      if (_selectedType != 'Entretien' &&
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
              if (_selectedType == 'Entretien' ||
                  _selectedType == 'installation' ||
                  _selectedType == 'repair')
                const SizedBox(height: 16),

              // Description avec label et placeholder personnalisés selon le type
              Text(
                _selectedType == 'installation'
                    ? 'Emplacement de l\'installation'
                    : _selectedType == 'Entretien'
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
                      borderSide:
                          const BorderSide(color: Color(0xFF0a543d), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    hintText: _selectedType == 'Entretien'
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
                        : _selectedType == 'Entretien'
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
                      borderSide:
                          const BorderSide(color: Color(0xFF0a543d), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0a543d).withOpacity(0.1),
                      const Color(0xFF0d6b4d).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
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
                      color: const Color(0xFF0a543d),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nombre d'équipements
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
                  key: const ValueKey(TestKeys.interventionEquipmentCountField),
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
                      borderSide:
                          const BorderSide(color: Color(0xFF0a543d), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    hintText: '1',
                    hintStyle:
                        GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
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
                    helperText:
                        'Nombre d\'équipements concernés par l\'intervention',
                    helperStyle: GoogleFonts.poppins(fontSize: 12),
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
                    return null;
                  },
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
    );
  }
}
