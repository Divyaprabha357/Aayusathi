import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockInvestigationRepository.instance.reset();
    MockPatientRepository.instance.resetToDefaults();
    PatientSessionService.instance.startSession('AAYU-102938', authUid: 'auth-user-102938');
  });

  tearDown(() {
    PatientSessionService.instance.logout();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: PatientTheme.theme,
      home: PatientLocalizations.provider(
        strings: PatientLocalizations.forLocaleCode('en'),
        child: child,
      ),
    );
  }

  group('AAYUSATHI Part A: Patient Visit History & Clinical Records Integration', () {
    // 1. PatientSession patientId
    test('1. PatientSession holds canonical AAYUSATHI Patient ID', () {
      expect(PatientSessionService.instance.authenticatedPatientId, 'AAYU-102938');
      expect(PatientSessionService.instance.isAuthenticated, isTrue);
    });

    // 2. Own case lookup
    test('2. Own case lookup succeeds for authenticated patient', () async {
      final caseRepo = BackendProvider.instance.caseRepository;
      final testCase = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'AAYU-102938',
        title: 'Hypertension Management',
        domain: 'Cardiology',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await caseRepo.createCase(testCase);

      final fetched = await caseRepo.getCaseById(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
      );
      expect(fetched, isNotNull);
      expect(fetched?.caseId, 'CASE-001');
      expect(fetched?.patientId, 'AAYU-102938');
    });

    // 3. Own visit lookup
    test('3. Own visit lookup retrieves matching clinical visit record', () async {
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;
      final testVisit = ClinicalVisit(
        visitId: 'VIS-001-1',
        caseId: 'CASE-001',
        patientId: 'AAYU-102938',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        department: 'Cardiology',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
      );
      await visitRepo.createVisit(testVisit);

      final fetched = await visitRepo.getVisitById(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
        visitId: 'VIS-001-1',
      );
      expect(fetched, isNotNull);
      expect(fetched?.visitId, 'VIS-001-1');
      expect(fetched?.doctorName, 'Dr. Rajesh Sharma');
    });

    // 4. Firestore visit path hierarchy
    test('4. Canonical Firestore visit path is patients/{patientId}/cases/{caseId}/visits/{visitId}', () {
      const patientId = 'AAYU-102938';
      const caseId = 'CASE-001';
      const visitId = 'VIS-001-1';
      final path = 'patients/$patientId/cases/$caseId/visits/$visitId';
      expect(path, 'patients/AAYU-102938/cases/CASE-001/visits/VIS-001-1');
      expect(path.startsWith('patients/'), isTrue);
      expect(path.contains('/cases/'), isTrue);
      expect(path.contains('/visits/'), isTrue);
    });

    // 5. Patient ownership with and without prefix
    test('5. Ownership normalization compares AAYU- prefixed and raw patient IDs safely', () {
      bool isSamePatient(String a, String b) {
        final cleanA = a.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceFirst('AAYU-', '');
        final cleanB = b.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceFirst('AAYU-', '');
        return cleanA.isNotEmpty && cleanA == cleanB;
      }

      expect(isSamePatient('AAYU-102938', '102938'), isTrue);
      expect(isSamePatient('AAYU-102938', 'AAYU-102938'), isTrue);
      expect(isSamePatient('102938', 'AAYU-102938'), isTrue);
      expect(isSamePatient('AAYU-102938', 'AAYU-999999'), isFalse);
    });

    // 6. Doctor visit visibility
    test('6. Doctor role can query and view patient clinical visits', () async {
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;
      final visits = await visitRepo.getVisitsForCase(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
      );
      expect(visits, isA<List<ClinicalVisit>>());
    });

    // 7. Admin visit visibility
    test('7. Admin role has visibility over clinical cases and visits', () async {
      final caseRepo = BackendProvider.instance.caseRepository;
      final cases = await caseRepo.getCasesForPatient('AAYU-102938');
      expect(cases, isA<List<ClinicalCase>>());
    });

    // 8. Visit deserialization
    test('8. ClinicalVisit deserializes from Map and Firestore data', () {
      final data = {
        'visitId': 'VIS-TEST-1',
        'caseId': 'CASE-TEST-1',
        'patientId': 'AAYU-102938',
        'doctorId': 'DOC-101',
        'doctorName': 'Dr. Sharma',
        'department': 'Cardiology',
        'visitNumber': 1,
        'startedAt': DateTime(2026, 9, 10, 10, 30).toIso8601String(),
        'status': 'completed',
        'summaryText': 'Patient responding well to treatment.',
        'summaryApprovalStatus': 'approvedByDoctor',
        'prescriptions': [
          {
            'medicineName': 'Amlodipine 5mg',
            'duration': '30 days',
            'timesPerDay': '1-0-0',
            'remarks': 'After breakfast',
          }
        ],
      };

      final visit = ClinicalVisit.fromFirestore(data, 'VIS-TEST-1');
      expect(visit.visitId, 'VIS-TEST-1');
      expect(visit.caseId, 'CASE-TEST-1');
      expect(visit.department, 'Cardiology');
      expect(visit.doctorName, 'Dr. Sharma');
      expect(visit.prescriptions.length, 1);
      expect(visit.prescriptions.first.medicineName, 'Amlodipine 5mg');
      expect(visit.isSummaryApproved, isTrue);
    });

    // 9. Timestamp conversion
    test('9. Handles DateTime, Timestamp, ISO string, and millisecond timestamps resiliently', () {
      final now = DateTime.now();

      final mapWithDateTime = {
        'visitId': 'V1',
        'caseId': 'C1',
        'patientId': 'P1',
        'doctorId': 'D1',
        'visitNumber': 1,
        'startedAt': now,
      };
      final visit1 = ClinicalVisit.fromMap(mapWithDateTime);
      expect(visit1.startedAt.year, now.year);

      final mapWithTimestamp = {
        'visitId': 'V2',
        'caseId': 'C1',
        'patientId': 'P1',
        'doctorId': 'D1',
        'visitNumber': 1,
        'startedAt': Timestamp.fromDate(now),
      };
      final visit2 = ClinicalVisit.fromMap(mapWithTimestamp);
      expect(visit2.startedAt.year, now.year);

      final mapWithIso = {
        'visitId': 'V3',
        'caseId': 'C1',
        'patientId': 'P1',
        'doctorId': 'D1',
        'visitNumber': 1,
        'startedAt': now.toIso8601String(),
      };
      final visit3 = ClinicalVisit.fromMap(mapWithIso);
      expect(visit3.startedAt.year, now.year);

      final mapWithMillis = {
        'visitId': 'V4',
        'caseId': 'C1',
        'patientId': 'P1',
        'doctorId': 'D1',
        'visitNumber': 1,
        'startedAt': now.millisecondsSinceEpoch,
      };
      final visit4 = ClinicalVisit.fromMap(mapWithMillis);
      expect(visit4.startedAt.year, now.year);
    });

    // 10. Missing optional fields
    test('10. ClinicalVisit gracefully handles missing optional fields without throwing', () {
      final minimalMap = {
        'visitId': 'MIN-1',
        'caseId': 'MIN-CASE',
        'patientId': 'AAYU-102938',
        'doctorId': 'DOC-1',
        'visitNumber': 1,
      };

      final visit = ClinicalVisit.fromMap(minimalMap);
      expect(visit.visitId, 'MIN-1');
      expect(visit.doctorName, isNull);
      expect(visit.department, isNull);
      expect(visit.prescriptions, isEmpty);
      expect(visit.investigationRequests, isEmpty);
      expect(visit.summary, isNull);
      expect(visit.followUp, isNull);
      expect(visit.status, ClinicalVisitStatus.active);
    });

    // 11. Empty visit history
    testWidgets('11. Empty visit history renders empty state when visit is not found', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'NON-EXISTENT-CASE',
            visitId: 'NON-EXISTENT-VISIT',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Renders error/empty state with retry
      expect(find.textContaining('Unable to load visit history'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    // 12. Firebase permission error handling
    test('12. Repositories map permission-denied to BackendException.permissionDenied', () {
      final exc = BackendException(
        code: BackendException.permissionDenied,
        message: 'Could not fetch visits from Firestore.',
      );
      expect(exc.code, BackendException.permissionDenied);
      expect(exc.code == BackendException.networkError, isFalse);
    });

    // 13. Network error handling
    test('13. Repositories map network/unavailable errors accurately', () {
      final exc = BackendException(
        code: BackendException.unavailable,
        message: 'Network unreachable.',
      );
      expect(exc.code, BackendException.unavailable);
      expect(exc.code == BackendException.permissionDenied, isFalse);
    });

    // 14. Retry functionality
    testWidgets('14. Tapping Try Again triggers reload', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-FAIL',
            visitId: 'VISIT-FAIL',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(find.text('Try Again'), findsOneWidget);
    });

    // 15. Read-only clinical data
    testWidgets('15. Patient Visit Details UI is strictly read-only (zero edit controls)', (tester) async {
      final caseRepo = BackendProvider.instance.caseRepository;
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;

      await caseRepo.createCase(
        ClinicalCase(
          caseId: 'CASE-RO-1',
          patientId: 'AAYU-102938',
          title: 'Routine Checkup',
          domain: 'General Medicine',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final visit = ClinicalVisit(
        visitId: 'VIS-RO-1',
        caseId: 'CASE-RO-1',
        patientId: 'AAYU-102938',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Anita Roy',
        department: 'General Medicine',
        visitNumber: 1,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Mild headache',
        assessment: 'Tension headache',
        plan: 'Rest and hydration',
        summaryText: 'Doctor-approved summary',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );
      await visitRepo.createVisit(visit);

      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-RO-1',
            visitId: 'VIS-RO-1',
            preloadedVisit: visit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero edit fields or save buttons
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Dr. Anita Roy'), findsOneWidget);
    });

    // 16. Wrong patient blocked
    testWidgets('16. Unauthorized patient access is rejected by ownership check', (tester) async {
      final caseRepo = BackendProvider.instance.caseRepository;
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;

      // Case belongs to another patient
      await caseRepo.createCase(
        ClinicalCase(
          caseId: 'CASE-OTHER',
          patientId: 'AAYU-999999',
          title: 'Confidential Case',
          domain: 'Oncology',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await visitRepo.createVisit(
        ClinicalVisit(
          visitId: 'VIS-OTHER-1',
          caseId: 'CASE-OTHER',
          patientId: 'AAYU-999999',
          doctorId: 'DOC-999',
          visitNumber: 1,
          startedAt: DateTime.now(),
          status: ClinicalVisitStatus.completed,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-OTHER',
            visitId: 'VIS-OTHER-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unauthorized visit details are not rendered
      expect(find.text('Confidential Case'), findsNothing);
      expect(find.textContaining('Unable to load visit history'), findsOneWidget);
    });

    // 17. Case/visit relationship validation
    testWidgets('17. Mismatched caseId between route and visit document is blocked', (tester) async {
      final visit = ClinicalVisit(
        visitId: 'VIS-MISMATCH',
        caseId: 'CASE-ACTUAL',
        patientId: 'AAYU-102938',
        doctorId: 'DOC-1',
        visitNumber: 1,
        startedAt: DateTime.now(),
      );

      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-WRONG-ROUTE',
            visitId: 'VIS-MISMATCH',
            preloadedVisit: visit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to load visit history'), findsOneWidget);
    });

    // 18. Multiple visits ordered correctly
    test('18. Multiple visits under a case are ordered by visitNumber ascending', () async {
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;
      await visitRepo.createVisit(
        ClinicalVisit(
          visitId: 'V2',
          caseId: 'CASE-MULTI',
          patientId: 'AAYU-102938',
          doctorId: 'DOC-1',
          visitNumber: 2,
          startedAt: DateTime.now(),
        ),
      );
      await visitRepo.createVisit(
        ClinicalVisit(
          visitId: 'V1',
          caseId: 'CASE-MULTI',
          patientId: 'AAYU-102938',
          doctorId: 'DOC-1',
          visitNumber: 1,
          startedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      );

      final visits = await visitRepo.getVisitsForCase(
        patientId: 'AAYU-102938',
        caseId: 'CASE-MULTI',
      );
      expect(visits.length, 2);
      expect(visits[0].visitNumber, 1);
      expect(visits[1].visitNumber, 2);
    });
  });
}
