import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/models/complaint_model.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/complaint_repository.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final BaseApiService _apiService;

  ComplaintRepositoryImpl(this._apiService);

  @override
  Future<List<Complaint>> getCustomerComplaints() async {
    final response = await _apiService.get('/api/customer/complaints');
    final data = jsonDecode(response.body);
    return (data['data'] as List).map((item) => Complaint.fromJson(item)).toList();
  }

  @override
  Future<Complaint> getComplaintDetails(String id) async {
    final response = await _apiService.get('/api/customer/complaints/$id');
    final data = jsonDecode(response.body);
    return Complaint.fromJson(data['data']);
  }

  @override
  Future<Map<String, dynamic>> createComplaint(Map<String, dynamic> data) async {
    final response = await _apiService.post('/api/customer/complaints', body: data);
    return jsonDecode(response.body);
  }
}
