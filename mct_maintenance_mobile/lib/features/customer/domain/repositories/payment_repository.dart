abstract class PaymentRepository {
  Future<Map<String, dynamic>> initializeOrderPayment({
    required int orderId,
    required double amount,
    required String reference,
    int paymentStep = 1,
    String? redirectUrl,
    bool? autoRedirect,
  });
  
  Future<Map<String, dynamic>> initializeDiagnosticPayment({
    required int interventionId,
    required double amount,
    required String reference,
    String? redirectUrl,
    bool? autoRedirect,
  });

  Future<Map<String, dynamic>> initializeSubscriptionPayment({
    required int subscriptionId,
    required double amount,
    required String reference,
    String? redirectUrl,
    bool? autoRedirect,
  });

  Future<Map<String, dynamic>> initializeContractPayment({
    required int contractId,
    required double amount,
    required String reference,
    required int phase,
    String? redirectUrl,
    bool? autoRedirect,
  });

  Future<Map<String, dynamic>> checkPaymentStatus(String reference);
  Future<Map<String, dynamic>> getPaymentHistory();
  Future<List<int>> downloadInvoicePDF(String orderId);
  Future<Map<String, dynamic>> verifyOrderPayment(int orderId);
  Future<Map<String, dynamic>> verifyDiagnosticPayment(int interventionId);
  Future<Map<String, dynamic>> verifySubscriptionPayment(int subscriptionId);
}
