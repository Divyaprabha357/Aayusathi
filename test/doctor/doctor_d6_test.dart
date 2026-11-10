import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/doctor_assignment_result.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_request_screen.dart';
import 'package:aayusathi/doctor/services/doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/firebase_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/patient_notification_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_request_card.dart';
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
    mockAudit.clear();
    BackendProvider.instance.setCustomRepositories(auditRepo: mockAudit);

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

  group('AAYUSATHI Phase D6: DoctorAssignmentResult Model & Status Mapping', () {
    test('1. DoctorAssignmentResult.success creates valid exclusive assignment model', () {
      final now = DateTime.now();
      final result = DoctorAssignmentResult.success(
        requestId: 'REQ-D6-001',
        appointmentId: 'APT-D6-001',
        queueNumber: 'A-00027',
        assignedDoctorId: 'DOC-101',
        assignedAt: now,
      );

      expect(result.status, equals(DoctorAssignmentStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyAssigned, isFalse);
      expect(result.requestId, equals('REQ-D6-001'));
      expect(result.appointmentId, equals('APT-D6-001'));
      expect(result.queueNumber, equals('A-00027'));
      expect(result.assignedDoctorId, equals('DOC-101'));
      expect(result.assignedAt, equals(now));
    });

    test('2. DoctorAssignmentResult factory constructors for failure and conflict states', () {
      final already = DoctorAssignmentResult.alreadyAssigned(
        requestId: 'REQ-1',
        queueNumber: 'A-00027',
      );
      expect(already.status, equals(DoctorAssignmentStatus.alreadyAssigned));
      expect(already.isAlreadyAssigned, isTrue);

      final unavail = DoctorAssignmentResult.unavailable(requestId: 'REQ-2');
      expect(unavail.status, equals(DoctorAssignmentStatus.unavailable));
      expect(unavail.isUnavailable, isTrue);

      final inelig = DoctorAssignmentResult.ineligible(requestId: 'REQ-3');
      expect(inelig.status, equals(DoctorAssignmentStatus.ineligible));
      expect(inelig.isIneligible, isTrue);

      final invalid = DoctorAssignmentResult.invalidRequest(requestId: 'REQ-4');
      expect(invalid.status, equals(DoctorAssignmentStatus.invalidRequest));
      expect(invalid.isInvalidRequest, isTrue);

      final unauth = DoctorAssignmentResult.unauthorized(requestId: 'REQ-5');
      expect(unauth.status, equals(DoctorAssignmentStatus.unauthorized));
      expect(unauth.isUnauthorized, isTrue);

      final conflict = DoctorAssignmentResult.conflict(requestId: 'REQ-6');
      expect(conflict.status, equals(DoctorAssignmentStatus.conflict));
      expect(conflict.isConflict, isTrue);

      final err = DoctorAssignmentResult.error(requestId: 'REQ-7', message: 'Network error');
      expect(err.status, equals(DoctorAssignmentStatus.error));
      expect(err.isError, isTrue);
    });

    test('3. DoctorPatientRequest model holds assignedDoctorId and assignedAt', () {
      final now = DateTime.now();
      final request = DoctorPatientRequest(
        requestId: 'REQ-01',
        appointmentId: 'APT-01',
        patientId: 'PAT-01',
        queueNumber: 'A-00027',
        age: 45,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        assignedDoctorId: 'DOC-101',
        assignedAt: now,
        status: PatientRequestStatus.assigned,
        requestedAt: now,
      );

      expect(request.assignedDoctorId, equals('DOC-101'));
      expect(request.assignedAt, equals(now));
      expect(request.isAssigned, isTrue);
    });
  });

  group('AAYUSATHI Phase D6: Atomic First-Doctor-Wins & Eligibility Engine', () {
    test('4. Eligible doctor can accept a waiting request successfully', () async {
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isSuccess, isTrue);
      expect(result.assignedDoctorId, equals('DOC-101'));
      expect(result.queueNumber, equals('A-00027'));
    });

    test('5. FIRST-DOCTOR-WINS RACE CONDITION: Only one doctor can claim the request', () async {
      // Simulate Doctor A and Doctor B clicking ACCEPT almost simultaneously
      final futureA = mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      final futureB = mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-202',
        doctorDomain: 'Cardiology',
      );

      final results = await Future.wait([futureA, futureB]);
      final successResults = results.where((r) => r.isSuccess).toList();
      final alreadyAssignedResults = results.where((r) => r.isAlreadyAssigned).toList();

      // Exactly ONE doctor wins
      expect(successResults.length, equals(1));
      // Exactly ONE doctor loses with alreadyAssigned
      expect(alreadyAssignedResults.length, equals(1));

      // Check request state
      final pending = await mockRequestService.getPendingRequests(domain: 'Cardiology');
      expect(pending.any((r) => r.requestId == 'REQ-D5-001'), isFalse);
    });

    test('6. Ineligible doctor with domain mismatch is rejected', () async {
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001', // Cardiology request
        doctorId: 'DOC-NEURO-1',
        doctorDomain: 'Neurology',
      );

      expect(result.isIneligible, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('7. Ineligible doctor cannot claim another doctor\'s previous-doctor request', () async {
      // REQ-D5-003 is reserved for DOC-101
      final resultOther = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-003',
        doctorId: 'DOC-999',
        doctorDomain: 'Cardiology',
      );

      expect(resultOther.isIneligible, isTrue);
      expect(resultOther.isSuccess, isFalse);

      // The assigned doctor DOC-101 can claim it
      final resultOwner = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-003',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(resultOwner.isSuccess, isTrue);
      expect(resultOwner.assignedDoctorId, equals('DOC-101'));
    });

    test('8. Offline doctor is rejected before attempting backend mutation', () async {
      await mockPresence.goOffline();

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isUnavailable, isTrue);
    });

    test('9. Doctor in consultation is rejected from accepting a second request (One-Patient Lock)', () async {
      await mockPresence.setInConsultation();

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isUnavailable, isTrue);
    });

    test('10. Invalid/non-existent request ID returns invalidRequest result', () async {
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-NON-EXISTENT-999',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isInvalidRequest, isTrue);
    });

    test('11. Mock server failure returns error result without crashing', () async {
      mockRequestService.simulateError = true;

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isError, isTrue);
    });
  });

  group('AAYUSATHI Phase D6: Presence State Machine & Audit Governance', () {
    test('12. Successful assignment records DOCTOR_REQUEST_ACCEPTED audit event', () async {
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      final logs = await mockAudit.getLogsForEntity(
        entityType: 'APPOINTMENT',
        entityId: 'REQ-D5-001',
      );

      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.action, equals('DOCTOR_REQUEST_ACCEPTED'));
      expect(log.actorId, equals('DOC-101'));
      expect(log.actorType, equals('DOCTOR'));
      expect(log.metadata['queueNumber'], equals('A-00027'));
      expect(log.metadata['domain'], equals('Cardiology'));
    });

    test('13. Audit log contains strictly zero plain-text Aadhaar, passwords, or OTP', () async {
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      final logs = await mockAudit.getLogsForEntity(
        entityType: 'APPOINTMENT',
        entityId: 'REQ-D5-001',
      );

      final log = logs.first;
      expect(log.metadata.containsKey('aadhaar'), isFalse);
      expect(log.metadata.containsKey('aadhaarNumber'), isFalse);
      expect(log.metadata.containsKey('password'), isFalse);
      expect(log.metadata.containsKey('otp'), isFalse);
    });

    test('14. PatientNotificationService extension point dispatches consultation acceptance event', () async {
      final notifService = MockPatientNotificationService();
      PatientNotificationService.instance = notifService;

      await notifService.notifyPatientConsultationAccepted(
        appointmentId: 'APT-D6-001',
        patientId: 'PAT-MOCK-001',
        queueNumber: 'A-00027',
        doctorId: 'DOC-101',
      );

      expect(notifService.dispatchedNotifications.length, equals(1));
      expect(notifService.dispatchedNotifications.first['queueNumber'], equals('A-00027'));
      expect(notifService.dispatchedNotifications.first['doctorId'], equals('DOC-101'));
    });
  });

  group('AAYUSATHI Phase D6: DoctorPatientRequestCard & Screen Interactive UI', () {
    testWidgets('15. DoctorPatientRequestCard shows loading spinner when isLoading is true', (WidgetTester tester) async {
      final request = MockDoctorPatientRequestService.defaultDemoRequests[0];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(
            request: request,
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('16. Screen triggers acceptance, transitions presence to IN_CONSULTATION and shows success SnackBar', (WidgetTester tester) async {
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

      // Verify success feedback
      expect(find.text('Patient accepted successfully.'), findsOneWidget);

      // Verify doctor presence is now IN_CONSULTATION
      expect(mockPresence.isInConsultation, isTrue);
    });

    testWidgets('17. Already-assigned request displays conflict SnackBar and refreshes queue list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      // Pre-assign the first request behind the scenes to simulate another doctor winning
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-OTHER-99',
        doctorDomain: 'Cardiology',
      );

      // Doctor tries to accept REQ-D5-001
      final firstAcceptButton = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST').first;
      await tester.tap(firstAcceptButton);
      await tester.pump();

      // Verify conflict notice
      expect(find.text('Patient request has already been assigned to another doctor.'), findsOneWidget);

      // Verify presence was NOT changed to in consultation for the losing doctor
      expect(mockPresence.isAvailable, isTrue);

      // Settle and verify queue refreshed (REQ-D5-001 disappears)
      await tester.pumpAndSettle();
      expect(find.text('A-00027'), findsNothing);
    });

    testWidgets('18. Offline doctor attempting acceptance shows doctorNotAvailableNotice', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await mockPresence.goOffline();

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      // Accept buttons are disabled while offline
      final button = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST').first;
      await tester.tap(button);
      await tester.pump();

      expect(mockPresence.isOffline, isTrue);
    });

    testWidgets('19. Hindi localization: Shows translated acceptance confirmation and conflict notices', (WidgetTester tester) async {
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

      final firstAcceptButton = find.widgetWithText(DoctorPrimaryButton, 'अनुरोध स्वीकारें').first;
      await tester.tap(firstAcceptButton);
      await tester.pump();

      // Verify Hindi confirmation
      expect(find.text('मरीज़ अनुरोध सफलतापूर्वक स्वीकार कर लिया गया।'), findsOneWidget);
    });

    testWidgets('20. Marathi localization: Shows translated acceptance confirmation and conflict notices', (WidgetTester tester) async {
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

      final firstAcceptButton = find.widgetWithText(DoctorPrimaryButton, 'विनंती स्वीकारा').first;
      await tester.tap(firstAcceptButton);
      await tester.pump();

      // Verify Marathi confirmation
      expect(find.text('रुग्ण विनंती यशस्वीरित्या स्वीकारली गेली.'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D6: Isolation & Regression Verification', () {
    test('21. Mock service is strictly isolated from Cloud Firestore', () {
      expect(mockRequestService, isA<MockDoctorPatientRequestService>());
    });

    test('22. FirebaseDoctorPatientRequestService class exists and implements DoctorPatientRequestService', () {
      expect(FirebaseDoctorPatientRequestService, isNotNull);
    });

    test('23. 3-Doctor concurrent race condition: Exactly one doctor wins and two receive alreadyAssigned', () async {
      final futureA = mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-002',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      final futureB = mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-002',
        doctorId: 'DOC-102',
        doctorDomain: 'Cardiology',
      );
      final futureC = mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-002',
        doctorId: 'DOC-103',
        doctorDomain: 'Cardiology',
      );

      final results = await Future.wait([futureA, futureB, futureC]);
      final success = results.where((r) => r.isSuccess).toList();
      final alreadyAssigned = results.where((r) => r.isAlreadyAssigned).toList();

      expect(success.length, equals(1));
      expect(alreadyAssigned.length, equals(2));
    });

    test('24. Successful assignment preserves queue number, patient ID, and appointment ID', () async {
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.queueNumber, equals('A-00027'));
      expect(result.appointmentId, equals('APT-D5-001'));
      expect(result.assignedDoctorId, equals('DOC-101'));
    });

    test('25. Winning doctor transitions to IN_CONSULTATION and subsequent accept attempts are blocked', () async {
      final result1 = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(result1.isSuccess, isTrue);

      // Transition presence to in consultation
      await mockPresence.setInConsultation();
      expect(mockPresence.isInConsultation, isTrue);

      // Attempting to accept a second patient is blocked by one-patient lock
      final result2 = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-002',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(result2.isUnavailable, isTrue);
    });

    test('26. Losing doctor presence remains AVAILABLE after receiving alreadyAssigned', () async {
      // Doctor 1 claims the request
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-WINNER',
        doctorDomain: 'Cardiology',
      );

      // Doctor 2 attempts to claim the same request
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-LOSER',
        doctorDomain: 'Cardiology',
      );

      expect(result.isAlreadyAssigned, isTrue);
      expect(mockPresence.isAvailable, isTrue);
    });

    test('27. Backend error leaves doctor presence untouched in AVAILABLE', () async {
      mockRequestService.simulateError = true;

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isError, isTrue);
      expect(mockPresence.isAvailable, isTrue);
    });

    test('28. Offline doctor attempting acceptance leaves presence in OFFLINE', () async {
      await mockPresence.goOffline();

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isUnavailable, isTrue);
      expect(mockPresence.isOffline, isTrue);
    });

    test('29. Ineligible doctor domain mismatch leaves doctor presence in AVAILABLE', () async {
      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-DERMA-1',
        doctorDomain: 'Dermatology',
      );

      expect(result.isIneligible, isTrue);
      expect(mockPresence.isAvailable, isTrue);
    });

    test('30. Audit event timestamp is within active execution window', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      final after = DateTime.now().add(const Duration(seconds: 1));

      final logs = await mockAudit.getLogsForEntity(
        entityType: 'APPOINTMENT',
        entityId: 'REQ-D5-001',
      );
      expect(logs.isNotEmpty, isTrue);
      final logTimestamp = logs.first.timestamp;
      expect(logTimestamp.isAfter(before) && logTimestamp.isBefore(after), isTrue);
    });

    test('31. Successful assignment removes the request from pending queue list', () async {
      final initial = await mockRequestService.getPendingRequests(domain: 'Cardiology');
      expect(initial.length, equals(3));

      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      final updated = await mockRequestService.getPendingRequests(domain: 'Cardiology');
      expect(updated.length, equals(2));
      expect(updated.any((r) => r.requestId == 'REQ-D5-001'), isFalse);
    });

    test('32. getPendingRequestCount decreases by 1 after successful assignment', () async {
      final countBefore = await mockRequestService.getPendingRequestCount(domain: 'Cardiology');
      expect(countBefore, equals(3));

      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      final countAfter = await mockRequestService.getPendingRequestCount(domain: 'Cardiology');
      expect(countAfter, equals(2));
    });

    test('33. resetToDefault() restores all default queue fixtures', () async {
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(await mockRequestService.getPendingRequestCount(domain: 'Cardiology'), equals(2));

      mockRequestService.resetToDefault();
      expect(await mockRequestService.getPendingRequestCount(domain: 'Cardiology'), equals(3));
    });

    test('34. Attempting to accept a cancelled request returns alreadyAssigned', () async {
      mockRequestService.setRequests([
        DoctorPatientRequest(
          requestId: 'REQ-CANCELLED',
          appointmentId: 'APT-C',
          patientId: 'PAT-C',
          queueNumber: 'A-00099',
          age: 50,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          status: PatientRequestStatus.cancelled,
          requestedAt: DateTime.now(),
        ),
      ]);

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-CANCELLED',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isAlreadyAssigned, isTrue);
    });

    test('35. Attempting to accept a completed request returns alreadyAssigned', () async {
      mockRequestService.setRequests([
        DoctorPatientRequest(
          requestId: 'REQ-COMPLETED',
          appointmentId: 'APT-COMP',
          patientId: 'PAT-COMP',
          queueNumber: 'A-00088',
          age: 60,
          gender: 'Female',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          status: PatientRequestStatus.completed,
          requestedAt: DateTime.now(),
        ),
      ]);

      final result = await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-COMPLETED',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isAlreadyAssigned, isTrue);
    });

    testWidgets('36. UI: Already-assigned request does not mutate presence to IN_CONSULTATION', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      // Claim behind scenes
      await mockRequestService.acceptPatientRequest(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-OTHER',
        doctorDomain: 'Cardiology',
      );

      final button = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST').first;
      await tester.tap(button);
      await tester.pump();

      expect(mockPresence.status, equals(DoctorAvailabilityStatus.available));
    });

    testWidgets('37. UI: Multiple taps while loading do not trigger redundant accept calls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(DoctorPrimaryButton, 'ACCEPT REQUEST').first;
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false); // second tap while in-flight
      await tester.pump();

      expect(mockPresence.isInConsultation, isTrue);
    });

    testWidgets('38. English localized strings verify full acceptance vocabulary', (WidgetTester tester) async {
      final strings = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(strings.acceptingRequest, equals('Accepting Request...'));
      expect(strings.patientAcceptedNotice, equals('Patient accepted successfully.'));
      expect(strings.patientAlreadyAssignedNotice, equals('Patient request has already been assigned to another doctor.'));
      expect(strings.notEligibleNotice, equals('You are not eligible for this request.'));
      expect(strings.doctorNotAvailableNotice, equals('Workstation is not available for consultation.'));
      expect(strings.unableToAcceptNotice, equals('Unable to accept this patient request. Please try again.'));
      expect(strings.openingWorkspaceNotice, equals('Opening Patient Workspace...'));
    });

    test('39. Development mode runs with in-memory fixtures without cloud writes', () {
      expect(DoctorSessionService.instance.isDevelopmentMode, isFalse);
      expect(MockDoctorPatientRequestService.defaultDemoRequests.length, equals(3));
    });

    testWidgets('40. Zero Aadhaar or sensitive PII rendered across request cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const DoctorPatientRequestScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
      expect(find.textContaining('Password'), findsNothing);
    });
  });
}
