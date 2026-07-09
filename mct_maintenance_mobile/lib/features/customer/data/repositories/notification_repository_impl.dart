import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/notification_repository.dart';

class CustomerNotificationRepositoryImpl implements CustomerNotificationRepository {
  final BaseApiService _apiService;

  CustomerNotificationRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _apiService.get('/api/notifications');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    final response = await _apiService.patch('/api/notifications/$id/read');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await _apiService.post('/api/notifications/mark-all-read');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    final response = await _apiService.delete('/api/notifications/delete-all');
    return jsonDecode(response.body);
  }

  @override
  Future<int> getUnreadNotificationsCount() async {
    final response = await _apiService.get('/api/notifications/unread-count');
    final data = jsonDecode(response.body);
    return data['data']['unread_count'] ?? 0;
  }
}
