import 'quote_item_model.dart';

class QuoteContract {
  final String id;
  final String reference;
  final String title;
  final String description;
  final double amount;
  final String status; // 'draft', 'sent', 'accepted', 'rejected', 'expired'
  final DateTime? validUntil;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason; // Raison du refus
  final DateTime? scheduledDate; // Date planifiée de l'intervention
  final String? secondContact; // Second contact pour l'intervention
  final String? paymentStatus; // 'pending', 'deferred', 'paid'
  final bool executeNow; // Exécution immédiate
  final List<QuoteItem> items; // Liste des articles

  QuoteContract({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.amount,
    required this.status,
    this.validUntil,
    required this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    this.scheduledDate,
    this.secondContact,
    this.paymentStatus,
    this.executeNow = false,
    this.items = const [],
  });

  factory QuoteContract.fromJson(Map<String, dynamic> json) {
    // Parser les items
    List<QuoteItem> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) => QuoteItem.fromJson(item))
          .toList();
    }

    return QuoteContract(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      title: json['title'] ?? 'Sans titre',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? json['total'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'draft',
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : (json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      secondContact: json['second_contact'],
      paymentStatus: json['payment_status'],
      executeNow: json['execute_now'] == true || json['execute_now'] == 1,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'title': title,
      'description': description,
      'amount': amount,
      'status': status,
      'validUntil': validUntil?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'second_contact': secondContact,
      'payment_status': paymentStatus,
      'execute_now': executeNow,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
