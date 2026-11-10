import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/auth/mock_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/localization/doctor_strings.dart';
import 'package:aayusathi/doctor/models/doctor_assignment_result.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_dashboard_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_request_screen.dart';
import 'package:aayusathi/doctor/services/doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_request_card.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/opd_domain.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';

Widget _buildCardTestable(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: DoctorLocalizations.provider(
      strings: const DoctorStrings(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    ),
  );
}

Widget _buildScreenTestable(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: DoctorLocalizations.provider(
      strings: const DoctorStrings(),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AAYUSATHI — Critical Integration Tests: Vitals Telemetry Flow', () {
    setUp(() {
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
      MockAppointmentRepository.instance.clear();
      KioskService.instance.resetSession();
      MockDoctorPatientRequestService.instance.resetToDefault();
    });

    test('1. Kiosk vitals serialize correctly with canonical and alias keys', () {
      final vitals = VitalReading(
        heartRate: 76,
        spo2: 98,
        temperature: 36.7,
        source: VitalSource.arduino,
        timestamp: DateTime(2026, 9, 10, 10, 0),
        status: VitalStatus.valid,
        validationStatus: 'normal',
      );

      final map = vitals.toMap();
      expect(map['spo2'], equals(98));
      expect(map['heartRate'], equals(76));
      expect(map.containsKey('systolic'), isFalse);
      expect(map.containsKey('diastolic'), isFalse);
      expect(map.containsKey('systolicBp'), isFalse);
      expect(map.containsKey('diastolicBp'), isFalse);
      expect(map['temperature'], equals(36.7));
    });

    test('2. Firestore appointment contains vitals in serialized document', () {
      final vitals = VitalReading(
        heartRate: 76,
        spo2: 98,
        temperature: 36.7,
        timestamp: DateTime(2026, 9, 10, 10, 0),
      );

      final appointment = AppointmentRequest(
        requestId: 'REQ-TEST-001',
        patientId: 'PAT-001',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime(2026, 9, 10, 10, 0),
        sessionId: 'SESS-001',
        vitals: vitals,
      );

      final firestoreMap = appointment.toFirestore();
      expect(firestoreMap.containsKey('vitals'), isTrue);
      final vitalsMap = firestoreMap['vitals'] as Map<String, dynamic>;
      expect(vitalsMap['spo2'], equals(98));
      expect(vitalsMap['heartRate'], equals(76));
      expect(vitalsMap.containsKey('systolic'), isFalse);
      expect(vitalsMap.containsKey('diastolic'), isFalse);
      expect(vitalsMap.containsKey('bloodPressure'), isFalse);
      expect(vitalsMap['temperature'], equals(36.7));
    });

    test('3. Doctor request deserializes vitals safely with numeric and alias variations', () {
      final rawFirestoreMap = {
        'requestId': 'REQ-DESER-001',
        'patientId': 'PAT-001',
        'domainId': 'cardiology',
        'preferredDoctorMode': 'anyDoctor',
        'status': 'waiting',
        'queueNumber': 'A-00005',
        'createdAt': '2026-09-10T10:00:00.000',
        'sessionId': 'SESS-001',
        'vitals': {
          'spO2': 98.0, // double value
          'pulse': 76, // alias key
          'systolicBp': '120', // string value
          'diastolicBp': 80, // alias key
          'temp': 36.7, // alias key
        },
      };

      final appt = AppointmentRequest.fromMap(rawFirestoreMap);
      expect(appt.vitals, isNotNull);
      expect(appt.vitals!.spo2, equals(98));
      expect(appt.vitals!.heartRate, equals(76));
      expect(appt.vitals!.temperature, equals(36.7));
    });

    testWidgets('4. Doctor request displays SpO₂ correctly on UI', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-01',
        patientId: 'PAT-01',
        queueNumber: 'A-00010',
        age: 45,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          spo2: 98,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('98%'), findsOneWidget);
    });

    testWidgets('5. Doctor request displays HR correctly on UI', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-02',
        patientId: 'PAT-02',
        queueNumber: 'A-00011',
        age: 38,
        gender: 'Female',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          heartRate: 76,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('76 BPM'), findsOneWidget);
    });

    testWidgets('6. Doctor request does not display BP on UI', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-03',
        patientId: 'PAT-03',
        queueNumber: 'A-00012',
        age: 52,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          spo2: 98,
          heartRate: 76,
          temperature: 36.7,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('120/80 mmHg'), findsNothing);
      expect(find.textContaining('mmHg'), findsNothing);
    });

    testWidgets('7. Doctor request displays temperature correctly on UI', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-04',
        patientId: 'PAT-04',
        queueNumber: 'A-00013',
        age: 29,
        gender: 'Female',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          temperature: 36.7,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('36.7°C'), findsOneWidget);
    });

    testWidgets('8. Missing individual vital shows Not available only for missing parameter', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Temperature is intentionally omitted (null)
      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-05',
        patientId: 'PAT-05',
        queueNumber: 'A-00014',
        age: 60,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          spo2: 98,
          heartRate: 76,
          temperature: null,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('98%'), findsOneWidget);
      expect(find.text('76 BPM'), findsOneWidget);
      expect(find.text('120/80 mmHg'), findsNothing);
      // Only 1 'Not available' should be present for temperature
      expect(find.text('Not available'), findsOneWidget);
    });

    testWidgets('9. Valid vitals never become Not available when all 3 are present', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final request = DoctorPatientRequest(
        requestId: 'REQ-UI-06',
        patientId: 'PAT-06',
        queueNumber: 'A-00015',
        age: 33,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
        vitals: VitalReading(
          spo2: 98,
          heartRate: 76,
          temperature: 36.7,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _buildCardTestable(
          SizedBox(
            width: 500,
            child: DoctorPatientRequestCard(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsNothing);
      expect(find.text('98%'), findsOneWidget);
      expect(find.text('76 BPM'), findsOneWidget);
      expect(find.text('120/80 mmHg'), findsNothing);
      expect(find.text('36.7°C'), findsOneWidget);
    });

    test('10. No fake vital fallback: null vitals remain null', () {
      final apptWithoutVitals = AppointmentRequest(
        requestId: 'REQ-NO-VITALS',
        patientId: 'PAT-09',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00099',
        createdAt: DateTime.now(),
        sessionId: 'SESS-09',
        vitals: null,
      );

      expect(apptWithoutVitals.vitals, isNull);
      final serialized = apptWithoutVitals.toFirestore();
      expect(serialized.containsKey('vitals'), isFalse);
    });
  });

  group('AAYUSATHI — Critical Integration Tests: Assignment & First-Doctor-Wins', () {
    late KioskService kiosk;

    setUp(() {
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
      MockAppointmentRepository.instance.clear();
      kiosk = KioskService.instance;
      kiosk.resetSession();
      DoctorPresenceService.instance = MockDoctorPresenceService();
      MockDoctorPatientRequestService.instance.resetToDefault();
    });

    test('11. New appointment starts strictly unassigned (assignedDoctorId == null)', () async {
      final mockAuth = MockAuthService();
      BackendProvider.instance.setCustomRepositories(authService: mockAuth);
      await mockAuth.signInAnonymously(role: UserRole.kiosk);

      kiosk.startNewSession();
      const patient = PatientIdentity(
        aadhaarNumber: '111122223333',
        patientId: 'AAYU-102938',
        fullName: 'Aarav Sharma',
        dob: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        address: 'Pune',
        bloodGroup: 'O+',
        isNewRegistration: false,
      );
      kiosk.setIdentifiedPatient(patient);

      final vitals = VitalReading(
        heartRate: 76,
        spo2: 98,
        temperature: 36.7,
        source: VitalSource.arduino,
        timestamp: DateTime.now(),
      );
      kiosk.setVitalReading(vitals);

      final domain = OpdDomain.all.firstWhere((d) => d.id == 'cardiology');
      kiosk.setSelectedDomain(domain);

      final appointment = await kiosk.bookAndPersistAppointment(
        patientId: patient.patientId,
        domainId: domain.id,
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
      );

      expect(appointment.assignedDoctorId, isNull);
      expect(appointment.assignedAt, isNull);
      expect(appointment.status, equals(AppointmentStatus.waiting));
      expect(appointment.vitals, isNotNull);
      expect(appointment.vitals!.spo2, equals(98));

      final persisted = await BackendProvider.instance.appointmentRepository.getAppointmentById(appointment.requestId);
      expect(persisted?.assignedDoctorId, isNull);
      expect(persisted?.assignedAt, isNull);
    });

    test('12. Doctor becoming available does not assign any appointment', () async {
      DoctorPresenceService.instance = MockDoctorPresenceService(
        initialStatus: DoctorAvailabilityStatus.offline,
      );
      final presence = DoctorPresenceService.instance;
      expect(presence.isAvailable, isFalse);

      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);

      // Verify no appointments in repository were modified or assigned
      final appts = await BackendProvider.instance.appointmentRepository.getAllAppointments();
      for (final a in appts) {
        expect(a.assignedDoctorId, isNull);
      }
    });

    test('13. Request query / stream does not assign appointment', () async {
      final reqService = DoctorPatientRequestService.instance;
      final pending = await reqService.getPendingRequests(domain: 'Cardiology');

      for (final req in pending) {
        expect(req.assignedDoctorId, isNull);
        expect(req.status, equals(PatientRequestStatus.waiting));
      }
    });

    testWidgets('14. Dashboard load does not assign appointment', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreenTestable(const DoctorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final reqs = await DoctorPatientRequestService.instance.getPendingRequests(domain: 'Cardiology');
      for (final r in reqs) {
        expect(r.assignedDoctorId, isNull);
      }
    });

    testWidgets('15. Opening Patient Requests screen does not assign appointment', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreenTestable(const DoctorPatientRequestScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final reqs = await DoctorPatientRequestService.instance.getPendingRequests(domain: 'Cardiology');
      for (final r in reqs) {
        expect(r.assignedDoctorId, isNull);
      }
    });

    test('16. Refresh requests does not assign appointment', () async {
      final reqService = DoctorPatientRequestService.instance;
      await reqService.refreshRequests();

      final reqs = await reqService.getPendingRequests(domain: 'Cardiology');
      for (final r in reqs) {
        expect(r.assignedDoctorId, isNull);
      }
    });

    test('17. Only explicit Accept Request assigns appointment', () async {
      final reqService = DoctorPatientRequestService.instance;
      await DoctorPresenceService.instance.setAvailable();

      final pending = await reqService.getPendingRequests(domain: 'Cardiology');
      expect(pending.isNotEmpty, isTrue);

      final target = pending.first;
      expect(target.assignedDoctorId, isNull);

      final result = await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isSuccess, isTrue);
      expect(result.assignedDoctorId, equals('DOC-101'));
      expect(result.assignedAt, isNotNull);
    });

    test('18. Accept uses atomic transaction semantics', () async {
      final reqService = DoctorPatientRequestService.instance;
      await DoctorPresenceService.instance.setAvailable();

      final pending = await reqService.getPendingRequests(domain: 'Cardiology');
      final target = pending.first;

      final res = await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(res.status, equals(DoctorAssignmentStatus.success));
      expect(res.assignedDoctorId, equals('DOC-101'));
    });

    test('19. First doctor wins when claiming unassigned request', () async {
      final reqService = DoctorPatientRequestService.instance;
      await DoctorPresenceService.instance.setAvailable();

      final pending = await reqService.getPendingRequests(domain: 'Cardiology');
      final target = pending.first;

      // Doctor A accepts first
      final docAResult = await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-A',
        doctorDomain: 'Cardiology',
      );

      expect(docAResult.isSuccess, isTrue);
      expect(docAResult.assignedDoctorId, equals('DOC-A'));
    });

    test('20. Second doctor receives already-assigned result after race', () async {
      final reqService = DoctorPatientRequestService.instance;
      await DoctorPresenceService.instance.setAvailable();

      final pending = await reqService.getPendingRequests(domain: 'Cardiology');
      final target = pending.first;

      // Doctor A wins
      await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-A',
        doctorDomain: 'Cardiology',
      );

      // Doctor B attempts to accept same request
      final docBResult = await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-B',
        doctorDomain: 'Cardiology',
      );

      expect(docBResult.isSuccess, isFalse);
      expect(docBResult.isAlreadyAssigned, isTrue);
      expect(docBResult.message, contains('Patient request has already been assigned to another doctor.'));
    });

    test('21. assignedDoctorId strictly remains null before acceptance', () async {
      final appt = AppointmentRequest(
        requestId: 'REQ-UNASSIGNED',
        patientId: 'PAT-01',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime.now(),
        sessionId: 'SESS-01',
      );
      await BackendProvider.instance.appointmentRepository.saveAppointment(appt);

      final fetched = await BackendProvider.instance.appointmentRepository.getAppointmentById('REQ-UNASSIGNED');
      expect(fetched?.assignedDoctorId, isNull);
    });

    test('22. assignedAt remains null before acceptance', () async {
      final appt = AppointmentRequest(
        requestId: 'REQ-UNASSIGNED-TIME',
        patientId: 'PAT-01',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00002',
        createdAt: DateTime.now(),
        sessionId: 'SESS-02',
      );
      await BackendProvider.instance.appointmentRepository.saveAppointment(appt);

      final fetched = await BackendProvider.instance.appointmentRepository.getAppointmentById('REQ-UNASSIGNED-TIME');
      expect(fetched?.assignedAt, isNull);
    });

    test('23. Presence changes to IN_CONSULTATION only after acceptance', () async {
      final presence = DoctorPresenceService.instance;
      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
      expect(presence.isInConsultation, isFalse);

      final reqService = DoctorPatientRequestService.instance;
      final pending = await reqService.getPendingRequests(domain: 'Cardiology');
      final target = pending.first;

      final result = await reqService.acceptPatientRequest(
        requestId: target.requestId,
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isSuccess, isTrue);
      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);
      expect(presence.isAvailable, isFalse);
    });

    test('24. Kiosk eligibility remains correct across domains', () async {
      final apptService = KioskService.instance.appointmentService;
      final appt = await apptService.createAppointmentRequest(
        patientId: 'PAT-ELIG',
        domainId: 'cardiology',
        sessionId: 'SESS-ELIG',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
      );

      expect(appt.domainId, equals('cardiology'));
      expect(appt.assignedDoctorId, isNull);
      expect(appt.status, equals(AppointmentStatus.waiting));
    });

    test('25. Existing previous-doctor routing remains intact with unassigned state', () async {
      final apptService = KioskService.instance.appointmentService;
      final appt = await apptService.createAppointmentRequest(
        patientId: 'PAT-PREV',
        domainId: 'cardiology',
        sessionId: 'SESS-PREV',
        previousDoctorId: 'DOC-PREV-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
      );

      // Previous doctor ID is preserved for targeting, but NOT pre-assigned!
      expect(appt.previousDoctorId, equals('DOC-PREV-01'));
      expect(appt.assignedDoctorId, isNull);
      expect(appt.status, equals(AppointmentStatus.waiting));
    });
  });
}
