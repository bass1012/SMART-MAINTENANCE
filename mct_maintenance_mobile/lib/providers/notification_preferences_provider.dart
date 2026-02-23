import 'package:flutter/foundation.dart';
import '../models/notification_preference.dart';
import '../services/notification_preferences_service.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  final NotificationPreferencesService _service =
      NotificationPreferencesService();

  NotificationPreference? _preferences;
  bool _isLoading = false;
  String? _error;

  NotificationPreference? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPreferences => _preferences != null;

  /// Charger les préférences
  Future<void> loadPreferences({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await _service.getPreferences(forceRefresh: forceRefresh);
      _preferences = prefs;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur chargement préférences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour les préférences
  Future<bool> updatePreferences(Map<String, dynamic> updates) async {
    try {
      final updated = await _service.updatePreferences(updates);
      if (updated != null) {
        _preferences = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur mise à jour préférences: $e');
      notifyListeners();
      return false;
    }
  }

  /// Activer/Désactiver toutes les notifications email
  Future<bool> toggleEmail(bool enabled) async {
    try {
      final success = await _service.toggleEmail(enabled);
      if (success && _preferences != null) {
        _preferences = _preferences!.copyWith(emailEnabled: enabled);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur toggle email: $e');
      notifyListeners();
      return false;
    }
  }

  /// Activer/Désactiver toutes les notifications push
  Future<bool> togglePush(bool enabled) async {
    try {
      final success = await _service.togglePush(enabled);
      if (success && _preferences != null) {
        _preferences = _preferences!.copyWith(pushEnabled: enabled);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur toggle push: $e');
      notifyListeners();
      return false;
    }
  }

  /// Réinitialiser les préférences
  Future<bool> resetPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final reset = await _service.resetPreferences();
      if (reset != null) {
        _preferences = reset;
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Erreur réinitialisation: $e');
      notifyListeners();
      return false;
    }
  }

  /// Configurer les heures de silence
  Future<bool> setQuietHours({
    required bool enabled,
    String? start,
    String? end,
  }) async {
    try {
      final success = await _service.setQuietHours(
        enabled: enabled,
        start: start,
        end: end,
      );

      if (success && _preferences != null) {
        _preferences = _preferences!.copyWith(
          quietHoursEnabled: enabled,
          quietHoursStart: start,
          quietHoursEnd: end,
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur heures de silence: $e');
      notifyListeners();
      return false;
    }
  }

  /// Vider le cache
  void clearCache() {
    _service.clearCache();
    _preferences = null;
    _error = null;
    notifyListeners();
  }

  /// Vérifier si un type de notification est activé
  bool isNotificationEnabled(String type, {bool isEmail = true}) {
    if (_preferences == null) return true;

    // Vérifier d'abord si le canal global est activé
    if (isEmail && !_preferences!.emailEnabled) return false;
    if (!isEmail && !_preferences!.pushEnabled) return false;

    // Vérifier la préférence spécifique
    switch (type) {
      // Interventions
      case 'intervention_request':
        return isEmail
            ? _preferences!.interventionRequestEmail
            : _preferences!.interventionRequestPush;
      case 'intervention_assigned':
        return isEmail
            ? _preferences!.interventionAssignedEmail
            : _preferences!.interventionAssignedPush;
      case 'intervention_completed':
        return isEmail
            ? _preferences!.interventionCompletedEmail
            : _preferences!.interventionCompletedPush;

      // Commandes
      case 'order_created':
        return isEmail
            ? _preferences!.orderCreatedEmail
            : _preferences!.orderCreatedPush;
      case 'order_status_update':
        return isEmail
            ? _preferences!.orderStatusUpdateEmail
            : _preferences!.orderStatusUpdatePush;

      // Devis
      case 'quote_created':
        return isEmail
            ? _preferences!.quoteCreatedEmail
            : _preferences!.quoteCreatedPush;
      case 'quote_updated':
        return isEmail
            ? _preferences!.quoteUpdatedEmail
            : _preferences!.quoteUpdatedPush;

      // Réclamations
      case 'complaint_created':
        return isEmail
            ? _preferences!.complaintCreatedEmail
            : _preferences!.complaintCreatedPush;
      case 'complaint_responded':
        return isEmail
            ? _preferences!.complaintResponseEmail
            : _preferences!.complaintResponsePush;

      // Contrats
      case 'contract_expiring':
        return isEmail
            ? _preferences!.contractExpiringEmail
            : _preferences!.contractExpiringPush;

      // Marketing
      case 'promotion':
        return isEmail
            ? _preferences!.promotionEmail
            : _preferences!.promotionPush;
      case 'maintenance_tip':
        return isEmail
            ? _preferences!.maintenanceTipEmail
            : _preferences!.maintenanceTipPush;

      default:
        return true;
    }
  }
}
