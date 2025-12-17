class DashboardStats {
  final int totalInterventions;
  final int pendingInterventions;
  final int completedInterventions;
  final int totalQuotes;
  final int pendingQuotes;
  final int acceptedQuotes;
  final int totalOrders;
  final int totalComplaints;
  final int pendingComplaints;
  final int totalContracts;
  final int activeContracts;
  final double totalSpent;
  final int upcomingMaintenances;

  DashboardStats({
    required this.totalInterventions,
    required this.pendingInterventions,
    required this.completedInterventions,
    required this.totalQuotes,
    required this.pendingQuotes,
    required this.acceptedQuotes,
    required this.totalOrders,
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.totalContracts,
    required this.activeContracts,
    required this.totalSpent,
    required this.upcomingMaintenances,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalInterventions: json['totalInterventions'] ?? 0,
      pendingInterventions: json['pendingInterventions'] ?? 0,
      completedInterventions: json['completedInterventions'] ?? 0,
      totalQuotes: json['totalQuotes'] ?? 0,
      pendingQuotes: json['pendingQuotes'] ?? 0,
      acceptedQuotes: json['acceptedQuotes'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalComplaints: json['totalComplaints'] ?? 0,
      pendingComplaints: json['pendingComplaints'] ?? 0,
      totalContracts: json['totalContracts'] ?? 0,
      activeContracts: json['activeContracts'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      upcomingMaintenances: json['upcomingMaintenances'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInterventions': totalInterventions,
      'pendingInterventions': pendingInterventions,
      'completedInterventions': completedInterventions,
      'totalQuotes': totalQuotes,
      'pendingQuotes': pendingQuotes,
      'acceptedQuotes': acceptedQuotes,
      'totalOrders': totalOrders,
      'totalComplaints': totalComplaints,
      'pendingComplaints': pendingComplaints,
      'totalContracts': totalContracts,
      'activeContracts': activeContracts,
      'totalSpent': totalSpent,
      'upcomingMaintenances': upcomingMaintenances,
    };
  }
}
