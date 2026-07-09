abstract class EquipmentRepository {
  Future<List<Map<String, dynamic>>> getMyEquipments();
  Future<Map<String, dynamic>> addEquipment(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateEquipment(int id, Map<String, dynamic> data);
  Future<Map<String, dynamic>> deleteEquipment(int id);
}
