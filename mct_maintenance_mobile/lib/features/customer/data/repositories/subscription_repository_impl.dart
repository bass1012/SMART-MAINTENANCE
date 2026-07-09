import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final BaseApiService _apiService;

  SubscriptionRepositoryImpl(this._apiService);

  @override
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    final response = await _apiService.get('/api/customer/subscriptions');
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSubscriptionPayments() async {
    final subscriptions = await getSubscriptions();
    return subscriptions
        .where((s) => s['payment_status'] == 'pending' && s['status'] == 'active')
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionDetails(int subscriptionId) async {
    final response = await _apiService.get('/api/customer/subscriptions/$subscriptionId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    final response = await _apiService.post('/api/customer/subscriptions/$subscriptionId/cancel');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> createServiceSubscription({
    required int serviceId,
    required String serviceType,
  }) async {
    final response = await _apiService.post('/api/customer/subscriptions', body: {
      'service_id': serviceId,
      'service_type': serviceType,
    });
    return jsonDecode(response.body);
  }
}
