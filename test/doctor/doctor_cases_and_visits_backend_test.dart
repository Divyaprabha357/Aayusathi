import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_state_views.dart';
import 'package:aayusathi/repositories/case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';

/// Test repository implementing CaseRepository to simulate specific backend exceptions.
class ControllableCaseRepository implements CaseRepository {
  List<ClinicalCase> customCases = [];
  BackendException? exceptionToThrow;
  int getCasesForDoctorCallCount = 0;
  String? lastQueriedDoctorId;

  @override
  Future<List<ClinicalCase>> getCasesForDoctor(String doctorId) async {
    final cleanDoctorId = doctorId.trim();
    if (cleanDoctorId.isEmpty) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Doctor ID cannot be empty.',
      );
    }
    getCasesForDoctorCallCount++;
    lastQueriedDoctorId = cleanDoctorId;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return customCases;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControllableCaseRepository testRepo;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    testRepo = ControllableCaseRepository();
    BackendProvider.instance.setCustomRepositories(caseRepo: testRepo);
    DoctorSessionService.instance.resetSession();
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
  });

  tearDown(() {
    BackendProvider.instance.resetOverrides();
    DoctorSessionService.instance.resetSession();
  });

  group('AAYUSATHI Doctor Cases & Visits Backend Fix Tests', () {
    test('1. Authenticated Doctor loads clinical cases successfully', () async {
      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-103',
          doctorUniqueCode: 'DOC-103',
          name: 'Dr Anukush Khot',
          qualification: 'MBBS',
          department: 'general_medicine',
          registeredPhone: '+918795641647',
          email: 'doc-103@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'test-uid-103',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final now = DateTime.now();
      testRepo.customCases = [
        ClinicalCase(
          caseId: 'CASE-1789041094096',
          patientId: 'AAYU-102938',
          domain: 'general_medicine',
          title: 'Fever',
          status: ClinicalCaseStatus.open,
          visitCount: 1,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
        ),
      ];

      final cases = await testRepo.getCasesForDoctor('DOC-103');
      expect(cases.length, equals(1));
      expect(cases.first.caseId, equals('CASE-1789041094096'));
      expect(cases.first.title, equals('Fever'));
      expect(cases.first.domain, equals('general_medicine'));
    });

    test('2. Empty doctorId throws invalidData BackendException', () async {
      expect(
        () => testRepo.getCasesForDoctor('   '),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          equals(BackendException.invalidData),
        )),
      );
    });

    test('3. Doctor-specific visibility excludes other doctors cases', () async {
      final now = DateTime.now();
      final caseDoc103 = ClinicalCase(
        caseId: 'CASE-DOC-103',
        patientId: 'AAYU-102938',
        domain: 'general_medicine',
        title: 'Fever',
        status: ClinicalCaseStatus.open,
        createdAt: now,
      );

      testRepo.customCases = [caseDoc103];
      final results = await testRepo.getCasesForDoctor('DOC-103');
      expect(results.any((c) => c.caseId == 'CASE-DOC-103'), isTrue);
      expect(results.any((c) => c.caseId == 'CASE-DOC-104'), isFalse);
    });

    test('4. Cross-department continuity: Doctor retains access even if case domain differs', () async {
      final now = DateTime.now();
      final crossDeptCase = ClinicalCase(
        caseId: 'CASE-CROSS-DEPT',
        patientId: 'AAYU-102938',
        domain: 'Gastroenterology',
        title: 'Abdominal pain',
        status: ClinicalCaseStatus.open,
        createdAt: now,
      );

      testRepo.customCases = [crossDeptCase];
      final cases = await testRepo.getCasesForDoctor('DOC-103');
      expect(cases.first.domain, equals('Gastroenterology'));
      expect(cases.first.caseId, equals('CASE-CROSS-DEPT'));
    });

    test('5. Open and closed cases preserve their respective lifecycle statuses', () async {
      final now = DateTime.now();
      testRepo.customCases = [
        ClinicalCase(
          caseId: 'CASE-OPEN',
          patientId: 'P1',
          domain: 'general_medicine',
          title: 'Open Case',
          status: ClinicalCaseStatus.open,
          createdAt: now,
        ),
        ClinicalCase(
          caseId: 'CASE-CLOSED',
          patientId: 'P2',
          domain: 'general_medicine',
          title: 'Closed Case',
          status: ClinicalCaseStatus.closed,
          closedByDoctorId: 'DOC-103',
          closureNote: 'Patient recovered fully.',
          createdAt: now,
        ),
      ];

      final cases = await testRepo.getCasesForDoctor('DOC-103');
      final openCase = cases.firstWhere((c) => c.caseId == 'CASE-OPEN');
      final closedCase = cases.firstWhere((c) => c.caseId == 'CASE-CLOSED');

      expect(openCase.isOpen, isTrue);
      expect(openCase.isClosed, isFalse);
      expect(closedCase.isClosed, isTrue);
      expect(closedCase.isOpen, isFalse);
      expect(closedCase.closedByDoctorId, equals('DOC-103'));
      expect(closedCase.closureNote, equals('Patient recovered fully.'));
    });

    test('6. Error mapping: permission-denied maps to descriptive error', () async {
      testRepo.exceptionToThrow = const BackendException(
        code: BackendException.permissionDenied,
        message: 'Firestore permission denied. Doctor is not authorized to read clinical cases.',
      );

      expect(
        () => testRepo.getCasesForDoctor('DOC-103'),
        throwsA(isA<BackendException>().having(
          (e) => e.message,
          'message',
          contains('permission denied'),
        )),
      );
    });

    test('7. Error mapping: failed-precondition index error maps to index description', () async {
      testRepo.exceptionToThrow = const BackendException(
        code: BackendException.unavailable,
        message: 'Clinical records query requires a Firestore index. Index provisioning in progress.',
      );

      expect(
        () => testRepo.getCasesForDoctor('DOC-103'),
        throwsA(isA<BackendException>().having(
          (e) => e.message,
          'message',
          contains('requires a Firestore index'),
        )),
      );
    });

    test('8. Error mapping: network unavailable maps to networkError code', () async {
      testRepo.exceptionToThrow = const BackendException(
        code: BackendException.networkError,
        message: 'Network unavailable. Please check your connection and retry.',
      );

      expect(
        () => testRepo.getCasesForDoctor('DOC-103'),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          equals(BackendException.networkError),
        )),
      );
    });

    testWidgets('9. DoctorCaseScreen renders clean empty state when doctor has zero cases', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-103',
          doctorUniqueCode: 'DOC-103',
          name: 'Dr Anukush Khot',
          qualification: 'MBBS',
          department: 'general_medicine',
          registeredPhone: '+918795641647',
          email: 'doc-103@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'test-uid-103',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      testRepo.customCases = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DoctorEmptyView), findsOneWidget);
      expect(find.text('No Clinical Cases'), findsOneWidget);
      expect(find.byType(DoctorErrorView), findsNothing);
    });

    testWidgets('10. DoctorCaseScreen renders meaningful DoctorErrorView on failure and Retry works', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-103',
          doctorUniqueCode: 'DOC-103',
          name: 'Dr Anukush Khot',
          qualification: 'MBBS',
          department: 'general_medicine',
          registeredPhone: '+918795641647',
          email: 'doc-103@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'test-uid-103',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      testRepo.exceptionToThrow = const BackendException(
        code: BackendException.unavailable,
        message: 'Clinical records query requires a Firestore index. Index provisioning in progress.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DoctorErrorView), findsOneWidget);
      expect(
        find.text('Clinical records query requires a Firestore index. Index provisioning in progress.'),
        findsOneWidget,
      );

      // Clear exception and provide cases, then tap Retry
      testRepo.exceptionToThrow = null;
      testRepo.customCases = [
        ClinicalCase(
          caseId: 'CASE-RETRY-SUCCESS',
          patientId: 'AAYU-102938',
          domain: 'general_medicine',
          title: 'Resolved After Retry',
          status: ClinicalCaseStatus.open,
          createdAt: DateTime.now(),
        ),
      ];

      final retryFinder = find.text('Retry');
      expect(retryFinder, findsOneWidget);
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorErrorView), findsNothing);
      expect(find.text('Resolved After Retry'), findsOneWidget);
      expect(testRepo.getCasesForDoctorCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('11. DoctorCaseScreen renders real cases with all required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await DoctorSessionService.instance.enterDevelopmentWorkspace(
        profile: DoctorProfile(
          doctorId: 'DOC-103',
          doctorUniqueCode: 'DOC-103',
          name: 'Dr Anukush Khot',
          qualification: 'MBBS',
          department: 'general_medicine',
          registeredPhone: '+918795641647',
          email: 'doc-103@hospital.aayusathi.in',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'test-uid-103',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final now = DateTime.now();
      testRepo.customCases = [
        ClinicalCase(
          caseId: 'CASE-1789041094096',
          patientId: 'AAYU-102938',
          domain: 'general_medicine',
          title: 'Fever',
          status: ClinicalCaseStatus.open,
          visitCount: 2,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('general_medicine'), findsOneWidget);
      expect(find.text('Patient ID: AAYU-102938'), findsOneWidget);
      expect(find.text('CASES: CASE-1789041094096'), findsOneWidget);
      expect(find.text('2 visits'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
    });
  });
}
