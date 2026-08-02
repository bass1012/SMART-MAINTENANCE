import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran d'accueil racine.
/// Redirige automatiquement vers le bon tableau de bord selon le rôle
/// via le RouterGuard défini dans main.dart.
/// Cet écran ne s'affiche qu'en cas de problème de routage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 72,
              color: Color(0xFF0a543d),
            ),
            const SizedBox(height: 24),
            Text(
              'MCT Maintenance',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chargement en cours…',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF0a543d),
            ),
          ],
        ),
      ),
    );
  }
}
