import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class ViewReportScreen extends StatelessWidget {
  final Map<String, dynamic> intervention;

  const ViewReportScreen({
    super.key,
    required this.intervention,
  });

  Map<String, dynamic> get _report {
    // Parser le JSON stocké dans report_data
    if (intervention['report_data'] != null) {
      if (intervention['report_data'] is String) {
        // Si c'est une string JSON, la parser
        try {
          return json.decode(intervention['report_data'])
              as Map<String, dynamic>;
        } catch (e) {
          print('❌ Erreur parsing JSON report_data: $e');
          return {};
        }
      } else if (intervention['report_data'] is Map) {
        return intervention['report_data'] as Map<String, dynamic>;
      }
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final hasReport = report.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport d\'Intervention'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          // Bouton de partage
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager le rapport',
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: !hasReport
          ? _buildNoReport()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec statut
                    _buildStatusBadge(report['status'] ?? 'submitted'),
                    const SizedBox(height: 24),

                    // Informations intervention
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Date de soumission
                    if (intervention['report_submitted_at'] != null)
                      _buildInfoRow(
                        '📅 Rapport soumis le',
                        _formatDate(intervention['report_submitted_at']),
                      ),
                    const SizedBox(height: 24),

                    // Travail effectué
                    _buildSection(
                      'Travail Effectué',
                      Icons.construction,
                      report['work_description'] ?? 'Non renseigné',
                    ),
                    const SizedBox(height: 24),

                    // Durée
                    if (report['duration'] != null &&
                        (int.tryParse(report['duration'].toString()) ?? 0) > 0)
                      _buildSection(
                        'Durée de l\'Intervention',
                        Icons.access_time,
                        '${report['duration']} minutes',
                      ),
                    const SizedBox(height: 24),

                    // Matériaux utilisés
                    if (report['materials_used'] != null &&
                        (report['materials_used'] as List).isNotEmpty)
                      _buildMaterialsSection(
                        report['materials_used'] as List<dynamic>,
                      ),
                    const SizedBox(height: 24),

                    // Photos
                    if (report['photos_count'] != null &&
                        report['photos_count'] > 0)
                      _buildPhotosSection(report['photos_count']),
                    const SizedBox(height: 24),

                    // Observations
                    if (report['observations'] != null &&
                        (report['observations'] as String).isNotEmpty)
                      _buildSection(
                        'Observations / Recommandations',
                        Icons.comment,
                        report['observations'],
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoReport() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun rapport disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le rapport n\'a pas encore été soumis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'submitted':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        label = 'Soumis';
        icon = Icons.send;
        break;
      case 'approved':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = 'Approuvé';
        icon = Icons.check_circle;
        break;
      case 'draft':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'Brouillon';
        icon = Icons.edit;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFF0a543d)),
                const SizedBox(width: 8),
                const Text(
                  'Intervention',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0a543d),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Titre', intervention['title'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Client', intervention['customer'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Adresse', intervention['address'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Date',
              intervention['scheduled_date'] != null
                  ? _formatDate(intervention['scheduled_date'])
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0a543d), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsSection(List<dynamic> materials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inventory_2,
              color: Color(0xFF0a543d),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Matériaux Utilisés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...materials.asMap().entries.map((entry) {
          final index = entry.key;
          final material = entry.value as Map<String, dynamic>;
          return Container(
            margin:
                EdgeInsets.only(bottom: index < materials.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Color(0xFF0a543d),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${material['quantity']} ${material['unit']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPhotosSection(int photosCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library,
              color: Color(0xFF0a543d),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.image, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                '$photosCount photo${photosCount > 1 ? 's' : ''} jointe${photosCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Les photos sont stockées sur le serveur',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _shareReport(BuildContext context) {
    final report = _report;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    final materials = report['materials_used'] as List? ?? [];
    final duration = report['duration'] ?? 0;
    final observations = report['observations'] ?? '';
    final workDescription = report['work_description'] ?? '';

    // Créer le message de partage
    String materialsText = '';
    if (materials.isNotEmpty) {
      materialsText = '\n📦 Matériaux utilisés:\n';
      for (var material in materials) {
        materialsText +=
            '  • ${material['name']} - Qté: ${material['quantity']} - ${material['unit_price']} FCFA\n';
      }
    }

    // Calculer le total des matériaux
    double totalMaterials = 0;
    for (var material in materials) {
      final quantity = material['quantity'] ?? 0;
      final unitPrice = material['unit_price'] ?? 0;
      totalMaterials += (quantity * unitPrice);
    }

    final String shareText = '''
🔧 RAPPORT D'INTERVENTION - MCT MAINTENANCE

Intervention #${intervention['id']}
${intervention['title'] ?? 'Sans titre'}

📅 Date: ${intervention['report_submitted_at'] != null ? dateFormat.format(DateTime.parse(intervention['report_submitted_at'])) : dateFormat.format(DateTime.now())}
⏱️ Durée: ${duration}h

📝 Description des travaux:
$workDescription

${observations.isNotEmpty ? '💡 Observations:\n$observations\n' : ''}
$materialsText
${materials.isNotEmpty ? '\n💰 Total matériaux: ${totalMaterials.toStringAsFixed(0)} FCFA\n' : ''}
---
MCT Maintenance - Service de qualité
Rapport officiel soumis
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        if (date.isEmpty) return 'N/A';
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dateTime);
    } catch (e) {
      print('❌ Erreur formatage date: $e, date=$date');
      return 'Date invalide';
    }
  }
}
