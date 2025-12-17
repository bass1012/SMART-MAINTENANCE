import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug: Login and print dashboard widgets',
      (WidgetTester tester) async {
    print('🚀 Starting app');
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    print('🔐 Logging in');
    await tester.enterText(
        find.byKey(const Key('emailField')), 'grace.zoko@gmail.com');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(const Key('passwordField')), 'test123');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('loginButton')), warnIfMissed: false);
    print('Waiting for dashboard...');
    await tester.pumpAndSettle(const Duration(seconds: 10));

    print('✅ Dashboard loaded, analyzing widgets...');

    // Print all Text widgets on screen
    final allText = find.byType(Text);
    print('\n📝 Found ${allText.evaluate().length} Text widgets:');

    for (final element in allText.evaluate()) {
      final widget = element.widget as Text;
      final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      if (text.isNotEmpty) {
        print('  - "$text"');
      }
    }

    // Print all Card widgets
    final allCards = find.byType(Card);
    print('\n📦 Found ${allCards.evaluate().length} Card widgets');

    // Print all GridView widgets
    final allGrids = find.byType(GridView);
    print('\n📊 Found ${allGrids.evaluate().length} GridView widgets');

    // Try to find "Intervention" with different approaches
    print('\n🔍 Searching for "Interventions":');
    print('  - Exact match: ${find.text('Interventions').evaluate().length}');
    print(
        '  - Contains "Intervent": ${find.textContaining('Intervent').evaluate().length}');
    print(
        '  - Contains "intervention" (lowercase): ${find.textContaining('intervention').evaluate().length}');

    // Print all Icon widgets
    final allIcons = find.byType(Icon);
    print('\n🎨 Found ${allIcons.evaluate().length} Icon widgets');

    // Try to find Cards with "Interventions" text
    print('\n🔍 Looking for Card ancestors of text');
    final interventionsText =
        find.textContaining('Intervention', findRichText: true);
    if (interventionsText.evaluate().isNotEmpty) {
      print(
          '  - Found text containing "Intervention": ${interventionsText.evaluate().length}');
      final firstText = interventionsText.first;

      // Try to find parent Card
      final ancestor =
          find.ancestor(of: firstText, matching: find.byType(InkWell));
      print('  - Found InkWell ancestor: ${ancestor.evaluate().length}');
    }

    print('\n✅ Debug complete - check output above');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
