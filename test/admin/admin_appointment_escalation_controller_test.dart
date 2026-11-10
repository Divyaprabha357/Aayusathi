import 'package:aayusathi/admin/controllers/admin_appointment_escalation_controller.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:aayusathi/services/appointment_escalation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppointmentRepository appointmentRepo;
  late MockDoctorRepository doctorRepo;
  late MockAuditRepository auditRepo;
  late AdminAppointmentEscalationController controller;

  final fixedNow = DateTime(2026, 9, 8, 10, 30, 0);

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    appointmentRepo = MockAppointmentRepository.instance;
    doctorRepo = MockDoctorRepository.instance;
    auditRepo = MockAuditRepository.instance;

    appointmentRepo.clear();
    auditRepo.clear();
    doctorRepo.resetToDefaults();

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );

    controller = AdminAppointmentEscalationController.instance;
    controller.resetForTesting();
    controller.nowProvider = () => fixedNow;
  });

  tearDown(() {
    controller.resetForTesting();
  });

  group('Phase A7: Central Appointment Escalation Policy Tests', () {
    test('1. Appointment under 20 minutes is NOT eligible for escalation', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-001',
        patientId: 'PAT-001',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: fixedNow.subtract(const Duration(minutes: 19, seconds: 59)),
        sessionId: 'SES-001',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isFalse);
    });

    test('2. Appointment at exactly 20 minutes IS eligible for escalation', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-002',
        patientId: 'PAT-002',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00002',
        createdAt: fixedNow.subtract(const Duration(minutes: 20)),
        sessionId: 'SES-002',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isTrue);
    });

    test('3. Appointment over 20 minutes IS eligible for escalation', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-003',
        patientId: 'PAT-003',
        domainId: 'orthopedics',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00003',
        createdAt: fixedNow.subtract(const Duration(minutes: 35)),
        sessionId: 'SES-003',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isTrue);
    });

    test('4. Assigned appointment is NEVER escalated even if >20 min', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-004',
        patientId: 'PAT-004',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.accepted,
        assignedDoctorId: 'DOC-101',
        queueNumber: 'A-00004',
        createdAt: fixedNow.subtract(const Duration(minutes: 40)),
        sessionId: 'SES-004',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isFalse);
    });

    test('5. Cancelled appointment is NEVER escalated', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-005',
        patientId: 'PAT-005',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.cancelled,
        queueNumber: 'A-00005',
        createdAt: fixedNow.subtract(const Duration(minutes: 50)),
        sessionId: 'SES-005',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isFalse);
    });

    test('6. Completed appointment is NEVER escalated', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-006',
        patientId: 'PAT-006',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.completed,
        queueNumber: 'A-00006',
        createdAt: fixedNow.subtract(const Duration(hours: 2)),
        sessionId: 'SES-006',
      );

      expect(AppointmentEscalationPolicy.shouldEscalate(appt, fixedNow), isFalse);
    });

    test('16. Waiting duration calculation and formatting', () {
      final d1 = const Duration(minutes: 4);
      final d2 = const Duration(minutes: 27);
      final d3 = const Duration(hours: 1, minutes: 4);
      final d4 = const Duration(hours: 2, minutes: 15);

      expect(AppointmentEscalationPolicy.formatWaitDuration(d1), equals('04 min'));
      expect(AppointmentEscalationPolicy.formatWaitDuration(d2), equals('27 min'));
      expect(AppointmentEscalationPolicy.formatWaitDuration(d3), equals('1 hr 04 min'));
      expect(AppointmentEscalationPolicy.formatWaitDuration(d4), equals('2 hr 15 min'));
    });
  });

  group('Phase A7: Repository Atomic Escalation & Duplicate Protection Tests', () {
    test('7. Mark appointment escalated transitions none -> escalated', () async {
      final appt = AppointmentRequest(
        requestId: 'REQ-ESC-1',
        patientId: 'PAT-001',
        domainId: 'neurology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00010',
        createdAt: fixedNow.subtract(const Duration(minutes: 25)),
        sessionId: 'SES-010',
      );
      await appointmentRepo.saveAppointment(appt);

      final didEscalate = await appointmentRepo.markAppointmentEscalated('REQ-ESC-1');
      expect(didEscalate, isTrue);

      final updated = await appointmentRepo.getAppointmentById('REQ-ESC-1');
      expect(updated?.escalationStatus, equals(AppointmentEscalationStatus.escalated));
      expect(updated?.escalatedAt, isNotNull);
    });

    test('8. Duplicate escalation is prevented (Idempotent)', () async {
      final appt = AppointmentRequest(
        requestId: 'REQ-ESC-2',
        patientId: 'PAT-002',
        domainId: 'neurology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00011',
        createdAt: fixedNow.subtract(const Duration(minutes: 30)),
        sessionId: 'SES-011',
      );
      await appointmentRepo.saveAppointment(appt);

      final firstCall = await appointmentRepo.markAppointmentEscalated('REQ-ESC-2');
      expect(firstCall, isTrue);

      // Second attempt on same record must return false
      final secondCall = await appointmentRepo.markAppointmentEscalated('REQ-ESC-2');
      expect(secondCall, isFalse);
    });

    test('9. Original escalatedAt timestamp is preserved', () async {
      final originalEscalatedAt = DateTime(2026, 9, 8, 10, 0, 0);
      final appt = AppointmentRequest(
        requestId: 'REQ-ESC-3',
        patientId: 'PAT-003',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        escalationStatus: AppointmentEscalationStatus.escalated,
        escalatedAt: originalEscalatedAt,
        queueNumber: 'A-00012',
        createdAt: DateTime(2026, 9, 8, 9, 35, 0),
        sessionId: 'SES-012',
      );
      await appointmentRepo.saveAppointment(appt);

      final didEscalate = await appointmentRepo.markAppointmentEscalated('REQ-ESC-3');
      expect(didEscalate, isFalse);

      final current = await appointmentRepo.getAppointmentById('REQ-ESC-3');
      expect(current?.escalatedAt, equals(originalEscalatedAt));
    });

    test('10. Appointment model toMap and fromMap serialize escalation fields correctly', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-TEST-MAP',
        patientId: 'PAT-MAP',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        previousDoctorId: 'DOC-101',
        status: AppointmentStatus.waiting,
        escalationStatus: AppointmentEscalationStatus.escalated,
        queueNumber: 'A-00099',
        createdAt: DateTime(2026, 9, 8, 10, 0),
        escalatedAt: DateTime(2026, 9, 8, 10, 20),
        resolvedAt: DateTime(2026, 9, 8, 10, 25),
        assignedAt: DateTime(2026, 9, 8, 10, 25),
        sessionId: 'SES-MAP',
      );

      final map = appt.toMap();
      expect(map['escalationStatus'], equals('escalated'));
      expect(map['escalatedAt'], isNotNull);

      final reconstituted = AppointmentRequest.fromMap(map);
      expect(reconstituted.requestId, equals('REQ-TEST-MAP'));
      expect(reconstituted.escalationStatus, equals(AppointmentEscalationStatus.escalated));
      expect(reconstituted.isEscalated, isTrue);
      expect(reconstituted.previousDoctorId, equals('DOC-101'));
    });
  });

  group('Phase A7: Admin Controller Metrics & Filtering Tests', () {
    setUp(() async {
      final appointments = [
        AppointmentRequest(
          requestId: 'REQ-101',
          patientId: 'PAT-101',
          domainId: 'cardiology',
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          status: AppointmentStatus.waiting,
          queueNumber: 'A-00041',
          createdAt: fixedNow.subtract(const Duration(minutes: 5)),
          sessionId: 'SES-101',
        ),
        AppointmentRequest(
          requestId: 'REQ-102',
          patientId: 'PAT-102',
          domainId: 'cardiology',
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          status: AppointmentStatus.waiting,
          queueNumber: 'A-00042',
          createdAt: fixedNow.subtract(const Duration(minutes: 25)),
          sessionId: 'SES-102',
        ),
        AppointmentRequest(
          requestId: 'REQ-103',
          patientId: 'PAT-103',
          domainId: 'orthopedics',
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          status: AppointmentStatus.waiting,
          queueNumber: 'A-00043',
          createdAt: fixedNow.subtract(const Duration(minutes: 40)),
          sessionId: 'SES-103',
        ),
        AppointmentRequest(
          requestId: 'REQ-104',
          patientId: 'PAT-104',
          domainId: 'pediatrics',
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          status: AppointmentStatus.accepted,
          assignedDoctorId: 'DOC-103',
          escalationStatus: AppointmentEscalationStatus.resolved,
          resolvedAt: fixedNow.subtract(const Duration(minutes: 10)),
          queueNumber: 'A-00044',
          createdAt: fixedNow.subtract(const Duration(minutes: 50)),
          sessionId: 'SES-104',
        ),
      ];

      appointmentRepo.seedAppointments(appointments);
      await controller.initialize(
        appointmentRepository: appointmentRepo,
        doctorRepository: doctorRepo,
      );
    });

    test('11. Admin KPI counts calculate escalated, waiting, and resolved accurately', () {
      expect(controller.escalatedCount, equals(2)); // REQ-102 (25 min) and REQ-103 (40 min)
      expect(controller.waitingCount, equals(3)); // REQ-101, REQ-102, REQ-103
      expect(controller.resolvedTodayCount, equals(1)); // REQ-104
    });

    test('12. Oldest-first (FIFO) sorting orders by createdAt ascending', () {
      controller.setSort('oldestWaiting');
      final list = controller.filteredAppointments;

      expect(list.length, equals(4));
      expect(list.first.requestId, equals('REQ-104')); // 50 min ago
      expect(list[1].requestId, equals('REQ-103')); // 40 min ago
      expect(list[2].requestId, equals('REQ-102')); // 25 min ago
      expect(list.last.requestId, equals('REQ-101')); // 5 min ago
    });

    test('13. Department filter restricts appointments to domain', () {
      controller.setDepartment('cardiology');
      final list = controller.filteredAppointments;

      expect(list.length, equals(2));
      expect(list.every((a) => a.domainId == 'cardiology'), isTrue);
    });

    test('14. Search query filters by Queue Number and Appointment ID', () {
      controller.setSearchQuery('A-00042');
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.requestId, equals('REQ-102'));

      controller.setSearchQuery('REQ-103');
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.queueNumber, equals('A-00043'));
    });

    test('15. Status filter isolates Escalated, Waiting, and Resolved requests', () {
      controller.setStatus('escalated');
      expect(controller.filteredAppointments.length, equals(2));
      expect(controller.filteredAppointments.map((a) => a.requestId), containsAll(['REQ-102', 'REQ-103']));

      controller.setStatus('waiting');
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.requestId, equals('REQ-101'));

      controller.setStatus('resolved');
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.requestId, equals('REQ-104'));
    });
  });

  group('Phase A7: Doctor Eligibility & Assignment Safeguards Tests', () {
    late AppointmentRequest escalatedAppt;

    setUp(() async {
      escalatedAppt = AppointmentRequest(
        requestId: 'REQ-CARDIO-ESC',
        patientId: 'PAT-999',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00099',
        createdAt: fixedNow.subtract(const Duration(minutes: 30)),
        sessionId: 'SES-999',
      );

      final doctors = [
        DoctorProfile(
          doctorId: 'DOC-CARDIO-AVAIL',
          doctorUniqueCode: 'DOC-CARDIO-AVAIL',
          name: 'Dr. Available Cardio',
          qualification: 'MBBS, MD',
          department: 'cardiology',
          registeredPhone: '9876543210',
          email: 'avail.cardio@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'uid_1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-CARDIO-INACTIVE',
          doctorUniqueCode: 'DOC-CARDIO-INACTIVE',
          name: 'Dr. Inactive Cardio',
          qualification: 'MBBS, MD',
          department: 'cardiology',
          registeredPhone: '9876543211',
          email: 'inactive.cardio@aayusathi.com',
          isActive: false,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'uid_2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-CARDIO-OFFLINE',
          doctorUniqueCode: 'DOC-CARDIO-OFFLINE',
          name: 'Dr. Offline Cardio',
          qualification: 'MBBS, MD',
          department: 'cardiology',
          registeredPhone: '9876543212',
          email: 'offline.cardio@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.offline,
          authUid: 'uid_3',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-CARDIO-BUSY',
          doctorUniqueCode: 'DOC-CARDIO-BUSY',
          name: 'Dr. Busy Cardio',
          qualification: 'MBBS, MD',
          department: 'cardiology',
          registeredPhone: '9876543213',
          email: 'busy.cardio@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.inConsultation,
          authUid: 'uid_4',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-ORTHO-AVAIL',
          doctorUniqueCode: 'DOC-ORTHO-AVAIL',
          name: 'Dr. Available Ortho',
          qualification: 'MBBS, MS',
          department: 'orthopedics',
          registeredPhone: '9876543214',
          email: 'avail.ortho@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'uid_5',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final doc in doctors) {
        doctorRepo.saveDoctorProfile(doc);
      }
      appointmentRepo.seedAppointments([escalatedAppt]);

      await controller.initialize(
        appointmentRepository: appointmentRepo,
        doctorRepository: doctorRepo,
      );
    });

    test('17. Eligible doctor filtering returns only active and available matching domain', () {
      final eligible = controller.getEligibleDoctorsForAppointment(escalatedAppt);

      expect(eligible.isNotEmpty, isTrue);
      expect(eligible.any((d) => d.doctorId == 'DOC-CARDIO-AVAIL'), isTrue);
      for (final doc in eligible) {
        expect(doc.isActive, isTrue);
        expect(doc.availabilityStatus, equals(DoctorAvailabilityStatus.available));
        expect(doc.department.toLowerCase(), equals('cardiology'));
      }
    });

    test('18. Inactive doctor is rejected from eligibility', () {
      final eligible = controller.getEligibleDoctorsForAppointment(escalatedAppt);
      expect(eligible.any((d) => d.doctorId == 'DOC-CARDIO-INACTIVE'), isFalse);
    });

    test('19. Offline doctor is rejected from eligibility', () {
      final eligible = controller.getEligibleDoctorsForAppointment(escalatedAppt);
      expect(eligible.any((d) => d.doctorId == 'DOC-CARDIO-OFFLINE'), isFalse);
    });

    test('20. In-consultation doctor is rejected from eligibility', () {
      final eligible = controller.getEligibleDoctorsForAppointment(escalatedAppt);
      expect(eligible.any((d) => d.doctorId == 'DOC-CARDIO-BUSY'), isFalse);
    });

    test('21. Wrong department doctor is rejected from eligibility', () {
      final eligible = controller.getEligibleDoctorsForAppointment(escalatedAppt);
      expect(eligible.any((d) => d.doctorId == 'DOC-ORTHO-AVAIL'), isFalse);
    });

    test('22. Transactional manual assignment succeeds and locks doctor presence', () async {
      final result = await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      expect(result.isSuccess, isTrue);

      // Check appointment state
      final appt = await appointmentRepo.getAppointmentById('REQ-CARDIO-ESC');
      expect(appt?.status, equals(AppointmentStatus.accepted));
      expect(appt?.assignedDoctorId, equals('DOC-CARDIO-AVAIL'));
      expect(appt?.escalationStatus, equals(AppointmentEscalationStatus.resolved));
      expect(appt?.resolvedAt, isNotNull);

      // Check doctor presence is now inConsultation
      final doc = await doctorRepo.getDoctorProfileById('DOC-CARDIO-AVAIL');
      expect(doc?.availabilityStatus, equals(DoctorAvailabilityStatus.inConsultation));
    });

    test('23. Assignment race condition / busy doctor is rejected', () async {
      // Doctor becomes busy before commit
      await doctorRepo.setDoctorAvailabilityStatus(
        doctorId: 'DOC-CARDIO-AVAIL',
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );

      final result = await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isUnavailable, isTrue);
    });

    test('24. Attempt to assign already-assigned appointment is rejected', () async {
      // Another doctor claimed the appointment
      await appointmentRepo.saveAppointment(
        escalatedAppt.copyWith(
          status: AppointmentStatus.accepted,
          assignedDoctorId: 'DOC-OTHER',
        ),
      );

      final result = await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isAlreadyAssigned, isTrue);
    });

    test('25. Audit trail generated for ADMIN_APPOINTMENT_ASSIGNED & APPOINTMENT_ESCALATION_RESOLVED', () async {
      auditRepo.clear();

      await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      final events = await auditRepo.getLogsForEntity(
        entityType: 'APPOINTMENT',
        entityId: 'REQ-CARDIO-ESC',
      );
      expect(events.any((e) => e.action == 'ADMIN_APPOINTMENT_ASSIGNED'), isTrue);
      expect(events.any((e) => e.action == 'APPOINTMENT_ESCALATION_RESOLVED'), isTrue);
    });

    test('26. Audit logs strictly exclude passwords, tokens, Aadhaar, and OTPs', () async {
      auditRepo.clear();

      await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      final events = auditRepo.logs;
      for (final event in events) {
        final metaStr = event.metadata.toString().toLowerCase();
        expect(metaStr.contains('password'), isFalse);
        expect(metaStr.contains('token'), isFalse);
        expect(metaStr.contains('aadhaar'), isFalse);
        expect(metaStr.contains('otp'), isFalse);
      }
    });

    test('27. Previous-doctor restriction is respected', () async {
      final prevDocAppt = AppointmentRequest(
        requestId: 'REQ-PREV-DOC',
        patientId: 'PAT-777',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        previousDoctorId: 'DOC-SPECIALIST-9',
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00077',
        createdAt: fixedNow.subtract(const Duration(minutes: 30)),
        sessionId: 'SES-777',
      );

      final eligible = controller.getEligibleDoctorsForAppointment(prevDocAppt);
      // DOC-CARDIO-AVAIL is not DOC-SPECIALIST-9, so eligible list must be empty
      expect(eligible.isEmpty, isTrue);
    });

    test('28. Assignment failure preserves waiting and escalation state', () async {
      // Make doctor inactive to trigger failure
      await doctorRepo.setDoctorActiveStatus(
        doctorId: 'DOC-CARDIO-AVAIL',
        isActive: false,
      );

      final result = await controller.assignDoctor(
        requestId: 'REQ-CARDIO-ESC',
        doctorId: 'DOC-CARDIO-AVAIL',
      );

      expect(result.isSuccess, isFalse);

      // Appointment must still be waiting
      final appt = await appointmentRepo.getAppointmentById('REQ-CARDIO-ESC');
      expect(appt?.status, equals(AppointmentStatus.waiting));
      expect(appt?.assignedDoctorId, isNull);
    });
  });
}
