import 'package:flutter/foundation.dart';

// Classe pour représenter un équipement dans le rapport
class ReportEquipment {
  final int? index;
  final String? state;
  final String? type;
  final String? brand;
  final String? pression;
  final String? puissance;
  final String? intensite;
  final String? tension;

  ReportEquipment({
    this.index,
    this.state,
    this.type,
    this.brand,
    this.pression,
    this.puissance,
    this.intensite,
    this.tension,
  });

  factory ReportEquipment.fromJson(Map<String, dynamic> json) {
    return ReportEquipment(
      index: json['index'] as int?,
      state: json['state']?.toString(),
      type: json['type']?.toString(),
      brand: json['brand']?.toString(),
      pression: json['pression']?.toString(),
      puissance: json['puissance']?.toString(),
      intensite: json['intensite']?.toString(),
      tension: json['tension']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'state': state,
      'type': type,
      'brand': brand,
      'pression': pression,
      'puissance': puissance,
      'intensite': intensite,
      'tension': tension,
    };
  }

  bool get hasTechnicalMeasures =>
      (pression != null && pression!.isNotEmpty) ||
      (puissance != null && puissance!.isNotEmpty) ||
      (intensite != null && intensite!.isNotEmpty) ||
      (tension != null && tension!.isNotEmpty);
}

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
  // Équipements (nouveau format)
  final List<ReportEquipment>? equipments;
  // Mesures techniques (format legacy)
  final String? pression;
  final String? puissance;
  final String? intensite;
  final String? tension;

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
    this.equipments,
    this.pression,
    this.puissance,
    this.intensite,
    this.tension,
  });

  factory MaintenanceReport.fromJson(Map<String, dynamic> json) {
    try {
      // Parser les équipements si disponibles
      List<ReportEquipment>? equipmentsList;
      if (json['equipments'] != null && json['equipments'] is List) {
        equipmentsList = (json['equipments'] as List)
            .map((e) => ReportEquipment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

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
        // Équipements
        equipments: equipmentsList,
        // Mesures techniques legacy
        pression: json['pression']?.toString(),
        puissance:
            json['puissance']?.toString() ?? json['temperature']?.toString(),
        intensite: json['intensite']?.toString(),
        tension: json['tension']?.toString(),
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
      'equipments': equipments?.map((e) => e.toJson()).toList(),
      'pression': pression,
      'puissance': puissance,
      'intensite': intensite,
      'tension': tension,
    };
  }

  // Vérifie si le rapport a des mesures techniques (nouveau ou legacy)
  bool get hasTechnicalMeasures {
    if (equipments != null && equipments!.isNotEmpty) {
      return equipments!.any((e) => e.hasTechnicalMeasures);
    }
    return (pression != null && pression!.isNotEmpty) ||
        (puissance != null && puissance!.isNotEmpty) ||
        (intensite != null && intensite!.isNotEmpty) ||
        (tension != null && tension!.isNotEmpty);
  }
}
