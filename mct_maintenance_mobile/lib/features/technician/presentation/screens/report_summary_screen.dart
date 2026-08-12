import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/config/environment.dart' show AppConfig;
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';
import 'package:mct_maintenance_mobile/widgets/common/authenticated_network_image.dart';

class ReportSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;
  final Map<String, dynamic> reportData;

  const ReportSummaryScreen({
    super.key,
    required this.intervention,
    required this.reportData,
  });

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  late final InterventionRepository _interventionRepository;
  bool _isLoading = false;

  static const Map<String, String> _taskLabels = {
    'filtres_air': 'Nettoyage des filtres à air',
    'batterie_evaporateur': 'Nettoyage de la batterie évaporateur',
    'bacs_condensat': 'Nettoyage des bacs à condensat',
    'turbine': 'Nettoyage de la turbine',
    'condenseur': 'Nettoyage du condenseur',
    'carrosserie_evaporateur': 'Nettoyage de la carrosserie évaporateur',
    'tuyauterie_evacuation':
        'Soufflement à forte pression de la tuyauterie d\'évacuation des condensats',
    'parties_electriques': 'Nettoyage des parties électriques',
    'volets_air': 'Nettoyage des volets d\'air',
  };

  @override
  void initState() {
    super.initState();
    _interventionRepository = context.read<InterventionRepository>();
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);

    try {
      final response = await _interventionRepository.submitInterventionReport(
        widget.intervention['id'],
        widget.reportData,
      );

      if (mounted) {
        if (response['queued'] == true) {
          SnackBarHelper.showSuccess(
            context,
            response['message'] ?? 'Rapport enregistré (sera synchronisé)',
            emoji: '📦',
            duration: const Duration(seconds: 4),
          );
        } else {
          SnackBarHelper.showSuccess(
            context,
            'Rapport soumis avec succès au client et à l\'admin',
            emoji: '✅',
            duration: const Duration(seconds: 3),
          );
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          'Erreur lors de la soumission: $e',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  void _shareReport() {
    final dateFormat = DateFormat("dd/MM/yyyy HH'h'mm", 'fr_FR');
    final intervention = widget.intervention;
    final reportData = widget.reportData;

    final materials = reportData['materials_used'] as List? ?? [];
    final duration = reportData['duration'] ?? 0;
    final observations = reportData['observations'] ?? '';
    final workDescription = reportData['work_description'] ?? '';

    String materialsText = '';
    if (materials.isNotEmpty) {
      materialsText = '\n📦 Matériaux utilisés:\n';
      for (var material in materials) {
        materialsText +=
            '  • ${material['name']} - Qté: ${material['quantity']}\n';
      }
    }

    final String shareText = '''
🔧 RAPPORT D'INTERVENTION - SMART MAINTENANCE

Intervention #${intervention['id']}
${intervention['title'] ?? 'Sans titre'}

📅 Date: ${dateFormat.format(DateTime.now())}
⏱️ Durée: ${duration}min

📝 Description des travaux:
$workDescription
${observations.isNotEmpty ? '\n💡 Observations:\n$observations\n' : ''}
$materialsText
---
Smart Maintenance - Service de qualité
    '''
        .trim();

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    Share.share(
      shareText,
      subject:
          'Rapport d\'intervention #${intervention['id']} - Smart Maintenance',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  String _getCustomerName() {
    final customer = widget.intervention['customer'];
    if (customer == null) return 'N/A';

    if (customer is Map) {
      final firstName = customer['first_name'] ?? '';
      final lastName = customer['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }

    return customer.toString();
  }

  Widget _buildPhotoThumbnail(String rawPath) {
    final pathLower = rawPath.toLowerCase();
    final isVideo = pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.avi');
    final isNetwork = rawPath.startsWith('http://') ||
        rawPath.startsWith('https://') ||
        rawPath.startsWith('/uploads/');

    if (isVideo) {
      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 28, color: Colors.grey.shade600),
            const SizedBox(height: 2),
            Text('Vidéo',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      );
    } else if (isNetwork) {
      final fullUrl = rawPath.startsWith('/uploads/')
          ? '${AppConfig.baseUrl}$rawPath'
          : rawPath;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AuthenticatedNetworkImage(
          fullUrl,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 84,
            height: 84,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(rawPath),
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 84,
            height: 84,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportData = widget.reportData;
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    // Équipements
    final List<dynamic> equipments = reportData['equipments'] as List? ?? [];

    // Fallback legacy
    final equipmentState = reportData['equipment_state']?.toString() ?? '';
    final equipmentType = reportData['equipment_type']?.toString() ?? '';
    final equipmentBrand = reportData['equipment_brand']?.toString() ?? '';

    final hasEquipmentInfo = equipments.isNotEmpty ||
        equipmentState.isNotEmpty ||
        equipmentType.isNotEmpty ||
        equipmentBrand.isNotEmpty;

    // Travaux effectués & Photos
    final tasksDone = reportData['tasks_done'] as Map?;
    final photosBefore = (reportData['photos_before'] as List?) ?? [];
    final photosAfter = (reportData['photos_after'] as List?) ?? [];
    final photos = (reportData['photos'] as List?) ?? [];

    // Détails
    final technicianName = reportData['technician_name']?.toString() ?? '';
    final interventionDateStr = reportData['intervention_date']?.toString();
    DateTime? interventionDate;
    if (interventionDateStr != null && interventionDateStr.isNotEmpty) {
      try {
        interventionDate = DateTime.parse(interventionDateStr);
      } catch (_) {}
    }
    final startTime = reportData['start_time']?.toString() ?? '';
    final endTime = reportData['end_time']?.toString() ?? '';
    final duration = reportData['duration'] ?? 0;
    final interventionNature = reportData['intervention_nature']?.toString() ??
        reportData['work_description']?.toString() ??
        '';
    final observations = reportData['observations']?.toString() ?? '';

    final spareParts = reportData['spare_parts'] as List? ??
        reportData['materials_used'] as List? ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récapitulatif du Rapport'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager le rapport',
            onPressed: _shareReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vérifiez les informations avant de soumettre au client et à l\'admin',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations intervention
                  _buildSection(
                    'Intervention',
                    Icons.assignment,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.title, 'Titre', widget.intervention['title']),
                        _buildInfoRow(
                            Icons.person, 'Client', _getCustomerName()),
                        _buildInfoRow(Icons.location_on, 'Adresse',
                            widget.intervention['address'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // === SECTION ÉQUIPEMENTS ===
                  if (hasEquipmentInfo) ...[
                    _buildSection(
                      'Équipements (${equipments.isNotEmpty ? equipments.length : 1})',
                      Icons.build,
                      equipments.isNotEmpty
                          ? Column(
                              children: [
                                for (int i = 0; i < equipments.length; i++) ...[
                                  _buildEquipmentCard(
                                      Map<String, dynamic>.from(equipments[i]),
                                      i + 1),
                                  if (i < equipments.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            )
                          : _buildEquipmentCard(reportData, 1),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // === SECTION TRAVAUX EFFECTUÉS ===
                  if (tasksDone != null && tasksDone.isNotEmpty) ...[
                    _buildSection(
                      'Travaux Effectués',
                      Icons.checklist,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  const Color(0xFF0a543d).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var entry in _taskLabels.entries)
                              if (tasksDone[entry.key] == true)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Color(0xFF0a543d), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // === SECTION PHOTOS & MÉDIAS ===
                  if (photosBefore.isNotEmpty ||
                      photosAfter.isNotEmpty ||
                      photos.isNotEmpty) ...[
                    _buildSection(
                      'Photos & Médias',
                      Icons.photo_library,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photosBefore.isNotEmpty) ...[
                            const Text(
                              '📸 Photos AVANT intervention',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0a543d)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: photosBefore
                                  .map((p) =>
                                      _buildPhotoThumbnail(p.toString()))
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (photosAfter.isNotEmpty) ...[
                            Text(
                              '📸 Photos APRÈS intervention',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.orange.shade900),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: photosAfter
                                  .map((p) =>
                                      _buildPhotoThumbnail(p.toString()))
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (photosBefore.isEmpty &&
                              photosAfter.isEmpty &&
                              photos.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: photos
                                  .map((p) =>
                                      _buildPhotoThumbnail(p.toString()))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // === SECTION DÉTAIL DE L'INTERVENTION ===
                  _buildSection(
                    'Détail de l\'Intervention',
                    Icons.assignment,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (technicianName.isNotEmpty) ...[
                            _buildInfoRow(
                                Icons.person, 'Technicien', technicianName),
                            const SizedBox(height: 8),
                          ],
                          if (interventionDate != null) ...[
                            _buildInfoRow(
                                Icons.calendar_today,
                                'Date intervention',
                                dateFormat.format(interventionDate)),
                            const SizedBox(height: 8),
                          ],
                          if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                            _buildInfoRow(
                              Icons.access_time,
                              'Horaires',
                              '${startTime.isNotEmpty ? startTime : "--"} - ${endTime.isNotEmpty ? endTime : "--"}',
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (duration > 0) ...[
                            _buildInfoRow(
                                Icons.timer, 'Durée', '$duration minutes'),
                            const SizedBox(height: 8),
                          ],
                          if (interventionNature.isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              'Nature de l\'intervention',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              interventionNature,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                          if (observations.isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              'Observations / Recommandations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              observations,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // === SECTION PIÈCES DE RECHANGE ===
                  if (spareParts.isNotEmpty) ...[
                    _buildSection(
                      'Pièces de Rechange',
                      Icons.inventory_2,
                      Column(
                        children: spareParts.map((part) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF0a543d), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    part is Map
                                        ? (part['name'] ?? part.toString())
                                        : part.toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                if (part is Map && part['quantity'] != null)
                                  Text(
                                    'x${part['quantity']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context, false),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text(
                            'Modifier',
                            style: TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0a543d),
                            side: const BorderSide(color: Color(0xFF0a543d)),
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitReport,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(
                            _isLoading ? 'Envoi...' : 'Soumettre le rapport',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0a543d),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0a543d), size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment, int index) {
    final state = (equipment['state'] ?? equipment['equipment_state'])?.toString() ?? '';
    final type = (equipment['type'] ?? equipment['equipment_type'])?.toString() ?? '';
    final name = (equipment['name'] ?? equipment['equipment_name'])?.toString() ?? '';
    final brand = (equipment['brand'] ?? equipment['equipment_brand'])?.toString() ?? '';
    final location = equipment['location']?.toString() ?? '';
    final tested = equipment['tested'];

    // Données techniques AVANT
    final bPression = (equipment['before_pression'] ?? equipment['pression'])?.toString() ?? '';
    final bPuissance = (equipment['before_puissance'] ?? equipment['puissance'])?.toString() ?? '';
    final bIntensite = (equipment['before_intensite'] ?? equipment['intensite'])?.toString() ?? '';
    final bTension = (equipment['before_tension'] ?? equipment['tension'])?.toString() ?? '';
    final bFreon = (equipment['before_freon'] ?? equipment['freon'])?.toString() ?? '';

    final hasBeforeMeasures = bPression.isNotEmpty ||
        bPuissance.isNotEmpty ||
        bIntensite.isNotEmpty ||
        bTension.isNotEmpty ||
        bFreon.isNotEmpty;

    // Données techniques APRÈS
    final aPression = equipment['after_pression']?.toString() ?? '';
    final aPuissance = equipment['after_puissance']?.toString() ?? '';
    final aIntensite = equipment['after_intensite']?.toString() ?? '';
    final aTension = equipment['after_tension']?.toString() ?? '';
    final aFreon = equipment['after_freon']?.toString() ?? '';

    final hasAfterMeasures = aPression.isNotEmpty ||
        aPuissance.isNotEmpty ||
        aIntensite.isNotEmpty ||
        aTension.isNotEmpty ||
        aFreon.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isNotEmpty
                      ? name
                      : brand.isNotEmpty
                          ? '$brand - $type'
                          : 'Équipement $index',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isNotEmpty) ...[
            _buildInfoRow(Icons.settings, 'État', state),
            const SizedBox(height: 8),
          ],
          if (type.isNotEmpty) ...[
            _buildInfoRow(Icons.category, 'Type', type),
            const SizedBox(height: 8),
          ],
          if (brand.isNotEmpty) ...[
            _buildInfoRow(Icons.branding_watermark, 'Marque', brand),
            const SizedBox(height: 8),
          ],
          if (location.isNotEmpty) ...[
            _buildInfoRow(Icons.place, 'Emplacement', location),
            const SizedBox(height: 8),
          ],
          if (tested != null) ...[
            _buildInfoRow(Icons.playlist_add_check, 'Test équipement',
                tested == true ? 'Oui' : 'Non'),
            const SizedBox(height: 8),
          ],

          if (hasBeforeMeasures) ...[
            const Divider(),
            Text(
              '🟠 Données Techniques — AVANT Intervention',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (bPuissance.isNotEmpty)
                  _buildMeasureItem(Icons.power, 'Puissance', '$bPuissance CV', Colors.orange.shade800),
                if (bPression.isNotEmpty)
                  _buildMeasureItem(
                      Icons.compress, 'Pression', '$bPression bar', Colors.orange.shade800),
                if (bIntensite.isNotEmpty)
                  _buildMeasureItem(
                      Icons.electrical_services, 'Intensité', '$bIntensite A', Colors.orange.shade800),
                if (bTension.isNotEmpty)
                  _buildMeasureItem(Icons.bolt, 'Tension', '$bTension V', Colors.orange.shade800),
                if (bFreon.isNotEmpty)
                  _buildMeasureItem(Icons.cloud, 'Fréon', bFreon, Colors.orange.shade800),
              ],
            ),
          ],

          if (hasAfterMeasures) ...[
            const Divider(),
            const Text(
              '🟢 Données Techniques — APRÈS Intervention',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (aPuissance.isNotEmpty)
                  _buildMeasureItem(Icons.power, 'Puissance', '$aPuissance CV', const Color(0xFF0a543d)),
                if (aPression.isNotEmpty)
                  _buildMeasureItem(
                      Icons.compress, 'Pression', '$aPression bar', const Color(0xFF0a543d)),
                if (aIntensite.isNotEmpty)
                  _buildMeasureItem(
                      Icons.electrical_services, 'Intensité', '$aIntensite A', const Color(0xFF0a543d)),
                if (aTension.isNotEmpty)
                  _buildMeasureItem(Icons.bolt, 'Tension', '$aTension V', const Color(0xFF0a543d)),
                if (aFreon.isNotEmpty)
                  _buildMeasureItem(Icons.cloud, 'Fréon', aFreon, const Color(0xFF0a543d)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasureItem(IconData icon, String label, String value, [Color? color]) {
    final itemColor = color ?? Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: itemColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: itemColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: itemColor, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
