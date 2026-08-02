class RepairService {
  final int id;
  final String title;
  final String? model;
  final double? price;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RepairService({
    required this.id,
    required this.title,
    this.model,
    this.price,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepairService.fromJson(Map<String, dynamic> json) {
    return RepairService(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] ?? '',
      model: json['model'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      description: json['description'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'model': model,
      'price': price,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
