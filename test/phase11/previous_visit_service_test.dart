import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/models/previous_visit_record.dart';
import 'package:aayusathi/services/previous_visit_service.dart';

void main() {
  group('Phase 11: RepositoryPreviousVisitService Integration Tests', () {
    late RepositoryPreviousVisitService service;

    setUp(() {
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
      service = RepositoryPreviousVisitService();
    });

    tearDown(() {
      BackendProvider.instance.resetOverrides();
    });

    test('hasPreviousVisit returns true for Aarav Sharma in cardiology', () async {
      final hasVisit = await service.hasPreviousVisit(
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
      );
      expect(hasVisit, isTrue);
    });

    test('hasPreviousVisit returns false for Aarav Sharma in dermatology', () async {
      final hasVisit = await service.hasPreviousVisit(
        patientId: 'AAYU-102938',
        domainId: 'dermatology',
      );
      expect(hasVisit, isFalse);
    });

    test('getPreviousVisit returns correct doctor ID for prior visit', () async {
      final visit = await service.getPreviousVisit(
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
      );
      expect(visit, isNotNull);
      expect(visit?.previousDoctorId, 'DOC-CARD-01');
    });

    test('Custom visit record added to repository is reflected in service queries', () async {
      final customRecord = PreviousVisitRecord(
        visitId: 'VIS-TEST-99',
        patientId: 'AAYU-918234',
        domainId: 'gastroenterology',
        previousDoctorId: 'DOC-GAST-01',
        lastVisitDate: DateTime(2026, 8, 20),
      );

      await BackendProvider.instance.visitRepository.saveVisit(customRecord);

      final hasVisit = await service.hasPreviousVisit(
        patientId: 'AAYU-918234',
        domainId: 'gastroenterology',
      );
      expect(hasVisit, isTrue);

      final retrieved = await service.getPreviousVisit(
        patientId: 'AAYU-918234',
        domainId: 'gastroenterology',
      );
      expect(retrieved?.previousDoctorId, 'DOC-GAST-01');
    });
  });
}
