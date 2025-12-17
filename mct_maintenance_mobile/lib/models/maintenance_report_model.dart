import 'dart:developer';
import 'package:flutter/foundation.dart';

class MaintenanceReport {
  final String id;
  final String? reference;
  final String? title;
  final String? description;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String? technicianName;
  final String? technicianNotes;
  final String? customerNotes;
  final List<String>? imageUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceReport({
    required this.id,
    this.reference,
    this.title,
    this.description,
    this.status = 'scheduled',
    this.scheduledDate,
    this.completedDate,
    this.technicianName,
    this.technicianNotes,
    this.customerNotes,
    this.imageUrls,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceReport.fromJson(Map<String, dynamic> json) {
    try {
      return MaintenanceReport(
        id: json['id']?.toString() ?? '',
        reference: json['reference']?.toString(),
        title: json['title']?.toString() ?? 'Rapport sans titre',
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? 'scheduled',
        scheduledDate: json['scheduledDate'] != null &&
                json['scheduledDate'].toString().isNotEmpty
            ? DateTime.tryParse(json['scheduledDate'].toString())
            : null,
        completedDate: json['completedDate'] != null &&
                json['completedDate'].toString().isNotEmpty
            ? DateTime.tryParse(json['completedDate'].toString())
            : null,
        technicianName:
            json['technicianName']?.toString() ?? 'Technicien non attribué',
        technicianNotes: json['technicianNotes']?.toString(),
        customerNotes: json['customerNotes']?.toString(),
        imageUrls: json['imageUrls'] != null
            ? (json['imageUrls'] as List).map((e) => e.toString()).toList()
            : null,
        createdAt: json['createdAt'] != null &&
                json['createdAt'].toString().isNotEmpty
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt:
            json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty
                ? DateTime.tryParse(json['updatedAt'].toString())
                : null,
      );
    } catch (e) {
      debugPrint('Error parsing MaintenanceReport: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'title': title,
      'description': description,
      'status': status,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'technicianName': technicianName,
      'technicianNotes': technicianNotes,
      'customerNotes': customerNotes,
      'imageUrls': imageUrls,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
