import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/app.dart';
import 'services/fcm_service.dart';
import 'services/connectivity_service.dart';
import 'services/deep_link_service.dart';
import 'services/location_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intercepter les erreurs de rendu UI
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('❌ Flutter UI Error: ${details.exceptionAsString()}');
    }
  };

  // Intercepter les erreurs asynchrones hors boucle UI
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('❌ Unhandled Async Error: $error\n$stack');
    }
    return true; // Empêcher le crash brutal de l'application
  };

  // Initialiser le service de Deep Link pour FineoPay
  DeepLinkService().initialize();

  // Initialiser le service de suivi GPS en arrière-plan
  LocationTrackingService().initializeService();

  if (kDebugMode) debugPrint('🚀 DÉMARRAGE APP');

  // Initialiser Firebase avec gestion d'erreur
  try {
    // Vérifier si Firebase n'est pas déjà initialisé
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) debugPrint('✅ Firebase initialisé');
    } else {
      if (kDebugMode) debugPrint('ℹ️  Firebase déjà initialisé');
    }

    // Configurer le handler pour les notifications en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) debugPrint('✅ Handler background configuré');
  } on FirebaseException catch (e) {
    // Ignorer silencieusement l'erreur duplicate-app
    if (e.code == 'duplicate-app') {
      if (kDebugMode) debugPrint('ℹ️  Firebase déjà initialisé (duplicate-app)');
    } else {
      if (kDebugMode) debugPrint('❌ ERREUR Firebase: $e');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('❌ ERREUR Firebase: $e');
    // Continuer même si Firebase échoue
  }

  // Initialiser le service de connectivité pour le mode offline
  if (kDebugMode) debugPrint('📡 Initialisation du service de connectivité...');
  final connectivityService = ConnectivityService();
  connectivityService.initialize();
  if (kDebugMode) debugPrint('✅ Service de connectivité initialisé');

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

  if (kDebugMode) debugPrint('✅ LANCEMENT APP');

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

  // Gestion des erreurs non capturées de la couche Flutter UI
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('🚨 FATAL FLUTTER ERROR: ${details.exceptionAsString()}');
  };

  // Gestion des erreurs asynchrones non capturées
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🚨 UNHANDLED DART ASYNC ERROR: $error\n$stack');
    return true;
  };

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
