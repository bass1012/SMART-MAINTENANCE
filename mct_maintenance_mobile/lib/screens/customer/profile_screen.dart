import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';
import 'package:mct_maintenance_mobile/widgets/common/support_fab_wrapper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/snackbar_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPickingImage = false; // Protection contre les appels multiples
  UserModel? _user;
  File? _selectedImage;

  // Contrôleurs
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(userData['data']);
          _firstNameController.text = _user?.firstName ?? '';
          _lastNameController.text = _user?.lastName ?? '';
          _emailController.text = _user?.email ?? '';
          _phoneController.text = _user?.phone ?? '';
          _latitudeController.text = _user?.latitude?.toString() ?? '';
          _longitudeController.text = _user?.longitude?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _pickImage() async {
    // Protection contre les appels multiples (double tap)
    if (_isPickingImage) {
      print('⚠️ Sélection d\'image déjà en cours, ignorer le double tap');
      return;
    }

    try {
      setState(() => _isPickingImage = true);

      final ImagePicker picker = ImagePicker();

      if (!mounted) {
        setState(() => _isPickingImage = false);
        return;
      }

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null && mounted) {
        try {
          final XFile? image = await picker.pickImage(
            source: source,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 85,
          );

          if (image != null && mounted) {
            print('✅ Image sélectionnée: ${image.path}');
            setState(() {
              _selectedImage = File(image.path);
            });
            print('✅ _selectedImage défini: ${_selectedImage?.path}');

            if (mounted) {
              SnackBarHelper.showSuccess(
                context,
                'Image sélectionnée avec succès - Cliquez sur Enregistrer',
                emoji: '📸',
                duration: const Duration(seconds: 3),
              );
            }
          } else {
            print('⚠️ Aucune image sélectionnée ou widget non monté');
          }
        } catch (e) {
          print('❌ Erreur lors de la sélection de l\'image: $e');
          if (mounted) {
            SnackBarHelper.showError(
              context,
              source == ImageSource.camera
                  ? 'Erreur d\'accès à la caméra. Vérifiez les permissions dans les paramètres.'
                  : 'Erreur d\'accès à la galerie. Vérifiez les permissions dans les paramètres.',
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Erreur générale dans _pickImage: $e');
      if (mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    } finally {
      // Toujours réinitialiser le flag, même en cas d'erreur
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context,
            'Les services de localisation sont désactivés',
          );
        }
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackBarHelper.showError(
              context,
              'Permission de localisation refusée',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Permission de localisation refusée définitivement. Activez-la dans les paramètres.',
          );
        }
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });

        SnackBarHelper.showSuccess(
          context,
          'Position GPS récupérée avec succès',
          emoji: '📍',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la récupération de la position: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    print('🚀 _saveProfile appelé');
    print('📝 _selectedImage: ${_selectedImage?.path}');

    if (!_formKey.currentState!.validate()) {
      print('❌ Validation du formulaire échouée');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Préparer les données à envoyer
      final Map<String, dynamic> updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Ajouter latitude/longitude si présentes
      final latitude = double.tryParse(_latitudeController.text.trim());
      if (latitude != null) {
        updateData['latitude'] = latitude;
      }
      final longitude = double.tryParse(_longitudeController.text.trim());
      if (longitude != null) {
        updateData['longitude'] = longitude;
      }

      print('📦 updateData initial: $updateData');

      // Upload de l'image si une nouvelle image a été sélectionnée
      if (_selectedImage != null) {
        print('🖼️ Une nouvelle image a été sélectionnée, upload en cours...');
        try {
          print('📤 Upload de l\'avatar en cours...');
          print('📁 Chemin du fichier: ${_selectedImage!.path}');

          final imageUrl = await _apiService.uploadAvatar(_selectedImage!.path);
          print('✅ Avatar uploadé avec succès !');
          print('🔗 URL retournée: $imageUrl');

          // Extraire uniquement le nom du fichier depuis l'URL
          // L'URL retournée est du format: /uploads/avatars/avatar-123-1234567890.jpg
          String filename = imageUrl;
          if (imageUrl.contains('/')) {
            filename = imageUrl.split('/').last;
          }

          print('📝 Nom du fichier extrait: $filename');
          print('🖼️ Ancienne image: ${_user?.profileImage}');

          updateData['profile_image'] = filename;
          print('📦 Données à envoyer: $updateData');
        } catch (e) {
          print('❌ Erreur upload avatar: $e');
          if (mounted) {
            SnackBarHelper.showWarning(
              context,
              'Erreur lors de l\'upload de l\'image: $e',
            );
          }
          // Ne pas continuer si l'upload échoue
          setState(() => _isSaving = false);
          return;
        }
      }

      print('🚀 Mise à jour du profil...');
      print('📦 updateData final: $updateData');

      // Appel API pour mettre à jour le profil
      final response = await _apiService.updateProfile(updateData);
      print('✅ Réponse updateProfile: $response');

      if (mounted) {
        // Recharger le profil pour afficher les nouvelles données
        await _loadUserProfile();

        setState(() {
          _isEditing = false;
          _isSaving = false;
          _selectedImage = null; // Réinitialiser l'image sélectionnée
        });

        SnackBarHelper.showSuccess(
          context,
          'Profil mis à jour avec succès',
          emoji: '🎉',
        );

        // Retourner true pour indiquer que le profil a été mis à jour
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Mon Profil',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF0a543d),
          elevation: 0,
          actions: [
            if (!_isEditing && !_isLoading)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, size: 20),
                  ),
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                ),
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF0a543d),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // En-tête moderne avec gradient
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0a543d),
                              Color(0xFF0d6b4d),
                              Color(0xFF0f7d59),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF0a543d),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar avec ombre et effet glassmorphism
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: _buildAvatar(),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0a543d),
                                            Color(0xFF0d6b4d)
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        onPressed: _pickImage,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!_isEditing) ...[
                              Text(
                                '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                    .trim(),
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _user?.email ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Formulaire avec cards modernes
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Informations personnelles
                              _buildSectionTitle('Informations personnelles'),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _firstNameController,
                                label: 'Prénom',
                                icon: Icons.person_outline,
                                enabled: _isEditing,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le prénom est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _lastNameController,
                                label: 'Nom',
                                icon: Icons.person_outline,
                                enabled: _isEditing,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le nom est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Coordonnées
                              _buildSectionTitle('Coordonnées'),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                enabled: _isEditing,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  // Email optionnel mais doit être valide si fourni
                                  if (value != null &&
                                      value.trim().isNotEmpty) {
                                    if (!value.contains('@')) {
                                      return 'Email invalide';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _phoneController,
                                label: 'Téléphone',
                                icon: Icons.phone_outlined,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le téléphone est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Géolocalisation
                              _buildSectionTitle('Localisation'),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _latitudeController,
                                      label: 'Latitude',
                                      icon: Icons.location_on_outlined,
                                      enabled: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _longitudeController,
                                      label: 'Longitude',
                                      icon: Icons.location_on_outlined,
                                      enabled: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),

                              if (_isEditing) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _isLoadingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  icon: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.my_location),
                                  label: Text(_isLoadingLocation
                                      ? 'Récupération...'
                                      : 'Obtenir ma position actuelle'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Informations du compte
                              _buildSectionTitle('Informations du compte'),
                              const SizedBox(height: 16),

                              _buildInfoCard(
                                icon: Icons.badge_outlined,
                                label: 'Rôle',
                                value: _getRoleLabel(_user?.role ?? ''),
                              ),
                              const SizedBox(height: 12),

                              _buildInfoCard(
                                icon: Icons.verified_outlined,
                                label: 'Statut',
                                value: _getStatusLabel(_user?.status ?? ''),
                              ),
                              const SizedBox(height: 12),

                              _buildInfoCard(
                                icon: Icons.calendar_today_outlined,
                                label: 'Membre depuis',
                                value: _formatDate(_user?.createdAt),
                              ),
                              const SizedBox(height: 24),

                              // Actions rapides
                              if (!_isEditing) ...[
                                _buildSectionTitle('Actions'),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  icon: Icons.lock_outline,
                                  label: 'Changer le mot de passe',
                                  onTap: _showChangePasswordDialog,
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'Supprimer mon compte',
                                  color: Colors.red,
                                  onTap: _showDeleteAccountDialog,
                                ),
                              ],

                              // Boutons d'action modernes en mode édition
                              if (_isEditing) ...[
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF0a543d),
                                            width: 2,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _isSaving
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _isEditing = false;
                                                      // Restaurer les valeurs originales
                                                      _firstNameController
                                                              .text =
                                                          _user?.firstName ??
                                                              '';
                                                      _lastNameController.text =
                                                          _user?.lastName ?? '';
                                                      _emailController.text =
                                                          _user?.email ?? '';
                                                      _phoneController.text =
                                                          _user?.phone ?? '';
                                                      _latitudeController
                                                          .text = _user
                                                              ?.latitude
                                                              ?.toString() ??
                                                          '';
                                                      _longitudeController
                                                          .text = _user
                                                              ?.longitude
                                                              ?.toString() ??
                                                          '';
                                                      _selectedImage = null;
                                                    });
                                                  },
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Center(
                                              child: Text(
                                                'Annuler',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF0a543d),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0a543d),
                                              Color(0xFF0d6b4d)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0a543d)
                                                  .withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap:
                                                _isSaving ? null : _saveProfile,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Center(
                                              child: _isSaving
                                                  ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Enregistrer',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    Widget avatarContent;

    if (_selectedImage != null) {
      avatarContent = ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_user?.profileImage != null && _user!.profileImage!.isNotEmpty) {
      // Construire l'URL complète de l'image
      String imageUrl;
      if (_user!.profileImage!.startsWith('http')) {
        // URL complète
        imageUrl = _user!.profileImage!;
      } else if (_user!.profileImage!.startsWith('/')) {
        // Chemin relatif avec /
        imageUrl = '${AppConfig.baseUrl}${_user!.profileImage!}';
      } else {
        // Juste le nom du fichier
        imageUrl =
            '${AppConfig.baseUrl}/uploads/avatars/${_user!.profileImage!}';
      }

      // Utiliser le nom du fichier comme clé de cache unique
      // Cela force le rechargement quand le fichier change
      final cacheKey = _user!.profileImage!.split('/').last;

      print('🖼️ Affichage avatar: $imageUrl');
      print('🔑 Cache key: $cacheKey');

      avatarContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheKey: cacheKey,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) => SizedBox(
            width: 120,
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            print('❌ Erreur chargement image: $error');
            print('🔗 URL tentée: $url');
            return _buildInitialsAvatar();
          },
        ),
      );
    } else {
      avatarContent = _buildInitialsAvatar();
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white,
      child: avatarContent,
    );
  }

  Widget _buildInitialsAvatar() {
    String initials = '';
    if (_user?.firstName != null && _user!.firstName!.isNotEmpty) {
      initials += _user!.firstName![0].toUpperCase();
    }
    if (_user?.lastName != null && _user!.lastName!.isNotEmpty) {
      initials += _user!.lastName![0].toUpperCase();
    }
    if (initials.isEmpty) {
      initials = '?';
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0a543d),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: enabled ? const Color(0xFF0a543d) : Colors.grey[500],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        const Color(0xFF0a543d).withOpacity(0.1),
                        const Color(0xFF0d6b4d).withOpacity(0.1)
                      ]
                    : [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.1)
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? const Color(0xFF0a543d) : Colors.grey[500],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0a543d), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0a543d).withOpacity(0.1),
                  const Color(0xFF0d6b4d).withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0a543d), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFF0a543d);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: buttonColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: buttonColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'customer':
        return 'Client';
      case 'technician':
        return 'Technicien';
      case 'admin':
        return 'Administrateur';
      default:
        return role;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Minimum 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _apiService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showSuccess(
                      context,
                      'Mot de passe changé avec succès',
                      emoji: '🔒',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showError(context, e.toString());
                  }
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Supprimer mon compte',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible !',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toutes vos données seront définitivement supprimées :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Votre profil et informations personnelles\n'
              '• Vos interventions et historiques\n'
              '• Vos équipements enregistrés\n'
              '• Vos contrats et documents',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pour confirmer, entrez votre mot de passe :',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (password.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer votre mot de passe'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Utiliser email ou téléphone selon ce qui est disponible
                final String contact = (_user?.email?.isNotEmpty == true)
                    ? _user!.email!
                    : (_user?.phone ?? '');

                // Vérifier d'abord le mot de passe en essayant de se connecter
                await _apiService.login(
                  contact,
                  password,
                );

                // Si la connexion réussit, supprimer le compte
                await _apiService.deleteMyAccount();

                // Fermer le dialog AVANT de dispose le controller
                navigator.pop();

                // Déconnecter (peut échouer car le compte est supprimé, on ignore l'erreur)
                try {
                  await _apiService.logout();
                } catch (e) {
                  // Ignorer l'erreur 401 du logout car le compte est déjà inactif
                  print('ℹ️ Erreur logout ignorée (compte déjà supprimé): $e');
                }

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Votre compte a été supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Rediriger vers l'écran de login
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}
