import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Service de gestion des notifications Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiService _apiService = ApiService();
  String? _fcmToken;
  bool _initialized = false;

  /// Initialiser FCM
  Future<void> initialize() async {
    print('🔔 [FCM] Début initialisation...');

    if (_initialized) {
      print('🔔 [FCM] Déjà initialisé, skip');
      return;
    }

    try {
      print('🚀 [FCM] Étape 1: Demande de permission...');

      // Demander la permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📋 [FCM] Statut permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [FCM] Permission de notification accordée');
      } else {
        print(
            '⚠️  [FCM] Permission de notification refusée: ${settings.authorizationStatus}');
        return;
      }

      // Initialiser les notifications locales
      print('🔔 [FCM] Étape 2: Initialisation notifications locales...');
      await _initializeLocalNotifications();
      print('✅ [FCM] Notifications locales OK');

      // Obtenir le token FCM
      print('🔔 [FCM] Étape 3: Obtention du token FCM...');
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 [FCM] Token obtenu: ${_fcmToken!.substring(0, 20)}...');

        // Envoyer le token au backend
        print('📤 [FCM] Étape 4: Envoi token au backend...');
        await _sendTokenToBackend(_fcmToken!);
        print('✅ [FCM] Token envoyé au backend avec succès');
      } else {
        print('⚠️  [FCM] Impossible d\'obtenir le token FCM');
      }

      // Écouter les rafraîchissements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Nouveau FCM Token: ${newToken.substring(0, 20)}...');
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
      print('🎉 [FCM] Initialisation terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ [FCM] ERREUR lors de l\'initialisation: $e');
      print('📍 [FCM] Stack trace: $stackTrace');
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
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le clic sur la notification locale
        if (response.payload != null) {
          _handleLocalNotificationTap(response.payload!);
        }
      },
    );

    print('✅ Notifications locales initialisées (Android + iOS)');
  }

  /// Envoyer le token FCM au backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      print('📤 [FCM->Backend] Appel API updateFcmToken...');
      print('📱 [FCM->Backend] Token: ${token.substring(0, 30)}...');
      await _apiService.updateFcmToken(token);
      print('✅ [FCM->Backend] Token FCM enregistré dans le backend');
    } catch (e, stackTrace) {
      print('❌ [FCM->Backend] Erreur envoi token: $e');
      print('📍 [FCM->Backend] Stack trace: $stackTrace');
    }
  }

  /// Gérer les notifications quand l'app est au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Notification reçue (foreground)');
    print('   Titre: ${message.notification?.title}');
    print('   Message: ${message.notification?.body}');
    print('   Data: ${message.data}');

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
      'payment_confirmed',
      'payment_success',
      'payment_failed',
      'payment_refunded',
      'payment_pending',
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
      message.hashCode,
      message.notification?.title ?? 'MCT Maintenance',
      message.notification?.body ?? 'Nouvelle notification',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Gérer le clic sur une notification FCM
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification cliquée');
    print('   Data: ${message.data}');

    // Stocker les données de la notification pour la navigation
    _pendingNotificationData = message.data;

    // Gérer les notifications de chat
    final String? type = message.data['type'];

    if (type == 'chat') {
      print('   → Type: Chat - Navigation vers la page de chat');
      _lastChatNotification = message.data;
    } else if (type == 'maintenance_offer_created' ||
        type == 'maintenance_offer_activated') {
      print('   → Type: Offre d\'entretien - Navigation vers les offres');
      _lastOfferNotification = message.data;
    }

    final String? actionUrl = message.data['actionUrl'];
    if (actionUrl != null) {
      print('   → Navigation vers: $actionUrl (type: $type)');
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
    print('👆 Notification locale cliquée');
    print('   Payload: $payload');

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? notificationType = data['type'];

      // Stocker pour la navigation
      _pendingNotificationData = data;

      if (notificationType == 'chat') {
        print('   → Type: Chat - Navigation vers la page de chat');
        _lastChatNotification = data;
      } else if (notificationType == 'maintenance_offer_created' ||
          notificationType == 'maintenance_offer_activated') {
        print('   → Type: Offre d\'entretien - Navigation vers les offres');
        _lastOfferNotification = data;
      }

      final String? actionUrl = data['actionUrl'];
      if (actionUrl != null) {
        print('   → Navigation vers: $actionUrl (type: $notificationType)');
      }
    } catch (e) {
      print('❌ Erreur parsing payload: $e');
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Vérifier si FCM est initialisé
  bool get isInitialized => _initialized;

  /// Renvoyer le token FCM au backend (utile après reconnexion)
  Future<void> refreshToken() async {
    try {
      print('🔄 [FCM] Rafraîchissement du token...');

      if (_fcmToken != null) {
        print(
            '📤 [FCM] Renvoi du token existant: ${_fcmToken!.substring(0, 30)}...');
        await _sendTokenToBackend(_fcmToken!);
        print('✅ [FCM] Token renvoyé au backend avec succès');
      } else {
        print('🔔 [FCM] Aucun token, tentative d\'obtention...');
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          print('📱 [FCM] Token obtenu: ${_fcmToken!.substring(0, 30)}...');
          await _sendTokenToBackend(_fcmToken!);
          print('✅ [FCM] Token envoyé au backend avec succès');
        } else {
          print('⚠️  [FCM] Impossible d\'obtenir le token FCM');
        }
      }
    } catch (e) {
      print('❌ [FCM] Erreur lors du rafraîchissement du token: $e');
    }
  }
}

/// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase seulement si pas encore fait (pour les background isolates)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  print('🔔 Notification reçue (background)');
  print('   Titre: ${message.notification?.title}');
  print('   Message: ${message.notification?.body}');
}
