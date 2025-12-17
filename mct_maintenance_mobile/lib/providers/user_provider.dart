import 'package:flutter/foundation.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger le profil utilisateur
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = await _apiService.getProfile();
      _user = UserModel.fromJson(userData['data']);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      await _apiService.updateProfile(data);
      // Recharger le profil après la mise à jour
      await loadUserProfile();
    } catch (e) {
      rethrow;
    }
  }

  // Réinitialiser l'utilisateur (déconnexion)
  void clearUser() {
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
