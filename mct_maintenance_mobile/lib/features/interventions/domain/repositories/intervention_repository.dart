import 'dart:io';
import 'package:mct_maintenance_mobile/models/maintenance_report_model.dart';

abstract class InterventionRepository {
  Future<Map<String, dynamic>> createIntervention(Map<String, dynamic> data);
  Future<Map<String, dynamic>> createInterventionWithImages({
    required Map<String, dynamic> data,
    List<File>? images,
  });
  Future<Map<String, dynamic>> getDiagnosticConfig();
  Future<Map<String, dynamic>> getInterventions({int? customerId, String? status});
  Future<Map<String, dynamic>> getTechnicianInterventions({String? status});
  Future<Map<String, dynamic>> getRecentInterventions({int limit = 5});
  Future<Map<String, dynamic>> getDashboardStats();
  Future<Map<String, dynamic>> getTechnicianStats();
  Future<Map<String, dynamic>> updateTechnicianAvailability(String status);
  Future<Map<String, dynamic>> getInterventionById(int id);
  Future<Map<String, dynamic>> cancelIntervention(int id);
  Future<Map<String, dynamic>> rateIntervention(int id, int rating, String review);
  Future<Map<String, dynamic>> confirmInterventionCompletion(int id, bool confirmed, {String? rejectionReason});
  Future<List<Map<String, dynamic>>> getUnratedInterventions();
  Future<List<Map<String, dynamic>>> getPendingDiagnosticPayments();
  Future<List<Map<String, dynamic>>> getPendingConfirmationReports();
  Future<List<MaintenanceReport>> getMaintenanceReports();
  
  // Technician specific
  Future<Map<String, dynamic>> acceptIntervention(int id);
  Future<Map<String, dynamic>> markInterventionOnTheWay(int id);
  Future<Map<String, dynamic>> markInterventionArrived(int id);
  Future<Map<String, dynamic>> startIntervention(int id);
  Future<Map<String, dynamic>> completeIntervention(int id);
  Future<Map<String, dynamic>> submitInterventionReport(int id, Map<String, dynamic> reportData);
  Future<Map<String, dynamic>> submitDiagnosticReport(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getTechnicianCalendar({String? startDate, String? endDate});
  Future<Map<String, dynamic>> getTechnicianReports();
  Future<String> downloadTechnicianReport(int reportId);
  Future<Map<String, dynamic>> getTechnicianReviews();
  Future<Map<String, dynamic>> replyToReview(int reviewId, String reply);
  Future<Map<String, dynamic>> suggestTechnicians({required int interventionId, int maxResults = 10});
}
