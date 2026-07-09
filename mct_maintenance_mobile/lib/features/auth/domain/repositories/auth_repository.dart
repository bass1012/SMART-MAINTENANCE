import 'dart:async';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> requestResetCode(String email);
  Future<Map<String, dynamic>> checkResetCode(String email, String code);
  Future<Map<String, dynamic>> verifyResetCode(String email, String code, String newPassword);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
  Future<String> uploadAvatar(String imagePath);
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Map<String, dynamic>> deleteAccount();
  Future<Map<String, dynamic>> getProfile();
  Future<void> logout();
  Future<List<int>> exportData();
  Future<bool> isLoggedIn();
  Future<void> loadSavedToken();
  Future<Map<String, dynamic>?> getUserData();
  Future<Map<String, dynamic>> verifyEmailCode(String emailOrPhone, String code);
  Future<Map<String, dynamic>> resendVerificationCode(String emailOrPhone, {String verificationMethod = 'auto'});
  Future<Map<String, dynamic>> updateWorkingHours(Map<String, dynamic> hours);
  Future<void> saveUserData(Map<String, dynamic> userData);
}
