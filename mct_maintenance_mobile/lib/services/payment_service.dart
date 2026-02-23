import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Initialiser un paiement FineoPay pour une commande
  Future<Map<String, dynamic>> initializeOrderPayment(
    int orderId,
    double amount,
    String reference,
  ) async {
    try {
      print('💳 Initialisation paiement pour commande $orderId');

      final response = await _apiService.post(
        '/payments/fineopay/initialize',
        {
          'orderId': orderId,
          'amount': amount,
          'title': 'Commande $reference',
          'description': 'Paiement pour la commande $reference',
        },
      );

      if (response['success'] == true) {
        print('✅ Paiement initialisé avec FineoPay');
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Erreur initialisation paiement');
      }
    } catch (e) {
      print('❌ Erreur initialisation paiement: $e');
      rethrow;
    }
  }

  /// Ouvrir le lien de paiement FineoPay dans le navigateur
  Future<void> openPaymentUrl(String paymentUrl) async {
    try {
      print('🔗 Tentative d\'ouverture de l\'URL: $paymentUrl');
      final Uri url = Uri.parse(paymentUrl);

      print('🔍 Vérification canLaunchUrl...');
      final canLaunch = await canLaunchUrl(url);
      print('🔍 canLaunchUrl result: $canLaunch');

      if (canLaunch) {
        print('🚀 Lancement de l\'URL dans le navigateur...');
        final result = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        print('✅ launchUrl result: $result');
        print('✅ URL de paiement ouverte: $paymentUrl');
      } else {
        print('❌ canLaunchUrl a retourné false');
        throw Exception(
            'Impossible d\'ouvrir le lien de paiement. Veuillez vérifier vos paramètres.');
      }
    } catch (e) {
      print('❌ Erreur ouverture URL: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      print('🔍 Vérification statut paiement: $transactionId');

      final response = await _apiService.get(
        '/payments/fineopay/status/$transactionId',
      );

      if (response['success'] == true) {
        print('✅ Statut récupéré: ${response['data']}');
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Erreur vérification statut');
      }
    } catch (e) {
      print('❌ Erreur vérification statut: $e');
      rethrow;
    }
  }

  /// Initialiser un paiement pour les frais de diagnostic
  Future<Map<String, dynamic>> initializeDiagnosticPayment(
      int interventionId) async {
    try {
      print(
          '💳 Initialisation paiement diagnostic pour intervention $interventionId');

      final response = await _apiService.post(
        '/payments/fineopay/initialize-diagnostic',
        {'interventionId': interventionId},
      );

      if (response['success'] == true) {
        print(
            '✅ Paiement diagnostic initialisé: ${response['data']['transaction_id']}');
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Erreur initialisation paiement diagnostic');
      }
    } catch (e) {
      print('❌ Erreur initialisation paiement diagnostic: $e');
      rethrow;
    }
  }

  /// Lancer le processus complet de paiement
  Future<bool> processOrderPayment(
    int orderId,
    double amount,
    String reference,
  ) async {
    try {
      // 1. Initialiser le paiement
      final paymentData =
          await initializeOrderPayment(orderId, amount, reference);
      final paymentUrl = paymentData['paymentUrl'] as String;

      // 2. Ouvrir le lien de paiement
      await openPaymentUrl(paymentUrl);

      print('✅ Paiement FineoPay lancé avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur processus paiement: $e');
      return false;
    }
  }
}
