import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/kiosk/models/kiosk_session.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/repositories/firebase/firebase_appointment_repository.dart';
import 'package:aayusathi/repositories/firebase/firebase_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9: Backend Mode, Error Handling & Session Reset', () {
    test('BackendProvider switches mode and resolves repositories with safe fallback', () {
      final provider = BackendProvider.instance;
      provider.resetOverrides();

      provider.setMode(BackendMode.mock);
      expect(provider.mode, BackendMode.mock);
      expect(provider.isFirebaseMode, isFalse);
      expect(provider.patientRepository, isA<MockPatientRepository>());

      // Firebase mode without live Firebase initialized safely falls back to Mock
      provider.setMode(BackendMode.firebase);
      expect(provider.mode, BackendMode.firebase);
      expect(provider.isFirebaseMode, isTrue);

      // Revert to mock
      provider.setMode(BackendMode.mock);
      expect(provider.mode, BackendMode.mock);
    });

    test('BackendProvider allows custom repository injection for tests', () {
      final provider = BackendProvider.instance;
      final customPatientRepo = MockPatientRepository();
      provider.setCustomRepositories(patientRepo: customPatientRepo);

      expect(provider.patientRepository, equals(customPatientRepo));
      provider.resetOverrides();
    });

    test('FirebasePatientRepository rejects patient with empty ID', () async {
      final repo = FirebasePatientRepository();
      final invalidPatient = Patient(
        patientId: '',
        name: 'No ID',
        dateOfBirth: '01 Jan 2000',
        age: 26,
        gender: 'Female',
        phone: '123',
        bloodGroup: 'O+',
        address: 'Addr',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repo.savePatient(invalidPatient),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          BackendException.invalidData,
        )),
      );
    });

    test('FirebaseAppointmentRepository rejects appointment with invalid queue format', () async {
      final repo = FirebaseAppointmentRepository();
      final invalidAppt = AppointmentRequest(
        requestId: 'REQ-ERR',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.pending,
        queueNumber: 'BAD-QUEUE-123', // Does not match ^A-[0-9]{5}$
        createdAt: DateTime.now(),
        sessionId: 'SESS-1',
      );

      expect(
        () => repo.saveAppointment(invalidAppt),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          BackendException.invalidData,
        )),
      );
    });

    test('KioskService.resetSession() completely wipes all sensitive data and restores English', () {
      final kiosk = KioskService.instance;
      kiosk.startNewSession();
      kiosk.setUserType(UserType.newUser);
      kiosk.setLocale(KioskLocale.hindi);
      kiosk.setAadhaarInput('111122223333');
      kiosk.setPatientIdInput('102938');
      kiosk.setOtpVerified(true);

      const identity = PatientIdentity(
        aadhaarNumber: '111122223333',
        patientId: 'AAYU-102938',
        fullName: 'Aarav Sharma',
        dob: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        address: '104, Green Meadows, Pune',
        bloodGroup: 'O+',
      );
      kiosk.setIdentifiedPatient(identity);

      // Verify session has active state
      expect(kiosk.identifiedPatient, isNotNull);
      expect(kiosk.activeAadhaarInput, '111122223333');
      expect(kiosk.isOtpVerified, isTrue);
      expect(kiosk.activeLocale, KioskLocale.hindi);

      // Trigger resetSession()
      kiosk.resetSession();

      // Verify total wipe
      expect(kiosk.currentSession, isNull);
      expect(kiosk.userType, isNull);
      expect(kiosk.identifiedPatient, isNull);
      expect(kiosk.activeAadhaarInput, isEmpty);
      expect(kiosk.activePatientIdInput, isEmpty);
      expect(kiosk.isOtpVerified, isFalse);
      expect(kiosk.currentVitalReading, isNull);
      expect(kiosk.vitalValidationResult, isNull);
      expect(kiosk.selectedDomain, isNull);
      expect(kiosk.currentPreviousVisitRecord, isNull);
      expect(kiosk.currentAppointmentRequest, isNull);
      expect(kiosk.activeLocale, KioskLocale.english); // Strictly resets to English
    });
  });
}
