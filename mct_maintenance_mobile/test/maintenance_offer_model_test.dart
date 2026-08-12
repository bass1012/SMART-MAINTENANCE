import 'package:flutter_test/flutter_test.dart';
import 'package:mct_maintenance_mobile/models/maintenance_offer_model.dart';

void main() {
  group('MaintenanceOffer.fromJson', () {
    test('uses structured merchandising fields as the source of truth', () {
      final offer = MaintenanceOffer.fromJson({
        'id': 42,
        'title': 'Entretien ponctuel dans le titre historique',
        'description': 'Ancien texte libre trompeur',
        'price': '95000.00',
        'offer_type': 'annual',
        'equipment_category': 'allege_armoire',
        'pricing_mode': 'flat',
        'duration_months': 12,
        'visits_total': 4,
        'visit_interval_months': 3,
        'annual_discount_percentage': '5.00',
        'includes_freon': true,
        'features': ['Nettoyage', 'Rapport'],
        'is_active': true,
      });

      expect(offer.isAnnual, isTrue);
      expect(offer.equipmentCategory, 'allege_armoire');
      expect(offer.pricingMode, 'flat');
      expect(offer.durationMonths, 12);
      expect(offer.visitsPerYear, 4);
      expect(offer.visitIntervalMonths, 3);
      expect(offer.discountPercent, 5);
      expect(offer.includesFreon, isTrue);
      expect(offer.price, 95000);
    });

    test('keeps legacy text fallbacks for offers without structured fields',
        () {
      final offer = MaintenanceOffer.fromJson({
        'id': '7',
        'title': 'Abonnement cassette R410A',
        'description': '4 passages par an, fréon inclus',
        'price': 100000,
      });

      expect(offer.isAnnual, isTrue);
      expect(offer.equipmentCategory, 'cassette');
      expect(offer.visitsPerYear, 4);
      expect(offer.refrigerant, 'R410A');
      expect(offer.includesFreon, isTrue);
    });

    test('does not classify an unknown legacy offer as mural', () {
      final offer = MaintenanceOffer.fromJson({
        'id': 8,
        'title': 'Entretien standard',
        'price': 25000,
        'features': 'invalid legacy value',
      });

      expect(offer.offerType, 'on_demand');
      expect(offer.equipmentCategory, 'all');
      expect(offer.features, isEmpty);
    });

    test('structured freon flag overrides misleading legacy text', () {
      final offer = MaintenanceOffer.fromJson({
        'id': 9,
        'title': 'Split mural R410A',
        'price': 30000,
        'includes_freon': false,
      });

      expect(offer.includesFreon, isFalse);
      expect(offer.refrigerant, isNull);
    });
  });
}
