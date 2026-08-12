abstract class SubscriptionRepository {
  Future<List<Map<String, dynamic>>> getSubscriptions();
  Future<List<Map<String, dynamic>>> getPendingSubscriptionPayments();
  Future<Map<String, dynamic>> getSubscriptionDetails(int subscriptionId);
  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId);
  Future<Map<String, dynamic>> createServiceSubscription({
    required int serviceId,
    required String serviceType,
  });
  Future<Map<String, dynamic>> createMaintenanceSubscription({
    required int maintenanceOfferId,
    required int equipmentCount,
    DateTime? firstInterventionDate,
    String? promoCode,
    Map<String, dynamic>? interventionData,
  });

  /// Souscription à une offre `offer_type == 'annual'`.
  ///
  /// Passe par la route dédiée qui crée un contrat `scheduled` : visites
  /// planifiées, remise annuelle appliquée et conditions figées côté serveur.
  /// La remise annuelle est exclusive : aucun code promo n'est accepté ici.
  Future<Map<String, dynamic>> createAnnualSubscription({
    required int maintenanceOfferId,
    required int equipmentCount,
    required DateTime firstInterventionDate,
    int? splitId,
    Map<String, dynamic>? interventionData,
  });

  /// Récupère l'éligibilité du client à la récompense parrainage (50% après 3 filleuls)
  Future<Map<String, dynamic>> getReferralReward();
}

