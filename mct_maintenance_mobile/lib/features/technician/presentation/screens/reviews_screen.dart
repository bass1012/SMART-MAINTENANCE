import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  const TechnicianReviewsScreen({super.key});

  @override
  State<TechnicianReviewsScreen> createState() =>
      _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState extends State<TechnicianReviewsScreen> {
  late final InterventionRepository _interventionRepository;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingsBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _interventionRepository = context.read<InterventionRepository>();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final response = await _interventionRepository.getTechnicianReviews();

      if (kDebugMode) debugPrint('🔍 DEBUG - Response complète: $response');
      if (kDebugMode) debugPrint('🔍 DEBUG - Response data: ${response['data']}');

      if (mounted) {
        setState(() {
          final data = response['data'] ?? {};

          if (kDebugMode) debugPrint('🔍 DEBUG - data keys: ${data.keys}');
          if (kDebugMode) debugPrint('🔍 DEBUG - average_rating: ${data['average_rating']}');
          if (kDebugMode) debugPrint('🔍 DEBUG - total_reviews: ${data['total_reviews']}');
          if (kDebugMode) debugPrint('🔍 DEBUG - ratings_breakdown: ${data['ratings_breakdown']}');
          if (kDebugMode) debugPrint('🔍 DEBUG - reviews: ${data['reviews']}');

          // Statistiques globales
          _averageRating = (data['average_rating'] ?? 0).toDouble();
          _totalReviews = data['total_reviews'] ?? 0;

          // Répartition des notes
          if (data['ratings_breakdown'] != null) {
            final breakdown = data['ratings_breakdown'];
            _ratingsBreakdown = {
              5: breakdown[5] ?? breakdown['5'] ?? 0,
              4: breakdown[4] ?? breakdown['4'] ?? 0,
              3: breakdown[3] ?? breakdown['3'] ?? 0,
              2: breakdown[2] ?? breakdown['2'] ?? 0,
              1: breakdown[1] ?? breakdown['1'] ?? 0,
            };
          }

          // Liste des avis
          _reviews = (data['reviews'] as List? ?? []).map((item) {
            final rawDate = (item['date'] ?? item['created_at'])?.toString() ?? '';
            String formattedDate = '';
            if (rawDate.isNotEmpty) {
              final parsed = DateTime.tryParse(rawDate);
              if (parsed != null) {
                formattedDate = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
              } else {
                formattedDate = rawDate.split('T')[0];
              }
            }

            return {
              'id': item['id'],
              'rating': (item['rating'] ?? 0).toDouble(),
              'date': formattedDate,
              'intervention': item['intervention_title'] ??
                  item['intervention']?['title'] ??
                  'Intervention',
            };
          }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Évaluations'),
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
                  onRefresh: _loadReviews,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildRatingsSummary(),
                      const SizedBox(height: 24),
                      _buildRatingsBreakdown(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Évaluations reçues (${_reviews.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_reviews.isEmpty)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Aucune évaluation reçue pour le moment.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._reviews.map((review) => _buildReviewCard(review)),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRatingsSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber[700]!,
              Colors.amber[500]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.star,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalReviews avis',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            _buildStarRating(_averageRating, large: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsBreakdown() {
    final breakdown = [
      {'stars': 5, 'count': _ratingsBreakdown[5] ?? 0, 'color': Colors.green},
      {
        'stars': 4,
        'count': _ratingsBreakdown[4] ?? 0,
        'color': Colors.lightGreen
      },
      {'stars': 3, 'count': _ratingsBreakdown[3] ?? 0, 'color': Colors.orange},
      {
        'stars': 2,
        'count': _ratingsBreakdown[2] ?? 0,
        'color': Colors.deepOrange
      },
      {'stars': 1, 'count': _ratingsBreakdown[1] ?? 0, 'color': Colors.red},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.map((item) {
              final stars = item['stars'] as int;
              final count = item['count'] as int;
              final color = item['color'] as Color;
              final percentage =
                  _totalReviews > 0 ? (count / _totalReviews) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$stars★',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final String dateStr = review['date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['intervention'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStarRating(review['rating'] as double),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, {bool large = false}) {
    final size = large ? 24.0 : 16.0;
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(
            Icons.star,
            size: size,
            color: large ? Colors.white : Colors.amber,
          );
        } else if (index == fullStars && hasHalfStar) {
          return Icon(
            Icons.star_half,
            size: size,
            color: large ? Colors.white : Colors.amber,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: size,
            color: large ? Colors.white70 : Colors.grey[400],
          );
        }
      }),
    );
  }
}
