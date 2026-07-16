import re

file_path = '/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/lib/features/customer/presentation/screens/notifications_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Etape 1: on va chercher _buildNotificationCard
# et retirer le margin: const EdgeInsets.only(bottom: 12),

content = content.replace("margin: const EdgeInsets.only(bottom: 12),", "")

# Etape 2: on va ajouter le Dismissible mais AVEC le margin englobant
# on englobe le Container principal
def wrap_with_dismissible(match):
    return f"""return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
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
        child: {match.group(1)}
      ),
    );"""

content = re.sub(r'return\s+(Container\()', wrap_with_dismissible, content)

with open(file_path, 'w') as f:
    f.write(content)
