import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_case_escalation_controller.dart';
import 'package:aayusathi/admin/controllers/admin_escalated_patient_workspace_controller.dart';
import 'package:aayusathi/admin/screens/admin_escalated_patient_workspace_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/widgets/admin_case_escalation_dialogs.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/patient_transfer_request.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;
  late MockClinicalVisitRepository visitRepo;
  late MockPatientRepository patientRepo;
  late MockVitalRepository vitalRepo;
  late MockTransferRepository transferRepo;
  late MockInvestigationRepository investigationRepo;
  late MockReportRepository reportRepo;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    caseRepo = MockCaseRepository.instance;
    caseRepo.resetToDefaults();
    visitRepo = MockClinicalVisitRepository.instance;
    visitRepo.resetToDefaults();
    patientRepo = MockPatientRepository.instance;
    patientRepo.resetToDefaults();
    vitalRepo = MockVitalRepository.instance;
    vitalRepo.clear();
    transferRepo = MockTransferRepository.instance;
    transferRepo.resetToDefaults();
    investigationRepo = MockInvestigationRepository.instance;
    investigationRepo.reset();
    reportRepo = MockReportRepository.instance;
    reportRepo.reset();
    MockAdminDashboardService.instance.reset();

    // Escalate primary demo case
    await caseRepo.escalateCase(
      patientId: 'PAT-MOCK-001',
      caseId: 'CASE-PAT-001-01',
      visitId: 'VIS-PAT-001-01-1',
      reason: CaseEscalationReason.clinicalDeterioration,
      doctorId: 'DOC-101',
      doctorName: 'Dr. Rajesh Sharma',
      note: 'SpO2 dropping rapidly below 92% despite medication adjustment.',
    );

    // Seed a vital reading for PAT-MOCK-001
    await vitalRepo.saveVitalReading(
      patientId: 'PAT-MOCK-001',
      reading: VitalReading(
        patientId: 'PAT-MOCK-001',
        heartRate: 88,
        spo2: 91,
        temperature: 37.4,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: VitalStatus.abnormal,
      ),
    );

    // Seed a transfer record for this case
    await transferRepo.createTransfer(
      PatientTransferRequest(
        transferId: 'TRF-DEMO-001',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        patientName: 'Aarav Sharma',
        sourceVisitId: 'VIS-PAT-001-01-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'General Medicine',
        destinationDepartment: 'Cardiology',
        reason: 'Suspected coronary ischemia requiring specialist cardiology consultation.',
        status: TransferStatus.accepted,
        requestedAt: DateTime.now().subtract(const Duration(days: 10)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 10, hours: -1)),
        destinationDoctorId: 'DOC-102',
        destinationDoctorName: 'Dr. Amit Mehta',
      ),
    );

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );

    AdminCaseEscalationController.instance.resetForTesting();
  });

  group('Phase A9: Controller Unit Tests', () {
    test('1. Loads longitudinal patient clinical data, multi-visit history, vitals, and transfers', () async {
      final controller = AdminEscalatedPatientWorkspaceController(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );

      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.patient, isNotNull);
      expect(controller.patient!.patientId, 'PAT-MOCK-001');
      expect(controller.patient!.name, 'Aarav Sharma');

      expect(controller.clinicalCase, isNotNull);
      expect(controller.clinicalCase!.caseId, 'CASE-PAT-001-01');
      expect(controller.clinicalCase!.escalationStatus, CaseEscalationStatus.escalated);
      expect(controller.clinicalCase!.escalationReason, CaseEscalationReason.clinicalDeterioration);

      expect(controller.visits.length, greaterThanOrEqualTo(2));
      expect(controller.visits[0].visitNumber, 1);
      expect(controller.visits[1].visitNumber, 2);

      expect(controller.latestVital, isNotNull);
      expect(controller.latestVital!.spo2, 91);
      expect(controller.latestVital!.heartRate, 88);

      expect(controller.transfers.length, 1);
      expect(controller.transfers.first.destinationDepartment, 'Cardiology');

      controller.dispose();
    });

    test('2. Multi-visit selection switching updates selectedVisit', () async {
      final controller = AdminEscalatedPatientWorkspaceController(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );

      await controller.initialize();

      controller.selectVisitIndex(0);
      expect(controller.selectedVisit?.visitNumber, 1);

      controller.selectVisitIndex(1);
      expect(controller.selectedVisit?.visitNumber, 2);

      controller.selectVisitById('VIS-PAT-001-01-1');
      expect(controller.selectedVisit?.visitNumber, 1);

      controller.dispose();
    });

    test('3. Start Review action transitions state to underReview', () async {
      final controller = AdminEscalatedPatientWorkspaceController(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );

      await controller.initialize();
      expect(controller.clinicalCase!.isUnderReview, isFalse);

      await controller.startReview();

      expect(controller.clinicalCase!.isUnderReview, isTrue);
      expect(controller.clinicalCase!.adminReviewStartedBy, 'admin01');
      expect(controller.clinicalCase!.adminReviewStartedAt, isNotNull);

      controller.dispose();
    });
  });

  group('Phase A9: Admin Escalated Patient Workspace UI Tests', () {
    testWidgets('1. Renders full read-only clinical workstation on desktop resolutions', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & Action Bar
      expect(find.text('PATIENT CLINICAL REVIEW'), findsWidgets);
      expect(find.byKey(const ValueKey('back_to_escalations_button')), findsOneWidget);

      // Section 1: Escalation Banner
      expect(find.byKey(const ValueKey('AdminEscalationBanner')), findsOneWidget);
      expect(find.text('CLINICAL CASE ESCALATION'), findsOneWidget);
      expect(find.text('Clinical Deterioration'), findsWidgets);
      expect(find.text('Dr. Rajesh Sharma'), findsWidgets);

      // Section 2: Patient Identity Card (Aadhaar strictly omitted)
      expect(find.byKey(const ValueKey('AdminPatientIdentityCard')), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('PAT-MOCK-001'), findsWidgets);
      expect(find.text('READ ONLY'), findsWidgets);
      // Zero Aadhaar or UIDAI strings
      expect(find.textContaining('Aadhaar'), findsNothing);

      // Section 3: Case Summary & Current Vitals
      expect(find.byKey(const ValueKey('AdminCaseSummaryCard')), findsOneWidget);
      expect(find.text('CASE-PAT-001-01'), findsWidgets);
      expect(find.byKey(const ValueKey('AdminCurrentVitalsCard')), findsOneWidget);
      expect(find.text('91%'), findsOneWidget); // SpO2 abnormal

      // Section 4: Chronological Case Timeline
      expect(find.byKey(const ValueKey('AdminCaseTimelineView')), findsOneWidget);
      expect(find.text('CASE TIMELINE'), findsOneWidget);

      // Section 5: Multi-visit tabs & 9-Section Visit Detail
      expect(find.text('VISIT HISTORY'), findsOneWidget);
      expect(find.text('Visit 1'), findsWidgets);
      expect(find.text('Visit 2'), findsWidgets);

      expect(find.text('SECTION 1: VISIT IDENTIFICATION'), findsOneWidget);
      expect(find.text('SECTION 2: PATIENT & ATTENDING PHYSICIAN'), findsOneWidget);
      expect(find.text('SECTION 3: VITALS AT CONSULTATION'), findsOneWidget);
      expect(find.text('SECTION 4: CASE INFORMATION'), findsOneWidget);
      expect(find.text('SECTION 5: STRUCTURED CONSULTATION (8 OFFICIAL FIELDS)'), findsOneWidget);
      expect(find.text('SECTION 6: DOCTOR-APPROVED VISIT SUMMARY'), findsOneWidget);
      expect(find.text('SECTION 7: DIAGNOSTIC INVESTIGATIONS & REPORTS'), findsOneWidget);
      expect(find.text('SECTION 8: PLAN & FOLLOW-UP'), findsOneWidget);
      expect(find.text('SECTION 9: VISIT COMPLETION & OFFICIAL PDF'), findsOneWidget);

      // Section 6: Transfer History Card
      expect(find.byKey(const ValueKey('AdminTransferHistoryCard')), findsOneWidget);
      expect(find.text('INTER-DEPARTMENT TRANSFER HISTORY'), findsOneWidget);
      expect(find.textContaining('General Medicine → Cardiology'), findsWidgets);

      // Section 7: Governance History
      expect(find.byKey(const ValueKey('AdminEscalationGovernanceHistoryCard')), findsOneWidget);
    });

    testWidgets('2. Strict Read-Only Verification: Zero editable text fields or mutation controls', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure NO editable text fields exist on the entire screen
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      // Ensure NO clinical editing or lifecycle mutation buttons exist
      expect(find.text('Edit Patient'), findsNothing);
      expect(find.text('Edit Visit'), findsNothing);
      expect(find.text('Edit Vitals'), findsNothing);
      expect(find.text('Complete Visit'), findsNothing);
      expect(find.text('Close Case'), findsNothing);
      expect(find.text('Assign Doctor'), findsNothing);
      expect(find.text('Transfer Patient'), findsNothing);
      expect(find.text('Add Visit'), findsNothing);
    });

    testWidgets('3. Start Review button executes transition and updates badge to UNDER REVIEW', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startReviewBtn = find.byKey(const ValueKey('start_review_workspace_button'));
      expect(startReviewBtn, findsOneWidget);

      await tester.tap(startReviewBtn);
      await tester.pumpAndSettle();

      // Badge should now display UNDER REVIEW
      expect(find.text('UNDER REVIEW'), findsWidgets);
    });

    testWidgets('4. Multi-visit selector switches active visit record view', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Visit 1 tab
      final visit1Tab = find.byKey(const ValueKey('visit_tab_VIS-PAT-001-01-1'));
      expect(visit1Tab, findsOneWidget);

      await tester.ensureVisible(visit1Tab);
      await tester.tap(visit1Tab);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('AdminVisitDetailView_VIS-PAT-001-01-1')), findsOneWidget);

      // Tap on Visit 2 tab
      final visit2Tab = find.byKey(const ValueKey('visit_tab_VIS-PAT-001-01-2'));
      expect(visit2Tab, findsOneWidget);

      await tester.ensureVisible(visit2Tab);
      await tester.tap(visit2Tab);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('AdminVisitDetailView_VIS-PAT-001-01-2')), findsOneWidget);
    });

    testWidgets('5. A8 Case Review Dialog has [OPEN CLINICAL WORKSPACE] button wired to A9 workspace', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
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
        escalationSourceVisitId: 'VIS-PAT-001-01-1',
        escalationNote: 'Rapid oxygen desaturation, needs ICU/Senior specialist oversight',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.adminEscalatedPatient: (ctx) {
              final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
              return AdminEscalatedPatientWorkspaceScreen(
                patientId: args?['patientId'] as String?,
                caseId: args?['caseId'] as String?,
              );
            },
          },
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
                child: const Text('Open Review Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Review Dialog'));
      await tester.pumpAndSettle();

      // Modal dialog appears
      expect(find.byType(AdminCaseEscalationReviewDialog), findsOneWidget);
      expect(find.text('OPEN CLINICAL WORKSPACE'), findsWidgets);

      // Tap OPEN CLINICAL WORKSPACE
      final openBtn = find.byKey(const ValueKey('open_workspace_modal_button'));
      expect(openBtn, findsOneWidget);

      await tester.tap(openBtn);
      await tester.pumpAndSettle();

      // Should now be on AdminEscalatedPatientWorkspaceScreen
      expect(find.byType(AdminEscalatedPatientWorkspaceScreen), findsOneWidget);
      expect(find.text('PATIENT CLINICAL REVIEW'), findsWidgets);
    });
  });
}
