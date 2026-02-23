import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart' show AppConfig, ApiConfig;
import '../models/quote_contract_model.dart';
import '../models/contract_model.dart';
import '../models/maintenance_report_model.dart';
import '../models/complaint_model.dart';
import '../models/maintenance_offer_model.dart';
import 'local_cache_service.dart';
import 'connectivity_service.dart';

class ApiService {
  // Instance unique
  static final ApiService _instance = ApiService._internal();

  // Client HTTP personnalisé
  late final http.Client _client;

  // Token d'authentification
  String? _authToken;
  String? _accessToken;

  // Services pour mode offline
  final LocalCacheService _cacheService = LocalCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Clés pour SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Constructeur privé
  ApiService._internal() {
    final httpClient = HttpClient()
      ..connectionTimeout = ApiConfig.timeout
      ..badCertificateCallback =
          (cert, host, port) => true; // Pour le développement seulement
    _client = IOClient(httpClient);
  }

  // Getter pour l'instance unique
  factory ApiService() => _instance;

  // Mettre à jour le token et le sauvegarder
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
    if (ApiConfig.debugLogs) {
      debugPrint(
          '🔑 Token updated: ${token != null ? '${token.substring(0, 10)}...' : 'null'}');
    }
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  // Charger le token sauvegardé
  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    if (_authToken != null && ApiConfig.debugLogs) {
      debugPrint('🔑 Token chargé depuis le stockage');
    }
  }

  // Sauvegarder les données utilisateur
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Charger les données utilisateur
  Future<Map<String, dynamic>?> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Alias pour getUserData
  Future<Map<String, dynamic>?> getUserData() async {
    return await loadUserData();
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    await loadSavedToken();
    return _authToken != null;
  }

  // Obtenir les en-têtes avec le token si disponible
  Map<String, String> get _headers {
    final headers = {
      ...ApiConfig.defaultHeaders,
      // Note: Les headers CORS ne doivent pas être envoyés par le client
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
      // Token masqué pour sécurité - ne jamais logger le token complet
      debugPrint('📤 Authorization header: Bearer ***TOKEN_PRESENT***');
    }
    if (ApiConfig.debugLogs) {
      // Copie des headers sans le token pour le log
      final safeHeaders = Map<String, String>.from(headers);
      if (safeHeaders.containsKey('Authorization')) {
        safeHeaders['Authorization'] = 'Bearer ***REDACTED***';
      }
      debugPrint('📤 Sending headers: $safeHeaders');
    }
    return headers;
  }

  /// Getter public pour les headers avec authentification
  Map<String, String> get headers => _headers;

  Map<String, String> get _authHeaders {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // URL de base de l'API
  String get baseUrl => AppConfig.baseUrl;

  // Méthode générique pour les requêtes HTTP
  Future<http.Response> _request(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Nettoyer l'endpoint pour éviter les doubles slashes
      final cleanEndpoint =
          endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = '$baseUrl/$cleanEndpoint';

      final uri = Uri.parse(url).replace(
        queryParameters: queryParams,
      );

      if (ApiConfig.debugLogs) {
        debugPrint('🔵 API Request: $method $uri');
        if (body != null) debugPrint('📦 Request Body: $body');
        debugPrint('📋 Headers: $headers');
      }

      final request = http.Request(method, uri);

      // Fusionner les en-têtes de base avec les en-têtes spécifiques à la requête
      final mergedHeaders = Map<String, String>.from(_headers);
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }

      request.headers.addAll(mergedHeaders);

      if (body != null) {
        request.body =
            body is Map || body is List ? jsonEncode(body) : body.toString();

        // S'assurer que le Content-Type est défini pour les requêtes avec corps
        if (!request.headers.containsKey('Content-Type')) {
          request.headers['Content-Type'] = 'application/json';
        }
      }

      final streamedResponse =
          await _client.send(request).timeout(ApiConfig.timeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (ApiConfig.debugLogs) {
        debugPrint(
            '🟢 API Response (${streamedResponse.statusCode}): $responseBody');
      }

      return http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: streamedResponse.request,
      );
    } on SocketException catch (e) {
      final error =
          'Erreur de connexion: ${e.message}. Vérifiez votre connexion Internet et que le serveur est en cours d\'exécution.';
      if (ApiConfig.debugLogs) debugPrint('🔴 $error');
      throw Exception(error);
    } on TimeoutException {
      const error =
          'Le serveur ne répond pas dans le délai imparti. Vérifiez votre connexion Internet.';
      if (ApiConfig.debugLogs) debugPrint('🔴 $error');
      throw TimeoutException(error);
    } catch (e) {
      final error = 'Erreur inattendue lors de la requête: $e';
      if (ApiConfig.debugLogs) debugPrint('🔴 $error');
      throw Exception(error);
    }
  }

  // ==================== AUTHENTIFICATION ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _handleRequest(
        'POST',
        AppConfig.loginUrl.replaceFirst(AppConfig.baseUrl, ''),
        body: {'email': email.trim(), 'password': password},
        skipAuth: true, // Ne pas inclure le token pour la connexion
      );

      // Stocker le token si présent dans la réponse
      String? token;
      if (response['accessToken'] != null) {
        token = response['accessToken'];
      } else if (response['data']?['accessToken'] != null) {
        token = response['data']['accessToken'];
      } else if (response['token'] != null) {
        token = response['token'];
      } else if (response['data']?['token'] != null) {
        token = response['data']['token'];
      } else if (response['access_token'] != null) {
        token = response['access_token'];
      }

      if (token != null) {
        await setAuthToken(token);
        setAccessToken(token);

        // Sauvegarder les données utilisateur
        if (response['data']?['user'] != null) {
          await saveUserData(response['data']['user']);
        }
      }

      if (ApiConfig.debugLogs) {
        debugPrint(
            '✅ Connexion réussie, token: ${_authToken != null ? '${_authToken!.substring(0, 10)}...' : 'non reçu'}');
      }

      return response;
    } catch (e) {
      if (ApiConfig.debugLogs) {
        debugPrint('❌ Erreur de connexion: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return _handleRequest(
      'POST',
      AppConfig.registerUrl.replaceFirst(AppConfig.baseUrl, ''),
      body: userData,
      successMessage: 'Inscription réussie',
    );
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _handleRequest(
        'POST',
        '/api/auth/forgot-password',
        body: {'email': email.trim()},
        skipAuth: true,
      );

      if (ApiConfig.debugLogs) {
        debugPrint('✅ Email de réinitialisation envoyé à $email');
      }

      return response;
    } catch (e) {
      if (ApiConfig.debugLogs) {
        debugPrint('❌ Erreur forgot password: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _handleRequest(
      'GET',
      AppConfig.profileUrl.replaceFirst(AppConfig.baseUrl, ''),
      successMessage: 'Profil récupéré avec succès',
    );
  }

  /// Demander un code de réinitialisation
  Future<Map<String, dynamic>> requestResetCode(String email) async {
    return await _handleRequest(
      'POST',
      '/api/auth/request-reset-code',
      body: {'email': email.trim()},
      skipAuth: true,
    );
  }

  /// Vérifier uniquement le code (sans changer le mot de passe)
  Future<Map<String, dynamic>> checkResetCode(String email, String code) async {
    return await _handleRequest(
      'POST',
      '/api/auth/check-reset-code',
      body: {
        'email': email.trim(),
        'code': code.trim(),
      },
      skipAuth: true,
    );
  }

  /// Vérifier le code et changer le mot de passe
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code, String newPassword) async {
    return await _handleRequest(
      'POST',
      '/api/auth/verify-reset-code',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword.trim(),
      },
      skipAuth: true,
    );
  }

  // ==================== DEVIS ET CONTRATS ====================

  Future<Map<String, dynamic>> getQuotes() async {
    return await _handleRequest(
      'GET',
      '/api/customer/quotes',
      successMessage: 'Devis récupérés avec succès',
    );
  }

  Future<List<QuoteContract>> getCustomerQuotes() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/quotes',
      successMessage: 'Devis récupérés avec succès',
    );

    return (response['data'] as List)
        .map((item) => QuoteContract.fromJson(item))
        .toList();
  }

  Future<QuoteContract> getQuoteDetails(String quoteId) async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/quotes/$quoteId',
      successMessage: 'Détails du devis récupérés',
    );

    return QuoteContract.fromJson(response['data']);
  }

  Future<void> acceptQuote(
    String quoteId, {
    DateTime? scheduledDate,
    bool executeNow = false,
    String? secondContact,
  }) async {
    await _handleRequest(
      'POST',
      '/api/customer/quotes/$quoteId/accept',
      body: {
        'execute_now': executeNow,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate.toIso8601String(),
        if (secondContact != null) 'second_contact': secondContact,
      },
      successMessage: 'Devis accepté avec succès',
    );
  }

  Future<QuoteContract> rejectQuote(String quoteId, String reason) async {
    final response = await _handleRequest(
      'POST',
      '/api/customer/quotes/$quoteId/reject',
      body: {'reason': reason},
      successMessage: 'Devis refusé',
    );
    return QuoteContract.fromJson(response['data']);
  }

  // ==================== RAPPORTS DE MAINTENANCE ====================

  Future<List<MaintenanceReport>> getMaintenanceReports() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/maintenance-reports',
      successMessage: 'Rapports de maintenance récupérés',
    );

    return (response['data'] as List)
        .map((item) => MaintenanceReport.fromJson(item))
        .toList();
  }

  Future<MaintenanceReport> getMaintenanceReportDetails(String reportId) async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/maintenance-reports/$reportId',
      successMessage: 'Détails du rapport récupérés',
    );

    return MaintenanceReport.fromJson(response['data']);
  }

  // ==================== RÉCLAMATIONS ====================

  Future<List<Complaint>> getCustomerComplaints() async {
    print('🔍 Fetching customer complaints...');

    final response = await _handleRequest(
      'GET',
      '/api/customer/complaints',
      successMessage: 'Réclamations récupérées',
    );

    print('📥 Response: $response');
    print('📥 Response data type: ${response['data'].runtimeType}');
    print('📥 Response data: ${response['data']}');

    if (response['data'] is! List) {
      print('❌ Data is not a List, it is: ${response['data'].runtimeType}');
      return [];
    }

    final complaints = (response['data'] as List).map((item) {
      print('📄 Parsing complaint item: $item');
      return Complaint.fromJson(item);
    }).toList();

    print('✅ Parsed ${complaints.length} complaints');
    return complaints;
  }

  Future<Complaint> createComplaint(Complaint complaint) async {
    print('📤 Creating complaint: ${complaint.toJson()}');

    final response = await _handleRequest(
      'POST',
      '/api/customer/complaints',
      body: complaint.toJson(),
      successMessage: 'Réclamation créée avec succès',
    );

    print('📥 Response data: ${response['data']}');

    if (response['data'] == null) {
      throw Exception('La réponse du serveur ne contient pas de données');
    }

    return Complaint.fromJson(response['data']);
  }

  Future<Complaint> getComplaintDetails(String complaintId) async {
    print('🔍 Fetching complaint details for ID: $complaintId');

    final response = await _handleRequest(
      'GET',
      '/api/customer/complaints/$complaintId',
      successMessage: 'Détails récupérés',
    );

    print('📥 Complaint details: ${response['data']}');

    if (response['data'] == null) {
      throw Exception('La réponse du serveur ne contient pas de données');
    }

    return Complaint.fromJson(response['data']);
  }

  // ==================== OFFRES D'ENTRETIEN ====================

  Future<List<MaintenanceOffer>> getMaintenanceOffers() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/maintenance-offers',
      successMessage: 'Offres d\'entretien récupérées',
    );

    return (response['data'] as List)
        .map((item) => MaintenanceOffer.fromJson(item))
        .toList();
  }

  Future<MaintenanceOffer> getMaintenanceOfferDetails(String offerId) async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/maintenance-offers/$offerId',
      successMessage: 'Détails de l\'offre récupérés',
    );

    return MaintenanceOffer.fromJson(response['data']);
  }

  // ==================== SOUSCRIPTIONS ====================

  Future<Map<String, dynamic>> createSubscription(
      int maintenanceOfferId) async {
    final response = await _handleRequest(
      'POST',
      '/api/customer/subscriptions',
      body: {'maintenance_offer_id': maintenanceOfferId},
      successMessage: 'Souscription créée avec succès',
    );

    return response['data'];
  }

  Future<Map<String, dynamic>> createServiceSubscription({
    required int serviceId,
    required String serviceType, // 'installation' ou 'repair'
  }) async {
    final body = serviceType == 'installation'
        ? {'installation_service_id': serviceId}
        : {'repair_service_id': serviceId};

    final response = await _handleRequest(
      'POST',
      '/api/customer/subscriptions',
      body: body,
      successMessage: 'Souscription créée avec succès',
    );

    return response['data'];
  }

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/subscriptions',
      successMessage: 'Souscriptions récupérées',
    );

    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Récupérer les souscriptions avec paiement en attente
  Future<List<Map<String, dynamic>>> getPendingSubscriptionPayments() async {
    final subscriptions = await getSubscriptions();
    // Filtrer les souscriptions avec payment_status = 'pending' et status = 'active'
    return subscriptions
        .where(
            (s) => s['payment_status'] == 'pending' && s['status'] == 'active')
        .toList();
  }

  Future<Map<String, dynamic>> getSubscriptionDetails(
      int subscriptionId) async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/subscriptions/$subscriptionId',
      successMessage: 'Détails de la souscription récupérés',
    );

    return response['data'];
  }

  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    final response = await _handleRequest(
      'PATCH',
      '/api/customer/subscriptions/$subscriptionId/cancel',
      successMessage: 'Souscription annulée avec succès',
    );

    return response['data'];
  }

  // ==================== MÉTHODE GÉNÉRIQUE POUR LES REQUÊTES ====================

  Future<Map<String, dynamic>> _handleRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams = const {},
    String? successMessage,
    bool skipAuth = false,
  }) async {
    // Utiliser les en-têtes avec ou sans authentification selon le paramètre
    final headers = skipAuth
        ? {
            ...ApiConfig.defaultHeaders,
            ...ApiConfig.corsHeaders,
          }
        : _authHeaders; // Utiliser _authHeaders au lieu de _headers

    if (ApiConfig.debugLogs) {
      debugPrint('🔐 Auth headers: $headers');
    }

    try {
      final response = await _request(
        method,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (ApiConfig.debugLogs && successMessage != null) {
          debugPrint('✅ $successMessage');
        }
        return responseBody;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        debugPrint('🔴 Token invalide ou expiré - Status 401');
        final errorMessage =
            responseBody['message'] ?? 'Token invalide ou expiré';
        throw Exception('AUTH_ERROR: $errorMessage');
      } else {
        final errorMessage = responseBody['message'] ?? 'Erreur inconnue';
        debugPrint('🔴 Erreur ${response.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Erreur de connexion au serveur');
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé');
    } on FormatException {
      throw Exception('Format de réponse invalide');
    } catch (e) {
      rethrow;
    }
  }

  // Méthode pour mettre à jour le token d'authentification
  void updateAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Méthode pour mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await _handleRequest(
      'PUT',
      '/api/auth/profile',
      body: data,
    );
  }

  // Méthode pour uploader l'avatar
  Future<String> uploadAvatar(String imagePath) async {
    try {
      // Charger le token si nécessaire
      if (_authToken == null) {
        await loadSavedToken();
      }

      if (_authToken == null) {
        throw Exception('Non authentifié');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/upload/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $_authToken';

      // Déterminer le type MIME en fonction de l'extension
      String? mimeType;
      final extension = imagePath.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Par défaut
      }

      if (ApiConfig.debugLogs) {
        debugPrint('📤 Upload avatar: $imagePath');
        debugPrint('📤 Extension: $extension, MIME type: $mimeType');
      }

      // Ajouter le fichier avec le type MIME explicite
      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        imagePath,
        contentType: http_parser.MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (ApiConfig.debugLogs) {
        debugPrint('📥 Upload response: ${response.statusCode}');
        debugPrint('📥 Upload body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Le backend retourne soit data.data, soit directement les données
        String? filename;

        if (data['data'] != null) {
          filename = data['data']['avatar'] ?? data['data']['image'];
        } else {
          // Récupérer le nom du fichier depuis 'avatar' ou extraire depuis 'url'
          filename = data['avatar'];
          if (filename == null && data['url'] != null) {
            // Extraire le nom du fichier depuis l'URL
            // Ex: "/uploads/avatars/avatar-15-123456.jpg" -> "avatar-15-123456.jpg"
            filename = (data['url'] as String).split('/').last;
          }
        }

        if (ApiConfig.debugLogs) {
          debugPrint('📥 Filename extrait: $filename');
        }

        return filename ?? '';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'upload');
      }
    } catch (e) {
      debugPrint('❌ Erreur upload avatar: $e');
      throw Exception('Erreur lors de l\'upload de l\'image');
    }
  }

  // Méthode pour changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _handleRequest(
      'POST',
      '/api/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // Méthode pour supprimer son propre compte (soft delete)
  Future<Map<String, dynamic>> deleteMyAccount() async {
    return await _handleRequest(
      'DELETE',
      '/api/auth/delete-account',
    );
  }

  // Méthode pour récupérer les statistiques du tableau de bord
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _handleRequest(
      'GET',
      '/api/customer/dashboard/stats',
    );
  }

  // Méthode pour récupérer les interventions récentes
  Future<List<dynamic>> getRecentInterventions({int limit = 5}) async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/interventions',
      queryParams: {'limit': limit.toString(), 'sort': 'desc'},
    );
    return response['data'] ?? [];
  }

  // Méthode pour récupérer tous les contrats
  Future<List<Contract>> getCustomerContracts() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/contracts',
    );

    return (response['data'] as List)
        .map((item) => Contract.fromJson(item))
        .toList();
  }

  // Méthode pour récupérer les contrats actifs
  Future<List<Contract>> getActiveContracts() async {
    final response = await _handleRequest(
      'GET',
      '/api/customer/contracts',
      queryParams: {'status': 'active'},
    );

    return (response['data'] as List)
        .map((item) => Contract.fromJson(item))
        .toList();
  }

  // Méthode pour demander le renouvellement d'un contrat
  Future<Map<String, dynamic>> requestContractRenewal(int contractId) async {
    final response = await _handleRequest(
      'POST',
      '/api/customer/contracts/$contractId/request-renewal',
    );

    return response;
  }

  // Méthode générique GET
  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    return await _handleRequest(
      'GET',
      '/api$endpoint',
      queryParams: queryParams,
    );
  }

  // Méthode générique POST
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    return await _handleRequest(
      'POST',
      '/api$endpoint',
      body: data,
    );
  }

  // Méthode pour récupérer les produits
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    int? brandId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }

    if (brandId != null) {
      queryParams['brandId'] = brandId.toString();
    }

    return await _handleRequest(
      'GET',
      '/api/products',
      queryParams: queryParams,
    );
  }

  // Méthode pour récupérer un produit par ID
  Future<Map<String, dynamic>> getProductById(String productId) async {
    return await _handleRequest(
      'GET',
      '/api/products/$productId',
    );
  }

  // Méthode pour récupérer les commandes du client
  Future<Map<String, dynamic>> getOrders() async {
    return await _handleRequest(
      'GET',
      '/api/orders',
    );
  }

  // Méthode pour récupérer les détails d'une commande
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await _handleRequest(
        'GET',
        '/api/customer/orders/$orderId',
        successMessage: 'Commande récupérée',
      );
      return response['data'];
    } catch (e) {
      debugPrint('❌ Erreur récupération commande: $e');
      rethrow;
    }
  }

  // Méthode pour récupérer les factures (invoices)
  Future<Map<String, dynamic>> getInvoices() async {
    return await _handleRequest(
      'GET',
      '/api/orders', // Les factures sont liées aux commandes
    );
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    try {
      await _request('POST', '/api/auth/logout');
    } finally {
      _authToken = null;
      _accessToken = null;

      // Supprimer les données sauvegardées
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);

      if (ApiConfig.debugLogs) {
        debugPrint('🔓 Déconnexion et suppression des données sauvegardées');
      }
    }
  }

  // Traiter un paiement (ancien système)
  Future<Map<String, dynamic>> processPayment(
      Map<String, dynamic> paymentData) async {
    return await _handleRequest(
      'POST',
      '/api/payments/initiate',
      body: paymentData,
      successMessage: 'Paiement traité avec succès',
    );
  }

  // Initialiser un paiement FineoPay
  Future<Map<String, dynamic>> initializeFineoPay(int orderId) async {
    return await _handleRequest(
      'POST',
      '/api/payments/fineopay/initialize',
      body: {'orderId': orderId},
      successMessage: 'Paiement FineoPay initialisé',
    );
  }

  // Vérifier le statut d'un paiement FineoPay
  Future<Map<String, dynamic>> checkFineoPayStatus(String reference) async {
    return await _handleRequest(
      'GET',
      '/api/payments/fineopay/status/$reference',
      successMessage: 'Statut vérifié',
    );
  }

  // Traiter un paiement de souscription
  Future<Map<String, dynamic>> processSubscriptionPayment(
      Map<String, dynamic> paymentData) async {
    return await _handleRequest(
      'POST',
      '/api/payments/subscription/initiate',
      body: paymentData,
      successMessage: 'Paiement de souscription traité avec succès',
    );
  }

  // ==================== NOTIFICATIONS FCM ====================

  /// Mettre à jour le token FCM de l'utilisateur
  Future<void> updateFcmToken(String fcmToken) async {
    print('📤 Envoi du token FCM au backend...');

    await _handleRequest(
      'POST',
      '/api/auth/fcm-token',
      body: {'fcm_token': fcmToken},
      successMessage: 'Token FCM enregistré',
    );
  }

  // Créer une demande d'intervention
  Future<Map<String, dynamic>> createIntervention(
      Map<String, dynamic> interventionData) async {
    return await _handleRequest(
      'POST',
      '/api/interventions',
      body: interventionData,
      successMessage: 'Demande d\'intervention créée avec succès',
    );
  }

  // OPTION 1: Créer intervention avec images (Multipart/Form-Data) - RECOMMANDÉ
  Future<Map<String, dynamic>> createInterventionWithImages({
    required Map<String, dynamic> data,
    List<File>? images,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/interventions');

      var request = http.MultipartRequest('POST', url);

      // Headers avec authentification
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.headers['Accept'] = 'application/json';

      // Ajouter les données texte
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Ajouter les images si présentes
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final mimeType = file.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';

          request.files.add(
            await http.MultipartFile.fromPath(
              'images', // Nom du champ pour array côté backend
              file.path,
              contentType: http_parser.MediaType.parse(mimeType),
            ),
          );
        }
        debugPrint('📤 [API] Envoi de ${images.length} image(s)');
      }

      debugPrint('📤 [API] POST ${url.path} (multipart)');

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [API] Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        debugPrint('✅ [API] Intervention créée avec succès');
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      debugPrint('❌ [API] Erreur: $e');
      rethrow;
    }
  }

  // OPTION 2: Créer intervention avec images Base64 (Alternative)
  Future<Map<String, dynamic>> createInterventionWithImagesBase64({
    required Map<String, dynamic> data,
    List<File>? images,
  }) async {
    try {
      // Convertir les images en Base64 si présentes
      if (images != null && images.isNotEmpty) {
        List<Map<String, String>> imagesBase64 = [];

        for (var image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = image.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';

          imagesBase64.add({
            'data': base64Image,
            'mimeType': mimeType,
          });
        }

        data['images_base64'] = imagesBase64;
        debugPrint('📤 [API] Envoi de ${images.length} image(s) en Base64');
      }

      // Utiliser la méthode classique avec les images encodées
      return await _handleRequest(
        'POST',
        '/api/interventions',
        body: data,
        successMessage: 'Demande d\'intervention créée avec succès',
      );
    } catch (e) {
      debugPrint('❌ [API] Erreur Base64: $e');
      rethrow;
    }
  }

  // Récupérer les interventions d'un client
  Future<Map<String, dynamic>> getInterventions(
      {int? customerId, String? status}) async {
    final queryParams = <String, String>{};
    if (customerId != null) queryParams['customer_id'] = customerId.toString();
    if (status != null) queryParams['status'] = status;

    return await _handleRequest(
      'GET',
      '/api/interventions',
      queryParams: queryParams,
      successMessage: 'Interventions récupérées',
    );
  }

  // Récupérer une intervention par ID
  Future<Map<String, dynamic>> getInterventionById(int interventionId) async {
    return await _handleRequest(
      'GET',
      '/api/interventions/$interventionId',
      successMessage: 'Détails de l\'intervention récupérés',
    );
  }

  // Annuler une intervention (customer)
  Future<Map<String, dynamic>> cancelIntervention(int interventionId) async {
    return await _handleRequest(
      'PUT',
      '/api/interventions/$interventionId',
      body: {
        'status': 'cancelled',
      },
      successMessage: 'Intervention annulée avec succès',
    );
  }

  // Noter une intervention (customer rating)
  Future<Map<String, dynamic>> rateIntervention(
    int interventionId,
    int rating,
    String review,
  ) async {
    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/rate',
      body: {
        'rating': rating,
        'review': review,
      },
      successMessage: 'Évaluation enregistrée',
    );
  }

  // Récupérer les interventions terminées non notées
  Future<List<Map<String, dynamic>>> getUnratedInterventions() async {
    print('🔍 Appel API getUnratedInterventions...');
    try {
      final response = await _handleRequest(
        'GET',
        '/api/interventions/unrated',
      );
      print(
          '✅ Réponse API unrated: ${response['data']?.length ?? 0} interventions');
      print('📊 Données: ${response['data']}');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('❌ Erreur getUnratedInterventions: $e');
      rethrow;
    }
  }

  // Récupérer les interventions avec diagnostic non payé
  Future<List<Map<String, dynamic>>> getPendingDiagnosticPayments() async {
    print('🔍 Appel API getPendingDiagnosticPayments...');
    try {
      final response = await _handleRequest(
        'GET',
        '/api/interventions/pending-diagnostic-payment',
      );
      print(
          '💳 Réponse API pending-diagnostic: ${response['data']?.length ?? 0} interventions');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('❌ Erreur getPendingDiagnosticPayments: $e');
      rethrow;
    }
  }

  // Télécharger la facture PDF d'une commande
  Future<List<int>> downloadInvoicePDF(int orderId) async {
    try {
      if (ApiConfig.debugLogs) {
        debugPrint('📄 Téléchargement de la facture pour la commande $orderId');
      }

      final token = _authToken ?? _accessToken;
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final url = Uri.parse(
          '${AppConfig.baseUrl}/api/payments/invoice/$orderId/download');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      ).timeout(const Duration(seconds: 30));

      if (ApiConfig.debugLogs) {
        debugPrint('📄 Réponse: ${response.statusCode}');
        debugPrint('📊 Taille du PDF: ${response.bodyBytes.length} bytes');
      }

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        // Essayer d'extraire le message d'erreur du serveur
        String errorMessage =
            'Erreur lors du téléchargement: ${response.statusCode}';
        try {
          final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
          if (jsonResponse['message'] != null) {
            errorMessage = jsonResponse['message'];
          }
        } catch (_) {
          // Si le parsing échoue, garder le message par défaut
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ApiConfig.debugLogs) {
        debugPrint('❌ Erreur téléchargement facture: $e');
      }
      rethrow;
    }
  }

  // ==================== TECHNICIEN ====================

  // Récupérer les statistiques du technicien
  Future<Map<String, dynamic>> getTechnicianStats() async {
    return await _handleRequest(
      'GET',
      '/api/technician/dashboard/stats',
      successMessage: 'Statistiques technicien récupérées',
    );
  }

  // Mettre à jour la disponibilité du technicien
  Future<Map<String, dynamic>> updateTechnicianAvailability(
      String status) async {
    return await _handleRequest(
      'PUT',
      '/api/technician/availability',
      body: {'availability_status': status},
      successMessage: 'Disponibilité mise à jour',
    );
  }

  // Mettre à jour les horaires de travail
  Future<Map<String, dynamic>> updateWorkingHours(
      Map<String, dynamic> workingHours) async {
    return await _handleRequest(
      'PATCH',
      '/api/technician/working-hours',
      body: {'working_hours': workingHours},
      successMessage: 'Horaires mis à jour',
    );
  }

  // Récupérer les interventions du technicien
  Future<Map<String, dynamic>> getTechnicianInterventions(
      {String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    // Vérifier si en ligne
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Lecture depuis cache local');
      final cachedInterventions = await _cacheService.getCachedInterventions();

      // Filtrer par statut si nécessaire (les données sont déjà décodées)
      List<Map<String, dynamic>> filteredData = cachedInterventions;
      if (status != null) {
        filteredData = cachedInterventions
            .where((intervention) {
              // Vérifier que l'intervention n'est pas null et contient le champ status
              if (intervention == null) return false;
              final interventionStatus = intervention['status'];
              return interventionStatus != null && interventionStatus == status;
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return {
        'success': true,
        'data': filteredData,
        'message':
            'Interventions chargées depuis le cache (${filteredData.length})',
        'fromCache': true,
      };
    }

    try {
      // Appel API normal si en ligne
      final response = await _handleRequest(
        'GET',
        '/api/technician/interventions',
        queryParams: queryParams,
        successMessage: 'Interventions récupérées',
      );

      // Mettre en cache si succès
      if (response['success'] == true && response['data'] != null) {
        final interventions = response['data'] as List;
        debugPrint('💾 Mise en cache de ${interventions.length} interventions');

        // Nettoyer le cache existant avant de le remplir
        for (var intervention in interventions) {
          await _cacheService.cacheIntervention(intervention);
        }
      }

      return response;
    } catch (e) {
      // En cas d'erreur réseau, fallback sur le cache
      debugPrint('⚠️ Erreur API, fallback cache: $e');
      final cachedInterventions = await _cacheService.getCachedInterventions();

      if (cachedInterventions.isEmpty) {
        rethrow; // Si pas de cache, propager l'erreur
      }

      // Filtrer par statut si nécessaire (les données sont déjà décodées)
      List<Map<String, dynamic>> filteredData = cachedInterventions;
      if (status != null) {
        filteredData = cachedInterventions
            .where((intervention) {
              // Vérifier que l'intervention n'est pas null et contient le champ status
              if (intervention == null) return false;
              final interventionStatus = intervention['status'];
              return interventionStatus != null && interventionStatus == status;
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return {
        'success': true,
        'data': filteredData,
        'message': 'Interventions chargées depuis le cache (mode dégradé)',
        'fromCache': true,
      };
    }
  }

  // Accepter une intervention
  Future<Map<String, dynamic>> acceptIntervention(int interventionId) async {
    // Si offline, ajouter à la queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout acceptation à la queue');

      // Mettre à jour le cache local
      await _cacheService.updateCachedIntervention(
        interventionId,
        {'status': 'accepted'},
      );

      await _cacheService.addToSyncQueue(
        'intervention_status',
        interventionId,
        {'status': 'accepted', 'action': 'accept'},
      );
      return {
        'success': true,
        'message': 'Acceptation enregistrée (sera synchronisée)',
        'queued': true,
      };
    }

    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/accept',
      successMessage: 'Intervention acceptée',
    );
  }

  // Signaler "En route"
  Future<Map<String, dynamic>> markInterventionOnTheWay(
      int interventionId) async {
    // Si offline, ajouter à la queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout "En route" à la queue');

      // Mettre à jour le cache local
      await _cacheService.updateCachedIntervention(
        interventionId,
        {'status': 'on_the_way'},
      );

      await _cacheService.addToSyncQueue(
        'intervention_status',
        interventionId,
        {'status': 'on_the_way', 'action': 'on-the-way'},
      );
      return {
        'success': true,
        'message': 'Statut "En route" enregistré (sera synchronisé)',
        'queued': true,
      };
    }

    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/on-the-way',
      successMessage: 'Statut mis à jour: En route',
    );
  }

  // Signaler "Arrivé sur les lieux"
  Future<Map<String, dynamic>> markInterventionArrived(
      int interventionId) async {
    // Si offline, ajouter à la queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout "Arrivé" à la queue');

      // Mettre à jour le cache local
      await _cacheService.updateCachedIntervention(
        interventionId,
        {'status': 'arrived'},
      );
      await _cacheService.addToSyncQueue(
        'intervention_status',
        interventionId,
        {'status': 'arrived', 'action': 'arrived'},
      );
      return {
        'success': true,
        'message': 'Statut "Arrivé" enregistré (sera synchronisé)',
        'queued': true,
      };
    }

    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/arrived',
      successMessage: 'Statut mis à jour: Arrivé',
    );
  }

  // Démarrer l'intervention
  Future<Map<String, dynamic>> startIntervention(int interventionId) async {
    // Si offline, ajouter à la queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout "Démarrer" à la queue');

      // Mettre à jour le cache local
      await _cacheService.updateCachedIntervention(
        interventionId,
        {'status': 'in_progress'},
      );

      await _cacheService.addToSyncQueue(
        'intervention_status',
        interventionId,
        {'status': 'in_progress', 'action': 'start'},
      );
      return {
        'success': true,
        'message': 'Démarrage enregistré (sera synchronisé)',
        'queued': true,
      };
    }

    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/start',
      successMessage: 'Intervention démarrée',
    );
  }

  // Terminer une intervention
  Future<Map<String, dynamic>> completeIntervention(int interventionId) async {
    // Si offline, ajouter à la queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout "Terminer" à la queue');

      // Mettre à jour le cache local
      await _cacheService.updateCachedIntervention(
        interventionId,
        {'status': 'completed'},
      );

      await _cacheService.addToSyncQueue(
        'intervention_status',
        interventionId,
        {'status': 'completed', 'action': 'complete'},
      );
      return {
        'success': true,
        'message': 'Finalisation enregistrée (sera synchronisée)',
        'queued': true,
      };
    }

    return await _handleRequest(
      'POST',
      '/api/interventions/$interventionId/complete',
      successMessage: 'Intervention terminée',
    );
  }

  // Soumettre un rapport d'intervention
  Future<Map<String, dynamic>> submitInterventionReport(
    int interventionId,
    Map<String, dynamic> reportData,
  ) async {
    // Mode offline: Enregistrer localement et mettre en queue
    if (!_connectivityService.isConnected) {
      debugPrint('📦 Mode offline - Ajout rapport à la queue');

      try {
        // Mettre à jour le cache local avec les données du rapport
        await _cacheService.updateCachedIntervention(
          interventionId,
          {
            'report_data': reportData,
            'report_submitted_at': DateTime.now().toIso8601String(),
            'status': 'completed',
          },
        );

        // Cache les photos localement si présentes
        final List<String> imagePaths = (reportData['photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        if (imagePaths.isNotEmpty) {
          debugPrint(
              '📷 Cache de ${imagePaths.length} photo(s) pour sync ultérieure');
          for (final photoPath in imagePaths) {
            final fileName = photoPath.split('/').last;
            await _cacheService.cachePhoto(interventionId, photoPath, fileName);
          }
        }

        // Ajouter à la queue de synchronisation
        await _cacheService.addToSyncQueue(
          'report_upload',
          interventionId,
          reportData,
        );

        debugPrint('✅ Rapport enregistré localement et ajouté à la queue');

        return {
          'success': true,
          'message':
              'Rapport enregistré. Il sera synchronisé automatiquement quand la connexion sera rétablie.',
          'queued': true,
        };
      } catch (e) {
        debugPrint('❌ Erreur cache rapport offline: $e');
        rethrow;
      }
    }

    // Mode online: Upload normal
    try {
      if (_authToken == null) {
        await loadSavedToken();
        if (_authToken == null) {
          throw Exception('Non authentifié');
        }
      }

      final url = Uri.parse(
          '${AppConfig.baseUrl}/api/interventions/$interventionId/report');

      // Extraire les chemins des images du reportData
      final List<String> imagePaths = (reportData['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Créer la requête multipart si des images existent
      if (imagePaths.isNotEmpty) {
        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $_authToken';

        // Ajouter les champs texte
        request.fields['work_description'] =
            reportData['work_description']?.toString() ?? '';
        request.fields['duration'] = reportData['duration']?.toString() ?? '0';
        request.fields['observations'] =
            reportData['observations']?.toString() ?? '';

        // Ajouter les mesures techniques
        request.fields['pression'] = reportData['pression']?.toString() ?? '';
        request.fields['temperature'] =
            reportData['temperature']?.toString() ?? '';
        request.fields['intensite'] = reportData['intensite']?.toString() ?? '';
        request.fields['tension'] = reportData['tension']?.toString() ?? '';

        // Ajouter materials_used en JSON
        if (reportData['materials_used'] != null) {
          request.fields['materials_used'] =
              jsonEncode(reportData['materials_used']);
        }

        // Ajouter les images
        for (int i = 0; i < imagePaths.length; i++) {
          final file = File(imagePaths[i]);
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint(
                '📤 Préparation image $i: ${file.path} (${(fileSize / 1024).toStringAsFixed(1)} KB)');

            final multipartFile = await http.MultipartFile.fromPath(
              'images',
              file.path,
              filename: 'image_$i.jpg',
              contentType: http_parser.MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
            debugPrint('✅ Image $i ajoutée au multipart');
          } else {
            debugPrint('⚠️ Fichier introuvable: ${file.path}');
          }
        }

        debugPrint(
            '📤 Envoi du rapport avec ${request.files.length} image(s)...');

        // Augmenter le timeout pour les gros uploads
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Upload timeout après 60 secondes');
          },
        );

        debugPrint('📡 Réponse reçue, traitement en cours...');
        final response = await http.Response.fromStream(streamedResponse);

        debugPrint('📥 Réponse (${response.statusCode}): ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data as Map<String, dynamic>;
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Pas d'images, envoi en JSON standard
        return await _handleRequest(
          'POST',
          '/api/interventions/$interventionId/report',
          body: reportData,
          successMessage: 'Rapport soumis avec succès',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur submitInterventionReport: $e');
      rethrow;
    }
  }

  // Récupérer les rapports du technicien
  Future<Map<String, dynamic>> getTechnicianReports({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    return await _handleRequest(
      'GET',
      '/api/technician/reports',
      queryParams: queryParams,
      successMessage: 'Rapports récupérés',
    );
  }

  // Télécharger un rapport en HTML/PDF
  Future<String> downloadTechnicianReport(int interventionId) async {
    try {
      if (_authToken == null) {
        // Essayer de charger le token sauvegardé
        await loadSavedToken();
        if (_authToken == null) {
          throw Exception('Non authentifié');
        }
      }

      final url = Uri.parse(
          '${AppConfig.baseUrl}/api/technician/reports/$interventionId/download');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'text/html',
          'Accept': 'text/html',
        },
      );

      if (response.statusCode == 200) {
        return response.body; // Retourne le HTML
      } else {
        throw Exception('Erreur téléchargement: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur téléchargement rapport: $e');
      rethrow;
    }
  }

  // Créer un rapport
  Future<Map<String, dynamic>> createReport(
      Map<String, dynamic> reportData) async {
    return await _handleRequest(
      'POST',
      '/api/technician/reports',
      body: reportData,
      successMessage: 'Rapport créé avec succès',
    );
  }

  // Mettre à jour un rapport
  Future<Map<String, dynamic>> updateReport(
      int reportId, Map<String, dynamic> reportData) async {
    return await _handleRequest(
      'PUT',
      '/api/technician/reports/$reportId',
      body: reportData,
      successMessage: 'Rapport mis à jour',
    );
  }

  // Récupérer les évaluations du technicien
  Future<Map<String, dynamic>> getTechnicianReviews() async {
    return await _handleRequest(
      'GET',
      '/api/technician/reviews',
      successMessage: 'Évaluations récupérées',
    );
  }

  // Répondre à une évaluation
  Future<Map<String, dynamic>> replyToReview(int reviewId, String reply) async {
    return await _handleRequest(
      'POST',
      '/api/technician/reviews/$reviewId/reply',
      body: {'reply': reply},
      successMessage: 'Réponse envoyée',
    );
  }

  // Récupérer le calendrier du technicien
  Future<Map<String, dynamic>> getTechnicianCalendar(
      {String? startDate, String? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    return await _handleRequest(
      'GET',
      '/api/technician/calendar',
      queryParams: queryParams,
      successMessage: 'Calendrier récupéré',
    );
  }

  // ==================== NOTIFICATIONS ====================

  /// Récupérer toutes les notifications de l'utilisateur
  Future<Map<String, dynamic>> getNotifications() async {
    return await _handleRequest(
      'GET',
      '/api/notifications',
      successMessage: 'Notifications récupérées',
    );
  }

  /// Récupérer le nombre de notifications non lues
  Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    return await _handleRequest(
      'GET',
      '/api/notifications/unread-count',
      successMessage: 'Compteur récupéré',
    );
  }

  /// Marquer une notification comme lue
  Future<Map<String, dynamic>> markNotificationAsRead(
      int notificationId) async {
    return await _handleRequest(
      'PATCH',
      '/api/notifications/$notificationId/read',
      successMessage: 'Notification marquée comme lue',
    );
  }

  /// Marquer toutes les notifications comme lues
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await _handleRequest(
      'POST',
      '/api/notifications/mark-all-read',
      successMessage: 'Toutes les notifications marquées comme lues',
    );
  }

  /// Supprimer toutes les notifications
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    return await _handleRequest(
      'DELETE',
      '/api/notifications/delete-all',
      successMessage: 'Toutes les notifications ont été supprimées',
    );
  }

  // Fermer le client HTTP
  void dispose() {
    _client.close();
  }
}
