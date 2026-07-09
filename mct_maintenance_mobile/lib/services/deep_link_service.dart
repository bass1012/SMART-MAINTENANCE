import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Stream to propagate payment callback events to active payment screens
  final _paymentController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get paymentStream => _paymentController.stream;

  void initialize() {
    if (_linkSubscription != null) return;

    if (kDebugMode) {
      debugPrint('🔗 [DeepLinkService] Initializing DeepLinkService...');
    }

    // Handle links received while the app is already running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        if (kDebugMode) {
          debugPrint('❌ [DeepLinkService] Stream error: $err');
        }
      },
    );

    // Handle the link that launched the app (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }).catchError((err) {
      if (kDebugMode) {
        debugPrint('❌ [DeepLinkService] Initial link error: $err');
      }
    });
  }

  void _handleUri(Uri uri) {
    if (kDebugMode) {
      debugPrint('🔗 [DeepLinkService] Intercepted link: $uri');
    }

    // Check if this is our payment callback
    if (uri.scheme == 'smartmaintenance' && uri.host == 'payment-callback') {
      final status = uri.queryParameters['status'] ?? '';
      final reference = uri.queryParameters['reference'] ?? '';
      final syncRef = uri.queryParameters['syncRef'] ?? '';

      if (kDebugMode) {
        debugPrint('💳 [DeepLinkService] Payment callback detected:');
        debugPrint('   - Status: $status');
        debugPrint('   - Reference: $reference');
        debugPrint('   - SyncRef: $syncRef');
      }

      _paymentController.add({
        'status': status,
        'reference': reference,
        'syncRef': syncRef,
      });
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _paymentController.close();
  }
}
