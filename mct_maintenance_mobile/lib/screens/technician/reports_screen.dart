import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/screens/technician/create_report_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class TechnicianReportsScreen extends StatefulWidget {
  const TechnicianReportsScreen({super.key});

  @override
  State<TechnicianReportsScreen> createState() =>
      _TechnicianReportsScreenState();
}

class _TechnicianReportsScreenState extends State<TechnicianReportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  String _currentFilter = 'all'; // all, draft, submitted, approved

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _downloadReportPDF(Map<String, dynamic> report) async {
    try {
      // Afficher un loader
      SnackBarHelper.showLoading(context, 'Téléchargement du rapport...',
          duration: const Duration(seconds: 30));

      // Télécharger le rapport HTML
      final htmlContent =
          await _apiService.downloadTechnicianReport(report['id']);

      // Obtenir le répertoire de téléchargements
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Créer le fichier
      final fileName = 'rapport-${report['id']}.html';
      final file = File('${directory!.path}/$fileName');
      await file.writeAsString(htmlContent);

      // Masquer le loader
      SnackBarHelper.hide(context);

      // Afficher le succès
      SnackBarHelper.showSuccess(
        context,
        'Rapport téléchargé: $fileName',
        emoji: '📄',
        action: SnackBarAction(
          label: 'Ouvrir',
          textColor: Colors.white,
          onPressed: () async {
            await OpenFile.open(file.path);
          },
        ),
      );

      // Ouvrir automatiquement
      await OpenFile.open(file.path);
    } catch (e) {
      SnackBarHelper.hide(context);
      SnackBarHelper.showError(context, 'Erreur téléchargement: $e');
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getTechnicianReports();

      if (mounted) {
        setState(() {
          // Convertir les données API en format attendu
          _reports = (response['data'] as List? ?? [])
              .map((item) => {
                    'id': item['id'],
                    'title': item['title'] ??
                        '${item['intervention_title'] ?? 'Intervention'} - ${item['customer_name'] ?? 'Client'}',
                    'date': item['date'] ??
                        item['created_at']?.toString().split(' ')[0] ??
                        DateTime.now().toString().split(' ')[0],
                    'status': item['status'] ?? 'draft',
                    'customer': item['customer_name'] ?? 'Client non renseigné',
                    'customer_phone': item['customer_phone'] ?? '',
                    'customer_email': item['customer_email'] ?? '',
                    'customer_company': item['customer_company'] ?? '',
                    'address': item['address'] ?? 'Adresse non spécifiée',
                    'duration': item['duration']?.toString() ?? '0',
                    'description':
                        item['description'] ?? item['work_description'] ?? '',
                    'materials': item['materials_used'] is List
                        ? item['materials_used']
                        : (item['materials_used'] is String
                            ? item['materials_used'].split(',')
                            : (item['materials'] is List
                                ? item['materials']
                                : [])),
                    'cost': item['cost'] ?? item['total_cost'] ?? 0,
                    'photos':
                        item['photos_count'] ?? item['photos']?.length ?? 0,
                    // Équipements (nouveau format)
                    'equipments':
                        item['equipments'] is List ? item['equipments'] : [],
                    // Mesures techniques (format legacy)
                    'pression': item['pression']?.toString() ?? '',
                    'temperature': item['temperature']?.toString() ?? '',
                    'puissance': item['puissance']?.toString() ?? '',
                    'intensite': item['intensite']?.toString() ?? '',
                    'tension': item['tension']?.toString() ?? '',
                  })
              .toList();
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  void _applyFilter() {
    if (_currentFilter == 'all') {
      _filteredReports = List.from(_reports);
    } else {
      _filteredReports = _reports.where((report) {
        final status = report['status'] as String;
        switch (_currentFilter) {
          case 'draft':
            return status == 'draft' || status == 'pending';
          case 'submitted':
            return status == 'submitted' || status == 'in_review';
          case 'approved':
            return status == 'approved' || status == 'completed';
          default:
            return true;
        }
      }).toList();
    }

    // Trier par date (plus récent en premier)
    _filteredReports.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Mes Rapports',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/background_tech.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenu
          _isLoading
              ? const Center(child: LoadingIndicator())
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: _filteredReports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            return _buildReportCard(report);
                          },
                        ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade100],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun rapport',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos rapports d\'intervention apparaîtront ici',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showReportDetails(report);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.calendar_today,
                                  size: 14, color: Colors.blue.shade600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(report['date']),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 14),

              // Client et adresse
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person,
                        size: 18, color: Colors.purple.shade600),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    report['customer'],
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on,
                        size: 18, color: Colors.orange.shade600),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report['address'],
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Statistiques
              Row(
                children: [
                  _buildStatChip(
                    Icons.schedule,
                    report['duration'],
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.photo_library,
                    '${report['photos']} photos',
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _editReport(report);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text('Modifier',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    List<Color> gradientColors;
    String label;
    IconData icon;

    switch (status) {
      case 'draft':
        gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
        label = 'Brouillon';
        icon = Icons.edit_note;
        break;
      case 'submitted':
        gradientColors = [Colors.orange.shade600, Colors.orange.shade400];
        label = 'Soumis';
        icon = Icons.send;
        break;
      case 'approved':
        gradientColors = [Colors.green.shade600, Colors.green.shade400];
        label = 'Approuvé';
        icon = Icons.check_circle;
        break;
      default:
        gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  report['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(report['status']),
                const SizedBox(height: 24),

                // Section Client
                const Text(
                  'Informations Client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 18, color: Colors.purple.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              report['customer'] ?? 'Non renseigné',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      if ((report['customer_company'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.business,
                                size: 18, color: Colors.purple.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(report['customer_company'])),
                          ],
                        ),
                      ],
                      if ((report['customer_phone'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 18, color: Colors.purple.shade600),
                            const SizedBox(width: 8),
                            Text(report['customer_phone']),
                          ],
                        ),
                      ],
                      if ((report['customer_email'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: 18, color: Colors.purple.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(report['customer_email'])),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Informations intervention
                _buildDetailRow(
                    Icons.location_on, 'Adresse', report['address']),
                _buildDetailRow(
                    Icons.calendar_today, 'Date', _formatDate(report['date'])),
                _buildDetailRow(Icons.schedule, 'Durée', report['duration']),

                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'],
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Matériel utilisé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(report['materials'] as List).map((material) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(material is Map
                              ? material['name'] ?? material.toString()
                              : material.toString()),
                        ],
                      ),
                    )),

                // Équipements (nouveau format multi-équipements)
                if (_hasEquipments(report))
                  _buildEquipmentsSection(report)
                // Mesures techniques (format legacy)
                else if (_hasTechnicalMeasures(report)) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Mesures Techniques',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            if (report['pression']?.toString().isNotEmpty ==
                                true)
                              Expanded(
                                  child: _buildMeasureItem(Icons.compress,
                                      'Pression', '${report['pression']} bar')),
                            if (report['temperature']?.toString().isNotEmpty ==
                                    true ||
                                report['puissance']?.toString().isNotEmpty ==
                                    true)
                              Expanded(
                                  child: _buildMeasureItem(
                                      Icons.power,
                                      'Puissance',
                                      '${report['puissance'] ?? report['temperature']} CV')),
                          ],
                        ),
                        if (report['intensite']?.toString().isNotEmpty ==
                                true ||
                            report['tension']?.toString().isNotEmpty == true)
                          const SizedBox(height: 12),
                        Row(
                          children: [
                            if (report['intensite']?.toString().isNotEmpty ==
                                true)
                              Expanded(
                                  child: _buildMeasureItem(
                                      Icons.electrical_services,
                                      'Intensité',
                                      '${report['intensite']} A')),
                            if (report['tension']?.toString().isNotEmpty ==
                                true)
                              Expanded(
                                  child: _buildMeasureItem(Icons.bolt,
                                      'Tension', '${report['tension']} V')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.photo_library, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${report['photos']} photos jointes',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReport(Map<String, dynamic> report) async {
    try {
      // Afficher un loader pendant le chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: LoadingIndicator()),
      );

      // Charger les détails complets de l'intervention depuis l'API
      final response = await _apiService.getInterventionById(report['id']);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (response['success'] && response['data'] != null) {
        final intervention = response['data'];

        // Naviguer vers l'écran de création/modification du rapport
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateReportScreen(
              intervention: intervention,
            ),
          ),
        );

        // Recharger la liste si le rapport a été modifié
        if (result == true) {
          await _loadReports();
        }
      } else {
        SnackBarHelper.showError(
          context,
          'Impossible de charger les détails de l\'intervention',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader en cas d'erreur
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer et trier',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0a543d),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.all_inclusive,
                color: _currentFilter == 'all'
                    ? const Color(0xFF0a543d)
                    : Colors.grey,
              ),
              title: Text(
                'Tous les rapports',
                style: GoogleFonts.poppins(
                  fontWeight: _currentFilter == 'all'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: _currentFilter == 'all'
                  ? const Icon(Icons.check, color: Color(0xFF0a543d))
                  : null,
              onTap: () {
                setState(() {
                  _currentFilter = 'all';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_note,
                color: _currentFilter == 'draft'
                    ? Colors.grey.shade700
                    : Colors.grey,
              ),
              title: Text(
                'Brouillons',
                style: GoogleFonts.poppins(
                  fontWeight: _currentFilter == 'draft'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: _currentFilter == 'draft'
                  ? const Icon(Icons.check, color: Color(0xFF0a543d))
                  : null,
              onTap: () {
                setState(() {
                  _currentFilter = 'draft';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.send,
                color:
                    _currentFilter == 'submitted' ? Colors.orange : Colors.grey,
              ),
              title: Text(
                'Soumis',
                style: GoogleFonts.poppins(
                  fontWeight: _currentFilter == 'submitted'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: _currentFilter == 'submitted'
                  ? const Icon(Icons.check, color: Color(0xFF0a543d))
                  : null,
              onTap: () {
                setState(() {
                  _currentFilter = 'submitted';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color:
                    _currentFilter == 'approved' ? Colors.green : Colors.grey,
              ),
              title: Text(
                'Approuvés',
                style: GoogleFonts.poppins(
                  fontWeight: _currentFilter == 'approved'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: _currentFilter == 'approved'
                  ? const Icon(Icons.check, color: Color(0xFF0a543d))
                  : null,
              onTap: () {
                setState(() {
                  _currentFilter = 'approved';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Date non disponible';
    }

    try {
      DateTime date;

      // Essayer différents formats
      if (dateStr.contains('T')) {
        // Format ISO (2024-01-20T10:30:00)
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('-') && dateStr.length == 10) {
        // Format YYYY-MM-DD
        date = DateTime.parse(dateStr);
      } else {
        return dateStr; // Retourner tel quel si format non reconnu
      }

      // Formater en français avec jour de la semaine
      final formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
      return formatter.format(date);
    } catch (e) {
      return dateStr; // Retourner la chaîne d'origine en cas d'erreur
    }
  }

  bool _hasTechnicalMeasures(Map<String, dynamic> report) {
    // Vérifier le nouveau format multi-équipements
    final equipments = report['equipments'] as List? ?? [];
    if (equipments.isNotEmpty) {
      return equipments.any((eq) {
        final e = eq as Map<String, dynamic>;
        return (e['pression']?.toString().isNotEmpty == true) ||
            (e['puissance']?.toString().isNotEmpty == true) ||
            (e['intensite']?.toString().isNotEmpty == true) ||
            (e['tension']?.toString().isNotEmpty == true);
      });
    }
    // Format legacy
    return (report['pression']?.toString().isNotEmpty == true) ||
        (report['temperature']?.toString().isNotEmpty == true) ||
        (report['puissance']?.toString().isNotEmpty == true) ||
        (report['intensite']?.toString().isNotEmpty == true) ||
        (report['tension']?.toString().isNotEmpty == true);
  }

  bool _hasEquipments(Map<String, dynamic> report) {
    final equipments = report['equipments'] as List? ?? [];
    return equipments.isNotEmpty;
  }

  Widget _buildEquipmentsSection(Map<String, dynamic> report) {
    final equipments = report['equipments'] as List? ?? [];
    if (equipments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.build_circle, color: const Color(0xFF0a543d), size: 22),
            const SizedBox(width: 8),
            Text(
              'Équipements (${equipments.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...equipments.asMap().entries.map((entry) {
          final index = entry.key;
          final eq = entry.value as Map<String, dynamic>;
          return _buildEquipmentCard(eq, index + 1);
        }),
      ],
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment, int index) {
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  brand.isNotEmpty ? '$brand - $type' : 'Équipement $index',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              if (state.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStateColor(state),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Mesures techniques
          if (hasMeasures) ...[
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
                  if (pression.isNotEmpty)
                    _buildMeasureItem(
                        Icons.compress, 'Pression', '$pression bar'),
                  if (puissance.isNotEmpty)
                    _buildMeasureItem(
                        Icons.power, 'Puissance', '$puissance CV'),
                  if (intensite.isNotEmpty)
                    _buildMeasureItem(
                        Icons.electrical_services, 'Intensité', '$intensite A'),
                  if (tension.isNotEmpty)
                    _buildMeasureItem(Icons.bolt, 'Tension', '$tension V'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'bon':
      case 'bon état':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'mauvais':
      case 'hors service':
        return Colors.red;
      default:
        return Colors.blue;
    }
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
