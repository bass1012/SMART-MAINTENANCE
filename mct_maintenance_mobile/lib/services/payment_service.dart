import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Initialiser un paiement FineoPay pour une commande
  Future<Map<String, dynamic>> initializeOrderPayment(
    int orderId,
    double amount,
    String reference, {
    int paymentStep = 1, // 1 = premier paiement 50%, 2 = second paiement 50%
  }) async {
    try {
      if (kDebugMode) debugPrint(
          '💳 Initialisation paiement pour commande $orderId (étape $paymentStep)');

      final response = await _apiService.post(
        '/payments/fineopay/initialize',
        {
          'orderId': orderId,
          'amount': amount,
          'title': paymentStep == 1
              ? 'Commande $reference - Premier paiement (50%)'
              : 'Commande $reference - Paiement final (50%)',
          'description': paymentStep == 1
              ? 'Premier paiement (50%) pour la commande $reference'
              : 'Paiement final (50%) pour la commande $reference',
          'paymentStep': paymentStep,
        },
      );

      if (response['success'] == true) {
        if (kDebugMode) debugPrint('✅ Paiement initialisé avec FineoPay');
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Erreur initialisation paiement');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur initialisation paiement: $e');
      rethrow;
    }
  }

  /// Ouvrir le lien de paiement FineoPay dans le navigateur
  Future<void> openPaymentUrl(String paymentUrl) async {
    try {
      if (kDebugMode) debugPrint('🔗 Tentative d\'ouverture de l\'URL: $paymentUrl');
      final Uri url = Uri.parse(paymentUrl);

      if (kDebugMode) debugPrint('🔍 Vérification canLaunchUrl...');
      final canLaunch = await canLaunchUrl(url);
      if (kDebugMode) debugPrint('🔍 canLaunchUrl result: $canLaunch');

      if (canLaunch) {
        if (kDebugMode) debugPrint('🚀 Lancement de l\'URL dans le navigateur...');
        final result = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (kDebugMode) debugPrint('✅ launchUrl result: $result');
        if (kDebugMode) debugPrint('✅ URL de paiement ouverte: $paymentUrl');
      } else {
        if (kDebugMode) debugPrint('❌ canLaunchUrl a retourné false');
        throw Exception(
            'Impossible d\'ouvrir le lien de paiement. Veuillez vérifier vos paramètres.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur ouverture URL: $e');
      if (kDebugMode) debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      if (kDebugMode) debugPrint('🔍 Vérification statut paiement: $transactionId');

      final response = await _apiService.get(
        '/payments/fineopay/status/$transactionId',
      );

      if (response['success'] == true) {
        if (kDebugMode) debugPrint('✅ Statut récupéré: ${response['data']}');
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Erreur vérification statut');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur vérification statut: $e');
      rethrow;
    }
  }

  /// Initialiser un paiement pour les frais de diagnostic
  Future<Map<String, dynamic>> initializeDiagnosticPayment(
      int interventionId) async {
    try {
      if (kDebugMode) debugPrint(
          '💳 Initialisation paiement diagnostic pour intervention $interventionId');

      final response = await _apiService.post(
        '/payments/fineopay/initialize-diagnostic',
        {'interventionId': interventionId},
      );

      if (response['success'] == true) {
        if (kDebugMode) debugPrint(
            '✅ Paiement diagnostic initialisé: ${response['data']['transaction_id']}');
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Erreur initialisation paiement diagnostic');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur initialisation paiement diagnostic: $e');
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

      if (kDebugMode) debugPrint('✅ Paiement FineoPay lancé avec succès');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur processus paiement: $e');
      return false;
    }
  }

  /// Initialiser un paiement FineoPay pour un contrat/subscription
  Future<Map<String, dynamic>> initializeSubscriptionPayment(
    int subscriptionId,
    double amount,
    String reference, {
    int? paymentPhase,
  }) async {
    try {
      final phaseLabel = paymentPhase == 1
          ? '1er paiement (50%)'
          : (paymentPhase == 2 ? '2ème paiement (50%)' : '');
      if (kDebugMode) debugPrint(
          '💳 Initialisation paiement pour contrat $subscriptionId - $phaseLabel');

      final response = await _apiService.post(
        '/payments/fineopay/initialize-subscription',
        {
          'subscriptionId': subscriptionId,
          'amount': amount,
          'title':
              'Contrat $reference${paymentPhase != null ? ' - ${paymentPhase == 1 ? "1er" : "2ème"} paiement' : ''}',
          'description':
              'Paiement du contrat de maintenance $reference${paymentPhase != null ? ' (${paymentPhase == 1 ? "50% à la validation" : "50% dernière visite"})' : ''}',
          'paymentPhase': paymentPhase,
        },
      );

      if (response['success'] == true) {
        if (kDebugMode) debugPrint('✅ Paiement contrat initialisé avec FineoPay');
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Erreur initialisation paiement contrat');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur initialisation paiement contrat: $e');
      rethrow;
    }
  }
}
