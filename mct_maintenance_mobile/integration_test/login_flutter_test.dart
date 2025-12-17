import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test connexion complète', (WidgetTester tester) async {
    print('🚀 DÉMARRAGE TEST CONNEXION');

    // Lancer l'application
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('✅ App lancée');

    // Vérifier que l'écran de connexion est affiché
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final loginButton = find.byKey(const Key('loginButton'));

    expect(emailField, findsOneWidget, reason: 'Champ email doit être présent');
    expect(passwordField, findsOneWidget,
        reason: 'Champ mot de passe doit être présent');
    expect(loginButton, findsOneWidget,
        reason: 'Bouton connexion doit être présent');

    print('✅ Champs de connexion trouvés');

    // Remplir les champs
    await tester.enterText(emailField, 'grace.zoko@gmail.com');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.enterText(passwordField, 'test123');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    print('✅ Champs remplis');

    // Cliquer sur connexion
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    print('✅ Bouton connexion cliqué');

    // Attendre la navigation et la réponse de l'API
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Vérifier la navigation vers le dashboard
    // L'écran de connexion ne devrait plus être visible
    expect(find.byKey(const Key('emailField')), findsNothing,
        reason: 'Doit avoir quitté écran connexion');

    // Le FAB de nouvelle intervention devrait être visible
    final newInterventionFAB = find.byKey(const Key('newInterventionFAB'));
    expect(newInterventionFAB, findsOneWidget,
        reason: 'Dashboard doit afficher le FAB');

    print('✅ Test connexion complète réussi');
  });
}
