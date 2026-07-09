import 'package:mct_maintenance_mobile/models/quote_contract_model.dart';
import 'package:mct_maintenance_mobile/models/contract_model.dart';

abstract class ContractRepository {
  Future<List<QuoteContract>> getCustomerQuotes();
  Future<List<Contract>> getCustomerContracts();
  Future<QuoteContract> getQuoteDetails(String quoteId);
  Future<Contract> getContractDetails(String contractId);
  Future<Map<String, dynamic>> acceptQuote(
    String quoteId, {
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
    String paymentOption = 'split',
  });
  Future<QuoteContract> rejectQuote(String quoteId, String reason);
  Future<Map<String, dynamic>> requestContractRenewal(int contractId);
  Future<Map<String, dynamic>> getCustomerQuotesRaw();
  Future<Map<String, dynamic>> verifySubscriptionPayment(int subscriptionId);
  Future<Map<String, dynamic>> confirmContractPayment(int subscriptionId);
  Future<List<int>> downloadQuotePDF(String quoteId);
}
