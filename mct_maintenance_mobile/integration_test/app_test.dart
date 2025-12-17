import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mct_maintenance_mobile/main.dart' as app;
import 'package:patrol/patrol.dart';

/// Configuration Patrol pour les tests E2E
///
/// Ce fichier configure l'environnement de test avec Patrol.
/// Patrol permet de tester l'application comme un vrai utilisateur,
/// y compris les permissions natives et interactions système.
void main() {
  patrolTest(
    '🔐 Test 1: Connexion Client - Flux Complet',
    ($) async {
      // Démarrer l'application
      app.main();
      await $.pumpAndSettle();

      // Vérifier que nous sommes sur l'écran de connexion
      expect($(#emailField).visible, true);
      expect($(#passwordField).visible, true);
      expect($(#loginButton).visible, true);

      // Remplir le formulaire de connexion
      await $(#emailField).enterText('client@test.com');
      await $(#passwordField).enterText('password123');

      // Cliquer sur le bouton de connexion
      await $(#loginButton).tap();

      // Attendre la navigation vers le dashboard
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier que nous sommes connectés (dashboard visible)
      expect($(#customerDashboard).visible, true);

      print('✅ Test connexion client réussi');
    },
  );

  patrolTest(
    '🔧 Test 2: Création Intervention - Flux Complet',
    ($) async {
      // Démarrer et se connecter
      app.main();
      await $.pumpAndSettle();

      // Connexion
      await $(#emailField).enterText('client@test.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Aller à l'écran des interventions
      await $(#interventionsTab).tap();
      await $.pumpAndSettle();

      // Cliquer sur le bouton "Nouvelle Intervention"
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      // Remplir le formulaire
      await $(#interventionTitleField).enterText('Panne climatisation');
      await $(#interventionDescriptionField).enterText(
        'La climatisation ne fonctionne plus depuis ce matin. Besoin d\'une intervention urgente.',
      );

      // Sélectionner le type
      await $(#interventionTypeDropdown).tap();
      await $.pumpAndSettle();
      await $(#typeRepair).tap(); // Sélectionner "Réparation"
      await $.pumpAndSettle();

      // Sélectionner la priorité
      await $(#priorityDropdown).tap();
      await $.pumpAndSettle();
      await $(#priorityHigh).tap(); // Sélectionner "Haute"
      await $.pumpAndSettle();

      // Note: Pour les permissions natives (localisation, photos),
      // Patrol peut les gérer automatiquement

      // Soumettre le formulaire
      await $(#submitInterventionButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier le SnackBar de succès
      expect($('Intervention créée avec succès'), findsOneWidget);

      // Vérifier que nous sommes revenus à la liste
      expect($(#interventionsList).visible, true);

      // Vérifier que la nouvelle intervention apparaît dans la liste
      expect($('Panne climatisation'), findsOneWidget);

      print('✅ Test création intervention réussi');
    },
  );

  patrolTest(
    '🛒 Test 3: Achat Boutique - Flux Complet',
    ($) async {
      // Démarrer et se connecter
      app.main();
      await $.pumpAndSettle();

      await $(#emailField).enterText('client@test.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Aller à la boutique
      await $(#shopTab).tap();
      await $.pumpAndSettle();

      // Vérifier que des produits sont affichés
      expect($(#productsList).visible, true);

      // Cliquer sur le premier produit
      await $(#product0).tap();
      await $.pumpAndSettle();

      // Ajouter au panier
      await $(#addToCartButton).tap();
      await $.pumpAndSettle();

      // Vérifier le SnackBar de confirmation
      expect($('Produit ajouté au panier'), findsOneWidget);

      // Aller au panier
      await $(#cartIcon).tap();
      await $.pumpAndSettle();

      // Vérifier que le produit est dans le panier
      expect($(#cartItemsList).visible, true);

      // Modifier la quantité à 2
      await $(#quantityIncrement0).tap();
      await $.pumpAndSettle();

      // Procéder au paiement
      await $(#checkoutButton).tap();
      await $.pumpAndSettle();

      // Remplir l'adresse de livraison
      await $(#shippingAddressField).enterText('123 Avenue Test, Dakar');

      // Sélectionner le mode de paiement
      await $(#paymentMethodDropdown).tap();
      await $.pumpAndSettle();
      await $(#paymentWave).tap(); // Sélectionner "Wave"
      await $.pumpAndSettle();

      // Confirmer la commande
      await $(#confirmOrderButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier le succès
      expect($('Commande confirmée'), findsOneWidget);

      // Vérifier que nous sommes dans l'historique des commandes
      expect($(#ordersList).visible, true);

      print('✅ Test achat boutique réussi');
    },
  );

  patrolTest(
    '👨‍🔧 Test 4: Workflow Technicien - Accepter et Traiter Intervention',
    ($) async {
      // Démarrer l'application
      app.main();
      await $.pumpAndSettle();

      // Connexion en tant que technicien
      await $(#emailField).enterText('technicien@test.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier dashboard technicien
      expect($(#technicianDashboard).visible, true);

      // Voir les interventions assignées
      await $(#interventionsTab).tap();
      await $.pumpAndSettle();

      // Cliquer sur la première intervention
      await $(#intervention0).tap();
      await $.pumpAndSettle();

      // Accepter l'intervention
      await $(#acceptInterventionButton).tap();
      await $.pumpAndSettle();

      // Marquer "En route"
      await $(#enRouteButton).tap();
      await $.pumpAndSettle();

      // Vérifier changement de statut
      expect($('En route'), findsOneWidget);

      // Marquer "Arrivé sur site"
      await $(#arrivedButton).tap();
      await $.pumpAndSettle();

      // Démarrer l'intervention
      await $(#startInterventionButton).tap();
      await $.pumpAndSettle();

      // Terminer l'intervention
      await $(#completeInterventionButton).tap();
      await $.pumpAndSettle();

      // Créer le rapport
      expect($(#reportForm).visible, true);

      await $(#reportDescriptionField).enterText(
        'Intervention réalisée avec succès. Problème résolu.',
      );

      // Soumettre le rapport
      await $(#submitReportButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier le succès
      expect($('Rapport soumis avec succès'), findsOneWidget);

      print('✅ Test workflow technicien réussi');
    },
  );

  patrolTest(
    '📱 Test 5: Permissions Natives - Localisation et Photos',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Connexion
      await $(#emailField).enterText('client@test.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Nouvelle intervention
      await $(#interventionsTab).tap();
      await $.pumpAndSettle();
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      // Tester la permission de localisation
      await $(#getCurrentLocationButton).tap();

      // Patrol gère automatiquement la popup de permission
      await $.native.grantPermissionWhenInUse();

      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Vérifier que le champ adresse est visible
      expect($(#addressField).visible, true);

      // Tester l'ajout de photo
      await $(#addPhotoButton).tap();
      await $.pumpAndSettle();

      // Sélectionner "Caméra"
      await $(#cameraOption).tap();

      // Patrol gère automatiquement la permission caméra
      await $.native.grantPermissionOnlyThisTime();

      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      print('✅ Test permissions natives réussi');
    },
  );

  patrolTest(
    '🔔 Test 6: Notifications Push',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Connexion
      await $(#emailField).enterText('client@test.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Accorder permission notifications
      await $.native.grantPermissionWhenInUse();

      // Créer une intervention qui déclenchera une notification
      await $(#interventionsTab).tap();
      await $.pumpAndSettle();
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      await $(#interventionTitleField).enterText('Test notification');
      await $(#interventionDescriptionField).enterText('Test');
      await $(#submitInterventionButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Attendre la notification (simulée par le backend)
      await Future.delayed(const Duration(seconds: 3));

      // Vérifier que la notification apparaît dans le centre de notifications
      await $(#notificationsTab).tap();
      await $.pumpAndSettle();

      expect($(#notificationsList).visible, true);
      expect($('Nouvelle intervention'), findsAtLeastNWidgets(1));

      print('✅ Test notifications réussi');
    },
  );
}
