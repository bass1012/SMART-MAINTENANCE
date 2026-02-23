import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preference.dart';
import '../config/environment.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();

  factory NotificationPreferencesService() => _instance;

  NotificationPreferencesService._internal();

  // Cache local des préférences
  NotificationPreference? _cachedPreferences;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  /// Récupérer le token d'authentification
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Headers HTTP avec authentification
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...corsHeaders,
    };
  }

  /// Récupérer les préférences de notifications
  Future<NotificationPreference?> getPreferences({
    bool forceRefresh = false,
  }) async {
    try {
      // Retourner le cache si valide
      if (!forceRefresh &&
          _cachedPreferences != null &&
          _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheDuration) {
        print('✅ Préférences notifications (cache)');
        return _cachedPreferences;
      }

      final headers = await _getHeaders();
      final url = Uri.parse('$apiBaseUrl/api/notification-preferences');

      print('🔄 GET $url');

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final prefs = NotificationPreference.fromJson(data['data']);

          // Mettre à jour le cache
          _cachedPreferences = prefs;
          _lastFetch = DateTime.now();

          print('✅ Préférences récupérées: ${prefs.toJson()}');
          return prefs;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      print('❌ Erreur récupération préférences: $e');
      // Retourner le cache même périmé en cas d'erreur
      if (_cachedPreferences != null) {
        return _cachedPreferences;
      }
      rethrow;
    }
    return null;
  }

  /// Mettre à jour les préférences
  Future<NotificationPreference?> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$apiBaseUrl/api/notification-preferences');

      print('🔄 PUT $url');
      print('📤 Body: $updates');

      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode(updates),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final prefs = NotificationPreference.fromJson(data['data']);

          // Mettre à jour le cache
          _cachedPreferences = prefs;
          _lastFetch = DateTime.now();

          print('✅ Préférences mises à jour');
          return prefs;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      print('❌ Erreur mise à jour préférences: $e');
      rethrow;
    }
    return null;
  }

  /// Activer/Désactiver toutes les notifications email
  Future<bool> toggleEmail(bool enabled) async {
    try {
      final headers = await _getHeaders();
      final url =
          Uri.parse('$apiBaseUrl/api/notification-preferences/toggle-email');

      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode({'enabled': enabled}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            emailEnabled: enabled,
          );
        }

        print('✅ Email ${enabled ? "activé" : "désactivé"}');
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur toggle email: $e');
      return false;
    }
  }

  /// Activer/Désactiver toutes les notifications push
  Future<bool> togglePush(bool enabled) async {
    try {
      final headers = await _getHeaders();
      final url =
          Uri.parse('$apiBaseUrl/api/notification-preferences/toggle-push');

      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode({'enabled': enabled}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            pushEnabled: enabled,
          );
        }

        print('✅ Push ${enabled ? "activé" : "désactivé"}');
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur toggle push: $e');
      return false;
    }
  }

  /// Réinitialiser aux valeurs par défaut
  Future<NotificationPreference?> resetPreferences() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$apiBaseUrl/api/notification-preferences/reset');

      print('🔄 POST $url (reset)');

      final response = await http
          .post(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final prefs = NotificationPreference.fromJson(data['data']);

          // Mettre à jour le cache
          _cachedPreferences = prefs;
          _lastFetch = DateTime.now();

          print('✅ Préférences réinitialisées');
          return prefs;
        }
      }
    } catch (e) {
      print('❌ Erreur réinitialisation: $e');
      rethrow;
    }
    return null;
  }

  /// Configurer les heures de silence
  Future<bool> setQuietHours({
    required bool enabled,
    String? start,
    String? end,
  }) async {
    try {
      final headers = await _getHeaders();
      final url =
          Uri.parse('$apiBaseUrl/api/notification-preferences/quiet-hours');

      final body = {
        'enabled': enabled,
        if (start != null) 'start': start,
        if (end != null) 'end': end,
      };

      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            quietHoursEnabled: enabled,
            quietHoursStart: start,
            quietHoursEnd: end,
          );
        }

        print('✅ Heures de silence configurées');
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur heures de silence: $e');
      return false;
    }
  }

  /// Vider le cache local
  void clearCache() {
    _cachedPreferences = null;
    _lastFetch = null;
    print('🗑️ Cache préférences vidé');
  }
}
