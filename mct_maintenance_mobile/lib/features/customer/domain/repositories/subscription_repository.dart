abstract class SubscriptionRepository {
  Future<List<Map<String, dynamic>>> getSubscriptions();
  Future<List<Map<String, dynamic>>> getPendingSubscriptionPayments();
  Future<Map<String, dynamic>> getSubscriptionDetails(int subscriptionId);
  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId);
  Future<Map<String, dynamic>> createServiceSubscription({
    required int serviceId,
    required String serviceType,
  });
}
