import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:async';

class SuggestTechniciansScreen extends StatefulWidget {
  final int interventionId;
  final String interventionTitle;

  const SuggestTechniciansScreen({
    Key? key,
    required this.interventionId,
    required this.interventionTitle,
  }) : super(key: key);

  @override
  _SuggestTechniciansScreenState createState() =>
      _SuggestTechniciansScreenState();
}

class _SuggestTechniciansScreenState extends State<SuggestTechniciansScreen> {
  final ApiService _apiService = ApiService();
  List<TechnicianSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  // bool _isAutoAssigning = false; // Feature désactivée temporairement

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.post(
        '/interventions/${widget.interventionId}/suggest-technicians',
        {'max_results': 10},
      );

      if (response['success']) {
        final List<dynamic> suggestionsData = response['data']['suggestions'];
        setState(() {
          _suggestions = suggestionsData
              .map((s) => TechnicianSuggestion.fromJson(s))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erreur chargement suggestions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  // Feature auto-assignation désactivée temporairement
  // Future<void> _autoAssign() async {
  //   setState(() => _isAutoAssigning = true);
  //   try {
  //     final response = await _apiService.post(
  //       '/interventions/${widget.interventionId}/auto-assign',
  //       {},
  //     );
  //
  //     if (response['success']) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(response['message']),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //         Navigator.pop(context, true); // Retour avec succès
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(response['message'] ?? 'Erreur assignation'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Erreur: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isAutoAssigning = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions Techniciens'),
        // actions: [
        //   if (_suggestions.isNotEmpty)
        //     IconButton(
        //       icon: _isAutoAssigning
        //           ? const SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: CircularProgressIndicator(color: Colors.white),
        //             )
        //           : const Icon(Icons.auto_fix_high),
        //       onPressed: _isAutoAssigning ? null : _confirmAutoAssign,
        //       tooltip: 'Auto-Assigner',
        //     ),
        // ], // Feature auto-assignation désactivée
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun technicien disponible',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _SuggestionCard(
            suggestion: suggestion,
            rank: index + 1,
            onTap: () => _showSuggestionDetails(suggestion),
          );
        },
      ),
    );
  }

  // Feature auto-assignation désactivée temporairement
  // void _confirmAutoAssign() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Auto-Assignation'),
  //       content: Text(
  //         'Assigner automatiquement le meilleur technicien (${_suggestions.first.name}) ?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Annuler'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _autoAssign();
  //           },
  //           child: const Text('Confirmer'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showSuggestionDetails(TechnicianSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SuggestionDetailsSheet(suggestion: suggestion),
    );
  }
}

// Widget Card pour chaque suggestion
class _SuggestionCard extends StatelessWidget {
  final TechnicianSuggestion suggestion;
  final int rank;
  final VoidCallback onTap;

  const _SuggestionCard({
    Key? key,
    required this.suggestion,
    required this.rank,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(suggestion.totalScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Rank + Name + Score
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank == 1 ? Colors.amber : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank == 1 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          suggestion.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${suggestion.totalScore}/100',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Score bars
              _ScoreBar(
                label: 'Distance',
                value: suggestion.details.distanceScore,
                subtitle: '${suggestion.details.distanceKm} km',
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              _ScoreBar(
                label: 'Compétences',
                value: suggestion.details.skillsScore,
                subtitle: suggestion.details.matchedSkills.isNotEmpty
                    ? suggestion.details.matchedSkills.join(', ')
                    : 'Aucune compétence spécifique',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _ScoreBar(
                label: 'Disponibilité',
                value: suggestion.details.availabilityScore,
                subtitle: suggestion.details.availabilityScore == 100
                    ? 'Entièrement libre'
                    : 'Partiellement occupé',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

// Widget barre de score
class _ScoreBar extends StatelessWidget {
  final String label;
  final int value;
  final String subtitle;
  final Color color;

  const _ScoreBar({
    Key? key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value/100',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

// Bottom sheet détails complets
class _SuggestionDetailsSheet extends StatelessWidget {
  final TechnicianSuggestion suggestion;

  const _SuggestionDetailsSheet({
    Key? key,
    required this.suggestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      suggestion.name[0],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(suggestion.phone),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${suggestion.totalScore}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Détails scores
              _DetailRow(
                icon: Icons.location_on,
                label: 'Distance',
                value: '${suggestion.details.distanceKm} km',
                score: suggestion.details.distanceScore,
              ),
              _DetailRow(
                icon: Icons.build,
                label: 'Compétences',
                value: suggestion.details.matchedSkills.isNotEmpty
                    ? suggestion.details.matchedSkills.join(', ')
                    : 'Polyvalent',
                score: suggestion.details.skillsScore,
              ),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Disponibilité',
                value: suggestion.details.availabilityScore == 100
                    ? 'Libre'
                    : 'Occupé',
                score: suggestion.details.availabilityScore,
              ),
              _DetailRow(
                icon: Icons.work_outline,
                label: 'Charge travail',
                value:
                    '${suggestion.details.recentInterventions} interventions (7j)',
                score: suggestion.details.workloadScore,
              ),
              _DetailRow(
                icon: Icons.star,
                label: 'Performance',
                value: suggestion.details.totalRatings > 0
                    ? '${suggestion.details.avgRating}/5 (${suggestion.details.totalRatings} notes)'
                    : 'Pas encore noté',
                score: suggestion.details.performanceScore,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int score;

  const _DetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            '$score/100',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

// Modèle de données
class TechnicianSuggestion {
  final int technicianId;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final int totalScore;
  final SuggestionDetails details;

  TechnicianSuggestion({
    required this.technicianId,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.totalScore,
    required this.details,
  });

  factory TechnicianSuggestion.fromJson(Map<String, dynamic> json) {
    return TechnicianSuggestion(
      technicianId: json['technician_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      totalScore: json['total_score'],
      details: SuggestionDetails.fromJson(json['details']),
    );
  }
}

class SuggestionDetails {
  final int distanceScore;
  final double distanceKm;
  final int skillsScore;
  final List<String> matchedSkills;
  final int availabilityScore;
  final int workloadScore;
  final int recentInterventions;
  final int performanceScore;
  final double avgRating;
  final int totalRatings;

  SuggestionDetails({
    required this.distanceScore,
    required this.distanceKm,
    required this.skillsScore,
    required this.matchedSkills,
    required this.availabilityScore,
    required this.workloadScore,
    required this.recentInterventions,
    required this.performanceScore,
    required this.avgRating,
    required this.totalRatings,
  });

  factory SuggestionDetails.fromJson(Map<String, dynamic> json) {
    return SuggestionDetails(
      distanceScore: json['distance_score'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      skillsScore: json['skills_score'],
      matchedSkills: List<String>.from(json['matched_skills'] ?? []),
      availabilityScore: json['availability_score'],
      workloadScore: json['workload_score'],
      recentInterventions: json['recent_interventions'],
      performanceScore: json['performance_score'],
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'],
    );
  }
}
