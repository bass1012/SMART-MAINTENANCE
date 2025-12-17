import 'complaint_note_model.dart';

class Complaint {
  final String id;
  final String reference;
  final String title;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'rejected'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String? relatedTo; // 'service', 'product', 'billing', 'other'
  final String? relatedId; // ID de l'élément concerné
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final List<ComplaintNote>? notes; // Notes de suivi

  Complaint({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.relatedTo,
    this.relatedId,
    this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.notes,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    List<ComplaintNote>? notes;
    if (json['notes'] != null && json['notes'] is List) {
      notes = (json['notes'] as List)
          .map((note) => ComplaintNote.fromJson(note))
          .toList();
    }

    return Complaint(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      title: json['title'] ?? json['subject'] ?? 'Sans titre',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      relatedTo: json['relatedTo'],
      relatedId: json['relatedId']?.toString(),
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null 
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']) 
          : null,
      resolvedAt: json['resolvedAt'] != null || json['resolved_at'] != null
          ? DateTime.parse(json['resolvedAt'] ?? json['resolved_at'])
          : null,
      resolutionNotes: json['resolutionNotes'] ?? json['resolution'],
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (reference.isNotEmpty) 'reference': reference,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      if (relatedTo != null) 'relatedTo': relatedTo,
      if (relatedId != null) 'relatedId': relatedId,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    };
  }
}
