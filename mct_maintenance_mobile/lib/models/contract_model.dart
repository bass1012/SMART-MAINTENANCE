class Contract {
  final int id;
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

  Contract({
    required this.id,
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
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
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
      amount: (json['amount'] ?? 0).toDouble(),
      paymentFrequency: json['payment_frequency'] ?? 'yearly',
      termsAndConditions: json['terms_and_conditions'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
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
