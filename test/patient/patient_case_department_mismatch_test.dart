import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/screens/patient_case_detail_screen.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_case_card.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockPatientRepository mockPatientRepo;
  final sessionService = PatientSessionService.instance;

  const testPatientId = 'PAT-TEST-001';

  final testPatient = Patient(
    patientId: testPatientId,
    name: 'Aarav Sharma',
    phone: '9876543210',
    dateOfBirth: '2002-01-01',
    age: 24,
    gender: 'Male',
    bloodGroup: 'O+',
    address: 'Mumbai, Maharashtra',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() async {
    mockCaseRepo = MockCaseRepository.instance..resetToDefaults();
    mockVisitRepo = MockClinicalVisitRepository.instance..resetToDefaults();
    mockPatientRepo = MockPatientRepository.instance..resetToDefaults();

    BackendProvider.instance.setCustomRepositories(
      caseRepo: mockCaseRepo,
      clinicalVisitRepo: mockVisitRepo,
      patientRepo: mockPatientRepo,
    );

    await mockPatientRepo.savePatient(testPatient);
    sessionService.startSession(testPatientId, authUid: 'auth-test-uid');
  });

  tearDown(() {
    sessionService.logout();
    BackendProvider.instance.resetOverrides();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: PatientTheme.theme,
      home: PatientLocalizations.provider(
        strings: PatientLocalizations.forLocaleCode('en'),
        child: Scaffold(body: child),
      ),
    );
  }

  group('AAYUSATHI: Patient Case Department Mismatch Fix Test Suite', () {
    // 1. Dermatology case -> displays Dermatology
    testWidgets('1. Dermatology case displays "Dermatology" and NOT "General Medicine"', (tester) async {
      final dermCase = ClinicalCase(
        caseId: 'CASE-DERM-001',
        patientId: testPatientId,
        domain: 'Dermatology',
        title: 'Acne Vulgaris Consultation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: dermCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dermatology'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
      expect(find.text('Acne Vulgaris Consultation'), findsOneWidget);
    });

    // 1b. Lowercase 'dermatology' case -> displays 'Dermatology'
    testWidgets('1b. Lowercase "dermatology" normalizes to "Dermatology"', (tester) async {
      final dermCase = ClinicalCase(
        caseId: 'CASE-DERM-002',
        patientId: testPatientId,
        domain: 'dermatology',
        title: 'Eczema Flare-up',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: dermCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dermatology'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
    });

    // 2. Cardiology case -> displays Cardiology
    testWidgets('2. Cardiology case displays "Cardiology"', (tester) async {
      final cardioCase = ClinicalCase(
        caseId: 'CASE-CARD-001',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Hypertension Management',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 2,
      );

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: cardioCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
    });

    // 3. Pediatrics case -> displays Pediatrics
    testWidgets('3. Pediatrics case displays "Pediatrics"', (tester) async {
      final pedsCase = ClinicalCase(
        caseId: 'CASE-PEDS-001',
        patientId: testPatientId,
        domain: 'pediatrics',
        title: 'Annual Well-Child Checkup',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: pedsCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pediatrics'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
    });

    // 4. General Medicine case -> displays General Medicine
    testWidgets('4. General Medicine case displays "General Medicine" when actually stored as such', (tester) async {
      final gmCase = ClinicalCase(
        caseId: 'CASE-GM-001',
        patientId: testPatientId,
        domain: 'general_medicine',
        title: 'Routine Health Checkup',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: gmCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('General Medicine'), findsOneWidget);
    });

    // 5. Missing department -> displays Department not available (never General Medicine)
    testWidgets('5. Missing department displays "Department not available" without hardcoded General Medicine', (tester) async {
      final missingDeptCase = ClinicalCase.fromMap({
        'caseId': 'CASE-EMPTY-001',
        'patientId': testPatientId,
        'title': 'Unspecified Condition',
      });

      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: missingDeptCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Department not available'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
    });

    // 6. Case Details matches Cases card
    testWidgets('6. Case Details screen matches Cases card department display exactly', (tester) async {
      final dermCase = ClinicalCase(
        caseId: 'CASE-DERM-003',
        patientId: testPatientId,
        domain: 'Dermatology',
        title: 'Acne Severity Grade 2',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      await mockCaseRepo.createCase(dermCase);

      // Card rendering
      await tester.pumpWidget(createTestWidget(
        PatientCaseCard(
          clinicalCase: dermCase,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dermatology'), findsOneWidget);

      // Detail Screen rendering
      await tester.pumpWidget(createTestWidget(
        PatientCaseDetailScreen(
          caseId: 'CASE-DERM-003',
          preloadedCase: dermCase,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dermatology'), findsOneWidget);
      expect(find.text('General Medicine'), findsNothing);
      expect(find.text('Acne Severity Grade 2'), findsOneWidget);
    });

    // 7. Visit Details matches case department
    testWidgets('7. Visit Details matches case department and does not show General Medicine', (tester) async {
      final dermCase = ClinicalCase(
        caseId: 'CASE-DERM-004',
        patientId: testPatientId,
        domain: 'Dermatology',
        title: 'Acne Treatment Follow-up',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 10),
        visitCount: 1,
      );

      final visit = ClinicalVisit(
        visitId: 'VIS-DERM-001',
        caseId: 'CASE-DERM-004',
        patientId: testPatientId,
        doctorId: 'DOC-DERM-01',
        doctorName: 'Dr. Neha Shah',
        department: 'Dermatology',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 10),
        status: ClinicalVisitStatus.completed,
      );

      await mockCaseRepo.createCase(dermCase);
      await mockVisitRepo.createVisit(visit);

      await tester.pumpWidget(createTestWidget(
        PatientVisitDetailScreen(
          caseId: 'CASE-DERM-004',
          visitId: 'VIS-DERM-001',
          preloadedVisit: visit,
        ),
      ));
      await tester.pumpAndSettle();

      // Department in header
      expect(find.text('Dermatology'), findsWidgets);
      expect(find.text('General Medicine'), findsNothing);
    });

    // 8. Firestore deserialization preserves department across all key variants
    test('8. Firestore deserialization preserves department across all candidate keys and cases', () {
      final keys = [
        'domain',
        'domainId',
        'department',
        'departmentId',
        'caseDepartment',
        'visitDepartment',
        'specialty',
        'speciality',
      ];

      for (final key in keys) {
        final c1 = ClinicalCase.fromMap({
          'caseId': 'C-1',
          'patientId': 'P-1',
          key: 'dermatology',
        });
        expect(c1.domain, equals('Dermatology'), reason: 'Failed for key $key lowercase');

        final c2 = ClinicalCase.fromMap({
          'caseId': 'C-2',
          'patientId': 'P-1',
          key: 'DERMATOLOGY',
        });
        expect(c2.domain, equals('Dermatology'), reason: 'Failed for key $key uppercase');

        final c3 = ClinicalCase.fromMap({
          'caseId': 'C-3',
          'patientId': 'P-1',
          key: 'Dermatology',
        });
        expect(c3.domain, equals('Dermatology'), reason: 'Failed for key $key titlecase');
      }

      // Other specialties
      expect(ClinicalCase.normalizeDepartment('ent'), equals('ENT'));
      expect(ClinicalCase.normalizeDepartment('ENT'), equals('ENT'));
      expect(ClinicalCase.normalizeDepartment('orthopedics'), equals('Orthopedics'));
      expect(ClinicalCase.normalizeDepartment('paediatrics'), equals('Pediatrics'));
      expect(ClinicalCase.normalizeDepartment('gastroenterology'), equals('Gastroenterology'));
      expect(ClinicalCase.normalizeDepartment('neurology'), equals('Neurology'));
      expect(ClinicalCase.normalizeDepartment('general_medicine'), equals('General Medicine'));
    });

    // 9. Existing cases are not modified incorrectly
    test('9. Existing mock repository cases retain correct clinical departments', () async {
      final cases = await MockCaseRepository.instance.getCasesForPatient('PAT-MOCK-001');
      expect(cases.isNotEmpty, isTrue);

      final c1 = cases.firstWhere((c) => c.caseId == 'CASE-PAT-001-01');
      expect(c1.displayDepartment, equals('General Medicine'));

      final c2 = cases.firstWhere((c) => c.caseId == 'CASE-PAT-001-02');
      expect(c2.displayDepartment, equals('Orthopedics'));

      final dermCases = await MockCaseRepository.instance.getCasesForPatient('AAYU-482910');
      expect(dermCases.first.displayDepartment, equals('Dermatology'));
    });

    // 10. No hardcoded General Medicine fallback
    test('10. No hardcoded General Medicine fallback when department is omitted or empty', () {
      final emptyCase = ClinicalCase.fromMap({
        'caseId': 'C-EMPTY',
        'patientId': 'P-EMPTY',
      });
      expect(emptyCase.domain, equals('Department not available'));
      expect(emptyCase.displayDepartment, equals('Department not available'));
      expect(emptyCase.domain.toLowerCase().contains('general medicine'), isFalse);

      final whitespaceCase = ClinicalCase.fromMap({
        'caseId': 'C-WS',
        'patientId': 'P-WS',
        'domain': '   ',
      });
      expect(whitespaceCase.domain, equals('Department not available'));

      final emptyVisit = ClinicalVisit.fromMap({
        'visitId': 'V-EMPTY',
        'caseId': 'C-EMPTY',
        'patientId': 'P-EMPTY',
        'doctorId': 'DOC-1',
      });
      expect(emptyVisit.department, isNull);
      expect(emptyVisit.displayDepartment, equals('Department not available'));
    });
  });
}
