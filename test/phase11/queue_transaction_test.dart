import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';

void main() {
  group('Phase 11: Transaction-Safe Queue Allocation & Capacity Tests', () {
    late MockAppointmentRepository repo;

    setUp(() {
      repo = MockAppointmentRepository();
      repo.clear();
    });

    test('saveAppointmentWithAtomicQueue allocates sequential A-XXXXX tickets', () async {
      final req1 = AppointmentRequest(
        requestId: 'REQ-001',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00000',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-001',
      );

      final req2 = AppointmentRequest(
        requestId: 'REQ-002',
        patientId: 'AAYU-482910',
        domainId: 'neurology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00000',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-002',
      );

      final saved1 = await repo.saveAppointmentWithAtomicQueue(req1);
      final saved2 = await repo.saveAppointmentWithAtomicQueue(req2);

      expect(saved1.queueNumber, 'A-00001');
      expect(saved2.queueNumber, 'A-00002');
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(saved1.queueNumber), isTrue);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(saved2.queueNumber), isTrue);

      // Verify appointments were stored with the generated queue numbers
      final retrieved1 = await repo.getAppointmentById('REQ-001');
      expect(retrieved1?.queueNumber, 'A-00001');
      final retrieved2 = await repo.getAppointmentById('REQ-002');
      expect(retrieved2?.queueNumber, 'A-00002');
    });

    test('Throws queueCapacityReached when counter reaches 99,999 limit', () async {
      // Simulate counter at 100,000 (past 99,999 limit)
      repo.setQueueCounterForTesting(100000);

      final reqLimit = AppointmentRequest(
        requestId: 'REQ-LIMIT',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00000',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-LIMIT',
      );

      // Now counter has exceeded 99,999
      expect(
        () => repo.saveAppointmentWithAtomicQueue(reqLimit),
        throwsA(
          isA<BackendException>().having(
            (e) => e.code,
            'code',
            BackendException.queueCapacityReached,
          ),
        ),
      );
    });
  });
}
