import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/subscription_repository_impl.dart';

/// Capture l'endpoint et le corps réellement envoyés, sans appel réseau.
class _RecordingApiService extends BaseApiService {
  String? lastEndpoint;
  dynamic lastBody;

  @override
  Future<http.Response> post(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    lastEndpoint = endpoint;
    lastBody = body;
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'subscription': {'id': 44, 'payment_status': 'pending'},
          'pricing': {'first_payment_amount': 9001}
        }
      }),
      201,
    );
  }
}

void main() {
  test(
      'createAnnualSubscription cible la route contrat annuel, pas la route générique',
      () async {
    final api = _RecordingApiService();
    final repository = SubscriptionRepositoryImpl(api);

    final response = await repository.createAnnualSubscription(
      maintenanceOfferId: 9,
      equipmentCount: 2,
      firstInterventionDate: DateTime(2026, 9, 1),
    );

    expect(api.lastEndpoint, '/api/customer/subscriptions/annual');
    expect(api.lastBody, {
      'maintenance_offer_id': 9,
      'equipment_count': 2,
      'first_intervention_date': '2026-09-01',
    });
    expect(response['data']['subscription']['id'], 44);
  });

  test('createMaintenanceSubscription reste sur la route ponctuelle', () async {
    final api = _RecordingApiService();
    final repository = SubscriptionRepositoryImpl(api);

    await repository.createMaintenanceSubscription(
      maintenanceOfferId: 3,
      equipmentCount: 1,
    );

    expect(api.lastEndpoint, '/api/customer/subscriptions');
  });
}
