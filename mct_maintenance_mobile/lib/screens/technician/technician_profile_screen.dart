import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mct_maintenance_mobile/screens/technician/edit_profile_screen.dart';
import 'package:mct_maintenance_mobile/utils/avatar_helper.dart';
import '../../utils/snackbar_helper.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(response['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiService.getTechnicianStats();
      if (mounted && response['success']) {
        setState(() {
          _stats = response['data'];
        });
      }
    } catch (e) {
      print('⚠️ Erreur chargement stats: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      print('📸 [PROFILE] Image sélectionnée: ${image.path}');
      setState(() => _isUploading = true);

      final imageFilename = await _apiService.uploadAvatar(image.path);
      print('📸 [PROFILE] Filename reçu du serveur: $imageFilename');

      if (mounted) {
        setState(() {
          if (_user != null) {
            _user = UserModel(
              id: _user!.id,
              email: _user!.email,
              firstName: _user!.firstName,
              lastName: _user!.lastName,
              phone: _user!.phone,
              role: _user!.role,
              profileImage: imageFilename,
            );
            print(
                '📸 [PROFILE] ProfileImage mis à jour: ${_user!.profileImage}');
          }
          _isUploading = false;
        });

        SnackBarHelper.showSuccess(
            context, 'Photo de profil mise à jour avec succès',
            emoji: '📸');
      }
    } catch (e) {
      print('❌ [PROFILE] Erreur upload: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Mon Profil',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_user == null) return;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: _user!),
                ),
              );

              // Si le profil a été modifié avec succès, recharger
              if (result == true) {
                _loadProfile();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/background_tech_2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenu
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // En-tête avec photo de profil
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0a543d),
                            Color(0xFF0d6b4d),
                            Color(0xFF0f7d59)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white24,
                                backgroundImage:
                                    AvatarHelper.hasAvatar(_user?.profileImage)
                                        ? NetworkImage(
                                            AvatarHelper.buildAvatarUrl(
                                                _user!.profileImage))
                                        : null,
                                child: _user?.profileImage == null ||
                                        _user!.profileImage!.isEmpty
                                    ? Text(
                                        (_user?.firstName?.isNotEmpty == true
                                                ? _user!.firstName![0]
                                                : 'T')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 20,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: _isUploading
                                        ? null
                                        : _pickAndUploadImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                    .trim()
                                    .isNotEmpty
                                ? '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                    .trim()
                                : 'Technicien',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _user?.email ?? 'Email non disponible',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Technicien',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informations personnelles
                    _buildSection(
                      title: 'Informations personnelles',
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          label: 'Nom complet',
                          value: '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                  .trim()
                                  .isNotEmpty
                              ? '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'
                                  .trim()
                              : 'Non défini',
                        ),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _user?.email ?? 'Non défini',
                        ),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: _user?.phone ?? 'Non défini',
                        ),
                      ],
                    ),

                    // Informations professionnelles
                    _buildSection(
                      title: 'Informations professionnelles',
                      children: [
                        _buildInfoTile(
                          icon: Icons.work_outline,
                          label: 'Spécialisation',
                          value: 'Climatisation, Plomberie',
                        ),
                        _buildInfoTile(
                          icon: Icons.star_outline,
                          label: 'Évaluation',
                          value: _stats != null
                              ? '${_stats!['average_rating']?.toStringAsFixed(1) ?? '0.0'}/5 (${_stats!['total_reviews'] ?? 0} avis)'
                              : 'Chargement...',
                        ),
                        _buildInfoTile(
                          icon: Icons.verified_outlined,
                          label: 'Statut',
                          value: 'Vérifié',
                        ),
                      ],
                    ),

                    // Statistiques
                    _buildSection(
                      title: 'Statistiques',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'Interventions',
                                      value:
                                          '${_stats?['total_interventions'] ?? 0}',
                                      icon: Icons.assignment_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'Complétées',
                                      value:
                                          '${_stats?['completed_interventions'] ?? 0}',
                                      icon: Icons.check_circle_outline,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'En cours',
                                      value:
                                          '${_stats?['in_progress_interventions'] ?? 0}',
                                      icon: Icons.pending_actions_outlined,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'Note moyenne',
                                      value:
                                          '${_stats?['average_rating'] ?? 0.0}',
                                      icon: Icons.star_outline,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0a543d),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade600, color.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
