/// Modèle Split - Représente une unité de climatisation individuelle
///
/// Un client peut avoir plusieurs splits, et chaque split peut avoir
/// sa propre offre d'entretien (abonnement).
class Split {
  final int id;
  final String splitCode;
  final String? qrCodeUrl;
  final int customerId;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? power;
  final String? powerType;
  final String? location;
  final String? floor;
  final DateTime? installationDate;
  final DateTime? warrantyEndDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String status;
  final String? notes;
  final String? photoUrl;
  final int interventionCount;
  final String? installationAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relations
  final SplitCustomer? customer;
  final SplitActiveOffer? activeOffer;

  Split({
    required this.id,
    required this.splitCode,
    this.qrCodeUrl,
    required this.customerId,
    this.brand,
    this.model,
    this.serialNumber,
    this.power,
    this.powerType,
    this.location,
    this.floor,
    this.installationDate,
    this.warrantyEndDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.status = 'active',
    this.notes,
    this.photoUrl,
    this.interventionCount = 0,
    this.installationAddress,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.activeOffer,
  });

  factory Split.fromJson(Map<String, dynamic> json) {
    return Split(
      id: json['id'] ?? 0,
      splitCode: json['split_code'] ?? json['splitCode'] ?? '',
      qrCodeUrl: json['qr_code_url'] ?? json['qrCodeUrl'],
      customerId: json['customer_id'] ?? json['customerId'] ?? 0,
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serial_number'] ?? json['serialNumber'],
      power: json['power'],
      powerType: json['power_type'] ?? json['powerType'] ?? 'BTU',
      location: json['location'],
      floor: json['floor'],
      installationDate: json['installation_date'] != null
          ? DateTime.tryParse(json['installation_date'].toString())
          : null,
      warrantyEndDate: json['warranty_end_date'] != null
          ? DateTime.tryParse(json['warranty_end_date'].toString())
          : null,
      lastMaintenanceDate: json['last_maintenance_date'] != null
          ? DateTime.tryParse(json['last_maintenance_date'].toString())
          : null,
      nextMaintenanceDate: json['next_maintenance_date'] != null
          ? DateTime.tryParse(json['next_maintenance_date'].toString())
          : null,
      status: json['status'] ?? 'active',
      notes: json['notes'],
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      interventionCount:
          json['intervention_count'] ?? json['interventionCount'] ?? 0,
      installationAddress:
          json['installation_address'] ?? json['installationAddress'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      customer: json['customer'] != null
          ? SplitCustomer.fromJson(json['customer'])
          : null,
      activeOffer: json['activeOffer'] != null
          ? SplitActiveOffer.fromJson(json['activeOffer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'split_code': splitCode,
      'qr_code_url': qrCodeUrl,
      'customer_id': customerId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'power': power,
      'power_type': powerType,
      'location': location,
      'floor': floor,
      'installation_date': installationDate?.toIso8601String(),
      'warranty_end_date': warrantyEndDate?.toIso8601String(),
      'last_maintenance_date': lastMaintenanceDate?.toIso8601String(),
      'next_maintenance_date': nextMaintenanceDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'photo_url': photoUrl,
      'intervention_count': interventionCount,
      'installation_address': installationAddress,
    };
  }

  /// Retourne le nom complet du split (marque + modèle ou localisation)
  String get displayName {
    if (brand != null && model != null) {
      return '$brand $model';
    } else if (location != null) {
      return 'Split - $location';
    }
    return 'Split $splitCode';
  }

  /// Retourne la puissance formatée
  String get formattedPower {
    if (power == null) return 'Non spécifiée';
    return '$power ${powerType ?? 'BTU'}';
  }

  /// Vérifie si le split a une offre active
  bool get hasActiveOffer => activeOffer != null;

  /// Vérifie si le split est sous garantie
  bool get isUnderWarranty {
    if (warrantyEndDate == null) return false;
    return warrantyEndDate!.isAfter(DateTime.now());
  }

  /// Retourne le statut traduit en français
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'out_of_service':
        return 'Hors service';
      case 'pending_installation':
        return 'En attente d\'installation';
      default:
        return status;
    }
  }
}

/// Client propriétaire du split
class SplitCustomer {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  SplitCustomer({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory SplitCustomer.fromJson(Map<String, dynamic> json) {
    return SplitCustomer(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Client #$id';
  }
}

/// Offre active associée au split
class SplitActiveOffer {
  final int id;
  final String title;
  final String? description;
  final List<String>? features;
  final double price;
  final DateTime? endDate;

  SplitActiveOffer({
    required this.id,
    required this.title,
    this.description,
    this.features,
    required this.price,
    this.endDate,
  });

  factory SplitActiveOffer.fromJson(Map<String, dynamic> json) {
    List<String>? featuresList;
    if (json['features'] != null) {
      if (json['features'] is List) {
        featuresList =
            (json['features'] as List).map((e) => e.toString()).toList();
      } else if (json['features'] is String) {
        try {
          final decoded = json['features'];
          if (decoded is List) {
            featuresList = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    return SplitActiveOffer(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['offer_title'] ?? 'Offre',
      description: json['description'] ?? json['offer_description'],
      features: featuresList,
      price: (json['price'] ?? 0).toDouble(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
    );
  }

  /// Vérifie si l'offre expire bientôt (dans les 30 jours)
  bool get expiresSoon {
    if (endDate == null) return false;
    return endDate!.difference(DateTime.now()).inDays <= 30;
  }

  /// Jours restants avant expiration
  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }
}

/// Résultat d'un scan QR de split
class SplitScanResult {
  final Split split;
  final SplitActiveOffer? activeOffer;
  final bool hasActiveOffer;
  final List<SplitRecentIntervention>? recentInterventions;

  SplitScanResult({
    required this.split,
    this.activeOffer,
    required this.hasActiveOffer,
    this.recentInterventions,
  });

  factory SplitScanResult.fromJson(Map<String, dynamic> json) {
    List<SplitRecentIntervention>? interventions;
    if (json['recentInterventions'] != null) {
      interventions = (json['recentInterventions'] as List)
          .map((e) => SplitRecentIntervention.fromJson(e))
          .toList();
    }

    return SplitScanResult(
      split: Split.fromJson(json['split'] ?? {}),
      activeOffer: json['activeOffer'] != null
          ? SplitActiveOffer.fromJson(json['activeOffer'])
          : null,
      hasActiveOffer: json['hasActiveOffer'] ?? false,
      recentInterventions: interventions,
    );
  }
}

/// Intervention récente sur un split
class SplitRecentIntervention {
  final int id;
  final String? title;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? createdAt;

  SplitRecentIntervention({
    required this.id,
    this.title,
    required this.status,
    this.scheduledDate,
    this.createdAt,
  });

  factory SplitRecentIntervention.fromJson(Map<String, dynamic> json) {
    return SplitRecentIntervention(
      id: json['id'] ?? 0,
      title: json['title'],
      status: json['status'] ?? 'unknown',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
