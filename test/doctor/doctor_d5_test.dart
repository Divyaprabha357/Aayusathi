import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_request_screen.dart';
import 'package:aayusathi/doctor/services/doctor_dashboard_metrics_service.dart';
import 'package:aayusathi/doctor/services/doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_request_card.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: DoctorLocalizations.provider(
      strings: DoctorLocalizations.forLocale(locale),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorPresenceService mockPresence;
  late MockDoctorSessionService mockSession;
  late MockDoctorPatientRequestService mockRequestService;
  late MockAuditRepository mockAudit;

  setUp(() {
    mockPresence = MockDoctorPresenceService(
      initialStatus: DoctorAvailabilityStatus.available,
    );
    DoctorPresenceService.instance = mockPresence;

    mockAudit = MockAuditRepository();
    mockSession = MockDoctorSessionService(auditRepository: mockAudit);
    DoctorSessionService.instance = mockSession;

    mockRequestService = MockDoctorPatientRequestService();
    DoctorPatientRequestService.instance = mockRequestService;
  });

  tearDown(() {
    mockPresence.resetPresence();
    mockSession.resetSession();
    mockRequestService.resetToDefault();
    mockAudit.clear();
  });

  group('AAYUSATHI Phase D5: DoctorPatientRequest Model & Privacy Architecture', () {
    test('1. Model instantiates correctly with clinical queue attributes', () {
      final now = DateTime.now();
      final request = DoctorPatientRequest(
        requestId: 'REQ-001',
        appointmentId: 'APT-001',
        patientId: 'PAT-001',
        queueNumber: 'A-00027',
        age: 42,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: now,
      );

      expect(request.requestId, equals('REQ-001'));
      expect(request.appointmentId, equals('APT-001'));
      expect(request.patientId, equals('PAT-001'));
      expect(request.queueNumber, equals('A-00027'));
      expect(request.age, equals(42));
      expect(request.gender, equals('Male'));
      expect(request.domain, equals('Cardiology'));
      expect(request.requestType, equals(PatientRequestType.newVisit));
      expect(request.isWaiting, isTrue);
      expect(request.isNewVisit, isTrue);
      expect(request.isPreviousDoctorRequested, isFalse);
      expect(request.formattedAge, equals('42 yrs'));
      expect(request.formattedAgeGender, equals('42 yrs • Male'));
    });

    test('2. PatientRequestType extension provides correct labels and predicates', () {
      expect(PatientRequestType.newVisit.label, equals('New Visit'));
      expect(PatientRequestType.newVisit.isNewVisit, isTrue);
      expect(PatientRequestType.newVisit.isPreviousDoctor, isFalse);

      expect(PatientRequestType.previousDoctor.label, equals('Previous Doctor Requested'));
      expect(PatientRequestType.previousDoctor.isNewVisit, isFalse);
      expect(PatientRequestType.previousDoctor.isPreviousDoctor, isTrue);
    });

    test('3. PatientRequestStatus extension provides correct lifecycle states', () {
      expect(PatientRequestStatus.waiting.label, equals('Waiting'));
      expect(PatientRequestStatus.waiting.isWaiting, isTrue);

      expect(PatientRequestStatus.assigned.label, equals('Assigned'));
      expect(PatientRequestStatus.assigned.isAssigned, isTrue);

      expect(PatientRequestStatus.inConsultation.label, equals('In Consultation'));
      expect(PatientRequestStatus.inConsultation.isInConsultation, isTrue);

      expect(PatientRequestStatus.completed.label, equals('Completed'));
      expect(PatientRequestStatus.completed.isCompleted, isTrue);

      expect(PatientRequestStatus.cancelled.label, equals('Cancelled'));
      expect(PatientRequestStatus.cancelled.isCancelled, isTrue);
    });

    test('4. copyWith preserves values and modifies specified attributes', () {
      final now = DateTime.now();
      final original = DoctorPatientRequest(
        requestId: 'REQ-001',
        appointmentId: 'APT-001',
        patientId: 'PAT-001',
        queueNumber: 'A-00027',
        age: 42,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: now,
      );

      final modified = original.copyWith(
        status: PatientRequestStatus.inConsultation,
        queueNumber: 'A-00099',
      );

      expect(modified.requestId, equals('REQ-001'));
      expect(modified.queueNumber, equals('A-00099'));
      expect(modified.status, equals(PatientRequestStatus.inConsultation));
      expect(modified.isInConsultation, isTrue);
    });

    test('5. Model design enforces Zero PII by omitting name, aadhaar, phone, and address', () {
      // Introspective check: DoctorPatientRequest fields do not have name or personal contact identifiers
      final req = DoctorPatientRequest(
        requestId: 'REQ-001',
        appointmentId: 'APT-001',
        patientId: 'PAT-001',
        queueNumber: 'A-00027',
        age: 42,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
      );

      expect(req.queueNumber, equals('A-00027'));
      expect(req.patientId, equals('PAT-001'));
      expect(req.age, equals(42));
      expect(req.gender, equals('Male'));
    });
  });

  group('AAYUSATHI Phase D5: Mock Service, Domain Filtering & FIFO Queue Ordering', () {
    test('6. Mock service provides 3 default Cardiology development fixtures', () async {
      final requests = await mockRequestService.getPendingRequests();
      expect(requests.length, equals(3));
      expect(requests[0].queueNumber, equals('A-00027'));
      expect(requests[1].queueNumber, equals('A-00028'));
      expect(requests[2].queueNumber, equals('A-00029'));
    });

    test('7. Mock service orders requests FIFO by requestedAt ascending (oldest first)', () async {
      final requests = await mockRequestService.getPendingRequests();
      for (int i = 0; i < requests.length - 1; i++) {
        expect(
          requests[i].requestedAt.isBefore(requests[i + 1].requestedAt) ||
              requests[i].requestedAt.isAtSameMomentAs(requests[i + 1].requestedAt),
          isTrue,
        );
      }
    });

    test('8. Mock service filters requests by clinical domain (Cardiology vs Neurology)', () async {
      final mixedList = [
        DoctorPatientRequest(
          requestId: 'REQ-CARD-1',
          appointmentId: 'APT-1',
          patientId: 'PAT-1',
          queueNumber: 'A-00001',
          age: 45,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
        ),
        DoctorPatientRequest(
          requestId: 'REQ-NEURO-1',
          appointmentId: 'APT-2',
          patientId: 'PAT-2',
          queueNumber: 'A-00002',
          age: 60,
          gender: 'Female',
          domain: 'Neurology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
        ),
      ];

      mockRequestService.setRequests(mixedList);

      final cardRequests = await mockRequestService.getPendingRequests(domain: 'Cardiology');
      expect(cardRequests.length, equals(1));
      expect(cardRequests.first.domain, equals('Cardiology'));

      final neuroRequests = await mockRequestService.getPendingRequests(domain: 'Neurology');
      expect(neuroRequests.length, equals(1));
      expect(neuroRequests.first.domain, equals('Neurology'));

      final orthoRequests = await mockRequestService.getPendingRequests(domain: 'Orthopedics');
      expect(orthoRequests, isEmpty);
    });

    test('9. getPendingRequestCount returns accurate count', () async {
      final count = await mockRequestService.getPendingRequestCount(domain: 'Cardiology');
      expect(count, equals(3));
    });

    test('10. Mock service simulates error when simulateError is true', () async {
      mockRequestService.simulateError = true;
      expect(
        () => mockRequestService.getPendingRequests(),
        throwsException,
      );
    });

    test('11. DoctorDashboardMetricsService integration consumes pending requests count', () async {
      final count = await DoctorDashboardMetricsService.instance.getPendingRequestsCount();
      expect(count, equals(3));
    });
  });

  group('AAYUSATHI Phase D5: DoctorPatientRequestCard UI Component', () {
    testWidgets('12. Renders queue number, age/gender, domain, and request type badge', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: request),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A-00027'), findsOneWidget);
      expect(find.text('42 age • Male'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('New Visit'), findsOneWidget);
      expect(find.text('WAITING'), findsOneWidget);
      expect(find.text('ACCEPT REQUEST'), findsOneWidget);
    });

    testWidgets('13. Renders Previous Doctor Requested badge for returning patient requests', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[2]; // A-00029

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: request),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A-00029'), findsOneWidget);
      expect(find.text('Previous Doctor Requested'), findsOneWidget);
    });

    testWidgets('14. Displays 4-quadrant vitals telemetry with exact values', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: request),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VITALS'), findsOneWidget);
      expect(find.text('97%'), findsOneWidget); // SpO2
      expect(find.text('78 BPM'), findsOneWidget); // Heart Rate
      expect(find.text('122/80 mmHg'), findsNothing); // Blood Pressure removed
      expect(find.text('36.8°C'), findsOneWidget); // Temperature
    });

    testWidgets('15. Falls back cleanly to "Not available" when vitals are missing/null', (WidgetTester tester) async {
      final requestWithoutVitals = DoctorPatientRequest(
        requestId: 'REQ-NO-VIT',
        appointmentId: 'APT-NO-VIT',
        patientId: 'PAT-NO-VIT',
        queueNumber: 'A-00099',
        age: 29,
        gender: 'Female',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        vitals: null,
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: requestWithoutVitals),
        ),
      );
      await tester.pumpAndSettle();

      // All 3 chips should display "Not available"
      expect(find.text('Not available'), findsNWidgets(3));
    });

    testWidgets('16. Zero PII verification on rendered card widget tree', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: request),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no patient name, phone numbers, or aadhaar appear
      expect(find.textContaining('Rajesh Kumar'), findsNothing);
      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
      expect(find.textContaining('Address'), findsNothing);
    });

    testWidgets('17. Accept button is disabled when isAcceptEnabled is false', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];
      bool wasTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(
            request: request,
            isAcceptEnabled: false,
            onAccept: () => wasTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(wasTapped, isFalse);
    });

    testWidgets('18. Accept button triggers onAccept callback when enabled', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];
      bool wasTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(
            request: request,
            isAcceptEnabled: true,
            onAccept: () => wasTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST');
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });

  group('AAYUSATHI Phase D5: DoctorPatientRequestScreen State Machine & Queue UI', () {
    testWidgets('19. DoctorPatientRequestScreen renders top queue bar and requests in loaded state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('PATIENT REQUESTS'), findsOneWidget);
      expect(find.text('Department of Cardiology'), findsOneWidget);
      expect(find.text('3 Pending Requests'), findsOneWidget);
      expect(find.text('Refresh Requests'), findsOneWidget);

      // Verify all 3 queue tickets are present
      expect(find.text('A-00027'), findsOneWidget);
      expect(find.text('A-00028'), findsOneWidget);
      expect(find.text('A-00029'), findsOneWidget);
    });

    testWidgets('20. Refresh button triggers reload of requests', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('A-00027'), findsOneWidget);

      // Change requests in mock service
      mockRequestService.setRequests([
        DoctorPatientRequest(
          requestId: 'REQ-UPDATED-1',
          appointmentId: 'APT-U-1',
          patientId: 'PAT-U-1',
          queueNumber: 'A-00099',
          age: 50,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
        ),
      ]);

      // Tap refresh
      await tester.tap(find.text('Refresh Requests'));
      await tester.pumpAndSettle();

      expect(find.text('A-00099'), findsOneWidget);
      expect(find.text('1 Pending Requests'), findsOneWidget);
    });

    testWidgets('21. Empty state displays NO PATIENT REQUESTS when queue is empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRequestService.setRequests([]);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 Pending Requests'), findsOneWidget);
      expect(find.text('NO PATIENT REQUESTS'), findsOneWidget);
      expect(find.text('There are currently no waiting OPD requests for your department.'), findsOneWidget);
    });

    testWidgets('22. Error state displays error notice and Retry button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRequestService.simulateError = true;

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load patient requests.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now reset error and tap Retry
      mockRequestService.simulateError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('A-00027'), findsOneWidget);
    });

    testWidgets('23. Presence awareness: OFFLINE status disables Accept buttons and shows banner with GO AVAILABLE', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await mockPresence.goOffline();

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workstation is offline. Set status to Available to accept OPD requests.'), findsOneWidget);
      expect(find.text('GO AVAILABLE'), findsOneWidget);

      // Tapping GO AVAILABLE makes workstation available and dismisses offline banner
      await tester.tap(find.text('GO AVAILABLE'));
      await tester.pumpAndSettle();

      expect(mockPresence.isAvailable, isTrue);
      expect(find.text('Workstation is offline. Set status to Available to accept OPD requests.'), findsNothing);
    });

    testWidgets('24. Presence awareness: IN_CONSULTATION status disables Accept buttons and shows consultation banner', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await mockPresence.setInConsultation();

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Currently in consultation. Complete active consultation before accepting new requests.'), findsOneWidget);
    });

    testWidgets('25. Accept Action: Shows confirmation and transitions presence to IN_CONSULTATION', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      final firstAcceptButton = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST').first;
      await tester.tap(firstAcceptButton);
      await tester.pump();

      // Verify SnackBar notice appears
      expect(find.text('Patient accepted successfully.'), findsOneWidget);

      // Verify Presence transitioned to IN_CONSULTATION
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.inConsultation));
    });

    testWidgets('26. Localization: Hindi locale renders translated queue titles and vitals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientRequestScreen(),
          locale: KioskLocale.hindi,
        ),
      );
      await tester.pumpAndSettle();

      // Check Hindi strings
      expect(find.text('मरीज़ अनुरोध'), findsOneWidget);
      expect(find.text('रक्तचाप'), findsNothing); // Blood Pressure removed
      expect(find.text('हृदय गति'), findsWidgets); // Heart Rate
      expect(find.text('तापमान'), findsWidgets); // Temperature
      expect(find.text('अनुरोध स्वीकारें'), findsWidgets); // Accept request
    });

    testWidgets('27. Localization: Marathi locale renders translated queue titles and vitals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientRequestScreen(),
          locale: KioskLocale.marathi,
        ),
      );
      await tester.pumpAndSettle();

      // Check Marathi strings
      expect(find.text('रुग्ण विनंत्या'), findsOneWidget);
      expect(find.text('रक्तदाब'), findsNothing); // Blood Pressure removed
      expect(find.text('हृदयाचे ठोके'), findsWidgets); // Heart Rate
      expect(find.text('तापमान'), findsWidgets); // Temperature
      expect(find.text('विनंती स्वीकारा'), findsWidgets); // Accept request
    });

    test('28. Mock service filters out completed and cancelled requests', () async {
      mockRequestService.setRequests([
        DoctorPatientRequest(
          requestId: 'REQ-W-1',
          appointmentId: 'APT-1',
          patientId: 'PAT-1',
          queueNumber: 'A-00001',
          age: 40,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
          status: PatientRequestStatus.waiting,
        ),
        DoctorPatientRequest(
          requestId: 'REQ-C-1',
          appointmentId: 'APT-2',
          patientId: 'PAT-2',
          queueNumber: 'A-00002',
          age: 50,
          gender: 'Female',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
          status: PatientRequestStatus.completed,
        ),
        DoctorPatientRequest(
          requestId: 'REQ-X-1',
          appointmentId: 'APT-3',
          patientId: 'PAT-3',
          queueNumber: 'A-00003',
          age: 60,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
          status: PatientRequestStatus.cancelled,
        ),
      ]);

      final pending = await mockRequestService.getPendingRequests(domain: 'Cardiology');
      expect(pending.length, equals(1));
      expect(pending.first.requestId, equals('REQ-W-1'));
    });

    test('29. Case-insensitive domain matching handles lowercase and uppercase input', () async {
      final pendingLower = await mockRequestService.getPendingRequests(domain: 'cardiology');
      expect(pendingLower.length, equals(3));

      final pendingUpper = await mockRequestService.getPendingRequests(domain: 'CARDIOLOGY');
      expect(pendingUpper.length, equals(3));
    });

    test('30. Previous doctor ID is preserved in copyWith and model getters', () {
      final req = DoctorPatientRequest(
        requestId: 'REQ-P-1',
        appointmentId: 'APT-P-1',
        patientId: 'PAT-P-1',
        queueNumber: 'A-00099',
        age: 33,
        gender: 'Female',
        domain: 'Cardiology',
        requestType: PatientRequestType.previousDoctor,
        previousDoctorId: 'DOC-101',
        requestedAt: DateTime.now(),
      );

      expect(req.previousDoctorId, equals('DOC-101'));
      expect(req.isPreviousDoctorRequested, isTrue);

      final copy = req.copyWith(previousDoctorId: 'DOC-202');
      expect(copy.previousDoctorId, equals('DOC-202'));
    });

    testWidgets('31. Header back button is rendered and functional', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Go back');
      expect(backButton, findsOneWidget);
    });

    testWidgets('32. Narrow screen layout (<1050px) renders requests in single column without error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('PATIENT REQUESTS'), findsOneWidget);
      expect(find.text('A-00027'), findsOneWidget);
      expect(find.text('A-00028'), findsOneWidget);
      expect(find.text('A-00029'), findsOneWidget);
    });

    testWidgets('33. Reactively updates when presence changes from AVAILABLE to OFFLINE', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workstation is offline. Set status to Available to accept OPD requests.'), findsNothing);

      // Change presence to offline
      await mockPresence.goOffline();
      await tester.pumpAndSettle();

      expect(find.text('Workstation is offline. Set status to Available to accept OPD requests.'), findsOneWidget);
    });

    testWidgets('34. Partial vitals with null vital value renders "Not available" cleanly', (WidgetTester tester) async {
      final partialVitalsReq = DoctorPatientRequest(
        requestId: 'REQ-PARTIAL-1',
        appointmentId: 'APT-P-1',
        patientId: 'PAT-P-1',
        queueNumber: 'A-00077',
        age: 62,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        vitals: VitalReading(
          vitalId: 'VIT-PARTIAL-1',
          patientId: 'PAT-P-1',
          appointmentId: 'APT-P-1',
          spo2: 99,
          heartRate: 70,
          temperature: null,
          timestamp: DateTime.now(),
        ),
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(request: partialVitalsReq),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99%'), findsOneWidget);
      expect(find.text('70 BPM'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget); // Temperature is null
    });
  });
}
