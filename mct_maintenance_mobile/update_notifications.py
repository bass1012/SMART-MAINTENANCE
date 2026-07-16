import re

file_path = '/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/lib/features/customer/presentation/screens/notifications_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

delete_method = """
  Future<void> _deleteNotification(int notificationId) async {
    try {
      // Pour l'instant on utilise markAsRead coté API s'il n'y a pas de delete
      await _notificationRepository.markAsRead(notificationId); 
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        _unreadCount = _notifications.where((n) => !(n['is_read'] ?? false)).length;
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Notification supprimée', emoji: '🗑️');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la suppression');
      }
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
"""

# Ajouter _deleteNotification juste avant _buildNotificationCard
if "_deleteNotification" not in content:
    content = content.replace("  Widget _buildNotificationCard(Map<String, dynamic> notification) {", delete_method)

# Ajouter Dismissible
# On va chercher le "return InkWell(" dans _buildNotificationCard et l'encadrer avec Dismissible
def wrap_with_dismissible(match):
    return f"""return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {{
        _deleteNotification(notification['id']);
      }},
      child: {match.group(1)}"""

if "Dismissible(" not in content:
    content = re.sub(r'return\s+(InkWell\()', wrap_with_dismissible, content)

with open(file_path, 'w') as f:
    f.write(content)
