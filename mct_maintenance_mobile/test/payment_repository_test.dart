import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/payment_repository_impl.dart';

class _RecordingApiService extends BaseApiService {
  String? lastEndpoint;
  dynamic lastBody;
  int postCalls = 0;

  @override
  Future<http.Response> post(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    postCalls++;
    lastEndpoint = endpoint;
    lastBody = body;
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {'paymentUrl': 'https://payment.test/checkout'}
      }),
      200,
    );
  }

  @override
  Future<http.Response> get(String endpoint,
      {Map<String, dynamic>? queryParams, Map<String, String>? headers}) async {
    lastEndpoint = endpoint;
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'id': 42,
          'status': 'active',
          'payment_status': 'paid',
          'first_payment_status': 'paid'
        }
      }),
      200,
    );
  }
}

void main() {
  test('un montant de souscription nul reste confirmé par le serveur',
      () async {
    final api = _RecordingApiService();
    final repository = PaymentRepositoryImpl(api);

    final result = await repository.initializeSubscriptionPayment(
      subscriptionId: 42,
      amount: 0,
      reference: 'SUB-42',
    );

    expect(api.lastEndpoint, '/api/fineopay/verify-subscription-payment/42');
    expect(api.postCalls, 0);
    expect(result['payment_status'], 'paid');
  });
}
