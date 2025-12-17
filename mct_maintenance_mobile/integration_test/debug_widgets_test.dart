import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug: Afficher tous les widgets du dashboard',
      (WidgetTester tester) async {
    print('🚀 DÉMARRAGE APP');
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    print('🔐 CONNEXION');
    await tester.enterText(
        find.byKey(const Key('emailField')), 'grace.zoko@gmail.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'test123');
    await tester.tap(find.byKey(const Key('loginButton')));

    print('⏳ Attente du dashboard...');
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('\n📊 === ANALYSE DES WIDGETS PRÉSENTS ===\n');

    // Trouver tous les Text widgets
    final textWidgets = find.byType(Text);
    final textCount = textWidgets.evaluate().length;
    print('📝 Nombre de widgets Text trouvés: $textCount');

    for (var i = 0; i < textCount && i < 20; i++) {
      try {
        final widget = tester.widget<Text>(textWidgets.at(i));
        final data = widget.data ?? widget.textSpan?.toPlainText() ?? 'N/A';
        print('  [$i] Text: "$data"');
      } catch (e) {
        print('  [$i] Erreur lecture: $e');
      }
    }

    print('\n🎴 === WIDGETS CARD ===');
    final cards = find.byType(Card);
    print('Nombre de Cards: ${cards.evaluate().length}');

    print('\n🖱️  === WIDGETS INKWELL (cliquables) ===');
    final inkWells = find.byType(InkWell);
    print('Nombre de InkWell: ${inkWells.evaluate().length}');

    print('\n📦 === WIDGETS CONTAINER ===');
    final containers = find.byType(Container);
    print('Nombre de Containers: ${containers.evaluate().length}');

    print('\n🔲 === WIDGETS COLUMN ===');
    final columns = find.byType(Column);
    print('Nombre de Columns: ${columns.evaluate().length}');

    print('\n✅ Test de débogage terminé');
  });
}
