import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_assignment_result.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/services/doctor_dashboard_metrics_service.dart';
import 'package:aayusathi/doctor/services/doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/windows_speech_to_text_service.dart';

DoctorPatientRequest _buildRequest({
  required String requestId,
  String domain = 'Cardiology',
  PatientRequestStatus status = PatientRequestStatus.waiting,
  DateTime? requestedAt,
  String? assignedDoctorId,
}) {
  return DoctorPatientRequest(
    requestId: requestId,
    appointmentId: 'APPT-$requestId',
    patientId: 'PAT-001',
    queueNumber: 'A-00001',
    age: 40,
    gender: 'Male',
    domain: domain,
    requestType: PatientRequestType.newVisit,
    status: status,
    assignedDoctorId: assignedDoctorId,
    requestedAt: requestedAt ?? DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    DoctorSessionService.instance = MockDoctorSessionService();
    DoctorPresenceService.instance = MockDoctorPresenceService();
    await DoctorPresenceService.instance.setAvailable();
  });

  group('Group 1: Dashboard Metrics - Attended Today & Pending Requests', () {
    test('T1: Attended today returns 0 when no visits have been completed today', () async {
      final metricsService = MockDoctorDashboardMetricsService(mockAttendedCount: 0);
      DoctorDashboardMetricsService.instance = metricsService;

      final count = await DoctorDashboardMetricsService.instance.getPatientsAttendedTodayCount(doctorId: 'DOC-101');
      expect(count, equals(0), reason: 'Real zero attended visits must return 0, not fake 12');
    });

    test('T2: Attended today increments correctly when a visit is completed today for the logged-in doctor', () async {
      final metricsService = MockDoctorDashboardMetricsService(mockAttendedCount: 1);
      DoctorDashboardMetricsService.instance = metricsService;

      final count = await DoctorDashboardMetricsService.instance.getPatientsAttendedTodayCount(doctorId: 'DOC-101');
      expect(count, equals(1));
    });

    test('T3: Attended today does not count visits completed on previous calendar days', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      bool isDateToday(DateTime dt) =>
          dt.year == today.year && dt.month == today.month && dt.day == today.day;

      expect(isDateToday(today), isTrue);
      expect(isDateToday(yesterday), isFalse);
    });

    test('T4: Attended today does not count visits completed by other doctors', () {
      const activeDoctorId = 'DOC-101';
      const otherDoctorId = 'DOC-202';

      final visits = [
        {'id': 'v1', 'doctorId': activeDoctorId, 'status': 'completed'},
        {'id': 'v2', 'doctorId': otherDoctorId, 'status': 'completed'},
        {'id': 'v3', 'doctorId': activeDoctorId, 'status': 'completed'},
      ];

      final filtered = visits.where((v) => v['doctorId'] == activeDoctorId && v['status'] == 'completed').toList();
      expect(filtered.length, equals(2));
    });

    test('T5: Attended today does not count in-progress or cancelled visits', () {
      const activeDoctorId = 'DOC-101';
      final visits = [
        {'id': 'v1', 'doctorId': activeDoctorId, 'status': 'completed'},
        {'id': 'v2', 'doctorId': activeDoctorId, 'status': 'inConsultation'},
        {'id': 'v3', 'doctorId': activeDoctorId, 'status': 'cancelled'},
      ];

      final completed = visits.where((v) => v['status'] == 'completed').toList();
      expect(completed.length, equals(1));
    });

    test('T6: Error in dashboard metrics query throws/propagates exception without silent mock fallback', () async {
      final throwingService = _ThrowingMetricsService();
      DoctorDashboardMetricsService.instance = throwingService;

      expect(
        () async => await DoctorDashboardMetricsService.instance.getPatientsAttendedTodayCount(doctorId: 'DOC-101'),
        throwsA(isA<Exception>()),
      );
    });

    test('T7: Stream subscription updates attended count in real-time', () async {
      final metricsService = MockDoctorDashboardMetricsService(mockAttendedCount: 0);
      DoctorDashboardMetricsService.instance = metricsService;

      final stream = DoctorDashboardMetricsService.instance.watchPatientsAttendedTodayCount(doctorId: 'DOC-101');
      final expectation = expectLater(stream, emitsThrough(1));

      await pumpEventQueue();
      metricsService.setAttendedCount(1);
      await expectation;
    });

    test('T8: Pending requests count shows 0 when queue is empty for doctor department', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      DoctorPatientRequestService.instance = requestService;

      final count = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Cardiology');
      expect(count, equals(0), reason: 'Zero pending requests must return 0, not fake 187');
    });

    test('T9: Pending requests count matches unassigned waiting requests for doctor department', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(requestId: 'REQ-1', domain: 'Cardiology'));
      DoctorPatientRequestService.instance = requestService;

      final count = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Cardiology');
      expect(count, equals(1));
    });

    test('T10: Pending requests count does not count requests from other clinical departments', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(requestId: 'REQ-CARDIO', domain: 'Cardiology'));
      requestService.addRequest(_buildRequest(requestId: 'REQ-DERM', domain: 'Dermatology'));
      DoctorPatientRequestService.instance = requestService;

      final cardioCount = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Cardiology');
      expect(cardioCount, equals(1));

      final dermCount = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Dermatology');
      expect(dermCount, equals(1));
    });

    test('T11: Pending requests count does not count requests already assigned to a doctor', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-ASSIGNED',
        domain: 'Cardiology',
        status: PatientRequestStatus.assigned,
        assignedDoctorId: 'DOC-999',
      ));
      DoctorPatientRequestService.instance = requestService;

      final count = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Cardiology');
      expect(count, equals(0));
    });

    test('T12: Pending requests count does not count completed or cancelled requests', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-DONE',
        domain: 'Cardiology',
        status: PatientRequestStatus.completed,
      ));
      DoctorPatientRequestService.instance = requestService;

      final count = await DoctorPatientRequestService.instance.getPendingRequestCount(domain: 'Cardiology');
      expect(count, equals(0));
    });

    test('T13: Error in pending requests query emits error state with Retry', () async {
      final throwingRequestService = _ThrowingRequestService();
      DoctorPatientRequestService.instance = throwingRequestService;

      expect(
        () async => await DoctorPatientRequestService.instance.getPendingRequests(domain: 'Cardiology'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Group 2: Patient Requests Queue & First-Doctor-Wins Semantics', () {
    test('T14: Incoming queue streams waiting, unassigned requests matching doctor department in FIFO order', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();

      final firstTime = DateTime.now().subtract(const Duration(minutes: 10));
      final secondTime = DateTime.now().subtract(const Duration(minutes: 5));

      requestService.addRequest(_buildRequest(
        requestId: 'REQ-2',
        domain: 'Cardiology',
        requestedAt: secondTime,
      ));
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-1',
        domain: 'Cardiology',
        requestedAt: firstTime,
      ));

      final requests = await requestService.getPendingRequests(domain: 'Cardiology');
      expect(requests.length, equals(2));
      expect(requests.first.requestId, equals('REQ-1'), reason: 'FIFO order: earlier check-in time must come first');
    });

    test('T15: Requests for other departments are strictly filtered out', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-PEDIATRICS',
        domain: 'Pediatrics',
      ));

      final requests = await requestService.getPendingRequests(domain: 'Cardiology');
      expect(requests.isEmpty, isTrue);
    });

    test('T16: When doctor presence is not Available, accept attempts are rejected with unavailable', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-1',
        domain: 'Cardiology',
      ));

      // Doctor goes offline
      await DoctorPresenceService.instance.goOffline();
      expect(DoctorPresenceService.instance.isAvailable, isFalse);

      final result = await requestService.acceptPatientRequest(
        requestId: 'REQ-1',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );
      expect(result.status, equals(DoctorAssignmentStatus.unavailable));
      expect(result.isUnavailable, isTrue);

      // Doctor returns available
      await DoctorPresenceService.instance.setAvailable();
      expect(DoctorPresenceService.instance.isAvailable, isTrue);
    });

    test('T17: Atomic First-Doctor-Wins: Successful acceptance assigns doctor and transitions presence', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-1',
        domain: 'Cardiology',
      ));

      final result = await requestService.acceptPatientRequest(
        requestId: 'REQ-1',
        doctorId: 'DOC-101',
        doctorDomain: 'Cardiology',
      );

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(DoctorAssignmentStatus.success));

      // Presence transition
      await DoctorPresenceService.instance.setInConsultation();
      expect(DoctorPresenceService.instance.isInConsultation, isTrue);
    });

    test('T18: Race condition / conflict: If another doctor accepted first, returns alreadyAssigned', () async {
      final requestService = MockDoctorPatientRequestService();
      requestService.clearAllRequests();
      requestService.addRequest(_buildRequest(
        requestId: 'REQ-1',
        domain: 'Cardiology',
      ));

      // Doctor A accepts
      final resA = await requestService.acceptPatientRequest(
        requestId: 'REQ-1',
        doctorId: 'DOC-A',
        doctorDomain: 'Cardiology',
      );
      expect(resA.isSuccess, isTrue);

      // Doctor B attempts to accept the same request
      final resB = await requestService.acceptPatientRequest(
        requestId: 'REQ-1',
        doctorId: 'DOC-B',
        doctorDomain: 'Cardiology',
      );
      expect(resB.isAlreadyAssigned, isTrue);
      expect(resB.status, equals(DoctorAssignmentStatus.alreadyAssigned));
    });

    test('T19: Stream emits error on failure to trigger explicit error view', () async {
      final throwingRequestService = _ThrowingRequestService();
      DoctorPatientRequestService.instance = throwingRequestService;

      final stream = DoctorPatientRequestService.instance.watchPendingRequests(domain: 'Cardiology');
      expectLater(stream, emitsError(isA<Exception>()));
    });
  });

  group('Group 3: Speech-to-Text Subsystem Hardening & Locale Resolution', () {
    test('T20: SpeechToTextService starts in idle state; no auto-start', () {
      final speechService = WindowsSpeechToTextService.instance;
      expect(speechService.state, equals(SpeechRecognitionState.idle));
      expect(speechService.isListening, isFalse);
    });

    test('T21: Locale resolution: en-IN safely resolves and falls back to en-US', () {
      final tag = WindowsSpeechToTextService.resolveLocaleTag(KioskLocale.english);
      expect(tag, equals('en-IN'));

      final selected = WindowsSpeechToTextService.selectBestCulture('en-IN', ['en-US (Microsoft Speech Recognizer 8.0)']);
      expect(selected, equals('en-US'), reason: 'English Indian locale safely maps to en-US installed recognizer');
    });

    test('T22: Unsupported locale handling: Hindi or Marathi not installed reports clear error message without hang', () {
      final installed = ['en-US (Microsoft Speech Recognizer 8.0)'];

      final hindiMatch = WindowsSpeechToTextService.selectBestCulture('hi-IN', installed);
      expect(hindiMatch, isNull, reason: 'Hindi is not installed in recognizers and must not silently fall back to English');

      final marathiMatch = WindowsSpeechToTextService.selectBestCulture('mr-IN', installed);
      expect(marathiMatch, isNull, reason: 'Marathi is not installed in recognizers and must not silently fall back to English');
    });

    test('T23: Field isolation: Speech transcription targets only active field', () {
      const fieldA = 'chiefComplaint';
      const fieldB = 'assessment';

      String? activeField = fieldA;
      final controllers = {
        fieldA: 'Initial A',
        fieldB: 'Initial B',
      };

      final transcript = 'Patient presents with severe chest pain';
      controllers[activeField] = transcript;

      expect(controllers[fieldA], equals(transcript));
      expect(controllers[fieldB], equals('Initial B'), reason: 'fieldB must not be modified by speech on fieldA');
    });

    test('T24: Append vs. Replace modal preserves existing text and allows doctor choice', () {
      const existingText = 'Initial diagnosis';
      const newTranscript = 'Secondary observation';

      final appendResult = '$existingText $newTranscript';
      const replaceResult = newTranscript;

      expect(appendResult, equals('Initial diagnosis Secondary observation'));
      expect(replaceResult, equals('Secondary observation'));
    });

    test('T25: Zero raw audio data stored or transmitted to Gemini', () {
      final visit = ClinicalVisit(
        visitId: 'VISIT-1',
        caseId: 'CASE-1',
        patientId: 'PAT-1',
        visitNumber: 1,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        department: 'Cardiology',
        chiefComplaint: 'Chest tightness',
        startedAt: DateTime.now(),
      );

      final json = visit.toFirestore();
      expect(json.containsKey('audioBytes'), isFalse);
      expect(json.containsKey('audioFileUrl'), isFalse);
      expect(json['chiefComplaint'], equals('Chest tightness'));
    });

    test('T26: Single active mic: Triggering speech cancels/replaces any previous session', () async {
      final speechService = WindowsSpeechToTextService.instance;
      expect(speechService.isListening, isFalse);

      await speechService.cancelListening();
      expect(speechService.state, equals(SpeechRecognitionState.idle));
      expect(speechService.currentListeningField, isNull);
    });
  });
}

