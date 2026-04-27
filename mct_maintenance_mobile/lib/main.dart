import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/app.dart';
import 'services/fcm_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 DÉMARRAGE APP');

  // Initialiser Firebase avec gestion d'erreur
  try {
    // Vérifier si Firebase n'est pas déjà initialisé
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialisé');
    } else {
      print('ℹ️  Firebase déjà initialisé');
    }

    // Configurer le handler pour les notifications en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Handler background configuré');
  } on FirebaseException catch (e) {
    // Ignorer silencieusement l'erreur duplicate-app
    if (e.code == 'duplicate-app') {
      print('ℹ️  Firebase déjà initialisé (duplicate-app)');
    } else {
      print('❌ ERREUR Firebase: $e');
    }
  } catch (e) {
    print('❌ ERREUR Firebase: $e');
    // Continuer même si Firebase échoue
  }

  // Initialiser le service de connectivité pour le mode offline
  print('📡 Initialisation du service de connectivité...');
  final connectivityService = ConnectivityService();
  connectivityService.initialize();
  print('✅ Service de connectivité initialisé');

  // Configuration du mode paysage désactivé
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration du statut bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialisation et configuration de l'application
  _setupApp();

  print('✅ LANCEMENT APP');

  // Démarrer l'application
  runApp(const App());
}

void _setupApp() {
  // Configuration du statut bar en clair
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Gestion des erreurs non capturées
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Vous pouvez ajouter ici un envoi d'erreur à un service de suivi comme Sentry
  };

  // Gestion des erreurs asynchrones non capturées
  if (kReleaseMode) {
    ErrorWidget.builder =
        (_) => const Center(child: Text("Une erreur s'est produite"));
  } else {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return ErrorWidget(errorDetails.exception);
    };
  }
}

// Classe pour gérer les erreurs de l'application
class AppErrorHandler {
  static void handleError(FlutterErrorDetails details) {
    // Implémentez la gestion des erreurs ici
    debugPrint('Erreur non gérée: ${details.exception}');
  }
}
