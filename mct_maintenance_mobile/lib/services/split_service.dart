import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/split.dart' as models;
import '../services/api_service.dart';
import '../config/environment.dart';

/// Service pour gérer les Splits (équipements individuels)
class SplitService {
  final ApiService _apiService = ApiService();

  /// Headers avec authentification
  Map<String, String> get _headers => _apiService.headers;

  /// Base URL pour les splits
  String get _splitsUrl => '${AppConfig.baseUrl}/api/splits';

  /// Récupérer mes splits (client connecté)
  Future<List<models.Split>> getMySplits() async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl/my'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => models.Split.fromJson(item))
              .toList();
        }
      }

      print('❌ Erreur getMySplits: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception getMySplits: $e');
      return [];
    }
  }

  /// Rechercher un split par code QR
  Future<models.SplitScanResult?> findByQRCode(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl/code/$code'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return models.SplitScanResult.fromJson(data['data']);
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Split non trouvé: $code');
        return null;
      }

      print('❌ Erreur findByQRCode: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Exception findByQRCode: $e');
      return null;
    }
  }

  /// Scanner un split pour une intervention
  Future<Map<String, dynamic>?> scanSplitForIntervention({
    required int interventionId,
    required String splitCode,
    String scanMethod = 'qr_scan',
    String? exceptionReason,
  }) async {
    try {
      final body = {
        'split_code': splitCode,
        'scan_method': scanMethod,
        if (exceptionReason != null) 'exception_reason': exceptionReason,
      };

      final response = await http.post(
        Uri.parse('$_splitsUrl/scan/$interventionId'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        print('❌ Erreur scan: ${data['message']}');
        return {
          'error': true,
          'message': data['message'] ?? 'Erreur lors du scan',
          'warning': data['warning'],
        };
      }
    } catch (e) {
      print('❌ Exception scanSplitForIntervention: $e');
      return {
        'error': true,
        'message': 'Erreur de connexion',
      };
    }
  }

  /// Récupérer les splits d'un client (pour technicien/admin)
  Future<List<models.Split>> getCustomerSplits(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl/customer/$customerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => models.Split.fromJson(item))
              .toList();
        }
      }

      print('❌ Erreur getCustomerSplits: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception getCustomerSplits: $e');
      return [];
    }
  }

  /// Récupérer les splits pour une intervention (via l'API)
  Future<List<models.Split>> getSplitsForIntervention(
      int interventionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl/intervention/$interventionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => models.Split.fromJson(item))
              .toList();
        }
      }

      print('❌ Erreur getSplitsForIntervention: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception getSplitsForIntervention: $e');
      return [];
    }
  }

  /// Récupérer tous les splits (pour admin ou fallback)
  Future<List<models.Split>> getAllSplits() async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final splitsList = data['data']['splits'] ?? data['data'];
          if (splitsList is List) {
            return splitsList
                .map((item) => models.Split.fromJson(item))
                .toList();
          }
        }
      }

      print('❌ Erreur getAllSplits: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception getAllSplits: $e');
      return [];
    }
  }

  /// Récupérer un split par ID
  Future<models.Split?> getSplitById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_splitsUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return models.Split.fromJson(data['data']);
        }
      }

      print('❌ Erreur getSplitById: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Exception getSplitById: $e');
      return null;
    }
  }

  /// Parser les données d'un QR code scanné
  /// Format attendu: {"type": "SPLIT", "code": "SPLIT-2026-000001", "id": 1}
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = json.decode(qrData);
      if (data['type'] == 'SPLIT' && data['code'] != null) {
        return {
          'type': data['type'],
          'code': data['code'],
          'id': data['id'],
        };
      }
      return null;
    } catch (e) {
      // Si ce n'est pas du JSON, essayer de parser comme code simple
      if (qrData.startsWith('SPLIT-')) {
        return {
          'type': 'SPLIT',
          'code': qrData,
        };
      }
      print('❌ Format QR invalide: $qrData');
      return null;
    }
  }
}
