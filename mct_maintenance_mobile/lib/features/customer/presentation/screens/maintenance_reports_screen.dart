import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mct_maintenance_mobile/models/maintenance_report_model.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/widgets/common/support_fab_wrapper.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';
import 'package:mct_maintenance_mobile/widgets/common/authenticated_network_image.dart';

class MaintenanceReportsScreen extends StatefulWidget {
  const MaintenanceReportsScreen({super.key});

  @override
  State<MaintenanceReportsScreen> createState() =>
      _MaintenanceReportsScreenState();
}

class _MaintenanceReportsScreenState extends State<MaintenanceReportsScreen> {
  late final InterventionRepository _interventionRepository;
  bool _isLoading = true;
  List<MaintenanceReport> _reports = [];
  String? _error;
  final Set<String> _expandedReportIds = {};

  @override
  void initState() {
    super.initState();
    _interventionRepository = context.read<InterventionRepository>();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _interventionRepository.getMaintenanceReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
          if (reports.isNotEmpty) {
            _expandedReportIds.add(reports.first.id);
          }
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
    final dateFormat = DateFormat("dd/MM/yyyy HH'h'mm");
    final statusColor = _getStatusColor(report.status);
    final bool isExpanded = _expandedReportIds.contains(report.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête cliquable pour dérouler / réduire
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedReportIds.remove(report.id);
                  } else {
                    _expandedReportIds.add(report.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          report.reference ?? 'Sans référence',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatStatus(report.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF0a543d),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.title ?? 'Sans titre',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (report.description != null && report.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  report.description!,
                  maxLines: isExpanded ? 10 : 2,
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
                  const SizedBox(height: 6),
                  const Text(
                    'Notes du technicien:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    report.technicianNotes!,
                    maxLines: isExpanded ? 10 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            // Contenu détaillé (déroulant / réduisible avec flèche)
            if (isExpanded) ...[
              // Mesures techniques & Équipements 2-étapes
              if (_hasTechnicalMeasures(report))
                _buildTechnicalMeasuresSection(report),

              // Photos AVANT intervention
              if (report.photosBefore != null && report.photosBefore!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '📷 Photos AVANT intervention (${report.photosBefore!.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPhotoGallery(report.photosBefore!),
              ],

              // Photos APRÈS intervention
              if (report.photosAfter != null && report.photosAfter!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '📸 Photos APRÈS intervention (${report.photosAfter!.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPhotoGallery(report.photosAfter!),
              ],
              if ((report.photosBefore == null || report.photosBefore!.isEmpty) &&
                  (report.photosAfter == null || report.photosAfter!.isEmpty) &&
                  report.imageUrls != null && report.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPhotoGallery(report.imageUrls!),
              ],
            ],

            const SizedBox(height: 10),

            // Bouton barre inférieure pour dérouler / réduire
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedReportIds.remove(report.id);
                  } else {
                    _expandedReportIds.add(report.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? Colors.grey.shade100
                      : const Color(0xFF0a543d).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpanded
                        ? Colors.grey.shade300
                        : const Color(0xFF0a543d).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded
                          ? 'Réduire le rapport'
                          : 'Voir le rapport détaillé (Mesures & Photos)',
                      style: const TextStyle(
                        color: Color(0xFF0a543d),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF0a543d),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> rawPaths) {
    final urls = rawPaths.map((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) return path;
      final clean = path.startsWith('/') ? path : '/$path';
      return '${AppConfig.baseUrl}$clean';
    }).toList();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AuthenticatedNetworkImage(
                urls[index],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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
        (report.freon != null && report.freon!.isNotEmpty) ||
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
            const SizedBox(height: 6),
            Text(
              'État initial: ${equipment.state}',
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
            ),
          ],
          if (equipment.location != null && equipment.location!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Emplacement: ${equipment.location}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          if (equipment.functionalTest != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text('Test de bon fonctionnement: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                Text(
                  equipment.functionalTest == true ? 'Oui ✓' : 'Non ✗',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: equipment.functionalTest == true ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ],

          // Mesures techniques AVANT intervention (Constat initial)
          if (equipment.hasBeforeMeasures) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Données Techniques — AVANT Intervention',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                      if (equipment.beforePression != null && equipment.beforePression!.isNotEmpty)
                        _buildMeasureChip(Icons.compress, 'Pression', '${equipment.beforePression} bar', color: Colors.orange.shade900),
                      if (equipment.beforeFreon != null && equipment.beforeFreon!.isNotEmpty)
                        _buildMeasureChip(Icons.ac_unit, 'Fréon', '${equipment.beforeFreon}', color: Colors.orange.shade900),
                      if (equipment.beforePuissance != null && equipment.beforePuissance!.isNotEmpty)
                        _buildMeasureChip(Icons.power, 'Puissance', '${equipment.beforePuissance} CV', color: Colors.orange.shade900),
                      if (equipment.beforeIntensite != null && equipment.beforeIntensite!.isNotEmpty)
                        _buildMeasureChip(Icons.electrical_services, 'Intensité', '${equipment.beforeIntensite} A', color: Colors.orange.shade900),
                      if (equipment.beforeTension != null && equipment.beforeTension!.isNotEmpty)
                        _buildMeasureChip(Icons.bolt, 'Tension', '${equipment.beforeTension} V', color: Colors.orange.shade900),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Mesures techniques APRÈS intervention (Clôture finale)
          if (equipment.hasAfterMeasures) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Données Techniques — APRÈS Intervention',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (equipment.afterPression != null && equipment.afterPression!.isNotEmpty)
                        _buildMeasureChip(Icons.compress, 'Pression', '${equipment.afterPression} bar', color: Colors.green.shade800),
                      if (equipment.afterFreon != null && equipment.afterFreon!.isNotEmpty)
                        _buildMeasureChip(Icons.ac_unit, 'Fréon', '${equipment.afterFreon}', color: Colors.green.shade800),
                      if (equipment.afterPuissance != null && equipment.afterPuissance!.isNotEmpty)
                        _buildMeasureChip(Icons.power, 'Puissance', '${equipment.afterPuissance} CV', color: Colors.green.shade800),
                      if (equipment.afterIntensite != null && equipment.afterIntensite!.isNotEmpty)
                        _buildMeasureChip(Icons.electrical_services, 'Intensité', '${equipment.afterIntensite} A', color: Colors.green.shade800),
                      if (equipment.afterTension != null && equipment.afterTension!.isNotEmpty)
                        _buildMeasureChip(Icons.bolt, 'Tension', '${equipment.afterTension} V', color: Colors.green.shade800),
                    ],
                  ),
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
              if (report.freon != null && report.freon!.isNotEmpty)
                _buildMeasureChip(
                    Icons.ac_unit, 'Fréon', '${report.freon}'),
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

  Widget _buildMeasureChip(IconData icon, String label, String value, {Color? color}) {
    final activeColor = color ?? Colors.orange.shade800;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: activeColor),
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
            color: activeColor,
          ),
        ),
      ],
    );
  }
}
