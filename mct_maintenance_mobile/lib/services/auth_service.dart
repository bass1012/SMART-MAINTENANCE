import 'dart:convert';
import 'api_service_new.dart';

class AuthService {
  final _apiService = ApiService();

  Future<Map<String, dynamic>> verifyEmailCode(
      String emailOrPhone, String code) async {
    try {
      final response = await _apiService.verifyEmailCode(emailOrPhone, code);
      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(
    String emailOrPhone, {
    String verificationMethod = 'auto',
  }) async {
    try {
      final response = await _apiService.resendVerificationCode(
        emailOrPhone,
        verificationMethod: verificationMethod,
      );
      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  void dispose() {
    _apiService.dispose();
  }
}
