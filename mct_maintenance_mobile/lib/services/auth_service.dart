import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';

class AuthService {
  final AuthRepository _authRepository = AuthRepositoryImpl(BaseApiService());

  Future<Map<String, dynamic>> verifyEmailCode(
      String emailOrPhone, String code) async {
    try {
      return await _authRepository.verifyEmailCode(emailOrPhone, code);
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
      return await _authRepository.resendVerificationCode(
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
