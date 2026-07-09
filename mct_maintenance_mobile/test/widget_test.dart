// Non-regression tests for MCT Maintenance Mobile
// Validates that the api_service.dart → repository refactoring didn't break
// the core business logic of Interventions and Invoices screens.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/payment_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/interventions_list_screen.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/invoices_screen.dart';
import 'package:mct_maintenance_mobile/models/maintenance_report_model.dart';

// ─── Minimal fake implementations ──────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  final Map<String, dynamic>? _user;
  _FakeAuthRepository({Map<String, dynamic>? user})
      : _user = user ??
            const {'id': 1, 'role': 'customer', 'email': 'test@test.com'};

  @override
  Future<Map<String, dynamic>?> getUserData() async => _user;
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> loadSavedToken() async {}
  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {}
  @override
  Future<Map<String, dynamic>> getProfile() async => {
        'success': true,
        'data': {'user': _user}
      };
  @override
  Future<void> logout() async {}
  @override
  Future<Map<String, dynamic>> login(String e, String p) async => {};
  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> d) async => {};
  @override
  Future<Map<String, dynamic>> forgotPassword(String e) async => {};
  @override
  Future<Map<String, dynamic>> requestResetCode(String e) async => {};
  @override
  Future<Map<String, dynamic>> checkResetCode(String e, String c) async => {};
  @override
  Future<Map<String, dynamic>> verifyResetCode(
          String e, String c, String p) async =>
      {};
  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> d) async =>
      {};
  @override
  Future<String> uploadAvatar(String path) async => '';
  @override
  Future<Map<String, dynamic>> changePassword(
          {required String currentPassword,
          required String newPassword}) async =>
      {};
  @override
  Future<Map<String, dynamic>> deleteAccount() async => {};
  @override
  Future<List<int>> exportData() async => [];
  @override
  Future<Map<String, dynamic>> verifyEmailCode(String e, String c) async => {};
  @override
  Future<Map<String, dynamic>> resendVerificationCode(String e,
          {String verificationMethod = 'auto'}) async =>
      {};
  @override
  Future<Map<String, dynamic>> updateWorkingHours(
          Map<String, dynamic> h) async =>
      {};
}

class _FakeInterventionRepository implements InterventionRepository {
  final List<Map<String, dynamic>> _data;
  _FakeInterventionRepository({List<Map<String, dynamic>>? data})
      : _data = data ?? const [];

  @override
  Future<Map<String, dynamic>> getInterventions(
          {int? customerId, String? status}) async =>
      {
        'data': {'interventions': _data}
      };
  @override
  Future<List<Map<String, dynamic>>> getPendingDiagnosticPayments() async => [];
  @override
  Future<List<Map<String, dynamic>>> getPendingConfirmationReports() async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> getUnratedInterventions() async => [];
  @override
  Future<Map<String, dynamic>> createIntervention(
          Map<String, dynamic> d) async =>
      {};
  @override
  Future<Map<String, dynamic>> createInterventionWithImages(
          {required Map<String, dynamic> data, List<File>? images}) async =>
      {};
  @override
  Future<Map<String, dynamic>> getDiagnosticConfig() async => {};
  @override
  Future<Map<String, dynamic>> getTechnicianInterventions(
          {String? status}) async =>
      {'data': []};
  @override
  Future<Map<String, dynamic>> getRecentInterventions({int limit = 5}) async =>
      {'data': []};
  @override
  Future<Map<String, dynamic>> getDashboardStats() async => {};
  @override
  Future<Map<String, dynamic>> getTechnicianStats() async => {};
  @override
  Future<Map<String, dynamic>> updateTechnicianAvailability(String s) async =>
      {};
  @override
  Future<Map<String, dynamic>> getInterventionById(int id) async => {};
  @override
  Future<Map<String, dynamic>> cancelIntervention(int id) async => {};
  @override
  Future<Map<String, dynamic>> rateIntervention(
          int id, int r, String rev) async =>
      {};
  @override
  Future<Map<String, dynamic>> confirmInterventionCompletion(int id, bool c,
          {String? rejectionReason}) async =>
      {};
  @override
  Future<List<MaintenanceReport>> getMaintenanceReports() async => [];
  @override
  Future<Map<String, dynamic>> acceptIntervention(int id) async => {};
  @override
  Future<Map<String, dynamic>> markInterventionOnTheWay(int id) async => {};
  @override
  Future<Map<String, dynamic>> markInterventionArrived(int id) async => {};
  @override
  Future<Map<String, dynamic>> startIntervention(int id) async => {};
  @override
  Future<Map<String, dynamic>> completeIntervention(int id) async => {};
  @override
  Future<Map<String, dynamic>> submitInterventionReport(
          int id, Map<String, dynamic> d) async =>
      {};
  @override
  Future<Map<String, dynamic>> submitDiagnosticReport(
          Map<String, dynamic> d) async =>
      {};
  @override
  Future<Map<String, dynamic>> getTechnicianCalendar(
          {String? startDate, String? endDate}) async =>
      {};
  @override
  Future<Map<String, dynamic>> getTechnicianReports() async => {};
  @override
  Future<String> downloadTechnicianReport(int id) async => '';
  @override
  Future<Map<String, dynamic>> getTechnicianReviews() async => {};
  @override
  Future<Map<String, dynamic>> replyToReview(int id, String r) async => {};
  @override
  Future<Map<String, dynamic>> suggestTechnicians(
          {required int interventionId, int maxResults = 10}) async =>
      {};
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Map<String, dynamic>>> getPendingSubscriptionPayments() async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> getSubscriptions() async => [];
  @override
  Future<Map<String, dynamic>> getSubscriptionDetails(int id) async => {};
  @override
  Future<Map<String, dynamic>> cancelSubscription(int id) async => {};
  @override
  Future<Map<String, dynamic>> createServiceSubscription(
          {required int serviceId, required String serviceType}) async =>
      {};
}

