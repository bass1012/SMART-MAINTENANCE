import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'intervention_detail_screen.dart';
import 'new_intervention_screen.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/test_keys.dart';

class InterventionsListScreen extends StatefulWidget {
  const InterventionsListScreen({super.key});

  @override
  State<InterventionsListScreen> createState() =>
      _InterventionsListScreenState();
}

class _InterventionsListScreenState extends State<InterventionsListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _interventions = [];
  String _filterStatus = 'all';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadInterventions();

    // Rafraîchir automatiquement toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadInterventions();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInterventions() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _apiService.getUserData();
      final customerId = userData?['id'];

      if (customerId == null) {
        throw Exception('Impossible de récupérer l\'ID utilisateur');
      }

      final response =
          await _apiService.getInterventions(customerId: customerId);

      if (mounted) {
        setState(() {
          _interventions = List<Map<String, dynamic>>.from(
              response['data']?['interventions'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredInterventions {
    if (_filterStatus == 'all') {
      return _interventions;
    }
    return _interventions.where((i) => i['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interventions'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInterventions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey(TestKeys.newInterventionFAB),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewInterventionScreen(),
            ),
          );

          if (result == true) {
            _loadInterventions();
          }
        },
        backgroundColor: const Color(0xFF0a543d),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle Intervention',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilters(),

          // Liste des interventions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInterventions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadInterventions,
                        child: ListView.builder(
                          key: const ValueKey(TestKeys.interventionsList),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredInterventions.length,
                          itemBuilder: (context, index) {
                            final intervention = _filteredInterventions[index];
                            return _buildInterventionCard(intervention);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('En attente', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Assignée', 'assigned'),
            const SizedBox(width: 8),
            _buildFilterChip('Acceptée', 'accepted'),
            const SizedBox(width: 8),
            _buildFilterChip('En route', 'on_the_way'),
            const SizedBox(width: 8),
            _buildFilterChip('En cours', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Terminée', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: const Color(0xFF0a543d).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0a543d),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0a543d) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune intervention',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'Vous n\'avez pas encore de demande d\'intervention'
                : 'Aucune intervention avec ce statut',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    final status = intervention['status'] ?? 'pending';
    final priority = intervention['priority'] ?? 'medium';
    final scheduledDate = intervention['scheduled_date'] != null
        ? DateTime.parse(intervention['scheduled_date'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
      ),
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

          if (result == true) {
            _loadInterventions();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et priorité
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention['title'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(priority),
                ],
              ),
              const SizedBox(height: 12),

              // Statut
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 20,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              if (intervention['description'] != null)
                Text(
                  intervention['description'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Informations supplémentaires
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    scheduledDate != null
                        ? '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}'
                        : 'Date non définie',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.format_list_numbered,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${intervention['equipment_count'] ?? 1} équip.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (intervention['address'] != null)
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        intervention['address'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Technicien assigné
              if (intervention['technician'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Technicien: ${intervention['technician']['first_name']} ${intervention['technician']['last_name']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'low':
        color = Colors.blue;
        label = 'Basse';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Moyenne';
        break;
      case 'high':
        color = Colors.red;
        label = 'Haute';
        break;
      case 'critical':
        color = Colors.purple;
        label = 'Critique';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.assignment;
      case 'assigned':
        return Icons.person_add;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'on_the_way':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'accepted':
        return Colors.green.shade700;
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
        return Colors.teal;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente d\'assignation';
      case 'assigned':
        return 'Technicien assigné';
      case 'accepted':
        return 'Acceptée par le technicien';
      case 'on_the_way':
        return 'Technicien en route';
      case 'arrived':
        return 'Technicien sur place';
      case 'in_progress':
        return 'Intervention en cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
