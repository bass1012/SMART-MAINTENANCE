import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/models/installation_service.dart';
import 'package:mct_maintenance_mobile/models/repair_service.dart';
import 'package:mct_maintenance_mobile/models/maintenance_offer_model.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final BaseApiService _apiService;

  ServiceRepositoryImpl(this._apiService);

  @override
  Future<List<MaintenanceOffer>> getMaintenanceOffers() async {
    final response = await _apiService.get('/api/customer/maintenance-offers');
    final data = jsonDecode(response.body);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList.map((json) => MaintenanceOffer.fromJson(json)).toList();
  }

  @override
  Future<List<InstallationService>> getActiveInstallationServices() async {
    final response = await _apiService.get('/api/installation-services/active');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => InstallationService.fromJson(json)).toList();
  }

  @override
  Future<List<RepairService>> getActiveRepairServices() async {
    final response = await _apiService.get('/api/repair-services/active');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => RepairService.fromJson(json)).toList();
  }

  @override
  Future<InstallationService> getInstallationServiceById(int id) async {
    final response = await _apiService.get('/api/installation-services/$id');
    return InstallationService.fromJson(jsonDecode(response.body));
  }

  @override
  Future<RepairService> getRepairServiceById(int id) async {
    final response = await _apiService.get('/api/repair-services/$id');
    return RepairService.fromJson(jsonDecode(response.body));
  }
}
