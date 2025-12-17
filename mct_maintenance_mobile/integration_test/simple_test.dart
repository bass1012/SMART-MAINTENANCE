import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'Test simple - Démarrage app',
    ($) async {
      // Démarrer l'application
      app.main();
      await $.pumpAndSettle();

      // Vérifier qu'un widget Text existe
      expect(find.byType(MaterialApp), findsOneWidget);

      print('✅ Test démarrage réussi');
    },
  );

  patrolTest(
    'Test Connexion Client',
    ($) async {
      // Démarrer l'application
      app.main();
      await $.pumpAndSettle();

      // Vérifier les champs de connexion
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      final loginButton = find.byKey(const Key('loginButton'));

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      print('✅ Test connexion réussi');
    },
  );
}
