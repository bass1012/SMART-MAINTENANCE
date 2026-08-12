class PaidOption {
  final String label;
  final double? price;
  final String? note;
  final bool isCustom;

  PaidOption({
    required this.label,
    this.price,
    this.note,
    this.isCustom = false,
  });

  factory PaidOption.fromJson(dynamic json) {
    if (json is String) {
      return PaidOption(label: json);
    }
    if (json is Map<String, dynamic>) {
      final p = json['price'];
      return PaidOption(
        label: (json['label'] ?? '').toString(),
        price: p != null ? double.tryParse(p.toString()) : null,
        note: json['note']?.toString(),
        isCustom: json['isCustom'] == true,
      );
    }
    return PaidOption(label: json.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'price': price,
      'note': note,
      'isCustom': isCustom,
    };
  }
}

class MaintenanceOffer {
  final int id;
  final String title;
  final String description;
  final double price;
  final String? priceNote;
  final int duration; // durée en mois
  final List<String> features;
  final List<PaidOption> paidOptions;
  final bool isActive;
  final String offerType;
  final String equipmentCategory;
  final String pricingMode;
  final int durationMonths;
  final double? originalPrice;
  final double? discountPercent;
  final int? visitsPerYear;
  final int? visitIntervalMonths;
  final String? cadenceLabel;
  final String? refrigerant;
  final bool includesFreon;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.priceNote,
    required this.duration,
    required this.features,
    this.paidOptions = const [],
    required this.isActive,
    this.offerType = 'on_demand',
    this.equipmentCategory = 'all',
    this.pricingMode = 'per_equipment',
    this.durationMonths = 1,
    this.originalPrice,
    this.discountPercent,
    this.visitsPerYear,
    this.visitIntervalMonths,
    this.cadenceLabel,
    this.refrigerant,
    this.includesFreon = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceOffer.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? 'Offre sans titre').toString();
    final description = (json['description'] ?? '').toString();
    final priceNote = json['priceNote'] ?? json['price_note'];
    final legacyText = '$title ${priceNote ?? ''} $description'.toLowerCase();

    String legacyOfferType() {
      const annualMarkers = [
        'abonnement',
        'annuel',
        '4 passages',
        '6 passages',
        'trimestriel',
        'bimestriel',
      ];
      return annualMarkers.any(legacyText.contains) ? 'annual' : 'on_demand';
    }

    String legacyEquipmentCategory() {
      if (legacyText.contains('cassette')) return 'cassette';
      if (legacyText.contains('gainable')) return 'gainable';
      if (legacyText.contains('allège') || legacyText.contains('allege')) {
        return 'allege';
      }
      if (legacyText.contains('armoire')) return 'armoire';
      if (legacyText.contains('mural')) return 'mural';
      return 'all';
    }

    int? legacyVisits() {
      final match =
          RegExp(r'(\d+)\s*(?:passages?|visites?)').firstMatch(legacyText);
      return match == null ? null : int.tryParse(match.group(1)!);
    }

    String? legacyRefrigerant() {
      final match = RegExp(r'\b(r\s?\d{2,3}[a-z]?)\b', caseSensitive: false)
          .firstMatch(legacyText);
      return match?.group(1)?.replaceAll(' ', '').toUpperCase();
    }

    final rawOfferType =
        json['offer_type'] ?? json['offerType'] ?? json['type'];
    final rawCategory = json['equipment_category'] ??
        json['equipmentCategory'] ??
        json['split_type'] ??
        json['splitType'];
    final hasStructuredFreonFlag =
        json.containsKey('includes_freon') || json.containsKey('includesFreon');

    return MaintenanceOffer(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: title,
      description: description,
      price: _asDouble(
              json['final_price'] ?? json['finalPrice'] ?? json['price']) ??
          0,
      priceNote: priceNote?.toString(),
      duration: _asInt(
            json['duration_months'] ??
                json['durationMonths'] ??
                json['duration'],
          ) ??
          12,
      features: _asStringList(json['features']),
      paidOptions: _asPaidOptionsList(
          json['paidOptions'] ?? json['paid_options']),
      isActive: _asBool(json['isActive'] ?? json['is_active']) ?? true,
      offerType:
          _normalizeOfferType(rawOfferType?.toString()) ?? legacyOfferType(),
      equipmentCategory: () {
        final norm = _normalizeEquipmentCategory(rawCategory?.toString());
        if (norm != null && norm != 'all') return norm;
        return legacyEquipmentCategory();
      }(),
      pricingMode:
          (json['pricing_mode'] ?? json['pricingMode'] ?? 'per_equipment')
              .toString(),
      durationMonths: _asInt(
            json['duration_months'] ??
                json['durationMonths'] ??
                json['duration'],
          ) ??
          1,
      originalPrice: _asDouble(
        json['original_price'] ?? json['originalPrice'] ?? json['base_price'],
      ),
      discountPercent: _asDouble(
        json['discount_percent'] ??
            json['discount_percentage'] ??
            json['annual_discount_percentage'] ??
            json['discountPercent'],
      ),
      visitsPerYear: _asInt(
            json['visits_per_year'] ??
                json['visitsPerYear'] ??
                json['visits_total'],
          ) ??
          legacyVisits(),
      visitIntervalMonths: _asInt(
        json['visit_interval_months'] ?? json['visitIntervalMonths'],
      ),
      cadenceLabel: (json['cadence_label'] ??
              json['cadenceLabel'] ??
              json['periodicity_label'] ??
              json['periodicity'])
          ?.toString(),
      refrigerant: (json['refrigerant'] ??
              json['refrigerant_type'] ??
              json['freon_type'] ??
              (hasStructuredFreonFlag ? null : legacyRefrigerant()))
          ?.toString(),
      includesFreon: _asBool(
            json['includes_freon'] ?? json['includesFreon'],
          ) ??
          (!hasStructuredFreonFlag && legacyText.contains('fréon inclus')),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _asDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'priceNote': priceNote,
      'duration': duration,
      'features': features,
      'paidOptions': paidOptions.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'offerType': offerType,
      'equipmentCategory': equipmentCategory,
      'pricingMode': pricingMode,
      'durationMonths': durationMonths,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'visitsPerYear': visitsPerYear,
      'visitIntervalMonths': visitIntervalMonths,
      'cadenceLabel': cadenceLabel,
      'refrigerant': refrigerant,
      'includesFreon': includesFreon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isAnnual => offerType == 'annual';

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') return true;
      if (value.toLowerCase() == 'false' || value == '0') return false;
    }
    return null;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }
    return const [];
  }

  static List<PaidOption> _asPaidOptionsList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => PaidOption.fromJson(item))
          .toList();
    }
    return const [];
  }

  static DateTime _asDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String? _normalizeOfferType(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'annual':
      case 'annual_subscription':
      case 'subscription':
      case 'scheduled':
      case 'yearly':
        return 'annual';
      case 'on_demand':
      case 'demand':
      case 'one_time':
      case 'one-off':
        return 'on_demand';
    }
    return null;
  }

  static String? _normalizeEquipmentCategory(String? value) {
    final normalized = value
        ?.trim()
        .toLowerCase()
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    switch (normalized) {
      case 'mural':
      case 'cassette':
      case 'gainable':
      case 'allege':
      case 'armoire':
      case 'all':
        return normalized;
      case 'allege_armoire':
        return 'allege_armoire';
    }
    return null;
  }
}
