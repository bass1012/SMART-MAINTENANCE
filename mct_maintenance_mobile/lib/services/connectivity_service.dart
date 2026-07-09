import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Service de détection de connectivité réseau
///
/// Surveille l'état de la connexion (wifi/mobile/aucune) et notifie
/// les changements via un Stream pour permettre la synchronisation
/// automatique au retour du réseau.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream d'état de connexion (true = en ligne, false = hors ligne)
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription? _connectivitySubscription;

  /// Initialiser le service de connectivité
  void initialize() {
    if (_connectivitySubscription != null) return;

    if (kDebugMode) debugPrint('📡 Initialisation ConnectivityService...');

    // Écouter changements de connectivité
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) => _updateConnectionStatus(result),
      onError: (error) {
        if (kDebugMode) debugPrint('❌ Erreur écoute connectivité: $error');
      },
    );

    // Vérifier état initial
    _checkInitialConnection();
  }

  /// Vérifier l'état initial de la connexion
  Future<void> _checkInitialConnection() async {
    try {
      final List<ConnectivityResult> result =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Erreur vérification connectivité initiale: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Mettre à jour l'état de connexion
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Vérifier si au moins une connexion active
    final bool hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    // Si l'état change, notifier
    if (hasConnection != _isConnected) {
      _isConnected = hasConnection;
      _connectionController.add(_isConnected);

      if (kDebugMode) {
        debugPrint(
            '📡 Connectivité changée: ${_isConnected ? "🟢 En ligne" : "🔴 Hors ligne"}');
      }
      _logConnectionType(results);
    }
  }

  /// Logger le type de connexion
  void _logConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      if (kDebugMode) debugPrint('   Type: Aucune connexion');
      return;
    }

    for (var result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          if (kDebugMode) debugPrint('   Type: WiFi');
          break;
        case ConnectivityResult.mobile:
          if (kDebugMode) debugPrint('   Type: Mobile Data');
          break;
        case ConnectivityResult.ethernet:
          if (kDebugMode) debugPrint('   Type: Ethernet');
          break;
        case ConnectivityResult.vpn:
          if (kDebugMode) debugPrint('   Type: VPN');
          break;
        case ConnectivityResult.bluetooth:
          if (kDebugMode) debugPrint('   Type: Bluetooth');
          break;
        case ConnectivityResult.none:
          if (kDebugMode) debugPrint('   Type: Aucune');
          break;
        default:
          if (kDebugMode) debugPrint('   Type: Autre ($result)');
      }
    }
  }

  /// Forcer une vérification manuelle de connectivité
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> result =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur vérification connectivité: $e');
      return false;
    }
  }

  /// Obtenir le type de connexion actuel
  Future<List<ConnectivityResult>> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur récupération type connexion: $e');
      return [ConnectivityResult.none];
    }
  }

  /// Vérifier si connecté via WiFi
  Future<bool> isWiFiConnected() async {
    final results = await getConnectionType();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Vérifier si connecté via données mobiles
  Future<bool> isMobileDataConnected() async {
    final results = await getConnectionType();
    return results.contains(ConnectivityResult.mobile);
  }

  /// Libérer les ressources
  void dispose() {
    if (kDebugMode) debugPrint('📡 Fermeture ConnectivityService');
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}