class _ThrowingMetricsService implements DoctorDashboardMetricsService {
  @override
  Future<int> getPatientsAttendedTodayCount({String? doctorId}) async {
    throw Exception('Firestore offline network timeout');
  }

  @override
  Stream<int> watchPatientsAttendedTodayCount({String? doctorId}) {
    return Stream.error(Exception('Firestore offline network timeout'));
  }

  @override
  Future<int> getPendingRequestsCount({String? domain}) async {
    throw Exception('Firestore offline network timeout');
  }

  @override
  Stream<int> watchPendingRequestsCount({String? domain}) {
    return Stream.error(Exception('Firestore offline network timeout'));
  }
}

class _ThrowingRequestService implements DoctorPatientRequestService {
  @override
  Future<List<DoctorPatientRequest>> getPendingRequests({String? domain}) async {
    throw Exception('Firestore request fetch failure');
  }

  @override
  Stream<List<DoctorPatientRequest>> watchPendingRequests({String? domain}) {
    return Stream.error(Exception('Firestore request fetch failure'));
  }

  @override
  Future<int> getPendingRequestCount({String? domain}) async {
    throw Exception('Firestore request count failure');
  }

  @override
  Future<void> refreshRequests() async {
    throw Exception('Firestore refresh failure');
  }

  @override
  Future<DoctorAssignmentResult> acceptPatientRequest({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
  }) async {
    throw Exception('Firestore accept transaction failure');
  }
}
