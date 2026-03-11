import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/maintenance_report_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/support_fab_wrapper.dart';

class MaintenanceReportsScreen extends StatefulWidget {
  const MaintenanceReportsScreen({super.key});

  @override
  State<MaintenanceReportsScreen> createState() =>
      _MaintenanceReportsScreenState();
}

class _MaintenanceReportsScreenState extends State<MaintenanceReportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<MaintenanceReport> _reports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _apiService.getMaintenanceReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rapports de Maintenance'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _error != null
                  ? Center(child: Text('Erreur: $_error'))
                  : _reports.isEmpty
                      ? const Center(
                          child: Text('Aucun rapport de maintenance trouvé'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return _buildReportCard(report);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildReportCard(MaintenanceReport report) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _getStatusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Naviguer vers les détails du rapport
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    report.reference ?? 'Sans référence',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatStatus(report.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title ?? 'Sans titre',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (report.description != null && report.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    report.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Divider(),
              if (report.technicianName != null)
                _buildInfoRow(
                  Icons.person_outline,
                  'Technicien: ${report.technicianName!}',
                ),
              if (report.scheduledDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date prévue: ${dateFormat.format(report.scheduledDate!)}',
                ),
              if (report.completedDate != null)
                _buildInfoRow(
                  Icons.check_circle_outline,
                  'Terminé le: ${dateFormat.format(report.completedDate!)}',
                ),
              if (report.technicianNotes != null &&
                  report.technicianNotes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Notes du technicien:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      report.technicianNotes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              // Mesures techniques
              if (_hasTechnicalMeasures(report))
                _buildTechnicalMeasuresSection(report),
              if (report.imageUrls != null && report.imageUrls!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              report.imageUrls![index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Planifié';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  bool _hasTechnicalMeasures(MaintenanceReport report) {
    // Vérifier le nouveau format multi-équipements
    if (report.equipments != null && report.equipments!.isNotEmpty) {
      return report.equipments!.any((e) => e.hasTechnicalMeasures);
    }
    // Format legacy
    return (report.pression != null && report.pression!.isNotEmpty) ||
        (report.puissance != null && report.puissance!.isNotEmpty) ||
        (report.intensite != null && report.intensite!.isNotEmpty) ||
        (report.tension != null && report.tension!.isNotEmpty);
  }

  Widget _buildTechnicalMeasuresSection(MaintenanceReport report) {
    // Utiliser le nouveau format multi-équipements si disponible
    if (report.equipments != null && report.equipments!.isNotEmpty) {
      return Column(
        children: report.equipments!.asMap().entries.map((entry) {
          final index = entry.key;
          final equipment = entry.value;
          if (!equipment.hasTechnicalMeasures &&
              (equipment.state == null || equipment.state!.isEmpty) &&
              (equipment.type == null || equipment.type!.isEmpty) &&
              (equipment.brand == null || equipment.brand!.isEmpty)) {
            return const SizedBox.shrink();
          }
          return _buildEquipmentCard(equipment, index + 1);
        }).toList(),
      );
    }

    // Format legacy
    return _buildLegacyTechnicalMeasures(report);
  }

  Widget _buildEquipmentCard(ReportEquipment equipment, int index) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec numéro
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  equipment.brand != null && equipment.brand!.isNotEmpty
                      ? '${equipment.brand} - ${equipment.type ?? ""}'
                      : 'Équipement $index',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (equipment.state != null && equipment.state!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'État: ${equipment.state}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          // Mesures techniques
          if (equipment.hasTechnicalMeasures) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (equipment.pression != null &&
                      equipment.pression!.isNotEmpty)
                    _buildMeasureChip(Icons.compress, 'Pression',
                        '${equipment.pression} bar'),
                  if (equipment.puissance != null &&
                      equipment.puissance!.isNotEmpty)
                    _buildMeasureChip(
                        Icons.power, 'Puissance', '${equipment.puissance} CV'),
                  if (equipment.intensite != null &&
                      equipment.intensite!.isNotEmpty)
                    _buildMeasureChip(Icons.electrical_services, 'Intensité',
                        '${equipment.intensite} A'),
                  if (equipment.tension != null &&
                      equipment.tension!.isNotEmpty)
                    _buildMeasureChip(
                        Icons.bolt, 'Tension', '${equipment.tension} V'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegacyTechnicalMeasures(MaintenanceReport report) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Mesures Techniques',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (report.pression != null && report.pression!.isNotEmpty)
                _buildMeasureChip(
                    Icons.compress, 'Pression', '${report.pression} bar'),
              if (report.puissance != null && report.puissance!.isNotEmpty)
                _buildMeasureChip(
                    Icons.power, 'Puissance', '${report.puissance} kW'),
              if (report.intensite != null && report.intensite!.isNotEmpty)
                _buildMeasureChip(Icons.electrical_services, 'Intensité',
                    '${report.intensite} A'),
              if (report.tension != null && report.tension!.isNotEmpty)
                _buildMeasureChip(Icons.bolt, 'Tension', '${report.tension} V'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.orange.shade700),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade900,
          ),
        ),
      ],
    );
  }
}