class _FakePaymentRepository implements PaymentRepository {
  final List<Map<String, dynamic>> _history;
  _FakePaymentRepository({List<Map<String, dynamic>>? history})
      : _history = history ?? const [];

  @override
  Future<Map<String, dynamic>> getPaymentHistory() async => {'data': _history};
  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String r) async => {};
  @override
  Future<Map<String, dynamic>> initializeContractPayment(
          {required int contractId,
          required double amount,
          required String reference,
          required int phase,
          String? redirectUrl,
          bool? autoRedirect}) async =>
      {};
  @override
  Future<Map<String, dynamic>> initializeDiagnosticPayment(
          {required int interventionId,
          required double amount,
          required String reference,
          String? redirectUrl,
          bool? autoRedirect}) async =>
      {};
  @override
  Future<Map<String, dynamic>> initializeOrderPayment(
          {required int orderId,
          required double amount,
          required String reference,
          int paymentStep = 1,
          String? redirectUrl,
          bool? autoRedirect}) async =>
      {};
  @override
  Future<Map<String, dynamic>> initializeSubscriptionPayment(
          {required int subscriptionId,
          required double amount,
          required String reference,
          String? redirectUrl,
          bool? autoRedirect}) async =>
      {};
  @override
  Future<List<int>> downloadInvoicePDF(String orderId) async => [];
  @override
  Future<Map<String, dynamic>> verifyOrderPayment(int orderId) async => {};
  @override
  Future<Map<String, dynamic>> verifyDiagnosticPayment(int interventionId) async => {};
  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment(int subscriptionId) async => {};
}

// ─── Test helpers ───────────────────────────────────────────────────────────

Widget _withInterventionProviders(
  Widget child, {
  _FakeAuthRepository? auth,
  _FakeInterventionRepository? interventions,
  _FakeSubscriptionRepository? subscriptions,
}) {
  return MultiProvider(
    providers: [
      Provider<AuthRepository>(create: (_) => auth ?? _FakeAuthRepository()),
      Provider<InterventionRepository>(
          create: (_) => interventions ?? _FakeInterventionRepository()),
      Provider<SubscriptionRepository>(
          create: (_) => subscriptions ?? _FakeSubscriptionRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

Widget _withInvoiceProviders(Widget child, {_FakePaymentRepository? payments}) {
  return MultiProvider(
    providers: [
      Provider<PaymentRepository>(
          create: (_) => payments ?? _FakePaymentRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('InterventionsListScreen', () {
    testWidgets('shows empty state when no interventions', (tester) async {
      await tester.pumpWidget(
        _withInterventionProviders(const InterventionsListScreen()),
      );
      await tester.pump(); // trigger build
      await tester.pump(const Duration(seconds: 1)); // await async load

      expect(find.byType(InterventionsListScreen), findsOneWidget);
      // Empty state widget should be visible
      expect(find.text('Aucune intervention'), findsOneWidget);
    });

    testWidgets('renders intervention cards for each item returned',
        (tester) async {
      final fakeInterventions = [
        {
          'id': 1,
          'title': 'Réparation climatiseur',
          'status': 'pending',
          'address': '12 rue de la Paix',
          'scheduled_date': '2026-04-30T09:00:00Z',
          'description': 'AC en panne',
          'type': 'Climatisation',
          'priority': 'high',
        },
        {
          'id': 2,
          'title': 'Plomberie urgente',
          'status': 'accepted',
          'address': '5 avenue de l\'Indépendance',
          'scheduled_date': '2026-04-30T14:00:00Z',
          'description': 'Fuite importante',
          'type': 'Plomberie',
          'priority': 'high',
        },
      ];

      await tester.pumpWidget(
        _withInterventionProviders(
          const InterventionsListScreen(),
          interventions: _FakeInterventionRepository(data: fakeInterventions),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Both titles should appear in the list
      expect(find.text('Réparation climatiseur'), findsAtLeastNWidgets(1));
      expect(find.text('Plomberie urgente'), findsAtLeastNWidgets(1));
    });
  });

  group('InvoicesScreen', () {
    testWidgets('shows empty state when no invoices', (tester) async {
      await tester.pumpWidget(
        _withInvoiceProviders(const InvoicesScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InvoicesScreen), findsOneWidget);
      expect(find.text('Aucune facture'), findsOneWidget);
    });

    testWidgets('renders invoice cards and stat counters', (tester) async {
      final fakeHistory = [
        {
          'id': '42',
          'reference': '260430-001',
          'amount': '15000',
          'status': 'paid',
          'type': 'quote_first_payment',
          'description': 'Acompte devis #42',
          'date': '2026-04-01T10:00:00Z',
        },
        {
          'id': '43',
          'reference': '260430-002',
          'amount': '8500',
          'status': 'pending',
          'type': 'order',
          'description': 'Commande #43',
          'date': '2026-04-15T10:00:00Z',
        },
      ];

      await tester.pumpWidget(
        _withInvoiceProviders(
          const InvoicesScreen(),
          payments: _FakePaymentRepository(history: fakeHistory),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Stat counter: 2 total
      expect(find.text('2'), findsAtLeastNWidgets(1));
      // Invoice numbers generated correctly
      expect(find.textContaining('DEV-'), findsAtLeastNWidgets(1));
      expect(find.textContaining('CMD-'), findsAtLeastNWidgets(1));
    });
  });
}
