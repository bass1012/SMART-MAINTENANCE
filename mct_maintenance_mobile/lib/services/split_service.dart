import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mct_maintenance_mobile/models/split.dart' as models;
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';

/// Service pour gérer les Splits (équipements individuels)
class SplitService {
  final BaseApiService _apiService = BaseApiService();

  /// Récupérer mes splits (client connecté)
  Future<List<models.Split>> getMySplits() async {
    try {
      final response = await _apiService.get('/api/splits/my');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => models.Split.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getMySplits: $e');
      return [];
    }
  }

  /// Rechercher un split par code QR
  Future<models.SplitScanResult?> findByQRCode(String code) async {
    try {
      final response = await _apiService.get('/api/splits/code/$code');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return models.SplitScanResult.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ findByQRCode: $e');
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
      final response = await _apiService.post('/api/splits/scan/$interventionId', body: body);
      final data = jsonDecode(response.body);
      return data['data'];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ scanSplitForIntervention: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Récupérer les splits d'un client (pour technicien/admin)
  Future<List<models.Split>> getCustomerSplits(int customerId) async {
    try {
      final response = await _apiService.get('/api/splits/customer/$customerId');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => models.Split.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getCustomerSplits: $e');
      return [];
    }
  }

  /// Récupérer les splits pour une intervention
  Future<List<models.Split>> getSplitsForIntervention(
      int interventionId) async {
    try {
      final response =
          await _apiService.get('/api/splits/intervention/$interventionId');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => models.Split.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getSplitsForIntervention: $e');
      return [];
    }
  }

  /// Récupérer tous les splits
  Future<List<models.Split>> getAllSplits() async {
    try {
      final response = await _apiService.get('/api/splits');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final splitsList = data['data']['splits'] ?? data['data'];
        if (splitsList is List) {
          return splitsList.map((item) => models.Split.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAllSplits: $e');
      return [];
    }
  }

  /// Récupérer un split par ID
  Future<models.Split?> getSplitById(int id) async {
    try {
      final response = await _apiService.get('/api/splits/$id');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return models.Split.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getSplitById: $e');
      return null;
    }
  }

  /// Parser les données d'un QR code scanné
  /// Format attendu: {"type": "SPLIT", "code": "SPLIT-2026-000001", "id": 1}
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = json.decode(qrData) as Map<String, dynamic>;
      if (data['type'] == 'SPLIT' && data['code'] != null) {
        return {'type': data['type'], 'code': data['code'], 'id': data['id']};
      }
      return null;
    } catch (_) {
      if (qrData.startsWith('SPLIT-')) {
        return {'type': 'SPLIT', 'code': qrData};
      }
      if (kDebugMode) debugPrint('❌ Format QR invalide: $qrData');
      return null;
    }
  }
}
