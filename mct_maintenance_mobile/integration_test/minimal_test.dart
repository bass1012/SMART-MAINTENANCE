import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Minimal: App démarre', (WidgetTester tester) async {
    print('🚀 Lancement app...');
    app.main();
    await tester.pump();

    print('⏳ Attente 2 secondes...');
    await tester.pump(const Duration(seconds: 2));

    print('✅ App démarrée avec succès!');

    // Vérifier qu'un widget MaterialApp existe
    expect(find.byType(MaterialApp), findsOneWidget);

    print('✅ Test réussi - Flutter Integration Test fonctionne!');
  });
}
