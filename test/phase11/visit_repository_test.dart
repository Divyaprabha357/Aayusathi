import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/models/previous_visit_record.dart';
import 'package:aayusathi/repositories/mock/mock_visit_repository.dart';

void main() {
  group('Phase 11: VisitRepository & Visit Lifecycle Tests', () {
    late MockVisitRepository repo;

    setUp(() {
      repo = MockVisitRepository();
      repo.resetToDefaults();
    });

    test('Retrieves default consultation visits for Aarav Sharma', () async {
      final cardioVisit = await repo.getLatestVisitForPatientAndDomain(
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
      );

      expect(cardioVisit, isNotNull);
      expect(cardioVisit?.previousDoctorId, 'DOC-CARD-01');
      expect(cardioVisit?.domainId, 'cardiology');
    });

    test('Returns null when no visit exists for patient in domain', () async {
      final entVisit = await repo.getLatestVisitForPatientAndDomain(
        patientId: 'AAYU-102938',
        domainId: 'ent',
      );

      expect(entVisit, isNull);
    });

    test('Saves new visit with queued status and retrieves it as latest', () async {
      final now = DateTime(2026, 9, 5, 14, 30);
      final newVisit = PreviousVisitRecord(
        visitId: 'VIS-NEW-101',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        previousDoctorId: 'DOC-CARD-02',
        lastVisitDate: now,
        appointmentId: 'REQ-12345',
        status: 'queued', // Kiosk registers initial status as queued/requested
      );

      await repo.saveVisit(newVisit);

      final latest = await repo.getLatestVisitForPatientAndDomain(
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
      );

      expect(latest, isNotNull);
      expect(latest?.visitId, 'VIS-NEW-101');
      expect(latest?.previousDoctorId, 'DOC-CARD-02');
      expect(latest?.status, 'queued');
    });

    test('getVisitsForPatient returns strictly records for the requested patient', () async {
      final aaravVisits = await repo.getVisitsForPatient('AAYU-102938');
      final priyaVisits = await repo.getVisitsForPatient('AAYU-482910');

      for (final v in aaravVisits) {
        expect(v.patientId, 'AAYU-102938');
      }
      for (final v in priyaVisits) {
        expect(v.patientId, 'AAYU-482910');
      }
    });
  });
}
