import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/invoices_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/support_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/profile_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/settings_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/history_screen.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(userData['data']);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données si elles ont changé
    if (!_isLoading && _user == null) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            accountName: _isLoading
                ? const Text('Chargement...')
                : _errorMessage != null
                    ? Text(_errorMessage!)
                    : Text(
                        '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim().isNotEmpty
                            ? '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim()
                            : 'Utilisateur',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
            accountEmail: _isLoading
                ? const Text('')
                : _errorMessage != null
                    ? const Text('')
                    : Text(_user?.email ?? 'Email non disponible'),
            otherAccountsPictures: [
              if (!_isLoading && _errorMessage == null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    // Si le profil a été mis à jour, recharger les données
                    if (result == true && mounted) {
                      _loadUserData();
                    }
                  },
                ),
            ],
            currentAccountPicture: _buildProfilePicture(),
          ),
          
          // Options de menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Accueil',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Naviguer vers l'accueil
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mon Profil',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    // Si le profil a été mis à jour, recharger les données
                    if (result == true && mounted) {
                      _loadUserData();
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_outlined,
                  title: 'Historique',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Factures',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoicesScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Aide & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Pied de page
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    if (_isLoading) {
      return const CircleAvatar(
        backgroundColor: Colors.white24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return const CircleAvatar(
        backgroundColor: Colors.white24,
        child: Icon(Icons.error_outline, size: 40, color: Colors.white),
      );
    }

    // Si l'utilisateur a une image de profil
    if (_user?.profileImage != null && _user!.profileImage!.isNotEmpty) {
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
        imageUrl = '${AppConfig.baseUrl}/uploads/avatars/${_user!.profileImage!}';
      }
      
      return CircleAvatar(
        backgroundColor: Colors.white24,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Drawer - Erreur chargement image: $error');
              print('🔗 Drawer - URL tentée: $imageUrl');
              return _buildInitialsAvatar();
            },
          ),
        ),
      );
    }

    return _buildInitialsAvatar();
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

    return CircleAvatar(
      backgroundColor: Colors.white24,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Déconnexion'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          // Afficher une boîte de dialogue de confirmation
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );

          if (shouldLogout == true && mounted) {
            try {
              // Appeler la méthode de déconnexion de l'API
              await _apiService.logout();
            } catch (e) {
              // Ignorer les erreurs de déconnexion
            }
            
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }
}
