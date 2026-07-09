import 'package:mct_maintenance_mobile/models/installation_service.dart';
import 'package:mct_maintenance_mobile/models/repair_service.dart';
import 'package:mct_maintenance_mobile/models/maintenance_offer_model.dart';

abstract class ServiceRepository {
  Future<List<MaintenanceOffer>> getMaintenanceOffers();
  Future<List<InstallationService>> getActiveInstallationServices();
  Future<List<RepairService>> getActiveRepairServices();
  Future<InstallationService> getInstallationServiceById(int id);
  Future<RepairService> getRepairServiceById(int id);
}
