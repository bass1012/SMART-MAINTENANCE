class MaintenanceOffer {
  final int id;
  final String title;
  final String description;
  final double price;
  final int duration; // durée en mois
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceOffer.fromJson(Map<String, dynamic> json) {
    return MaintenanceOffer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Offre sans titre',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] is int ? json['duration'] : int.tryParse(json['duration'].toString()) ?? 12,
      features: json['features'] != null ? List<String>.from(json['features']) : [],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'features': features,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
