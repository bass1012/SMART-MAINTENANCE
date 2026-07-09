import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/services/connectivity_service.dart';
import 'package:mct_maintenance_mobile/services/local_cache_service.dart';
import 'package:mct_maintenance_mobile/models/maintenance_report_model.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  final BaseApiService _apiService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalCacheService _cacheService = LocalCacheService();

  InterventionRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> createIntervention(
      Map<String, dynamic> data) async {
    final response = await _apiService.post('/api/interventions', body: data);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> createInterventionWithImages({
    required Map<String, dynamic> data,
    List<File>? images,
  }) async {
    final fields = <String, String>{};
    data.forEach((key, value) {
      if (value != null) fields[key] = value.toString();
    });

    final List<http.MultipartFile> files = [];
    if (images != null) {
      for (final image in images) {
        final mimeType = image.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        files.add(await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: http_parser.MediaType.parse(mimeType),
        ));
      }
    }

    final response = await _apiService.multipart(
      'POST',
      '/api/interventions',
      fields: fields,
      files: files,
    );

    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticConfig() async {
    final response =
        await _apiService.get('/api/interventions/config/diagnostic-fee');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getInterventions(
      {int? customerId, String? status}) async {
    final queryParams = <String, String>{};
    if (customerId != null) queryParams['customer_id'] = customerId.toString();
    if (status != null) queryParams['status'] = status;

    // Mode Offline
    if (!_connectivityService.isConnected) {
      if (kDebugMode)
        debugPrint('📦 Mode offline - Lecture interventions depuis cache');
      final cached = await _cacheService.getCachedInterventions();

      // Filtrer par status si demandé
      var results = cached;
      if (status != null) {
        results = cached.where((i) => i['status'] == status).toList();
      }

      return {'success': true, 'data': results, 'from_cache': true};
    }

    final endpoint = '/api/interventions${_buildQueryString(queryParams)}';
    final response = await _apiService.get(endpoint);
    final responseData = jsonDecode(response.body);

    // Mettre en cache les résultats
    if (responseData['success'] == true && responseData['data'] != null) {
      final rawData = responseData['data'];
      // L'API peut retourner data directement comme List ou comme Map { interventions: [] }
      final List<dynamic> interventions = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['interventions'] as List? ?? []) : []);
      for (var intervention in interventions) {
        await _cacheService.cacheIntervention(intervention);
      }
    }

    return responseData;
  }

  @override
  Future<Map<String, dynamic>> getTechnicianInterventions(
      {String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    final endpoint =
        '/api/technician/interventions${_buildQueryString(queryParams)}';
    final response = await _apiService.get(endpoint);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getRecentInterventions({int limit = 5}) async {
    final response = await _apiService
        .get('/api/customer/interventions?limit=$limit&sort=desc');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _apiService.get('/api/customer/dashboard/stats');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getTechnicianStats() async {
    final response = await _apiService.get('/api/technician/dashboard/stats');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updateTechnicianAvailability(
      String status) async {
    final response = await _apiService.put('/api/technician/availability',
        body: {'availability_status': status});
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getInterventionById(int id) async {
    // Mode Offline
    if (!_connectivityService.isConnected) {
      if (kDebugMode)
        debugPrint('📦 Mode offline - Lecture intervention #$id depuis cache');
      final cached = await _cacheService.getCachedIntervention(id);
      if (cached != null) {
        return {'success': true, 'data': cached, 'from_cache': true};
      }
    }

    final response = await _apiService.get('/api/interventions/$id');
    final responseData = jsonDecode(response.body);

    if (responseData['success'] == true && responseData['data'] != null) {
      await _cacheService.cacheIntervention(responseData['data']);
    }

    return responseData;
  }

  @override
  Future<Map<String, dynamic>> cancelIntervention(int id) async {
    final response = await _apiService
        .put('/api/interventions/$id', body: {'status': 'cancelled'});
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> rateIntervention(
      int id, int rating, String review) async {
    final response =
        await _apiService.post('/api/interventions/$id/rate', body: {
      'rating': rating,
      'review': review,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> confirmInterventionCompletion(
      int id, bool confirmed,
      {String? rejectionReason}) async {
    final body = <String, dynamic>{'confirmed': confirmed};
    if (!confirmed && rejectionReason != null) {
      body['rejection_reason'] = rejectionReason;
    }
    final response = await _apiService
        .post('/api/interventions/$id/confirm-completion', body: body);
    return jsonDecode(response.body);
  }

  @override
  Future<List<Map<String, dynamic>>> getUnratedInterventions() async {
    final response = await _apiService.get('/api/interventions/unrated');
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingDiagnosticPayments() async {
    final response =
        await _apiService.get('/api/interventions/pending-diagnostic-payment');
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingConfirmationReports() async {
    final response =
        await _apiService.get('/api/interventions/pending-confirmation');
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  @override
  Future<List<MaintenanceReport>> getMaintenanceReports() async {
    final response = await _apiService.get('/api/customer/maintenance-reports');
    final data = jsonDecode(response.body);
    final List<dynamic> reports = data['data'] ?? [];
    return reports.map((json) => MaintenanceReport.fromJson(json)).toList();
  }

  @override
  Future<Map<String, dynamic>> acceptIntervention(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'accept', 'accepted');
    }
    final response = await _apiService.post('/api/interventions/$id/accept');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markInterventionOnTheWay(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'on-the-way', 'on_the_way');
    }
    final response =
        await _apiService.post('/api/interventions/$id/on-the-way');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> markInterventionArrived(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'arrived', 'arrived');
    }
    final response = await _apiService.post('/api/interventions/$id/arrived');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> startIntervention(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'start', 'in_progress');
    }
    final response = await _apiService.post('/api/interventions/$id/start');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> completeIntervention(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'complete', 'completed');
    }
    final response = await _apiService.post('/api/interventions/$id/complete');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> submitInterventionReport(
      int id, Map<String, dynamic> reportData) async {
    if (!_connectivityService.isConnected) {
      // Logic for offline report submission (save to cache and queue)
      await _cacheService.updateCachedIntervention(id, {
        'report_data': reportData,
        'report_submitted_at': DateTime.now().toIso8601String(),
        'status': 'completed',
      });

      final List<String> imagePaths = (reportData['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      for (final path in imagePaths) {
        await _cacheService.cachePhoto(id, path, path.split('/').last);
      }

      await _cacheService.addToSyncQueue('report_upload', id, reportData);

      return {
        'success': true,
        'message': 'Rapport enregistré offline',
        'queued': true
      };
    }

    // Online submission
    final fields = <String, String>{
      'work_description': reportData['work_description']?.toString() ?? '',
      'duration': reportData['duration']?.toString() ?? '0',
      'observations': reportData['observations']?.toString() ?? '',
    };

    final List<http.MultipartFile> files = [];
    final List<String> imagePaths = (reportData['photos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    for (final path in imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        final mimeType =
            path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        files.add(await http.MultipartFile.fromPath(
          'photos',
          path,
          contentType: http_parser.MediaType.parse(mimeType),
        ));
      }
    }

    final response = await _apiService.multipart(
      'POST',
      '/api/interventions/$id/report',
      fields: fields,
      files: files,
    );

    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> submitDiagnosticReport(
      Map<String, dynamic> data) async {
    final response =
        await _apiService.post('/api/diagnostic-reports', body: data);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getTechnicianCalendar(
      {String? startDate, String? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final endpoint =
        '/api/technician/calendar${_buildQueryString(queryParams)}';
    final response = await _apiService.get(endpoint);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getTechnicianReports() async {
    final response = await _apiService.get('/api/technician/reports');
    return jsonDecode(response.body);
  }

  @override
  Future<String> downloadTechnicianReport(int reportId) async {
    final response =
        await _apiService.get('/api/technician/reports/$reportId/download');
    return response.body;
  }

  @override
  Future<Map<String, dynamic>> getTechnicianReviews() async {
    final response = await _apiService.get('/api/technician/reviews');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> replyToReview(int reviewId, String reply) async {
    final response = await _apiService.post(
        '/api/technician/reviews/$reviewId/reply',
        body: {'reply': reply});
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> suggestTechnicians(
      {required int interventionId, int maxResults = 10}) async {
    final response = await _apiService.post(
        '/api/interventions/$interventionId/suggest-technicians',
        body: {'max_results': maxResults});
    return jsonDecode(response.body);
  }

  // Helpers
  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    final pairs = <String>[];
    params.forEach(
        (key, value) => pairs.add('$key=${Uri.encodeComponent(value)}'));
    return '?${pairs.join('&')}';
  }

  Future<Map<String, dynamic>> _queueAction(
      int id, String action, String status) async {
    await _cacheService.updateCachedIntervention(id, {'status': status});
    await _cacheService.addToSyncQueue(
        'intervention_status', id, {'status': status, 'action': action});
    return {
      'success': true,
      'message': 'Action mise en attente (hors ligne)',
      'queued': true,
    };
  }
}
