import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:mct_maintenance_mobile/models/installation_service.dart';
import 'package:mct_maintenance_mobile/models/repair_service.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';
import 'package:flutter/foundation.dart';

class ServiceApiService {
  static String? _verifiedBaseUrl;
  
  // Tester et obtenir une URL fonctionnelle
  static Future<String> _getWorkingBaseUrl() async {
    if (_verifiedBaseUrl != null) {
      return _verifiedBaseUrl!;
    }

    final candidateUrls = <String>[];
    
    // Sur Android émulateur, essayer d'abord 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      candidateUrls.add('http://10.0.2.2:3000');
    }
    
    // Ajouter l'URL configurée
    candidateUrls.add(AppConfig.baseUrl);
    
    // Essayer localhost en dernier recours
    if (!candidateUrls.contains('http://localhost:3000')) {
      candidateUrls.add('http://localhost:3000');
    }

    if (kDebugMode) debugPrint('🔍 Testing API connectivity...');
    
    for (final baseUrl in candidateUrls) {
      try {
        if (kDebugMode) debugPrint('   Trying: $baseUrl/health');
        final response = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          if (kDebugMode) debugPrint('✅ Connected to: $baseUrl');
          _verifiedBaseUrl = baseUrl;
          return baseUrl;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('   ❌ Failed: $baseUrl ($e)');
      }
    }

    if (kDebugMode) debugPrint('⚠️  No working API URL found, using default: ${AppConfig.baseUrl}');
    return AppConfig.baseUrl;
  }
  // Get active installation services
  Future<List<InstallationService>> getActiveInstallationServices() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final url = '$baseUrl/api/installation-services/active';
      if (kDebugMode) debugPrint('🔵 Calling Installation Services API: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      if (kDebugMode) debugPrint('🔵 Installation Services Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        if (kDebugMode) debugPrint('✅ Installation Services Count: ${jsonList.length}');
        return jsonList
            .map((json) => InstallationService.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des services d\'installation');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur getActiveInstallationServices: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Get active repair services
  Future<List<RepairService>> getActiveRepairServices() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final url = '$baseUrl/api/repair-services/active';
      if (kDebugMode) debugPrint('🟠 Calling Repair Services API: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      if (kDebugMode) debugPrint('🟠 Repair Services Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        if (kDebugMode) debugPrint('✅ Repair Services Count: ${jsonList.length}');
        return jsonList.map((json) => RepairService.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des services de réparation');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur getActiveRepairServices: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Get installation service by ID
  Future<InstallationService> getInstallationServiceById(int id) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/installation-services/$id'),
      );

      if (response.statusCode == 200) {
        return InstallationService.fromJson(json.decode(response.body));
      } else {
        throw Exception('Service non trouvé');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur getInstallationServiceById: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Get repair service by ID
  Future<RepairService> getRepairServiceById(int id) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/repair-services/$id'),
      );

      if (response.statusCode == 200) {
        return RepairService.fromJson(json.decode(response.body));
      } else {
        throw Exception('Service non trouvé');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur getRepairServiceById: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
