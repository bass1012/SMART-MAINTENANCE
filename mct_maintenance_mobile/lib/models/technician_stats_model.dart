class TechnicianStats {
  final int totalInterventions;
  final int pendingInterventions;
  final int completedInterventions;
  final int inProgressInterventions;
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageRating;
  final int totalReviews;
  final int upcomingAppointments;

  TechnicianStats({
    required this.totalInterventions,
    required this.pendingInterventions,
    required this.completedInterventions,
    required this.inProgressInterventions,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageRating,
    required this.totalReviews,
    required this.upcomingAppointments,
  });

  factory TechnicianStats.fromJson(Map<String, dynamic> json) {
    return TechnicianStats(
      totalInterventions: json['total_interventions'] ?? 0,
      pendingInterventions: json['pending_interventions'] ?? 0,
      completedInterventions: json['completed_interventions'] ?? 0,
      inProgressInterventions: json['in_progress_interventions'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      upcomingAppointments: json['upcoming_appointments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_interventions': totalInterventions,
      'pending_interventions': pendingInterventions,
      'completed_interventions': completedInterventions,
      'in_progress_interventions': inProgressInterventions,
      'total_revenue': totalRevenue,
      'monthly_revenue': monthlyRevenue,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'upcoming_appointments': upcomingAppointments,
    };
  }
}
