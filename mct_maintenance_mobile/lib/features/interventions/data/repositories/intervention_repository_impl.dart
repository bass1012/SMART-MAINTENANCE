import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';
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
        String mimeType = 'image/jpeg'; // default
        final lowerPath = image.path.toLowerCase();
        if (lowerPath.endsWith('.png'))
          mimeType = 'image/png';
        else if (lowerPath.endsWith('.mp4'))
          mimeType = 'video/mp4';
        else if (lowerPath.endsWith('.mov'))
          mimeType = 'video/quicktime';
        else if (lowerPath.endsWith('.avi')) mimeType = 'video/x-msvideo';

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

    try {
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
        
        // 🧹 Nettoyer les anciennes interventions en cache local pour éviter la persistance d'anciens comptes
        await _cacheService.clearCachedInterventions();
        for (var intervention in interventions) {
          await _cacheService.cacheIntervention(intervention);
        }
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erreur réseau sur getInterventions, fallback cache: $e');
      }
      final cached = await _cacheService.getCachedInterventions();
      var results = cached;
      if (status != null) {
        results = cached.where((i) => i['status'] == status).toList();
      }
      return {
        'success': true,
        'data': results,
        'from_cache': true,
        'offline_fallback': true
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getTechnicianInterventions(
      {String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    // Mode Offline
    if (!_connectivityService.isConnected) {
      if (kDebugMode) {
        debugPrint(
            '📦 Mode offline - Lecture interventions technicien depuis cache');
      }
      final cached = await _cacheService.getCachedInterventions();

      // Filtrer par status si demandé
      var results = cached;
      if (status != null) {
        results = cached.where((i) => i['status'] == status).toList();
      }

      return {'success': true, 'data': results, 'from_cache': true};
    }

    try {
      final endpoint =
          '/api/technician/interventions${_buildQueryString(queryParams)}';
      final response = await _apiService.get(endpoint);
      final responseData = jsonDecode(response.body);

      // Mettre en cache les résultats
      if (responseData['success'] == true && responseData['data'] != null) {
        final rawData = responseData['data'];
        final List<dynamic> interventions = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['interventions'] as List? ?? []) : []);
        for (var intervention in interventions) {
          await _cacheService.cacheIntervention(intervention);
        }
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Erreur réseau sur getTechnicianInterventions, fallback cache: $e');
      }
      final cached = await _cacheService.getCachedInterventions();
      var results = cached;
      if (status != null) {
        results = cached.where((i) => i['status'] == status).toList();
      }
      return {
        'success': true,
        'data': results,
        'from_cache': true,
        'offline_fallback': true
      };
    }
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

    try {
      final response = await _apiService.get('/api/interventions/$id');
      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true && responseData['data'] != null) {
        await _cacheService.cacheIntervention(responseData['data']);
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Erreur réseau sur getInterventionById, fallback cache: $e');
      }
      final cached = await _cacheService.getCachedIntervention(id);
      if (cached != null) {
        return {
          'success': true,
          'data': cached,
          'from_cache': true,
          'offline_fallback': true
        };
      }
      rethrow;
    }
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
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      try {
        await _cacheService
            .updateCachedIntervention(id, {'status': 'in_progress'});
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur maj cache offline: $e');
      }
    }
    return responseData;
  }

  @override
  Future<Map<String, dynamic>> markInterventionOnTheWay(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'on_the_way', 'on_the_way');
    }
    final response =
        await _apiService.post('/api/interventions/$id/on-the-way');
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      try {
        await _cacheService
            .updateCachedIntervention(id, {'status': 'on_the_way'});
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur maj cache offline: $e');
      }
    }
    return responseData;
  }

  @override
  Future<Map<String, dynamic>> markInterventionArrived(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'arrived', 'arrived');
    }
    final response = await _apiService.post('/api/interventions/$id/arrived');
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      try {
        await _cacheService.updateCachedIntervention(id, {'status': 'arrived'});
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur maj cache offline: $e');
      }
    }
    return responseData;
  }

  @override
  Future<Map<String, dynamic>> startIntervention(int id,
      {Map<String, dynamic>? reportData}) async {
    if (!_connectivityService.isConnected) {
      return _queueOfflineStart(id, reportData);
    }

    try {
      late final http.Response response;
      if (reportData == null) {
        response = await _apiService.post('/api/interventions/$id/start');
      } else {
        final files = <http.MultipartFile>[];
        final photoPaths = (reportData['photos_before'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .where((item) =>
                !item.startsWith('http://') &&
                !item.startsWith('https://') &&
                !item.startsWith('/uploads/'));

        for (final photoPath in photoPaths) {
          final file = File(photoPath);
          if (!await file.exists()) continue;
          files.add(await http.MultipartFile.fromPath(
            'images',
            photoPath,
            contentType:
                http_parser.MediaType.parse(_mimeTypeForPath(photoPath)),
          ));
        }

        response = await _apiService.multipart(
          'POST',
          '/api/interventions/$id/start',
          fields: {'report_data': jsonEncode(reportData)},
          files: files,
        );
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          responseData['success'] != true) {
        throw Exception(
            responseData['message'] ?? 'Impossible de démarrer l’intervention');
      }

      if (responseData['success'] == true) {
        try {
          final updateMap = <String, dynamic>{'status': 'in_progress'};
          final serverData = responseData['data'];
          if (serverData is Map && serverData['report_data'] != null) {
            updateMap['report_data'] = serverData['report_data'];
          } else if (reportData != null) {
            updateMap['report_data'] = reportData;
          }
          await _cacheService.updateCachedIntervention(id, updateMap);
          if (reportData != null) {
            final cachedPhotos = await _cacheService.getUnuploadedPhotos(id);
            final beforePaths =
                (reportData['photos_before'] as List<dynamic>? ?? [])
                    .map((item) => item.toString())
                    .toSet();
            for (final cachedPhoto in cachedPhotos) {
              if (beforePaths.contains(cachedPhoto['file_path'])) {
                await _cacheService.markPhotoUploaded(cachedPhoto['id'] as int);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Erreur maj cache offline: $e');
        }
      }
      return responseData;
    } on SocketException {
      return _queueOfflineStart(id, reportData);
    } on TimeoutException {
      return _queueOfflineStart(id, reportData);
    }
  }

  @override
  Future<Map<String, dynamic>> completeIntervention(int id) async {
    if (!_connectivityService.isConnected) {
      return _queueAction(id, 'complete', 'completed');
    }
    final response = await _apiService.post('/api/interventions/$id/complete');
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      try {
        await _cacheService
            .updateCachedIntervention(id, {'status': 'completed'});
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur maj cache offline: $e');
      }
    }
    return responseData;
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

      final List<String> imagePaths =
          (reportData['photos_after'] as List<dynamic>? ??
                      reportData['photos'] as List<dynamic>?)
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
    final fields = <String, String>{};
    reportData.forEach((key, value) {
      if (value != null) {
        if (key == 'photos') {
          // Géré séparément
        } else if (value is List || value is Map) {
          fields[key] = jsonEncode(value);
        } else {
          fields[key] = value.toString();
        }
      }
    });

    final List<http.MultipartFile> files = [];
    final List<String> imagePaths =
        (reportData['photos_after'] as List<dynamic>? ??
                    reportData['photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    for (final path in imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'images',
          path,
          contentType: http_parser.MediaType.parse(_mimeTypeForPath(path)),
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

  @override
  Future<Map<String, dynamic>> reportClientUnreachable(int interventionId,
      {String? notes}) async {
    final Map<String, dynamic> data = {};
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    try {
      final response = await _apiService.post(
        '/api/technician/interventions/$interventionId/report-unreachable',
        body: data,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> rescheduleIntervention(
      int interventionId, DateTime newDate) async {
    try {
      final response = await _apiService.post(
        '/api/customer/interventions/$interventionId/reschedule',
        body: {
          'scheduled_date': newDate.toIso8601String(),
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _queueAction(
      int id, String action, String status,
      {Map<String, dynamic>? additionalData}) async {
    final cacheUpdates = <String, dynamic>{
      'status': status,
      ...?additionalData,
    };
    await _cacheService.updateCachedIntervention(id, cacheUpdates);
    await _cacheService.addToSyncQueue('intervention_status', id, {
      'status': status,
      'action': action,
      ...?additionalData,
    });
    return {
      'success': true,
      'message': 'Action mise en attente (hors ligne)',
      'queued': true,
    };
  }

  Future<Map<String, dynamic>> _queueOfflineStart(
      int id, Map<String, dynamic>? reportData) async {
    final durableReportData =
        reportData == null ? null : await _persistReportPhotos(id, reportData);
    return _queueAction(
      id,
      'start',
      'in_progress',
      additionalData:
          durableReportData == null ? null : {'report_data': durableReportData},
    );
  }

  Future<Map<String, dynamic>> _persistReportPhotos(
      int interventionId, Map<String, dynamic> reportData) async {
    final durableData = Map<String, dynamic>.from(reportData);
    final sourcePaths = (reportData['photos_before'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    if (sourcePaths.isEmpty) return durableData;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final reportDirectory = Directory(path_util.join(
        documentsDirectory.path, 'offline_reports', '$interventionId'));
    await reportDirectory.create(recursive: true);

    final durablePaths = <String>[];
    for (int index = 0; index < sourcePaths.length; index++) {
      final sourcePath = sourcePaths[index];
      if (sourcePath.startsWith('http://') ||
          sourcePath.startsWith('https://') ||
          sourcePath.startsWith('/uploads/')) {
        durablePaths.add(sourcePath);
        continue;
      }

      final source = File(sourcePath);
      if (!await source.exists()) {
        throw Exception('Photo avant intervention introuvable');
      }
      final extension = path_util.extension(sourcePath);
      final destinationPath = path_util.join(reportDirectory.path,
          'before_${DateTime.now().microsecondsSinceEpoch}_$index$extension');
      await source.copy(destinationPath);
      durablePaths.add(destinationPath);
      await _cacheService.cachePhoto(
          interventionId, destinationPath, path_util.basename(destinationPath));
    }

    durableData['photos_before'] = durablePaths;
    durableData['photos'] = durablePaths;
    return durableData;
  }

  String _mimeTypeForPath(String filePath) {
    final lowerPath = filePath.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    if (lowerPath.endsWith('.mp4')) return 'video/mp4';
    if (lowerPath.endsWith('.mov')) return 'video/quicktime';
    if (lowerPath.endsWith('.avi')) return 'video/x-msvideo';
    return 'image/jpeg';
  }
}
