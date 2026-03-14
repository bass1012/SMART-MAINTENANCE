class UserModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? role;
  final String? status;
  final bool? emailVerified;
  final bool? phoneVerified;
  final String? profileImage;
  final Map<String, dynamic>? preferences;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Helper pour parser les valeurs qui peuvent être String ou num
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.role,
    this.status,
    this.emailVerified,
    this.phoneVerified,
    this.profileImage,
    this.preferences,
    this.latitude,
    this.longitude,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Si json contient 'user' et 'profile', fusionner les données
    final userData = json['user'] ?? json;
    final profileData = json['profile'] ?? {};

    return UserModel(
      id: userData['id']?.toString(),
      firstName: userData['first_name'] ??
          userData['firstName'] ??
          profileData['first_name'] ??
          profileData['firstName'],
      lastName: userData['last_name'] ??
          userData['lastName'] ??
          profileData['last_name'] ??
          profileData['lastName'],
      email: userData['email'],
      phone: userData['phone'] ?? profileData['phone'],
      role: userData['role'],
      status: userData['status'],
      emailVerified:
          userData['email_verified'] ?? userData['emailVerified'] ?? false,
      phoneVerified:
          userData['phone_verified'] ?? userData['phoneVerified'] ?? false,
      profileImage: userData['profile_image'] ?? userData['profileImage'],
      preferences: userData['preferences'] is Map
          ? Map<String, dynamic>.from(userData['preferences'])
          : {},
      latitude: _parseDouble(userData['latitude'] ?? profileData['latitude']),
      longitude:
          _parseDouble(userData['longitude'] ?? profileData['longitude']),
      address: userData['address'] ?? profileData['address'],
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'])
          : null,
      updatedAt: userData['updatedAt'] != null
          ? DateTime.parse(userData['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'profile_image': profileImage,
      'preferences': preferences,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Crée une copie de l'utilisateur avec des mises à jour optionnelles
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? status,
    bool? emailVerified,
    bool? phoneVerified,
    String? profileImage,
    Map<String, dynamic>? preferences,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      profileImage: profileImage ?? this.profileImage,
      preferences: preferences ?? this.preferences,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
