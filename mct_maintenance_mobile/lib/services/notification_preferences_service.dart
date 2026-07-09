import 'package:flutter/foundation.dart';
import 'package:mct_maintenance_mobile/features/common/domain/repositories/notification_repository.dart';
import 'package:mct_maintenance_mobile/features/common/data/repositories/notification_repository_impl.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/models/notification_preference.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();

  factory NotificationPreferencesService() => _instance;

  NotificationPreferencesService._internal();

  // Cache local des préférences
  NotificationPreference? _cachedPreferences;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  late final NotificationRepository _notificationRepository;

  void init(NotificationRepository repository) {
    _notificationRepository = repository;
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
        if (kDebugMode) debugPrint('✅ Préférences notifications (cache)');
        return _cachedPreferences;
      }

      final data = await _notificationRepository.getPreferences();
      if (data['success'] == true && data['data'] != null) {
        final prefs = NotificationPreference.fromJson(data['data']);

        // Mettre à jour le cache
        _cachedPreferences = prefs;
        _lastFetch = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Préférences récupérées: ${prefs.toJson()}');
        }
        return prefs;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération des préférences');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur récupération préférences: $e');
      // Retourner le cache même périmé en cas d'erreur
      if (_cachedPreferences != null) {
        return _cachedPreferences;
      }
      rethrow;
    }
  }

  /// Mettre à jour les préférences
  Future<NotificationPreference?> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await _notificationRepository.updatePreferences(updates);
      if (data['success'] == true && data['data'] != null) {
        final prefs = NotificationPreference.fromJson(data['data']);

        // Mettre à jour le cache
        _cachedPreferences = prefs;
        _lastFetch = DateTime.now();

        if (kDebugMode) debugPrint('✅ Préférences mises à jour');
        return prefs;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur mise à jour préférences: $e');
      rethrow;
    }
  }

  /// Activer/Désactiver toutes les notifications email
  Future<bool> toggleEmail(bool enabled) async {
    try {
      final success = await _notificationRepository.toggleEmail(enabled);
      if (success) {
        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            emailEnabled: enabled,
          );
        }
        if (kDebugMode) {
          debugPrint('✅ Email ${enabled ? "activé" : "désactivé"}');
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur toggle email: $e');
      return false;
    }
  }

  /// Activer/Désactiver toutes les notifications push
  Future<bool> togglePush(bool enabled) async {
    try {
      final success = await _notificationRepository.togglePush(enabled);
      if (success) {
        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            pushEnabled: enabled,
          );
        }
        if (kDebugMode) {
          debugPrint('✅ Push ${enabled ? "activé" : "désactivé"}');
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur toggle push: $e');
      return false;
    }
  }

  /// Réinitialiser aux valeurs par défaut
  Future<NotificationPreference?> resetPreferences() async {
    try {
      final data = await _notificationRepository.resetPreferences();
      if (data['success'] == true && data['data'] != null) {
        final prefs = NotificationPreference.fromJson(data['data']);

        // Mettre à jour le cache
        _cachedPreferences = prefs;
        _lastFetch = DateTime.now();

        if (kDebugMode) debugPrint('✅ Préférences réinitialisées');
        return prefs;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur réinitialisation: $e');
      rethrow;
    }
  }

  /// Configurer les heures de silence
  Future<bool> setQuietHours({
    required bool enabled,
    String? start,
    String? end,
  }) async {
    try {
      final body = {
        'enabled': enabled,
        if (start != null) 'start': start,
        if (end != null) 'end': end,
      };

      final success = await _notificationRepository.setQuietHours(body);

      if (success) {
        // Mettre à jour le cache localement
        if (_cachedPreferences != null) {
          _cachedPreferences = _cachedPreferences!.copyWith(
            quietHoursEnabled: enabled,
            quietHoursStart: start,
            quietHoursEnd: end,
          );
        }
        if (kDebugMode) debugPrint('✅ Heures de silence configurées');
      }
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur heures de silence: $e');
      return false;
    }
  }

  /// Vider le cache local
  void clearCache() {
    _cachedPreferences = null;
    _lastFetch = null;
    if (kDebugMode) debugPrint('🗑️ Cache préférences vidé');
  }
}
