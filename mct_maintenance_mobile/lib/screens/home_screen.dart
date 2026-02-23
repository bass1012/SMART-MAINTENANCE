import 'package:flutter/material.dart';
import 'admin/suggest_technicians_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue sur MCT Maintenance Mobile'),
            const SizedBox(height: 40),

            // Bouton de test pour suggestions techniciens
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuggestTechniciansScreen(
                      interventionId: 141,
                      interventionTitle: 'Réparation fuite eau - Test',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_search),
              label: const Text('🧪 Test Suggestions Techniciens'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
