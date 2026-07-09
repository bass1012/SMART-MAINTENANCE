import 'package:mct_maintenance_mobile/models/complaint_model.dart';

abstract class ComplaintRepository {
  Future<List<Complaint>> getCustomerComplaints();
  Future<Complaint> getComplaintDetails(String id);
  Future<Map<String, dynamic>> createComplaint(Map<String, dynamic> data);
}
