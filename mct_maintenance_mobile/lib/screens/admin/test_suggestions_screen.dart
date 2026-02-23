import 'package:flutter/material.dart';

/// Écran de test pour accéder rapidement à la fonctionnalité de suggestions
/// 
/// Usage:
/// 1. Ajouter dans main.dart ou home_screen.dart
/// 2. Naviguer vers cet écran
/// 3. Tester les différents scénarios
///
class TestSuggestionsScreen extends StatelessWidget {
  const TestSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Suggestions'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestCard(
            context,
            title: 'Test Intervention 141',
            subtitle: 'Plomberie - 2 techniciens attendus',
            interventionId: 141,
            interventionTitle: 'Réparation fuite eau',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            context,
            title: 'Test Intervention 139',
            subtitle: 'Déjà assignée - devrait échouer',
            interventionId: 139,
            interventionTitle: 'Maintenance climatisation',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            context,
            title: 'Test Intervention 999',
            subtitle: 'N\'existe pas - devrait afficher erreur',
            interventionId: 999,
            interventionTitle: 'Test erreur 404',
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '📝 Notes de Test:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.check_circle,
            title: 'Backend requis',
            description:
                'Le serveur API doit tourner sur localhost:3000',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.person,
            title: 'Connexion admin',
            description:
                'Utilisateur: admin@mct-maintenance.com\nMot de passe: P@ssword',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Géolocalisation',
            description:
                'Les techniciens ont des coordonnées GPS à Abidjan',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int interventionId,
    required String interventionTitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            interventionId.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _DynamicSuggestionScreen(
                interventionId: interventionId,
                interventionTitle: interventionTitle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget dynamique pour charger le vrai écran avec lazy import
class _DynamicSuggestionScreen extends StatelessWidget {
  final int interventionId;
  final String interventionTitle;

  const _DynamicSuggestionScreen({
    required this.interventionId,
    required this.interventionTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Import dynamique pour éviter les erreurs si le fichier n'existe pas
    try {
      // ignore: unused_local_variable
      final screen = _loadScreen();
      return screen;
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Écran suggestions non disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erreur: $e',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Vérifier que le fichier existe:\nlib/screens/admin/suggest_technicians_screen.dart',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _loadScreen() {
    // Import du vrai écran
    // ignore: unnecessary_import
    import '../admin/suggest_technicians_screen.dart';
    
    return SuggestTechniciansScreen(
      interventionId: interventionId,
      interventionTitle: interventionTitle,
    );
  }
}
