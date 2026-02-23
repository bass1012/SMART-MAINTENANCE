import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/installation_service.dart';
import '../models/repair_service.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

    print('🔍 Testing API connectivity...');
    
    for (final baseUrl in candidateUrls) {
      try {
        print('   Trying: $baseUrl/health');
        final response = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('✅ Connected to: $baseUrl');
          _verifiedBaseUrl = baseUrl;
          return baseUrl;
        }
      } catch (e) {
        print('   ❌ Failed: $baseUrl ($e)');
      }
    }

    print('⚠️  No working API URL found, using default: ${AppConfig.baseUrl}');
    return AppConfig.baseUrl;
  }
  // Get active installation services
  Future<List<InstallationService>> getActiveInstallationServices() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final url = '$baseUrl/api/installation-services/active';
      print('🔵 Calling Installation Services API: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      print('🔵 Installation Services Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Installation Services Count: ${jsonList.length}');
        return jsonList
            .map((json) => InstallationService.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des services d\'installation');
      }
    } catch (e) {
      print('❌ Erreur getActiveInstallationServices: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Get active repair services
  Future<List<RepairService>> getActiveRepairServices() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final url = '$baseUrl/api/repair-services/active';
      print('🟠 Calling Repair Services API: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      print('🟠 Repair Services Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Repair Services Count: ${jsonList.length}');
        return jsonList.map((json) => RepairService.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des services de réparation');
      }
    } catch (e) {
      print('❌ Erreur getActiveRepairServices: $e');
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
      print('❌ Erreur getInstallationServiceById: $e');
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
      print('❌ Erreur getRepairServiceById: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
