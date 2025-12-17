import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tests Simples Flutter', () {
    testWidgets('Test 1: Démarrage app', (WidgetTester tester) async {
      // Démarrer l'application
      app.main();
      await tester.pumpAndSettle();

      // Vérifier qu'un widget MaterialApp existe
      expect(find.byType(MaterialApp), findsOneWidget);
      print('✅ Test démarrage réussi');
    });

    testWidgets('Test 2: Champs connexion présents',
        (WidgetTester tester) async {
      // Démarrer l'application
      app.main();
      await tester.pumpAndSettle();

      // Attendre que l'écran de connexion soit visible
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier les champs de connexion
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      final loginButton = find.byKey(const Key('loginButton'));

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      print('✅ Test connexion réussi');
    });

    testWidgets('Test 3: Connexion complète', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Attendre l'écran de connexion
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Remplir les champs
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'grace.zoko@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'P@ssword',
      );

      // Cliquer sur le bouton
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Attendre la navigation (API call + navigation)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Vérifier qu'on est sur l'écran principal
      // Rechercher des éléments typiques de l'écran d'accueil
      // (adapter selon votre UI - cherchons FAB ou texte "Interventions")
      final hasNavigated =
          find.byKey(const Key('newInterventionFAB')).evaluate().isNotEmpty ||
              find.text('Interventions').evaluate().isNotEmpty;

      expect(hasNavigated, isTrue,
          reason: 'La navigation vers l\'écran principal a échoué');

      print('✅ Test connexion complète réussi');
    });
  });
}
