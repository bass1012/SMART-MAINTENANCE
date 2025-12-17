import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/environment.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late http.Client _client;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...corsHeaders,
  };

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    // Configuration du client HTTP avec un délai d'attente
    final httpClient = HttpClient()
      ..connectionTimeout = apiTimeout
      ..badCertificateCallback = (cert, host, port) => true; // Ne pas utiliser en production
    _client = IOClient(httpClient);
  }

  // Méthode générique pour les requêtes HTTP
  Future<http.Response> _request(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/$endpoint').replace(
        queryParameters: queryParams,
      );

      if (debugLogs) {
        print('API Request: $method $uri');
        if (body != null) print('Request Body: $body');
      }

      final response = await _client
          .send(
            http.Request(
              method,
              uri,
            )
              ..headers.addAll({..._headers, ...?headers})
              ..body = body is Map ? jsonEncode(body) : body?.toString() ?? '',
          )
          .timeout(apiTimeout);

      final responseBody = await response.stream.bytesToString();
      
      if (debugLogs) {
        print('API Response (${response.statusCode}): $responseBody');
      }

      return http.Response(
        responseBody,
        response.statusCode,
        headers: response.headers,
        request: response.request,
      );
    } on SocketException catch (e) {
      throw Exception('Erreur de connexion: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Le serveur ne répond pas. Veuillez réessayer.');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Méthode de connexion
  Future<http.Response> login(String email, String password) async {
    return _request(
      'POST',
      'login',
      body: {'email': email, 'password': password},
    );
  }

  // Méthode d'inscription
  Future<http.Response> register(Map<String, dynamic> data) async {
    return _request('POST', 'register', body: data);
  }

  // N'oubliez pas de fermer le client quand vous avez fini
  void dispose() {
    _client.close();
  }
}
