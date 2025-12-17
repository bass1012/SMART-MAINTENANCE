import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/screens/auth/login_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/profile_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/history_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/invoices_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/support_screen.dart';
import 'package:mct_maintenance_mobile/screens/customer/settings_screen.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';

class ModernProfileMenu {
  final BuildContext context;
  final UserModel? user;
  final ApiService apiService;

  ModernProfileMenu({
    required this.context,
    required this.user,
    required this.apiService,
  });

  // Bouton de profil moderne
  Widget buildProfileButton() {
    return GestureDetector(
      onTap: showModernMenu,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.white24, Colors.white12],
          ),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Center(
          child: Text(
            user != null &&
                    user!.firstName != null &&
                    user!.firstName!.isNotEmpty
                ? user!.firstName![0].toUpperCase()
                : '?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Menu moderne en bottom sheet
  void showModernMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // En-tête avec profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0a543d).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user != null &&
                                user!.firstName != null &&
                                user!.firstName!.isNotEmpty
                            ? '${user!.firstName![0]}${user!.lastName != null && user!.lastName!.isNotEmpty ? user!.lastName![0] : ''}'
                                .toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? '${user!.firstName ?? ''} ${user!.lastName ?? ''}'
                                  .trim()
                              : 'Utilisateur',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0a543d),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            // Menu items
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Mon Profil',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.history_outlined,
              title: 'Historique',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Factures',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InvoicesScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SupportScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Déconnexion',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Annuler', style: GoogleFonts.poppins()),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            Text('Déconnexion', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  try {
                    await apiService.logout();
                  } catch (e) {
                    // Ignorer les erreurs
                  }
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF0a543d)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color ?? const Color(0xFF0a543d),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
