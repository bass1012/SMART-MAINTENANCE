import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_helper.dart';

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
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.submitInterventionReport(
        widget.intervention['id'],
        widget.reportData,
      );

      if (mounted) {
        // Vérifier si le rapport a été mis en queue (mode offline)
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

        // Retourner avec succès (2 pops pour revenir à l'écran de détail)
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final intervention = widget.intervention;
    final reportData = widget.reportData;

    final materials = reportData['materials_used'] as List? ?? [];
    final duration = reportData['duration'] ?? 0;
    final observations = reportData['observations'] ?? '';
    final workDescription = reportData['work_description'] ?? '';

    // Mesures techniques
    final pression = reportData['pression'] ?? '';
    final puissance = reportData['puissance'] ?? '';
    final intensite = reportData['intensite'] ?? '';
    final tension = reportData['tension'] ?? '';

    // Créer le message de partage
    String materialsText = '';
    if (materials.isNotEmpty) {
      materialsText = '\n📦 Matériaux utilisés:\n';
      for (var material in materials) {
        materialsText +=
            '  • ${material['name']} - Qté: ${material['quantity']} - ${material['unit_price']} FCFA\n';
      }
    }

    // Mesures techniques texte
    String measuresText = '';
    if (pression.toString().isNotEmpty ||
        puissance.toString().isNotEmpty ||
        intensite.toString().isNotEmpty ||
        tension.toString().isNotEmpty) {
      measuresText = '\n📊 Mesures techniques:\n';
      if (pression.toString().isNotEmpty)
        measuresText += '  • Pression: $pression bar\n';
      if (puissance.toString().isNotEmpty)
        measuresText += '  • Puissance: $puissance CV\n';
      if (intensite.toString().isNotEmpty)
        measuresText += '  • Intensité: $intensite A\n';
      if (tension.toString().isNotEmpty)
        measuresText += '  • Tension: $tension V\n';
    }

    final String shareText = '''
🔧 RAPPORT D'INTERVENTION - SMART MAINTENANCE

Intervention #${intervention['id']}
${intervention['title'] ?? 'Sans titre'}

📅 Date: ${dateFormat.format(DateTime.now())}
⏱️ Durée: ${duration}h

📝 Description des travaux:
$workDescription
$measuresText
${observations.isNotEmpty ? '💡 Observations:\n$observations\n' : ''}
$materialsText
---
Smart Maintenance - Service de qualité
    '''
        .trim();

    // Obtenir la position du bouton pour iOS
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

  @override
  Widget build(BuildContext context) {
    final reportData = widget.reportData;
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    // === SECTION ÉQUIPEMENTS (nouveau format) ===
    final List<dynamic> equipments = reportData['equipments'] as List? ?? [];

    // === SECTION ÉQUIPEMENT (format legacy pour rétrocompatibilité) ===
    final equipmentState = reportData['equipment_state']?.toString() ?? '';
    final equipmentType = reportData['equipment_type']?.toString() ?? '';
    final equipmentBrand = reportData['equipment_brand']?.toString() ?? '';
    final pression = reportData['pression']?.toString() ?? '';
    final puissance = reportData['puissance']?.toString() ?? '';
    final intensite = reportData['intensite']?.toString() ?? '';
    final tension = reportData['tension']?.toString() ?? '';

    final hasEquipmentInfo = equipments.isNotEmpty ||
        equipmentState.isNotEmpty ||
        equipmentType.isNotEmpty ||
        equipmentBrand.isNotEmpty;
    final hasTechnicalMeasures = pression.isNotEmpty ||
        puissance.isNotEmpty ||
        intensite.isNotEmpty ||
        tension.isNotEmpty;

    // === SECTION DÉTAIL INTERVENTION ===
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

    // === SECTION PIÈCES DE RECHANGE ===
    final spareParts = reportData['spare_parts'] as List? ??
        reportData['materials_used'] as List? ??
        [];

    // Photos
    final photos = reportData['photos'] as List? ?? [];

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
            // Bannière d'information
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
                  if (hasEquipmentInfo || hasTechnicalMeasures) ...[
                    _buildSection(
                      'Équipements (${equipments.isNotEmpty ? equipments.length : 1})',
                      Icons.build,
                      equipments.isNotEmpty
                          ? Column(
                              children: [
                                for (int i = 0; i < equipments.length; i++) ...[
                                  _buildEquipmentCard(equipments[i], i + 1),
                                  if (i < equipments.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (equipmentState.isNotEmpty) ...[
                                    _buildInfoRow(Icons.settings,
                                        'État équipement', equipmentState),
                                    const SizedBox(height: 8),
                                  ],
                                  if (equipmentType.isNotEmpty) ...[
                                    _buildInfoRow(
                                        Icons.category, 'Type', equipmentType),
                                    const SizedBox(height: 8),
                                  ],
                                  if (equipmentBrand.isNotEmpty) ...[
                                    _buildInfoRow(Icons.branding_watermark,
                                        'Marque', equipmentBrand),
                                    const SizedBox(height: 8),
                                  ],
                                  if (hasTechnicalMeasures) ...[
                                    const Divider(),
                                    const Text(
                                      'Mesures Techniques',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: [
                                        if (pression.isNotEmpty)
                                          _buildMeasureItem(
                                            Icons.compress,
                                            'Pression',
                                            '$pression bar',
                                          ),
                                        if (puissance.isNotEmpty)
                                          _buildMeasureItem(
                                            Icons.power,
                                            'Puissance',
                                            '$puissance CV',
                                          ),
                                        if (intensite.isNotEmpty)
                                          _buildMeasureItem(
                                            Icons.electrical_services,
                                            'Intensité',
                                            '$intensite A',
                                          ),
                                        if (tension.isNotEmpty)
                                          _buildMeasureItem(
                                            Icons.bolt,
                                            'Tension',
                                            '$tension V',
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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
                                Icon(Icons.check_circle,
                                    color: const Color(0xFF0a543d), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    part['name'] ?? part.toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                if (part is Map && part['quantity'] != null)
                                  Text(
                                    'x${part['quantity']} ${part['unit'] ?? ''}',
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

                  // Photos
                  if (photos.isNotEmpty) ...[
                    _buildSection(
                      'Photos',
                      Icons.photo_library,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '${photos.length} photo(s) jointe(s)',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Boutons d'action
                  Row(
                    children: [
                      // Bouton Modifier
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
                      // Bouton Soumettre
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
                            _isLoading ? 'Soumission...' : 'Soumettre',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0a543d),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message d'information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_active,
                            color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Une notification sera envoyée au client et à l\'administrateur après la soumission',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            Icon(icon, color: const Color(0xFF0a543d), size: 24),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0a543d), size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une carte d'équipement dans le récapitulatif
  Widget _buildEquipmentCard(dynamic equipment, int index) {
    final state = equipment['state']?.toString() ?? '';
    final type = equipment['type']?.toString() ?? '';
    final brand = equipment['brand']?.toString() ?? '';
    final pression = equipment['pression']?.toString() ?? '';
    final puissance = equipment['puissance']?.toString() ?? '';
    final intensite = equipment['intensite']?.toString() ?? '';
    final tension = equipment['tension']?.toString() ?? '';

    final hasMeasures = pression.isNotEmpty ||
        puissance.isNotEmpty ||
        intensite.isNotEmpty ||
        tension.isNotEmpty;

    return Container(
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
                  brand.isNotEmpty ? '$brand - $type' : 'Équipement $index',
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
          if (hasMeasures) ...[
            const Divider(),
            const Text(
              'Mesures Techniques',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (pression.isNotEmpty)
                  _buildMeasureItem(
                      Icons.compress, 'Pression', '$pression bar'),
                if (puissance.isNotEmpty)
                  _buildMeasureItem(Icons.power, 'Puissance', '$puissance CV'),
                if (intensite.isNotEmpty)
                  _buildMeasureItem(
                      Icons.electrical_services, 'Intensité', '$intensite A'),
                if (tension.isNotEmpty)
                  _buildMeasureItem(Icons.bolt, 'Tension', '$tension V'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasureItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
