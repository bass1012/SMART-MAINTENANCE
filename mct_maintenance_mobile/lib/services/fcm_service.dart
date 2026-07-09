import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/features/common/domain/repositories/notification_repository.dart';
import 'package:mct_maintenance_mobile/features/common/data/repositories/notification_repository_impl.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';

/// Service de gestion des notifications Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final BaseApiService _fcmApiService = BaseApiService();
  late final NotificationRepository _notificationRepository =
      NotificationRepositoryImpl(_fcmApiService);
  String? _fcmToken;
  bool _initialized = false;
  int? _currentUserId;

  // Stream pour notifier quand une notification est cliquée
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream des clics sur notification (pour navigation immédiate)
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  /// Initialiser FCM
  Future<void> initialize() async {
    if (kDebugMode) debugPrint('🔔 [FCM] Début initialisation...');

    if (_initialized) {
      if (kDebugMode) debugPrint('🔔 [FCM] Déjà initialisé, skip');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🚀 [FCM] Étape 1: Demande de permission...');

      // Demander la permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode)
        debugPrint(
            '📋 [FCM] Statut permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode)
          debugPrint('✅ [FCM] Permission de notification accordée');
      } else {
        print(
            '⚠️  [FCM] Permission de notification refusée: ${settings.authorizationStatus}');
        return;
      }

      // Initialiser les notifications locales
      if (kDebugMode)
        debugPrint('🔔 [FCM] Étape 2: Initialisation notifications locales...');
      await _initializeLocalNotifications();
      if (kDebugMode) debugPrint('✅ [FCM] Notifications locales OK');

      // Forcer la régénération du token FCM (important après changement de projet Firebase)
      if (kDebugMode)
        debugPrint(
            '🔔 [FCM] Étape 3: Suppression ancien token et régénération...');
      try {
        await _firebaseMessaging.deleteToken();
        if (kDebugMode) debugPrint('🗑️ [FCM] Ancien token supprimé');
      } catch (e) {
        if (kDebugMode)
          debugPrint('⚠️  [FCM] Erreur suppression token (ignorée): $e');
      }

      // Obtenir le nouveau token FCM
      if (kDebugMode)
        debugPrint('🔔 [FCM] Étape 4: Obtention du nouveau token FCM...');
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        if (kDebugMode)
          debugPrint(
              '📱 [FCM] Token obtenu: ${_fcmToken!.substring(0, 20)}...');

        // Envoyer le token au backend
        if (kDebugMode)
          debugPrint('📤 [FCM] Étape 5: Envoi token au backend...');
        await _sendTokenToBackend(_fcmToken!);
        if (kDebugMode)
          debugPrint('✅ [FCM] Token envoyé au backend avec succès');
      } else {
        if (kDebugMode)
          debugPrint('⚠️  [FCM] Impossible d\'obtenir le token FCM');
      }

      // Écouter les rafraîchissements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode)
          debugPrint('🔄 Nouveau FCM Token: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // Gérer les notifications en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Gérer les notifications quand l'app est en background mais ouverte
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Vérifier si l'app a été ouverte depuis une notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      if (kDebugMode)
        debugPrint('🎉 [FCM] Initialisation terminée avec succès');
    } catch (e, stackTrace) {
      if (kDebugMode)
        debugPrint('❌ [FCM] ERREUR lors de l\'initialisation: $e');
      if (kDebugMode) debugPrint('📍 [FCM] Stack trace: $stackTrace');
      // Ne pas marquer comme initialized en cas d'erreur
    }
  }

  /// Initialiser les notifications locales (pour foreground)
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le clic sur la notification locale
        if (response.payload != null) {
          _handleLocalNotificationTap(response.payload!);
        }
      },
    );

    if (kDebugMode)
      debugPrint('✅ Notifications locales initialisées (Android + iOS)');
  }

  /// Envoyer le token FCM au backend
  /// Retourne true si l'envoi a réussi
  Future<bool> _sendTokenToBackend(String token) async {
    try {
      if (kDebugMode)
        debugPrint('📤 [FCM->Backend] Appel API updateFcmToken...');
      if (kDebugMode)
        debugPrint('📱 [FCM->Backend] Token: ${token.substring(0, 30)}...');

      final success = await _notificationRepository.updateFcmToken(token);

      if (success) {
        print(
            '✅ [FCM->Backend] Token FCM enregistré avec succès dans le backend');
      } else {
        if (kDebugMode)
          debugPrint(
              '❌ [FCM->Backend] Échec de l\'enregistrement du token FCM');
      }
      return success;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('❌ [FCM->Backend] Erreur envoi token: $e');
      if (kDebugMode) debugPrint('📍 [FCM->Backend] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Propager le token auth à ce service puis re-envoyer le token FCM au backend
  Future<void> setAuthToken(String? token) async {
    _fcmApiService.setToken(token);
    if (token != null && _fcmToken != null) {
      // Token auth disponible + token FCM connu → envoyer au backend
      await _sendTokenToBackend(_fcmToken!);
    }
  }

  /// Mettre à jour l'ID de l'utilisateur courant (appelé après login/logout)
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }

  /// Vérifier si une notification est destinée à l'utilisateur courant
  /// Retourne true si la notification est valide (doit être affichée)
  bool _isNotificationForCurrentUser(Map<String, dynamic> data) {
    final String? targetUserId = data['target_user_id'];

    // Si pas de target_user_id (anciennes notifs), on accepte
    if (targetUserId == null || targetUserId.isEmpty) return true;

    // Si on ne connaît pas l'utilisateur courant, on accepte
    if (_currentUserId == null) return true;

    final bool isForMe = targetUserId == _currentUserId.toString();
    if (!isForMe) {
      print(
          '⚠️ [FCM] Notification ignorée: destinée à user $targetUserId, utilisateur courant: $_currentUserId');
    }
    return isForMe;
  }

  /// Gérer les notifications quand l'app est au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) debugPrint('🔔 Notification reçue (foreground)');
    if (kDebugMode) debugPrint('   Titre: ${message.notification?.title}');
    if (kDebugMode) debugPrint('   Message: ${message.notification?.body}');
    if (kDebugMode) debugPrint('   Data: ${message.data}');

    // Vérifier que la notification est destinée à l'utilisateur courant
    if (!_isNotificationForCurrentUser(message.data)) return;

    // Afficher une notification locale pour les types importants
    final String? type = message.data['type'];
    final List<String> importantTypes = [
      'technician_assigned',
      'technician_on_the_way',
      'technician_arrived',
      'intervention_status',
      'intervention_assigned',
      'intervention_completed',
      'intervention_cancelled',
      'quote_created',
      'quote_received',
      'quote_sent',
      'quote_accepted',
      'quote_rejected',
      'quote_execution_confirmed', // Exécution confirmée par le client
      'order_status',
      'complaint_response',
      'maintenance_reminder',
      'contract_created', // Contrat de maintenance créé
      'contract_expiring', // Contrat bientôt expiré
      'contract_renewal_request', // Demande de renouvellement
      'payment_confirmed',
      'payment_success',
      'payment_failed',
      'payment_refunded',
      'payment_pending',
      'diagnostic_payment_confirmed', // Paiement diagnostic confirmé
      'diagnostic_payment_failed', // Échec paiement diagnostic
      'report_submitted', // Rapport d'intervention soumis
      'report_confirmation_required', // Demande de confirmation par le client
      'intervention_confirmed', // Client a confirmé l'intervention
      'intervention_rejected', // Client a contesté l'intervention
      'intervention_dispute', // Litige intervention (pour admins)
      'general', // Notifications broadcast
      'announcement', // Annonces
      'alert', // Alertes
      'promotion', // Promotions
    ];

    if (type != null && importantTypes.contains(type)) {
      print(
          '📢 Type important ($type), affichage notification locale en foreground');
      await _showLocalNotification(message);
    } else {
      print(
          '✓ App en foreground, notification stockée (pas d\'affichage local pour type: $type)');
    }
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Personnaliser le son et l'icône selon le type de notification
    final String? type = message.data['type'];
    final bool isChatNotification = type == 'chat';
    final bool isMaintenanceOfferNotification =
        type == 'maintenance_offer_created' ||
            type == 'maintenance_offer_activated';

    // Déterminer le canal approprié
    String channelId = 'default_channel';
    String channelName = 'Notifications';
    String channelDescription = 'Notifications MCT Maintenance';

    if (isChatNotification) {
      channelId = 'chat_channel';
      channelName = 'Messages';
      channelDescription = 'Messages du support MCT Maintenance';
    } else if (isMaintenanceOfferNotification) {
      channelId = 'offers_channel';
      channelName = 'Offres d\'entretien';
      channelDescription = 'Nouvelles offres et promotions MCT Maintenance';
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0a543d), // Vert MCT
      // Son spécifique pour les messages de chat
      sound: isChatNotification
          ? RawResourceAndroidNotificationSound('chat_notification')
          : null,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'MCT Maintenance',
      body: message.notification?.body ?? 'Nouvelle notification',
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Gérer le clic sur une notification FCM
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) debugPrint('👆 Notification cliquée (FCM)');
    if (kDebugMode) debugPrint('   Data: ${message.data}');

    // Vérifier que la notification est destinée à l'utilisateur courant
    if (!_isNotificationForCurrentUser(message.data)) return;

    // Convertir les données en Map<String, dynamic>
    final Map<String, dynamic> notificationData =
        Map<String, dynamic>.from(message.data);

    // Stocker les données de la notification pour la navigation
    _pendingNotificationData = notificationData;

    // Émettre l'événement sur le stream pour navigation immédiate
    _notificationTapController.add(notificationData);
    if (kDebugMode) debugPrint('📢 Événement de clic émis sur le stream');

    // Gérer les notifications de chat
    final String? type = message.data['type'];

    if (type == 'chat') {
      if (kDebugMode)
        debugPrint('   → Type: Chat - Navigation vers la page de chat');
      _lastChatNotification = notificationData;
    } else if (type == 'maintenance_offer_created' ||
        type == 'maintenance_offer_activated') {
      if (kDebugMode)
        debugPrint(
            '   → Type: Offre d\'entretien - Navigation vers les offres');
      _lastOfferNotification = notificationData;
    }

    final String? actionUrl = message.data['actionUrl'];
    if (actionUrl != null) {
      if (kDebugMode)
        debugPrint('   → Navigation vers: $actionUrl (type: $type)');
    }
  }

  Map<String, dynamic>? _lastChatNotification;
  Map<String, dynamic>? _lastOfferNotification;
  Map<String, dynamic>? _pendingNotificationData;

  /// Obtenir et effacer la dernière notification de chat
  Map<String, dynamic>? getAndClearLastChatNotification() {
    final notification = _lastChatNotification;
    _lastChatNotification = null;
    return notification;
  }

  /// Obtenir et effacer la dernière notification d'offre
  Map<String, dynamic>? getAndClearLastOfferNotification() {
    final notification = _lastOfferNotification;
    _lastOfferNotification = null;
    return notification;
  }

  /// Obtenir et effacer les données de notification en attente
  Map<String, dynamic>? getAndClearPendingNotification() {
    final notification = _pendingNotificationData;
    _pendingNotificationData = null;
    return notification;
  }

  /// Gérer le clic sur une notification locale
  void _handleLocalNotificationTap(String payload) {
    if (kDebugMode) debugPrint('👆 Notification locale cliquée');
    if (kDebugMode) debugPrint('   Payload: $payload');

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? notificationType = data['type'];

      // Stocker pour la navigation
      _pendingNotificationData = data;

      // Émettre l'événement sur le stream pour navigation immédiate
      _notificationTapController.add(data);
      if (kDebugMode)
        debugPrint('📢 Événement de clic local émis sur le stream');

      if (notificationType == 'chat') {
        if (kDebugMode)
          debugPrint('   → Type: Chat - Navigation vers la page de chat');
        _lastChatNotification = data;
      } else if (notificationType == 'maintenance_offer_created' ||
          notificationType == 'maintenance_offer_activated') {
        if (kDebugMode)
          debugPrint(
              '   → Type: Offre d\'entretien - Navigation vers les offres');
        _lastOfferNotification = data;
      }

      final String? actionUrl = data['actionUrl'];
      if (actionUrl != null) {
        if (kDebugMode)
          debugPrint(
              '   → Navigation vers: $actionUrl (type: $notificationType)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur parsing payload: $e');
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Vérifier si FCM est initialisé
  bool get isInitialized => _initialized;

  /// Renvoyer le token FCM au backend (utile après reconnexion)
  /// Rafraîchir et renvoyer le token FCM au backend
  /// Retourne true si le token a été envoyé avec succès
  Future<bool> refreshToken() async {
    try {
      if (kDebugMode) debugPrint('🔄 [FCM] Rafraîchissement du token...');

      // Toujours tenter d'obtenir un nouveau token pour être sûr
      String? token = _fcmToken;

      if (token == null) {
        if (kDebugMode)
          debugPrint(
              '🔔 [FCM] Aucun token en mémoire, tentative d\'obtention...');
        token = await _firebaseMessaging.getToken();
        _fcmToken = token;
      }

      if (token != null) {
        if (kDebugMode)
          debugPrint('📤 [FCM] Envoi du token: ${token.substring(0, 30)}...');
        final success = await _sendTokenToBackend(token);

        if (success) {
          if (kDebugMode)
            debugPrint('✅ [FCM] Token envoyé au backend avec succès');
        } else {
          if (kDebugMode)
            debugPrint('❌ [FCM] Échec de l\'envoi du token au backend');
        }
        return success;
      } else {
        if (kDebugMode)
          debugPrint('⚠️  [FCM] Impossible d\'obtenir le token FCM');
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode)
        debugPrint('❌ [FCM] Erreur lors du rafraîchissement du token: $e');
      if (kDebugMode) debugPrint('📍 [FCM] Stack: $stackTrace');
      return false;
    }
  }

  /// Nettoyer les données FCM lors de la déconnexion
  /// Supprime le token Firebase et efface l'ID utilisateur courant
  Future<void> clearOnLogout() async {
    try {
      // Supprimer le token Firebase pour forcer sa régénération au prochain login
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) debugPrint('🔕 [FCM] Token Firebase supprimé (logout)');
    } catch (e) {
      if (kDebugMode)
        debugPrint('⚠️  [FCM] Erreur suppression token Firebase: $e');
    }
    _fcmToken = null;
    _currentUserId = null;
    _initialized = false; // Forcer la réinitialisation au prochain login
    if (kDebugMode) debugPrint('🔕 [FCM] État FCM réinitialisé (logout)');
  }
}

/// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase seulement si pas encore fait (pour les background isolates)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  if (kDebugMode) debugPrint('🔔 Notification reçue (background)');
  if (kDebugMode) debugPrint('   Titre: ${message.notification?.title}');
  if (kDebugMode) debugPrint('   Message: ${message.notification?.body}');
}
