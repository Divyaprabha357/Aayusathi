import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_dev_workspace_controller.dart';
import 'package:aayusathi/doctor/services/doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_profile_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_consultation_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
  Map<String, dynamic>? initialArgs,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: {
      AppRoutes.doctorDashboard: (ctx) => const Scaffold(body: Text('Doctor Dashboard Screen')),
      AppRoutes.doctorPatientWorkspace: (ctx) =>
          DoctorPatientWorkspaceScreen(initialArguments: initialArgs),
    },
    home: DoctorLocalizations.provider(
      strings: DoctorLocalizations.forLocale(locale),
      child: Material(child: child),
    ),
  );
}

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1366, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAuditRepo;
  late MockPatientRepository mockPatientRepo;
  late MockAppointmentRepository mockApptRepo;
  late MockVitalRepository mockVitalRepo;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockDoctorPresenceService mockPresenceService;
  late MockDoctorPatientRequestService mockRequestService;
  late MockDoctorPatientWorkspaceService mockWorkspaceService;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockAuditRepo = MockAuditRepository.instance;
    mockAuditRepo.clear();

    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();

    mockApptRepo = MockAppointmentRepository.instance;
    mockApptRepo.clear();

    mockVitalRepo = MockVitalRepository.instance;
    mockVitalRepo.clear();

    mockCaseRepo = MockCaseRepository.instance;
    mockCaseRepo.resetToDefaults();

    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockVisitRepo.resetToDefaults();

    mockPresenceService = MockDoctorPresenceService(
      initialStatus: DoctorAvailabilityStatus.available,
    );
    DoctorPresenceService.instance = mockPresenceService;

    mockSession = MockDoctorSessionService(auditRepository: mockAuditRepo);
    DoctorSessionService.instance = mockSession;

    mockRequestService = MockDoctorPatientRequestService();
    mockRequestService.resetToDefault();
    DoctorPatientRequestService.instance = mockRequestService;

    mockWorkspaceService = MockDoctorPatientWorkspaceService.instance;
    DoctorPatientWorkspaceService.instance = mockWorkspaceService;

    DoctorDevWorkspaceController.devModeOverride = true;
  });

  tearDown(() {
    DoctorDevWorkspaceController.devModeOverride = null;
    DoctorPatientRequestService.instance = null;
    DoctorPatientWorkspaceService.instance = null;
    BackendProvider.instance.resetOverrides();
  });

  group('D8 Regression: D6 Request Acceptance to Patient Workspace Flow', () {
    test('1. D6 accept request creates appointment, updates status, and workspace resolves it', () async {
      // 1. Doctor enters development workspace
      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );
      expect(mockSession.isDevelopmentMode, isTrue);
      expect(mockSession.activeDoctorId, equals('DOC-101'));

      // 2. Doctor fetches pending requests
      final pending = await mockRequestService.getPendingRequests();
      expect(pending.isNotEmpty, isTrue);
      final req = pending.first;
      expect(req.requestId, equals('REQ-D5-001'));
      expect(req.isWaiting, isTrue);

      // 3. Doctor accepts request via D6 service
      final result = await mockRequestService.acceptPatientRequest(
        requestId: req.requestId,
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(result.isSuccess, isTrue);
      expect(result.assignedDoctorId, equals('DOC-101'));

      // 4. Verify request is marked assigned in mock service
      final updatedReq = mockRequestService.getRequestById(req.requestId);
      expect(updatedReq, isNotNull);
      expect(updatedReq!.isAssigned, isTrue);
      expect(updatedReq.assignedDoctorId, equals('DOC-101'));

      // 5. Verify appointment was saved in appointment repository
      final savedAppt = await BackendProvider.instance.appointmentRepository
          .getAppointmentById(req.requestId);
      expect(savedAppt, isNotNull);
      expect(savedAppt!.requestId, equals('REQ-D5-001'));
      expect(savedAppt.assignedDoctorId, equals('DOC-101'));
      expect(savedAppt.status, equals(AppointmentStatus.accepted));

      // 6. Doctor workspace service loads workspace data without error
      final data = await DoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: req.requestId,
        doctorId: 'DOC-101',
      );

      expect(data.isSuccess, isTrue);
      expect(data.patient, isNotNull);
      expect(data.patient!.patientId, equals('PAT-MOCK-001'));
      expect(data.patient!.name, equals('Aarav Sharma'));
      expect(data.appointment, isNotNull);
      expect(data.appointment!.assignedDoctorId, equals('DOC-101'));
      expect(data.vitals, isNotNull);
      expect(data.cases, isNotEmpty);
      expect(data.visits, isNotEmpty);
      expect(data.message, isNull);
    });

    test('2. Development Workspace is strictly isolated when BackendProvider is in Firebase mode', () async {
      // Set global backend mode to firebase (simulating startup with live Firebase)
      BackendProvider.instance.setMode(BackendMode.firebase);
      expect(BackendProvider.instance.isFirebaseMode, isTrue);

      // Doctor logs into Development Workspace
      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );
      expect(mockSession.isDevelopmentMode, isTrue);

      // When doctor is in development mode, workspace and request services resolve to mock
      expect(DoctorPatientWorkspaceService.instance, isA<MockDoctorPatientWorkspaceService>());
      expect(DoctorPatientRequestService.instance, isA<MockDoctorPatientRequestService>());

      // Repositories also return mock implementations
      expect(BackendProvider.instance.patientRepository, isA<MockPatientRepository>());
      expect(BackendProvider.instance.appointmentRepository, isA<MockAppointmentRepository>());
      expect(BackendProvider.instance.caseRepository, isA<MockCaseRepository>());
      expect(BackendProvider.instance.clinicalVisitRepository, isA<MockClinicalVisitRepository>());

      // Accept request in mock queue
      final result = await DoctorPatientRequestService.instance.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(result.isSuccess, isTrue);

      // Load workspace data for accepted request
      final data = await DoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
      );

      // MUST succeed without Firestore connection error or appointmentNotFound
      expect(data.isSuccess, isTrue);
      expect(data.patient?.name, equals('Aarav Sharma'));
      expect(data.appointment?.queueNumber, equals('A-00027'));
    });

    test('3. Custom dynamic request is successfully resolved and auto-initializes case/visit if empty', () async {
      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );

      // Custom request with a new patient who has no pre-existing cases
      final customRequest = DoctorPatientRequest(
        requestId: 'REQ-CUSTOM-NEW-01',
        appointmentId: 'APT-CUSTOM-NEW-01',
        patientId: 'PAT-CUSTOM-NEW',
        queueNumber: 'A-00999',
        age: 29,
        gender: 'Female',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        status: PatientRequestStatus.waiting,
        vitals: VitalReading(
          vitalId: 'VIT-CUSTOM-01',
          patientId: 'PAT-CUSTOM-NEW',
          appointmentId: 'APT-CUSTOM-NEW-01',
          spo2: 99,
          heartRate: 72,
          temperature: 36.5,
          timestamp: DateTime.now(),
          status: VitalStatus.valid,
        ),
      );

      mockRequestService.setRequests([customRequest]);

      final acceptResult = await mockRequestService.acceptPatientRequest(
        requestId: customRequest.requestId,
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(acceptResult.isSuccess, isTrue);

      // Load workspace data
      final data = await DoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: customRequest.requestId,
        doctorId: 'DOC-101',
      );

      expect(data.isSuccess, isTrue);
      expect(data.patient, isNotNull);
      expect(data.vitals?.spo2, equals(99));
      expect(data.cases, isNotEmpty);
      expect(data.cases.first.isOpen, isTrue);

      // In D16, workspace data initializes open case without auto-creating an active visit.
      // Creating next visit explicitly creates the active consultation visit.
      final visit = await BackendProvider.instance.clinicalVisitRepository.createNextVisit(
        patientId: data.patient!.patientId,
        caseId: data.cases.first.caseId,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
      );
      expect(visit.isActive, isTrue);
      expect(visit.visitNumber, greaterThanOrEqualTo(1));
    });

    test('4. Workspace rejects unauthorized doctor when assigned to a different physician', () async {
      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );

      // Accept request for DOC-101
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      // Another doctor DOC-999 attempts to open workspace
      final data = await DoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-999',
      );

      expect(data.isUnauthorized, isTrue);
      expect(data.isSuccess, isFalse);
    });

    testWidgets('5. Full UI rendering: Patient Workspace successfully renders accepted patient without error screen', (tester) async {
      setDesktopViewport(tester);

      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );

      // Accept request in mock queue
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'appointmentId': 'APT-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the error messages DO NOT appear
      expect(find.text('Patient information could not be loaded.'), findsNothing);
      expect(find.text('Appointment consultation record could not be found.'), findsNothing);

      // Verify header and identification
      expect(find.textContaining('A-00027'), findsWidgets);
      expect(find.textContaining('Aarav Sharma'), findsWidgets);
      expect(find.textContaining('Cardiology'), findsWidgets);

      // Verify Vitals section
      expect(find.textContaining('97%'), findsWidgets);
      expect(find.textContaining('122 / 80'), findsNothing);

      // Verify Consultation Cards exist
      expect(find.byType(DoctorVisitIdentificationCard), findsOneWidget);
      expect(find.byType(DoctorPatientInfoConsultationCard), findsOneWidget);
      expect(find.byType(DoctorVitalsConsultationCard), findsOneWidget);
      expect(find.byType(DoctorStructuredConsultationCard), findsOneWidget);
      expect(find.byType(DoctorApprovedSummaryCard), findsOneWidget);
      expect(find.byType(DoctorInvestigationRequestsCard), findsOneWidget);
      expect(find.byType(DoctorFollowUpCard), findsOneWidget);

      // Verify bottom action buttons exist
      expect(find.byType(DoctorWorkspaceBottomBar), findsOneWidget);
      expect(find.text('SAVE DRAFT'), findsOneWidget);
      expect(find.text('COMPLETE VISIT'), findsOneWidget);
    });

    testWidgets('6. UI route argument fallback: works when only appointmentId is provided', (tester) async {
      setDesktopViewport(tester);

      await mockSession.enterDevelopmentWorkspace(
        profile: MockDoctorProfileService.demoDoctor,
      );

      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      // Navigate with only appointmentId
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'appointmentId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Patient information could not be loaded.'), findsNothing);
      expect(find.textContaining('Aarav Sharma'), findsWidgets);
    });
  });
}
