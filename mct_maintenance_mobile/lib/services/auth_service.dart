import 'api_service.dart';

class AuthService {
  final _apiService = ApiService();

  Future<Map<String, dynamic>> verifyEmailCode(
      String emailOrPhone, String code) async {
    try {
      return await _apiService.verifyEmailCode(emailOrPhone, code);
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
      return await _apiService.resendVerificationCode(
        emailOrPhone,
        verificationMethod: verificationMethod,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  void dispose() {}
}
