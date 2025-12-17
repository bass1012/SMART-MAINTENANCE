import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../services/chat_service.dart';
import '../../config/environment.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isConnected = false;
  bool _isLoading = true;
  String? _typingUser;
  String? _userId;

  // Stocker les subscriptions pour les annuler dans dispose()
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le Timer dans ChatService gère maintenant la synchronisation automatique
    // Pas besoin d'appeler ensureConnected() ici
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Le Timer dans ChatService gère maintenant la synchronisation automatique
    // Pas besoin d'appeler ensureConnected() ici
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _typingSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    print('🎬 [ChatScreen] Initialisation du chat...');
    print(
        '🔍 [ChatScreen] État initial: _isConnected = $_isConnected, service.isConnected = ${_chatService.isConnected}');

    final prefs = await SharedPreferences.getInstance();

    // Charger les données utilisateur et extraire l'ID
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        _userId = userData['id']?.toString();
      } catch (e) {
        print('❌ Erreur lors du décodage des données utilisateur: $e');
      }
    }

    // Charger l'historique des messages
    await _loadChatHistory();

    print('🔌 [ChatScreen] Appel de ensureConnected()...');
    // Forcer la reconnexion si nécessaire (au cas où le socket serait déconnecté)
    await _chatService.ensureConnected();

    print(
        '✅ [ChatScreen] Après ensureConnected(): service.isConnected = ${_chatService.isConnected}');

    // Initialiser l'état de connexion immédiatement après
    setState(() {
      _isConnected = _chatService.isConnected;
      print('🎨 [ChatScreen] setState: _isConnected = $_isConnected');
    });

    // Écouter les nouveaux messages
    _messageSubscription = _chatService.messageStream.listen((data) {
      print(
          '📨 [ChatScreen] Nouveau message reçu via Socket.IO: ${data['message']}');
      final newMessage = ChatMessage.fromJson(data);
      // Vérifier si un message similaire n'existe pas déjà (éviter les doublons)
      // On compare par ID OU par contenu+sender+timestamp proche
      final exists = _messages.any((msg) {
        // Même ID de base de données
        if (msg.id == newMessage.id && newMessage.id > 0) return true;

        // Même contenu, même sender, et timestamp très proche (moins de 2 secondes)
        final timeDiff = msg.createdAt.difference(newMessage.createdAt).abs();
        return msg.message == newMessage.message &&
            msg.senderId == newMessage.senderId &&
            timeDiff.inSeconds < 2;
      });

      if (!exists) {
        print(
            '✅ [ChatScreen] Message ajouté à la liste (${_messages.length} -> ${_messages.length + 1})');
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      } else {
        print('⚠️ [ChatScreen] Message déjà existant, ignoré');
      }
    });

    // Écouter l'état de la connexion
    _connectionSubscription = _chatService.connectionStream.listen((connected) {
      // Mettre à jour l'état UI uniquement si différent
      if (_isConnected != connected) {
        setState(() {
          _isConnected = connected;
        });
      }
      // Ne pas recharger l'historique - c'est déjà fait au démarrage
    });

    // Écouter les indicateurs de frappe
    _typingSubscription = _chatService.typingStream.listen((data) {
      setState(() {
        if (data['isTyping'] == false) {
          _typingUser = null;
        } else {
          _typingUser = data['userName'] ?? 'Quelqu\'un';
        }
      });
    });

    // Écouter les mises à jour de lecture des messages
    _chatService.messagesReadStream.listen((messageIds) {
      print('📖 [ChatScreen] ${messageIds.length} messages marqués comme lus');
      setState(() {
        for (var id in messageIds) {
          final index = _messages.indexWhere((msg) => msg.id == id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: _messages[index].id,
              senderId: _messages[index].senderId,
              senderRole: _messages[index].senderRole,
              message: _messages[index].message,
              isRead: true, // Mettre à jour l'état de lecture
              createdAt: _messages[index].createdAt,
              senderName: _messages[index].senderName,
            );
          }
        }
      });
    });
  }

  Future<void> _loadChatHistory() async {
    print(
        '📜 [ChatScreen] Chargement de l\'historique... Messages actuels: ${_messages.length}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/chat/history?limit=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Le backend retourne data.data (liste des messages)
        final List<dynamic> messagesJson =
            (data['data'] ?? []) as List<dynamic>;

        print(
            '📜 [ChatScreen] Historique reçu: ${messagesJson.length} messages');

        setState(() {
          // Fusionner intelligemment : combiner historique et messages actuels
          final historyMessages =
              messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

          // Garder les messages actuels qui sont plus récents que le dernier message de l'historique
          final lastHistoryTimestamp = historyMessages.isNotEmpty
              ? historyMessages.last.createdAt
              : DateTime.fromMillisecondsSinceEpoch(0);

          print(
              '📜 [ChatScreen] Dernier timestamp historique: $lastHistoryTimestamp');

          // Messages récents non présents dans l'historique (envoyés après le chargement)
          final recentMessages = _messages.where((msg) {
            // Si le message est plus récent que le dernier de l'historique
            if (msg.createdAt.isAfter(lastHistoryTimestamp)) return true;
            // Ou si c'est un message optimiste (ID négatif)
            if (msg.id < 0) return true;
            return false;
          }).toList();

          print(
              '📜 [ChatScreen] Messages récents conservés: ${recentMessages.length}');

          // Combiner : historique + messages récents (éviter les doublons par ID)
          final allMessages = [...historyMessages];
          for (final recentMsg in recentMessages) {
            if (!allMessages
                .any((m) => m.id == recentMsg.id && recentMsg.id > 0)) {
              allMessages.add(recentMsg);
            }
          }

          print('📜 [ChatScreen] Total après fusion: ${allMessages.length}');

          _messages.clear();
          _messages.addAll(allMessages);
          _isLoading = false;
        });

        _scrollToBottom();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Envoyer au serveur - le message sera affiché via le stream quand confirmé
    _chatService.sendMessage(text);
    _messageController.clear();
    _chatService.stopTyping();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [ChatScreen.build] Le widget est reconstruit');

    // FORCER la synchronisation de l'état à chaque build
    final serviceConnected = _chatService.isConnected;
    if (serviceConnected != _isConnected) {
      // Utiliser addPostFrameCallback pour ne pas appeler setState pendant build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _chatService.isConnected != _isConnected) {
          setState(() {
            _isConnected = _chatService.isConnected;
            print('✅ [PostFrameCallback] État forcé à: $_isConnected');
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
        backgroundColor: Colors.blue,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'En ligne' : 'Hors ligne',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),

          // Indicateur de frappe
          if (_typingUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_typingUser est en train d\'écrire...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (text) {
                      if (text.isNotEmpty) {
                        _chatService.startTyping();
                      } else {
                        _chatService.stopTyping();
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez une conversation avec notre équipe',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId.toString() == _userId;
    final time = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text(
                message.senderName?.substring(0, 1).toUpperCase() ?? 'S',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && message.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? Colors.lightBlueAccent
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
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Modèle de données pour les messages
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
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderRole: json['sender_role'] ?? 'customer',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      senderName: json['sender']?['name'] ?? json['sender']?['username'],
    );
  }
}
