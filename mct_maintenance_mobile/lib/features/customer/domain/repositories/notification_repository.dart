abstract class CustomerNotificationRepository {
  Future<Map<String, dynamic>> getNotifications();
  Future<Map<String, dynamic>> markNotificationAsRead(int id);
  Future<Map<String, dynamic>> markAllNotificationsAsRead();
  Future<Map<String, dynamic>> deleteAllNotifications();
  Future<int> getUnreadNotificationsCount();
}
