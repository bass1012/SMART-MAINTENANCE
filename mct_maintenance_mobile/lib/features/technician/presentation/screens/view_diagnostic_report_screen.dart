import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:mct_maintenance_mobile/widgets/common/authenticated_network_image.dart';

class ViewDiagnosticReportScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;

  const ViewDiagnosticReportScreen({
    super.key,
    required this.intervention,
  });

  @override
  State<ViewDiagnosticReportScreen> createState() => _ViewDiagnosticReportScreenState();
}

class _ViewDiagnosticReportScreenState extends State<ViewDiagnosticReportScreen> {
  late Map<String, dynamic> _intervention;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _intervention = Map<String, dynamic>.from(widget.intervention);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFreshIntervention();
    });
  }

  Future<void> _fetchFreshIntervention() async {
    final rawId = _intervention['id'];
    if (rawId == null) return;
    final int id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    if (id == 0) return;

    setState(() => _isLoading = true);

    try {
      final interventionRepository = context.read<InterventionRepository>();
      final response = await interventionRepository.getInterventionById(id);
      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _intervention = Map<String, dynamic>.from(response['data']);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur chargement rapport: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _report {
    if (_intervention['diagnosticReports'] != null) {
      final reports = _intervention['diagnosticReports'];
      if (reports is List && reports.isNotEmpty) {
        final first = reports[0];
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
    }
    if (_intervention['diagnostic_report'] != null) {
      final r = _intervention['diagnostic_report'];
      if (r is Map<String, dynamic>) return r;
      if (r is Map) return Map<String, dynamic>.from(r);
    }
    if (_intervention['report_data'] != null) {
      final r = _intervention['report_data'];
      if (r is Map<String, dynamic>) return r;
      if (r is Map) return Map<String, dynamic>.from(r);
    }
    return null;
  }

  List<dynamic> get _equipments {
    final report = _report;
    if (report == null) return [];

    if (report['equipments'] != null) {
      final eq = report['equipments'];
      if (eq is List) return eq;
      if (eq is String) {
        try {
          final decoded = json.decode(eq);
          if (decoded is List) return decoded;
        } catch (_) {}
      }
    }

    // Fallback legacy (single equipment)
    if (report['equipment_brand'] != null || report['equipment_type'] != null || report['pression'] != null) {
      return [
        {
          'index': 1,
          'type': report['equipment_type'] ?? 'Mural',
          'brand': report['equipment_brand'] ?? '',
          'location': report['location'] ?? '',
          'state': report['equipment_state'] ?? '',
          'tested': report['tested'] ?? true,
          'before_intensite': report['intensite'] ?? '',
          'before_tension': report['tension'] ?? '',
          'before_freon': report['freon'] ?? '',
          'before_pression': report['pression'] ?? '',
          'before_puissance': report['puissance'] ?? '',
        }
      ];
    }

    return [];
  }

  List<dynamic> get _partsList {
    if (_report == null || _report!['parts_needed'] == null) {
      return [];
    }

    final partsNeeded = _report!['parts_needed'];
    if (partsNeeded is String) {
      if (partsNeeded.isEmpty || partsNeeded == '[]') {
        return [];
      }
      try {
        final decoded = json.decode(partsNeeded);
        if (decoded is List) return decoded;
        return [];
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Erreur parsing parts_needed: $e');
        return [];
      }
    } else if (partsNeeded is List) {
      return partsNeeded;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final hasReport = report != null;
    final equipments = _equipments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de Diagnostic', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFreshIntervention,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0a543d)))
          : !hasReport
              ? _buildNoReport()
              : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec statut
                    _buildStatusBadge(report['status'] ?? 'submitted'),
                    const SizedBox(height: 20),

                    // Informations intervention
                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    // Section Devis Généré par la direction (si disponible)
                    if (_intervention['quote'] != null && _intervention['quote'] is Map) ...[
                      _buildQuoteSection(Map<String, dynamic>.from(_intervention['quote'])),
                      const SizedBox(height: 20),
                    ],

                    // Date de soumission
                    if (report['submitted_at'] != null)
                      _buildInfoRow(
                        '📅 Rapport soumis le',
                        _formatDate(report['submitted_at']),
                      ),
                    const SizedBox(height: 20),

                    // SECTION ÉQUIPEMENTS & DONNÉES TECHNIQUES
                    if (equipments.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.build, color: Color(0xFF0a543d), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Équipements (${equipments.length}) & Constantes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0a543d),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < equipments.length; i++) ...[
                        _buildEquipmentCard(Map<String, dynamic>.from(equipments[i]), i + 1),
                        if (i < equipments.length - 1) const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // POINT 6 : DESCRIPTION DE LA PANNE
                    _buildSection(
                      '6/ Description / Constat de la Panne',
                      Icons.report_problem,
                      report['problem_description'] ??
                          report['work_description'] ??
                          report['description'] ??
                          'Non renseigné',
                    ),
                    const SizedBox(height: 24),

                    // POINT 7 : MATÉRIELS NÉCESSAIRES
                    if ((report['materials_needed'] != null && report['materials_needed'].toString().isNotEmpty) ||
                        _partsList.isNotEmpty ||
                        report['labor_cost'] != null ||
                        report['estimated_total'] != null ||
                        report['total_cost'] != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.build_circle, size: 20, color: Color(0xFF0a543d)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '7/ Matériels nécessaires (Dépannage / Installation)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0a543d),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (report['materials_needed'] != null && report['materials_needed'].toString().isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                report['materials_needed'],
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          if (_partsList.isNotEmpty) ...[
                            _buildPartsSection(_partsList),
                            const SizedBox(height: 12),
                          ],
                          _buildCostsSection(report),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Solution recommandée (si renseignée)
                    if (report['recommended_solution'] != null &&
                        report['recommended_solution'].toString().isNotEmpty &&
                        report['recommended_solution'] != report['problem_description']) ...[
                      _buildSection(
                        'Solution Recommandée',
                        Icons.check_circle_outline,
                        report['recommended_solution'],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Niveau d'urgence & Durée estimée
                    Row(
                      children: [
                        Expanded(child: _buildUrgencyBadge(report['urgency_level'] ?? 'medium')),
                        if (report['estimated_duration'] != null &&
                            report['estimated_duration'].toString().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSection(
                              'Durée Estimée',
                              Icons.access_time,
                              report['estimated_duration'],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    if ((report['notes'] != null && report['notes'].toString().isNotEmpty) ||
                        (report['observations'] != null && report['observations'].toString().isNotEmpty))
                      _buildSection(
                        'Notes / Observations',
                        Icons.comment,
                        (report['notes'] ?? report['observations']).toString(),
                      ),
                    const SizedBox(height: 24),

                    // Photos du diagnostic
                    _buildPhotosGallerySection(report, _intervention),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> eq, int index) {
    final name = eq['name'] ?? '';
    final type = eq['type'] ?? '';
    final brand = eq['brand'] ?? '';
    final location = eq['location'] ?? '';
    final state = eq['state'] ?? '';
    final tested = eq['tested'];

    final bIntensite = eq['before_intensite'] ?? eq['intensite'] ?? '';
    final bTension = eq['before_tension'] ?? eq['tension'] ?? '';
    final bFreon = eq['before_freon'] ?? eq['freon'] ?? '';
    final bPression = eq['before_pression'] ?? eq['pression'] ?? '';
    final bPuissance = eq['before_puissance'] ?? eq['puissance'] ?? '';

    final hasMeasures = bIntensite.isNotEmpty ||
        bTension.isNotEmpty ||
        bFreon.isNotEmpty ||
        bPression.isNotEmpty ||
        bPuissance.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0a543d).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0a543d),
                child: Text(
                  '$index',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isNotEmpty ? name : (brand.isNotEmpty ? '$brand - $type' : 'Équipement $index'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (type.isNotEmpty) _buildInfoRow('Type :', type),
          if (brand.isNotEmpty) _buildInfoRow('Marque :', brand),
          if (location.isNotEmpty) _buildInfoRow('Emplacement :', location),
          if (state.isNotEmpty) _buildInfoRow('État :', state),
          if (tested != null) _buildInfoRow('Test équipement :', tested == true ? 'Oui' : 'Non'),

          if (hasMeasures) ...[
            const Divider(),
            const Text(
              '🟢 Données Techniques (Constantes avant intervention)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (bPression.isNotEmpty) _buildMeasureChip(Icons.compress, 'Pression', '$bPression bar'),
                if (bPuissance.isNotEmpty) _buildMeasureChip(Icons.power, 'Puissance', '$bPuissance CV'),
                if (bIntensite.isNotEmpty) _buildMeasureChip(Icons.electrical_services, 'Intensité', '$bIntensite A'),
                if (bTension.isNotEmpty) _buildMeasureChip(Icons.bolt, 'Tension', '$bTension V'),
                if (bFreon.isNotEmpty) _buildMeasureChip(Icons.cloud, 'Fréon', bFreon),
              ],
            ),
          ],
        ],
      ),
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
                      child: AuthenticatedNetworkImage(
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
                child: AuthenticatedNetworkImage(
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

  Widget _buildMeasureChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0a543d)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0a543d),
          ),
        ),
      ],
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
              'Le rapport de diagnostic n\'a pas encore été soumis',
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
      case 'pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'En attente';
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _intervention['title'] ?? 'Sans titre',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_intervention['description'] != null)
              Text(
                _intervention['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0a543d)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0a543d),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

  Widget _buildCostsSection(Map<String, dynamic> report) {
    final laborCostRaw = report['labor_cost'] ?? 0;
    final totalRaw = report['estimated_total'] ?? report['total_cost'] ?? report['total_estimated'] ?? 0;

    final laborCost = num.tryParse(laborCostRaw.toString()) ?? 0;
    final total = num.tryParse(totalRaw.toString()) ?? 0;
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0a543d).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Coût main d\'œuvre: ${fmt.format(laborCost)} FCFA',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            'Total estimé: ${fmt.format(total)} FCFA',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0a543d)),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection(List<dynamic> parts) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...parts.map((part) {
          final pMap = part is Map ? part : {'name': part.toString()};
          final name = pMap['name'] ?? pMap['label'] ?? pMap['title'] ?? 'Pièce sans nom';
          final qty = pMap['quantity'] ?? pMap['qty'] ?? 1;
          final unitPriceRaw = pMap['unitPrice'] ?? pMap['unit_price'] ?? pMap['price'];
          final unitPriceNum = unitPriceRaw != null ? num.tryParse(unitPriceRaw.toString()) : null;
          final priceText = (unitPriceNum != null && unitPriceNum > 0) ? '${fmt.format(unitPriceNum)} FCFA' : '-';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF0a543d),
                ),
              ),
              title: Text(
                name.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('Prix unitaire: $priceText'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x$qty',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    String label;
    IconData icon;

    switch (urgency) {
      case 'critical':
        color = Colors.red;
        label = 'URGENT';
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.orange;
        label = 'ÉLEVÉ';
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.blue;
        label = 'MOYEN';
        icon = Icons.info;
        break;
      case 'low':
        color = Colors.green;
        label = 'FAIBLE';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = urgency.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Urgence: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection(Map<String, dynamic> quote) {
    final reference = quote['reference'] ?? 'Devis';
    final status = (quote['status'] ?? 'draft').toString();
    final total = (quote['total'] ?? quote['subtotal'] ?? 0).toDouble();
    final items = quote['items'] is List ? (quote['items'] as List) : [];

    String statusText = 'Brouillon';
    Color statusColor = Colors.grey;
    if (status == 'sent') {
      statusText = 'Envoyé au client';
      statusColor = Colors.blue;
    } else if (status == 'accepted') {
      statusText = 'Accepté par le client';
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusText = 'Refusé par le client';
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.request_quote_rounded, color: Color(0xFF0a543d), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Devis généré ($reference)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0a543d),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Montant Total : ${NumberFormat('#,##0', 'fr_FR').format(total)} FCFA',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Détail des prestations / articles :',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            for (var item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item['productName'] ?? item['product_name'] ?? item['description'] ?? 'Article'} (x${item['quantity'] ?? 1})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0', 'fr_FR').format((item['unitPrice'] ?? item['unit_price'] ?? 0) * (item['quantity'] ?? 1))} FCFA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Date inconnue';
      }

      return DateFormat("dd MMMM yyyy à HH'h'mm", 'fr_FR').format(date);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur formatage date: $e');
      return 'Date invalide';
    }
  }
}
