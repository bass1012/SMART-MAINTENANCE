import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Configuration des environnements
enum Environment { development, staging, production }

// Configuration des lieux (Bureau / Maison)
enum Location { office, home }

// 🔧 CONFIGURATION RAPIDE - Changez cette ligne selon votre lieu
const Location currentLocation =
    Location.office; // Changez en Location.office au bureau

// Configuration par défaut (développement)
const Environment env = Environment.development;

/// Configuration de l'application
class AppConfig {
  // Configuration des IPs selon le lieu
  static const Map<Location, String> _locationIPs = {
    Location.office: '192.168.1.139', // IP du bureau
    Location.home: '192.168.1.6', // IP de la maison
  };

  // Configuration des environnements
  // IMPORTANT: Remplacez xxx par l'adresse IP de votre machine à la maison
  // Pour trouver votre IP:
  // - Mac: System Preferences > Network ou commande `ifconfig | grep "inet "`
  // - Windows: cmd > ipconfig
  // - Linux: ifconfig ou ip addr
  static Map<Environment, String> get _baseUrls => {
        Environment.development: 'http://${_locationIPs[currentLocation]}:3000',
        Environment.staging: 'https://staging.votreserveur.com',
        Environment.production: 'https://api.votreserveur.com',
      };

  // URL spécifique pour Android (l'émulateur Android utilise 10.0.2.2 pour accéder à localhost de la machine hôte)
  static const Map<Environment, String> _androidBaseUrls = {
    Environment.development:
        'http://10.0.2.2:3000', // Pour émulateur Android uniquement
    Environment.staging: 'https://staging.votreserveur.com',
    Environment.production: 'https://api.votreserveur.com',
  };

  // Configuration des chemins d'API
  static const Map<String, String> _apiEndpoints = {
    'auth': '/api/auth',
    'login': '/api/auth/login',
    'register': '/api/auth/register',
    'profile': '/api/auth/profile',
  };

  // Obtenir l'URL de base en fonction de l'environnement et de la plateforme
  static String get baseUrl {
    // Sur Android, utiliser 10.0.2.2 au lieu de localhost
    if (!kIsWeb && Platform.isAndroid) {
      return _androidBaseUrls[env] ??
          _androidBaseUrls[Environment.development]!;
    }
    return _baseUrls[env] ?? _baseUrls[Environment.development]!;
  }

  // Obtenir l'URL complète d'un endpoint
  static String getApiUrl(String endpoint) {
    final path = _apiEndpoints[endpoint] ?? '';
    return '$baseUrl$path';
  }

  // URL complètes des endpoints principaux
  static String get loginUrl => getApiUrl('login');
  static String get registerUrl => getApiUrl('register');
  static String get profileUrl => '$baseUrl${_apiEndpoints['profile']}';
}

/// Configuration des requêtes API
class ApiConfig {
  // Timeout des requêtes
  static const Duration timeout = Duration(seconds: 15);

  // Activer/désactiver les logs en mode debug
  static const bool debugLogs = true;

  // Configuration des en-têtes par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };

  // Configuration CORS pour le développement
  static const Map<String, String> corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
  };
}

/// Clés API et autres secrets
class AppSecrets {
  // Ces valeurs devraient être stockées de manière sécurisée en production
  // Par exemple, en utilisant flutter_dotenv ou un service de gestion des secrets
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');

  // Autres configurations spécifiques à l'application
  static const String appName = 'MCT Maintenance';
  static const String appVersion = '1.0.0';
}

// Raccourcis pour la rétrocompatibilité
String get apiBaseUrl => AppConfig.baseUrl;
Map<String, String> get corsHeaders => Map.from(ApiConfig.corsHeaders);
