import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';

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
          if (kDebugMode) debugPrint('❌ Erreur parsing JSON report_data: $e');
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

                    // Équipements ou Mesures techniques
                    if (_getEquipments(report).isNotEmpty) ...[
                      _buildEquipmentsSection(
                        _getEquipments(report),
                      ),
                    ] else if (_hasTechnicalMeasures(report)) ...[
                      _buildTechnicalMeasuresSection(report),
                    ],
                    const SizedBox(height: 24),

                    // Travaux effectués
                    if (report['tasks_done'] != null) ...[
                      _buildTasksDoneSection(report['tasks_done']),
                      const SizedBox(height: 24),
                    ],

                    // Matériaux utilisés
                    if (report['materials_used'] != null &&
                        (report['materials_used'] as List).isNotEmpty)
                      _buildMaterialsSection(
                        report['materials_used'] as List<dynamic>,
                      ),
                    const SizedBox(height: 24),

                    // Photos
                    _buildPhotosGallerySection(report, intervention),
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
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
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
            _buildInfoRow('Client', _getCustomerName(intervention['customer'])),
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

  Widget _buildTasksDoneSection(dynamic tasksData) {
    if (tasksData == null || tasksData is! Map || tasksData.isEmpty) {
      return const SizedBox.shrink();
    }

    const taskLabels = {
      'filtres_air': 'Nettoyage des filtres à air',
      'batterie_evaporateur': 'Nettoyage de la batterie évaporateur',
      'bacs_condensat': 'Nettoyage des bacs à condensat',
      'turbine': 'Nettoyage de la turbine',
      'volets_air': 'Nettoyage des volets d\'air',
      'carrosserie_evaporateur': 'Nettoyage de la carrosserie évaporateur',
      'tuyauterie_evacuation':
          'Soufflement à forte pression de la tuyauterie d\'évacuation des condensats',
    };

    final hasCheckedTask = taskLabels.keys.any((key) => tasksData[key] == true);
    if (!hasCheckedTask) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, color: Color(0xFF0a543d), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Travaux Effectués',
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
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0a543d).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0a543d).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var entry in taskLabels.entries)
                if (tasksData[entry.key] == true)
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
                    color: const Color(0xFF0a543d).withValues(alpha: 0.1),
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
        }),
      ],
    );
  }

  Widget _buildPhotosGallerySection(dynamic photosData, [dynamic extraImages]) {
    final List<String> imageUrls = [];

    void extractUrls(dynamic data) {
      if (data == null) return;
      if (data is String) {
        final str = data.trim();
        if (str.startsWith('[')) {
          try {
            final List decoded = json.decode(str);
            for (var item in decoded) {
              extractUrls(item);
            }
            return;
          } catch (_) {}
        }
        if (str.isNotEmpty) {
          if (str.startsWith('http://') || str.startsWith('https://')) {
            imageUrls.add(str);
          } else {
            final clean = str.startsWith('/') ? str : '/$str';
            imageUrls.add('${AppConfig.baseUrl}$clean');
          }
        }
      } else if (data is Map) {
        extractUrls(data['image_url'] ?? data['url'] ?? data['path']);
      } else if (data is List) {
        for (var item in data) {
          extractUrls(item);
        }
      }
    }

    extractUrls(photosData);
    extractUrls(extraImages);

    final uniqueUrls = imageUrls.toSet().toList();

    if (uniqueUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFF0a543d),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Photos (${uniqueUrls.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: uniqueUrls.length,
            itemBuilder: (context, index) {
              final url = uniqueUrls[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _openImageDialog(context, url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                                SizedBox(height: 4),
                                Text(
                                  'Non disponible',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 12),
                          Text('Erreur de chargement de l\'image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReport(BuildContext context) {
    final report = _report;
    final dateFormat = DateFormat("dd/MM/yyyy HH'h'mm", 'fr_FR');

    final materials = report['materials_used'] as List? ?? [];
    final duration = report['duration'] ?? 0;
    final observations = report['observations'] ?? '';
    final workDescription = report['work_description'] ?? '';

    // Mesures techniques
    final pression = report['pression']?.toString() ?? '';
    final temperature = report['temperature']?.toString() ?? '';
    final intensite = report['intensite']?.toString() ?? '';
    final tension = report['tension']?.toString() ?? '';

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

    // Mesures techniques texte
    String measuresText = '';
    if (pression.isNotEmpty ||
        temperature.isNotEmpty ||
        intensite.isNotEmpty ||
        tension.isNotEmpty) {
      measuresText = '\n📊 Mesures techniques:\n';
      if (pression.isNotEmpty) measuresText += '  • Pression: $pression bar\n';
      if (temperature.isNotEmpty) {
        measuresText += '  • Température: $temperature °C\n';
      }
      if (intensite.isNotEmpty) measuresText += '  • Intensité: $intensite A\n';
      if (tension.isNotEmpty) measuresText += '  • Tension: $tension V\n';
    }

    final String shareText = '''
🔧 RAPPORT D'INTERVENTION - MCT MAINTENANCE

Intervention #${intervention['id']}
${intervention['title'] ?? 'Sans titre'}

📅 Date: ${intervention['report_submitted_at'] != null ? dateFormat.format(DateTime.parse(intervention['report_submitted_at'])) : dateFormat.format(DateTime.now())}
⏱️ Durée: ${duration}h

📝 Description des travaux:
$workDescription
$measuresText
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

  String _getCustomerName(dynamic customer) {
    if (customer == null) return 'N/A';
    if (customer is String) return customer;
    if (customer is Map) {
      final firstName = customer['first_name'] ?? '';
      final lastName = customer['last_name'] ?? '';
      final name = '$firstName $lastName'.trim();
      return name.isNotEmpty ? name : (customer['email'] ?? 'N/A');
    }
    return 'N/A';
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
      return DateFormat("dd/MM/yyyy à HH'h'mm", 'fr_FR').format(dateTime);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur formatage date: $e, date=$date');
      return 'Date invalide';
    }
  }

  List<dynamic> _getEquipments(Map<String, dynamic> report) {
    final equipments = report['equipments'];
    if (equipments == null) return [];
    if (equipments is List) return equipments;
    if (equipments is String) {
      try {
        final decoded = json.decode(equipments);
        if (decoded is List) return decoded;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  bool _hasTechnicalMeasures(Map<String, dynamic> report) {
    final pression = report['pression']?.toString() ?? '';
    final puissance = report['puissance']?.toString() ??
        report['temperature']?.toString() ??
        '';
    final intensite = report['intensite']?.toString() ?? '';
    final tension = report['tension']?.toString() ?? '';
    final freon = report['freon']?.toString() ?? '';
    return pression.isNotEmpty ||
        puissance.isNotEmpty ||
        intensite.isNotEmpty ||
        tension.isNotEmpty ||
        freon.isNotEmpty;
  }

  Widget _buildEquipmentsSection(List<dynamic> equipments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.kitchen, color: const Color(0xFF0a543d), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Équipements & Mesures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...equipments.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildEquipmentCard(entry.value, entry.key + 1),
          );
        }),
      ],
    );
  }

  Widget _buildEquipmentCard(dynamic equipment, int index) {
    final eqMap = equipment is Map ? equipment : {};
    final state = (eqMap['state'] ?? eqMap['equipment_state'])?.toString() ?? '';
    final type = (eqMap['type'] ?? eqMap['equipment_type'])?.toString() ?? '';
    final name = (eqMap['name'] ?? eqMap['equipment_name'])?.toString() ?? '';
    final brand = (eqMap['brand'] ?? eqMap['equipment_brand'])?.toString() ?? '';
    final location = eqMap['location']?.toString() ?? '';
    final tested = eqMap['tested'];

    // Données techniques AVANT
    final bPression = (eqMap['before_pression'] ?? eqMap['pression'])?.toString() ?? '';
    final bPuissance = (eqMap['before_puissance'] ?? eqMap['puissance'])?.toString() ?? '';
    final bIntensite = (eqMap['before_intensite'] ?? eqMap['intensite'])?.toString() ?? '';
    final bTension = (eqMap['before_tension'] ?? eqMap['tension'])?.toString() ?? '';
    final bFreon = (eqMap['before_freon'] ?? eqMap['freon'])?.toString() ?? '';

    final hasBeforeMeasures = bPression.isNotEmpty ||
        bPuissance.isNotEmpty ||
        bIntensite.isNotEmpty ||
        bTension.isNotEmpty ||
        bFreon.isNotEmpty;

    // Données techniques APRÈS
    final aPression = eqMap['after_pression']?.toString() ?? '';
    final aPuissance = eqMap['after_puissance']?.toString() ?? '';
    final aIntensite = eqMap['after_intensite']?.toString() ?? '';
    final aTension = eqMap['after_tension']?.toString() ?? '';
    final aFreon = eqMap['after_freon']?.toString() ?? '';

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
            _buildInfoRow('État', state),
            const SizedBox(height: 8),
          ],
          if (type.isNotEmpty) ...[
            _buildInfoRow('Type', type),
            const SizedBox(height: 8),
          ],
          if (brand.isNotEmpty) ...[
            _buildInfoRow('Marque', brand),
            const SizedBox(height: 8),
          ],
          if (location.isNotEmpty) ...[
            _buildInfoRow('Emplacement', location),
            const SizedBox(height: 8),
          ],
          if (tested != null) ...[
            _buildInfoRow('Test équipement', tested == true ? 'Oui' : 'Non'),
            const SizedBox(height: 8),
          ],

          if (hasBeforeMeasures) ...[
            const Divider(),
            const Text(
              '🟢 Données Techniques — AVANT Intervention',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (bPression.isNotEmpty)
                  _buildMeasureItem(
                      Icons.compress, 'Pression', '$bPression bar'),
                if (bPuissance.isNotEmpty)
                  _buildMeasureItem(Icons.power, 'Puissance', '$bPuissance CV'),
                if (bIntensite.isNotEmpty)
                  _buildMeasureItem(
                      Icons.electrical_services, 'Intensité', '$bIntensite A'),
                if (bTension.isNotEmpty)
                  _buildMeasureItem(Icons.bolt, 'Tension', '$bTension V'),
                if (bFreon.isNotEmpty)
                  _buildMeasureItem(Icons.cloud, 'Fréon', bFreon),
              ],
            ),
          ],

          if (hasAfterMeasures) ...[
            const Divider(),
            Text(
              '🟠 Données Techniques — APRÈS Intervention',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (aPression.isNotEmpty)
                  _buildMeasureItem(
                      Icons.compress, 'Pression', '$aPression bar'),
                if (aPuissance.isNotEmpty)
                  _buildMeasureItem(Icons.power, 'Puissance', '$aPuissance CV'),
                if (aIntensite.isNotEmpty)
                  _buildMeasureItem(
                      Icons.electrical_services, 'Intensité', '$aIntensite A'),
                if (aTension.isNotEmpty)
                  _buildMeasureItem(Icons.bolt, 'Tension', '$aTension V'),
                if (aFreon.isNotEmpty)
                  _buildMeasureItem(Icons.cloud, 'Fréon', aFreon),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildTechnicalMeasuresSection(Map<String, dynamic> report) {
    final pression = report['pression']?.toString() ?? '';
    final puissance = report['puissance']?.toString() ??
        report['temperature']?.toString() ??
        '';
    final intensite = report['intensite']?.toString() ?? '';
    final tension = report['tension']?.toString() ?? '';
    final freon = report['freon']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: const Color(0xFF0a543d), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Mesures Techniques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (pression.isNotEmpty)
                    Expanded(
                      child: _buildMeasureItem(
                        Icons.compress,
                        'Pression',
                        '$pression bar',
                      ),
                    ),
                  if (puissance.isNotEmpty)
                    Expanded(
                      child: _buildMeasureItem(
                        Icons.power,
                        'Puissance',
                        '$puissance CV',
                      ),
                    ),
                ],
              ),
              if (intensite.isNotEmpty || tension.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (intensite.isNotEmpty)
                      Expanded(
                        child: _buildMeasureItem(
                          Icons.electrical_services,
                          'Intensité',
                          '$intensite A',
                        ),
                      ),
                    if (tension.isNotEmpty)
                      Expanded(
                        child: _buildMeasureItem(
                          Icons.bolt,
                          'Tension',
                          '$tension V',
                        ),
                      ),
                  ],
                ),
              ],
              if (freon.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasureItem(
                        Icons.cloud,
                        'Fréon',
                        freon,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasureItem(IconData icon, String label, String value) {
    return Row(
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
