import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/snackbar_helper.dart';

class TechnicianMessagesScreen extends StatefulWidget {
  const TechnicianMessagesScreen({super.key});

  @override
  State<TechnicianMessagesScreen> createState() =>
      _TechnicianMessagesScreenState();
}

class _TechnicianMessagesScreenState extends State<TechnicianMessagesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      // Simuler des conversations pour l'instant
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _conversations = [
            {
              'id': 1,
              'customer_name': 'Jean Dupont',
              'customer_avatar': null,
              'last_message':
                  'Merci pour votre intervention, tout fonctionne parfaitement !',
              'last_message_time': '10:30',
              'unread_count': 0,
              'intervention_title': 'Réparation climatisation',
            },
            {
              'id': 2,
              'customer_name': 'Marie Lambert',
              'customer_avatar': null,
              'last_message': 'Pouvez-vous passer demain matin ?',
              'last_message_time': '09:15',
              'unread_count': 2,
              'intervention_title': 'Installation chaudière',
            },
            {
              'id': 3,
              'customer_name': 'Pierre Martin',
              'customer_avatar': null,
              'last_message': 'Le devis est-il prêt ?',
              'last_message_time': 'Hier',
              'unread_count': 1,
              'intervention_title': 'Dépannage plomberie',
            },
            {
              'id': 4,
              'customer_name': 'Sophie Bernard',
              'customer_avatar': null,
              'last_message': 'Intervention terminée avec succès',
              'last_message_time': '15/10',
              'unread_count': 0,
              'intervention_title': 'Entretien annuel',
            },
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Messages Clients',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () async {
              await _loadConversations();
              if (mounted) {
                SnackBarHelper.showSuccess(context, 'Messages actualisés',
                    emoji: '✅');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              SnackBarHelper.showInfo(context, 'Recherche - À implémenter');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: _conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        return _buildConversationCard(conversation);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun message',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos conversations avec les clients apparaîtront ici',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final hasUnread = conversation['unread_count'] > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasUnread
            ? Border.all(
                color: const Color(0xFF0a543d).withOpacity(0.3), width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF0a543d).withOpacity(0.1),
              child: Text(
                conversation['customer_name'][0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0a543d),
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${conversation['unread_count']}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation['customer_name'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              conversation['last_message_time'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: hasUnread ? const Color(0xFF0a543d) : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build, size: 12, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    conversation['intervention_title'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              conversation['last_message'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: hasUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF0a543d)),
        onTap: () {
          _openChat(conversation);
        },
      ),
    );
  }

  void _openChat(Map<String, dynamic> conversation) {
    SnackBarHelper.showInfo(
        context, 'Chat avec ${conversation['customer_name']} - À implémenter');
  }
}
