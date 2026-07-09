import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mct_maintenance_mobile/config/environment.dart' show AppConfig, ApiConfig;

/// Logique de base pour les appels API HTTP
class BaseApiService {
  late final http.Client _client;
  String? _token;

  BaseApiService() {
    final httpClient = HttpClient()..connectionTimeout = ApiConfig.timeout;
    if (kDebugMode) {
      // ignore: invalid_use_of_protected_member
      httpClient.badCertificateCallback = (cert, host, port) => true;
    }
    _client = IOClient(httpClient);
  }

  void setToken(String? token) {
    _token = token;
    if (kDebugMode && ApiConfig.debugLogs) {
      debugPrint('🔑 [BaseApiService] Token set: ${token != null ? '${token.substring(0, 10)}...' : 'null'}');
    }
  }

  String get baseUrl => AppConfig.baseUrl;

  Map<String, String> get _headers {
    final headers = {
      ...ApiConfig.defaultHeaders,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> request(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = '$baseUrl/$cleanEndpoint';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🔵 API Request: $method $uri');
      }

      final request = http.Request(method, uri);
      final mergedHeaders = Map<String, String>.from(_headers);
      if (kDebugMode && ApiConfig.debugLogs) {
        final hasAuth = mergedHeaders.containsKey('Authorization');
        debugPrint('📋 [BaseApiService] Request headers: ${hasAuth ? 'Auth present' : 'Auth MISSING'}');
      }
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }
      request.headers.addAll(mergedHeaders);

      if (body != null) {
        request.body = body is Map || body is List ? jsonEncode(body) : body.toString();
        if (!request.headers.containsKey('Content-Type')) {
          request.headers['Content-Type'] = 'application/json';
        }
      }

      final streamedResponse = await _client.send(request).timeout(ApiConfig.timeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🟢 API Response (${streamedResponse.statusCode}): $responseBody');
      }

      return http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: streamedResponse.request,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API Error ($method $endpoint): $e');
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, dynamic>? queryParams, Map<String, String>? headers}) =>
      request('GET', endpoint, queryParams: queryParams, headers: headers);

  Future<http.Response> post(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('POST', endpoint, body: body, headers: headers);

  Future<http.Response> put(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('PUT', endpoint, body: body, headers: headers);

  Future<http.Response> delete(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('DELETE', endpoint, body: body, headers: headers);

  Future<http.Response> patch(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('PATCH', endpoint, body: body, headers: headers);

  Future<http.Response> multipart(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = '$baseUrl/$cleanEndpoint';
      final uri = Uri.parse(url);

      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🔵 API Multipart Request: $method $uri');
      }

      final request = http.MultipartRequest(method, uri);
      final mergedHeaders = Map<String, String>.from(_headers);
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }
      request.headers.addAll(mergedHeaders);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await _client.send(request).timeout(ApiConfig.timeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🟢 API Response (${streamedResponse.statusCode}): $responseBody');
      }

      return http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: streamedResponse.request,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API Multipart Error ($method $endpoint): $e');
      rethrow;
    }
  }

  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = '$baseUrl/$cleanEndpoint';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🔵 API Request (Bytes): GET $uri');
      }

      final request = http.Request('GET', uri);
      final mergedHeaders = Map<String, String>.from(_headers);
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }
      request.headers.addAll(mergedHeaders);

      final streamedResponse = await _client.send(request).timeout(ApiConfig.timeout);
      
      if (streamedResponse.statusCode >= 400) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API Error (${streamedResponse.statusCode}): $errorBody');
      }

      final bytes = await streamedResponse.stream.toBytes();
      
      if (kDebugMode && ApiConfig.debugLogs) {
        debugPrint('🟢 API Response (Bytes) (${streamedResponse.statusCode}): ${bytes.length} bytes');
      }

      return bytes;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API Error (GET Bytes $endpoint): $e');
      rethrow;
    }
  }
}
