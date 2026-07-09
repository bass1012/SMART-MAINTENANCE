import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/config/environment.dart'
    show AppConfig;
import 'package:mct_maintenance_mobile/services/notification_navigation_service.dart';
import 'package:mct_maintenance_mobile/services/fcm_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BaseApiService _apiService;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _loggedOutFlag = 'has_logged_out';

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      AppConfig.loginUrl.replaceFirst(AppConfig.baseUrl, ''),
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      // Extraire le token (plusieurs clés possibles selon le backend)
      final token = data['token'] ??
          data['data']?['token'] ??
          data['accessToken'] ??
          data['data']?['accessToken'] ??
          data['access_token'] ??
          data['data']?['access_token'];

      if (token != null) {
        await _saveToken(token);
      }
      if (data['data']?['user'] != null) {
        await saveUserData(data['data']['user']);
      }
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _apiService.post(
      AppConfig.registerUrl.replaceFirst(AppConfig.baseUrl, ''),
      body: userData,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      final token = data['token'] ??
          data['data']?['token'] ??
          data['accessToken'] ??
          data['data']?['accessToken'] ??
          data['access_token'] ??
          data['data']?['access_token'];

      if (token != null) {
        await _saveToken(token);
      }
      final user = data['user'] ?? data['data']?['user'];
      if (user != null) {
        await saveUserData(user);
      }
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _apiService
        .post('/api/auth/forgot-password', body: {'email': email});
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> requestResetCode(String email) async {
    final response = await _apiService
        .post('/api/auth/request-reset-code', body: {'email': email});
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> checkResetCode(String email, String code) async {
    final response =
        await _apiService.post('/api/auth/check-reset-code', body: {
      'email': email,
      'code': code,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code, String newPassword) async {
    final response =
        await _apiService.post('/api/auth/verify-reset-code', body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put('/api/auth/profile', body: data);
    return jsonDecode(response.body);
  }

  @override
  Future<String> uploadAvatar(String imagePath) async {
    final file = await http.MultipartFile.fromPath('avatar', imagePath);
    final response = await _apiService
        .multipart('POST', '/api/upload/avatar', files: [file]);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Le backend peut renvoyer data['url'] ou data['data']['url']
      return data['data']?['url'] ?? data['url'] ?? '';
    } else {
      throw Exception(data['message'] ?? 'Échec de l\'upload de l\'avatar');
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiService.post('/api/auth/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> deleteAccount() async {
    final response = await _apiService.delete('/api/auth/delete-account');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _clearAuthData();
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.get('/api/auth/profile');
    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    return jsonDecode(response.body);
  }

  @override
  Future<void> logout() async {
    try {
      await _apiService.post('/api/auth/logout');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Logout API call failed: $e');
    }
    await _clearAuthData();
  }

  @override
  Future<List<int>> exportData() async {
    final response = await _apiService.get('/api/customer/export-data');
    return response.bodyBytes;
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_loggedOutFlag) == true) {
        if (kDebugMode) debugPrint('🔒 [AuthRepository] Ignorer le token (déconnexion explicite détectée)');
        return false;
      }

      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        NotificationNavigationService().setToken(token);
        await FCMService().setAuthToken(token);
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur lecture token secureStorage: $e');
    }
    return false;
  }

  @override
  Future<void> loadSavedToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) {
      _apiService.setToken(token);
      NotificationNavigationService().setToken(token);
      await FCMService().setAuthToken(token);
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> verifyEmailCode(
      String emailOrPhone, String code) async {
    // Le backend attend "email" ou "phone" (pas "emailOrPhone")
    final bool isPhone =
        RegExp(r'^\+?[0-9]{7,15}$').hasMatch(emailOrPhone.trim());
    final body = <String, dynamic>{
      if (isPhone)
        'phone': emailOrPhone.trim()
      else
        'email': emailOrPhone.trim(),
      'code': code,
    };
    final response =
        await _apiService.post('/api/auth/verify-email-code', body: body);

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      // Extraire le token (plusieurs clés possibles selon le backend)
      final token = data['token'] ??
          data['data']?['token'] ??
          data['accessToken'] ??
          data['data']?['accessToken'] ??
          data['access_token'] ??
          data['data']?['access_token'];

      if (token != null) {
        await _saveToken(token);
      }
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> resendVerificationCode(String emailOrPhone,
      {String verificationMethod = 'auto'}) async {
    // Le backend attend "email" ou "phone" (pas "emailOrPhone") + "verification_method" (snake_case)
    final bool isPhone =
        RegExp(r'^\+?[0-9]{7,15}$').hasMatch(emailOrPhone.trim());
    final body = <String, String>{
      if (isPhone)
        'phone': emailOrPhone.trim()
      else
        'email': emailOrPhone.trim(),
      'verification_method': verificationMethod,
    };
    final response = await _apiService
        .post('/api/auth/resend-verification-code', body: body);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updateWorkingHours(
      Map<String, dynamic> hours) async {
    final response =
        await _apiService.post('/api/technician/working-hours', body: {
      'working_hours': hours,
    });
    return jsonDecode(response.body);
  }

  // Helpers
  Future<void> _saveToken(String token) async {
    if (kDebugMode)
      debugPrint(
          '💾 [AuthRepository] Sauvegarde du token: ${token.substring(0, 10)}...');
    
    // Retirer le flag de déconnexion si on se reconnecte
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedOutFlag);

    await _secureStorage.write(key: _tokenKey, value: token);
    _apiService.setToken(token);
    NotificationNavigationService().setToken(token);
    await FCMService().setAuthToken(token);
    if (kDebugMode)
      debugPrint('✅ [AuthRepository] Token sauvegardé et synchronisé');
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<void> _clearAuthData() async {
    try {
      // Sur certains simulateurs iOS/Mac, delete peut échouer silencieusement.
      // On écrase la valeur par une chaîne vide d'abord.
      await _secureStorage.write(key: _tokenKey, value: '');
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.deleteAll(); 
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur suppression _secureStorage: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      // Sécurité absolue : flag de déconnexion explicite
      await prefs.setBool(_loggedOutFlag, true);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur suppression SharedPreferences: $e');
    }

    _apiService.setToken(null);
    NotificationNavigationService().setToken(null);
    
    try {
      await FCMService().setAuthToken(null);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur suppression FCM token: $e');
    }
  }
}
