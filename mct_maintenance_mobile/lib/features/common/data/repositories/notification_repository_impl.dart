import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/common/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final BaseApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _apiService.get('/api/notifications?page=$page');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await _apiService.get('/api/notifications/unread-count');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    final response = await _apiService.patch('/api/notifications/$notificationId/read');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await _apiService.post('/api/notifications/mark-all-read');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> deleteAll() async {
    final response = await _apiService.delete('/api/notifications/delete-all');
    return jsonDecode(response.body);
  }

  @override
  Future<bool> updateFcmToken(String token) async {
    final response = await _apiService.post('/api/auth/fcm-token', body: {'fcm_token': token});
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _apiService.get('/api/notification-preferences');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> updates) async {
    final response = await _apiService.put('/api/notification-preferences', body: updates);
    return jsonDecode(response.body);
  }

  @override
  Future<bool> toggleEmail(bool enabled) async {
    final response = await _apiService.put('/api/notification-preferences/toggle-email', body: {'enabled': enabled});
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  @override
  Future<bool> togglePush(bool enabled) async {
    final response = await _apiService.put('/api/notification-preferences/toggle-push', body: {'enabled': enabled});
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> resetPreferences() async {
    final response = await _apiService.post('/api/notification-preferences/reset');
    return jsonDecode(response.body);
  }

  @override
  Future<bool> setQuietHours(Map<String, dynamic> data) async {
    final response = await _apiService.put('/api/notification-preferences/quiet-hours', body: data);
    final responseData = jsonDecode(response.body);
    return responseData['success'] == true;
  }
}
