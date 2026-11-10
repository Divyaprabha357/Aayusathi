import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/auth/mock_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/opd_domain.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';

void main() {
  group('Phase 11: End-to-End Kiosk Persistence Integration', () {
    late KioskService kiosk;

    setUp(() {
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
      MockAppointmentRepository.instance.clear();

      kiosk = KioskService.instance;
      kiosk.resetSession();
    });

    tearDown(() {
      kiosk.resetSession();
      BackendProvider.instance.resetOverrides();
    });

    test('Full OPD booking flow persists appointment, visit, queue, and audit records', () async {
      // 1. Setup terminal authenticated session
      final mockAuth = MockAuthService();
      BackendProvider.instance.setCustomRepositories(authService: mockAuth);
      await mockAuth.signInAnonymously(role: UserRole.kiosk);

      kiosk.startNewSession();

      // 2. Identify patient
      const patient = PatientIdentity(
        aadhaarNumber: '111122223333',
        patientId: 'AAYU-102938',
        fullName: 'Aarav Sharma',
        dob: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        address: 'Pune, Maharashtra',
        bloodGroup: 'O+',
        isNewRegistration: false,
      );
      kiosk.setIdentifiedPatient(patient);

      // 3. Record vitals
      final vitals = VitalReading(
        heartRate: 72,
        spo2: 98,
        temperature: 36.8,
        source: VitalSource.arduino,
        timestamp: DateTime.now(),
      );
      kiosk.setVitalReading(vitals);

      // 4. Select domain
      final domain = OpdDomain.all.firstWhere((d) => d.id == 'cardiology');
      kiosk.setSelectedDomain(domain);

      // 5. Book and atomically persist appointment
      final appointment = await kiosk.bookAndPersistAppointment(
        patientId: patient.patientId,
        domainId: domain.id,
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
      );

      // Assertions:
      expect(appointment.queueNumber, 'A-00001');
      expect(appointment.patientId, 'AAYU-102938');
      expect(appointment.domainId, 'cardiology');

      // Verify AppointmentRepository contains the appointment
      final persistedAppt = await BackendProvider.instance.appointmentRepository.getAppointmentById(appointment.requestId);
      expect(persistedAppt, isNotNull);
      expect(persistedAppt?.queueNumber, 'A-00001');

      // Verify VisitRepository contains the visit with queued/requested status
      final persistedVisit = await BackendProvider.instance.visitRepository.getLatestVisitForPatientAndDomain(
        patientId: patient.patientId,
        domainId: domain.id,
      );
      expect(persistedVisit, isNotNull);
      expect(persistedVisit?.appointmentId, appointment.requestId);
      expect(persistedVisit?.status, anyOf('queued', 'requested'));

      // Verify AuditRepository contains APPOINTMENT_CREATED audit
      final apptAudits = await BackendProvider.instance.auditRepository.getLogsForEntity(
        entityType: 'APPOINTMENT',
        entityId: appointment.requestId,
      );
      expect(apptAudits.isNotEmpty, isTrue);
      expect(apptAudits.first.action, 'APPOINTMENT_CREATED');

      // 6. Reset session at end of patient turn
      kiosk.resetSession();

      expect(kiosk.hasActiveSession, isFalse);
      expect(kiosk.currentAppointmentRequest, isNull);
      expect(kiosk.identifiedPatient, isNull);

      // Kiosk terminal auth identity remains active
      expect(BackendProvider.instance.authService.isAuthenticated, isTrue);
      expect(BackendProvider.instance.authService.currentUser?.role, UserRole.kiosk);
    });
  });
}
