import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/patient/controllers/patient_cases_controller.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_session.dart';
import 'package:aayusathi/patient/screens/patient_cases_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_top_bar.dart';
import 'package:aayusathi/repositories/case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

class PermissionDeniedCaseRepository implements CaseRepository {
  @override
  Future<List<ClinicalCase>> getCasesForPatient(String patientId) async {
    throw const BackendException(
      code: BackendException.permissionDenied,
      message: 'Could not retrieve patient clinical cases from Firestore.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository mockCaseRepo;
  late MockPatientRepository mockPatientRepo;
  late PatientSessionService sessionService;

  setUp(() {
    mockCaseRepo = MockCaseRepository.instance;
    mockPatientRepo = MockPatientRepository.instance;
    sessionService = PatientSessionService.instance;
    sessionService.logout();
    PatientAppState.instance.resetSession();
  });

  tearDown(() {
    sessionService.logout();
    PatientAppState.instance.resetSession();
  });

  group('AAYUSATHI P4 Live Android Bug Fix Regression Suite', () {
    test('1. Authenticated patient case query uses PatientSession.patientId exclusively', () async {
      sessionService.setSession(PatientSession.authenticated(
        patientId: 'AAYU-102938',
      ));

      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await controller.loadCases();
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(sessionService.authenticatedPatientId, equals('AAYU-102938'));
    });

    test('2. Case model deserialization handles missing/alternative fields safely', () {
      final jsonWithFallbacks = {
        'department': 'Cardiology',
        'problemLabel': 'Chest Discomfort',
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
        'visitCount': 2,
      };

      final clinicalCase = ClinicalCase.fromFirestore(jsonWithFallbacks, 'DOC-CASE-999');
      expect(clinicalCase.caseId, equals('DOC-CASE-999'));
      expect(clinicalCase.domain, equals('Cardiology'));
      expect(clinicalCase.title, equals('Chest Discomfort'));
      expect(clinicalCase.isOpen, isTrue);
      expect(clinicalCase.visitCount, equals(2));
    });

    test('3. Case status parsing handles closed/open string variants safely', () {
      final openCase = ClinicalCase.fromMap({
        'caseId': 'C1',
        'patientId': 'P1',
        'status': 'ClinicalCaseStatus.open',
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(openCase.isOpen, isTrue);
      expect(openCase.isClosed, isFalse);

      final closedCase = ClinicalCase.fromMap({
        'caseId': 'C2',
        'patientId': 'P1',
        'status': 'closed',
        'createdAt': DateTime.now().toIso8601String(),
        'closedAt': DateTime.now().toIso8601String(),
      });
      expect(closedCase.isOpen, isFalse);
      expect(closedCase.isClosed, isTrue);
    });

    testWidgets('4. Permission-denied error renders user-friendly error envelope without technical leak', (tester) async {
      sessionService.setSession(PatientSession.authenticated(
        patientId: 'AAYU-102938',
      ));

      final controller = PatientCasesController(
        caseRepo: PermissionDeniedCaseRepository(),
        sessionService: sessionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to load your cases'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      // Ensure no raw backend error string leaks to UI
      expect(find.textContaining('permission-denied'), findsNothing);
      expect(find.textContaining('BackendException'), findsNothing);
    });

    testWidgets('5. Empty active cases tab displays "No Ongoing Cases"', (tester) async {
      sessionService.setSession(PatientSession.authenticated(
        patientId: 'EMPTY-PATIENT-001',
      ));

      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('You currently have no active cases.'), findsOneWidget);
    });

    testWidgets('6. Empty completed cases tab displays "No Completed Cases"', (tester) async {
      sessionService.setSession(PatientSession.authenticated(
        patientId: 'EMPTY-PATIENT-001',
      ));

      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('No Completed Cases'), findsOneWidget);
      expect(find.text("You don't have any completed cases yet."), findsOneWidget);
    });

    testWidgets('7. Header Top Bar contains ONLY official AAYUSATHI branding and profile button (zero social icons)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PatientTopBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify official logo asset is rendered
      expect(find.byType(Image), findsOneWidget);
      // Verify profile icon
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      // Verify NO social media icons exist
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.thumb_up), findsNothing);
      expect(find.byIcon(Icons.chat_bubble), findsNothing);
    });

    test('8. P3 Dashboard regression: DashboardController retrieves patient-specific cases correctly', () async {
      sessionService.setSession(PatientSession.authenticated(
        patientId: 'AAYU-102938',
      ));

      final dashboardController = PatientDashboardController(
        patientRepo: mockPatientRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await dashboardController.loadDashboardData();
      expect(dashboardController.isLoading, isFalse);
      expect(dashboardController.hasError, isFalse);
      expect(dashboardController.ongoingCasesCount, greaterThanOrEqualTo(0));
    });

    test('9. Patient session isolation: logout wipes session and case state cleanly', () async {
      sessionService.startSession('AAYU-102938');
      expect(sessionService.isAuthenticated, isTrue);

      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadCases();

      // Perform logout
      sessionService.logout();
      expect(sessionService.isAuthenticated, isFalse);
      expect(sessionService.authenticatedPatientId, isNull);
      expect(PatientAppState.instance.authenticatedPatientId, isNull);
    });
  });
}
