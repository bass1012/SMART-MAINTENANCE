abstract class NotificationRepository {
  Future<Map<String, dynamic>> getNotifications({int page = 1});
  Future<Map<String, dynamic>> getUnreadCount();
  Future<Map<String, dynamic>> markAsRead(int notificationId);
  Future<Map<String, dynamic>> markAllAsRead();
  Future<Map<String, dynamic>> deleteAll();
  Future<bool> updateFcmToken(String token);
  Future<Map<String, dynamic>> getPreferences();
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> updates);
  Future<bool> toggleEmail(bool enabled);
  Future<bool> togglePush(bool enabled);
  Future<Map<String, dynamic>> resetPreferences();
  Future<bool> setQuietHours(Map<String, dynamic> data);
}
