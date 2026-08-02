import 'package:flutter/foundation.dart';

// Classe pour représenter un équipement dans le rapport
// Classe pour représenter un équipement dans le rapport (support format 2 étapes)
class ReportEquipment {
  final int? index;
  final String? state;
  final String? type;
  final String? brand;
  final String? location;
  final bool? functionalTest;
  final bool? finalTest;
  // Mesures AVANT
  final String? beforePression;
  final String? beforeFreon;
  final String? beforePuissance;
  final String? beforeIntensite;
  final String? beforeTension;
  // Mesures APRÈS
  final String? afterPression;
  final String? afterFreon;
  final String? afterPuissance;
  final String? afterIntensite;
  final String? afterTension;
  // Legacy fallbacks
  final String? pression;
  final String? freon;
  final String? puissance;
  final String? intensite;
  final String? tension;

  ReportEquipment({
    this.index,
    this.state,
    this.type,
    this.brand,
    this.location,
    this.functionalTest,
    this.finalTest,
    this.beforePression,
    this.beforeFreon,
    this.beforePuissance,
    this.beforeIntensite,
    this.beforeTension,
    this.afterPression,
    this.afterFreon,
    this.afterPuissance,
    this.afterIntensite,
    this.afterTension,
    this.pression,
    this.freon,
    this.puissance,
    this.intensite,
    this.tension,
  });

  factory ReportEquipment.fromJson(Map<String, dynamic> json) {
    bool? parseBool(dynamic val) {
      if (val == null) return null;
      if (val is bool) return val;
      if (val.toString().toLowerCase() == 'true' || val.toString() == '1' || val.toString().toLowerCase() == 'oui') return true;
      if (val.toString().toLowerCase() == 'false' || val.toString() == '0' || val.toString().toLowerCase() == 'non') return false;
      return null;
    }

    final bp = json['before_pression']?.toString() ?? json['pression']?.toString();
    final bf = json['before_freon']?.toString() ?? json['freon']?.toString();
    final bpow = json['before_puissance']?.toString() ?? json['puissance']?.toString();
    final bi = json['before_intensite']?.toString() ?? json['intensite']?.toString();
    final bt = json['before_tension']?.toString() ?? json['tension']?.toString();

    final ap = json['after_pression']?.toString();
    final af = json['after_freon']?.toString();
    final apow = json['after_puissance']?.toString();
    final ai = json['after_intensite']?.toString();
    final at = json['after_tension']?.toString();

    return ReportEquipment(
      index: json['index'] as int?,
      state: json['state']?.toString() ?? json['initial_state']?.toString(),
      type: json['type']?.toString(),
      brand: json['brand']?.toString(),
      location: json['location']?.toString(),
      functionalTest: parseBool(json['functional_test'] ?? json['tested']),
      finalTest: parseBool(json['final_test']),
      beforePression: bp,
      beforeFreon: bf,
      beforePuissance: bpow,
      beforeIntensite: bi,
      beforeTension: bt,
      afterPression: ap,
      afterFreon: af,
      afterPuissance: apow,
      afterIntensite: ai,
      afterTension: at,
      pression: bp,
      freon: bf,
      puissance: bpow,
      intensite: bi,
      tension: bt,
    );
  }

  bool get hasBeforeMeasures =>
      (beforePression != null && beforePression!.isNotEmpty) ||
      (beforeFreon != null && beforeFreon!.isNotEmpty) ||
      (beforePuissance != null && beforePuissance!.isNotEmpty) ||
      (beforeIntensite != null && beforeIntensite!.isNotEmpty) ||
      (beforeTension != null && beforeTension!.isNotEmpty);

  bool get hasAfterMeasures =>
      (afterPression != null && afterPression!.isNotEmpty) ||
      (afterFreon != null && afterFreon!.isNotEmpty) ||
      (afterPuissance != null && afterPuissance!.isNotEmpty) ||
      (afterIntensite != null && afterIntensite!.isNotEmpty) ||
      (afterTension != null && afterTension!.isNotEmpty);

  bool get hasTechnicalMeasures => hasBeforeMeasures || hasAfterMeasures;
}

class MaintenanceReport {
  final String id;
  final String? reference;
  final String? title;
  final String? description;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String? technicianName;
  final String? technicianNotes;
  final String? customerNotes;
  final List<String>? imageUrls;
  final List<String>? photosBefore;
  final List<String>? photosAfter;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ReportEquipment>? equipments;
  final String? pression;
  final String? freon;
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
    this.photosBefore,
    this.photosAfter,
    this.createdAt,
    this.updatedAt,
    this.equipments,
    this.pression,
    this.freon,
    this.puissance,
    this.intensite,
    this.tension,
  });

  factory MaintenanceReport.fromJson(Map<String, dynamic> json) {
    try {
      List<ReportEquipment>? equipmentsList;
      if (json['equipments'] != null && json['equipments'] is List) {
        equipmentsList = (json['equipments'] as List)
            .map((e) => ReportEquipment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final photosBefore = json['photos_before'] != null && json['photos_before'] is List
          ? (json['photos_before'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final photosAfter = json['photos_after'] != null && json['photos_after'] is List
          ? (json['photos_after'] as List).map((e) => e.toString()).toList()
          : <String>[];

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
            : [...photosBefore, ...photosAfter],
        photosBefore: photosBefore,
        photosAfter: photosAfter,
        createdAt: json['createdAt'] != null &&
                json['createdAt'].toString().isNotEmpty
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt:
            json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty
                ? DateTime.tryParse(json['updatedAt'].toString())
                : null,
        equipments: equipmentsList,
        pression: json['pression']?.toString(),
        freon: json['freon']?.toString(),
        puissance:
            json['puissance']?.toString() ?? json['temperature']?.toString(),
        intensite: json['intensite']?.toString(),
        tension: json['tension']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing MaintenanceReport: $e');
      rethrow;
    }
  }

  bool get hasTechnicalMeasures {
    if (equipments != null && equipments!.isNotEmpty) {
      return equipments!.any((e) => e.hasTechnicalMeasures);
    }
    return (pression != null && pression!.isNotEmpty) ||
        (freon != null && freon!.isNotEmpty) ||
        (puissance != null && puissance!.isNotEmpty) ||
        (intensite != null && intensite!.isNotEmpty) ||
        (tension != null && tension!.isNotEmpty);
  }
}
