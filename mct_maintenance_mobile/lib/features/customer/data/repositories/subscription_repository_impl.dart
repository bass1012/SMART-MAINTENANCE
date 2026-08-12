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
        .where((s) =>
            s['payment_status'] == 'pending' &&
            (s['status'] == 'active' || s['status'] == 'pending_payment'))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionDetails(
      int subscriptionId) async {
    final response =
        await _apiService.get('/api/customer/subscriptions/$subscriptionId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    final response = await _apiService
        .post('/api/customer/subscriptions/$subscriptionId/cancel');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> createServiceSubscription({
    required int serviceId,
    required String serviceType,
  }) async {
    final response =
        await _apiService.post('/api/customer/subscriptions', body: {
      'service_id': serviceId,
      'service_type': serviceType,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> createMaintenanceSubscription({
    required int maintenanceOfferId,
    required int equipmentCount,
    DateTime? firstInterventionDate,
    String? promoCode,
    Map<String, dynamic>? interventionData,
  }) async {
    final response =
        await _apiService.post('/api/customer/subscriptions', body: {
      'maintenance_offer_id': maintenanceOfferId,
      'equipment_count': equipmentCount,
      if (firstInterventionDate != null)
        'first_intervention_date':
            firstInterventionDate.toIso8601String().split('T').first,
      if (promoCode != null) 'promo_code': promoCode,
      if (interventionData != null) ...interventionData,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> createAnnualSubscription({
    required int maintenanceOfferId,
    required int equipmentCount,
    required DateTime firstInterventionDate,
    int? splitId,
    Map<String, dynamic>? interventionData,
  }) async {
    final response =
        await _apiService.post('/api/customer/subscriptions/annual', body: {
      'maintenance_offer_id': maintenanceOfferId,
      'equipment_count': equipmentCount,
      'first_intervention_date':
          firstInterventionDate.toIso8601String().split('T').first,
      if (splitId != null) 'split_id': splitId,
      if (interventionData != null) ...interventionData,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getReferralReward() async {
    final response = await _apiService.get('/api/customer/referral-reward');
    return jsonDecode(response.body);
  }
}

