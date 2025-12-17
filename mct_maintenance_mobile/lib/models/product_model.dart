import '../config/environment.dart';

class ProductModel {
  final int id;
  final String sku;
  final String nom;
  final String? description;
  final double prix;
  final int? quantiteStock;
  final String? imageUrl;
  final int? categorieId;
  final int? marqueId;
  final bool? actif;
  final String? specifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.sku,
    required this.nom,
    this.description,
    required this.prix,
    this.quantiteStock,
    this.imageUrl,
    this.categorieId,
    this.marqueId,
    this.actif,
    this.specifications,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où images est un tableau
    String? imageUrl;
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final imagePath = json['images'][0];
      // Construire l'URL complète de l'image en utilisant la configuration centralisée
      imageUrl = imagePath.startsWith('http') 
          ? imagePath 
          : '${AppConfig.baseUrl}$imagePath';
    } else if (json['image_url'] != null) {
      final imagePath = json['image_url'];
      imageUrl = imagePath.startsWith('http') 
          ? imagePath 
          : '${AppConfig.baseUrl}$imagePath';
    }
    
    return ProductModel(
      id: json['id'],
      sku: json['reference'] ?? json['sku'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      prix: (json['prix'] ?? 0).toDouble(),
      quantiteStock: json['quantite_stock'],
      imageUrl: imageUrl,
      categorieId: json['categorie_id'],
      marqueId: json['marque_id'],
      actif: json['actif'] ?? true,
      specifications: json['specifications']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'nom': nom,
      'description': description,
      'prix': prix,
      'quantite_stock': quantiteStock,
      'image_url': imageUrl,
      'categorie_id': categorieId,
      'marque_id': marqueId,
      'actif': actif,
      'specifications': specifications,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get inStock => (quantiteStock ?? 0) > 0;
}
