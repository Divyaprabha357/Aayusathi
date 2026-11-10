import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_higher_authority_assignment_controller.dart';
import 'package:aayusathi/admin/screens/admin_escalated_patient_workspace_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/widgets/admin_higher_authority_assignment_dialog.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/higher_authority_assignment.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;
  late MockDoctorRepository doctorRepo;
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
    doctorRepo = MockDoctorRepository.instance;
    doctorRepo.resetToDefaults();
    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-101',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Rajesh Sharma',
        qualification: 'MBBS (Resident / MO)',
        department: 'general_medicine',
        registeredPhone: '9876543210',
        email: 'doc-101@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        clinicalAuthorityLevel: 1,
        authUid: 'mock-uid-DOC-101',
        createdAt: DateTime(2026, 1, 11),
        updatedAt: DateTime(2026, 1, 11),
      ),
    );
    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-102',
        doctorUniqueCode: 'DOC-102',
        name: 'Dr. Amit Mehta',
        qualification: 'MBBS, MD (Senior Consultant)',
        department: 'cardiology',
        registeredPhone: '9876543211',
        email: 'doc-102@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        clinicalAuthorityLevel: 2,
        authUid: 'mock-uid-DOC-102',
        createdAt: DateTime(2026, 1, 12),
        updatedAt: DateTime(2026, 1, 12),
      ),
    );
    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-103',
        doctorUniqueCode: 'DOC-103',
        name: 'Dr. Sneha Joshi',
        qualification: 'MBBS, MD, DM (Chief Specialist)',
        department: 'general_medicine',
        registeredPhone: '9876543212',
        email: 'doc-103@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        clinicalAuthorityLevel: 3,
        authUid: 'mock-uid-DOC-103',
        createdAt: DateTime(2026, 1, 13),
        updatedAt: DateTime(2026, 1, 13),
      ),
    );
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

    // Escalate demo case by Level 1 Doctor DOC-101 (General Medicine)
    await caseRepo.escalateCase(
      patientId: 'PAT-MOCK-001',
      caseId: 'CASE-PAT-001-01',
      visitId: 'VIS-PAT-001-01-1',
      reason: CaseEscalationReason.higherAuthorityReview,
      doctorId: 'DOC-101',
      doctorName: 'Dr. Rajesh Sharma',
      note: 'Complex multi-system symptoms requiring specialist review.',
    );

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );
  });

  tearDown(() async {
    await AdminAuthService.instance.logout();
    DoctorSessionService.instance.resetSession();
  });

  group('Phase A10: Data Model & Authority Hierarchy Tests', () {
    test('DoctorProfile authority levels and helper getters operate correctly', () {
      final l1 = DoctorProfile(
        doctorId: 'D1',
        doctorUniqueCode: 'DOC-01',
        name: 'Dr. One',
        qualification: 'MBBS',
        department: 'General Medicine',
        registeredPhone: '9999999991',
        email: 'dr.one@aayusathi.in',
        clinicalAuthorityLevel: 1,
        authUid: 'mock-uid-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final l2 = DoctorProfile(
        doctorId: 'D2',
        doctorUniqueCode: 'DOC-02',
        name: 'Dr. Two',
        qualification: 'MD',
        department: 'Cardiology',
        registeredPhone: '9999999992',
        email: 'dr.two@aayusathi.in',
        clinicalAuthorityLevel: 2,
        authUid: 'mock-uid-2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final l3 = DoctorProfile(
        doctorId: 'D3',
        doctorUniqueCode: 'DOC-03',
        name: 'Dr. Three',
        qualification: 'DM',
        department: 'General Medicine',
        registeredPhone: '9999999993',
        email: 'dr.three@aayusathi.in',
        clinicalAuthorityLevel: 3,
        authUid: 'mock-uid-3',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(l1.isStandardDoctor, isTrue);
      expect(l1.isSeniorDoctor, isFalse);
      expect(l1.isSpecialistHigherAuthority, isFalse);
      expect(l1.authorityLevelDisplay, contains('Level 1'));

      expect(l2.isStandardDoctor, isFalse);
      expect(l2.isSeniorDoctor, isTrue);
      expect(l2.isSpecialistHigherAuthority, isFalse);
      expect(l2.authorityLevelDisplay, contains('Level 2'));

      expect(l3.isStandardDoctor, isFalse);
      expect(l3.isSeniorDoctor, isFalse);
      expect(l3.isSpecialistHigherAuthority, isTrue);
      expect(l3.authorityLevelDisplay, contains('Level 3'));

      // Serialization & deserialization
      final map = l2.toMap();
      expect(map['clinicalAuthorityLevel'], 2);
      final restored = DoctorProfile.fromMap(map);
      expect(restored.clinicalAuthorityLevel, 2);
    });

    test('HigherAuthorityAssignment model serialization works properly', () {
      final assignment = HigherAuthorityAssignment(
        assignmentId: 'ASSIGN-001',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'General Medicine',
        sourceAuthorityLevel: 1,
        targetDoctorId: 'DOC-103',
        targetDoctorName: 'Dr. Priya Desai',
        targetDepartment: 'General Medicine',
        targetAuthorityLevel: 3,
        assignedByAdminId: 'admin01',
        assignedAt: DateTime.now(),
        reason: 'Complex diagnosis verification',
        status: HigherAuthorityAssignmentStatus.assigned,
      );

      final map = assignment.toMap();
      expect(map['assignmentId'], 'ASSIGN-001');
      expect(map['targetAuthorityLevel'], 3);
      expect(map['status'], 'assigned');

      final restored = HigherAuthorityAssignment.fromMap(map);
      expect(restored.targetDoctorId, 'DOC-103');
      expect(restored.targetAuthorityLevel, 3);
      expect(restored.status, HigherAuthorityAssignmentStatus.assigned);
    });

    test('ClinicalCase handles Higher Authority Assignment fields & getters', () {
      final c = ClinicalCase(
        caseId: 'CASE-01',
        patientId: 'PAT-01',
        domain: 'General Medicine',
        title: 'Fever & Cough',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        higherAuthorityDoctorId: 'DOC-103',
        higherAuthorityDoctorName: 'Dr. Priya Desai',
        higherAuthorityDepartment: 'General Medicine',
        higherAuthorityAssignedAt: DateTime.now(),
        higherAuthorityAssignedBy: 'admin01',
        higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.assigned,
        higherAuthorityAssignmentReason: 'Senior opinion requested',
      );

      expect(c.isAssignedToHigherAuthority, isTrue);
      expect(c.isHigherAuthorityAccepted, isFalse);

      final map = c.toMap();
      expect(map['higherAuthorityDoctorId'], 'DOC-103');
      expect(map['higherAuthorityAssignmentStatus'], 'assigned');

      final restored = ClinicalCase.fromMap(map);
      expect(restored.higherAuthorityDoctorId, 'DOC-103');
      expect(restored.higherAuthorityDoctorName, 'Dr. Priya Desai');
      expect(restored.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.assigned);

      final accepted = restored.copyWith(
        higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.accepted,
        higherAuthorityAcceptedAt: DateTime.now(),
      );
      expect(accepted.isHigherAuthorityAccepted, isTrue);
    });
  });

  group('Phase A10: Controller & Eligibility Filtering Tests', () {
    test('AdminHigherAuthorityAssignmentController enforces 11 eligibility rules', () async {
      final c = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(c, isNotNull);

      final controller = AdminHigherAuthorityAssignmentController(
        clinicalCase: c!,
        adminId: 'admin01',
      );
      await controller.initialize();

      // Escalated by DOC-101 (Level 1, General Medicine)
      // Candidates in MockDoctorRepository:
      // DOC-101: Level 1 (Source doctor -> excluded)
      // DOC-102: Level 2 (Cardiology -> cross department)
      // DOC-103: Level 3 (General Medicine, Available -> ELIGIBLE!)
      // DOC-104: Level 1 (General Medicine, Offline -> ineligible)
      // DOC-105: Level 2 (General Medicine, InConsultation -> ineligible)

      expect(controller.eligibleDoctors.length, 1);
      expect(controller.eligibleDoctors.first.doctorId, 'DOC-103');
      expect(controller.eligibleDoctors.first.clinicalAuthorityLevel, 3);

      // Now enable cross department transfer
      controller.toggleCrossDepartment(true);
      // DOC-102 (Cardiology, Level 2 > 1, Available) should now be eligible
      expect(controller.eligibleDoctors.any((d) => d.doctorId == 'DOC-102'), isTrue);

      // Select cross-department doctor DOC-102 without reason
      controller.selectDoctor(controller.eligibleDoctors.firstWhere((d) => d.doctorId == 'DOC-102'));
      final failedAssignment = await controller.assignHigherAuthority();
      expect(failedAssignment, isNull); // Missing cross-dept justification
      expect(controller.errorMessage, isNotNull);

      // Add justification
      controller.setCrossDepartmentReason('Requiring advanced cardiology consultation for underlying arrhythmia.');
      final successfulCrossAssignment = await controller.assignHigherAuthority();
      expect(successfulCrossAssignment, isNotNull);
      expect(successfulCrossAssignment!.higherAuthorityDoctorId, 'DOC-102');
      expect(successfulCrossAssignment.higherAuthorityDepartment?.toLowerCase(), 'cardiology');

      controller.dispose();
    });

    test('Controller successfully assigns higher authority doctor atomically', () async {
      final c = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      final controller = AdminHigherAuthorityAssignmentController(
        clinicalCase: c!,
        adminId: 'admin01',
      );
      await controller.initialize();

      final specialist = controller.eligibleDoctors.firstWhere((d) => d.doctorId == 'DOC-103');
      controller.selectDoctor(specialist);
      controller.setCrossDepartmentReason('Senior clinical evaluation required for persistent symptoms.');

      final updatedCase = await controller.assignHigherAuthority();
      expect(updatedCase, isNotNull);
      expect(controller.isSuccess, isTrue);

      // Verify case state in repository
      final repoCase = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(repoCase!.isAssignedToHigherAuthority, isTrue);
      expect(repoCase.higherAuthorityDoctorId, 'DOC-103');
      expect(repoCase.higherAuthorityDoctorName, specialist.name);
      expect(repoCase.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.assigned);
      expect(repoCase.higherAuthorityAssignedBy, 'admin01');

      // Check case continuity: Case ID, patient ID, and status are preserved!
      expect(repoCase.caseId, 'CASE-PAT-001-01');
      expect(repoCase.patientId, 'PAT-MOCK-001');
      expect(repoCase.isOpen, isTrue);

      controller.dispose();
    });
  });

  group('Phase A10: Doctor Acceptance & Case Continuity Tests', () {
    test('Assigned Higher Authority Doctor sees case in case desk and accepts it', () async {
      // 1. Assign to DOC-103
      await caseRepo.assignHigherAuthorityDoctor(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        targetDoctorId: 'DOC-103',
        targetDoctorName: 'Dr. Sneha Joshi',
        targetDepartment: 'General Medicine',
        assignedByAdminId: 'admin01',
        crossDepartmentReason: 'Specialist case escalation review',
      );

      // 2. Query cases for DOC-103
      final doc103Cases = await caseRepo.getCasesForDoctor('DOC-103');
      expect(doc103Cases.any((c) => c.caseId == 'CASE-PAT-001-01'), isTrue);

      // 3. Target doctor accepts the assignment
      final acceptedCase = await caseRepo.acceptHigherAuthorityAssignment(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-103',
      );

      expect(acceptedCase.isHigherAuthorityAccepted, isTrue);
      expect(acceptedCase.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.accepted);
      expect(acceptedCase.higherAuthorityAcceptedAt, isNotNull);

      // 4. Case continuity verified: visits remain intact
      final visits = await visitRepo.getVisitsForCase(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(visits.isNotEmpty, isTrue);
      expect(visits.first.patientId, 'PAT-MOCK-001');
    });
  });

  group('Phase A10: UI & Dialog Widget Tests', () {
    testWidgets('AdminHigherAuthorityAssignmentDialog renders eligible doctors and performs assignment', (tester) async {
      final c = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(c, isNotNull);

      await tester.binding.setSurfaceSize(const Size(1600, 1000));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.adminLogin: (_) => const Scaffold(body: Text('Login')),
          },
          home: Scaffold(
            body: AdminHigherAuthorityAssignmentDialog(
              clinicalCase: c!,
              sourceDoctorName: 'Dr. Rajesh Sharma',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dialog header & metadata
      expect(find.text('ASSIGN HIGHER-AUTHORITY DOCTOR'), findsOneWidget);
      expect(find.text('CASE-PAT-001-01'), findsOneWidget);
      expect(find.text('Dr. Rajesh Sharma'), findsOneWidget);

      // Verify eligible doctor card (Dr. Sneha Joshi - Level 3)
      expect(find.text('Dr. Sneha Joshi'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);

      // Tap on doctor card to select
      await tester.tap(find.byKey(const ValueKey('eligible_doctor_card_DOC-103')));
      await tester.pumpAndSettle();

      // Tap Assign button
      await tester.tap(find.byKey(const ValueKey('commit_higher_authority_assignment_button')));
      await tester.pumpAndSettle();

      // Confirmation modal should appear
      expect(find.text('Confirm Higher-Authority Assignment'), findsOneWidget);

      // Confirm assignment
      await tester.tap(find.byKey(const ValueKey('modal_confirm_assignment_button')));
      await tester.pumpAndSettle();

      // Case should now be assigned in repository
      final updated = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(updated!.isAssignedToHigherAuthority, isTrue);
      expect(updated.higherAuthorityDoctorId, 'DOC-103');
    });

    testWidgets('AdminEscalatedPatientWorkspaceScreen shows assign button and triggers dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.adminLogin: (_) => const Scaffold(body: Text('Login')),
            AppRoutes.adminCaseEscalations: (_) => const Scaffold(body: Text('Case Escalations')),
          },
          home: const AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Top Action Bar assign button
      expect(find.byKey(const ValueKey('top_assign_higher_authority_button')), findsOneWidget);

      // Check Governance Card assign button
      expect(find.byKey(const ValueKey('governance_assign_higher_authority_button')), findsOneWidget);

      // Tap Assign Higher Authority button
      await tester.tap(find.byKey(const ValueKey('top_assign_higher_authority_button')));
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('ASSIGN HIGHER-AUTHORITY DOCTOR'), findsOneWidget);
    });

    testWidgets('DoctorCaseScreen displays assigned higher authority case and accept button', (tester) async {
      // 1. Assign case to DOC-103
      await caseRepo.assignHigherAuthorityDoctor(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        targetDoctorId: 'DOC-103',
        targetDoctorName: 'Dr. Sneha Joshi',
        targetDepartment: 'General Medicine',
        assignedByAdminId: 'admin01',
        crossDepartmentReason: 'Specialist case escalation review',
      );

      // 2. Set active doctor to DOC-103
      final doc103Profile = DoctorProfile(
        doctorId: 'DOC-103',
        doctorUniqueCode: 'DOC-103',
        name: 'Dr. Sneha Joshi',
        qualification: 'DM (Clinical Medicine)',
        department: 'General Medicine',
        registeredPhone: '9876543212',
        email: 'dr.sneha@aayusathi.in',
        clinicalAuthorityLevel: 3,
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        authUid: 'mock-uid-103',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await DoctorSessionService.instance.enterDevelopmentWorkspace(profile: doc103Profile);

      await tester.binding.setSurfaceSize(const Size(1600, 1000));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.doctorDashboard: (_) => const Scaffold(body: Text('Doctor Dashboard')),
            AppRoutes.doctorStandby: (_) => const Scaffold(body: Text('Doctor Standby')),
            AppRoutes.doctorPatientWorkspace: (_) => const Scaffold(body: Text('Patient Workspace')),
          },
          home: const DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the assigned case
      expect(find.textContaining('CASE-PAT-001-01'), findsOneWidget);
      expect(find.text('HIGHER AUTHORITY: PENDING ACCEPTANCE'), findsOneWidget);

      // Should display ACCEPT CASE button
      final acceptBtn = find.byKey(const ValueKey('accept_case_CASE-PAT-001-01'));
      expect(acceptBtn, findsOneWidget);

      // Tap ACCEPT CASE
      await tester.tap(acceptBtn);
      await tester.pumpAndSettle();

      // Should now show HIGHER AUTHORITY: ACCEPTED
      expect(find.text('HIGHER AUTHORITY: ACCEPTED'), findsOneWidget);

      final accepted = await caseRepo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(accepted!.isHigherAuthorityAccepted, isTrue);
    });
  });
}
