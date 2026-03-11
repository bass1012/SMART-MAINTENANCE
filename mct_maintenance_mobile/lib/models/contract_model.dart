class Contract {
  final int id;
  final int? subscriptionId;
  final String reference;
  final String title;
  final String description;
  final int customerId;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String paymentFrequency;
  final String? termsAndConditions;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Champs pour les contrats de maintenance programmés
  final bool isSubscription;
  final int? visitsTotal;
  final int? visitsCompleted;
  final DateTime? nextVisitDate;
  final String? equipmentDescription;
  final String? equipmentModel;
  final String? paymentStatus;
  // Champs split payment (50/50)
  final double? firstPaymentAmount;
  final String? firstPaymentStatus;
  final double? secondPaymentAmount;
  final String? secondPaymentStatus;

  Contract({
    required this.id,
    this.subscriptionId,
    required this.reference,
    required this.title,
    required this.description,
    required this.customerId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.paymentFrequency,
    this.termsAndConditions,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSubscription = false,
    this.visitsTotal,
    this.visitsCompleted,
    this.nextVisitDate,
    this.equipmentDescription,
    this.equipmentModel,
    this.paymentStatus,
    this.firstPaymentAmount,
    this.firstPaymentStatus,
    this.secondPaymentAmount,
    this.secondPaymentStatus,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] ?? json['price'] ?? 0).toDouble();
    final id = _parseId(json['id']);
    // Générer une référence si non fournie (format: CTR-ID)
    final reference =
        (json['reference'] != null && json['reference'].toString().isNotEmpty)
            ? json['reference'].toString()
            : 'CTR-$id';
    return Contract(
      id: id,
      subscriptionId: json['subscription_id'],
      reference: reference,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      customerId: json['customer_id'] ?? 0,
      type: json['type'] ?? 'maintenance',
      status: json['status'] ?? 'draft',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      amount: amount,
      paymentFrequency: json['payment_frequency'] ?? 'yearly',
      termsAndConditions: json['terms_and_conditions'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isSubscription: json['is_subscription'] ?? false,
      visitsTotal: json['visits_total'],
      visitsCompleted: json['visits_completed'],
      nextVisitDate: json['next_visit_date'] != null
          ? DateTime.parse(json['next_visit_date'])
          : null,
      equipmentDescription: json['equipment_description'],
      equipmentModel: json['equipment_model'],
      paymentStatus: json['payment_status'],
      // Split payment fields with fallback to calculated 50%
      firstPaymentAmount: json['first_payment_amount']?.toDouble() ??
          (amount / 2).ceilToDouble(),
      firstPaymentStatus: json['first_payment_status'] ?? 'pending',
      secondPaymentAmount: json['second_payment_amount']?.toDouble() ??
          (amount / 2).floorToDouble(),
      secondPaymentStatus: json['second_payment_status'] ?? 'pending',
    );
  }

  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) {
      // Handle "sub_123" format by extracting the number
      if (id.startsWith('sub_')) {
        return int.tryParse(id.substring(4)) ?? 0;
      }
      return int.tryParse(id) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'title': title,
      'description': description,
      'customer_id': customerId,
      'type': type,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'amount': amount,
      'payment_frequency': paymentFrequency,
      'terms_and_conditions': termsAndConditions,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
