import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mct_maintenance_mobile/config/environment.dart';

// Constantes
const String supportPhone = '+225 07 09 09 09 42';
const String supportEmail = 'contact@mct.ci';
const String supportWhatsApp = '2250709090942';
const String facebookMessengerUrl =
    'https://m.me/Smartmaintenancebymct'; // Lien Messenger direct
const String instagramDmUrl =
    'https://ig.me/m/smartmaintenancebymct'; // Lien DM Instagram direct
const String linkedinUrl =
    'https://www.linkedin.com/company/mct-maintenance-climatisation-technique/posts/?feedView=all';
const String websiteUrl = 'https://www.smartmaintenance.ci/';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isLoading = true;
  String? _typingUser;

  @override
  bool get wantKeepAlive => true; // Garder le widget en vie

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedMessages();
  }

  // Charger les messages depuis le cache persistant
  Future<void> _loadCachedMessages() async {
    final cachedMessages = await _chatService.cachedMessages;
    if (cachedMessages.isNotEmpty) {
      print(
          '📦 [SupportScreen] ${cachedMessages.length} messages restaurés depuis le cache');
      setState(() {
        _messages =
            cachedMessages.map((json) => ChatMessage.fromJson(json)).toList();
      });
      // Scroller vers le bas après la restauration
      _scrollToBottom();
    }

    // Initialiser le chat après avoir chargé le cache
    _initChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, vérification de la connexion chat...');
      _chatService.ensureConnected();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      // Connexion Socket.IO
      await _chatService.connect();

      // Écouter les changements de connexion
      _chatService.connectionStream.listen((connected) {
        if (mounted) {
          setState(() => _isConnected = connected);
          // NE PLUS recharger l'historique automatiquement
          // Les nouveaux messages arrivent via messageStream
        }
      });

      // Écouter les nouveaux messages
      _chatService.messageStream.listen((data) {
        if (mounted) {
          print('📨 [SupportScreen] Nouveau message reçu: ${data['message']}');
          final newMessage = ChatMessage.fromJson(data);

          // Vérifier si le message n'existe pas déjà (éviter les doublons)
          final exists = _messages.any((msg) {
            // Même ID de base de données
            if (msg.id == newMessage.id && newMessage.id > 0) return true;
            // Même contenu, même sender, timestamp proche
            final timeDiff =
                msg.createdAt.difference(newMessage.createdAt).abs();
            return msg.message == newMessage.message &&
                msg.senderId == newMessage.senderId &&
                timeDiff.inSeconds < 2;
          });

          if (!exists) {
            print(
                '✅ [SupportScreen] Message ajouté (${_messages.length} -> ${_messages.length + 1})');
            print(
                '   → ID: ${newMessage.id}, isRead: ${newMessage.isRead}, sender: ${newMessage.senderRole}');
            setState(() {
              _messages.add(newMessage);
            });
            // Mettre à jour le cache (async)
            _chatService.addMessageToCache(data).catchError((e) {
              print('⚠️ Erreur sauvegarde cache: $e');
            });
            _scrollToBottom();

            // Marquer le message comme lu si c'est un message du support
            // (sender_role = 'admin' ou 'technician') et qu'il a un ID valide
            if (newMessage.id > 0 &&
                (newMessage.senderRole == 'admin' ||
                    newMessage.senderRole == 'technician')) {
              _markMessageAsRead(newMessage.id);
            }
          } else {
            print('⚠️ [SupportScreen] Message déjà existant, ignoré');
          }
        }
      });

      // Écouter les indicateurs de saisie
      _chatService.typingStream.listen((data) {
        if (mounted) {
          setState(() {
            if (data['isTyping'] == false) {
              _typingUser = null;
            } else {
              _typingUser = data['userName'] ?? 'Support';
            }
          });
        }
      });

      // Écouter les mises à jour de lecture des messages
      _chatService.messagesReadStream.listen((messageIds) {
        if (mounted) {
          print(
              '📖 [SupportScreen] Événement reçu: ${messageIds.length} IDs = $messageIds');
          print(
              '📖 [SupportScreen] Messages actuels dans la liste: ${_messages.map((m) => m.id).toList()}');
          setState(() {
            for (var id in messageIds) {
              final index = _messages.indexWhere((msg) => msg.id == id);
              if (index != -1) {
                print(
                    '✅ [SupportScreen] Message $id trouvé à l\'index $index, mise à jour isRead → true');
                _messages[index] = ChatMessage(
                  id: _messages[index].id,
                  senderId: _messages[index].senderId,
                  senderRole: _messages[index].senderRole,
                  message: _messages[index].message,
                  isRead: true, // Mettre à jour l'état de lecture
                  createdAt: _messages[index].createdAt,
                  senderName: _messages[index].senderName,
                );
              } else {
                print('❌ [SupportScreen] Message $id NOT FOUND dans la liste');
              }
            }
          });
        }
      });

      // Toujours charger l'historique pour synchroniser avec les nouveaux messages
      // (cas où l'utilisateur reçoit une notification FCM alors qu'il n'est pas sur la page)
      print(
          '📜 [SupportScreen] Chargement de l\'historique pour synchronisation...');
      await _loadChatHistory();
    } catch (e) {
      print('Erreur initialisation chat: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadChatHistory() async {
    print(
        '📜 [SupportScreen] Chargement historique... Messages actuels: ${_messages.length}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/chat/history?limit=50'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Le backend retourne data.data (liste des messages)
        final messagesJson = (data['data'] ?? []) as List;

        print(
            '📜 [SupportScreen] Historique reçu: ${messagesJson.length} messages');

        if (mounted) {
          setState(() {
            // Fusionner intelligemment : combiner historique et messages actuels
            final historyMessages =
                messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

            // Garder les messages actuels qui sont plus récents que le dernier message de l'historique
            final lastHistoryTimestamp = historyMessages.isNotEmpty
                ? historyMessages.last.createdAt
                : DateTime.fromMillisecondsSinceEpoch(0);

            print(
                '📜 [SupportScreen] Dernier timestamp historique: $lastHistoryTimestamp');

            // Messages récents non présents dans l'historique (envoyés après le chargement)
            final recentMessages = _messages.where((msg) {
              // Si le message est plus récent que le dernier de l'historique
              if (msg.createdAt.isAfter(lastHistoryTimestamp)) return true;
              // Ou si c'est un message optimiste (ID négatif)
              if (msg.id < 0) return true;
              return false;
            }).toList();

            print(
                '📜 [SupportScreen] Messages récents conservés: ${recentMessages.length}');

            // Combiner : historique + messages récents (éviter les doublons par ID)
            final allMessages = [...historyMessages];
            for (final recentMsg in recentMessages) {
              if (!allMessages
                  .any((m) => m.id == recentMsg.id && recentMsg.id > 0)) {
                allMessages.add(recentMsg);
              }
            }

            print(
                '📜 [SupportScreen] Total après fusion: ${allMessages.length}');

            _messages = allMessages;

            // Mettre à jour le cache avec TOUS les messages fusionnés (historique + récents)
            final jsonMessages =
                allMessages.map((msg) => msg.toJson()).toList();
            _chatService.setCachedMessages(jsonMessages).catchError((e) {
              print('⚠️ Erreur sauvegarde cache fusion: $e');
            });
          });
          _scrollToBottom();

          // Marquer tous les messages non lus du support comme lus
          _markAllUnreadMessagesAsRead();
        }
      }
    } catch (e) {
      print('Erreur chargement historique: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessages() async {
    if (!mounted) return;

    print('🔄 [SupportScreen] Actualisation des messages...');

    try {
      setState(() => _isLoading = true);

      // Recharger l'historique depuis le serveur
      await _loadChatHistory();

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Messages actualisés',
          emoji: '✅',
        );
      }
    } catch (e) {
      print('❌ [SupportScreen] Erreur actualisation: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de l\'actualisation',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markMessageAsRead(int messageId) {
    print('📖 [SupportScreen] Marquage message $messageId comme lu');
    _chatService.markAsRead([messageId]);
  }

  void _markAllUnreadMessagesAsRead() {
    final unreadMessageIds = _messages
        .where((msg) =>
            !msg.isRead &&
            (msg.senderRole == 'admin' || msg.senderRole == 'technician'))
        .map((msg) => msg.id)
        .where((id) => id > 0)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
      print(
          '📖 [SupportScreen] Marquage ${unreadMessageIds.length} messages comme lus');
      _chatService.markAsRead(unreadMessageIds);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(text);
    _messageController.clear();
    _chatService.stopTyping();

    // Vérifier si c'est hors des heures de service
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final dayOfWeek = now.weekday; // 1 = lundi, 7 = dimanche

    // Définir les heures de service : Lundi-Vendredi 8h-17h30, Samedi 9h-12h
    bool isOutsideBusinessHours = false;

    if (dayOfWeek == 7) {
      // Dimanche - fermé toute la journée
      isOutsideBusinessHours = true;
    } else if (dayOfWeek == 6) {
      // Samedi - 9h à 12h
      if (currentHour < 9 || (currentHour >= 12)) {
        isOutsideBusinessHours = true;
      }
    } else {
      // Lundi à Vendredi - 8h à 17h30
      if (currentHour < 8 ||
          currentHour > 17 ||
          (currentHour == 17 && currentMinute > 30)) {
        isOutsideBusinessHours = true;
      }
    }

    // Envoyer un message automatique si hors des heures de service
    if (isOutsideBusinessHours) {
      await Future.delayed(const Duration(seconds: 2));

      // Créer un message automatique
      final autoReplyMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: 0,
        senderRole: 'system',
        senderName: 'Service Client',
        message:
            '🤖 Message automatique\n\nMerci pour votre message. Notre service client est actuellement fermé.\n\nNos horaires :\n📅 Lundi - Vendredi : 8h - 17h30\n📅 Samedi : 9h - 12h\n📅 Dimanche : Fermé\n\nNous vous répondrons dès notre retour. Pour les urgences, appelez le $supportPhone.',
        isRead: false,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(autoReplyMessage);
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri =
        Uri(scheme: 'tel', path: supportPhone.replaceAll(' ', ''));
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          SnackBarHelper.showError(
              context, 'Impossible de lancer l\'appel téléphonique');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de l\'appel: $e');
      }
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Demande de support&body=Bonjour,\n\n',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          SnackBarHelper.showError(
              context, 'Impossible d\'ouvrir le client email');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'envoi d\'email: $e');
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$supportWhatsApp?text=${Uri.encodeComponent('Bonjour, j\'ai besoin d\'assistance')}',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarHelper.showError(context,
              'Impossible d\'ouvrir WhatsApp. Assurez-vous que WhatsApp est installé.');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'ouverture de WhatsApp: $e');
      }
    }
  }

  Future<void> _openFacebookMessenger() async {
    final Uri messengerUri = Uri.parse(facebookMessengerUrl);
    try {
      if (await canLaunchUrl(messengerUri)) {
        await launchUrl(messengerUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Impossible d\'ouvrir Messenger');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'ouverture de Messenger: $e');
      }
    }
  }

  Future<void> _openInstagramDm() async {
    final Uri instagramUri = Uri.parse(instagramDmUrl);
    try {
      if (await canLaunchUrl(instagramUri)) {
        await launchUrl(instagramUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Impossible d\'ouvrir Instagram');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'ouverture d\'Instagram: $e');
      }
    }
  }

  // Fonction pour ouvrir LinkedIn
  Future<void> _openLinkedIn() async {
    final Uri linkedinUri = Uri.parse(linkedinUrl);
    try {
      if (await canLaunchUrl(linkedinUri)) {
        await launchUrl(linkedinUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Impossible d\'ouvrir LinkedIn');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'ouverture de LinkedIn: $e');
      }
    }
  }

  // Fonction pour ouvrir le site web
  Future<void> _openWebsite() async {
    final Uri websiteUri = Uri.parse(websiteUrl);
    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Impossible d\'ouvrir le site web');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de l\'ouverture du site web: $e');
      }
    }
  }

  // Afficher les options de réseaux sociaux dans un menu
  void _showSocialMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Suivez-nous sur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0a543d),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSocialMediaOption(
              icon: FontAwesomeIcons.facebookMessenger,
              label: 'Messenger',
              color: const Color(0xFF0084FF),
              onTap: () {
                Navigator.pop(context);
                _openFacebookMessenger();
              },
            ),
            _buildSocialMediaOption(
              icon: FontAwesomeIcons.instagram,
              label: 'Instagram',
              color: const Color(0xFFE4405F),
              onTap: () {
                Navigator.pop(context);
                _openInstagramDm();
              },
            ),
            _buildSocialMediaOption(
              icon: FontAwesomeIcons.linkedin,
              label: 'LinkedIn',
              color: const Color(0xFF0A66C2),
              onTap: () {
                Navigator.pop(context);
                _openLinkedIn();
              },
            ),
            _buildSocialMediaOption(
              icon: FontAwesomeIcons.globe,
              label: 'Site Web',
              color: const Color(0xFF0a543d),
              onTap: () {
                Navigator.pop(context);
                _openWebsite();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Widget pour une option de réseau social dans le menu
  Widget _buildSocialMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: FaIcon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requis par AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Support Client',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    _isConnected ? const Color(0xFF4CAF50) : Colors.grey[400],
                shape: BoxShape.circle,
                boxShadow: _isConnected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0a543d),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Actualiser',
            onPressed: _refreshMessages,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            tooltip: 'Vider le cache',
            onPressed: () async {
              // Supprimer l'historique du backend d'abord
              final deleted = await _chatService.deleteHistory();

              if (deleted) {
                // Ensuite vider le cache local
                await _chatService.clearCache();
                setState(() {
                  _messages.clear();
                });
                if (mounted) {
                  SnackBarHelper.showSuccess(
                    context,
                    'Conversation supprimée avec succès',
                    emoji: '🧹',
                  );
                }
              } else {
                if (mounted) {
                  SnackBarHelper.showError(
                    context,
                    'Erreur lors de la suppression de la conversation',
                  );
                }
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFF0a543d),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // 3 premiers boutons compacts en ligne
                _buildCompactContactButton(
                  icon: FontAwesomeIcons.phone,
                  onTap: _makePhoneCall,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _buildCompactContactButton(
                  icon: FontAwesomeIcons.envelope,
                  onTap: _sendEmail,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(width: 8),
                _buildCompactContactButton(
                  icon: FontAwesomeIcons.whatsapp,
                  onTap: _openWhatsApp,
                  color: const Color(0xFF25D366),
                ),
                const SizedBox(width: 12),
                // Bouton Réseaux avec texte
                Expanded(
                  child: _buildModernQuickContactButton(
                    icon: FontAwesomeIcons.shareNodes,
                    label: 'Réseaux',
                    onTap: _showSocialMediaOptions,
                    color: const Color(0xFF0a543d),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/call_center.png'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Column(
          children: [
            // Zone de messages avec fond dégradé subtil
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[50]!.withOpacity(0.3),
                      Colors.white.withOpacity(0.3),
                    ],
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0a543d),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0a543d)
                                                .withOpacity(0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 64,
                                            color: const Color(0xFF0a543d)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Aucun message',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0a543d),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Commencez une conversation',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final message = _messages[index];
                                      return _buildMessageBubble(message);
                                    },
                                  ),
                          ),
                          if (_typingUser != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_typingUser est en train d\'écrire...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              top: false,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: _isConnected
                                              ? 'Écrivez votre message...'
                                              : 'Connexion...',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 15,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 14,
                                          ),
                                        ),
                                        enabled: _isConnected,
                                        maxLines: null,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        style: const TextStyle(fontSize: 15),
                                        onChanged: (text) {
                                          if (text.isNotEmpty) {
                                            _chatService.startTyping();
                                          } else {
                                            _chatService.stopTyping();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: _isConnected
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF0a543d),
                                                Color(0xFF0d6b4d),
                                              ],
                                            )
                                          : null,
                                      color: _isConnected
                                          ? null
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: _isConnected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF0a543d)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            _isConnected ? _sendMessage : null,
                                        borderRadius: BorderRadius.circular(28),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: const Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton compact (icône seulement)
  Widget _buildCompactContactButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: FaIcon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Bouton avec label (pour Réseaux)
  Widget _buildModernQuickContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderRole == 'customer';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: const Icon(Icons.support_agent,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.senderName != null && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF0a543d) : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.message,
                          style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    isMe ? Colors.white70 : Colors.grey[600]),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? Colors.lightGreen[200]
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF0a543d),
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderRole;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderRole: json['sender_role'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
    };
  }
}
