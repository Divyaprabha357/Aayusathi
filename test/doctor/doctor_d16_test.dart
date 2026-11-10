import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/localization/doctor_strings.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_header.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    DoctorSessionService.instance.resetSession();
    DoctorPresenceService.instance.resetPresence();
  });

  group('Phase D16: Visit Workflow & No Auto-Creation Tests', () {
    test('1. Opening existing case does not auto-create active visit in workspace service', () async {
      final workspaceService = MockDoctorPatientWorkspaceService.instance;
      
      // Load workspace for patient PAT-MOCK-001 with existing Case CASE-PAT-001-01
      final data = await workspaceService.loadWorkspaceData(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
      );

      expect(data.isSuccess, isTrue);
      expect(data.patient, isNotNull);
      expect(data.patient!.patientId, equals('PAT-MOCK-001'));
      expect(data.cases, isNotEmpty);

      // Verify that all visits for CASE-PAT-001-01 remain completed and NO active visit was auto-created
      final case1Visits = data.visits.where((v) => v.caseId == 'CASE-PAT-001-01').toList();
      expect(case1Visits.length, equals(2));
      expect(case1Visits.every((v) => v.isCompleted), isTrue);
      expect(case1Visits.any((v) => v.isActive), isFalse);

      // Verify repository has not created an extra visit
      final activeVisit = await BackendProvider.instance.clinicalVisitRepository
          .getActiveVisitForCase(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(activeVisit, isNull);
    });

    test('2. Doctor presence remains AVAILABLE when viewing completed case', () async {
      await DoctorPresenceService.instance.setAvailable();
      expect(DoctorPresenceService.instance.isAvailable, isTrue);

      final data = await MockDoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
      );

      expect(data.isSuccess, isTrue);
      // Presence must still be AVAILABLE because no active consultation is started
      expect(DoctorPresenceService.instance.isAvailable, isTrue);
      expect(DoctorPresenceService.instance.isInConsultation, isFalse);
    });
  });

  group('Phase D16: Explicit + NEW VISIT & Case Continuation Workflow', () {
    test('3. Sequential visit numbering per case', () async {
      final repo = MockClinicalVisitRepository.instance;
      final nextNum = await repo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      // Case PAT-001-01 has 2 completed visits (1 and 2), next must be 3
      expect(nextNum, equals(3));
    });

    test('4. createNextVisit creates active visit and enforces duplicate prevention', () async {
      final repo = MockClinicalVisitRepository.instance;
      
      // Start Visit 3 explicitly
      final createdVisit = await repo.createNextVisit(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        chiefComplaint: 'Follow-up on blood pressure',
      );

      expect(createdVisit.visitNumber, equals(3));
      expect(createdVisit.isActive, isTrue);
      expect(createdVisit.status, equals(ClinicalVisitStatus.active));

      // Attempting to create another visit while Visit 3 is active must throw StateError
      expect(
        () => repo.createNextVisit(
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Rajesh Sharma',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Completing visit transitions presence back to AVAILABLE and parent case remains OPEN', () async {
      final visitRepo = MockClinicalVisitRepository.instance;
      final caseRepo = MockCaseRepository.instance;

      // Set available then transition to consultation
      await DoctorPresenceService.instance.setAvailable();
      await DoctorPresenceService.instance.setInConsultation();
      expect(DoctorPresenceService.instance.isInConsultation, isTrue);

      final created = await visitRepo.createNextVisit(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
      );

      // Complete Visit 3
      final completed = await visitRepo.completeVisit(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: created.visitId,
        doctorId: 'DOC-101',
      );

      expect(completed.isCompleted, isTrue);
      expect(completed.completedByDoctorId, equals('DOC-101'));

      await DoctorPresenceService.instance.setAvailable();
      expect(DoctorPresenceService.instance.isAvailable, isTrue);

      // Verify Case strictly remains OPEN
      final clinicalCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(clinicalCase, isNotNull);
      expect(clinicalCase!.isOpen, isTrue);
      expect(clinicalCase.isClosed, isFalse);
    });
  });

  group('Phase D16: Doctor-Specific Case Access Control Tests', () {
    test('6. MockCaseRepository getCasesForDoctor filters strictly by doctor involvement', () async {
      final caseRepo = MockCaseRepository.instance;

      // 1. Dr. Rajesh Sharma (DOC-101, Cardiology):
      // - CASE-PAT-001-01 (Visits 1 & 2 by DOC-101)
      // - CASE-102938-01 (Visits 1 & 2 by DOC-101)
      // MUST EXCLUDE CASE-PAT-001-02 (Orthopedics, DOC-103)
      // MUST EXCLUDE CASE-482910-01 (Dermatology, DOC-102)
      final doc101Cases = await caseRepo.getCasesForDoctor('DOC-101');
      expect(doc101Cases.length, equals(2));
      expect(doc101Cases.any((c) => c.caseId == 'CASE-PAT-001-01'), isTrue);
      expect(doc101Cases.any((c) => c.caseId == 'CASE-102938-01'), isTrue);
      expect(doc101Cases.any((c) => c.caseId == 'CASE-PAT-001-02'), isFalse);
      expect(doc101Cases.any((c) => c.caseId == 'CASE-482910-01'), isFalse);

      // 2. Dr. Sneha Joshi (DOC-103, Orthopedics):
      // - CASE-PAT-001-02 (Visit 1 & closed by DOC-103)
      final doc103Cases = await caseRepo.getCasesForDoctor('DOC-103');
      expect(doc103Cases.length, equals(1));
      expect(doc103Cases.first.caseId, equals('CASE-PAT-001-02'));
      expect(doc103Cases.first.domain, equals('Orthopedics'));

      // 3. Dr. Ananya Sen (DOC-102, Dermatology):
      // - CASE-482910-01 (Visit 1 by DOC-102)
      final doc102Cases = await caseRepo.getCasesForDoctor('DOC-102');
      expect(doc102Cases.length, equals(1));
      expect(doc102Cases.first.caseId, equals('CASE-482910-01'));
      expect(doc102Cases.first.domain, equals('Dermatology'));

      // 4. Another Cardiologist (DOC-104) who never consulted on these cases: 0 cases
      final otherCardiologistCases = await caseRepo.getCasesForDoctor('DOC-104');
      expect(otherCardiologistCases.isEmpty, isTrue);
    });

    test('7. isDoctorAuthorizedForCase verifies consultation authorization', () async {
      final caseRepo = MockCaseRepository.instance;

      // DOC-101 is authorized for Cardiology cases
      final isAuth1 = await caseRepo.isDoctorAuthorizedForCase(
        doctorId: 'DOC-101',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
      );
      expect(isAuth1, isTrue);

      // DOC-101 is NOT authorized for Orthopedics CASE-PAT-001-02
      final isAuthOrthopedics = await caseRepo.isDoctorAuthorizedForCase(
        doctorId: 'DOC-101',
        caseId: 'CASE-PAT-001-02',
        patientId: 'PAT-MOCK-001',
      );
      expect(isAuthOrthopedics, isFalse);

      // DOC-103 (Orthopedics) is NOT authorized for Cardiology CASE-102938-01
      final isAuth2 = await caseRepo.isDoctorAuthorizedForCase(
        doctorId: 'DOC-103',
        caseId: 'CASE-102938-01',
        patientId: 'AAYU-102938',
      );
      expect(isAuth2, isFalse);
    });
  });

  group('Phase D16: Doctor Case Screen Widget Tests', () {
    testWidgets('8. DoctorCaseScreen displays doctor-specific cases and hides other doctor cases', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      // Authenticate as Dr. Rajesh Sharma (DOC-101, Cardiology)
      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-101',
          doctorUniqueCode: 'DOC-101',
          name: 'Dr. Rajesh Sharma',
          qualification: 'MBBS, MD (Cardiology)',
          department: 'Cardiology',
          registeredPhone: '+919876543210',
          email: 'rajesh.sharma@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'mock-uid-101',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.doctorCase: (_) => const DoctorCaseScreen(),
            AppRoutes.doctorDashboard: (_) => const Scaffold(body: Text('Dashboard')),
            AppRoutes.doctorPatientWorkspace: (_) => const Scaffold(body: Text('Workspace')),
          },
          home: const DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify DOC-101 cases are displayed: 2 open cases, 0 closed cases, total 2
      expect(find.text('All Cases (2)'), findsOneWidget);
      expect(find.text('Open Cases (2)'), findsOneWidget);
      expect(find.text('Closed Cases (0)'), findsOneWidget);

      expect(find.text('Hypertension & Exertional Dyspnea'), findsOneWidget);
      expect(find.text('Essential Hypertension Review'), findsOneWidget);

      // Verify Orthopedics "Right Knee Sprain" is strictly HIDDEN
      expect(find.text('Right Knee Sprain'), findsNothing);

      // Verify Dermatology "Contact Dermatitis" is strictly HIDDEN
      expect(find.text('Contact Dermatitis'), findsNothing);
    });

    testWidgets('9. DoctorCaseScreen search cannot reveal unauthorized cases', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-101',
          doctorUniqueCode: 'DOC-101',
          name: 'Dr. Rajesh Sharma',
          qualification: 'MBBS, MD (Cardiology)',
          department: 'Cardiology',
          registeredPhone: '+919876543210',
          email: 'rajesh.sharma@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'mock-uid-101',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Search for Orthopedics case title -> returns 0 results
      await tester.enterText(searchField, 'Right Knee Sprain');
      await tester.pumpAndSettle();
      expect(find.text('Orthopedics'), findsNothing);
      expect(find.text('Hypertension & Exertional Dyspnea'), findsNothing);
      expect(find.text('Essential Hypertension Review'), findsNothing);

      // Search for valid Cardiology query -> returns matching case
      await tester.enterText(searchField, 'Dyspnea');
      await tester.pumpAndSettle();
      expect(find.text('Hypertension & Exertional Dyspnea'), findsOneWidget);
      expect(find.text('Essential Hypertension Review'), findsNothing);
    });
  });

  group('Phase D16: Workspace Direct Access & Unauthorized Guard Tests', () {
    testWidgets('10. Direct unauthorized case access blocks access and shows unauthorized view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      // Authenticate as Dr. Rajesh Sharma (DOC-101, Cardiology)
      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-101',
          doctorUniqueCode: 'DOC-101',
          name: 'Dr. Rajesh Sharma',
          qualification: 'MBBS, MD (Cardiology)',
          department: 'Cardiology',
          registeredPhone: '+919876543210',
          email: 'rajesh.sharma@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'mock-uid-101',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      // Attempt to access Orthopedics CASE-PAT-001-02 directly
      await tester.pumpWidget(
        MaterialApp(
          home: const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'caseId': 'CASE-PAT-001-02',
              'patientId': 'PAT-MOCK-001',
              'domain': 'Orthopedics',
            },
          ),
          routes: {
            AppRoutes.doctorDashboard: (_) => const Scaffold(body: Text('Dashboard')),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Unauthorized guard should trigger
      final strings = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(find.text(strings.unauthorizedAccess), findsAtLeastNWidgets(1));
    });
  });

  group('Phase D16: Stationary Tab Bar & Zero Workspace Shift Tests', () {
    testWidgets('11. Switching tabs 20 times maintains 100% pixel-stationary tab buttons without horizontal movement', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 2000));

      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-101',
          doctorUniqueCode: 'DOC-101',
          name: 'Dr. Rajesh Sharma',
          qualification: 'MBBS, MD (Cardiology)',
          department: 'Cardiology',
          registeredPhone: '+919876543210',
          email: 'rajesh.sharma@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'mock-uid-101',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.doctorDashboard: (_) => const Scaffold(body: Text('Dashboard')),
          },
          home: const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final visitHistoryTabFinder = find.text('VISIT HISTORY');
      final caseTimelineTabFinder = find.text('CASE TIMELINE');

      expect(visitHistoryTabFinder, findsOneWidget);
      expect(caseTimelineTabFinder, findsOneWidget);

      await tester.ensureVisible(visitHistoryTabFinder);
      await tester.pumpAndSettle();

      final initialVisitTabOffset = tester.getTopLeft(visitHistoryTabFinder);
      final initialTimelineTabOffset = tester.getTopLeft(caseTimelineTabFinder);

      // Perform 20 sequential tab switches
      for (int i = 0; i < 20; i++) {
        if (i % 2 == 0) {
          // Switch to Case Timeline
          await tester.tap(caseTimelineTabFinder, warnIfMissed: false);
          await tester.pumpAndSettle();
        } else {
          // Switch to Visit History
          await tester.tap(visitHistoryTabFinder, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        // Verify Tab Button screen offsets remain pixel-stationary (0 pixel shift)
        final currentVisitTabOffset = tester.getTopLeft(visitHistoryTabFinder);
        final currentTimelineTabOffset = tester.getTopLeft(caseTimelineTabFinder);

        expect(currentVisitTabOffset.dx, equals(initialVisitTabOffset.dx));
        expect(currentVisitTabOffset.dy, equals(initialVisitTabOffset.dy));
        expect(currentTimelineTabOffset.dx, equals(initialTimelineTabOffset.dx));
        expect(currentTimelineTabOffset.dy, equals(initialTimelineTabOffset.dy));
      }
    });

    testWidgets('12. DoctorHeader renders with isolated live clock', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: DoctorHeader(
              title: 'Test Header',
              subtitle: 'Performance Optimization',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Test Header'), findsOneWidget);
      expect(find.text('DOCTOR PORTAL'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });
  });

  group('Phase D16: Multi-Language Localization Tests', () {
    test('13. All D16 strings exist across English, Hindi, and Marathi', () {
      const en = DoctorStrings();
      const hi = DoctorStringsHindi();
      const mr = DoctorStringsMarathi();

      expect(en.unauthorizedCaseAccess, isNotEmpty);
      expect(hi.unauthorizedCaseAccess, isNotEmpty);
      expect(mr.unauthorizedCaseAccess, isNotEmpty);

      expect(en.startNewVisitButton, equals('+ NEW VISIT'));
      expect(hi.startNewVisitButton, equals('+ नई भेंट'));
      expect(mr.startNewVisitButton, equals('+ नवीन भेट'));

      expect(en.confirmStartNewVisitButton, isNotEmpty);
      expect(hi.confirmStartNewVisitButton, isNotEmpty);
      expect(mr.confirmStartNewVisitButton, isNotEmpty);
    });
  });
}
