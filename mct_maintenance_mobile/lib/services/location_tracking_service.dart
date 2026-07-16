import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingService {
  static const String trackingStatusKey = 'is_tracking_active';

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking_channel', 
      'Suivi de localisation',
      description: 'Ce canal est utilisé pour le suivi GPS en arrière-plan',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking_channel',
        initialNotificationTitle: 'MCT Maintenance',
        initialNotificationContent: 'Suivi de localisation activé',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startTracking() async {
    // Demander les permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final service = FlutterBackgroundService();
    await service.startService();
    
    // Save state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingStatusKey, true);
  }

  Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");

    // Save state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingStatusKey, false);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listener pour les positions
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Mise à jour tous les 100 mètres
  );

  StreamSubscription<Position>? positionStream;

  positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) async {
      if (position != null) {
        await _sendLocationToApi(position.latitude, position.longitude);
      }
    });

  // Tâche de fond périodique par sécurité (toutes les 5 minutes)
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await _sendLocationToApi(position.latitude, position.longitude);
        } catch (e) {
          debugPrint('Error getting location: $e');
        }
      }
    }
  });
}

Future<void> _sendLocationToApi(double latitude, double longitude) async {
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    
    if (token == null) return;

    final url = Uri.parse('${AppConfig.baseUrl}/api/technicians/location');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('📍 Localisation envoyée: $latitude, $longitude');
    } else {
      debugPrint('⚠️ Erreur envoi localisation: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Erreur réseau envoi localisation: $e');
  }
}
