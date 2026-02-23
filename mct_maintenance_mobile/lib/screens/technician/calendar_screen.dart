import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class TechnicianCalendarScreen extends StatefulWidget {
  const TechnicianCalendarScreen({super.key});

  @override
  State<TechnicianCalendarScreen> createState() =>
      _TechnicianCalendarScreenState();
}

class _TechnicianCalendarScreenState extends State<TechnicianCalendarScreen> {
  final ApiService _apiService = ApiService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Calculer la plage de dates (début et fin du mois)
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final response = await _apiService.getTechnicianCalendar(
        startDate: firstDay.toString().split(' ')[0],
        endDate: lastDay.toString().split(' ')[0],
      );

      if (mounted) {
        setState(() {
          _events.clear();

          // Convertir les données API en format attendu
          final appointments = response['data'] as List? ?? [];
          print(
              '📅 [CALENDAR] ${appointments.length} rendez-vous reçus de l\'API');

          for (var appointment in appointments) {
            final dateStr =
                appointment['scheduled_date'] ?? appointment['date'];
            print(
                '📆 [CALENDAR] Traitement: ${appointment['title']} - Date: $dateStr');

            if (dateStr != null) {
              final date = DateTime.parse(dateStr);
              final dateKey = DateTime(date.year, date.month, date.day);
              print('🔑 [CALENDAR] Clé de date: $dateKey');

              if (_events[dateKey] == null) {
                _events[dateKey] = [];
              }

              _events[dateKey]!.add({
                'id': appointment['id'],
                'time': appointment['scheduled_time'] ??
                    appointment['time'] ??
                    '00:00',
                'title': appointment['title'] ??
                    appointment['description'] ??
                    'Rendez-vous',
                'customer': appointment['customer_name'] ??
                    appointment['customer']?['name'] ??
                    'Client',
                'address': appointment['address'] ?? 'Adresse non spécifiée',
              });

              print('✅ [CALENDAR] Événement ajouté à la date $dateKey');
            }
          }

          print(
              '📊 [CALENDAR] Total événements organisés: ${_events.length} jours avec rendez-vous');
          print(
              '📊 [CALENDAR] Dates avec événements: ${_events.keys.toList()}');
          print('📍 [CALENDAR] Jour sélectionné: $_selectedDay');
          print(
              '📍 [CALENDAR] Événements pour aujourd\'hui: ${_getEventsForDay(_selectedDay!).length}');

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

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  List<Map<String, dynamic>> _getAllEventsForMonth() {
    final allEvents = <Map<String, dynamic>>[];
    _events.forEach((date, events) {
      for (var event in events) {
        allEvents.add({...event, 'date': date});
      }
    });
    return allEvents;
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
          'Mon Calendrier',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Aujourd\'hui',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
              _loadEvents();
            },
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
          Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                              );
                            });
                            _loadEvents();
                          },
                        ),
                      ),
                      Text(
                        _formatMonth(_focusedDay),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0a543d),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                              );
                            });
                            _loadEvents();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vue simplifiée - Affichage de tous les rendez-vous',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tous les rendez-vous du mois',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0a543d).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${_getAllEventsForMonth().length}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAllEventsListGroupedByDate(),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildAllEventsListGroupedByDate() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade100],
                ),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.event_busy, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun rendez-vous ce mois',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes libre tout le mois',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Trier les dates
    final sortedDates = _events.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final events = _events[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de date
            Container(
              margin: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0a543d).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateHeader(date),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${events.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Liste des événements de cette date
            ...events
                .map((event) => Container(
                      margin:
                          const EdgeInsets.only(bottom: 12, left: 4, right: 4),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0a543d).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          event['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.person,
                                      size: 16, color: Colors.blue.shade600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event['customer'],
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.location_on,
                                      size: 16, color: Colors.orange.shade600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event['address'],
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0a543d).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            event['time'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onTap: () {
                          _showInterventionDetails(event['id']);
                        },
                      ),
                    ))
                .toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day} ${months[date.month - 1]}';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showInterventionDetails(int interventionId) async {
    try {
      // Afficher un loader pendant le chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer les détails de l'intervention
      final response = await _apiService.getInterventionById(interventionId);

      if (!mounted) return;

      // Fermer le loader
      Navigator.pop(context);

      final intervention = response['data'];

      // Afficher le dialogue avec les détails
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0a543d), Color(0xFF0f7d59)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Détails de l\'intervention',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0a543d),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailItem(
                  icon: Icons.title,
                  label: 'Titre',
                  value: intervention['title'] ?? 'Non spécifié',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.description,
                  label: 'Description',
                  value: intervention['description'] ?? 'Non spécifiée',
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.person,
                  label: 'Client',
                  value: intervention['customer']?['first_name'] != null
                      ? '${intervention['customer']['first_name']} ${intervention['customer']['last_name']}'
                      : 'Non spécifié',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.location_on,
                  label: 'Adresse',
                  value: intervention['address'] ?? 'Non spécifiée',
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Date prévue',
                  value: intervention['scheduled_date'] != null
                      ? _formatDate(
                          DateTime.parse(intervention['scheduled_date']))
                      : 'Non spécifiée',
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.flag,
                  label: 'Statut',
                  value: _getStatusLabel(intervention['status'] ?? 'pending'),
                  color: _getStatusColor(intervention['status'] ?? 'pending'),
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.priority_high,
                  label: 'Priorité',
                  value: _getPriorityLabel(intervention['priority']),
                  color: _getPriorityColor(intervention['priority']),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF0a543d),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assignée';
      case 'accepted':
        return 'Acceptée';
      case 'on_the_way':
        return 'En route';
      case 'arrived':
        return 'Arrivé';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status ?? 'Inconnu';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
      case 'assigned':
        return Colors.orange;
      case 'accepted':
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'low':
        return 'Basse';
      case 'normal':
        return 'Normale';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Haute';
      case 'urgent':
        return 'Urgente';
      case 'critical':
        return 'Critique';
      default:
        return priority ?? 'Normale';
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'urgent':
        return Colors.red;
      case 'critical':
        return Colors.red.shade900;
      default:
        return Colors.blue;
    }
  }
}
