import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final BaseApiService _apiService;

  PaymentRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> initializeOrderPayment({
    required int orderId,
    required double amount,
    required String reference,
    int paymentStep = 1,
    String? redirectUrl,
    bool? autoRedirect,
  }) async {
    final response = await _apiService
        .post('/api/payments/fineopay/initialize', body: {
      'orderId': orderId,
      'amount': amount,
      'reference': reference,
      'paymentStep': paymentStep,
      'title': paymentStep == 1
          ? 'Commande $reference - Premier paiement (50%)'
          : 'Commande $reference - Paiement final (50%)',
      'description': paymentStep == 1
          ? 'Premier paiement (50%) pour la commande $reference'
          : 'Paiement final (50%) pour la commande $reference',
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (autoRedirect != null) 'autoRedirect': autoRedirect,
    });
    final decoded = jsonDecode(response.body);
    if (decoded['success'] == true && decoded['data'] != null) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(
        decoded['message'] ?? 'Erreur initialisation paiement commande');
  }

  @override
  Future<Map<String, dynamic>> initializeDiagnosticPayment({
    required int interventionId,
    required double amount,
    required String reference,
    String? redirectUrl,
    bool? autoRedirect,
  }) async {
    final response = await _apiService
        .post('/api/payments/fineopay/initialize-diagnostic', body: {
      'interventionId': interventionId,
      'amount': amount,
      'reference': reference,
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (autoRedirect != null) 'autoRedirect': autoRedirect,
    });
    final decoded = jsonDecode(response.body);
    if (decoded['success'] == true && decoded['data'] != null) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(
        decoded['message'] ?? 'Erreur initialisation paiement diagnostic');
  }

  @override
  Future<Map<String, dynamic>> initializeSubscriptionPayment({
    required int subscriptionId,
    required double amount,
    required String reference,
    String? redirectUrl,
    bool? autoRedirect,
  }) async {
    final response = await _apiService
        .post('/api/payments/fineopay/initialize-subscription', body: {
      'subscriptionId': subscriptionId,
      'amount': amount,
      'reference': reference,
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (autoRedirect != null) 'autoRedirect': autoRedirect,
    });
    final decoded = jsonDecode(response.body);
    if (decoded['success'] == true && decoded['data'] != null) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(
        decoded['message'] ?? 'Erreur initialisation paiement abonnement');
  }

  @override
  Future<Map<String, dynamic>> initializeContractPayment({
    required int contractId,
    required double amount,
    required String reference,
    required int phase,
    String? redirectUrl,
    bool? autoRedirect,
  }) async {
    final response = await _apiService
        .post('/api/payments/fineopay/initialize-subscription', body: {
      'subscriptionId': contractId,
      'amount': amount,
      'reference': reference,
      'paymentPhase': phase,
      'title': 'Contrat $reference - Phase $phase',
      'description': 'Paiement du contrat de maintenance $reference (Phase $phase)',
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (autoRedirect != null) 'autoRedirect': autoRedirect,
    });
    final decoded = jsonDecode(response.body);
    if (decoded['success'] == true && decoded['data'] != null) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(
        decoded['message'] ?? 'Erreur initialisation paiement contrat');
  }

  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String reference) async {
    final response =
        await _apiService.get('/api/payments/fineopay/status/$reference');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getPaymentHistory() async {
    final response = await _apiService.get('/api/customer/payments/history');
    return jsonDecode(response.body);
  }

  @override
  Future<List<int>> downloadInvoicePDF(String orderId) async {
    final bytes = await _apiService.getBytes('/api/customer/orders/$orderId/download-invoice');
    return bytes;
  }

  @override
  Future<Map<String, dynamic>> verifyOrderPayment(int orderId) async {
    final response =
        await _apiService.get('/api/fineopay/verify-payment/$orderId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> verifyDiagnosticPayment(int interventionId) async {
    final response = await _apiService
        .get('/api/fineopay/verify-diagnostic-payment/$interventionId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment(int subscriptionId) async {
    final response = await _apiService
        .get('/api/fineopay/verify-subscription-payment/$subscriptionId');
    return jsonDecode(response.body);
  }
}
