import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/screens/technician/intervention_detail_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/view_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/create_report_screen.dart';
import 'package:mct_maintenance_mobile/screens/technician/diagnostic_report_screen.dart';
import '../../utils/test_keys.dart';
import '../../utils/test_keys.dart';

class TechnicianInterventionsScreen extends StatefulWidget {
  const TechnicianInterventionsScreen({super.key});

  @override
  State<TechnicianInterventionsScreen> createState() =>
      _TechnicianInterventionsScreenState();
}

class _TechnicianInterventionsScreenState
    extends State<TechnicianInterventionsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allInterventions = [];
  List<Map<String, dynamic>> _filteredInterventions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInterventions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _filterInterventions();
    }
  }

  Future<void> _loadInterventions() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getTechnicianInterventions();

      if (mounted) {
        setState(() {
          // Convertir les données API en format attendu
          _allInterventions = (response['data'] as List? ?? [])
              .where((item) => item != null) // Filtrer les items null
              .map((item) {
            // Formatter la date et l'heure depuis scheduled_date
            String formattedDate = '';
            String formattedTime = '';

            if (item['scheduled_date'] != null) {
              try {
                final dateTime = DateTime.parse(item['scheduled_date']);
                formattedDate =
                    DateFormat('dd/MM/yyyy', 'fr_FR').format(dateTime);
                formattedTime = DateFormat('HH:mm').format(dateTime);
              } catch (e) {
                formattedDate = item['scheduled_date'].toString().split(' ')[0];
                formattedTime = item['scheduled_time'] ?? '00:00';
              }
            } else {
              formattedDate =
                  item['date'] ?? DateTime.now().toString().split(' ')[0];
              formattedTime = item['scheduled_time'] ?? item['time'] ?? '00:00';
            }

            return {
              'id': item['id'],
              'title': item['title'] ?? item['description'] ?? 'Intervention',
              'customer': item['customer_name'] ??
                  item['customer']?['name'] ??
                  'Client',
              'address': item['address'] ?? 'Adresse non spécifiée',
              'date': formattedDate,
              'time': formattedTime,
              'status': item['status'] ?? 'pending',
              'priority': item['priority'] ?? 'medium',
              'description': item['description'] ?? '',
              'type': item['type'] ?? item['service_type'] ?? 'Service',
              // Ajouter les champs de rapport pour ViewReportScreen
              'report_data': item['report_data'],
              'report_submitted_at': item['report_submitted_at'],
            };
          }).toList();
          _filterInterventions();
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

  void _filterInterventions() {
    List<String> statuses;
    switch (_tabController.index) {
      case 0: // Toutes
        setState(() => _filteredInterventions = _allInterventions);
        return;
      case 1: // Assignées (en attente d'acceptation)
        statuses = ['assigned'];
        break;
      case 2: // Acceptées
        statuses = ['accepted'];
        break;
      case 3: // En route (on_the_way + arrived)
        statuses = ['on_the_way', 'arrived'];
        break;
      case 4: // En cours
        statuses = ['in_progress'];
        break;
      case 5: // Terminées
        statuses = ['completed', 'diagnostic_submitted', 'execution_confirmed'];
        break;
      default:
        setState(() => _filteredInterventions = _allInterventions);
        return;
    }

    setState(() {
      _filteredInterventions = _allInterventions
          .where((intervention) =>
              intervention != null && statuses.contains(intervention['status']))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0a543d), Color(0xFF0d6b4d), Color(0xFF0f7d59)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Mes Interventions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Assignées'),
            Tab(text: 'Acceptées'),
            Tab(text: 'En route'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
        ),
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
                  onRefresh: _loadInterventions,
                  child: _filteredInterventions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredInterventions.length,
                          itemBuilder: (context, index) {
                            final intervention = _filteredInterventions[index];
                            return _buildInterventionCard(intervention);
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune intervention',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas d\'intervention dans cette catégorie',
              style: GoogleFonts.poppins(
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

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    // Vérification de sécurité
    if (intervention == null) {
      return const SizedBox.shrink();
    }

    final status = intervention['status'] as String? ?? 'pending';
    final priority = intervention['priority'] as String? ?? 'medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InterventionDetailScreen(
                  intervention: intervention,
                ),
              ),
            );

            // Recharger la liste si l'intervention a été modifiée
            if (result == true) {
              _loadInterventions();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec titre et badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intervention['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0a543d).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              intervention['type'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0a543d),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: 6),
                        _buildPriorityBadge(priority),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Client
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_outline,
                          size: 16, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        intervention['customer'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Adresse
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.orange[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        intervention['address'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Date et heure
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.access_time,
                          size: 16, color: Colors.purple[700]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${intervention['date']} à ${intervention['time']}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    intervention['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton Accepter pour les interventions assignées
                    if (status == 'assigned') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          key:
                              const ValueKey(TestKeys.acceptInterventionButton),
                          onPressed: () async {
                            try {
                              await _apiService
                                  .acceptIntervention(intervention['id']);
                              if (context.mounted) {
                                SnackBarHelper.showSuccess(
                                    context, 'Intervention acceptée',
                                    emoji: '✓');
                              }
                              _loadInterventions();
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showError(context, e.toString());
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: Text('Accepter',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    // Bouton En route pour les interventions acceptées
                    if (status == 'accepted') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade600,
                              Colors.indigo.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _apiService
                                  .markInterventionOnTheWay(intervention['id']);
                              if (context.mounted) {
                                SnackBarHelper.showSuccess(
                                    context, 'En route vers le client',
                                    emoji: '🚗');
                              }
                              _loadInterventions();
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showError(context, e.toString());
                              }
                            }
                          },
                          icon: const Icon(Icons.directions_car, size: 18),
                          label: Text('En route',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    // Bouton Arrivé pour les interventions en route
                    if (status == 'on_the_way') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade600,
                              Colors.purple.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _apiService
                                  .markInterventionArrived(intervention['id']);
                              if (context.mounted) {
                                SnackBarHelper.showSuccess(
                                    context, 'Arrivée confirmée',
                                    emoji: '📍');
                              }
                              _loadInterventions();
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showError(context, e.toString());
                              }
                            }
                          },
                          icon: const Icon(Icons.location_on, size: 18),
                          label: Text('Arrivé',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    // Bouton Démarrer pour les interventions arrivées
                    if (status == 'arrived') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _apiService
                                  .startIntervention(intervention['id']);
                              if (context.mounted) {
                                SnackBarHelper.showSuccess(
                                    context, 'Intervention démarrée',
                                    emoji: '🔧');
                              }
                              _loadInterventions();
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showError(context, e.toString());
                              }
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: Text('Démarrer',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'in_progress') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0a543d).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          key: const ValueKey(
                              TestKeys.completeInterventionButton),
                          onPressed: () async {
                            try {
                              await _apiService
                                  .completeIntervention(intervention['id']);
                              if (context.mounted) {
                                SnackBarHelper.showSuccess(
                                    context, 'Intervention terminée',
                                    emoji: '🎉');
                              }
                              _loadInterventions();
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showError(context, e.toString());
                              }
                            }
                          },
                          icon: const Icon(Icons.done_all, size: 18),
                          label: Text('Terminer',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'completed') ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          key: const ValueKey(TestKeys.createReportButton),
                          onPressed: () async {
                            // Vérifier si un rapport existe
                            final hasReport =
                                intervention['report_submitted_at'] != null;

                            if (hasReport) {
                              // Naviguer vers l'écran de visualisation du rapport
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewReportScreen(
                                    intervention: intervention,
                                  ),
                                ),
                              );
                            } else {
                              // Déterminer le type d'intervention pour choisir l'écran approprié
                              final interventionType = intervention['type']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final isDiagnostic =
                                  interventionType.contains('diagnostic') ||
                                      interventionType.contains('depannage') ||
                                      interventionType.contains('dépannage') ||
                                      interventionType.contains('reparation') ||
                                      interventionType.contains('réparation') ||
                                      interventionType.contains('urgence');

                              Widget reportScreen;
                              if (isDiagnostic) {
                                // Utiliser le nouveau écran de diagnostic
                                reportScreen = DiagnosticReportScreen(
                                  interventionId: intervention['id'],
                                  intervention: intervention,
                                );
                              } else {
                                // Utiliser l'ancien écran pour maintenance
                                reportScreen = CreateReportScreen(
                                  intervention: intervention,
                                );
                              }

                              // Naviguer vers l'écran approprié
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => reportScreen,
                                ),
                              );

                              // Recharger la liste si un rapport a été créé
                              if (result == true) {
                                _loadInterventions();
                              }
                            }
                          },
                          icon: const Icon(Icons.description, size: 18),
                          label: Text(
                            intervention['report_submitted_at'] != null
                                ? 'Voir rapport'
                                : () {
                                    // Déterminer le texte du bouton selon le type
                                    final interventionType =
                                        intervention['type']
                                                ?.toString()
                                                .toLowerCase() ??
                                            '';
                                    final isDiagnostic = interventionType
                                            .contains('diagnostic') ||
                                        interventionType
                                            .contains('depannage') ||
                                        interventionType
                                            .contains('dépannage') ||
                                        interventionType
                                            .contains('reparation') ||
                                        interventionType
                                            .contains('réparation') ||
                                        interventionType.contains('urgence');
                                    return isDiagnostic
                                        ? 'Créer rapport diagnostic'
                                        : 'Créer rapport';
                                  }(),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
      case 'pending':
        gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case 'assigned':
        gradientColors = [Colors.orange.shade600, Colors.orange.shade400];
        label = 'Assignée';
        icon = Icons.assignment_ind;
        break;
      case 'accepted':
        gradientColors = [Colors.teal.shade600, Colors.teal.shade400];
        label = 'Acceptée';
        icon = Icons.thumb_up;
        break;
      case 'on_the_way':
        gradientColors = [Colors.indigo.shade600, Colors.indigo.shade400];
        label = 'En route';
        icon = Icons.directions_car;
        break;
      case 'arrived':
        gradientColors = [Colors.purple.shade600, Colors.purple.shade400];
        label = 'Sur place';
        icon = Icons.location_on;
        break;
      case 'in_progress':
        gradientColors = [Colors.blue.shade600, Colors.blue.shade400];
        label = 'En cours';
        icon = Icons.play_circle_filled;
        break;
      case 'completed':
        gradientColors = [Colors.green.shade600, Colors.green.shade400];
        label = 'Terminée';
        icon = Icons.check_circle;
        break;
      case 'diagnostic_submitted':
        gradientColors = [Colors.cyan.shade600, Colors.cyan.shade400];
        label = 'Diagnostic';
        icon = Icons.description;
        break;
      case 'execution_confirmed':
        gradientColors = [Colors.green.shade700, Colors.green.shade500];
        label = 'Confirmée';
        icon = Icons.verified;
        break;
      case 'cancelled':
        gradientColors = [Colors.red.shade600, Colors.red.shade400];
        label = 'Annulée';
        icon = Icons.cancel;
        break;
      case 'rejected':
        gradientColors = [Colors.red.shade800, Colors.red.shade600];
        label = 'Rejetée';
        icon = Icons.block;
        break;
      default:
        gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
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

  Widget _buildPriorityBadge(String priority) {
    List<Color> gradientColors;
    String label;

    switch (priority) {
      case 'high':
        gradientColors = [Colors.red.shade600, Colors.red.shade400];
        label = 'URGENT';
        break;
      case 'medium':
        gradientColors = [Colors.orange.shade600, Colors.orange.shade400];
        label = 'MOYEN';
        break;
      case 'low':
        gradientColors = [Colors.blue.shade600, Colors.blue.shade400];
        label = 'FAIBLE';
        break;
      default:
        gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
        label = priority.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
