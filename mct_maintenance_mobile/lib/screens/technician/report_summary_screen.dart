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
      await _apiService.submitInterventionReport(
        widget.intervention['id'],
        widget.reportData,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Rapport soumis avec succès au client et à l\'admin',
          emoji: '✅',
          duration: const Duration(seconds: 3),
        );

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

    // Créer le message de partage
    String materialsText = '';
    if (materials.isNotEmpty) {
      materialsText = '\n📦 Matériaux utilisés:\n';
      for (var material in materials) {
        materialsText +=
            '  • ${material['name']} - Qté: ${material['quantity']} - ${material['unit_price']} FCFA\n';
      }
    }

    final String shareText = '''
🔧 RAPPORT D'INTERVENTION - MCT MAINTENANCE

Intervention #${intervention['id']}
${intervention['title'] ?? 'Sans titre'}

📅 Date: ${dateFormat.format(DateTime.now())}
⏱️ Durée: ${duration}h

📝 Description des travaux:
$workDescription

${observations.isNotEmpty ? '💡 Observations:\n$observations\n' : ''}
$materialsText
---
MCT Maintenance - Service de qualité
    '''
        .trim();

    // Obtenir la position du bouton pour iOS
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    Share.share(
      shareText,
      subject:
          'Rapport d\'intervention #${intervention['id']} - MCT Maintenance',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = widget.reportData['materials_used'] as List? ?? [];
    final duration = widget.reportData['duration'] ?? 0;
    final observations = widget.reportData['observations'] ?? '';
    final workDescription = widget.reportData['work_description'] ?? '';
    final photos = widget.reportData['photos'] as List? ?? [];

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
                        _buildInfoRow('Titre', widget.intervention['title']),
                        _buildInfoRow(
                            'Client', widget.intervention['customer'] ?? 'N/A'),
                        _buildInfoRow(
                            'Adresse', widget.intervention['address'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Travail effectué
                  _buildSection(
                    'Travail Effectué',
                    Icons.construction,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workDescription,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Durée
                  if (duration > 0) ...[
                    _buildSection(
                      'Durée de l\'Intervention',
                      Icons.access_time,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '$duration minutes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Matériaux
                  if (materials.isNotEmpty) ...[
                    _buildSection(
                      'Matériaux Utilisés',
                      Icons.inventory_2,
                      Column(
                        children: materials.map((material) {
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
                                    material['name'] ?? material.toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                if (material is Map &&
                                    material['quantity'] != null)
                                  Text(
                                    'x${material['quantity']} ${material['unit'] ?? ''}',
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

                  // Observations
                  if (observations.isNotEmpty) ...[
                    _buildSection(
                      'Observations / Recommandations',
                      Icons.comment,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          observations,
                          style: const TextStyle(fontSize: 15),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
}
