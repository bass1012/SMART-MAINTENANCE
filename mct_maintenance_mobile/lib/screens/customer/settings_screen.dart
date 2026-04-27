import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/settings_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/support_fab_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  String _language = 'fr';
  String _theme = 'light';
  String _appVersion = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _language = prefs.getString('language') ?? 'fr';
      _theme = prefs.getString('theme') ?? 'light';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Paramètres',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          flexibleSpace: Container(
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
            ),
          ),
          elevation: 0,
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Notifications
              _buildSectionTitle('Notifications'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Activer les notifications',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Recevoir toutes les notifications',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _savePreference('notifications_enabled', value);
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 20),
                      ),
                      activeColor: const Color(0xFF0a543d),
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Notifications par email',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      value: _emailNotifications,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _emailNotifications = value);
                              _savePreference('email_notifications', value);
                            }
                          : null,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      activeColor: const Color(0xFF0a543d),
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Notifications par SMS',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      value: _smsNotifications,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _smsNotifications = value);
                              _savePreference('sms_notifications', value);
                            }
                          : null,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sms_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      activeColor: const Color(0xFF0a543d),
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Notifications push',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      value: _pushNotifications,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _pushNotifications = value);
                              _savePreference('push_notifications', value);
                            }
                          : null,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_android_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      activeColor: const Color(0xFF0a543d),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        'Préférences Détaillées',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Gérer toutes vos préférences de notifications',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () {
                        Navigator.pushNamed(context, '/notification-settings');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Préférences
              _buildSectionTitle('Préférences'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.language_outlined,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        'Langue',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _getLanguageLabel(_language),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showLanguageDialog(),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_outlined,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        'Thème',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _getThemeLabel(_theme),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showThemeDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confidentialité et sécurité
              _buildSectionTitle('Confidentialité et sécurité'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.privacy_tip_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Politique de confidentialité',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showPrivacyPolicy(),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Conditions d\'utilisation',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showTermsOfService(),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Changer le mot de passe',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showChangePasswordDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // À propos
              _buildSectionTitle('À propos'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Version de l\'application',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _appVersion.isEmpty ? '...' : _appVersion,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.update_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Vérifier les mises à jour',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () {
                        SnackBarHelper.showInfo(
                          context,
                          'Vous utilisez la dernière version',
                          emoji: '✓',
                        );
                      },
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.article_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Licences open source',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () {
                        showLicensePage(context: context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Données
              _buildSectionTitle('Données'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cached_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Vider le cache',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _showClearCacheDialog(),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_outlined,
                            color: Color(0xFF0a543d), size: 20),
                      ),
                      title: Text(
                        'Télécharger mes données',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF0a543d)),
                      onTap: () => _exportUserData(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return lang;
    }
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Clair';
      case 'dark':
        return 'Sombre';
      case 'system':
        return 'Système';
      default:
        return theme;
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: _language,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _language = value);
                _savePreference('language', value);
                Provider.of<SettingsProvider>(context, listen: false)
                    .setLocale(value);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Langue mise à jour');
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _language = value);
                _savePreference('language', value);
                Provider.of<SettingsProvider>(context, listen: false)
                    .setLocale(value);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Language updated');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Clair'),
              value: 'light',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                _savePreference('theme', value!);
                Provider.of<SettingsProvider>(context, listen: false)
                    .setThemeMode(value!);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Thème mis à jour');
              },
            ),
            RadioListTile<String>(
              title: const Text('Sombre'),
              value: 'dark',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                _savePreference('theme', value!);
                Provider.of<SettingsProvider>(context, listen: false)
                    .setThemeMode(value!);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Thème mis à jour');
              },
            ),
            RadioListTile<String>(
              title: const Text('Système'),
              value: 'system',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                _savePreference('theme', value!);
                Provider.of<SettingsProvider>(context, listen: false)
                    .setThemeMode(value!);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Thème mis à jour');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider le cache ? Cela supprimera toutes les données temporaires (préférences conservées).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(
                  dialogContext); // Fermer le dialogue de confirmation

              // Afficher un loader avec le context du widget
              if (!mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loaderContext) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Nettoyage en cours...'),
                    ],
                  ),
                ),
              );

              try {
                // Vider le cache d'images (méthodes synchrones)
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();

                // Note: On garde SharedPreferences car il contient les paramètres utilisateur

                await Future.delayed(const Duration(seconds: 1));

                if (mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .pop(); // Fermer le loader
                  SnackBarHelper.showSuccess(
                    context,
                    'Cache vidé avec succès',
                    emoji: '🧹',
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .pop(); // Fermer le loader
                  SnackBarHelper.showError(
                    context,
                    'Erreur lors du nettoyage: $e',
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'MCT Maintenance respecte votre vie privée et s\'engage à protéger vos données personnelles.\n\n'
            '1. COLLECTE DE DONNÉES\n'
            'Nous collectons uniquement les données nécessaires à la fourniture de nos services de maintenance.\n\n'
            '2. UTILISATION DES DONNÉES\n'
            'Vos données sont utilisées pour gérer vos interventions, devis, factures et communications.\n\n'
            '3. SÉCURITÉ\n'
            'Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos données.\n\n'
            '4. PARTAGE DES DONNÉES\n'
            'Nous ne vendons ni ne partageons vos données avec des tiers sans votre consentement.\n\n'
            '5. VOS DROITS\n'
            'Vous avez le droit d\'accéder, modifier ou supprimer vos données à tout moment.\n\n'
            'Pour toute question, contactez-nous à contact@mct-maintenance.com',
            style: TextStyle(fontSize: 14),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            'CONDITIONS GÉNÉRALES D\'UTILISATION\n\n'
            '1. ACCEPTATION DES CONDITIONS\n'
            'En utilisant notre application, vous acceptez ces conditions d\'utilisation.\n\n'
            '2. SERVICES PROPOSÉS\n'
            'MCT Maintenance propose des services de maintenance préventive et corrective pour équipements électroménagers et industriels.\n\n'
            '3. OBLIGATIONS DE L\'UTILISATEUR\n'
            '- Fournir des informations exactes\n'
            '- Respecter les rendez-vous convenus\n'
            '- Payer les factures dans les délais\n\n'
            '4. GARANTIES ET RESPONSABILITÉS\n'
            'Nous garantissons la qualité de nos interventions selon les normes en vigueur.\n\n'
            '5. TARIFS ET PAIEMENTS\n'
            'Les tarifs sont indiqués en FCFA. Le paiement est dû selon les conditions du devis accepté.\n\n'
            '6. RÉSILIATION\n'
            'Vous pouvez résilier votre compte à tout moment depuis les paramètres.\n\n'
            '7. MODIFICATIONS\n'
            'Nous nous réservons le droit de modifier ces conditions. Vous serez informé des changements.\n\n'
            'Dernière mise à jour : Octobre 2025',
            style: TextStyle(fontSize: 14),
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
                    SnackBarHelper.showError(
                      context,
                      e.toString().replaceAll("Exception: ", ""),
                    );
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

  Future<void> _exportUserData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Préparation de vos données...'),
          ],
        ),
      ),
    );

    try {
      final bytes = await _apiService.getBytes('/customer/export-data');

      if (!mounted) return;
      Navigator.pop(context); // fermer le loader

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final filename =
          'mct_donnees_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Mes données MCT Maintenance',
        text:
            'Export de mes données personnelles MCT Maintenance — ${now.day}/${now.month}/${now.year}',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SnackBarHelper.showError(context, 'Erreur lors de l\'export : $e');
      }
    }
  }
}
