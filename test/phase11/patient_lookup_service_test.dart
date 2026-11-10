import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/kiosk/services/patient_lookup_service.dart';

void main() {
  group('Phase 11: RepositoryPatientLookupService Tests', () {
    late RepositoryPatientLookupService service;

    setUp(() {
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
      service = RepositoryPatientLookupService(simulateDelay: false);
    });

    tearDown(() {
      BackendProvider.instance.resetOverrides();
    });

    test('Successfully looks up Aarav Sharma by numeric suffix', () async {
      final result = await service.lookupPatient('102938');

      expect(result.isSuccess, isTrue);
      expect(result.patient, isNotNull);
      expect(result.patient?.patientId, 'AAYU-102938');
      expect(result.patient?.fullName, 'Aarav Sharma');
    });

    test('Successfully looks up Priya Patil by full prefixed ID', () async {
      final result = await service.lookupPatient('AAYU-482910');

      expect(result.isSuccess, isTrue);
      expect(result.patient?.patientId, 'AAYU-482910');
      expect(result.patient?.fullName, 'Priya Patil');
    });

    test('Fails with NOT_FOUND for non-existent ID', () async {
      final result = await service.lookupPatient('999999');

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NOT_FOUND');
      expect(result.patient, isNull);
    });

    test('Fails with INVALID_FORMAT for malformed IDs', () async {
      final result1 = await service.lookupPatient('123');
      expect(result1.errorCode, 'INVALID_FORMAT');

      final result2 = await service.lookupPatient('ABCDEF');
      expect(result2.errorCode, 'INVALID_FORMAT');

      final result3 = await service.lookupPatient('AAYU-1234');
      expect(result3.errorCode, 'INVALID_FORMAT');
    });

    test('Fails with EMPTY_ID for blank input', () async {
      final result = await service.lookupPatient('');
      expect(result.errorCode, 'EMPTY_ID');
    });
  });
}
