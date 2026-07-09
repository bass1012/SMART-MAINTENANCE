import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/equipment_repository.dart';

class EquipmentRepositoryImpl implements EquipmentRepository {
  final BaseApiService _apiService;

  EquipmentRepositoryImpl(this._apiService);

  @override
  Future<List<Map<String, dynamic>>> getMyEquipments() async {
    final response = await _apiService.get('/api/equipments/my-equipments');
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  @override
  Future<Map<String, dynamic>> addEquipment(Map<String, dynamic> data) async {
    final response = await _apiService.post('/api/equipments', body: data);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updateEquipment(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('/api/equipments/$id', body: data);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> deleteEquipment(int id) async {
    final response = await _apiService.delete('/api/equipments/$id');
    return jsonDecode(response.body);
  }
}
