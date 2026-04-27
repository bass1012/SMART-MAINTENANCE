import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Écran WebView pour le paiement Fineopay intégré dans l'application
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final int? orderId;
  final int? subscriptionId;
  final Function(bool success)? onPaymentComplete;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.title = 'Paiement sécurisé',
    this.orderId,
    this.subscriptionId,
    this.onPaymentComplete,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Configuration spécifique iOS pour éviter les erreurs d'authentification SSL
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            if (kDebugMode) print('🌐 WebView page started: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            if (kDebugMode) print('✅ WebView page finished: $url');
            _checkForPaymentCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (kDebugMode) print('🔗 Navigation request: ${request.url}');

            // Détecter les URLs de succès/échec de paiement
            if (_isPaymentSuccessUrl(request.url)) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }

            if (_isPaymentFailureUrl(request.url)) {
              _handlePaymentFailure();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) print('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkForPaymentCompletion(String url) {
    if (_isPaymentSuccessUrl(url)) {
      _handlePaymentSuccess();
    } else if (_isPaymentFailureUrl(url)) {
      _handlePaymentFailure();
    }
  }

  bool _isPaymentSuccessUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final query = uri.query.toLowerCase();

    // Domaine FineoPay uniquement — chemins/params spécifiques
    if (host.contains('fineopay.com')) {
      return path.endsWith('/success') ||
          path.endsWith('/completed') ||
          path.endsWith('/done') ||
          query.contains('status=success') ||
          query.contains('status=completed') ||
          query.contains('status=paid');
    }

    // Domaine MCT API — chemins de callback configurés
    if (host.contains('mct.ci')) {
      return path.contains('/payment/success') ||
          path.contains('/payments/success') ||
          path.contains('/fineopay/success');
    }

    return false;
  }

  bool _isPaymentFailureUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final query = uri.query.toLowerCase();

    if (host.contains('fineopay.com')) {
      return path.endsWith('/failed') ||
          path.endsWith('/failure') ||
          path.endsWith('/cancelled') ||
          query.contains('status=failed') ||
          query.contains('status=cancelled') ||
          query.contains('status=declined');
    }

    if (host.contains('mct.ci')) {
      return path.contains('/payment/cancel') ||
          path.contains('/payment/failed') ||
          path.contains('/payments/cancel');
    }

    return false;
  }

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;
    _paymentCompleted = true;

    if (kDebugMode) print('✅ Paiement détecté comme réussi');

    widget.onPaymentComplete?.call(true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('Paiement réussi !'),
          content: const Text(
            'Votre paiement a été effectué avec succès.\n\n'
            'Vous allez recevoir une confirmation.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialog
                Navigator.pop(context, true); // Retourner avec succès
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _handlePaymentFailure() {
    if (_paymentCompleted) return;
    _paymentCompleted = true;

    if (kDebugMode) print('❌ Paiement détecté comme échoué');

    widget.onPaymentComplete?.call(false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          title: const Text('Paiement échoué'),
          content: const Text(
            'Le paiement n\'a pas pu être effectué.\n\n'
            'Veuillez réessayer ou choisir un autre mode de paiement.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialog
                Navigator.pop(context, false); // Retourner avec échec
              },
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialog
                setState(() {
                  _paymentCompleted = false;
                });
                // Recharger la page de paiement
                _controller.loadRequest(Uri.parse(widget.paymentUrl));
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler le paiement ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, continuer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF0a543d),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context, false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF0a543d)),
                  ),
                ],
              ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Les deux boutons sur la même ligne
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon:
                            const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          'Paiement effectué',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0a543d),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Indicateur de sécurité
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Color(0xFF0a543d), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Paiement sécurisé FineoPay',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Indicateur de sécurité
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.paid_rounded,
                        color: Color(0xFF0a543d), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Terminé le processus de paiement dans le navigateur\navant cliquer sur "Paiement effectué"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog pour afficher le paiement en popup
class PaymentWebViewDialog extends StatelessWidget {
  final String paymentUrl;
  final String title;
  final int? orderId;

  const PaymentWebViewDialog({
    super.key,
    required this.paymentUrl,
    this.title = 'Paiement sécurisé',
    this.orderId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String paymentUrl,
    String title = 'Paiement sécurisé',
    int? orderId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Pour équilibrer
                  ],
                ),
              ),
              const Divider(),
              // WebView
              Expanded(
                child: PaymentWebViewScreen(
                  paymentUrl: paymentUrl,
                  title: title,
                  orderId: orderId,
                  onPaymentComplete: (success) {
                    Navigator.pop(context, success);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaymentWebViewScreen(
      paymentUrl: paymentUrl,
      title: title,
      orderId: orderId,
    );
  }
}
