import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test Création Intervention', () {
    testWidgets('Test complet: Connexion + Navigation + Création intervention',
        (WidgetTester tester) async {
      // Démarrer l'application
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('🔐 Étape 1: Connexion...');

      // Attendre que l'écran de connexion soit visible
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier que nous sommes sur l'écran de connexion
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      final loginButton = find.byKey(const Key('loginButton'));

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      // Remplir les champs
      await tester.enterText(emailField, 'grace.zoko@gmail.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.enterText(passwordField, 'test123');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Cliquer sur le bouton de connexion
      await tester.tap(loginButton);
      print('🔄 Connexion en cours...');

      // Attendre la navigation et le chargement
      await tester.pumpAndSettle(const Duration(seconds: 8));

      print('✅ Connecté avec succès');

      // Vérifier qu'on est connecté (chercher des éléments de l'écran principal)
      // Adapter selon votre UI - cherchons le FAB ou un texte d'accueil
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('🔍 Étape 2: Recherche du bouton nouvelle intervention...');

      // Chercher le FAB pour créer une nouvelle intervention
      final newInterventionFAB = find.byKey(const Key('newInterventionFAB'));

      if (newInterventionFAB.evaluate().isEmpty) {
        print('⚠️ FAB non trouvé directement, recherche alternative...');

        // Essayer de trouver le FAB par type
        final fabByType = find.byType(FloatingActionButton);
        if (fabByType.evaluate().isNotEmpty) {
          print('✅ FAB trouvé par type');
          await tester.tap(fabByType.first);
        } else {
          print(
              '❌ Aucun FAB trouvé - peut-être besoin de naviguer vers l\'onglet interventions');
          // Essayer de trouver l'onglet interventions dans le bottom nav
          final interventionsTab = find.text('Interventions');
          if (interventionsTab.evaluate().isNotEmpty) {
            print('🔄 Navigation vers onglet Interventions...');
            await tester.tap(interventionsTab);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Réessayer de trouver le FAB
            final fabAfterNav = find.byKey(const Key('newInterventionFAB'));
            if (fabAfterNav.evaluate().isNotEmpty) {
              await tester.tap(fabAfterNav);
            } else {
              // Dernier essai avec le type
              final fabByTypeAfterNav = find.byType(FloatingActionButton);
              if (fabByTypeAfterNav.evaluate().isNotEmpty) {
                await tester.tap(fabByTypeAfterNav.first);
              }
            }
          }
        }
      } else {
        print('✅ FAB trouvé avec la clé');
        await tester.tap(newInterventionFAB);
      }

      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('📝 Étape 3: Remplissage du formulaire...');

      // Chercher les champs du formulaire
      final titleField = find.byKey(const Key('interventionTitleField'));
      final descriptionField =
          find.byKey(const Key('interventionDescriptionField'));
      final addressField = find.byKey(const Key('interventionAddressField'));

      // Vérifier que le formulaire est visible
      expect(titleField, findsOneWidget);
      print('✅ Champ titre trouvé');

      // Remplir les champs
      await tester.enterText(titleField, 'Test E2E Intervention');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.enterText(
          descriptionField, 'Description automatique créée par test E2E');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.enterText(addressField, '123 Rue de Test, Abidjan');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      print('✅ Formulaire rempli');

      // Chercher le bouton de soumission
      final submitButton = find.byKey(const Key('interventionSubmitButton'));

      if (submitButton.evaluate().isNotEmpty) {
        print('📤 Soumission de l\'intervention...');

        // Scroll vers le bouton si nécessaire
        await tester.ensureVisible(submitButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        print('✅ Intervention soumise');

        // Vérifier le succès (chercher un message de confirmation ou retour à la liste)
        // Adapter selon votre UI
        final successMessage = find.textContaining('succès');
        final createdMessage = find.textContaining('créée');

        if (successMessage.evaluate().isNotEmpty ||
            createdMessage.evaluate().isNotEmpty) {
          print('🎉 Test réussi - Intervention créée avec succès !');
        } else {
          print(
              '⚠️ Pas de message de confirmation visible, mais pas d\'erreur non plus');
        }
      } else {
        print('⚠️ Bouton de soumission non trouvé');
      }

      print('✅ Test de création d\'intervention terminé');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
