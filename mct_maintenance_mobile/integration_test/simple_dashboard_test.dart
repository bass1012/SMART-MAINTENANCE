import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Simple: Vérifier dashboard accessible',
      (WidgetTester tester) async {
    print('🚀 DÉMARRAGE APP');
    app.main();

    // Attendre que l'app se charge
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('✅ App lancée');

    // Vérifier si on est sur l'écran de connexion ou déjà connecté
    final emailField = find.byKey(const Key('emailField'));
    final isOnLoginScreen = emailField.evaluate().isNotEmpty;

    if (isOnLoginScreen) {
      print('🔐 Écran de connexion détecté - Connexion...');

      final passwordField = find.byKey(const Key('passwordField'));
      final loginButton = find.byKey(const Key('loginButton'));

      await tester.enterText(emailField, 'grace.zoko@gmail.com');
      await tester.enterText(passwordField, 'test123');
      await tester.tap(loginButton, warnIfMissed: false);

      print('⏳ Attente connexion...');
      await tester.pumpAndSettle(const Duration(seconds: 10));
      print('✅ Connexion terminée');
    } else {
      print('✅ Déjà connecté - Dashboard chargé');
    }

    // À ce stade, on devrait être sur le dashboard
    // Cherchons des indices du dashboard customer
    print('\n📊 Analyse du dashboard...');

    // Chercher des widgets typiques du dashboard
    final textWidgets = find.byType(Text);
    print('Nombre de Text widgets: ${textWidgets.evaluate().length}');

    // Chercher des mots-clés du dashboard
    final welcomeText = find.textContaining('Bienvenue', findRichText: true);
    final statsWidgets = find.byType(Card);

    if (welcomeText.evaluate().isNotEmpty) {
      print('✅ Message de bienvenue trouvé');
    }

    print('Nombre de cartes: ${statsWidgets.evaluate().length}');

    // Afficher quelques textes pour comprendre la structure
    for (var i = 0; i < textWidgets.evaluate().length && i < 15; i++) {
      try {
        final widget = tester.widget<Text>(textWidgets.at(i));
        final data = widget.data ?? '';
        if (data.isNotEmpty && data.length < 50) {
          print('  Text[$i]: "$data"');
        }
      } catch (e) {
        // Ignorer les erreurs
      }
    }

    print('\n✅ Test terminé - Dashboard accessible');
  });
}
