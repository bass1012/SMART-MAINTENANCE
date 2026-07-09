import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/models/quote_contract_model.dart';
import 'package:mct_maintenance_mobile/models/contract_model.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/contract_repository.dart';

class ContractRepositoryImpl implements ContractRepository {
  final BaseApiService _apiService;

  ContractRepositoryImpl(this._apiService);

  @override
  Future<List<QuoteContract>> getCustomerQuotes() async {
    final response = await _apiService.get('/api/customer/quotes');
    final data = jsonDecode(response.body);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList.map((json) => QuoteContract.fromJson(json)).toList();
  }

  @override
  Future<List<Contract>> getCustomerContracts() async {
    final response = await _apiService.get('/api/customer/contracts');
    final data = jsonDecode(response.body);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList.map((json) => Contract.fromJson(json)).toList();
  }

  @override
  Future<QuoteContract> getQuoteDetails(String quoteId) async {
    final response = await _apiService.get('/api/customer/quotes/$quoteId');
    final data = jsonDecode(response.body);
    return QuoteContract.fromJson(data['data']);
  }

  @override
  Future<Contract> getContractDetails(String contractId) async {
    final response = await _apiService.get('/api/customer/contracts/$contractId');
    final data = jsonDecode(response.body);
    return Contract.fromJson(data['data']);
  }

  @override
  Future<Map<String, dynamic>> acceptQuote(
    String quoteId, {
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
    String paymentOption = 'split',
  }) async {
    final body = {
      'execute_now': executeNow,
      'payment_option': paymentOption,
      if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String(),
      if (secondContact != null) 'second_contact': secondContact,
    };
    final response = await _apiService.post('/api/customer/quotes/$quoteId/accept', body: body);
    return jsonDecode(response.body);
  }

  @override
  Future<QuoteContract> rejectQuote(String quoteId, String reason) async {
    final body = {'reason': reason};
    final response = await _apiService.post('/api/customer/quotes/$quoteId/reject', body: body);
    final data = jsonDecode(response.body);
    return QuoteContract.fromJson(data['data']);
  }

  @override
  Future<Map<String, dynamic>> requestContractRenewal(int contractId) async {
    final response = await _apiService.post('/api/customer/contracts/$contractId/request-renewal');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getCustomerQuotesRaw() async {
    final response = await _apiService.get('/api/customer/quotes');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment(int subscriptionId) async {
    final response = await _apiService.get('/api/fineopay/verify-subscription-payment/$subscriptionId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> confirmContractPayment(int subscriptionId) async {
    final response = await _apiService.post('/api/customer/contracts/$subscriptionId/confirm-payment');
    return jsonDecode(response.body);
  }

  @override
  Future<List<int>> downloadQuotePDF(String quoteId) async {
    final bytes = await _apiService.getBytes('/api/quotes/$quoteId/pdf');
    return bytes;
  }
}
