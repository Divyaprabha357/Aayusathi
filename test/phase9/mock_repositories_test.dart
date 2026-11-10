import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';

void main() {
  group('Phase 9: Mock Repositories Unit Tests', () {
    test('MockPatientRepository retrieves existing fictional patients', () async {
      final repo = MockPatientRepository.instance;
      repo.resetToDefaults();

      final patient = await repo.getPatientById('AAYU-102938');
      expect(patient, isNotNull);
      expect(patient!.name, 'Aarav Sharma');
      expect(patient.age, 34);

      // Normalized lookup without AAYU- prefix
      final normalized = await repo.getPatientById('482910');
      expect(normalized, isNotNull);
      expect(normalized!.name, 'Priya Patil');

      // Patient not found
      final notFound = await repo.getPatientById('AAYU-999999');
      expect(notFound, isNull);

      // Exists check
      expect(await repo.patientExists('AAYU-773829'), isTrue);
      expect(await repo.patientExists('AAYU-000000'), isFalse);
    });

    test('MockPatientRepository saves new patient record', () async {
      final repo = MockPatientRepository.instance;
      final newPatient = Patient(
        patientId: 'AAYU-555555',
        name: 'Test Patient',
        dateOfBirth: '01 Jan 2000',
        age: 26,
        gender: 'Female',
        phone: '+91 91234 56789',
        bloodGroup: 'O+',
        address: 'Test Address',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.savePatient(newPatient);
      final fetched = await repo.getPatientById('AAYU-555555');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test Patient');
    });

    test('MockAppointmentRepository allocates strict sequential queue numbers', () async {
      final repo = MockAppointmentRepository.instance;
      repo.clear();

      final q1 = await repo.allocateNextQueueNumber();
      final q2 = await repo.allocateNextQueueNumber();
      final q3 = await repo.allocateNextQueueNumber();

      expect(q1, 'A-00001');
      expect(q2, 'A-00002');
      expect(q3, 'A-00003');
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(q1), isTrue);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(q2), isTrue);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(q3), isTrue);

      repo.resetQueueCounter();
      final qReset = await repo.allocateNextQueueNumber();
      expect(qReset, 'A-00001');
    });

    test('MockAppointmentRepository saves, retrieves and updates appointment', () async {
      final repo = MockAppointmentRepository.instance;
      repo.clear();

      final appt = AppointmentRequest(
        requestId: 'REQ-TEST-1',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime.now(),
        sessionId: 'SESS-1',
      );

      await repo.saveAppointment(appt);

      final fetched = await repo.getAppointmentById('REQ-TEST-1');
      expect(fetched, isNotNull);
      expect(fetched!.queueNumber, 'A-00001');

      final forPatient = await repo.getAppointmentsForPatient('AAYU-102938');
      expect(forPatient.length, 1);

      await repo.updateAppointmentStatus('REQ-TEST-1', AppointmentStatus.completed);
      final updated = await repo.getAppointmentById('REQ-TEST-1');
      expect(updated!.status, AppointmentStatus.completed);
    });

    test('MockVitalRepository saves and queries vital readings', () async {
      final repo = MockVitalRepository.instance;
      repo.clear();

      final reading = VitalReading(
        heartRate: 75,
        spo2: 99,
        temperature: 36.6,
        timestamp: DateTime.now(),
        source: VitalSource.arduino,
        status: VitalStatus.valid,
        validationStatus: 'normal',
      );

      await repo.saveVitalReading(
        patientId: 'AAYU-102938',
        reading: reading,
        appointmentId: 'REQ-TEST-1',
      );

      final vitals = await repo.getVitalsForPatient('AAYU-102938');
      expect(vitals.length, 1);
      expect(vitals.first.heartRate, 75);

      final forAppt = await repo.getVitalsForAppointment('REQ-TEST-1');
      expect(forAppt, isNotNull);
      expect(forAppt!.spo2, 99);
    });

    test('MockDoctorRepository respects doctor availability and domain queries', () async {
      final repo = MockDoctorRepository.instance;
      repo.resetToDefaults();

      final cardiologyDoctors = await repo.getDoctorsForDomain('cardiology');
      expect(cardiologyDoctors.length, 2);

      // Neurology doctor 01 is unavailable
      expect(await repo.isDoctorAvailable('DOC-NEUR-01'), isFalse);
      expect(await repo.isDoctorAvailable('DOC-NEUR-02'), isTrue);

      // Alternative doctor excludes previous unavailable doctor
      final alt = await repo.findAlternativeDoctor(
        domainId: 'neurology',
        excludeDoctorId: 'DOC-NEUR-01',
      );
      expect(alt, 'DOC-NEUR-02');

      // Orthopedics: all doctors busy
      expect(await repo.areAllDoctorsBusy('orthopedics'), isTrue);
      final altOrth = await repo.findAlternativeDoctor(domainId: 'orthopedics');
      expect(altOrth, isNull);
    });

    test('MockAuditRepository records and filters audit events', () async {
      final repo = MockAuditRepository.instance;
      repo.clear();

      await repo.logEvent(
        AuditLog(
          auditId: 'AUD-01',
          actorType: 'KIOSK',
          actorId: 'KIOSK-01',
          action: 'QUEUE_GENERATED',
          entityType: 'APPOINTMENT',
          entityId: 'REQ-100',
          timestamp: DateTime.now(),
        ),
      );

      await repo.logEvent(
        AuditLog(
          auditId: 'AUD-02',
          actorType: 'KIOSK',
          actorId: 'KIOSK-01',
          action: 'VITALS_RECORDED',
          entityType: 'PATIENT',
          entityId: 'AAYU-102938',
          timestamp: DateTime.now(),
        ),
      );

      final patientLogs = await repo.getLogsForEntity(
        entityType: 'PATIENT',
        entityId: 'AAYU-102938',
      );
      expect(patientLogs.length, 1);
      expect(patientLogs.first.action, 'VITALS_RECORDED');
    });
  });
}
