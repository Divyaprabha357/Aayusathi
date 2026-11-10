import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/doctor.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/models/previous_visit_record.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';

void main() {
  group('Phase 9: Data Models Serialization & Validation', () {
    test('Patient model serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final patient = Patient(
        patientId: 'AAYU-102938',
        name: 'Aarav Sharma',
        dateOfBirth: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        bloodGroup: 'O+',
        address: '104, Green Meadows, Pune',
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      final map = patient.toMap();
      expect(map['patientId'], 'AAYU-102938');
      expect(map['name'], 'Aarav Sharma');
      expect(map['age'], 34);
      expect(map.containsKey('aadhaarNumber'), isFalse);
      expect(map.containsKey('aadhaar'), isFalse);

      final reconstructed = Patient.fromMap(map);
      expect(reconstructed.patientId, patient.patientId);
      expect(reconstructed.name, patient.name);
      expect(reconstructed.phone, patient.phone);
      expect(reconstructed.bloodGroup, 'O+');
      expect(reconstructed.maskedPhone, '+91 ••••• •3210');
    });

    test('Patient model fromPatientIdentity strictly never stores Aadhaar', () {
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

      final patient = Patient.fromPatientIdentity(identity);
      expect(patient.patientId, 'AAYU-102938');
      expect(patient.name, 'Aarav Sharma');

      final firestoreData = patient.toFirestore();
      expect(firestoreData.containsKey('aadhaarNumber'), isFalse);
      expect(firestoreData.containsKey('aadhaar'), isFalse);
    });

    test('Doctor model serializes and deserializes with domain mapping', () {
      final now = DateTime(2026, 9, 5);
      final doctor = Doctor(
        doctorId: 'DOC-CARD-01',
        name: 'Dr. Ramesh Gupta',
        specialization: 'Cardiology',
        domains: const ['cardiology', 'general_medicine'],
        isActive: true,
        isAvailable: true,
        currentQueueCount: 3,
        createdAt: now,
        updatedAt: now,
      );

      final map = doctor.toMap();
      expect(map['doctorId'], 'DOC-CARD-01');
      expect(map['domains'], ['cardiology', 'general_medicine']);
      expect(map['isAvailable'], true);

      final reconstructed = Doctor.fromMap(map);
      expect(reconstructed.doctorId, 'DOC-CARD-01');
      expect(reconstructed.specialization, 'Cardiology');
      expect(reconstructed.domains.length, 2);
    });

    test('AppointmentRequest serializes and verifies strict queue format', () {
      final now = DateTime(2026, 9, 5);
      final appointment = AppointmentRequest(
        requestId: 'REQ-123456789',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        previousDoctorId: 'DOC-CARD-01',
        assignedDoctorId: 'DOC-CARD-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: now,
        source: 'KIOSK',
        sessionId: 'SESS-1001',
      );

      expect(appointment.hasValidQueueFormat, isTrue);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(appointment.queueNumber), isTrue);

      final map = appointment.toMap();
      expect(map['queueNumber'], 'A-00027');
      expect(map['status'], 'waiting');
      expect(map['preferredDoctorMode'], 'sameDoctor');

      final reconstructed = AppointmentRequest.fromMap(map);
      expect(reconstructed.requestId, 'REQ-123456789');
      expect(reconstructed.queueNumber, 'A-00027');
      expect(reconstructed.status, AppointmentStatus.waiting);
    });

    test('AppointmentRequest detects invalid queue numbers', () {
      final now = DateTime.now();
      final invalidQueue = AppointmentRequest(
        requestId: 'REQ-INVALID',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.pending,
        queueNumber: 'A-27', // Too short
        createdAt: now,
        sessionId: 'SESS-1001',
      );

      expect(invalidQueue.hasValidQueueFormat, isFalse);
    });

    test('VitalReading serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 5, 10, 30);
      final reading = VitalReading(
        vitalId: 'VIT-001',
        patientId: 'AAYU-102938',
        appointmentId: 'REQ-100',
        heartRate: 72,
        spo2: 98,
        temperature: 36.8,
        timestamp: now,
        source: VitalSource.arduino,
        status: VitalStatus.valid,
        validationStatus: 'normal',
      );

      expect(reading.isComplete, isTrue);

      final map = reading.toMap();
      expect(map['heartRate'], 72);
      expect(map['validationStatus'], 'normal');
      expect(map.containsKey('systolic'), isFalse);
      expect(map.containsKey('diastolic'), isFalse);
      expect(map.containsKey('bloodPressure'), isFalse);

      final reconstructed = VitalReading.fromMap(map);
      expect(reconstructed.vitalId, 'VIT-001');
      expect(reconstructed.patientId, 'AAYU-102938');
      expect(reconstructed.heartRate, 72);
      expect(reconstructed.spo2, 98);
      expect(reconstructed.temperature, 36.8);
      expect(reconstructed.validationStatus, 'normal');
    });

    test('PreviousVisitRecord serializes and deserializes correctly', () {
      final visitDate = DateTime(2026, 7, 15);
      final visit = PreviousVisitRecord(
        visitId: 'VISIT-001',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        previousDoctorId: 'DOC-CARD-01',
        lastVisitDate: visitDate,
        status: 'completed',
      );

      final map = visit.toMap();
      expect(map['patientId'], 'AAYU-102938');
      expect(map['previousDoctorId'], 'DOC-CARD-01');

      final reconstructed = PreviousVisitRecord.fromMap(map);
      expect(reconstructed.visitId, 'VISIT-001');
      expect(reconstructed.domainId, 'cardiology');
    });

    test('AuditLog serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 5, 11, 0, 0);
      final log = AuditLog(
        auditId: 'AUD-998877',
        actorType: 'KIOSK',
        actorId: 'KIOSK-01',
        action: 'PATIENT_REGISTERED',
        entityType: 'PATIENT',
        entityId: 'AAYU-102938',
        timestamp: now,
        metadata: {'kioskMode': 'NewUser'},
      );

      final map = log.toMap();
      expect(map['auditId'], 'AUD-998877');
      expect(map['actorType'], 'KIOSK');
      expect(map['action'], 'PATIENT_REGISTERED');

      final reconstructed = AuditLog.fromMap(map);
      expect(reconstructed.auditId, 'AUD-998877');
      expect(reconstructed.actorId, 'KIOSK-01');
      expect(reconstructed.metadata['kioskMode'], 'NewUser');
    });
  });
}
