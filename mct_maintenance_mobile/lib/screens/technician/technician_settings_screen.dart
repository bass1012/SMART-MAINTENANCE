import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';

class TechnicianSettingsScreen extends StatefulWidget {
  const TechnicianSettingsScreen({super.key});

  @override
  State<TechnicianSettingsScreen> createState() =>
      _TechnicianSettingsScreenState();
}

class _TechnicianSettingsScreenState extends State<TechnicianSettingsScreen> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = true;

  // Préférences notifications
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _vibrationEnabled = false;

  // Spécialisations
  List<String> _specializations = [];

  // Horaires de travail
  Map<String, Map<String, dynamic>> _workingHours = {
    'Lundi': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'Mardi': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'Mercredi': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'Jeudi': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'Vendredi': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'Samedi': {'enabled': false, 'start': '08:00', 'end': '18:00'},
    'Dimanche': {'enabled': false, 'start': '08:00', 'end': '18:00'},
  };

  // Zone d'intervention
  List<String> _serviceAreas = [];

  // Langue
  String _selectedLanguage = 'Français';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(response['data']);

          // Charger les spécialisations depuis le profil
          final profile = response['data']['profile'];
          if (profile != null && profile['specialization'] != null) {
            final spec = profile['specialization'];
            if (spec is String) {
              _specializations = spec.split(',').map((s) => s.trim()).toList();
            } else if (spec is List) {
              _specializations = List<String>.from(spec);
            }
          }

          // Charger les zones d'intervention
          if (profile != null && profile['service_area'] != null) {
            final areas = profile['service_area'];
            if (areas is String) {
              _serviceAreas = areas.split(',').map((s) => s.trim()).toList();
            } else if (areas is List) {
              _serviceAreas = List<String>.from(areas);
            }
          }

          // Charger les horaires de travail
          if (profile != null && profile['working_hours'] != null) {
            final hours = profile['working_hours'];
            if (hours is Map) {
              // Charger les horaires personnalisés en s'assurant des valeurs par défaut
              for (var entry in hours.entries) {
                final day = entry.key.toString();
                if (_workingHours.containsKey(day) && entry.value is Map) {
                  final dayHours = entry.value as Map;
                  _workingHours[day] = {
                    'enabled': dayHours['enabled'] == true,
                    'start': dayHours['start']?.toString() ?? '08:00',
                    'end': dayHours['end']?.toString() ?? '18:00',
                  };
                }
              }
            }
          }

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
          'Paramètres',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
              : ListView(
                  children: [
                    const SizedBox(height: 16),

                // Section Compte
                _buildSectionHeader('Compte'),
                _buildSettingTile(
                  icon: Icons.person_outline,
                  title: 'Informations personnelles',
                  subtitle: 'Nom, prénom, téléphone',
                  onTap: () => _showEditProfileDialog(),
                ),
                _buildSettingTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: _user?.email ?? 'Non défini',
                  onTap: () {
                    SnackBarHelper.showInfo(
                        context, 'Modifier email - À implémenter');
                  },
                ),
                _buildSettingTile(
                  icon: Icons.lock_outline,
                  title: 'Mot de passe',
                  subtitle: 'Modifier votre mot de passe',
                  onTap: () => _showChangePasswordDialog(),
                ),

                const Divider(),

                // Section Professionnel
                _buildSectionHeader('Professionnel'),
                _buildSettingTile(
                  icon: Icons.work_outline,
                  title: 'Spécialisation',
                  subtitle: _specializations.isEmpty
                      ? 'Aucune spécialisation sélectionnée'
                      : _specializations.join(', '),
                  onTap: () => _showSpecializationDialog(),
                ),
                _buildSettingTile(
                  icon: Icons.schedule_outlined,
                  title: 'Horaires de travail',
                  subtitle: _getWorkingDaysText(),
                  onTap: () => _showWorkingHoursDialog(),
                ),
                _buildSettingTile(
                  icon: Icons.location_on_outlined,
                  title: 'Zone d\'intervention',
                  subtitle: _serviceAreas.isEmpty
                      ? 'Aucune zone sélectionnée'
                      : _serviceAreas.join(', '),
                  onTap: () => _showServiceAreasDialog(),
                ),

                const Divider(),

                // Section Notifications
                _buildSectionHeader('Notifications'),
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications push',
                  subtitle: 'Recevoir des notifications sur votre téléphone',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    if (value) {
                      SnackBarHelper.showSuccess(
                          context, 'Notifications push activées');
                    } else {
                      SnackBarHelper.showWarning(
                          context, 'Notifications push désactivées');
                    }
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Notifications email',
                  subtitle:
                      'Recevoir des emails pour les nouvelles interventions',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    if (value) {
                      SnackBarHelper.showSuccess(
                          context, 'Notifications email activées',
                          emoji: '✉️');
                    } else {
                      SnackBarHelper.showWarning(
                          context, 'Notifications email désactivées');
                    }
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.vibration_outlined,
                  title: 'Vibration',
                  subtitle: 'Vibrer lors des notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    if (value) {
                      SnackBarHelper.showSuccess(context, 'Vibration activée');
                    } else {
                      SnackBarHelper.showWarning(
                          context, 'Vibration désactivée');
                    }
                  },
                ),

                const Divider(),

                // Section Application
                _buildSectionHeader('Application'),
                _buildSettingTile(
                  icon: Icons.language_outlined,
                  title: 'Langue',
                  subtitle: _selectedLanguage,
                  onTap: () => _showLanguageDialog(),
                ),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: 'Aide & Support',
                  subtitle: 'Obtenir de l\'aide',
                  onTap: () => _showHelpDialog(),
                ),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(),
                ),

                const SizedBox(height: 32),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0a543d),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
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
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0a543d),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureCurrentPassword = !obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: obscureCurrentPassword,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureNewPassword = !obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: obscureNewPassword,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: obscureConfirmPassword,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  SnackBarHelper.showWarning(
                      context, 'Les mots de passe ne correspondent pas');
                  return;
                }

                try {
                  await _apiService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showSuccess(
                        context, 'Mot de passe modifié avec succès',
                        emoji: '🔒');
                  }
                } catch (e) {
                  SnackBarHelper.showError(context, e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final firstNameController =
        TextEditingController(text: _user?.firstName ?? '');
    final lastNameController =
        TextEditingController(text: _user?.lastName ?? '');
    final phoneController = TextEditingController(text: _user?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
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
              if (firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty) {
                SnackBarHelper.showWarning(
                    context, 'Le prénom et le nom sont requis');
                return;
              }

              try {
                await _apiService.updateProfile({
                  'first_name': firstNameController.text,
                  'last_name': lastNameController.text,
                  'phone': phoneController.text,
                });

                if (mounted) {
                  Navigator.pop(context);
                  _loadProfile(); // Recharger le profil
                  SnackBarHelper.showSuccess(
                      context, 'Profil mis à jour avec succès',
                      emoji: '🎉');
                }
              } catch (e) {
                SnackBarHelper.showError(context, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showSpecializationDialog() {
    // Initialiser avec les spécialisations actuelles
    final specializations = {
      'Climatisation': _specializations.contains('Climatisation'),
      'Plomberie': _specializations.contains('Plomberie'),
      'Électricité': _specializations.contains('Électricité'),
      'Chauffage': _specializations.contains('Chauffage'),
      'Réfrigération': _specializations.contains('Réfrigération'),
      'VMC': _specializations.contains('VMC'),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Spécialisations'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: specializations.keys.map((spec) {
                return CheckboxListTile(
                  title: Text(spec),
                  value: specializations[spec],
                  onChanged: (value) {
                    setDialogState(() {
                      specializations[spec] = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selected = specializations.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                Navigator.pop(context);

                // Sauvegarder via l'API
                try {
                  await _apiService.updateProfile({
                    'specialization': selected.join(', '),
                  });

                  // Mettre à jour l'état local
                  if (mounted) {
                    setState(() {
                      _specializations = selected;
                    });

                    SnackBarHelper.showSuccess(
                        context,
                        selected.isEmpty
                            ? 'Spécialisations supprimées'
                            : 'Spécialisations: ${selected.join(", ")}');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarHelper.showError(
                        context, 'Erreur lors de la sauvegarde: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Aide & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                Icons.phone,
                'Téléphone',
                '+225 07 66 66 66',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.email,
                'Email',
                'support@mct-maintenance.com',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.schedule,
                'Horaires',
                'Lun - Ven: 8h - 18h',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'FAQ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFaqItem(
                'Comment accepter une intervention ?',
                'Allez dans "Mes Interventions" et cliquez sur "Accepter"',
              ),
              _buildFaqItem(
                'Comment modifier mes disponibilités ?',
                'Utilisez le menu "Disponibilités" dans le drawer',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String label, String value) {
    return Row(
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

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkingDaysText() {
    final activeDays =
        _workingHours.entries.where((e) => e.value['enabled'] == true).toList();

    if (activeDays.isEmpty) {
      return 'Aucun jour sélectionné';
    } else if (activeDays.length == 7) {
      final firstDay = activeDays.first.value;
      final start = firstDay['start']?.toString() ?? '08:00';
      final end = firstDay['end']?.toString() ?? '18:00';
      return 'Tous les jours ($start - $end)';
    } else if (activeDays.length == 5 &&
        _workingHours['Samedi']!['enabled'] == false &&
        _workingHours['Dimanche']!['enabled'] == false) {
      final firstDay = activeDays.first.value;
      final start = firstDay['start']?.toString() ?? '08:00';
      final end = firstDay['end']?.toString() ?? '18:00';
      return 'Lun - Ven ($start - $end)';
    } else {
      return '${activeDays.length} jour${activeDays.length > 1 ? "s" : ""}/7';
    }
  }

  void _showWorkingHoursDialog() {
    // Créer une copie profonde avec valeurs garanties
    final tempWorkingHours = Map<String, Map<String, dynamic>>.from(
        _workingHours.map((key, value) => MapEntry(key, {
              'enabled': value['enabled'] == true,
              'start': value['start']?.toString() ?? '08:00',
              'end': value['end']?.toString() ?? '18:00',
            })));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Horaires de travail'),
              IconButton(
                icon: const Icon(Icons.copy_all, size: 20),
                tooltip: 'Copier à tous',
                onPressed: () {
                  // Trouver le premier jour activé
                  final firstEnabled = tempWorkingHours.entries.firstWhere(
                      (e) => e.value['enabled'] == true,
                      orElse: () => tempWorkingHours.entries.first);

                  final startToCopy =
                      firstEnabled.value['start']?.toString() ?? '08:00';
                  final endToCopy =
                      firstEnabled.value['end']?.toString() ?? '18:00';

                  setDialogState(() {
                    for (var day in tempWorkingHours.keys) {
                      tempWorkingHours[day]!['start'] = startToCopy;
                      tempWorkingHours[day]!['end'] = endToCopy;
                    }
                  });

                  SnackBarHelper.showInfo(
                      context, 'Horaires copiés à tous les jours',
                      duration: const Duration(seconds: 1));
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tempWorkingHours.keys.map((day) {
                final dayData = tempWorkingHours[day]!;
                final isEnabled = dayData['enabled'] == true;
                final startTime = dayData['start']?.toString() ?? '08:00';
                final endTime = dayData['end']?.toString() ?? '18:00';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: isEnabled,
                        onChanged: (value) {
                          setDialogState(() {
                            dayData['enabled'] = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      if (isEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour:
                                            int.parse(startTime.split(':')[0]),
                                        minute:
                                            int.parse(startTime.split(':')[1]),
                                      ),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        dayData['start'] =
                                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 20),
                                        const SizedBox(width: 8),
                                        Text(startTime),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('-'),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: int.parse(endTime.split(':')[0]),
                                        minute:
                                            int.parse(endTime.split(':')[1]),
                                      ),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        dayData['end'] =
                                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 20),
                                        const SizedBox(width: 8),
                                        Text(endTime),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await _apiService.updateWorkingHours(tempWorkingHours);

                  if (mounted) {
                    setState(() {
                      _workingHours = tempWorkingHours;
                    });

                    SnackBarHelper.showSuccess(context, 'Horaires mis à jour',
                        emoji: '⏰');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarHelper.showError(context, e.toString());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceAreasDialog() {
    final areas = {
      'Plateau': _serviceAreas.contains('Plateau'),
      'Cocody': _serviceAreas.contains('Cocody'),
      'Yopougon': _serviceAreas.contains('Yopougon'),
      'Marcory': _serviceAreas.contains('Marcory'),
      'Treichville': _serviceAreas.contains('Treichville'),
      'Abobo': _serviceAreas.contains('Abobo'),
      'Adjamé': _serviceAreas.contains('Adjamé'),
      'Koumassi': _serviceAreas.contains('Koumassi'),
      'Port-Bouët': _serviceAreas.contains('Port-Bouët'),
      'Attécoubé': _serviceAreas.contains('Attécoubé'),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Zones d\'intervention'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: areas.keys.map((area) {
                return CheckboxListTile(
                  title: Text(area),
                  value: areas[area],
                  onChanged: (value) {
                    setDialogState(() {
                      areas[area] = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selected = areas.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                Navigator.pop(context);

                try {
                  await _apiService.updateProfile({
                    'service_area': selected,
                  });

                  if (mounted) {
                    setState(() {
                      _serviceAreas = selected;
                    });

                    SnackBarHelper.showSuccess(
                        context,
                        selected.isEmpty
                            ? 'Zones supprimées'
                            : 'Zones: ${selected.join(", ")}',
                        emoji: '📍');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarHelper.showError(context, e.toString());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['Français', 'English', 'العربية'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                Navigator.pop(context);
                setState(() {
                  _selectedLanguage = value!;
                });
                SnackBarHelper.showSuccess(context, 'Langue changée: $value',
                    emoji: '🌍');
              },
              activeColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'MCT Maintenance',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.engineering,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const Text('Application de gestion de maintenance pour techniciens.'),
        const SizedBox(height: 16),
        Text(
          'Développé par MCT © 2025',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
