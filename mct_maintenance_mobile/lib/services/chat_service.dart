import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/config/environment.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  bool _lastEmittedConnectionState = false;
  ChatService._internal() {
    // Timer qui émet l'état de connexion uniquement quand il change
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (isConnected != _lastEmittedConnectionState) {
        _lastEmittedConnectionState = isConnected;
        _connectionController.add(isConnected);
      }
    });
  }

  IO.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _messagesReadController = StreamController<List<int>>.broadcast();
  Completer<void>? _connectionCompleter; // Pour attendre la connexion

  bool _isConnected = false;
  String? _userId;
  String? _token; // Stocker le token pour la ré-authentification

  // Cache des messages pour éviter de les perdre lors de la recréation du widget
  List<Map<String, dynamic>> _cachedMessages = [];
  static const String _cacheKey = 'chat_messages_cache';

  // Getter pour accéder aux messages en cache
  Future<List<Map<String, dynamic>>> get cachedMessages async {
    if (_cachedMessages.isEmpty) {
      // Charger depuis le stockage persistant si le cache mémoire est vide
      await _loadCacheFromStorage();
    }
    return List.from(_cachedMessages);
  }

  // Charger le cache depuis SharedPreferences
  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      if (cacheString != null) {
        final List<dynamic> decoded = jsonDecode(cacheString);
        _cachedMessages = decoded.cast<Map<String, dynamic>>();
        print(
            '💾 [ChatService] ${_cachedMessages.length} messages chargés depuis le stockage');
      }
    } catch (e) {
      print('❌ [ChatService] Erreur chargement cache: $e');
      _cachedMessages = [];
    }
  }

  // Sauvegarder le cache dans SharedPreferences
  Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = jsonEncode(_cachedMessages);
      await prefs.setString(_cacheKey, cacheString);
      print(
          '💾 [ChatService] ${_cachedMessages.length} messages sauvegardés dans le stockage');
    } catch (e) {
      print('❌ [ChatService] Erreur sauvegarde cache: $e');
    }
  }

  // Méthode pour ajouter un message au cache
  Future<void> addMessageToCache(Map<String, dynamic> message) async {
    _cachedMessages.add(message);
    await _saveCacheToStorage();
  }

  // Méthode pour remplacer tout le cache (lors du chargement de l'historique)
  Future<void> setCachedMessages(List<Map<String, dynamic>> messages) async {
    _cachedMessages = List.from(messages);
    await _saveCacheToStorage();
  }

  // Méthode pour vider le cache
  Future<void> clearCache() async {
    _cachedMessages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    print('🗑️ [ChatService] Cache vidé');
  }

  // Méthode pour supprimer l'historique de chat du backend
  Future<bool> deleteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [ChatService] Pas de token pour supprimer l\'historique');
        return false;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/chat/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ [ChatService] Historique supprimé du backend: ${data['deletedCount']} message(s)');
        return true;
      } else {
        print(
            '❌ [ChatService] Erreur suppression historique: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print(
          '❌ [ChatService] Exception lors de la suppression de l\'historique: $e');
      return false;
    }
  }

  // Streams pour écouter les événements
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<List<int>> get messagesReadStream => _messagesReadController.stream;

  // Retourner l'état RÉEL du socket, pas juste la variable interne
  bool get isConnected {
    final socketExists = _socket != null;
    final socketConnected = _socket?.connected ?? false;
    final result = socketExists && socketConnected;

    // Log détaillé pour debug
    if (!result) {
      print(
          '❌ [ChatService.isConnected] Socket null: ${!socketExists}, Socket déconnecté: ${socketExists && !socketConnected}');
    }

    return result;
  }

  Future<void> connect() async {
    print('🔵 Demande de connexion au chat...');

    // Si le socket existe et est connecté, juste notifier et synchroniser l'état
    if (_socket != null && _socket!.connected) {
      print('💬 Socket déjà connecté et fonctionnel');
      // Synchroniser l'état interne avec l'état réel du socket
      _isConnected = true;
      // IMPORTANT: Notifier les écouteurs que c'est connecté
      _connectionController.add(true);
      return;
    }

    // Nettoyer l'ancien socket s'il existe
    if (_socket != null) {
      print('🧹 Nettoyage de l\'ancien socket...');
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        print('⚠️ Erreur lors du nettoyage: $e');
      }
      _socket = null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Charger les données utilisateur et extraire l'ID
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        try {
          final userData = jsonDecode(userDataString);
          // Essayer différentes clés possibles pour l'ID utilisateur
          _userId = userData['id']?.toString() ??
              userData['user']?['id']?.toString() ??
              userData['data']?['user']?['id']?.toString();
          print('🔍 UserData keys: ${userData.keys.toList()}');
          print('🔍 UserId extrait: $_userId');
        } catch (e) {
          print('❌ Erreur lors du décodage des données utilisateur: $e');
        }
      }

      if (token == null || _userId == null) {
        print('❌ Pas de token ou user_id pour le chat');
        print('   Token: ${token != null ? "présent" : "absent"}');
        print('   UserId: ${_userId ?? "absent"}');
        return;
      }

      // Stocker le token pour la ré-authentification
      _token = token;

      // URL du serveur (utilise la configuration centralisée)
      final serverUrl = AppConfig.baseUrl;

      print('💬 Création du nouveau socket: $serverUrl');
      print('💬 Token disponible: ${token.substring(0, 20)}...');
      print('💬 User ID: $_userId');

      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 10, // Limiter à 10 tentatives
        'forceNew': true, // Toujours créer une nouvelle connexion
        'multiplex': false,
      });

      // Configurer les listeners sur le nouveau socket
      print('🔧 Configuration des listeners Socket.IO...');
      _setupSocketListeners();

      print('🔌 Connexion au serveur...');

      // Créer un Completer pour attendre la connexion
      _connectionCompleter = Completer<void>();

      _socket!.connect();

      // Attendre que la connexion soit établie (avec timeout de 5 secondes)
      await _connectionCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Timeout de connexion après 5 secondes');
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      print('✅ [connect] Connexion établie avec succès');
    } catch (e) {
      print('❌ Erreur connexion chat: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('✅ Chat connecté au serveur avec succès!');
      _isConnected = true;
      _connectionController.add(true);

      // Compléter le Future pour débloquer await dans connect()
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }

      // S'authentifier avec le token stocké
      print('💬 Envoi de l\'authentification...');
      _socket!.emit('chat:authenticate', {
        'token': _token,
        'userId': _userId,
      });
    });

    _socket!.onDisconnect((_) {
      print('⚠️ Chat déconnecté du serveur');
      _isConnected = false;
      _connectionController.add(false);

      // Tenter une reconnexion après un court délai
      Future.delayed(const Duration(seconds: 2), () {
        if (_socket != null && !_socket!.connected) {
          print('🔄 Tentative de reconnexion automatique...');
          _socket!.connect();
        }
      });
    });

    // Dans socket_io_client 3.x, onConnectError et onConnectTimeout sont remplacés par des événements
    _socket!.on('connect_error', (error) {
      print('❌ Erreur de connexion Socket.IO: $error');
    });

    _socket!.on('connect_timeout', (error) {
      print('⏱️ Timeout de connexion Socket.IO: $error');
    });

    _socket!.on('chat:authenticated', (data) {
      print('✅ Authentifié avec succès: ${data['message']}');
      // S'assurer que l'état connecté est bien diffusé après l'authentification
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.on('chat:new_message', (data) {
      print('💬 Nouveau message reçu: ${data['message']}');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:message_sent', (data) {
      print('✅ Confirmation d\'envoi du serveur: ${data['success']}');
      if (data['success'] == true && data['message'] != null) {
        print('✅ Message bien enregistré, ajout dans le stream');
        // Ajouter le message confirmé dans le stream pour l'afficher
        _messageController.add(Map<String, dynamic>.from(data['message']));
      }
    });

    _socket!.on('chat:error', (data) {
      print('❌ Erreur reçue du serveur: ${data['error']}');
    });

    _socket!.on('chat:user_typing', (data) {
      print('💬 ${data['userName']} est en train d\'écrire...');
      _typingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:user_stop_typing', (data) {
      print('💬 ${data['userName']} a arrêté d\'écrire');
      _typingController.add({
        ...Map<String, dynamic>.from(data),
        'isTyping': false,
      });
    });

    _socket!.on('chat:messages_read', (data) {
      print('📖 Messages marqués comme lus: ${data['messageIds']}');
      if (data['messageIds'] != null && data['messageIds'] is List) {
        final messageIds = List<int>.from(data['messageIds']);
        _messagesReadController.add(messageIds);
      }
    });

    _socket!.on('error', (error) {
      print('❌ Erreur Socket.IO: $error');
    });
  }

  void sendMessage(String message) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket non connecté, impossible d\'envoyer le message');
      return;
    }

    print(
        '📤 Envoi du message: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
    print('📤 Socket connecté: ${_socket!.connected}, User ID: $_userId');

    _socket!.emit('chat:send_message', {
      'message': message,
      'sender_role': 'customer',
    });

    print('✅ Événement chat:send_message émis');
  }

  void startTyping() {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('chat:typing');
  }

  void stopTyping() {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('chat:stop_typing');
  }

  void markAsRead(List<int> messageIds) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('chat:mark_read', {'messageIds': messageIds});
  }

  // Vérifier la connexion et reconnecter si nécessaire
  Future<void> ensureConnected() async {
    print(
        '🔍 Vérification état connexion: ${_socket?.connected ?? false}, _isConnected: $_isConnected');

    if (_socket == null || !_socket!.connected) {
      print('🔄 Reconnexion nécessaire...');
      await connect();
    } else {
      print('✅ Socket déjà connecté, synchronisation de l\'état...');
      // Le socket est connecté, s'assurer que l'état interne est synchronisé
      _isConnected = true;
      // Notifier tous les écouteurs de l'état actuel
      _connectionController.add(true);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _messagesReadController.close();
  }
}
