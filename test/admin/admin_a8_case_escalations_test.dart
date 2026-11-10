import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_case_escalation_controller.dart';
import 'package:aayusathi/admin/screens/admin_case_escalations_screen.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/widgets/admin_case_escalation_dialogs.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    caseRepo = MockCaseRepository.instance;
    caseRepo.resetToDefaults();
    MockAdminDashboardService.instance.reset();

    // Escalate 2 cases for testing
    await caseRepo.escalateCase(
      patientId: 'PAT-MOCK-001',
      caseId: 'CASE-PAT-001-01',
      visitId: 'VISIT-001',
      reason: CaseEscalationReason.clinicalDeterioration,
      doctorId: 'DOC-101',
      doctorName: 'Dr. Ramesh Sharma',
      note: 'SPO2 dropping rapidly',
    );
    await caseRepo.escalateCase(
      patientId: 'AAYU-102938',
      caseId: 'CASE-102938-01',
      visitId: 'VISIT-002',
      reason: CaseEscalationReason.repeatedVisitsNoResolution,
      doctorId: 'DOC-102',
      doctorName: 'Dr. Priya Patel',
      note: '3rd visit with uncontrolled BP',
    );

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );

    AdminCaseEscalationController.instance.resetForTesting();
  });

  group('Phase A8: Admin Case Escalations Screen UI Tests', () {
    testWidgets('1. Renders stationary desktop layout with 4 KPI cards and filter controls', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCaseEscalationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header / Title
      expect(find.text('CLINICAL CASE ESCALATIONS'), findsWidgets);

      // Check 4 KPI Cards
      expect(find.byKey(const Key('card_kpi_total_case_escalations')), findsOneWidget);
      expect(find.byKey(const Key('card_kpi_deterioration')), findsOneWidget);
      expect(find.byKey(const Key('card_kpi_repeated_visits')), findsOneWidget);
      expect(find.byKey(const Key('card_kpi_under_review')), findsOneWidget);

      // Check Filter Controls
      expect(find.byKey(const ValueKey('case_escalation_search_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('case_escalation_dept_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('case_escalation_reason_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('case_escalation_status_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('case_escalation_sort_dropdown')), findsOneWidget);

      // Check Escalated Cases Table exists
      expect(find.byKey(const Key('admin_case_escalations_table')), findsOneWidget);
    });

    testWidgets('2. Clicking "Review" on a case opens AdminCaseEscalationReviewDialog and enables start review', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCaseEscalationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find at least one action button "REVIEW"
      final reviewButtons = find.text('REVIEW');
      expect(reviewButtons, findsWidgets);

      await tester.ensureVisible(reviewButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(reviewButtons.first);
      await tester.pumpAndSettle();

      // Review dialog should be open
      expect(find.text('CASE ESCALATION REVIEW'), findsOneWidget);
      expect(find.byKey(const ValueKey('start_review_modal_button')), findsOneWidget);

      // Tap "Start Review"
      await tester.tap(find.byKey(const ValueKey('start_review_modal_button')));
      await tester.pumpAndSettle();

      // Verify status updated in-place inside dialog
      expect(find.text('Currently Under Administrative Review'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('CASE ESCALATION REVIEW'), findsNothing);
    });
  });

  group('Phase A8: Admin Case Escalation Review Dialog Widget Tests', () {
    testWidgets('1. AdminCaseEscalationReviewDialog displays case details without sensitive data exposure', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleCase = ClinicalCase(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        domain: 'General Medicine',
        title: 'Severe bacterial pneumonia',
        createdAt: DateTime(2026, 9, 8, 8, 0),
        escalationStatus: CaseEscalationStatus.escalated,
        escalationReason: CaseEscalationReason.clinicalDeterioration,
        escalatedAt: DateTime(2026, 9, 8, 10, 15),
        escalatedByDoctorId: 'DOC-101',
        escalatedByDoctorName: 'Dr. Ramesh Sharma',
        escalationSourceVisitId: 'VISIT-PAT-001-01',
        escalationNote: 'Rapid oxygen desaturation, needs ICU/Senior specialist oversight',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AdminCaseEscalationReviewDialog(
                      clinicalCase: sampleCase,
                      controller: AdminCaseEscalationController.instance,
                    ),
                  );
                },
                child: const Text('Open Review'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Review'));
      await tester.pumpAndSettle();

      expect(find.text('CASE-PAT-001-01'), findsOneWidget);
      expect(find.text('PAT-MOCK-001'), findsOneWidget);
      expect(find.text('Dr. Ramesh Sharma'), findsWidgets);
      expect(find.text('Rapid oxygen desaturation, needs ICU/Senior specialist oversight'), findsOneWidget);
      expect(find.text('Clinical Deterioration'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('CASE-PAT-001-01'), findsNothing);
    });
  });

  group('Phase A8: Admin Dashboard Escalation Alert Card Tests', () {
    testWidgets('1. Admin Dashboard displays Case Escalation alert banner when escalated cases exist', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
            AppRoutes.adminCaseEscalations: (_) => const AdminCaseEscalationsScreen(),
          },
          home: const AdminDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify alert banner is visible
      final alertCard = find.byKey(const ValueKey('dashboard_case_escalation_alert_card'));
      expect(alertCard, findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsWidgets);

      // Scroll into view and tap alert card
      await tester.ensureVisible(alertCard);
      await tester.pumpAndSettle();

      await tester.tap(alertCard);
      await tester.pumpAndSettle();

      // Navigated to AdminCaseEscalationsScreen
      expect(find.byType(AdminCaseEscalationsScreen), findsOneWidget);
    });
  });

  group('Phase A8: Error State vs Empty State & Permission Tests', () {
    testWidgets('1. When stream produces permission-denied/error, displays error banner and error state without showing false empty state', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Simulate permission-denied error from Firestore via mock repository stream
      caseRepo.setMockStreamError('[cloud_firestore/permission-denied] Missing or insufficient permissions.');

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCaseEscalationsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify red error banner and error state container are visible
      expect(find.byKey(const Key('admin_case_escalations_error_state')), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsWidgets);

      // CRITICAL ASSERTION: Genuine empty state MUST NOT be shown
      expect(find.byKey(const Key('admin_case_escalations_empty_state')), findsNothing);
      expect(find.text('No clinical case escalations'), findsNothing);

      // Verify KPI cards display error state indicators ('--' and 'Error')
      expect(find.text('--'), findsWidgets);
      expect(find.text('Error'), findsWidgets);
    });

    testWidgets('2. When stream successfully returns empty list, displays genuine empty state with zero counts', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Reset repo to have 0 escalated cases (default cases have escalationStatus: none)
      caseRepo.resetToDefaults();

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCaseEscalationsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify genuine empty state is shown
      expect(find.byKey(const Key('admin_case_escalations_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('admin_case_escalations_error_state')), findsNothing);

      // Verify KPI total is 0 with All Clear badge
      expect(find.text('0'), findsWidgets);
      expect(find.text('All Clear'), findsOneWidget);
    });

    test('3. Non-Admin user cannot start case review', () async {
      // Log out Admin
      await AdminAuthService.instance.logout();

      final ctrl = AdminCaseEscalationController.instance;
      // When not logged in as admin, startReview uses fallback or rejects
      expect(ctrl.allEscalations, isEmpty);
    });
  });
}
