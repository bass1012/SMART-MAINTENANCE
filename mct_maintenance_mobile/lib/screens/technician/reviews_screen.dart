import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  const TechnicianReviewsScreen({super.key});

  @override
  State<TechnicianReviewsScreen> createState() =>
      _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState extends State<TechnicianReviewsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingsBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getTechnicianReviews();

      print('🔍 DEBUG - Response complète: $response');
      print('🔍 DEBUG - Response data: ${response['data']}');

      if (mounted) {
        setState(() {
          final data = response['data'] ?? {};

          print('🔍 DEBUG - data keys: ${data.keys}');
          print('🔍 DEBUG - average_rating: ${data['average_rating']}');
          print('🔍 DEBUG - total_reviews: ${data['total_reviews']}');
          print('🔍 DEBUG - ratings_breakdown: ${data['ratings_breakdown']}');
          print('🔍 DEBUG - reviews: ${data['reviews']}');

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
            final customerName =
                item['customer_name'] ?? item['customer']?['name'] ?? 'Client';
            return {
              'id': item['id'],
              'customer': customerName,
              'avatar': _getInitials(customerName),
              'rating': (item['rating'] ?? 0).toDouble(),
              'date': item['date'] ??
                  item['created_at']?.toString().split(' ')[0] ??
                  DateTime.now().toString().split(' ')[0],
              'intervention': item['intervention_title'] ??
                  item['intervention']?['title'] ??
                  'Intervention',
              'comment': item['comment'] ?? item['review'] ?? '',
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CL';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Text(
                    review['avatar'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customer'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review['intervention'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStarRating(review['rating'] as double),
                    const SizedBox(height: 4),
                    Text(
                      review['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final reply = await _showReplyDialog(review['customer']);
                    if (reply != null && reply.isNotEmpty) {
                      try {
                        await _apiService.replyToReview(review['id'], reply);
                        SnackBarHelper.showSuccess(context, 'Réponse envoyée',
                            emoji: '✓');
                        _loadReviews();
                      } catch (e) {
                        SnackBarHelper.showError(context, 'Erreur: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Répondre'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
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

  Future<String?> _showReplyDialog(String customerName) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Répondre à $customerName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Votre réponse...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
